local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local ProjectileAura = {
    Enabled = false,
    Range = 22,
    Targets = {},
    Pearls = {},
}

function ProjectileAura.CollectAvailableProjectiles(ClientStore, Bedwars, AllowedList)
    local found = {}
    local items = ClientStore.inventory and ClientStore.inventory.inventory and ClientStore.inventory.inventory.items
    if not items or type(AllowedList) ~= "table" then return found end

    for _, item in pairs(items) do
        if item and item.itemType then
            local meta = Bedwars.ItemMeta[item.itemType]
            local source = meta and (meta.projectileSource or (meta.block and meta.block.projectileSource))
            local projType = (source and source.projectileType and source.projectileType(nil)) or item.itemType

            if table.find(AllowedList, projType) or table.find(AllowedList, item.itemType) then
                local qty = item.count or item.quantity or item.amount
                if qty == nil or qty > 0 then
                    table.insert(found, {
                        Item = item,
                        ProjectileType = projType,
                        Source = source or meta,
                    })
                end
            end
        end
    end
    return found
end

function ProjectileAura.AimCameraAtTarget(dt, targetPos, gravity, speed, AimRate)
    local cam = Workspace.CurrentCamera
    if not cam or cam.CameraType == Enum.CameraType.Scriptable then return end

    local origin = cam.CFrame.Position
    local toTarget = targetPos - origin
    local dist = toTarget.Magnitude
    if dist < 1 then return end

    -- Bù độ rơi parabol theo trọng lực và vận tốc đạn
    local flightTime = dist / math.max(speed, 1)
    local compensatedTarget = targetPos + Vector3.new(0, 0.5 * gravity * flightTime * flightTime, 0)
    local desiredDir = (compensatedTarget - origin).Unit

    local currentRight = cam.CFrame.RightVector
    local yawDelta = (math.atan2(-desiredDir.X, -desiredDir.Z) - math.atan2(-currentRight.X, -currentRight.Z) + math.pi) % (2 * math.pi) - math.pi
    local pitchDelta = math.asin(math.clamp(desiredDir.Y, -1, 1)) - math.asin(math.clamp(currentRight.Y, -1, 1))

    local alpha = 1 - math.exp(-(AimRate or 14) * dt)
    local currentPitch = math.asin(math.clamp(cam.CFrame.LookVector.Y, -1, 1))
    local clampedPitch = math.clamp(currentPitch + pitchDelta * alpha, -1.39, 1.39) - currentPitch

    cam.CFrame = CFrame.new(cam.CFrame.Position)
        * CFrame.Angles(0, yawDelta * alpha, 0)
        * cam.CFrame.Rotation
        * CFrame.Angles(clampedPitch, 0, 0)
end
