local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local AutoBank = {
    Enabled = false,
    Mode = "Auto", -- "Auto" hoặc "On bind"
    Range = 18,
    Busy = false,
    NextPass = 0,
    Request = nil,
    Chests = {},
    Counters = {},
    CounterKey = nil,
    UI = nil,
    Box = nil,
    LockState = { Serial = 0, Holds = {} },
}

function AutoBank.AcquireLock(duration)
    local now = os.clock()
    if AutoBank.LockState.Owner ~= "AutoBank" then
        if AutoBank.LockState.Owner ~= nil then
            local activeHold = AutoBank.LockState.Holds[AutoBank.LockState.Serial]
            if activeHold and activeHold > now then
                return nil
            end
        end
        AutoBank.LockState.Owner = "AutoBank"
        table.clear(AutoBank.LockState.Holds)
    end
    AutoBank.LockState.Serial += 1
    AutoBank.LockState.Holds[AutoBank.LockState.Serial] = now + duration
    return AutoBank.LockState.Serial
end

function AutoBank.RenewLock(token, extraTime)
    local current = AutoBank.LockState.Holds[token]
    if AutoBank.LockState.Owner ~= "AutoBank" or not current then
        return false
    end
    AutoBank.LockState.Holds[token] = math.max(current, os.clock() + extraTime)
    return true
end

function AutoBank.ReleaseLock(token)
    if AutoBank.LockState.Owner == "AutoBank" and AutoBank.LockState.Holds[token] then
        AutoBank.LockState.Holds[token] = nil
        if next(AutoBank.LockState.Holds) == nil then
            AutoBank.LockState.Owner = nil
        end
    end
end

function AutoBank.IsLockedByOther()
    local owner = AutoBank.LockState.Owner
    if owner == nil or owner == "AutoBank" then return false end
    local now = os.clock()
    for _, expireAt in pairs(AutoBank.LockState.Holds) do
        if expireAt > now then
            return true
        end
    end
    return false
end

function AutoBank.FindNearestChest(char)
    local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    if not root then return nil, math.huge end

    local bestChest, bestDist = nil, math.huge
    for _, chest in ipairs(CollectionService:GetTagged("personal-chest")) do
        if chest:IsDescendantOf(Workspace) then
            local pos = chest:IsA("BasePart") and chest.Position or chest:GetPivot().Position
            local dist = (pos - root.Position).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestChest = chest
            end
        end
    end
    return bestChest, bestDist
end

function AutoBank.Tick(DepositRunner, NotifyFunc)
    if not AutoBank.Enabled or AutoBank.Busy then return end

    local now = os.clock()
    local char = LocalPlayer.Character
    local chest, dist = AutoBank.FindNearestChest(char)
    local inRange = dist <= AutoBank.Range

    if not AutoBank.Request then
        if AutoBank.Mode ~= "Auto" or now < AutoBank.NextPass then
            return
        end
    end

    if not chest then
        if AutoBank.Request then
            AutoBank.Request = nil
            NotifyFunc("AutoBank", "No personal chest found nearby.", 3)
        end
        return
    end

    if not inRange or AutoBank.IsLockedByOther() then
        return
    end

    AutoBank.Request = nil
    AutoBank.Busy = true
    AutoBank.NextPass = now + 1.5

    task.spawn(function()
        local token = AutoBank.AcquireLock(8)
        if token and type(DepositRunner) == "function" then
            pcall(DepositRunner, chest, token)
            AutoBank.ReleaseLock(token)
        end
        AutoBank.Busy = false
    end)
end
