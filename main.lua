--[[
    WrenchHub / main.lua — Modular Loader (guis / libraries / games)
    Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/hpv5508pubg-glitch/myownscript/main/main.lua", true))()
]]

local BUILD_ID = "2026.11.28.01"
local REPO_BASE = "https://raw.githubusercontent.com/hpv5508pubg-glitch/myownscript/main/"
shared.WrenchHubMainUrl = REPO_BASE .. "main.lua"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local StatsService = game:GetService("Stats")

local env = (getgenv and getgenv()) or _G
if env.__WrenchHub and env.__WrenchHub.Unload then pcall(env.__WrenchHub.Unload) end
if shared.vape then pcall(function() shared.vape:Uninject() end) end

local LP = Players.LocalPlayer
local function cam() return workspace.CurrentCamera end

if type(isfolder) == "function" and type(makefolder) == "function" then
    for _, dir in {
        "pistonware",
        "pistonware/profiles",
        "pistonware/assets",
        "pistonware/assets/fonts",
        "pistonware/assets/icons",
        "pistonware/exports",
        "wrenchhub",
        "wrenchhub/guis",
        "wrenchhub/libraries",
        "wrenchhub/games",
    } do
        local ok, exists = pcall(isfolder, dir)
        if not (ok and exists) then
            pcall(makefolder, dir)
        end
    end
end

if type(shared.PistonwareDevHttpGet) ~= "function" then
    shared.PistonwareDevHttpGet = function(url, nocache)
        local rewritten = tostring(url):gsub(
            "https://raw%.githubusercontent%.com/themagicpiston/pistonware/main/",
            "https://raw.githubusercontent.com/hpv5508pubg-glitch/pistonsource/main/"
        )
        return game:HttpGet(rewritten, nocache)
    end
end

local hasFS = (type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function")
local versionFile = "wrenchhub/version.txt"
local cacheFresh = false
if hasFS then
    local okVer, diskVer = pcall(function()
        return isfile(versionFile) and readfile(versionFile) or ""
    end)
    if okVer and type(diskVer) == "string" and diskVer == BUILD_ID then
        cacheFresh = true
    end
end

local function fetchModule(relPath)
    local cachePath = "wrenchhub/" .. relPath
    if cacheFresh and hasFS then
        local okRead, body = pcall(function()
            return isfile(cachePath) and readfile(cachePath) or nil
        end)
        if okRead and type(body) == "string" and body ~= "" then
            local okCompile, chunk = pcall(loadstring, body, relPath)
            if okCompile and type(chunk) == "function" then
                return chunk
            end
        end
    end

    local content, compiledChunk
    for attempt = 1, 3 do
        local okGet, res = pcall(game.HttpGet, game, REPO_BASE .. relPath, true)
        if okGet and type(res) == "string" and res ~= "" and res ~= "404: Not Found" then
            local okCompile, chunk = pcall(loadstring, res, relPath)
            if okCompile and type(chunk) == "function" then
                content = res
                compiledChunk = chunk
                break
            end
        end
        if attempt < 3 then task.wait(0.6 * attempt) end
    end

    if not compiledChunk then
        error("[WrenchHub] Failed to load module: " .. relPath)
    end
    if hasFS then
        pcall(writefile, cachePath, content)
    end
    return compiledChunk
end

local guiChunk = fetchModule("guis/newgui.lua")
local assetsChunk = fetchModule("libraries/assets.lua")
local entityChunk = fetchModule("libraries/entity.lua")
local predictionChunk = fetchModule("libraries/prediction.lua")
local bedwarsChunk = fetchModule("games/bedwars.lua")

if hasFS and not cacheFresh then
    pcall(writefile, versionFile, BUILD_ID)
end

local vape = guiChunk()
shared.vape = vape

local function Notify(title, body, duration, force)
    if vape and vape.CreateNotification then
        pcall(function()
            vape:CreateNotification(tostring(title or "WrenchHub"), tostring(body or ""), duration or 3, force and "alert" or nil)
        end)
    end
end

local T = {
    white = Color3.new(1, 1, 1),
    danger = Color3.fromRGB(220, 20, 60),
    good = Color3.fromRGB(75, 215, 120),
    warn = Color3.fromRGB(255, 195, 45),
    accent = Color3.fromRGB(243, 93, 18),
    cardBg = Color3.fromRGB(16, 16, 16),
}
local Center, Left = Enum.TextXAlignment.Center, Enum.TextXAlignment.Left

local guiParent
do
    local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    guiParent = ok and p or LP:WaitForChild("PlayerGui")
end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(p, r, s)
    return make("UICorner", { CornerRadius = UDim.new(s or 0, r) }, p)
end
local function textLabel(parent, str, size, color, align, pos, sz)
    return make("TextLabel", {
        BackgroundTransparency = 1, BorderSizePixel = 0, Font = Enum.Font.GothamBold, Text = str, TextSize = size,
        TextColor3 = color, TextXAlignment = align or Left, Position = pos or UDim2.new(),
        Size = sz or UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local OverlayGui = make("ScreenGui", {
    Name = "WrenchHubOverlays", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)
local OverlayL = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0 }, OverlayGui)

local CoreMaid = { tasks = {} }
function CoreMaid:give(x)
    if x ~= nil then table.insert(self.tasks, x) end
    return x
end
function CoreMaid:clean()
    for i = #self.tasks, 1, -1 do
        local t = self.tasks[i]
        self.tasks[i] = nil
        local ty = typeof(t)
        if ty == "RBXScriptConnection" then pcall(function() t:Disconnect() end)
        elseif ty == "Instance" then pcall(function() t:Destroy() end)
        elseif ty == "function" then pcall(t) end
    end
end

local ctx = {
    BuildId = BUILD_ID,
    Players = Players,
    RunService = RunService,
    UserInputService = UserInputService,
    ReplicatedStorage = ReplicatedStorage,
    CollectionService = CollectionService,
    HttpService = HttpService,
    Lighting = Lighting,
    StatsService = StatsService,
    LP = LP,
    cam = cam,
    vape = vape,
    env = env,
    Notify = Notify,
    CoreMaid = CoreMaid,
    T = T,
    Center = Center,
    Left = Left,
    make = make,
    corner = corner,
    textLabel = textLabel,
    OverlayGui = OverlayGui,
    OverlayL = OverlayL,
}

ctx.Assets = assetsChunk()
ctx.Entity = entityChunk(ctx)
ctx.Prediction = predictionChunk(ctx)
bedwarsChunk(ctx)
