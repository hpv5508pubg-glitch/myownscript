--[[
    libraries/prediction.lua — Resolvers, Remote Pickers, Quartic Lead Solver & Motion Predictor
]]
local ctx = ...
local ReplicatedStorage = ctx.ReplicatedStorage
local LP = ctx.LP
local AssetData = ctx.Assets.AssetData
local Config = ctx.Assets.Config

local function itemImage(name, model)
    if not name or name == "" then return nil end
    local img = AssetData.Items[name] or AssetData.Items[name:lower()]
    if img and img ~= "" then return img end
    if model then
        local tool = model:FindFirstChild(name)
        if tool and tool:IsA("Tool") and tool.TextureId ~= "" then return tool.TextureId end
    end
    return nil
end

local function kitImage(player, model)
    local kid = (player and player:GetAttribute(Config.Resolver.KitAttribute)) or (model and model:GetAttribute(Config.Resolver.KitAttribute))
    if type(kid) == "string" and kid ~= "" then
        return AssetData.Kits[kid] or AssetData.Kits[kid:lower()], kid
    end
    return nil, nil
end

local function enchantImage(model)
    if not model then return nil end
    local ench = model:GetAttribute(Config.Resolver.EnchantAttribute) or model:GetAttribute("WeaponEnchant")
    if type(ench) == "string" and ench ~= "" then
        return AssetData.Enchants[ench] or AssetData.Enchants[ench:lower()]
    end
    return nil
end

local function heldName(model)
    if not model then return nil end
    local hvName = Config.Resolver.HandValueName
    local hv = hvName and model:FindFirstChild(hvName)
    if hv then
        if hv:IsA("ObjectValue") and hv.Value then return hv.Value.Name end
        if hv:IsA("StringValue") and hv.Value ~= "" then return hv.Value end
    end
    local tool = model:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    for _, ch in ipairs(model:GetChildren()) do
        if ch:IsA("Model") and (AssetData.Items[ch.Name] or AssetData.Items[ch.Name:lower()] or ch:FindFirstChild("Handle")) then
            return ch.Name
        end
    end
    return nil
end

local function isRangedWeapon(itemName)
    if not itemName then return false end
    local nl = itemName:lower()
    for _, kw in ipairs(Config.RangedKeywords) do
        if nl:find(kw, 1, true) then return true end
    end
    return false
end

local function getProjectileProfile(itemName)
    if not itemName then return nil end
    local nl = itemName:lower()
    for key, prof in pairs(Config.ProjectileProfiles) do
        if nl:find(key, 1, true) then return prof end
    end
    return Config.ProjectileProfiles.arrow
end

local function readLoadout(model, isDummy)
    local armor = {}
    if isDummy then
        local nl = model.Name:lower()
        for _, t in ipairs(Config.Tiers) do
            if nl:find(t.key, 1, true) then
                for _, slot in ipairs(Config.Resolver.ArmorOrder) do armor[slot] = t.key .. "_" .. slot end
                break
            end
        end
    else
        for slot, valName in pairs(Config.Resolver.ArmorValueNames) do
            local v = model:FindFirstChild(valName)
            if v then
                if v:IsA("ObjectValue") and v.Value then armor[slot] = v.Value.Name
                elseif v:IsA("StringValue") and v.Value ~= "" then armor[slot] = v.Value end
            end
        end
    end
    return armor, heldName(model)
end

--------------------------------------------------------------------------------
-- Combat Helpers (Kill Aura + Projectile Aimbot)
--------------------------------------------------------------------------------

local function findRemote(pathList, nameFallback)
    local node = ReplicatedStorage
    for _, k in ipairs(pathList) do
        node = node and node:FindFirstChild(k)
    end
    if node and (node:IsA("RemoteEvent") or node:IsA("RemoteFunction")) then return node end
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and d.Name == nameFallback then return d end
    end
    return nil
end

local attackRemote
local function getAttackRemote()
    if attackRemote and attackRemote.Parent then return attackRemote end
    attackRemote = findRemote(Config.Combat.AttackRemotePath, Config.Combat.AttackRemoteName)
    return attackRemote
end

local placeRemote
local function getPlaceRemote()
    if placeRemote and placeRemote.Parent then return placeRemote end
    placeRemote = findRemote(Config.Combat.PlaceRemotePath, Config.Combat.PlaceRemoteName)
    return placeRemote
end

local function pickSword()
    local ch = LP.Character
    if ch then
        local hv = ch:FindFirstChild(Config.Resolver.HandValueName)
        if hv and hv:IsA("ObjectValue") and hv.Value then
            local hn = hv.Value.Name:lower()
            if hn:find("sword", 1, true) or hn:find("blade", 1, true) or hn:find("scythe", 1, true) then
                return hv.Value
            end
        end
    end
    local held = heldName(ch)
    local inv = ReplicatedStorage:FindFirstChild(Config.Combat.InventoriesFolder)
    inv = inv and inv:FindFirstChild(LP.Name)
    local best, bestRank = nil, -1
    if inv then
        for _, it in ipairs(inv:GetChildren()) do
            local n = it.Name:lower()
            if n:find("sword", 1, true) or n:find("blade", 1, true) or n:find("scythe", 1, true) then
                local rank = 0
                for key, r in pairs(Config.Combat.SwordRank) do
                    if n:find(key, 1, true) and r > rank then rank = r end
                end
                if held and it.Name == held then rank += 100 end
                if rank > bestRank then best, bestRank = it, rank end
            end
        end
    end
    if best then return best end
    for _, container in ipairs({ ch, LP:FindFirstChildOfClass("Backpack") }) do
        if container then
            for _, c in ipairs(container:GetChildren()) do
                if c:IsA("Tool") then
                    local n = c.Name:lower()
                    if n:find("sword", 1, true) or n:find("blade", 1, true) or n:find("scythe", 1, true) then return c end
                end
            end
        end
    end
    return nil
end

local function equipToolIfNeeded(itemObj)
    if not itemObj then return end
    local ch = LP.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if itemObj:IsA("Tool") and itemObj.Parent ~= ch then
        pcall(function() hum:EquipTool(itemObj) end)
    end
end

local function collectAvailableProjectiles()
    local found = {}
    local inv = ReplicatedStorage:FindFirstChild(Config.Combat.InventoriesFolder)
    inv = inv and inv:FindFirstChild(LP.Name)
    if inv then
        for _, it in ipairs(inv:GetChildren()) do
            if isRangedWeapon(it.Name) then
                found[#found + 1] = { Name = it.Name, Profile = getProjectileProfile(it.Name) }
            end
        end
    end
    return found
end

local PRED_EPS = 1e-9
local function predZero(d) return d > -PRED_EPS and d < PRED_EPS end
local function predCbrt(x) return (x > 0) and math.pow(x, 1 / 3) or -math.pow(math.abs(x), 1 / 3) end
local function predPush(list, ...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then list[#list + 1] = v end
    end
end
local function solveQuadric(c0, c1, c2)
    local p, q = c1 / (2 * c0), c2 / c0
    local D = p * p - q
    if predZero(D) then return -p
    elseif D < 0 then return nil
    else
        local sq = math.sqrt(D)
        return sq - p, -sq - p
    end
end
local function solveCubic(c0, c1, c2, c3)
    local A, B, C = c1 / c0, c2 / c0, c3 / c0
    local sqA = A * A
    local p = (1 / 3) * (-(1 / 3) * sqA + B)
    local q = 0.5 * ((2 / 27) * A * sqA - (1 / 3) * A * B + C)
    local cbP = p * p * p
    local D = q * q + cbP
    local s0, s1, s2, num = 0, 0, 0, 0
    if predZero(D) then
        if predZero(q) then s0 = 0 num = 1
        else local u = predCbrt(-q) s0 = 2 * u s1 = -u num = 2 end
    elseif D < 0 then
        local phi = (1 / 3) * math.acos(math.clamp(-q / math.sqrt(-cbP), -1, 1))
        local t = 2 * math.sqrt(-p)
        s0 = t * math.cos(phi)
        s1 = -t * math.cos(phi + math.pi / 3)
        s2 = -t * math.cos(phi - math.pi / 3)
        num = 3
    else
        local sqD = math.sqrt(D)
        s0 = predCbrt(sqD - q) - predCbrt(sqD + q)
        num = 1
    end
    local sub = (1 / 3) * A
    if num > 0 then s0 -= sub end
    if num > 1 then s1 -= sub end
    if num > 2 then s2 -= sub end
    if num == 3 then return s0, s1, s2
    elseif num == 2 then return s0, s1
    elseif num == 1 then return s0 end
end
local function softSqrt(x, scale)
    if x >= 0 then return math.sqrt(x) end
    if x > -1e-9 * math.max(scale, 1) then return 0 end
    return nil
end
local function solveQuartic(c0, c1, c2, c3, c4)
    local roots = {}
    local A, B, C, D = c1 / c0, c2 / c0, c3 / c0, c4 / c0
    local sqA = A * A
    local p = -0.375 * sqA + B
    local q = 0.125 * sqA * A - 0.5 * A * B + C
    local r = -(3 / 256) * sqA * sqA + 0.0625 * sqA * B - 0.25 * A * C + D
    if predZero(r) then
        predPush(roots, solveCubic(1, 0, p, q))
        predPush(roots, 0)
    else
        local z = solveCubic(1, -0.5 * p, -r, 0.5 * r * p - 0.125 * q * q)
        if not z then return nil end
        local u = softSqrt(z * z - r, math.max(z * z, math.abs(r)))
        local v = softSqrt(2 * z - p, math.max(math.abs(2 * z), math.abs(p)))
        if not (u and v) then return nil end
        predPush(roots, solveQuadric(1, q < 0 and -v or v, z - u))
        predPush(roots, solveQuadric(1, q < 0 and v or -v, z + u))
    end
    local sub = 0.25 * A
    for i, s in ipairs(roots) do roots[i] = s - sub end
    return roots
end
local function evalQuartic(c4, c3, c2, c1, c0, t)
    return (((c4 * t + c3) * t + c2) * t + c1) * t + c0,
           ((4 * c4 * t + 3 * c3) * t + 2 * c2) * t + c1
end
local function earliestRoot(c4, c3, c2, c1, c0)
    local tMin = 1e-6
    local scale = math.max(math.abs(c4), math.abs(c3), math.abs(c2), math.abs(c1), math.abs(c0), 1e-12)
    local candidates = {}
    if math.abs(c4) > 1e-12 * scale then
        candidates = solveQuartic(c4, c3, c2, c1, c0) or candidates
    elseif math.abs(c2) > 1e-12 * scale then
        predPush(candidates, solveQuadric(c2, c1, c0))
    elseif math.abs(c1) > 1e-12 * scale then
        predPush(candidates, -c0 / c1)
    end
    local best
    for _, t in ipairs(candidates) do
        if t == t then
            local f = evalQuartic(c4, c3, c2, c1, c0, t)
            local pol = t
            for _ = 1, 4 do
                local pf, df = evalQuartic(c4, c3, c2, c1, c0, pol)
                if df == 0 then break end
                pol -= pf / df
            end
            local pf = evalQuartic(c4, c3, c2, c1, c0, pol)
            if pf == pf and math.abs(pf) <= math.abs(f) then t, f = pol, pf end
            local at = math.abs(t)
            local size = math.abs(c4) * at^4 + math.abs(c3) * at^3 + math.abs(c2) * at * at + math.abs(c1) * at + math.abs(c0)
            if t > tMin and math.abs(f) <= 1e-6 * size and (not best or t < best) then best = t end
        end
    end
    return best
end

local function leadAim(origin, pos, vel, speed, gravity, tracker, now)
    if not speed or speed <= 0 then return pos end
    local g = gravity or 0
    local isKb = tracker and tracker.kbUntil and now and now < tracker.kbUntil
    local effVel = vel
    if isKb and tracker.kbBase then
        local approxT = (pos - origin).Magnitude / speed
        effVel = tracker.kbBase:Lerp(vel, math.exp(-(tracker.kbDecay or 3.0) * approxT))
    elseif tracker and tracker.turnRate and math.abs(tracker.turnRate) > 0.05 then
        local approxT = (pos - origin).Magnitude / speed
        local ang = math.clamp(tracker.turnRate * approxT * 0.5, -1.2, 1.2)
        local cs, sn = math.cos(ang), math.sin(ang)
        effVel = Vector3.new(vel.X * cs - vel.Z * sn, vel.Y, vel.X * sn + vel.Z * cs)
    end
    local disp = pos - origin
    local h, j, k = disp.X, disp.Y, disp.Z
    local p, q, r = effVel.X, effVel.Y, effVel.Z
    local l = -0.5 * g
    local t = earliestRoot(
        l * l,
        -2 * q * l,
        q * q - 2 * j * l - speed * speed + p * p + r * r,
        2 * j * q + 2 * h * p + 2 * k * r,
        j * j + h * h + k * k
    )
    if t then
        return pos + effVel * t + Vector3.new(0, 0.5 * g * t * t, 0)
    end
    local approxT = disp.Magnitude / speed
    return pos + effVel * approxT + Vector3.new(0, 0.5 * g * approxT * approxT, 0)
end


local function updateTargetMotion(e, now, trackers)
    local rootPart = e.root
    local pos = rootPart.Position
    local rawVel = rootPart.AssemblyLinearVelocity
    local char = e.model
    local lastDamageTime = typeof(char) == "Instance" and char:GetAttribute("LastDamageTakenTime") or nil
    local isAirborne = e.hum and e.hum.FloorMaterial == Enum.Material.Air

    local tracker = trackers[char]
    if not tracker or tracker.root ~= rootPart or (now - tracker.time) > 0.75 then
        tracker = {
            root = rootPart,
            time = now,
            position = pos,
            velocity = rawVel,
            stable = rawVel,
            samplePos = { pos },
            sampleTime = { now },
            sampleHead = 1,
            sampleCount = 1,
            damageTime = lastDamageTime,
        }
        trackers[char] = tracker
        return tracker
    end

    local dt = now - tracker.time
    if dt <= 1e-4 then return tracker end

    -- Ignore Telepearl / velocity spikes > 260
    local displacement = pos - tracker.position
    local maxAllowedDist = math.max(12, (math.max(tracker.velocity.Magnitude, rawVel.Magnitude) + 30) * dt * 1.5)
    if displacement.Magnitude > maxAllowedDist or rawVel.Magnitude > 260 then
        tracker.position = pos
        tracker.velocity = Vector3.zero
        tracker.time = now
        return tracker
    end

    -- 8-sample ring buffer
    local idx = (tracker.sampleHead + tracker.sampleCount - 1) % 8 + 1
    tracker.samplePos[idx] = pos
    tracker.sampleTime[idx] = now
    tracker.sampleCount += 1

    while tracker.sampleCount > 6 or (tracker.sampleCount > 2 and now - tracker.sampleTime[tracker.sampleHead] > 0.2) do
        tracker.sampleHead = tracker.sampleHead % 8 + 1
        tracker.sampleCount -= 1
    end

    local newestIdx = (tracker.sampleHead + tracker.sampleCount - 2) % 8 + 1
    local sampledVel = rawVel
    if tracker.sampleCount >= 2 then
        local span = tracker.sampleTime[newestIdx] - tracker.sampleTime[tracker.sampleHead]
        if span > 0.02 then
            local v = (tracker.samplePos[newestIdx] - tracker.samplePos[tracker.sampleHead]) / span
            if v.Magnitude <= 260 then sampledVel = v end
        end
    end

    local smoothedVel = rawVel:Lerp(sampledVel, 0.15)
    local finalVel = Vector3.new(smoothedVel.X, rawVel.Y, smoothedVel.Z)

    local tookDamage = (type(lastDamageTime) == "number" and lastDamageTime > 0 and lastDamageTime ~= tracker.damageTime)
    if tookDamage then
        tracker.hitAt = now
        if (finalVel - tracker.velocity).Magnitude > 1.5 then
            tracker.kbBase = tracker.stable
            tracker.kbDecay = isAirborne and 1.8 or 3.5
            tracker.kbStart = now
            tracker.kbUntil = now + 0.6
        end
    end

    local isKnockedBack = tracker.kbUntil and now < tracker.kbUntil
    if not isKnockedBack then tracker.stable = finalVel end

    if finalVel.Magnitude > 5 and not isKnockedBack then
        local dir = finalVel.Unit
        if tracker.turnUnit then
            local crossY = tracker.turnUnit.X * dir.Z - tracker.turnUnit.Z * dir.X
            local angleDiff = math.atan2(crossY, math.clamp(tracker.turnUnit:Dot(dir), -1, 1))
            if math.abs(angleDiff) < 1.4 then
                local rate = angleDiff / dt
                tracker.turnRate = tracker.turnRate and (tracker.turnRate + (rate - tracker.turnRate) * 0.3) or rate
            else
                tracker.turnRate = nil
            end
        end
        tracker.turnUnit = dir
    else
        tracker.turnRate = nil
        tracker.turnUnit = nil
    end

    tracker.damageTime = lastDamageTime
    tracker.position = pos
    tracker.time = now
    tracker.velocity = finalVel
    return tracker
end



return {
    itemImage = itemImage,
    kitImage = kitImage,
    enchantImage = enchantImage,
    heldName = heldName,
    isRangedWeapon = isRangedWeapon,
    getProjectileProfile = getProjectileProfile,
    readLoadout = readLoadout,
    findRemote = findRemote,
    getAttackRemote = getAttackRemote,
    getPlaceRemote = getPlaceRemote,
    pickSword = pickSword,
    equipToolIfNeeded = equipToolIfNeeded,
    collectAvailableProjectiles = collectAvailableProjectiles,
    leadAim = leadAim,
    updateTargetMotion = updateTargetMotion,
}
