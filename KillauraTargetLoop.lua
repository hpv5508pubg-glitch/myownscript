local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function UpdateKillauraFrame(State, Settings, EntityLib, Bedwars, CombatUtils)
    if not Settings.Enabled then
        State.Target = nil
        State.Count = 0
        return
    end

    local swordData, itemMeta = CombatUtils.GetBestSword()
    State.Target = nil
    State.Count = 0
    local isAttacking = false

    if not swordData or not EntityLib.isAlive then
        return
    end

    local rootPart = EntityLib.character.RootPart
    local myPos = rootPart.Position
    local extraReach = CombatUtils.GetReachBonus(itemMeta)
    local attackRange = Settings.AttackRange + extraReach
    local swingRange = Settings.SwingRange + extraReach
    local fovAngle = Settings.FOV

    -- Quét tất cả mục tiêu trong tầm vung kiếm
    local targets = EntityLib.AllPosition({
        Range = swingRange,
        Part = "RootPart",
        Wallcheck = Settings.Wallcheck,
        Players = Settings.TargetPlayers,
        NPCs = Settings.TargetNPCs,
        Limit = Settings.MaxTargets,
    })

    CombatUtils.SortByPriority(targets, Settings.TargetPriority)

    if #targets > 0 then
        -- Tự động cầm kiếm nếu chưa cầm
        local handItem = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HandInvItem")
        if not (handItem and handItem.Value == swordData.tool) then
            CombatUtils.EquipTool(swordData.tool)
        end

        local lookVector = rootPart.CFrame.LookVector * Vector3.new(1, 0, 1)

        for _, target in ipairs(targets) do
            local offset = target.RootPart.Position - myPos
            local distSq = offset:Dot(offset)
            local inAttackRange = distSq <= (attackRange * attackRange)

            -- Kiểm tra góc nhìn (FOV)
            if fovAngle < 360 then
                local flatOffset = offset * Vector3.new(1, 0, 1)
                if flatOffset.Magnitude > 0 and lookVector.Magnitude > 0 then
                    local angle = math.deg(math.acos(math.clamp(lookVector.Unit:Dot(flatOffset.Unit), -1, 1)))
                    if angle > (fovAngle / 2) then
                        continue
                    end
                end
            end

            State.Count += 1
            State.TrackedList[State.Count] = {
                Entity = target,
                InRange = inAttackRange,
                DistSq = distSq,
            }

            if not isAttacking then
                isAttacking = true
                State.Target = target
            end
        end
    end

    -- Xoay mặt nhân vật về phía mục tiêu gần nhất (Face Target)
    if Settings.FaceTarget and State.Count > 0 then
        local primaryTargetPos = State.TrackedList[1].Entity.RootPart.Position
        rootPart.CFrame = CFrame.lookAt(myPos, Vector3.new(primaryTargetPos.X, myPos.Y + 0.001, primaryTargetPos.Z))
    end
end
