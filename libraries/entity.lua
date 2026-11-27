--[[
    libraries/entity.lua — Entity Scanner, Petrified Statue Filter, Maid, Anim, Targeting
]]
local ctx = ...
local Players = ctx.Players
local CollectionService = ctx.CollectionService
local LP = ctx.LP
local cam = ctx.cam
local vape = ctx.vape
local CoreMaid = ctx.CoreMaid
local T = ctx.T

local function Maid()
    local m = { tasks = {} }
    function m:give(x)
        if x ~= nil then table.insert(self.tasks, x) end
        return x
    end
    function m:clean()
        for i = #self.tasks, 1, -1 do
            local t = self.tasks[i]
            self.tasks[i] = nil
            local ty = typeof(t)
            if ty == "RBXScriptConnection" then pcall(function() t:Disconnect() end)
            elseif ty == "Instance" then pcall(function() t:Destroy() end)
            elseif ty == "function" then pcall(t) end
        end
    end
    return m
end

local Anim = { live = {} }
local function mix(a, b, k)
    if type(a) == "number" then return a + (b - a) * k end
    return a:Lerp(b, k)
end
local function near(a, b)
    if type(a) == "number" then return math.abs(a - b) < 5e-4 end
    return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 2e-3
end
function Anim.new(initial, rate, apply)
    local s = { value = initial, target = initial, rate = rate }
    function s.to(t, instant)
        s.target = t
        if instant then
            s.value = t
            Anim.live[s] = nil
            apply(t)
        else
            Anim.live[s] = apply
        end
    end
    apply(initial)
    return s
end
local function stepAnims(dt)
    for s, apply in pairs(Anim.live) do
        s.value = mix(s.value, s.target, 1 - math.exp(-s.rate * dt))
        if near(s.value, s.target) then
            s.value = s.target
            Anim.live[s] = nil
        end
        apply(s.value)
    end
end

local Entities = { refs = 0, list = {}, byModel = {} }
local npcRegistry = setmetatable({}, { __mode = "k" })
local blockedCache = setmetatable({}, { __mode = "k" })
local deadHumCache = setmetatable({}, { __mode = "k" })

local SHOP_KEYWORDS = {
    "merchant", "shop", "florist", "blacksmith", "vendor",
    "store", "guide", "banker", "teller", "upgrade",
}

local function isPetrifiedStatueSlow(model)
    local curInst = model
    while curInst and curInst ~= workspace do
        if curInst:GetAttribute("PetrifyId") ~= nil then return true end
        local okTag, tagged = pcall(CollectionService.HasTag, CollectionService, curInst, "petrified-player")
        if okTag and tagged then return true end
        if curInst.Name:lower():find("petrif", 1, true) then return true end
        curInst = curInst.Parent
    end
    for _, ch in ipairs(model:GetChildren()) do
        if ch:GetAttribute("PetrifyId") ~= nil then return true end
    end
    local par = model.Parent
    if par and par ~= workspace and par:IsA("Model") and par:FindFirstChildWhichIsA("ProximityPrompt", true) then
        return true
    end
    return false
end

local function isBlockedModel(model)
    if not model or not model.Parent or not model:IsA("Model") then return true end
    local myChar = LP.Character
    if myChar and (model == myChar or model:IsDescendantOf(myChar)) then return true end

    local cached = blockedCache[model]
    if cached == true then
        return true
    elseif cached == "petrify" then
        if model:GetAttribute("PetrifyId") ~= nil then return true end
        local okTag, tagged = pcall(CollectionService.HasTag, CollectionService, model, "petrified-player")
        if okTag and tagged then return true end
        blockedCache[model] = nil
    elseif cached == false then
        -- Fast O(1) runtime invalidation check if statue attribute replicates late
        if model:GetAttribute("PetrifyId") ~= nil then
            blockedCache[model] = "petrify"
            return true
        end
        return false
    end

    if isPetrifiedStatueSlow(model) then
        blockedCache[model] = "petrify"
        return true
    end

    local blocked = false
    local c = cam()
    if c and model:IsDescendantOf(c) then blocked = true end
    if not blocked then
        local nl = model.Name:lower()
        if nl:find("viewmodel", 1, true) or nl:find("arms", 1, true) or nl:find("hand", 1, true) then
            blocked = true
        elseif not Players:GetPlayerFromCharacter(model) then
            for _, kw in ipairs(SHOP_KEYWORDS) do
                if nl:find(kw, 1, true) then blocked = true break end
            end
            if not blocked and model:FindFirstChildWhichIsA("ProximityPrompt", true) then
                blocked = true
            end
        end
    end
    blockedCache[model] = blocked
    return blocked
end

local function markStatueSubtree(inst, flag)
    if not inst then return end
    local mark = flag or true
    blockedCache[inst] = mark
    local mdl = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
    if mdl then
        blockedCache[mdl] = mark
        local h = mdl:FindFirstChildOfClass("Humanoid")
        if h then npcRegistry[h] = nil end
    end
    for _, sub in ipairs(inst:GetDescendants()) do
        if sub:IsA("Humanoid") then
            npcRegistry[sub] = nil
            if sub.Parent then blockedCache[sub.Parent] = mark end
        end
    end
end

local function clearPetrifySubtree(inst)
    if not inst then return end
    if blockedCache[inst] == "petrify" then blockedCache[inst] = nil end
    local mdl = inst:IsA("Model") and inst or inst:FindFirstAncestorOfClass("Model")
    if mdl and blockedCache[mdl] == "petrify" then blockedCache[mdl] = nil end
    for _, sub in ipairs(inst:GetDescendants()) do
        if sub.Parent and blockedCache[sub.Parent] == "petrify" then blockedCache[sub.Parent] = nil end
    end
end

local function registerNpc(model, kind)
    if not model or not model:IsA("Model") or Players:GetPlayerFromCharacter(model) then return end
    if isBlockedModel(model) then return end
    task.spawn(function()
        local h = model:FindFirstChildOfClass("Humanoid") or model:WaitForChild("Humanoid", 2)
        if h and h:IsA("Humanoid") and not npcRegistry[h] and not isBlockedModel(model) then
            npcRegistry[h] = kind
        end
    end)
end

local function trackWorkspaceEntity(inst)
    if inst:IsA("ProximityPrompt") then
        local mdl = inst:FindFirstAncestorOfClass("Model")
        if mdl and not Players:GetPlayerFromCharacter(mdl) then
            markStatueSubtree(mdl, true)
        end
        return
    end
    if not inst:IsA("Humanoid") then return end
    local model = inst.Parent
    if model and model:IsA("Model") and not Players:GetPlayerFromCharacter(model) and not isBlockedModel(model) then
        if model.Name:lower():find("dummy", 1, true) then
            npcRegistry[inst] = "dummy"
        end
    end
end

for _, d in ipairs(workspace:GetDescendants()) do trackWorkspaceEntity(d) end
CoreMaid:give(workspace.DescendantAdded:Connect(trackWorkspaceEntity))
CoreMaid:give(workspace.DescendantRemoving:Connect(function(d)
    npcRegistry[d] = nil
    deadHumCache[d] = nil
end))
for _, inst in ipairs(CollectionService:GetTagged("petrified-player")) do
    markStatueSubtree(inst, "petrify")
end
CoreMaid:give(CollectionService:GetInstanceAddedSignal("petrified-player"):Connect(function(inst)
    markStatueSubtree(inst, "petrify")
end))
CoreMaid:give(CollectionService:GetInstanceRemovedSignal("petrified-player"):Connect(clearPetrifySubtree))

local BEDWARS_TAGS = { "Monster", "DiamondGuardian", "GolemBoss", "Drone", "Mob", "NPC", "Enemy", "monster", "mob", "npc", "enemy" }
for _, tag in ipairs(BEDWARS_TAGS) do
    for _, inst in ipairs(CollectionService:GetTagged(tag)) do registerNpc(inst, "npc") end
    CoreMaid:give(CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst) registerNpc(inst, "npc") end))
end
local function hookNpcFolder(f)
    if not f then return end
    for _, ch in ipairs(f:GetChildren()) do registerNpc(ch, "npc") end
    CoreMaid:give(f.ChildAdded:Connect(function(ch) registerNpc(ch, "npc") end))
end
for _, folderName in ipairs({ "NPCs", "Mobs" }) do
    hookNpcFolder(workspace:FindFirstChild(folderName))
end
CoreMaid:give(workspace.ChildAdded:Connect(function(ch)
    if ch.Name == "NPCs" or ch.Name == "Mobs" then hookNpcFolder(ch) end
end))

function Entities.acquire()
    Entities.refs += 1
    local released = false
    return function()
        if not released then released = true Entities.refs -= 1 end
    end
end

function Entities.rebuild()
    local list, by = {}, {}
    local myChar = LP.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local mp = myRoot and myRoot.Position
    local myTeam = LP.Team
    local myTeamAttr = LP:GetAttribute("Team")
    local teamsOpt = vape.Categories and vape.Categories.Main and vape.Categories.Main.Options and vape.Categories.Main.Options["Teams by server"]
    local checkTeams = (teamsOpt == nil) or teamsOpt.Enabled

    local function push(model, hum, root, name, player, color, friendly, dummy, npc)
        local pos = root.Position
        if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z then return end
        local head = model:FindFirstChild("Head")
        local invis = (head and head:IsA("BasePart") and head.Transparency >= 0.99) or false
        local e = {
            model = model, hum = hum, root = root, head = head,
            name = name, player = player, color = color,
            friendly = friendly, isDummy = dummy, isNpc = npc, invisible = invis,
            dist = mp and (pos - mp).Magnitude or math.huge,
        }
        list[#list + 1] = e
        by[model] = e
    end

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local ch = p.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 and not isBlockedModel(ch) then
                local sameTeam = checkTeams and ((myTeam ~= nil and p.Team == myTeam) or (myTeamAttr ~= nil and p:GetAttribute("Team") == myTeamAttr))
                push(ch, hum, root, p.Name, p, p.TeamColor.Color, sameTeam, false, false)
            end
        end
    end

    for hum, kind in pairs(npcRegistry) do
        local model = hum.Parent
        if not model or isBlockedModel(model) then
            npcRegistry[hum] = nil
        elseif hum.Health > 0 then
            local okState, st = pcall(hum.GetState, hum)
            if not (okState and st == Enum.HumanoidStateType.Dead) then
                local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Head")
                if root then
                    local npcTeam = model:GetAttribute("Team")
                    local ownerId = tonumber(model:GetAttribute("PlayerUserId"))
                    local friendly = checkTeams and ((myTeamAttr ~= nil and npcTeam == myTeamAttr) or (ownerId == LP.UserId))
                    push(model, hum, root, model.Name, nil, Color3.fromRGB(190, 190, 205), friendly, true, kind == "npc")
                end
            end
        end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)
    Entities.list, Entities.byModel = list, by
end

vape.Libraries.entity = {
    Running = true,
    refresh = function() Entities.rebuild() end,
    entity = Entities,
}

local TargetState = { model = nil }
local Targeting = { by = {}, last = nil }
function Targeting.report(e, src)
    local r = { model = e.model, src = src, t = os.clock() }
    Targeting.by[src] = r
    Targeting.last = r
end
function Targeting.model()
    local L = Targeting.last
    if L and os.clock() - L.t < 0.6 then return L.model end
    return TargetState.model
end

local PRESET = {
    Red = Color3.fromRGB(255, 70, 70),
    Cyan = Color3.fromRGB(80, 230, 255),
    White = Color3.new(1, 1, 1),
}
local function entColor(e, mode, markTarget)
    if markTarget and Targeting.model() == e.model then return T.danger end
    if mode == "Team" then return e.color end
    return PRESET[mode] or e.color
end

return {
    Maid = Maid,
    Anim = Anim,
    stepAnims = stepAnims,
    Entities = Entities,
    Targeting = Targeting,
    TargetState = TargetState,
    isBlockedModel = isBlockedModel,
    entColor = entColor,
}
