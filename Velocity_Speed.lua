local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local MovementUtils = {
    IsLongJumping = false,
    LongJumpFireballThrown = false,
    KnockbackUntil = 0,
    KnockbackStrength = 0,
}

function MovementUtils.ApplyKnockbackReduction(damageEvent, Settings, CheckEnemy)
    if not Settings.VelocityEnabled then return end
    if not damageEvent or damageEvent.entityInstance ~= LocalPlayer.Character then return end
    if CheckEnemy and not CheckEnemy(damageEvent.fromEntity) then return end

    local now = os.clock()
    local horizMult = Settings.HorizontalMultiplier or 0
    local vertMult = Settings.VerticalMultiplier or 0

    MovementUtils.KnockbackUntil = now + (Settings.Duration or 0.5)
    MovementUtils.KnockbackStrength = horizMult

    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local vel = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(vel.X * horizMult, vel.Y * vertMult, vel.Z * horizMult)
    end
end

function MovementUtils.StepHorizontalBoost(dt, EntityLib, RayParams, SpeedValue, CanBoost)
    local root = EntityLib.isAlive and EntityLib.character and EntityLib.character.RootPart
    if not root or not CanBoost(root) then return end

    local now = os.clock()
    if MovementUtils.KnockbackUntil > now then
        local moveDir = EntityLib.character.Humanoid.MoveDirection
        if moveDir.Magnitude > 0.01 then
            local step = moveDir.Unit * SpeedValue * dt
            local hit = Workspace:Raycast(root.Position, step, RayParams)
            if not hit then
                root.CFrame = root.CFrame + step
            end
        end
    end
end

function MovementUtils.AntiFallCheck(EntityLib, MatchController, FallThreshold)
    if not EntityLib.isAlive then return end
    if MatchController and MatchController:getMatchState() ~= 1 then return end
    if MovementUtils.IsLongJumping then return end

    local root = EntityLib.character.RootPart
    local hum = EntityLib.character.Humanoid
    if root and hum and root.AssemblyLinearVelocity.Y < -(FallThreshold or 35) then
        local savedY = root.AssemblyLinearVelocity.Y
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 2.5, root.AssemblyLinearVelocity.Z)
        hum:ChangeState(Enum.HumanoidStateType.Landed)

        task.spawn(function()
            game:GetService("RunService").PreRender:Wait()
            if root and root.Parent then
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, savedY, root.AssemblyLinearVelocity.Z)
            end
        end)
    end
end

function MovementUtils.ResetLongJump(ReleaseItemFunc, ClaimToken)
    MovementUtils.IsLongJumping = false
    MovementUtils.LongJumpFireballThrown = false
    if ClaimToken ~= nil and type(ReleaseItemFunc) == "function" then
        pcall(ReleaseItemFunc, "longjump", ClaimToken)
    end
end
