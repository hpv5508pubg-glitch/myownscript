local function UpdateTargetMotion(targetEntity, rootPart, now, isAirborne, Config)
    local pos = rootPart.Position
    local rawVel = rootPart.AssemblyLinearVelocity
    local char = targetEntity.Character
    local lastDamageTime = typeof(char) == "Instance" and char:GetAttribute("LastDamageTakenTime") or nil

    local tracker = Config.Trackers[targetEntity]
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
        Config.Trackers[targetEntity] = tracker
        return tracker
    end

    local dt = now - tracker.time
    if dt <= 1e-4 then
        return tracker
    end

    -- Chống lỗi khi mục tiêu dịch chuyển tức thời (Telepearl) hoặc vận tốc ảo > 260
    local displacement = pos - tracker.position
    local maxAllowedDist = math.max(12, (math.max(tracker.velocity.Magnitude, rawVel.Magnitude) + 30) * dt * 1.5)
    if displacement.Magnitude > maxAllowedDist or rawVel.Magnitude > 260 then
        tracker.position = pos
        tracker.velocity = Vector3.zero
        tracker.time = now
        return tracker
    end

    -- Lưu mẫu vào hàng đợi vòng 8 phần tử để tính vận tốc trung bình
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
            if v.Magnitude <= 260 then
                sampledVel = v
            end
        end
    end

    -- Làm mượt vận tốc (Velocity Smoothing)
    local smoothedVel = rawVel:Lerp(sampledVel, 0.15)
    local finalVel = Vector3.new(smoothedVel.X, rawVel.Y, smoothedVel.Z)

    -- Phát hiện trạng thái bị đánh văng (Knockback Detection)
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
    if not isKnockedBack then
        tracker.stable = finalVel
    end

    -- Theo dõi góc cua (Turn Rate) và đảo chiều (Strafe Reversal)
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
