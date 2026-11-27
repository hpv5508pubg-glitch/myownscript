--[[
    games/bedwars.lua — WrenchHub BedWars Modules & Overlays (Perf-Hardened)
]]
local ctx = ...
local Players = ctx.Players
local RunService = ctx.RunService
local UserInputService = ctx.UserInputService
local CollectionService = ctx.CollectionService
local Lighting = ctx.Lighting
local StatsService = ctx.StatsService
local LP = ctx.LP
local cam = ctx.cam
local vape = ctx.vape
local env = ctx.env
local Notify = ctx.Notify
local CoreMaid = ctx.CoreMaid
local T = ctx.T
local Center = ctx.Center
local Left = ctx.Left
local make = ctx.make
local corner = ctx.corner
local textLabel = ctx.textLabel
local OverlayGui = ctx.OverlayGui
local OverlayL = ctx.OverlayL

local AssetData = ctx.Assets.AssetData
local Config = ctx.Assets.Config
local BlockColors = ctx.Assets.BlockColors
local LagEffects = ctx.Assets.LagEffects

local Maid = ctx.Entity.Maid
local Anim = ctx.Entity.Anim
local stepAnims = ctx.Entity.stepAnims
local Entities = ctx.Entity.Entities
local Targeting = ctx.Entity.Targeting
local TargetState = ctx.Entity.TargetState
local isBlockedModel = ctx.Entity.isBlockedModel
local entColor = ctx.Entity.entColor

local Pred = ctx.Prediction
local itemImage = Pred.itemImage
local kitImage = Pred.kitImage
local enchantImage = Pred.enchantImage
local heldName = Pred.heldName
local isRangedWeapon = Pred.isRangedWeapon
local getProjectileProfile = Pred.getProjectileProfile
local readLoadout = Pred.readLoadout
local findRemote = Pred.findRemote
local getAttackRemote = Pred.getAttackRemote
local pickSword = Pred.pickSword
local equipToolIfNeeded = Pred.equipToolIfNeeded
local leadAim = Pred.leadAim
local updateTargetMotion = Pred.updateTargetMotion

local SIGNS = { -1, 1 }

-- Shared-guarded Silent Aim hook state (never stacks hooks across reinjects; installed ONLY when Mode == "Silent")
shared.__WrenchHub_SilentAim = shared.__WrenchHub_SilentAim or { active = false, targetPos = nil, origin = nil }
local SilentAimState = shared.__WrenchHub_SilentAim

local function redirectVecTable(tbl, origin, targetPos)
    local dir = (targetPos - origin)
    if dir.Magnitude < 0.01 then return end
    local unitDir = dir.Unit
    for k, v in pairs(tbl) do
        local kl = tostring(k):lower()
        if typeof(v) == "Vector3" then
            if kl:find("vel", 1, true) and v.Magnitude > 5 then
                tbl[k] = unitDir * v.Magnitude
            elseif kl:find("dir", 1, true) then
                tbl[k] = unitDir
            elseif kl:find("pos", 1, true) and kl:find("target", 1, true) then
                tbl[k] = targetPos
            end
        elseif type(v) == "table" and typeof(v.value) == "Vector3" then
            if kl:find("dir", 1, true) then
                v.value = unitDir
            elseif kl:find("vel", 1, true) and v.value.Magnitude > 5 then
                v.value = unitDir * v.value.Magnitude
            elseif kl:find("target", 1, true) then
                v.value = targetPos
            end
        end
    end
end

local function installSilentAimHook()
    if shared.__WrenchHub_SilentAim_Installed or not (hookmetamethod and getnamecallmethod) then return end
    shared.__WrenchHub_SilentAim_Installed = true
    local mouse = LP:GetMouse()

    local oldNamecall
    local function namecallHook(self, ...)
        local st = shared.__WrenchHub_SilentAim
        local method = getnamecallmethod()
        if st and st.active and st.targetPos and typeof(self) == "Instance"
            and (method == "FireServer" or method == "InvokeServer") then
            local nl = self.Name:lower()
            if nl:find("proj", 1, true) or nl:find("shoot", 1, true) or nl:find("fire", 1, true) or nl:find("bow", 1, true) or nl:find("throw", 1, true) or nl:find("launch", 1, true) then
                local args = table.pack(...)
                local origin = st.origin or (cam() and cam().CFrame.Position) or Vector3.zero
                local tpos = st.targetPos
                local unitDir = (tpos - origin).Unit
                for i = 1, args.n do
                    local a = args[i]
                    if typeof(a) == "Vector3" then
                        if a.Magnitude > 10 then
                            args[i] = unitDir * a.Magnitude
                        elseif math.abs(a.Magnitude - 1) < 0.08 then
                            args[i] = unitDir
                        end
                    elseif typeof(a) == "CFrame" then
                        args[i] = CFrame.lookAt(a.Position, tpos)
                    elseif type(a) == "table" then
                        redirectVecTable(a, origin, tpos)
                    end
                end
                return oldNamecall(self, table.unpack(args, 1, args.n))
            end
        end
        return oldNamecall(self, ...)
    end
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure and newcclosure(namecallHook) or namecallHook)

    local oldIndex
    local function indexHook(self, key)
        local st = shared.__WrenchHub_SilentAim
        if st and st.active and st.targetPos and self == mouse then
            if key == "Hit" then
                return CFrame.new(st.targetPos)
            elseif key == "UnitRay" then
                local origin = cam() and cam().CFrame.Position or Vector3.zero
                return Ray.new(origin, (st.targetPos - origin).Unit)
            end
        end
        return oldIndex(self, key)
    end
    oldIndex = hookmetamethod(game, "__index", newcclosure and newcclosure(indexHook) or indexHook)
end

local capture = shared.__WrenchHub_Capture or { installed = false, untilT = 0, counts = {} }
shared.__WrenchHub_Capture = capture
local function dumpValue(v, depth)
    depth = depth or 0
    local ty = typeof(v)
    if ty == "table" then
        if depth >= 4 then return "{...}" end
        local parts, n = {}, 0
        for k, x in pairs(v) do
            n += 1
            if n > 16 then parts[#parts + 1] = "..." break end
            parts[#parts + 1] = tostring(k) .. "=" .. dumpValue(x, depth + 1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    elseif ty == "Instance" then
        return "<" .. v.ClassName .. " " .. v:GetFullName() .. ">"
    elseif ty == "string" then
        return string.format("%q", v)
    end
    return ty .. ":" .. tostring(v)
end

local function captureShots(seconds)
    if not (hookmetamethod and getnamecallmethod) then
        Notify("Capture", "Executor has no hookmetamethod", 4, true)
        return
    end
    capture.untilT = os.clock() + seconds
    capture.counts = {}
    if not capture.installed then
        capture.installed = true
        local old
        local function hooked(self, ...)
            if os.clock() < capture.untilT and getnamecallmethod() == "FireServer" and typeof(self) == "Instance" then
                local full = self:GetFullName()
                local n = (capture.counts[full] or 0) + 1
                capture.counts[full] = n
                if n <= 2 then
                    local packed = table.pack(...)
                    task.spawn(function()
                        local parts = {}
                        for i = 1, packed.n do parts[i] = dumpValue(packed[i]) end
                        print("[WrenchHub capture] " .. full .. " #" .. n .. " (" .. table.concat(parts, " | ") .. ")")
                    end)
                end
            end
            return old(self, ...)
        end
        old = hookmetamethod(game, "__namecall", newcclosure and newcclosure(hooked) or hooked)
    end
    Notify("Capture", "Fire your launcher now (" .. seconds .. "s)", 4, true)
end

--------------------------------------------------------------------------------
-- COMBAT : Kill Aura
--------------------------------------------------------------------------------
do
    local AttackRange, SwingRange, AutoCooldown, DelayOpt, FOVOpt, MaxTargets
    local PriorityOpt, TargetsOpt, AutoEquip, SwingAnim, FaceTarget
    local setInvRemote
    local function equipBedwarsSword(itemObj)
        if not itemObj then return end
        local ch = LP.Character
        if not ch then return end
        local hv = ch:FindFirstChild(Config.Resolver.HandValueName)
        if hv and hv:IsA("ObjectValue") and hv.Value == itemObj then return end
        if itemObj:IsA("Tool") then
            equipToolIfNeeded(itemObj)
            return
        end
        if not (setInvRemote and setInvRemote.Parent) then
            setInvRemote = findRemote({ "rbxts_include", "node_modules", "@rbxts", "net", "out", "_NetManaged", "SetInvItem" }, "SetInvItem")
        end
        if setInvRemote then
            if setInvRemote:IsA("RemoteFunction") then
                task.spawn(function() pcall(function() setInvRemote:InvokeServer({ hand = itemObj }) end) end)
            else
                pcall(function() setInvRemote:FireServer({ hand = itemObj }) end)
            end
        end
    end
    local function getSwordDelay(sword)
        if not AutoCooldown.Enabled then
            return DelayOpt.Value
        end
        local nm = sword and sword.Name and sword.Name:lower() or ""
        if nm:find("rageblade", 1, true) then
            return math.max(0.25, DelayOpt.Value)
        end
        return math.max(0.31, DelayOpt.Value)
    end

    local KillAura
    KillAura = vape.Categories.Combat:CreateModule({
        Name = "Kill Aura",
        Tooltip = "Attacks nearby enemies within 360 range cleanly (syncs sword cooldown & raycast).",
        ExtraText = function() return PriorityOpt and PriorityOpt.Value or "Distance" end,
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            KillAura:Clean(function() maid:clean() end)
            if not getAttackRemote() then
                Notify("Kill Aura", "Attack remote '" .. Config.Combat.AttackRemoteName .. "' not found", 4, true)
                pcall(KillAura.Toggle, KillAura, true)
                return
            end
            maid:give(Entities.acquire())
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local last, cycleIdx = 0, 0
            local swingAnimObj = maid:give(Instance.new("Animation"))
            swingAnimObj.AnimationId = "rbxassetid://4947108314"
            local cachedHum, cachedTrack = nil, nil
            local function playSwing(hum)
                if not hum then return end
                local animator = hum:FindFirstChildOfClass("Animator") or hum
                if cachedHum ~= hum or not cachedTrack then
                    cachedHum = hum
                    local ok, tr = pcall(function() return animator:LoadAnimation(swingAnimObj) end)
                    if ok and tr then
                        tr.Priority = Enum.AnimationPriority.Action
                        cachedTrack = tr
                    end
                end
                if cachedTrack then
                    pcall(function() cachedTrack:Play(0.05, 1, 1.8) end)
                end
            end
            maid:give(RunService.Heartbeat:Connect(function()
                local c = cam()
                local ch = LP.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                if not c or not hum or not root or hum.Health <= 0 then return end
                local spos = root.Position
                local lookFlat = root.CFrame.LookVector * Vector3.new(1, 0, 1)
                if lookFlat.Magnitude > 1e-3 then lookFlat = lookFlat.Unit end

                local atkPlayers, atkNpcs = {}, {}
                local swPlayers, swNpcs = {}, {}
                local rangeVal, swingVal = AttackRange.Value, SwingRange.Value
                local fovVal = FOVOpt.Value
                local wantPlayers = TargetsOpt.Players.Enabled
                local wantNpcs = TargetsOpt.NPCs.Enabled
                local ignoreInvis = TargetsOpt.Invisible.Enabled
                local wallcheck = TargetsOpt.Walls.Enabled
                local scanRange = math.max(rangeVal, swingVal)

                for _, e in ipairs(Entities.list) do
                    if e.dist > scanRange then break end
                    if not e.friendly and not (ignoreInvis and e.invisible) then
                        local okType = (not e.isDummy and wantPlayers) or (e.isDummy and wantNpcs)
                        if okType then
                            local passFov = true
                            if fovVal < 359 then
                                local flat = (e.root.Position - spos) * Vector3.new(1, 0, 1)
                                if flat.Magnitude > 0.1 then
                                    local ang = math.deg(math.acos(math.clamp(lookFlat:Dot(flat.Unit), -1, 1)))
                                    passFov = ang <= (fovVal / 2)
                                end
                            end
                            local passWall = true
                            if passFov and wallcheck then
                                rp.FilterDescendantsInstances = { ch, e.model }
                                passWall = workspace:Raycast(spos, e.root.Position - spos, rp) == nil
                            end
                            if passFov and passWall then
                                if e.dist <= rangeVal then
                                    if not e.isDummy then atkPlayers[#atkPlayers + 1] = e else atkNpcs[#atkNpcs + 1] = e end
                                end
                                if not e.isDummy then swPlayers[#swPlayers + 1] = e else swNpcs[#swNpcs + 1] = e end
                            end
                        end
                    end
                end

                local atkPool = (#atkPlayers > 0) and atkPlayers or atkNpcs
                local swPool = (#swPlayers > 0) and swPlayers or swNpcs
                if #atkPool == 0 and #swPool == 0 then return end

                local prio = PriorityOpt.Value
                if prio == "Health" then
                    if #atkPool > 1 then table.sort(atkPool, function(a, b) return a.hum.Health < b.hum.Health end) end
                    if #swPool > 1 then table.sort(swPool, function(a, b) return a.hum.Health < b.hum.Health end) end
                end

                local preview = atkPool[1] or swPool[1]
                if preview then
                    Targeting.report(preview, "KillAura")
                end
                if #atkPool == 0 then return end

                local sword = pickSword()
                local remote = getAttackRemote()
                if not sword or not remote then return end
                local cooldown = getSwordDelay(sword)
                local now = os.clock()
                if now - last < cooldown then return end

                if AutoEquip.Enabled then equipBedwarsSword(sword) end

                local maxT = math.max(1, math.min(#atkPool, MaxTargets.Value))
                local chosenIdx = 1
                if prio == "Switch" or maxT > 1 then
                    cycleIdx = (cycleIdx % maxT) + 1
                    chosenIdx = cycleIdx
                end
                local target = atkPool[chosenIdx] or atkPool[1]
                Targeting.report(target, "KillAura")

                local targetPartPos = target.root.Position
                if FaceTarget.Enabled then
                    root.CFrame = CFrame.lookAt(spos, Vector3.new(targetPartPos.X, spos.Y, targetPartPos.Z))
                end

                local dirVec = targetPartPos - spos
                local mag = dirVec.Magnitude
                if mag < 0.01 then return end
                local unitDir = dirVec / mag
                local spoofSelf = (mag > 14.4) and (spos + unitDir * math.min(mag - 14.0, 6.0)) or spos
                local rayCam = spos + unitDir * math.min(mag, 18)
                local rayDir = (rayCam - spoofSelf).Magnitude >= 0.05 and CFrame.lookAt(spoofSelf, rayCam).LookVector or unitDir
                local pivotPos = (target.model and target.model:GetPivot().Position) or targetPartPos

                local packet = {
                    entityInstance = target.model,
                    chargedAttack = { chargeRatio = 0 },
                    validate = {
                        targetPosition = { value = pivotPos },
                        selfPosition = { value = spoofSelf },
                        raycast = {
                            cameraPosition = { value = rayCam },
                            cursorDirection = { value = rayDir },
                        },
                    },
                    weapon = sword,
                }

                last = now
                if remote:IsA("RemoteFunction") then
                    task.spawn(function() pcall(function() remote:InvokeServer(packet) end) end)
                else
                    pcall(function() remote:FireServer(packet) end)
                end
                if SwingAnim.Enabled then
                    playSwing(hum)
                end
            end))
        end,
    })
    TargetsOpt = KillAura:CreateTargets({ Players = true, NPCs = true })
    PriorityOpt = KillAura:CreateDropdown({ Name = "Target Priority", List = { "Distance", "Health", "Switch" } })
    AttackRange = KillAura:CreateSlider({ Name = "Attack range", Min = 6, Max = 20, Default = 18, Decimal = 10 })
    SwingRange = KillAura:CreateSlider({ Name = "Swing range", Min = 6, Max = 22, Default = 20, Decimal = 10 })
    AutoCooldown = KillAura:CreateToggle({ Name = "Auto cooldown", Default = true, Tooltip = "Matches BedWars 0.3s sword cooldown (0.25s rageblade) so the server accepts every swing." })
    DelayOpt = KillAura:CreateSlider({ Name = "Delay", Min = 0.05, Max = 0.5, Default = Config.Combat.DefaultAttackDelay, Decimal = 100, Suffix = "s" })
    FOVOpt = KillAura:CreateSlider({ Name = "FOV", Min = 30, Max = 360, Default = 360, Decimal = 1 })
    MaxTargets = KillAura:CreateSlider({ Name = "Max targets", Min = 1, Max = 5, Default = 3, Decimal = 1 })
    AutoEquip = KillAura:CreateToggle({ Name = "Auto equip", Default = false })
    SwingAnim = KillAura:CreateToggle({ Name = "3rd person swing", Default = true })
    FaceTarget = KillAura:CreateToggle({ Name = "Face target", Default = false })
end

--------------------------------------------------------------------------------
-- COMBAT : Projectile Aimbot (Camera / Flick / Silent, lazy hook, pre-FOV gate)
--------------------------------------------------------------------------------
do
    local ModeOpt, TargetsOpt, PartOpt, FOVOpt, RangeOpt, SpeedOpt
    local RangedOnly, FOVCircleOpt, CircleColorOpt
    local circleStroke
    local Aimbot
    Aimbot = vape.Categories.Combat:CreateModule({
        Name = "Projectile Aimbot",
        Tooltip = "Aims your projectiles at enemies for you. (1st person only)",
        ExtraText = function() return ModeOpt and ModeOpt.Value or "Camera" end,
        Function = function(callback)
            if not callback then
                SilentAimState.active = false
                SilentAimState.targetPos = nil
                return
            end
            local maid = Maid()
            Aimbot:Clean(function() maid:clean() end)
            if ModeOpt and ModeOpt.Value == "Silent" and hookmetamethod and getnamecallmethod then
                installSilentAimHook()
            end
            maid:give(Entities.acquire())
            local circle = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, OverlayL)
            maid:give(circle)
            corner(circle, 9999)
            circleStroke = make("UIStroke", {
                Color = Color3.fromHSV(CircleColorOpt.Hue, CircleColorOpt.Sat, CircleColorOpt.Value),
                Thickness = 1.5,
                Transparency = 1 - CircleColorOpt.Opacity,
            }, circle)
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local lastBestPos = nil
            local flickUntil, flickTarget, flickSavedCF = 0, nil, nil
            local wasFirstPerson = true
            local motionTrackers = setmetatable({}, { __mode = "k" })
            local lastCircleSize = -1

            maid:give(UserInputService.InputEnded:Connect(function(input)
                if ModeOpt.Value ~= "Flick" or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                if not lastBestPos then return end
                local c = cam()
                if not c then return end
                flickSavedCF = c.CFrame
                flickTarget = lastBestPos
                flickUntil = os.clock() + 0.06
                c.CFrame = CFrame.lookAt(flickSavedCF.Position, flickTarget)
            end))

            local id = "WrenchHub.Aimbot"
            RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value + 2, function(dt)
                local c = cam()
                local ch = LP.Character
                if not c or not ch then
                    circle.Visible = false
                    SilentAimState.active = false
                    lastBestPos = nil
                    return
                end
                if flickSavedCF then
                    if os.clock() < flickUntil and flickTarget then
                        c.CFrame = CFrame.lookAt(c.CFrame.Position, flickTarget)
                        return
                    else
                        c.CFrame = flickSavedCF
                        flickSavedCF, flickTarget = nil, nil
                    end
                end
                local held = heldName(ch)
                local armed = (not RangedOnly.Enabled) or isRangedWeapon(held)
                local isFirstPerson = (c.CFrame.Position - c.Focus.Position).Magnitude < 1.5
                if not isFirstPerson then
                    circle.Visible = false
                    SilentAimState.active = false
                    lastBestPos = nil
                    if wasFirstPerson and armed then
                        Notify("Projectile Aimbot", "Paused in 3rd person (1st person only)", 2)
                    end
                    wasFirstPerson = false
                    return
                end
                wasFirstPerson = true
                circle.Visible = FOVCircleOpt.Enabled and armed
                if not armed then
                    SilentAimState.active = false
                    lastBestPos = nil
                    return
                end

                local fovVal = FOVOpt.Value
                if circle.Visible then
                    local vp = c.ViewportSize
                    local r = math.floor(math.tan(math.rad(fovVal / 2)) / math.tan(math.rad(c.FieldOfView / 2)) * (vp.Y / 2) + 0.5)
                    if r ~= lastCircleSize then
                        lastCircleSize = r
                        circle.Size = UDim2.fromOffset(r * 2, r * 2)
                    end
                end

                local prof = getProjectileProfile(held)
                local look, origin = c.CFrame.LookVector, c.CFrame.Position
                local now = os.clock()
                local rangeVal = RangeOpt.Value
                local wantPlayers = TargetsOpt.Players.Enabled
                local wantNpcs = TargetsOpt.NPCs.Enabled
                local ignoreInvis = TargetsOpt.Invisible.Enabled
                local checkWalls = TargetsOpt.Walls.Enabled
                local partMode = PartOpt.Value
                local halfFov = fovVal / 2
                local preFov = halfFov + 14

                local best, bestAng, bestPos
                for _, e in ipairs(Entities.list) do
                    if e.dist > rangeVal then break end
                    if not e.friendly and not (ignoreInvis and e.invisible) and ((e.isDummy and wantNpcs) or (not e.isDummy and wantPlayers)) then
                        local headPart = e.head
                        local part = (partMode == "Head" and headPart) or e.root
                        local basePos = (partMode == "Head" and headPart) and (part.Position + Vector3.new(0, 0.15, 0)) or part.Position
                        local rawTo = basePos - origin
                        local rawMag = rawTo.Magnitude
                        if rawMag > 0.01 then
                            -- Cheap pre-cone filter before updating motion ring buffer or solving quartics
                            local rawAng = math.deg(math.acos(math.clamp(look:Dot(rawTo / rawMag), -1, 1)))
                            if rawAng <= preFov then
                                local visible = true
                                if checkWalls then
                                    rp.FilterDescendantsInstances = { ch, e.model, c }
                                    local hitRes = workspace:Raycast(origin, part.Position - origin, rp)
                                    visible = (not hitRes) or (not hitRes.Instance.CanCollide) or (hitRes.Instance.Transparency >= 0.9)
                                end
                                if visible then
                                    local tracker = updateTargetMotion(e, now, motionTrackers)
                                    local predVel = tracker and tracker.velocity or e.root.AssemblyLinearVelocity
                                    local pos = leadAim(origin, basePos, predVel, prof.speed, prof.gravity, tracker, now)
                                    local to = pos - origin
                                    local tMag = to.Magnitude
                                    if tMag > 0 then
                                        local ang = math.deg(math.acos(math.clamp(look:Dot(to / tMag), -1, 1)))
                                        if ang <= halfFov and (not best or ang < bestAng) then
                                            best, bestAng, bestPos = e, ang, pos
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                if not best then
                    SilentAimState.active = false
                    lastBestPos = nil
                    return
                end
                Targeting.report(best, "ProjectileAimbot")
                lastBestPos = bestPos
                if ModeOpt.Value == "Silent" then
                    if hookmetamethod and getnamecallmethod then installSilentAimHook() end
                    if shared.__WrenchHub_SilentAim_Installed then
                        SilentAimState.active = true
                        SilentAimState.targetPos = bestPos
                        SilentAimState.origin = origin
                    end
                elseif ModeOpt.Value == "Camera" then
                    SilentAimState.active = false
                    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                        c.CFrame = c.CFrame:Lerp(CFrame.lookAt(origin, bestPos), 1 - math.exp(-SpeedOpt.Value * dt))
                    end
                else
                    SilentAimState.active = false
                end
            end)
            maid:give(function()
                RunService:UnbindFromRenderStep(id)
                SilentAimState.active = false
                SilentAimState.targetPos = nil
                circleStroke = nil
            end)
        end,
    })
    TargetsOpt = Aimbot:CreateTargets({ Players = true, NPCs = true, Walls = true })
    ModeOpt = Aimbot:CreateDropdown({
        Name = "Mode",
        List = { "Camera", "Flick", "Silent" },
        Function = function(val)
            if val == "Silent" and Aimbot.Enabled and hookmetamethod and getnamecallmethod then
                installSilentAimHook()
            elseif val ~= "Silent" then
                SilentAimState.active = false
            end
        end,
    })
    PartOpt = Aimbot:CreateDropdown({ Name = "Part", List = { "Head", "Body" } })
    FOVOpt = Aimbot:CreateSlider({ Name = "FOV", Min = 5, Max = 180, Default = 75, Decimal = 1 })
    RangeOpt = Aimbot:CreateSlider({ Name = "Range", Min = 20, Max = 300, Default = 150, Decimal = 1 })
    SpeedOpt = Aimbot:CreateSlider({ Name = "Aim Speed", Min = 1, Max = 40, Default = 40, Decimal = 1 })
    RangedOnly = Aimbot:CreateToggle({ Name = "Ranged weapon only", Default = true })
    FOVCircleOpt = Aimbot:CreateToggle({ Name = "FOV Circle", Default = true })
    CircleColorOpt = Aimbot:CreateColorSlider({
        Name = "FOV Circle Color",
        DefaultHue = 0,
        DefaultSat = 0,
        DefaultValue = 1,
        DefaultOpacity = 0.6,
        Function = function(hue, sat, val, opacity)
            if circleStroke and circleStroke.Parent then
                circleStroke.Color = Color3.fromHSV(hue, sat, val)
                circleStroke.Transparency = 1 - (opacity or 0.6)
            end
        end,
    })
    Aimbot:CreateButton({ Name = "Capture shots (6s)", Function = function() captureShots(6) end })
end

--------------------------------------------------------------------------------
-- COMBAT : Spin Bot
--------------------------------------------------------------------------------
do
    local SpeedOpt, DirOpt
    local SpinBot
    SpinBot = vape.Categories.Combat:CreateModule({
        Name = "Spin Bot",
        Tooltip = "Spins your character around cleanly.",
        ExtraText = function() return DirOpt and DirOpt.Value or "Left" end,
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            SpinBot:Clean(function() maid:clean() end)
            local touched = setmetatable({}, { __mode = "k" })
            maid:give(RunService.Stepped:Connect(function(_, dt)
                local ch = LP.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                if not hum or not root or hum.Health <= 0 then return end
                if touched[hum] == nil then touched[hum] = hum.AutoRotate end
                if hum.AutoRotate then hum.AutoRotate = false end
                if hum.Sit then return end
                local sgn = DirOpt.Value == "Right" and -1 or 1
                root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(SpeedOpt.Value * dt) * sgn, 0)
            end))
            maid:give(function()
                for hum, original in pairs(touched) do
                    if hum.Parent then hum.AutoRotate = original end
                end
            end)
        end,
    })
    SpeedOpt = SpinBot:CreateSlider({ Name = "Speed (deg/s)", Min = 30, Max = 2000, Default = 720, Decimal = 1 })
    DirOpt = SpinBot:CreateDropdown({ Name = "Direction", List = { "Left", "Right" } })
end

--------------------------------------------------------------------------------
-- MOVE : NoSlow & Velocity / Speed
--------------------------------------------------------------------------------
do
    local MinSpeed
    local NoSlow
    NoSlow = vape.Categories.Blatant:CreateModule({
        Name = "NoSlow",
        Tooltip = "Prevents bow/consume/block slowdown below minimum walkspeed.",
        ExtraText = function() return MinSpeed and tostring(MinSpeed.Value) or "20" end,
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            NoSlow:Clean(function() maid:clean() end)
            maid:give(RunService.Heartbeat:Connect(function()
                local ch = LP.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 and hum.WalkSpeed < MinSpeed.Value then
                    hum.WalkSpeed = MinSpeed.Value
                end
            end))
        end,
    })
    MinSpeed = NoSlow:CreateSlider({ Name = "Min walkspeed", Min = 16, Max = 26, Default = 20, Decimal = 1 })
end

do
    local VelEnabled, HorizMult, VertMult, SpeedEnabled, SpeedVal, AntiFall, FallY
    local VelSpeed
    VelSpeed = vape.Categories.Blatant:CreateModule({
        Name = "Velocity / Speed",
        Tooltip = "Reduces knockback, boosts move speed smoothly, and rescues void falls.",
        ExtraText = function() return SpeedEnabled and SpeedEnabled.Enabled and tostring(SpeedVal.Value) or "KB" end,
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            VelSpeed:Clean(function() maid:clean() end)
            local lastHp, safePos = nil, nil
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            maid:give(RunService.Heartbeat:Connect(function(dt)
                local ch = LP.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                if not hum or not root or hum.Health <= 0 then
                    lastHp = nil
                    return
                end
                if hum.FloorMaterial ~= Enum.Material.Air then
                    safePos = root.CFrame
                end
                local hp = hum.Health
                if lastHp and hp < lastHp - 0.1 and VelEnabled.Enabled then
                    local vel = root.AssemblyLinearVelocity
                    root.AssemblyLinearVelocity = Vector3.new(vel.X * HorizMult.Value, vel.Y * VertMult.Value, vel.Z * HorizMult.Value)
                end
                lastHp = hp
                if SpeedEnabled.Enabled then
                    local moveDir = hum.MoveDirection
                    if moveDir.Magnitude > 0.01 then
                        local extra = math.max(0, SpeedVal.Value - hum.WalkSpeed)
                        if extra > 0 then
                            local step = moveDir.Unit * extra * dt
                            rp.FilterDescendantsInstances = { ch }
                            if not workspace:Raycast(root.Position, step, rp) then
                                root.CFrame = root.CFrame + step
                            end
                        end
                    end
                end
                if AntiFall.Enabled and root.Position.Y < FallY.Value and safePos then
                    root.AssemblyLinearVelocity = Vector3.zero
                    root.CFrame = safePos + Vector3.new(0, 3, 0)
                end
            end))
        end,
    })
    VelEnabled = VelSpeed:CreateToggle({ Name = "Anti-Knockback", Default = true })
    HorizMult = VelSpeed:CreateSlider({ Name = "Horiz mult", Min = 0, Max = 1, Default = 0, Decimal = 10 })
    VertMult = VelSpeed:CreateSlider({ Name = "Vert mult", Min = 0, Max = 1, Default = 0, Decimal = 10 })
    SpeedEnabled = VelSpeed:CreateToggle({ Name = "Speed", Default = true })
    SpeedVal = VelSpeed:CreateSlider({ Name = "Speed value", Min = 16, Max = 45, Default = 24, Decimal = 1 })
    AntiFall = VelSpeed:CreateToggle({ Name = "Anti-Fall", Default = true })
    FallY = VelSpeed:CreateSlider({ Name = "Fall Y limit", Min = -120, Max = 0, Default = -40, Decimal = 1 })
end

--------------------------------------------------------------------------------
-- VISUAL : Player ESP (Free-list Pooled, Highlight Cap 8, Dirty-Checked UI)
--------------------------------------------------------------------------------
do
    local ColorOpt, NpcRange, MaxPlayers, HighlightOpt, BoxesOpt, Hitbox3dOpt
    local NamesOpt, HealthOpt, InfoOpt, TeamOpt, DummiesOpt, MarkTargetOpt
    local PlayerESP
    PlayerESP = vape.Categories.Render:CreateModule({
        Name = "Player ESP",
        Tooltip = "Highlights and displays boxes, names, health bars, and 3D hitboxes through walls.",
        ExtraText = function() return ColorOpt and ColorOpt.Value or "Team" end,
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            PlayerESP:Clean(function() maid:clean() end)
            local root = make("Frame", { Name = "ESP", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, OverlayL)
            local box3dFolder = make("Folder", { Name = "WrenchHub_Hitboxes" }, OverlayL)
            local hlFolder = make("Folder", { Name = "WrenchHub_Highlights" }, OverlayL)
            maid:give(root)
            maid:give(box3dFolder)
            maid:give(hlFolder)
            maid:give(Entities.acquire())
            local pool, freePool, frame = {}, {}, 0

            local function allocRec()
                if #freePool > 0 then
                    local r = table.remove(freePool)
                    r.lx, r.ly, r.lw, r.lh, r.lPct, r.lTextClock = -1, -1, -1, -1, -1, 0
                    return r
                end
                local r = { lx = -1, ly = -1, lw = -1, lh = -1, lPct = -1, lTextClock = 0 }
                r.outline = make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1 }, root)
                make("UIStroke", { Thickness = 3, Color = Color3.new(0, 0, 0), Transparency = 0.45 }, r.outline)
                r.box = make("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 2 }, root)
                r.stroke = make("UIStroke", { Thickness = 1.5, Color = T.white }, r.box)
                r.name = textLabel(root, "", 12, T.white, Center)
                r.name.AnchorPoint, r.name.Size, r.name.Visible, r.name.ZIndex = Vector2.new(0.5, 1), UDim2.fromOffset(180, 14), false, 3
                r.name.TextStrokeTransparency = 0.4
                r.info = textLabel(root, "", 11, T.white, Center)
                r.info.AnchorPoint, r.info.Size, r.info.Visible, r.info.ZIndex = Vector2.new(0.5, 0), UDim2.fromOffset(180, 14), false, 3
                r.info.TextStrokeTransparency = 0.4
                r.hbg = make("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, BorderSizePixel = 0, Visible = false, ZIndex = 2 }, root)
                r.hfill = make("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1), BorderSizePixel = 0, ZIndex = 3 }, r.hbg)

                local box3d = Instance.new("BoxHandleAdornment")
                box3d.Name = "PlayerBox"
                box3d.AlwaysOnTop = true
                box3d.ZIndex = 0
                box3d.Size = Vector3.new(3, 5, 3)
                box3d.CFrame = CFrame.new(0, -0.5, 0)
                box3d.Transparency = 0.72
                box3d.Visible = false
                box3d.Parent = box3dFolder
                r.box3d = box3d

                local hl = Instance.new("Highlight")
                hl.Name = "PlayerHL"
                hl.FillTransparency = 0.55
                hl.OutlineColor = T.white
                hl.OutlineTransparency = 0.1
                hl.Enabled = false
                hl.Parent = hlFolder
                r.hl = hl

                r.parts = { r.outline, r.box, r.name, r.info, r.hbg, r.box3d, r.hl }
                return r
            end

            local function hideRec(r)
                if r.vis == false then return end
                r.vis = false
                r.box.Visible, r.outline.Visible, r.name.Visible, r.info.Visible, r.hbg.Visible = false, false, false, false, false
                r.box3d.Visible = false
                if r.box3d.Adornee ~= nil then r.box3d.Adornee = nil end
                if r.hl.Enabled then r.hl.Enabled = false end
                if r.hl.Adornee ~= nil then r.hl.Adornee = nil end
            end

            local id = "WrenchHub.ESP"
            RunService:BindToRenderStep(id, Enum.RenderPriority.Last.Value, function()
                frame += 1
                local now = os.clock()
                local c = cam()
                if not c then return end
                local half = Config.BoxSize / 2
                local drawn, hlCount = 0, 0
                local maxP, npcR = MaxPlayers.Value, NpcRange.Value
                local wantBoxes, wantNames, wantInfo, wantHealth = BoxesOpt.Enabled, NamesOpt.Enabled, InfoOpt.Enabled, HealthOpt.Enabled
                local wantHit3d, wantHL = Hitbox3dOpt.Enabled, HighlightOpt.Enabled
                local wantTeam, wantDummies = TeamOpt.Enabled, DummiesOpt.Enabled
                local colMode, markTarget = ColorOpt.Value, MarkTargetOpt.Enabled

                for _, e in ipairs(Entities.list) do
                    if drawn >= maxP then break end
                    local inRange = (not e.isDummy) or (e.dist <= npcR)
                    if inRange and (wantTeam or not e.friendly) and (wantDummies or not e.isDummy) then
                        local need2D = wantBoxes or wantNames or wantInfo or wantHealth
                        local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
                        local ok = true
                        if need2D then
                            local p = e.root.Position
                            if wantBoxes then
                                for ix = 1, 2 do
                                    for iy = 1, 2 do
                                        for iz = 1, 2 do
                                            local v = c:WorldToViewportPoint(p + Vector3.new(SIGNS[ix] * half.X, SIGNS[iy] * half.Y, SIGNS[iz] * half.Z))
                                            if v.Z <= 0 then ok = false end
                                            if v.X < minX then minX = v.X end
                                            if v.X > maxX then maxX = v.X end
                                            if v.Y < minY then minY = v.Y end
                                            if v.Y > maxY then maxY = v.Y end
                                        end
                                    end
                                end
                            else
                                local vt = c:WorldToViewportPoint(p + Vector3.new(0, half.Y, 0))
                                local vb = c:WorldToViewportPoint(p - Vector3.new(0, half.Y, 0))
                                if vt.Z <= 0 or vb.Z <= 0 then
                                    ok = false
                                else
                                    local h = math.max(vb.Y - vt.Y, 12)
                                    local w = h * 0.6
                                    minX, maxX = vt.X - w / 2, vt.X + w / 2
                                    minY, maxY = vt.Y, vb.Y
                                end
                            end
                        end
                        if ok and ((not need2D) or (maxX > minX and maxY > minY)) then
                            local r = pool[e.model]
                            if not r then r = allocRec() pool[e.model] = r end
                            r.seen = frame
                            r.vis = true
                            drawn += 1
                            local col = entColor(e, colMode, markTarget)

                            if need2D then
                                local ix = math.floor(minX + 0.5)
                                local iy = math.floor(minY + 0.5)
                                local iw = math.floor((maxX - minX) + 0.5)
                                local ih = math.floor((maxY - minY) + 0.5)
                                local moved = (ix ~= r.lx or iy ~= r.ly or iw ~= r.lw or ih ~= r.lh)
                                local colChanged = (r.lCol ~= col)
                                if moved then
                                    r.lx, r.ly, r.lw, r.lh = ix, iy, iw, ih
                                end
                                if colChanged then r.lCol = col end

                                if r.box.Visible ~= wantBoxes then r.box.Visible, r.outline.Visible = wantBoxes, wantBoxes end
                                if wantBoxes then
                                    if moved then
                                        r.box.Position = UDim2.fromOffset(ix, iy)
                                        r.box.Size = UDim2.fromOffset(iw, ih)
                                        r.outline.Position, r.outline.Size = r.box.Position, r.box.Size
                                    end
                                    if colChanged then r.stroke.Color = col end
                                end

                                if r.name.Visible ~= wantNames then r.name.Visible = wantNames end
                                if wantNames then
                                    if r.lastName ~= e.name then r.name.Text = e.name r.lastName = e.name end
                                    if colChanged then r.name.TextColor3 = col end
                                    if moved then r.name.Position = UDim2.fromOffset(ix + iw * 0.5, iy - 2) end
                                end

                                if r.info.Visible ~= wantInfo then r.info.Visible = wantInfo end
                                if wantInfo then
                                    if now - r.lTextClock >= 0.1 then
                                        r.lTextClock = now
                                        local hpI = math.ceil(e.hum.Health)
                                        local dI = math.floor(e.dist)
                                        if r.lHpI ~= hpI or r.lDistI ~= dI then
                                            r.lHpI, r.lDistI = hpI, dI
                                            r.info.Text = string.format("%d HP  %dm", hpI, dI)
                                        end
                                    end
                                    if colChanged then r.info.TextColor3 = col end
                                    if moved then r.info.Position = UDim2.fromOffset(ix + iw * 0.5, iy + ih + 2) end
                                end

                                if r.hbg.Visible ~= wantHealth then r.hbg.Visible = wantHealth end
                                if wantHealth then
                                    if moved then
                                        r.hbg.Position = UDim2.fromOffset(ix - 6, iy)
                                        r.hbg.Size = UDim2.fromOffset(3, ih)
                                    end
                                    local pct = math.floor(math.clamp(e.hum.Health / math.max(e.hum.MaxHealth, 1), 0, 1) * 100 + 0.5) / 100
                                    if r.lPct ~= pct then
                                        r.lPct = pct
                                        r.hfill.Size = UDim2.fromScale(1, pct)
                                        r.hfill.BackgroundColor3 = Color3.fromRGB(245, 65, 65):Lerp(T.good, pct)
                                    end
                                end
                            elseif r.lNeed2D then
                                r.box.Visible, r.outline.Visible, r.name.Visible, r.info.Visible, r.hbg.Visible = false, false, false, false, false
                            end
                            r.lNeed2D = need2D

                            if r.box3d.Visible ~= wantHit3d then r.box3d.Visible = wantHit3d end
                            if wantHit3d then
                                if r.box3d.Adornee ~= e.root then r.box3d.Adornee = e.root end
                                if r.box3d.Color3 ~= col then r.box3d.Color3 = col end
                            elseif r.box3d.Adornee ~= nil then
                                r.box3d.Adornee = nil
                            end

                            -- Cap Highlights at 8 nearest targets to protect integrated GPU fillrate
                            local useHL = wantHL and hlCount < 8
                            if useHL then
                                hlCount += 1
                                if not r.hl.Enabled then r.hl.Enabled = true end
                                if r.hl.Adornee ~= e.model then r.hl.Adornee = e.model end
                                if r.hl.FillColor ~= col then r.hl.FillColor = col end
                            else
                                if r.hl.Enabled then r.hl.Enabled = false end
                                if r.hl.Adornee ~= nil then r.hl.Adornee = nil end
                            end
                        end
                    end
                end
                for model, r in pairs(pool) do
                    if r.seen ~= frame then
                        hideRec(r)
                    end
                    if not Entities.byModel[model] then
                        hideRec(r)
                        pool[model] = nil
                        if #freePool < 30 then
                            freePool[#freePool + 1] = r
                        else
                            for _, part in ipairs(r.parts) do part:Destroy() end
                        end
                    end
                end
            end)
            maid:give(function() RunService:UnbindFromRenderStep(id) end)
        end,
    })
    ColorOpt = PlayerESP:CreateDropdown({ Name = "Color", List = { "Team", "Red", "Cyan", "White" } })
    NpcRange = PlayerESP:CreateSlider({ Name = "NPC range", Min = 20, Max = 300, Default = 100, Decimal = 1 })
    MaxPlayers = PlayerESP:CreateSlider({ Name = "Max players", Min = 5, Max = 25, Default = 25, Decimal = 1 })
    HighlightOpt = PlayerESP:CreateToggle({ Name = "Highlight", Default = true })
    BoxesOpt = PlayerESP:CreateToggle({ Name = "2D Boxes", Default = false })
    Hitbox3dOpt = PlayerESP:CreateToggle({ Name = "3D Hitbox", Default = false })
    NamesOpt = PlayerESP:CreateToggle({ Name = "Names", Default = true })
    HealthOpt = PlayerESP:CreateToggle({ Name = "Health bar", Default = true })
    InfoOpt = PlayerESP:CreateToggle({ Name = "HP and distance", Default = true })
    TeamOpt = PlayerESP:CreateToggle({ Name = "Teammates", Default = false })
    DummiesOpt = PlayerESP:CreateToggle({ Name = "Dummies", Default = false })
    MarkTargetOpt = PlayerESP:CreateToggle({ Name = "Mark fight target", Default = true })
end

--------------------------------------------------------------------------------
-- VISUAL : Tracers (Free-list Pooled + Dirty-Checked)
--------------------------------------------------------------------------------
do
    local OriginOpt, AnchorOpt, ColorOpt, ThickOpt, RangeOpt, TeamOpt, DummiesOpt, MarkOpt
    local Tracers
    Tracers = vape.Categories.Render:CreateModule({
        Name = "Tracers",
        Tooltip = "Draws directional lines from your screen to enemy players.",
        ExtraText = function() return OriginOpt and OriginOpt.Value or "Bottom" end,
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            Tracers:Clean(function() maid:clean() end)
            local root = make("Frame", { Name = "Tracers", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, OverlayL)
            maid:give(root)
            maid:give(Entities.acquire())
            local pool, freeLines, frame = {}, {}, 0
            local function allocLine()
                if #freeLines > 0 then
                    local rec = table.remove(freeLines)
                    rec.lx, rec.ly, rec.llen, rec.lrot = -1, -1, -1, -999
                    return rec
                end
                local f = make("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, BackgroundTransparency = 0.15, Visible = false }, root)
                return { f = f, lx = -1, ly = -1, llen = -1, lrot = -999 }
            end
            local id = "WrenchHub.Tracers"
            RunService:BindToRenderStep(id, Enum.RenderPriority.Last.Value, function()
                frame += 1
                local c = cam()
                if not c then return end
                local vp = c.ViewportSize
                local center = Vector2.new(vp.X / 2, vp.Y / 2)
                local origin = center
                if OriginOpt.Value == "Bottom" then origin = Vector2.new(vp.X / 2, vp.Y)
                elseif OriginOpt.Value == "Mouse" then origin = UserInputService:GetMouseLocation() end
                local rVal, tVal = RangeOpt.Value, ThickOpt.Value
                local wantTeam, wantDummies = TeamOpt.Enabled, DummiesOpt.Enabled
                local cMode, mTarget, aMode = ColorOpt.Value, MarkOpt.Enabled, AnchorOpt.Value
                for _, e in ipairs(Entities.list) do
                    if e.dist <= rVal and (wantTeam or not e.friendly) and (wantDummies or not e.isDummy) then
                        local part = (aMode == "Head" and e.head) or e.root
                        local wp = part.Position
                        local v = c:WorldToViewportPoint(wp)
                        local pt
                        if v.Z > 0 then
                            pt = Vector2.new(v.X, v.Y)
                        else
                            local rel = c.CFrame:PointToObjectSpace(wp)
                            local dir = Vector2.new(rel.X, -rel.Y)
                            if dir.Magnitude < 1e-3 then dir = Vector2.new(0, 1) end
                            dir = dir.Unit
                            local hx, hy = vp.X / 2 - 20, vp.Y / 2 - 20
                            local k = math.min(hx / math.max(math.abs(dir.X), 1e-3), hy / math.max(math.abs(dir.Y), 1e-3))
                            pt = center + dir * k
                        end
                        local d = pt - origin
                        local len = math.floor(d.Magnitude + 0.5)
                        if len > 2 then
                            local rec = pool[e.model]
                            if not rec then
                                rec = allocLine()
                                pool[e.model] = rec
                            end
                            rec.seen = frame
                            local line = rec.f
                            if not line.Visible then line.Visible = true end
                            local px = math.floor(origin.X + d.X / 2 + 0.5)
                            local py = math.floor(origin.Y + d.Y / 2 + 0.5)
                            local rot = math.floor(math.deg(math.atan2(d.Y, d.X)) * 4 + 0.5) / 4
                            if rec.llen ~= len or rec.lt ~= tVal then
                                rec.llen, rec.lt = len, tVal
                                line.Size = UDim2.fromOffset(len, tVal)
                            end
                            if rec.lx ~= px or rec.ly ~= py then
                                rec.lx, rec.ly = px, py
                                line.Position = UDim2.fromOffset(px, py)
                            end
                            if rec.lrot ~= rot then
                                rec.lrot = rot
                                line.Rotation = rot
                            end
                            local col = entColor(e, cMode, mTarget)
                            if line.BackgroundColor3 ~= col then line.BackgroundColor3 = col end
                        end
                    end
                end
                for model, rec in pairs(pool) do
                    if rec.seen ~= frame and rec.f.Visible then rec.f.Visible = false end
                    if not Entities.byModel[model] then
                        rec.f.Visible = false
                        pool[model] = nil
                        if #freeLines < 25 then
                            freeLines[#freeLines + 1] = rec
                        else
                            rec.f:Destroy()
                        end
                    end
                end
            end)
            maid:give(function() RunService:UnbindFromRenderStep(id) end)
        end,
    })
    OriginOpt = Tracers:CreateDropdown({ Name = "Origin", List = { "Bottom", "Center", "Mouse" } })
    AnchorOpt = Tracers:CreateDropdown({ Name = "Aim at", List = { "Body", "Head" } })
    ColorOpt = Tracers:CreateDropdown({ Name = "Color", List = { "Team", "Red", "Cyan", "White" } })
    ThickOpt = Tracers:CreateSlider({ Name = "Thickness", Min = 1, Max = 4, Default = 1.5, Decimal = 10 })
    RangeOpt = Tracers:CreateSlider({ Name = "Range", Min = 50, Max = 500, Default = 300, Decimal = 1 })
    TeamOpt = Tracers:CreateToggle({ Name = "Teammates", Default = false })
    DummiesOpt = Tracers:CreateToggle({ Name = "Dummies", Default = false })
    MarkOpt = Tracers:CreateToggle({ Name = "Mark fight target", Default = true })
end

--------------------------------------------------------------------------------
-- VISUAL : Enhanced Pistonware Target Info (Kit Badge + 5x18x18 Icons + Far Aim)
--------------------------------------------------------------------------------
do
    local TargetInfoOverlay = vape.Categories["Target Info"]
    local FightRange = TargetInfoOverlay:CreateSlider({ Name = "Fight range", Min = 8, Max = 30, Default = 18, Decimal = 1 })
    local FarAimOpt = TargetInfoOverlay:CreateToggle({ Name = "Far aim detect", Default = true })
    local AimRange = TargetInfoOverlay:CreateSlider({ Name = "Aim range", Min = 30, Max = 300, Default = 220, Decimal = 1 })
    local AimFOV = TargetInfoOverlay:CreateSlider({ Name = "Aim FOV", Min = 5, Max = 60, Default = 30, Decimal = 1 })
    local HideDelay = TargetInfoOverlay:CreateSlider({ Name = "Hide delay", Min = 1, Max = 8, Default = 3, Decimal = 10, Suffix = "s" })
    local RangedOnly = TargetInfoOverlay:CreateToggle({ Name = "Ranged weapon only", Default = false })
    local DummiesOpt = TargetInfoOverlay:CreateToggle({ Name = "Dummies and NPCs", Default = true })

    shared.PistonwareTargetExtras = function(entity)
        local model = entity and entity.Character
        if not model then return nil, nil end
        local kImg = (not entity.IsDummy) and kitImage(entity.Player, model) or nil
        local armor, held = readLoadout(model, entity.IsDummy)
        local enchImg = enchantImage(model)
        local imgs = {}
        if held then
            local hi = itemImage(held, model)
            if hi then imgs[#imgs + 1] = hi end
        end
        for _, slot in ipairs(Config.Resolver.ArmorOrder) do
            if armor[slot] then
                local ai = itemImage(armor[slot], model)
                if ai then imgs[#imgs + 1] = ai end
            end
        end
        if enchImg and #imgs < 5 then imgs[#imgs + 1] = enchImg end
        return kImg, imgs
    end

    local tiCache = setmetatable({}, { __mode = "k" })
    local function getTiEntry(e)
        local entry = tiCache[e.model]
        if not entry then
            entry = {
                Player = e.player,
                Character = e.model,
                IsDummy = e.isDummy,
                HipHeight = e.hum and e.hum.HipHeight or 2,
            }
            tiCache[e.model] = entry
        end
        entry.Player = e.player
        entry.RootPart = e.root
        entry.Head = e.head
        entry.Health = e.hum and e.hum.Health or 0
        entry.MaxHealth = e.hum and e.hum.MaxHealth or 100
        return entry
    end

    local hpMem = setmetatable({}, { __mode = "k" })
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    local cur, myHp = nil, nil
    local releaseEntities = nil

    CoreMaid:give(RunService.RenderStepped:Connect(function()
        local enabled = TargetInfoOverlay.Button and TargetInfoOverlay.Button.Enabled
        if not enabled then
            if releaseEntities then releaseEntities() releaseEntities = nil end
            TargetState.model = nil
            cur = nil
            return
        end
        if not releaseEntities then releaseEntities = Entities.acquire() end

        local targetinfo = vape.Libraries.targetinfo
        if not targetinfo then return end
        local now = os.clock()
        local tickNow = tick()
        local c = cam()
        if not c then return end
        local myChar = LP.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local look, origin = c.CFrame.LookVector, c.CFrame.Position
        local holdingRanged = (not RangedOnly.Enabled) or isRangedWeapon(heldName(myChar))
        local fRange, aRange, aFov = FightRange.Value, AimRange.Value, AimFOV.Value
        local allowDummies = DummiesOpt.Enabled

        local hit, hitD, aim, aimAng = nil, math.huge, nil, math.huge
        for _, e in ipairs(Entities.list) do
            local hp = e.hum.Health
            local prev = hpMem[e.hum]
            hpMem[e.hum] = hp
            if myRoot and not e.friendly and (allowDummies or not e.isDummy) then
                local d = e.dist
                if prev and hp < prev - 0.01 and d <= fRange then
                    local to = e.root.Position - myRoot.Position
                    if d <= 7 or (to.Magnitude > 0 and to.Unit:Dot(look) > 0.35) then
                        if d < hitD then hit, hitD = e, d end
                    end
                elseif FarAimOpt.Enabled and holdingRanged and d <= aRange then
                    local aimPos = e.head and e.head.Position or (e.root.Position + Vector3.new(0, 1.5, 0))
                    local to = aimPos - origin
                    if to.Magnitude > 0 then
                        local ang = math.deg(math.acos(math.clamp(look:Dot(to.Unit), -1, 1)))
                        if ang <= (aFov / 2) and ang < aimAng then
                            rp.FilterDescendantsInstances = { myChar, e.model, c }
                            local hitRes = workspace:Raycast(origin, aimPos - origin, rp)
                            if not hitRes or not hitRes.Instance.CanCollide or hitRes.Instance.Transparency >= 0.9 then
                                aim, aimAng = e, ang
                            end
                        end
                    end
                end
            end
        end

        local myHpNow = myHum and myHum.Health
        if myHpNow and myHp and myHpNow < myHp - 0.01 and not hit and myRoot then
            local best, bd = nil, 14
            for _, e in ipairs(Entities.list) do
                if not e.friendly and not e.isDummy and e.dist <= bd then
                    local to = myRoot.Position - e.root.Position
                    if to.Magnitude > 0 and e.root.CFrame.LookVector:Dot(to.Unit) > 0.5 then best, bd = e, e.dist end
                end
            end
            hit = best
        end
        myHp = myHpNow

        local forced = false
        local L = Targeting.last
        if L and now - L.t < 0.5 then
            local fe = Entities.byModel[L.model]
            if fe and not fe.friendly then hit, forced = fe, true end
        end

        if hit then
            if (not cur) or forced or cur.model == hit.model or cur.soft or now - cur.lastHard > 0.8 then
                local entry = getTiEntry(hit)
                cur = {
                    model = hit.model, hum = hit.hum, entry = entry,
                    soft = false, lastHard = now, expiry = now + HideDelay.Value, deadAt = nil,
                }
            end
        elseif aim then
            if (not cur) or cur.soft then
                local entry = getTiEntry(aim)
                cur = {
                    model = aim.model, hum = aim.hum, entry = entry,
                    soft = true, lastHard = (cur and cur.lastHard) or 0, expiry = now + 1.5, deadAt = nil,
                }
            end
        end

        if cur then
            local e = Entities.byModel[cur.model]
            if isBlockedModel(cur.model) then
                cur = nil
            else
                if e then
                    getTiEntry(e)
                elseif cur.hum then
                    cur.entry.Health = math.max(cur.hum.Health, 0)
                end
                if cur.hum.Health <= 0 and not cur.deadAt then
                    cur.deadAt = now
                    cur.expiry = now + 1.2
                end
                local maxDist = cur.soft and (aRange * 1.2) or (fRange * 1.5)
                if (not e and not cur.deadAt) or now > cur.expiry or (e and e.dist > maxDist) then
                    cur = nil
                end
            end
        end

        TargetState.model = cur and cur.model or nil
        if cur and cur.entry then
            targetinfo.Targets[cur.entry] = tickNow + 0.25
        end
    end))
end

--------------------------------------------------------------------------------
-- VISUAL : Block ESP
--------------------------------------------------------------------------------
do
    local RangeOpt, BedsOpt, LuckyOpt, TrapsOpt, OresOpt
    local BlockESP
    BlockESP = vape.Categories.Render:CreateModule({
        Name = "Block ESP",
        Tooltip = "Highlights Beds, Lucky Blocks, Traps, and Iron Ores through walls.",
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            BlockESP:Clean(function() maid:clean() end)
            local hlFolder = make("Folder", { Name = "WrenchHub_BlockESP" }, OverlayL)
            maid:give(hlFolder)
            local tracked = {}
            local optMap = {
                beds = function() return BedsOpt.Enabled end,
                lucky = function() return LuckyOpt.Enabled end,
                traps = function() return TrapsOpt.Enabled end,
                ores = function() return OresOpt.Enabled end,
            }
            local BLOCK_DEFS = {
                { tag = "bed", opt = "beds", col = Color3.fromRGB(235, 65, 65) },
                { tag = "LuckyBlock", opt = "lucky", col = Color3.fromRGB(245, 200, 45) },
                { tag = "tesla-trap", opt = "traps", col = Color3.fromRGB(165, 85, 245) },
                { tag = "beehive", opt = "traps", col = Color3.fromRGB(245, 165, 45) },
                { tag = "iron_ore_mesh_block", opt = "ores", col = Color3.fromRGB(205, 210, 220) },
            }
            local function addObj(inst, def)
                if tracked[inst] or not inst:IsDescendantOf(workspace) then return end
                local hl = Instance.new("Highlight")
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0.1
                hl.FillColor = def.col
                hl.OutlineColor = def.col
                hl.Adornee = inst
                hl.Enabled = false
                hl.Parent = hlFolder
                tracked[inst] = { hl = hl, def = def }
            end
            for _, def in ipairs(BLOCK_DEFS) do
                for _, inst in ipairs(CollectionService:GetTagged(def.tag)) do addObj(inst, def) end
                maid:give(CollectionService:GetInstanceAddedSignal(def.tag):Connect(function(inst) addObj(inst, def) end))
                maid:give(CollectionService:GetInstanceRemovedSignal(def.tag):Connect(function(inst)
                    local rec = tracked[inst]
                    if rec then rec.hl:Destroy() tracked[inst] = nil end
                end))
            end
            local acc = 0
            maid:give(RunService.Heartbeat:Connect(function(dt)
                acc += dt
                if acc < 0.25 then return end
                acc = 0
                local ch = LP.Character
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                local myPos = root and root.Position
                local activeCount, rVal = 0, RangeOpt.Value
                for inst, rec in pairs(tracked) do
                    if not inst.Parent then
                        rec.hl:Destroy()
                        tracked[inst] = nil
                    else
                        local show = optMap[rec.def.opt]() and activeCount < 16
                        if show and myPos then
                            local pos = inst:IsA("BasePart") and inst.Position or inst:GetPivot().Position
                            if (pos - myPos).Magnitude > rVal then show = false end
                        end
                        if show then activeCount += 1 end
                        if rec.hl.Enabled ~= show then rec.hl.Enabled = show end
                    end
                end
            end))
        end,
    })
    RangeOpt = BlockESP:CreateSlider({ Name = "Range", Min = 30, Max = 500, Default = 220, Decimal = 1 })
    BedsOpt = BlockESP:CreateToggle({ Name = "Beds", Default = true })
    LuckyOpt = BlockESP:CreateToggle({ Name = "Lucky Blocks", Default = true })
    TrapsOpt = BlockESP:CreateToggle({ Name = "Traps", Default = true })
    OresOpt = BlockESP:CreateToggle({ Name = "Iron Ore", Default = false })
end

--------------------------------------------------------------------------------
-- VISUAL : Fullbright (Event-driven, zero per-frame Lighting spam)
--------------------------------------------------------------------------------
do
    local Fullbright
    Fullbright = vape.Categories.Render:CreateModule({
        Name = "Fullbright",
        Tooltip = "Removes darkness and fog across the entire map.",
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            Fullbright:Clean(function() maid:clean() end)
            local saved = {
                Brightness = Lighting.Brightness,
                FogEnd = Lighting.FogEnd,
                GlobalShadows = Lighting.GlobalShadows,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
            }
            local targetAmb = Color3.fromRGB(178, 178, 178)
            local applying = false
            local function apply()
                if applying then return end
                applying = true
                if Lighting.Brightness ~= 2 then Lighting.Brightness = 2 end
                if Lighting.FogEnd ~= 1e5 then Lighting.FogEnd = 1e5 end
                if Lighting.GlobalShadows ~= false then Lighting.GlobalShadows = false end
                if Lighting.Ambient ~= targetAmb then Lighting.Ambient = targetAmb end
                if Lighting.OutdoorAmbient ~= targetAmb then Lighting.OutdoorAmbient = targetAmb end
                applying = false
            end
            apply()
            for prop in pairs(saved) do
                maid:give(Lighting:GetPropertyChangedSignal(prop):Connect(apply))
            end
            maid:give(function()
                applying = true
                for k, v in pairs(saved) do pcall(function() Lighting[k] = v end) end
                applying = false
            end)
        end,
    })
end

--------------------------------------------------------------------------------
-- VISUAL : FPS Boost (Weak-keyed savedProps so debris/VFX never leak RAM)
--------------------------------------------------------------------------------
do
    local LightsOpt, ExplosionsOpt, EffectsOpt, BlocksOpt, PotatoOpt, MemfixOpt, HideNametagsOpt, KillEffectsOpt
    local FPSBoost
    FPSBoost = vape.Categories.Render:CreateModule({
        Name = "FPS Boost",
        Tooltip = "Simplifies blocks cleanly (preserves beds/chests/lucky blocks) and disables heavy VFX/connections.",
        Function = function(callback)
            if not callback then return end
            local maid = Maid()
            FPSBoost:Clean(function() maid:clean() end)
            local savedProps = setmetatable({}, { __mode = "k" })
            local function getInstProp(inst, prop) return inst[prop] end
            local function setInstProp(inst, prop, val) inst[prop] = val end
            local function saveProp(inst, prop, newVal)
                local ok, curVal = pcall(getInstProp, inst, prop)
                if ok and curVal ~= newVal then
                    local rec = savedProps[inst]
                    if not rec then
                        rec = {}
                        savedProps[inst] = rec
                    end
                    if rec[prop] == nil then rec[prop] = curVal end
                    pcall(setInstProp, inst, prop, newVal)
                end
            end
            local mapFolder = workspace:FindFirstChild("Map")
            local function optimizeInst(inst)
                if not inst or not inst.Parent then return end
                if inst:IsA("Light") and LightsOpt.Enabled then
                    saveProp(inst, "Enabled", false)
                elseif inst:IsA("Explosion") and ExplosionsOpt.Enabled then
                    saveProp(inst, "Visible", false)
                elseif (inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")) and EffectsOpt.Enabled then
                    if not inst:GetAttribute("WrenchHubSelf") then
                        saveProp(inst, "Enabled", false)
                    end
                elseif BlocksOpt.Enabled and mapFolder and inst:IsDescendantOf(mapFolder) then
                    if inst:IsA("BasePart") then
                        saveProp(inst, "Reflectance", 0)
                        saveProp(inst, "CastShadow", false)
                        if PotatoOpt.Enabled and inst:IsA("MeshPart") then
                            saveProp(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
                        end
                        local flatCol = BlockColors[inst.Name]
                        if flatCol then
                            saveProp(inst, "MaterialVariant", "")
                            saveProp(inst, "Material", Enum.Material.SmoothPlastic)
                            saveProp(inst, "Color", flatCol)
                        end
                    elseif (inst:IsA("Texture") or inst:IsA("Decal")) and inst.Parent and BlockColors[inst.Parent.Name] then
                        saveProp(inst, "Transparency", 1)
                    end
                elseif HideNametagsOpt.Enabled and inst:IsA("BillboardGui") and not inst:IsDescendantOf(OverlayGui) then
                    local p = inst.Parent
                    if p and (p.Name == "Head" or p.Name == "HumanoidRootPart" or (p.Parent and p.Parent:FindFirstChildOfClass("Humanoid"))) then
                        saveProp(inst, "Enabled", false)
                    end
                end
            end
            for _, d in ipairs(workspace:GetDescendants()) do optimizeInst(d) end
            maid:give(workspace.DescendantAdded:Connect(optimizeInst))

            local disabledConns = {}
            if MemfixOpt.Enabled and type(getconnections) == "function" then
                local signals = { RunService.Heartbeat, RunService.PreSimulation, RunService.RenderStepped, RunService.Stepped }
                for _, sig in ipairs(signals) do
                    local ok, conns = pcall(getconnections, sig)
                    if ok and conns then
                        for _, conn in ipairs(conns) do
                            if type(conn.Function) == "function" then
                                local iok, src = pcall(function() return debug.getinfo(conn.Function).source end)
                                if iok and type(src) == "string" then
                                    local ls = src:lower():gsub("-", "_")
                                    for _, targetName in ipairs(LagEffects) do
                                        if ls:find(targetName:lower():gsub("-", "_"), 1, true) then
                                            pcall(function() conn:Disable() end)
                                            disabledConns[#disabledConns + 1] = conn
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            local savedKillEffects, savedViz = {}, {}
            if KillEffectsOpt.Enabled and type(_G.bedwars) == "table" then
                pcall(function()
                    local kec = _G.bedwars.KillEffectController
                    if kec and type(kec.killEffects) == "table" then
                        for k, v in pairs(kec.killEffects) do
                            if not tostring(k):find("Custom") then
                                savedKillEffects[k] = v
                                kec.killEffects[k] = { new = function() return { onKill = function() end, isPlayDefaultKillEffect = function() return true end } end }
                            end
                        end
                    end
                    local viz = _G.bedwars.VisualizerUtils
                    if type(viz) == "table" then
                        for k, v in pairs(viz) do savedViz[k] = v viz[k] = function() end end
                    end
                end)
            end

            maid:give(function()
                for inst, props in pairs(savedProps) do
                    if inst and inst.Parent then
                        for p, v in pairs(props) do pcall(function() inst[p] = v end) end
                    end
                end
                for _, conn in ipairs(disabledConns) do pcall(function() conn:Enable() end) end
                if type(_G.bedwars) == "table" then
                    pcall(function()
                        local kec = _G.bedwars.KillEffectController
                        if kec and type(kec.killEffects) == "table" then
                            for k, v in pairs(savedKillEffects) do kec.killEffects[k] = v end
                        end
                        local viz = _G.bedwars.VisualizerUtils
                        if type(viz) == "table" then
                            for k, v in pairs(savedViz) do viz[k] = v end
                        end
                    end)
                end
            end)
        end,
    })
    LightsOpt = FPSBoost:CreateToggle({ Name = "Remove lights", Default = true })
    ExplosionsOpt = FPSBoost:CreateToggle({ Name = "Remove explosions", Default = true })
    EffectsOpt = FPSBoost:CreateToggle({ Name = "Remove particles", Default = true })
    BlocksOpt = FPSBoost:CreateToggle({ Name = "Simplify blocks", Default = true })
    PotatoOpt = FPSBoost:CreateToggle({ Name = "Potato mode", Default = false })
    MemfixOpt = FPSBoost:CreateToggle({ Name = "Disable lag conns", Default = true })
    HideNametagsOpt = FPSBoost:CreateToggle({ Name = "Hide game nametags", Default = false })
    KillEffectsOpt = FPSBoost:CreateToggle({ Name = "Disable kill effects", Default = true })
end

--------------------------------------------------------------------------------
-- VISUAL OVERLAYS : Stats & Keystrokes (Pinned / Draggable via Pistonware UI)
--------------------------------------------------------------------------------
local StatsOverlay
do
    local FpsOpt, PingOpt, MemOpt, TransOpt, ScaleOpt
    local cardFrame, statsLabel, statsScale
    StatsOverlay = vape:CreateOverlay({
        Name = "Stats",
        Tooltip = "Displays FPS, Ping, and Memory usage.",
        CategorySize = 190,
        Function = function(callback)
            if not callback then return end
            local frames, acc = 0, 0
            StatsOverlay:Clean(RunService.RenderStepped:Connect(function(dt)
                frames += 1
                acc += dt
                if acc < 0.45 then return end
                local fps = math.floor(frames / acc + 0.5)
                frames, acc = 0, 0
                local lines = {}
                if FpsOpt.Enabled then lines[#lines + 1] = "FPS   " .. fps end
                if PingOpt.Enabled then
                    local ok, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                    if ok and v then lines[#lines + 1] = string.format("PING  %dms", math.floor(v + 0.5)) end
                end
                if MemOpt.Enabled then
                    lines[#lines + 1] = string.format("MEM   %dMB", math.floor(StatsService:GetTotalMemoryUsageMb() + 0.5))
                end
                if statsLabel then
                    statsLabel.Text = #lines > 0 and table.concat(lines, "\n") or "No stats"
                    if cardFrame then
                        cardFrame.Size = UDim2.fromOffset(190, math.max(#lines, 1) * 20 + 16)
                    end
                end
            end))
        end,
    })
    statsScale = Instance.new("UIScale")
    statsScale.Name = "StatsScale"
    statsScale.Scale = 1.3
    statsScale.Parent = StatsOverlay.Children
    cardFrame = make("Frame", {
        Active = true,
        BackgroundColor3 = T.cardBg,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(190, 76),
    }, StatsOverlay.Children)
    corner(cardFrame, 12)
    make("UIStroke", { Color = T.white, Thickness = 1, Transparency = 0.9 }, cardFrame)
    statsLabel = textLabel(cardFrame, "FPS   --\nPING  --\nMEM   --", 16, Color3.fromRGB(240, 240, 240), Left, UDim2.fromOffset(12, 8), UDim2.new(1, -24, 1, -16))
    statsLabel.TextYAlignment = Enum.TextYAlignment.Top
    statsLabel.TextTruncate = Enum.TextTruncate.None

    FpsOpt = StatsOverlay:CreateToggle({ Name = "FPS", Default = true })
    PingOpt = StatsOverlay:CreateToggle({ Name = "Ping", Default = true })
    MemOpt = StatsOverlay:CreateToggle({ Name = "Memory", Default = true })
    ScaleOpt = StatsOverlay:CreateSlider({
        Name = "Scale",
        Min = 0.8,
        Max = 2,
        Default = 1.3,
        Decimal = 20,
        Function = function(val)
            if statsScale then statsScale.Scale = val end
        end,
    })
    TransOpt = StatsOverlay:CreateSlider({
        Name = "Transparency",
        Min = 0,
        Max = 0.9,
        Default = 0.15,
        Decimal = 100,
        Function = function(val)
            if cardFrame then cardFrame.BackgroundTransparency = val end
        end,
    })
end

local KeystrokesOverlay
do
    local StyleOpt, SpaceOpt, ScaleOpt
    local KeyDefs = {
        { Enum.KeyCode.W, "W", "↑", 48, 0, 44, 44 },
        { Enum.KeyCode.A, "A", "←", 0, 48, 44, 44 },
        { Enum.KeyCode.S, "S", "↓", 48, 48, 44, 44 },
        { Enum.KeyCode.D, "D", "→", 96, 48, 44, 44 },
        { Enum.KeyCode.Space, "SPACE", "SPACE", 0, 96, 140, 32 },
    }
    local keyBoxes = {}
    KeystrokesOverlay = vape:CreateOverlay({
        Name = "Keystrokes",
        Tooltip = "Shows WASD and Spacebar key presses on screen.",
        CategorySize = 140,
        Function = function(callback)
            if not callback then return end
            local anims, prev = {}, {}
            for i, _ in ipairs(KeyDefs) do
                prev[i] = false
                local f = keyBoxes[i].frame
                anims[i] = Anim.new(0, 28, function(v)
                    local accent = Color3.fromHSV(vape.GUIColor.Hue, vape.GUIColor.Sat, vape.GUIColor.Value)
                    f.BackgroundColor3 = T.cardBg:Lerp(accent, v)
                end)
            end
            KeystrokesOverlay:Clean(RunService.RenderStepped:Connect(function()
                for i, d in ipairs(KeyDefs) do
                    local down = UserInputService:IsKeyDown(d[1])
                    if down ~= prev[i] then
                        prev[i] = down
                        anims[i].to(down and 1 or 0)
                    end
                end
            end))
        end,
    })
    local keyScale = Instance.new("UIScale")
    keyScale.Name = "KeystrokesScale"
    keyScale.Scale = 1.35
    keyScale.Parent = KeystrokesOverlay.Children
    local holder = make("Frame", {
        Active = true,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(140, 128),
    }, KeystrokesOverlay.Children)
    for i, d in ipairs(KeyDefs) do
        local f = make("Frame", {
            Position = UDim2.fromOffset(d[4], d[5]),
            Size = UDim2.fromOffset(d[6], d[7]),
            BackgroundColor3 = T.cardBg,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
        }, holder)
        corner(f, 9)
        make("UIStroke", { Color = T.white, Thickness = 1, Transparency = 0.9 }, f)
        local lbl = textLabel(f, d[2], 16, Color3.fromRGB(240, 240, 240), Center)
        keyBoxes[i] = { frame = f, label = lbl }
    end
    StyleOpt = KeystrokesOverlay:CreateDropdown({
        Name = "Key Style",
        List = { "Keyboard", "Arrow" },
        Function = function(val)
            local arrow = (val == "Arrow")
            for i, d in ipairs(KeyDefs) do
                keyBoxes[i].label.Text = arrow and d[3] or d[2]
            end
        end,
    })
    ScaleOpt = KeystrokesOverlay:CreateSlider({
        Name = "Scale",
        Min = 0.8,
        Max = 2,
        Default = 1.35,
        Decimal = 20,
        Function = function(val)
            if keyScale then keyScale.Scale = val end
        end,
    })
    SpaceOpt = KeystrokesOverlay:CreateToggle({
        Name = "Show Spacebar",
        Default = true,
        Function = function(val)
            keyBoxes[5].frame.Visible = val
            holder.Size = UDim2.fromOffset(140, val and 128 or 92)
        end,
    })
end

for _, ov in { vape.Categories["Target Info"], StatsOverlay, KeystrokesOverlay } do
    if ov and not ov.Pinned then
        ov:Pin()
        ov:Update()
    end
end

--------------------------------------------------------------------------------
-- Core Loop + Lifecycle + Persistence
--------------------------------------------------------------------------------
local function UnloadAll()
    if shared.vape then
        pcall(function() shared.vape:Uninject() end)
    end
end

vape:Clean(function()
    SilentAimState.active = false
    SilentAimState.targetPos = nil
    pcall(function() RunService:UnbindFromRenderStep("WrenchHub.Core") end)
    pcall(function() CoreMaid:clean() end)
    pcall(function() OverlayGui:Destroy() end)
    shared.PistonwareTargetExtras = nil
    env.__WrenchHub = nil
end)

RunService:BindToRenderStep("WrenchHub.Core", Enum.RenderPriority.First.Value, function(dt)
    dt = math.min(dt, 0.1)
    if Entities.refs > 0 then Entities.rebuild() end
    stepAnims(dt)
end)

CoreMaid:give(Players.PlayerRemoving:Connect(function(p)
    if p == LP and vape and vape.CanSave and vape:CanSave() then
        pcall(function() vape:Save() end)
    end
end))
pcall(function()
    game:BindToClose(function()
        if vape and vape.CanSave and vape:CanSave() then
            pcall(function() vape:Save() end)
        end
    end)
end)

pcall(function() vape:Load() end)
vape.Loaded = true
if vape.AllowSaving then vape:AllowSaving() else vape.SaveBlocked = nil end

env.__WrenchHub = { Unload = UnloadAll, Notify = Notify, Vape = vape }
pcall(function()
    local keys = vape.GUIBind and vape.GUIBind.Keys
    local how = (keys and #keys > 0) and ("Press " .. table.concat(keys, " + "):upper() .. " to open GUI") or "Press RIGHTSHIFT to open GUI"
    vape:CreateNotification("WrenchHub | Loaded", how, 5)
end)
print("[WrenchHub x Pistonware Modular] loaded (" .. tostring(ctx.BuildId) .. "). RightShift opens the menu.")
