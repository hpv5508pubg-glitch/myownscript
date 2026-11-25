local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TargetEffects = {
    "base_weather_particle_controller",
    "drill_tablet_controller",
    "paint_shotgun_effects_controller",
    "carrot_cannon_effects_controller",
    "RbxCharacterSounds",
    "dodo_bird_animation_controller",
}

local disabledConnections = {}

local function DisableLagConnections(selectedList)
    -- Khôi phục các kết nối cũ trước khi áp dụng mới
    for _, conn in ipairs(disabledConnections) do
        pcall(function() conn:Enable() end)
    end
    table.clear(disabledConnections)

    if type(getconnections) ~= "function" then
        warn("[MemoryFixer] Executor không hỗ trợ getconnections!")
        return
    end

    local signals = { RunService.Heartbeat, RunService.PreSimulation, RunService.RenderStepped, RunService.Stepped }
    for _, signal in ipairs(signals) do
        local ok, conns = pcall(getconnections, signal)
        if ok and conns then
            for _, conn in ipairs(conns) do
                if type(conn.Function) == "function" then
                    local infoOk, source = pcall(function() return debug.getinfo(conn.Function).source end)
                    if infoOk and type(source) == "string" then
                        local lowerSrc = source:lower():gsub("-", "_")
                        for _, targetName in ipairs(selectedList) do
                            if lowerSrc:find(targetName:lower():gsub("-", "_"), 1, true) then
                                pcall(function() conn:Disable() end)
                                table.insert(disabledConnections, conn)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end
