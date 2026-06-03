--[[
    ObsidianUi - Developer API & Configuration Guide (Aesthetic Customization Edition)
    
    This guide documents the API, layouts, features, and styling of the ObsidianUi library.
    It is designed to serve as clear context for both developers and AI assistants.

    =====================================================================================
    1. INITIALIZATION & SETUP
    =====================================================================================
    To load the UI library, theme manager, and save manager, load them from your repository:
        local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
        local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
        local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    =====================================================================================
    2. CREATING A WINDOW
    =====================================================================================
    Library:CreateWindow(WindowInfo) instantiates the main application frame.
    Parameters in WindowInfo:
        - Title (string): Main window title. Shown in the top bar.
        - Footer (string): Text shown in the footer.
        - NotifySide (string): Position of notifications ("Left" or "Right").
        - ShowCustomCursor (boolean): Set true to enable custom crosshair cursor tracking.
        - Center (boolean): Automatically centers the window on the screen upon load.
        - AutoShow (boolean): Automatically opens the window upon loading.
        - Resizable (boolean): Enables resizing handle in the bottom-right corner.
        - CornerRadius (number): Radius of rounded elements (default 10).

    =====================================================================================
    3. CREATING TABS
    =====================================================================================
    Window:AddTab(Name, IconName) creates a tab page and a tab selector button.
        - Name (string): Tab title.
        - IconName (string): Lucide icon identifier (e.g. "home", "swords", "eye", "settings").
    Returns a Tab object.

    =====================================================================================
    4. CREATING GROUPBOXES
    =====================================================================================
    Tabs support Left and Right column layout using Groupboxes:
        local Groupbox = Tab:AddLeftGroupbox(Name, IconName)
        local Groupbox = Tab:AddRightGroupbox(Name, IconName)
    If no IconName is specified, it auto-maps keywords (like "Player" -> "user", etc.).
    Returns a Groupbox object.

    =====================================================================================
    5. ADDING UI COMPONENTS TO GROUPBOXES
    =====================================================================================
    Groupbox objects support the following method chain interfaces:

    A. Toggles:
        Groupbox:AddToggle(Index, { Text = "Label", Default = false, Callback = function(state) ... })
        - Stores toggle state inside the global table `Library.Toggles[Index]`.
        - Chainable: supports adding keybinds or color pickers, e.g.:
          `AddToggle(...):AddKeyPicker(Index, ...) :AddColorPicker(Index, ...)`

    B. Sliders (Smooth Tweens):
        Groupbox:AddSlider(Index, { Text = "Label", Min = 0, Max = 100, Default = 10, Rounding = 0, Suffix = "", Callback = function(val) ... })
        - Fills the slider track smoothly with a quad out tween animation over 0.08 seconds.
        - Stores state inside the global table `Library.Options[Index]`.

    C. Dropdowns:
        Groupbox:AddDropdown(Index, { Text = "Label", Values = { "A", "B" }, Default = "A", Multi = false, Callback = function(selected) ... })
        - Custom lists supporting single-select or multi-select dropdowns.
        - Stores option reference in `Library.Options[Index]`.

    D. KeyPickers (Keybinds):
        Groupbox:AddLabel("Keybind"):AddKeyPicker(Index, { Default = "Q", Mode = "Hold", Text = "Key Label" })
        - Allows registering keyboard shortcuts.
        - Binds a visible setting button in the UI next to the label.
        - Note: The floating keybinds indicator list has been removed, but callbacks and shortcuts remain fully functional.

    E. Buttons:
        Groupbox:AddButton({ Text = "Click Me", Tooltip = "Optional tip", Func = function() ... })
        - Compact clickable buttons that trigger immediate actions.

    F. Labels & Dividers:
        Groupbox:AddLabel("Text Content")
        Groupbox:AddDivider()

    =====================================================================================
    6. THEME & AUTO-SAVE CONFIGURATION
    =====================================================================================
    Integrate SaveManager & ThemeManager to manage player settings automatically:
        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)
        ThemeManager:SetFolder("ProjectName")
        SaveManager:SetFolder("ProjectName/configs")
        ThemeManager:ApplyToTab(Tab)         -- Adds theme control section
        SaveManager:BuildConfigSection(Tab)  -- Adds configuration save/load section
        SaveManager:LoadAutoloadConfig()     -- Restores player's saved auto-load config
]]

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
    Combat   = Window:AddTab("Combat",      "swords"),
    Visual   = Window:AddTab("Visuals",     "eye"),
    Misc     = Window:AddTab("Misc",        "package"),
    Configs  = Window:AddTab("Configs",     "database"),
    Settings = Window:AddTab("Settings",    "settings"),
    Credits  = Window:AddTab("Credits",     "info"),
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
--  MISC TAB
-- ─────────────────────────────────────────────
local MiscLeft  = Tabs.Misc:AddLeftGroupbox("Fun")
local MiscRight = Tabs.Misc:AddRightGroupbox("Utility")

MiscLeft:AddButton({
    Text = "Spin Bot",
    Tooltip = "Triggers a spin bot action",
    Func = function()
        Library:Notify("Spin Bot Activated!")
    end,
})

MiscRight:AddToggle("InfJump", {
    Text    = "Infinite Jump",
    Default = false,
    Tooltip = "Enables jumping infinitely in the air",
    Callback = function(val)
        -- logic
    end,
})

-- ─────────────────────────────────────────────
--  CREDITS TAB
-- ─────────────────────────────────────────────
local CreditsLeft = Tabs.Credits:AddLeftGroupbox("Information")
CreditsLeft:AddLabel("Developer: Melio")
CreditsLeft:AddLabel("UI Designer: Antigravity")
CreditsLeft:AddLabel("Version: 2.0.0")
CreditsLeft:AddLabel("Theme: Deep Ocean Cyan Gradient")

-- ─────────────────────────────────────────────
--  SETTINGS TAB
-- ─────────────────────────────────────────────
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Interface")

MenuGroup:AddButton({
    Text = "Test Notification (Success)",
    Func = function()
        Library:Notify({
            Title = "Action Completed",
            Description = "Feature loaded successfully!",
            Time = 5
        })
    end,
})

MenuGroup:AddButton({
    Text = "Test Notification (Error)",
    Func = function()
        Library:Notify({
            Title = "Warning Alert",
            Description = "Verification failed, please retry.",
            Time = 5
        })
    end,
})

MenuGroup:AddButton({
    Text = "Test Notification (Info)",
    Func = function()
        Library:Notify({
            Title = "System Notification",
            Description = "Updates are available for this script.",
            Time = 5
        })
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

-- Build config section in Configs tab, and theme section in Settings
SaveManager:BuildConfigSection(Tabs.Configs)
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
