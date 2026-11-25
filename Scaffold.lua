local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Scaffold = {
    Enabled = false,
    Expand = 1,
    Tower = true,
    Downwards = false,
    Diagonal = true,
    LastCell = nil,
    SavedState = nil,
}

function Scaffold.SaveAndEnable(Settings, Overrides)
    Overrides = Overrides or {}
    Scaffold.SavedState = {
        WasEnabled = Scaffold.Enabled,
        Expand = Scaffold.Expand,
        Tower = Scaffold.Tower,
        Downwards = Scaffold.Downwards,
        Diagonal = Scaffold.Diagonal,
    }
    Scaffold.Expand = Overrides.Expand or 1
    Scaffold.Diagonal = (Overrides.Diagonal ~= false)
    Scaffold.Downwards = (Overrides.Downwards == true)
    Scaffold.Tower = (Overrides.Tower == true)
    Scaffold.Enabled = true
end

function Scaffold.RestoreState()
    local saved = Scaffold.SavedState
    if not saved then return end
    Scaffold.SavedState = nil
    Scaffold.Expand = saved.Expand
    Scaffold.Tower = saved.Tower
    Scaffold.Downwards = saved.Downwards
    Scaffold.Diagonal = saved.Diagonal
    Scaffold.Enabled = saved.WasEnabled
end

function Scaffold.CreateCounterUI(ParentGui)
    local frame = Instance.new("Frame")
    frame.Name = "ScaffoldCount"
    frame.Size = UDim2.fromOffset(62, 72)
    frame.Position = UDim2.new(0.5, -31, 0.5, 30)
    frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10):Lerp(Color3.fromRGB(240, 122, 31), 0.1)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = ParentGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Border"
    stroke.Color = Color3.fromRGB(240, 122, 31)
    stroke.Transparency = 0.55
    stroke.Thickness = 1
    stroke.Parent = frame

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.fromOffset(38, 38)
    icon.Position = UDim2.fromOffset(12, 9)
    icon.BackgroundTransparency = 1
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = frame

    local countLabel = Instance.new("TextLabel")
    countLabel.Name = "Count"
    countLabel.Size = UDim2.new(1, 0, 0, 18)
    countLabel.Position = UDim2.new(0, 0, 1, -22)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = "0"
    countLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    countLabel.TextSize = 14
    countLabel.Parent = frame

    return frame, icon, countLabel
end

function Scaffold.Step(EntityLib, Bedwars, GetBlockItem, GetTotalBlocks, FindPlaceSpot)
    if not Scaffold.Enabled or not EntityLib.isAlive then return end

    local blockItem = GetBlockItem()
    local totalBlocks = GetTotalBlocks()
    if totalBlocks == 0 and Scaffold.AutoDisableOnEmpty then
        Scaffold.Enabled = false
        return
    end
    if not blockItem then return end

    local root = EntityLib.character.RootPart
    local hum = EntityLib.character.Humanoid
    local isJumping = UserInputService:IsKeyDown(Enum.KeyCode.Space)

    if Scaffold.Tower and isJumping and not UserInputService:GetFocusedTextBox() then
        root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 38, root.AssemblyLinearVelocity.Z)
    end

    local crouchOffset = (Scaffold.Downwards and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)) and 4.5 or 1.5
    for step = Scaffold.Expand, 1, -1 do
        local samplePos = root.Position - Vector3.new(0, EntityLib.character.HipHeight + crouchOffset, 0) + (hum.MoveDirection * (step * 3))
        local cell = Bedwars.BlockController:getBlockPosition(samplePos)

        local isOccupied = Bedwars.BlockController:getStore():getBlockAt(cell) ~= nil
        if not isOccupied then
            local placePos = FindPlaceSpot and FindPlaceSpot(cell) or (cell * 3)
            if placePos then
                task.spawn(Bedwars.placeBlock, placePos, blockItem, false)
            end
        end
        Scaffold.LastCell = cell
    end
end
