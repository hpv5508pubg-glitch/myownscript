local HttpService = game:GetService("HttpService")

local AutoWinBridges = {
    ScaffoldBridge = nil,
    NukerBridge = nil,
    ProjectileBridge = nil,
}

function AutoWinBridges.ReleaseAll(SharedTable)
    for key, bridge in pairs(AutoWinBridges) do
        if bridge and type(bridge.Release) == "function" then
            pcall(bridge.Release, bridge)
        end
        AutoWinBridges[key] = nil
    end
    if SharedTable then
        SharedTable.AutoWinScaffoldBridge = nil
        SharedTable.AutoWinNukerBridge = nil
        SharedTable.AutoWinProjectileAuraBridge = nil
    end
end

local function CreateESPHitbox(adorneePart, parentGui, sizeVec, isItemBox)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = isItemBox and "ItemBox" or "PlayerBox"
    box.AlwaysOnTop = true
    box.ZIndex = 0
    box.Size = sizeVec or Vector3.new(3, 5, 3)
    box.CFrame = isItemBox and CFrame.identity or CFrame.new(0, -0.5, 0)
    box.Adornee = adorneePart
    box.Visible = false
    box.Parent = parentGui
    return box
end

local function SaveAutoQueueConfig(ConfigTable)
    if type(writefile) ~= "function" then return end
    local encoded = HttpService:JSONEncode(ConfigTable)
    pcall(writefile, "pistonware/autoqueuedodge.txt", encoded)
end

local function LoadRegionLockConfig(RegionMap)
    if type(isfile) ~= "function" or type(readfile) ~= "function" then return nil end
    if not isfile("pistonware/regionlock.txt") then return nil end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(readfile("pistonware/regionlock.txt"))
    end)
    if not ok or type(decoded) ~= "table" then return nil end

    local activeRegions = {}
    for _, reg in ipairs(decoded.regions or {}) do
        local key = tostring(reg):gsub("%s+", ""):upper()
        activeRegions[(RegionMap and RegionMap[key]) or key] = true
    end
    return {
        Enabled = decoded.enabled == true,
        Requeue = decoded.requeue == true,
        Timeout = tonumber(decoded.timeout),
        Regions = activeRegions,
    }
end
