--[[
    ObsidianUi - Complete Developer API & Documentation Guide
    Y2k Script Back2Back | UI Library v2.0

    This file documents every feature, option, and design decision of the ObsidianUi library.
    It serves as the authoritative reference for developers and AI assistants working on this project.

    =====================================================================================
    1. INITIALIZATION & SETUP
    =====================================================================================
    Load the UI library and its addons from your repository URL:

        local repo = "https://raw.githubusercontent.com/Y2kScriptBack2Back/ObsidianUi/main/"
        local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
        local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
        local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

    For local testing (Roblox executor):
        local Library      = loadstring(readfile("Library.lua"))()
        local ThemeManager = loadstring(readfile("addons/ThemeManager.lua"))()
        local SaveManager  = loadstring(readfile("addons/SaveManager.lua"))()

    =====================================================================================
    2. CREATING A WINDOW
    =====================================================================================
    Library:CreateWindow(WindowInfo) instantiates the main application frame.

    Parameters in WindowInfo (all optional, defaults shown):
        Title            (string)  = "No Title"     — Window title shown in the top bar.
        Footer           (string)  = "No Footer"     — Text shown in the footer bar.
        NotifySide       (string)  = "Right"         — Notification position: "Left" or "Right".
        ShowCustomCursor (boolean) = true            — Enable the cyan crosshair cursor.
        Center           (boolean) = true            — Center window on screen at startup.
        AutoShow         (boolean) = true            — Show the window immediately on load.
        Resizable        (boolean) = true            — Enable drag-to-resize handle.
        CornerRadius     (number)  = 10              — Border radius of all UI elements.
        Size             (UDim2)   = 720x600         — Initial window size.
        Font             (Enum)    = Jura             — Font used throughout the UI.
        ToggleKeybind    (Enum)    = RightControl     — Key to show/hide the window.

    Example:
        local Window = Library:CreateWindow({
            Title = "My Script",
            Footer = "by Developer",
            NotifySide = "Right",
            ShowCustomCursor = true,
            Center = true,
            AutoShow = true,
            Resizable = true,
            CornerRadius = 10,
        })

    =====================================================================================
    3. CREATING TABS
    =====================================================================================
    Window:AddTab(Name, IconName) creates a tab page and its button in the left sidebar.
        - Name     (string): Label shown on the tab button.
        - IconName (string): Lucide icon name. See Section 7 for confirmed working icons.
    Returns a Tab object.

    IMPORTANT - Tab ordering rules:
        - Tabs are shown in the order they are created.
        - "Settings" tab is ALWAYS placed second-to-last (LayoutOrder = 99998).
        - "Credits"  tab is ALWAYS placed last       (LayoutOrder = 99999).
        - All other tabs appear in creation order.

    Selected tab visuals:
        - A 3px cyan accent bar appears on the left edge of the selected tab button.
        - The selected tab has a subtle glass-style background highlight (semi-transparent).
        - Hovering a non-selected tab shows a faint background glow for feedback.
        - Tab icon and label fade to full opacity when selected, dimmed when not.

    Example:
        local Tabs = {
            Main     = Window:AddTab("Main",     "home"),
            Combat   = Window:AddTab("Combat",   "swords"),
            Visuals  = Window:AddTab("Visuals",  "eye"),
            Misc     = Window:AddTab("Misc",     "package"),
            Configs  = Window:AddTab("Configs",  "database"),
            Settings = Window:AddTab("Settings", "settings"),  -- always 2nd to last
            Credits  = Window:AddTab("Credits",  "info"),       -- always last
        }

    =====================================================================================
    4. CREATING GROUPBOXES
    =====================================================================================
    Each tab has a LEFT column and a RIGHT column. Use groupboxes to fill them.

        local Left  = Tab:AddLeftGroupbox("Name", "icon-name")
        local Right = Tab:AddRightGroupbox("Name", "icon-name")

    If no IconName is provided, the library auto-maps common names:
        "Player"    -> "user"       "Movement"  -> "activity"   "Aim"       -> "crosshair"
        "Combat"    -> "shield"     "ESP"       -> "eye"        "World"     -> "map"
        "Fun"       -> "smile"      "Utility"   -> "wrench"     "Interface" -> "monitor"
        "Misc"      -> "package"    "Config"    -> "database"   "Info"      -> "info"
        "Credit"    -> "heart"      "Settings"  -> "settings"   "Save"      -> "save"
        "Theme"     -> "palette"    (anything else -> "package")

    Each groupbox header shows the icon + name with a subtle separator line below it.
    Returns a Groupbox object.

    Tabboxes (sub-tabs inside a groupbox column):
        local Tabbox = Tab:AddLeftTabbox()
        local SubTab = Tabbox:AddTab("Sub Tab Name")
        SubTab:AddToggle(...)   -- elements go inside the sub-tab

    =====================================================================================
    5. ADDING UI COMPONENTS
    =====================================================================================

    -- A. TOGGLE --
    Groupbox:AddToggle(Index, {
        Text     = "Label",           -- (string)  displayed name
        Default  = false,             -- (boolean) initial state
        Tooltip  = "Hint text",       -- (string)  shown on hover
        Risky    = false,             -- (boolean) renders text in red if true
        Disabled = false,             -- (boolean) grays out the toggle
        Callback = function(val) end, -- fires when state changes
    })
    Access: Library.Toggles["Index"].Value
    Chain:  :AddKeyPicker(...)  :AddColorPicker(...)

    -- B. SLIDER (Smooth Tweens) --
    Groupbox:AddSlider(Index, {
        Text     = "Label",
        Default  = 50,   Min = 0,   Max = 100,
        Rounding = 0,               -- decimal places (0 = integer)
        Suffix   = " px",           -- appended to displayed value
        Prefix   = "",              -- prepended to displayed value
        Callback = function(val) end,
    })
    Fill bar tweens smoothly (0.08s Quad Out). Access: Library.Options["Index"].Value

    -- C. DROPDOWN --
    Groupbox:AddDropdown(Index, {
        Text    = "Label",
        Values  = { "Option A", "Option B" },
        Default = "Option A",       -- or { "A", "B" } for multi-select
        Multi   = false,            -- true = multi-select checkboxes
        Callback = function(val) end,
    })
    Access: Library.Options["Index"].Value

    -- D. BUTTON --
    Groupbox:AddButton({
        Text        = "Click Me",
        Tooltip     = "Hint",
        Risky       = false,        -- text in red if true
        DoubleClick = false,        -- requires second click to confirm
        Func        = function() end,
    })
    Sub-button: Groupbox:AddButton({ ... }):AddButton({ Text = "Also", Func = ... })

    -- E. LABEL & DIVIDER --
    Groupbox:AddLabel("Static text")
    Groupbox:AddLabel({ Text = "Wrap text", DoesWrap = true, Size = 14 })
    Groupbox:AddDivider()

    -- F. INPUT BOX --
    Groupbox:AddInput(Index, {
        Text = "Label",  Default = "",  Placeholder = "Type here...",
        Numeric = false,  Finished = false,  Callback = function(val) end,
    })

    -- G. COLOR PICKER --
    Groupbox:AddLabel("Color"):AddColorPicker(Index, {
        Default = Color3.fromRGB(0, 210, 229),  Title = "Picker Title",
        Transparency = 0,   Callback = function(color) end,
    })

    -- H. KEYBIND (KEY PICKER) --
    Groupbox:AddLabel("Action"):AddKeyPicker(Index, {
        Default = "Q",              -- key name string or "None"
        Mode    = "Toggle",         -- "Toggle", "Hold", or "Always"
        Text    = "Display label",
        Callback = function(state) end,
    })
    Note: The floating keybind panel is removed. Binds still work via InputBegan.

    =====================================================================================
    6. NOTIFICATIONS
    =====================================================================================
    Library:Notify({ Title = "...", Description = "...", Time = 5 })
    Library:Notify("Simple message")          -- string form, 5s default
    Library:Notify("Message", seconds, soundId)

    Icon and accent stripe color are auto-detected from Title + Description keywords:

        Keyword                   | Icon   | Accent color
        --------------------------+--------+-----------------------------
        success/done/loaded/complet| check | Green  RGB(50, 210, 120)
        error/fail/warn/alert      | x     | Red    RGB(255, 80,  80)
        (default)                  | info  | Cyan   AccentColor

    Each notification has a 3px colored left stripe + matching icon color.
    Update while visible:
        local N = Library:Notify({ Title = "Loading...", Time = 30 })
        N:ChangeTitle("Done!")
        N:ChangeDescription("Completed.")

    =====================================================================================
    7. ICONS REFERENCE (Lucide for Roblox)
    =====================================================================================
    Usage: Window:AddTab("Name", "icon-name")
           Tab:AddLeftGroupbox("Name", "icon-name")

    CONFIRMED WORKING:
        "home"  "settings"  "info"   "package"  "database"  "eye"
        "swords" "key"  "user"  "activity"  "crosshair"  "shield"
        "map"  "smile"  "wrench"  "monitor"  "palette"  "save"
        "heart"  "check"  "chevron-up"  "move-diagonal-2"

    AVOID (do not exist in this Lucide version):
        "bell"           -> use "info"    "circle-check"   -> use "check"
        "triangle-alert" -> use "x"       "alert-triangle" -> use "x"
        "globe"          -> use "map"     "scan"           -> use "eye"
        "face-smile"     -> use "smile"   "tool"           -> use "wrench"

    Browse all names at: https://lucide.dev/icons/ (use exact kebab-case name)

    =====================================================================================
    8. AESTHETIC FEATURES
    =====================================================================================
    Window: diagonal gradient (navy → teal, 45°), separator lines, rounded corners.
    Tabs:   selected tab shows 3px cyan indicator bar + subtle glass highlight.
            hover shows faint glow; all transitions are tweened (0.1s Quad Out).
    Logo:   36×36px, 8px rounded corners, cyan UIStroke outline.
    Sliders: fill animates via TweenService (0.08s Quad Out).
    Cursor: custom crosshair; color via Library:SetCursorColor(Color3.fromRGB(...))
    Drag:   window fades to 18% transparency while dragged, restores on release.
    Notifications: slide in from screen edge; colored stripe + icon per type.

    =====================================================================================
    9. THEME & AUTO-SAVE CONFIGURATION
    =====================================================================================
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    ThemeManager:SetFolder("ProjectName")
    SaveManager:SetFolder("ProjectName/configs")
    ThemeManager:ApplyToTab(Tabs.Settings)       -- adds theme picker to Settings tab
    SaveManager:BuildConfigSection(Tabs.Configs) -- adds config UI to Configs tab
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
    SaveManager:IgnoreThemeSettings()
    SaveManager:LoadAutoloadConfig()             -- restore auto-load on start

    =====================================================================================
    10. MISC UTILITIES
    =====================================================================================
    Library.ToggleKeybind = Options.MenuKeybind  -- bind toggle to a KeyPicker
    Library:SetNotifySide("Left" or "Right")
    Library:SetDPIScale(100)                     -- 75, 100, 125, or 150
    Library:Unload()                             -- destroy UI + disconnect signals

    Color scheme:
        Library.Scheme.BackgroundColor  -- deep dark navy (main bg)
        Library.Scheme.MainColor        -- lighter navy (panels, buttons)
        Library.Scheme.AccentColor      -- cyan RGB(0,210,229)
        Library.Scheme.OutlineColor     -- teal RGB(0,59,77)
        Library.Scheme.FontColor        -- white (all text)
    After changes: Library:UpdateColorsUsingRegistry()
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
    Combat   = Window:AddTab("Combat",      "swords"),
    Visual   = Window:AddTab("Visuals",     "eye"),
    Misc     = Window:AddTab("Misc",        "package"),
    Configs  = Window:AddTab("Configs",     "database"),
    Settings = Window:AddTab("Settings",    "settings"),
    Credits  = Window:AddTab("Credits",     "info"),
}

-- ─────────────────────────────────────────────
--  COMBAT TAB
-- ─────────────────────────────────────────────
local CombatLeft  = Tabs.Combat:AddLeftGroupbox("Aim",  "crosshair")
local CombatRight = Tabs.Combat:AddRightGroupbox("Misc", "shield")

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
local VisualLeft  = Tabs.Visual:AddLeftGroupbox("ESP",   "eye")
local VisualRight = Tabs.Visual:AddRightGroupbox("World", "map")

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
local MiscLeft  = Tabs.Misc:AddLeftGroupbox("Fun",     "smile")
local MiscRight = Tabs.Misc:AddRightGroupbox("Utility", "wrench")

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
local CreditsLeft = Tabs.Credits:AddLeftGroupbox("Information", "info")
CreditsLeft:AddLabel("Developer: Melio")
CreditsLeft:AddLabel("UI Designer: Antigravity")
CreditsLeft:AddLabel("Version: 2.0.0")
CreditsLeft:AddLabel("Theme: Deep Ocean Cyan Gradient")

-- ─────────────────────────────────────────────
--  SETTINGS TAB
-- ─────────────────────────────────────────────
local MenuGroup = Tabs.Settings:AddLeftGroupbox("Interface", "monitor")

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
