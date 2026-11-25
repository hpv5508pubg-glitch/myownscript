local ItemList = {}

local DefaultItems = {
    { Id = "adetunde_crown", Name = "Adetunde Crown" },
    { Id = "aery_crown", Name = "Aery Crown" },
    { Id = "flying_monster_block", Name = "Air" },
    { Id = "alchemist_flask", Name = "Alchemist Flask" },
    { Id = "wood_sword", Name = "Wood Sword" },
    { Id = "stone_sword", Name = "Stone Sword" },
    { Id = "iron_sword", Name = "Iron Sword" },
    { Id = "diamond_sword", Name = "Diamond Sword" },
    { Id = "emerald_sword", Name = "Emerald Sword" },
    { Id = "rageblade", Name = "Rageblade" },
    { Id = "void_sword", Name = "Void Sword" },
    { Id = "telepearl", Name = "Telepearl" },
    { Id = "fireball", Name = "Fireball" },
    { Id = "tnt", Name = "TNT" },
    -- (Có thể nạp toàn bộ 400+ item khác tự động từ ItemMeta bên dưới)
}

function ItemList.Build(BedwarsData)
    local result = {}
    local seenIds = {}
    local seenNames = {}

    for _, item in ipairs(DefaultItems) do
        seenIds[item.Id] = true
        seenNames[item.Name:lower()] = true
        table.insert(result, item)
    end

    -- Tự động đồng bộ thêm các item mới từ game nếu có
    if type(BedwarsData.ItemMeta) == "table" then
        for itemId, meta in pairs(BedwarsData.ItemMeta) do
            if type(itemId) == "string" and not seenIds[itemId] and type(meta) == "table" then
                local displayName = type(meta.displayName) == "string" and meta.displayName:match("^%s*(.-)%s*$") or ""
                if displayName ~= "" then
                    if seenNames[displayName:lower()] then
                        displayName = itemId:gsub("_", " ")
                    end
                    seenIds[itemId] = true
                    seenNames[displayName:lower()] = true
                    table.insert(result, { Id = itemId, Name = displayName })
                end
            end
        end
    end

    table.sort(result, function(a, b)
        return a.Name:lower() < b.Name:lower()
    end)

    return result
end

return ItemList
