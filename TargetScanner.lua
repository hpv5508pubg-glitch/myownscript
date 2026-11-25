local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local function ScanAllTargets(range, maxLimit, sortFunc, includeNPCs, EntityLib, Bedwars)
    local results = {}
    if not EntityLib.isAlive then
        return results
    end

    local myRoot = EntityLib.character.HumanoidRootPart
    local myPos = myRoot.Position
    local myTeam = LocalPlayer:GetAttribute("Team")
    local candidates = {}

    -- 1. Quét người chơi địch
    for _, entity in pairs(EntityLib.List) do
        if entity.Targetable and entity.RootPart then
            local dist = (myPos - entity.RootPart.Position).Magnitude
            if dist <= range then
                table.insert(candidates, entity)
            end
        end
    end

    -- 2. Quét quái, Boss, Drone và Pot nếu bật Target NPCs
    if includeNPCs then
        local npcTags = { "Monster", "DiamondGuardian", "GolemBoss", "Drone" }
        for _, tag in ipairs(npcTags) do
            for _, model in ipairs(CollectionService:GetTagged(tag)) do
                if model.PrimaryPart then
                    local dist = (myPos - model.PrimaryPart.Position).Magnitude
                    if dist <= range then
                        -- Bỏ qua quái/Drone cùng đội
                        if model:GetAttribute("Team") == myTeam then continue end
                        if tonumber(model:GetAttribute("PlayerUserId")) == LocalPlayer.UserId then continue end

                        table.insert(candidates, {
                            Player = { Name = model.Name, UserId = 1443379645 },
                            Character = model,
                            RootPart = model.PrimaryPart,
                            Humanoid = model:FindFirstChildOfClass("Humanoid"),
                        })
                    end
                end
            end
        end
    end

    -- Sắp xếp theo độ ưu tiên (gần nhất / ít máu nhất)
    if sortFunc then
        table.sort(candidates, sortFunc)
    end

    for i = 1, math.min(#candidates, maxLimit) do
        table.insert(results, candidates[i])
    end

    return results
end
