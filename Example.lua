-- ObsidianUi - Y2k Script Back2Back
-- Customized UI Library

local repo = "https://raw.githubusercontent.com/Y2kScriptBack2Back/ObsidianUi/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Local loading (for testing):
-- local Library = loadstring(readfile("Library.lua"))()
-- local ThemeManager = loadstring(readfile("addons/ThemeManager.lua"))()
-- local SaveManager = loadstring(readfile("addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "Escape",
    Footer = "Y2k Script Back2Back",
    NotifySide = "Right",
    ShowCustomCursor = true,
    Center = true,
    AutoShow = true,
    Resizable = true,
    CornerRadius = 10,
})

-- ─────────────────────────────────────────────
--  TABS
-- ─────────────────────────────────────────────
local Tabs = {
    Main     = Window:AddTab("Main",        "home"),
    Combat   = Window:AddTab("Combat",      "sword"),
    Visual   = Window:AddTab("Visuals",     "eye"),
    Settings = Window:AddTab("Settings",    "settings"),
}

-- ─────────────────────────────────────────────
--  MAIN TAB
-- ─────────────────────────────────────────────
local MainLeft  = Tabs.Main:AddLeftGroupbox("Player")
local MainRight = Tabs.Main:AddRightGroupbox("Movement")

MainLeft:AddToggle("GodMode", {
    Text    = "God Mode",
    Default = false,
    Tooltip = "Makes you immune to all damage",
    Callback = function(val)
        -- your logic here
    end,
})

MainLeft:AddToggle("InfStamina", {
    Text    = "Infinite Stamina",
    Default = false,
    Tooltip = "Disables stamina drain",
    Callback = function(val)
        -- your logic here
    end,
})

MainLeft:AddToggle("AutoFarm", {
    Text    = "Auto Farm",
    Default = false,
    Tooltip = "Automatically collects resources",
    Risky   = true,
    Callback = function(val)
        -- your logic here
    end,
})

MainLeft:AddDivider()

MainLeft:AddSlider("WalkSpeed", {
    Text    = "Walk Speed",
    Default = 16,
    Min     = 8,
    Max     = 100,
    Rounding = 0,
    Suffix  = " stud/s",
    Tooltip = "Controls the character walk speed",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = val
        end
    end,
})

MainLeft:AddSlider("JumpPower", {
    Text    = "Jump Power",
    Default = 50,
    Min     = 10,
    Max     = 200,
    Rounding = 0,
    Suffix  = " N",
    Tooltip = "Controls the character jump power",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = val
        end
    end,
})

MainRight:AddToggle("Noclip", {
    Text    = "Noclip",
    Default = false,
    Tooltip = "Walk through walls",
    Callback = function(val)
        -- your logic here
    end,
})

MainRight:AddToggle("Fly", {
    Text    = "Fly",
    Default = false,
    Tooltip = "Enables flight",
    Callback = function(val)
        -- your logic here
    end,
})

MainRight:AddSlider("FlySpeed", {
    Text    = "Fly Speed",
    Default = 50,
    Min     = 10,
    Max     = 300,
    Rounding = 0,
    Suffix  = " stud/s",
    Tooltip = "Controls the fly speed",
    Callback = function(val)
        -- your logic here
    end,
})

-- ─────────────────────────────────────────────
--  COMBAT TAB
-- ─────────────────────────────────────────────
local CombatLeft  = Tabs.Combat:AddLeftGroupbox("Aim")
local CombatRight = Tabs.Combat:AddRightGroupbox("Misc")

CombatLeft:AddToggle("AimLock", {
    Text    = "Aim Lock",
    Default = false,
    Tooltip = "Locks aim to nearest player",
    Callback = function(val)
        -- your logic here
    end,
})

CombatLeft:AddSlider("Smoothness", {
    Text    = "Smoothness",
    Default = 5,
    Min     = 1,
    Max     = 20,
    Rounding = 1,
    Tooltip = "Aim lock smoothness factor",
    Callback = function(val)
        -- your logic here
    end,
})

CombatLeft:AddDropdown("HitPart", {
    Text    = "Target Part",
    Values  = { "Head", "HumanoidRootPart", "Torso", "Random" },
    Default = "Head",
    Tooltip = "Which part to aim at",
    Callback = function(val)
        -- your logic here
    end,
})

CombatLeft:AddLabel("Keybind"):AddKeyPicker("AimKey", {
    Default          = "Q",
    Mode             = "Hold",
    Text             = "Aim Lock Key",
    SyncToggleState  = false,
    Callback = function(val)
        -- your logic here
    end,
})

CombatRight:AddToggle("SilentAim", {
    Text    = "Silent Aim",
    Default = false,
    Tooltip = "Shoots towards target without moving crosshair",
    Risky   = true,
    Callback = function(val)
        -- your logic here
    end,
})

CombatRight:AddSlider("FOV", {
    Text    = "FOV Radius",
    Default = 100,
    Min     = 20,
    Max     = 400,
    Rounding = 0,
    Tooltip = "Detection radius in pixels",
    Callback = function(val)
        -- your logic here
    end,
})

-- ─────────────────────────────────────────────
--  VISUALS TAB
-- ─────────────────────────────────────────────
local VisualLeft  = Tabs.Visual:AddLeftGroupbox("ESP")
local VisualRight = Tabs.Visual:AddRightGroupbox("World")

VisualLeft:AddToggle("PlayerESP", {
    Text    = "Player ESP",
    Default = false,
    Tooltip = "Shows boxes around players",
    Callback = function(val)
        -- your logic here
    end,
})

VisualLeft:AddToggle("HealthBar", {
    Text    = "Health Bars",
    Default = false,
    Tooltip = "Shows health bar above players",
    Callback = function(val)
        -- your logic here
    end,
})

VisualLeft:AddToggle("NameTag", {
    Text    = "Name Tags",
    Default = false,
    Tooltip = "Shows player names above heads",
    Callback = function(val)
        -- your logic here
    end,
})

VisualLeft:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
    Default     = Color3.fromRGB(0, 210, 229),
    Title       = "ESP Box Color",
    Transparency = 0,
    Callback = function(val)
        -- your logic here
    end,
})

VisualRight:AddToggle("Fullbright", {
    Text    = "Fullbright",
    Default = false,
    Tooltip = "Maximum game brightness",
    Callback = function(val)
        local lighting = game:GetService("Lighting")
        lighting.Brightness = val and 2 or 1
        lighting.GlobalShadows = not val
    end,
})

VisualRight:AddToggle("NoFog", {
    Text    = "Remove Fog",
    Default = false,
    Tooltip = "Removes atmospheric fog",
    Callback = function(val)
        local lighting = game:GetService("Lighting")
        if lighting:FindFirstChildOfClass("Atmosphere") then
            lighting:FindFirstChildOfClass("Atmosphere").Density = val and 0 or 0.3
        end
    end,
})

-- ─────────────────────────────────────────────
--  SETTINGS TAB
-- ─────────────────────────────────────────────
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Interface")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text    = "Show Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text    = "Custom Cursor",
    Default = true,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddLabel("Cursor Color"):AddColorPicker("CursorColor", {
    Default = Color3.fromRGB(0, 210, 229),
    Title   = "Custom Cursor Color",
    Tooltip = "Change the crosshair cursor color",
    Callback = function(val)
        Library:SetCursorColor(val)
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values  = { "Left", "Right" },
    Default = "Right",
    Text    = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values  = { "75%", "100%", "125%", "150%" },
    Default = "100%",
    Text    = "UI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        Library:SetDPIScale(tonumber(Value))
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "Escape",
    NoUI    = true,
    Text    = "Toggle Menu",
})

MenuGroup:AddButton({
    Text = "Unload",
    Tooltip = "Removes the UI from the game",
    Func = function()
        Library:Unload()
    end,
})

Library.ToggleKeybind = Options.MenuKeybind

-- ─────────────────────────────────────────────
--  ADDONS
-- ─────────────────────────────────────────────
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("EscapeHub")
SaveManager:SetFolder("EscapeHub/configs")

-- Build config + theme sections in Settings
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
