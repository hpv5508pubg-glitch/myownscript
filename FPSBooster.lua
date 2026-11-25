local BlockColors = {
    grass = Color3.fromRGB(88, 152, 60),
    dirt = Color3.fromRGB(122, 88, 60),
    stone = Color3.fromRGB(126, 126, 126),
    cobblestone = Color3.fromRGB(112, 112, 112),
    obsidian = Color3.fromRGB(38, 32, 52),
    wood_plank_oak = Color3.fromRGB(162, 130, 78),
    iron_block = Color3.fromRGB(206, 206, 206),
    gold_block = Color3.fromRGB(238, 202, 82),
    diamond_block = Color3.fromRGB(108, 216, 214),
    emerald_block = Color3.fromRGB(74, 190, 108),
    wool_builder = Color3.fromRGB(228, 228, 228),
}

local function OptimizeInstance(inst, Settings, MapFolder, SaveOriginalProp)
    -- 1. Tắt ánh sáng, vụ nổ và hiệu ứng hạt
    if inst:IsA("Light") and Settings.RemoveLights then
        SaveOriginalProp(inst, "Enabled", false)
        return
    elseif inst:IsA("Explosion") and Settings.RemoveExplosions then
        SaveOriginalProp(inst, "Visible", false)
        return
    elseif (inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")) and Settings.RemoveEffects then
        if not inst:GetAttribute("PistonwareSelf") then
            SaveOriginalProp(inst, "Enabled", false)
        end
        return
    end

    -- 2. Chuyển Block trong Map thành SmoothPlastic phẳng để tăng FPS
    if Settings.SimplifyBlocks and MapFolder and inst:IsDescendantOf(MapFolder) then
        if inst:IsA("BasePart") then
            SaveOriginalProp(inst, "Reflectance", 0)
            SaveOriginalProp(inst, "CastShadow", false)

            if Settings.PotatoMode and inst:IsA("MeshPart") then
                SaveOriginalProp(inst, "RenderFidelity", Enum.RenderFidelity.Performance)
            end

            local flatColor = Settings.PotatoMode and Color3.fromRGB(255, 255, 255) or BlockColors[inst.Name]
            if flatColor then
                SaveOriginalProp(inst, "MaterialVariant", "")
                SaveOriginalProp(inst, "Material", Enum.Material.SmoothPlastic)
                SaveOriginalProp(inst, "Color", flatColor)
            end
        elseif inst:IsA("Texture") or inst:IsA("Decal") then
            SaveOriginalProp(inst, "Transparency", 1)
        end
    end
end
