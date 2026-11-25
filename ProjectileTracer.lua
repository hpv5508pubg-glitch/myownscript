local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function StepProjectileTracer(tracer, now, UpdateBeamFunc, FadeOutFunc)
    if (now - tracer.born) > tracer.maxFlight then
        FadeOutFunc(tracer, now, 0, "backstop")
        return
    end

    local rootPart = tracer.root
    if not rootPart or not rootPart.Parent then
        FadeOutFunc(tracer, now, 0, "gone")
        return
    end

    local currentPos = rootPart.Position
    local velocity = rootPart.AssemblyLinearVelocity

    -- Nếu đạn đã vượt quá 200 studs thì kết thúc tia
    if (currentPos - tracer.startPos).Magnitude > 200 then
        FadeOutFunc(tracer, now, 0, "range")
        return
    end

    -- Kiểm tra va chạm vật cản phía trước
    local dt = math.min(now - (tracer.lastSeen or tracer.born), 0.1)
    if dt > 0 then
        local stepVec = velocity * dt + tracer.accel * (0.5 * dt * dt)
        if stepVec.Magnitude >= 0.01 then
            rayParams.FilterDescendantsInstances = { LocalPlayer.Character, workspace.CurrentCamera }
            local hit = workspace:Raycast(currentPos, stepVec, rayParams)
            if hit then
                UpdateBeamFunc(tracer, hit.Position, velocity, tracer.elapsed + dt)
                FadeOutFunc(tracer, now, 0, "impact")
                return
            end
        end
    end

    -- Cập nhật độ cong của Beam theo vận tốc hiện tại
    local elapsed = now - tracer.born
    UpdateBeamFunc(tracer, currentPos, velocity, elapsed)
    tracer.lastSeen = now
end
