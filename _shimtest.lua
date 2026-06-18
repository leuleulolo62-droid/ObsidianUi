local Library = loadstring(game:HttpGet("https://y2kscript.xyz/lib?f=Library-y2k.lua&cb="..math.random(1,99999)))()

local Window = Library:CreateWindow({ Title = "Shim Test", Footer = "compat check" })
local Tabs = {
    Main    = Window:AddTab("Main", "home"),
    Visuals = Window:AddTab("Visuals", "eye"),
}

local box = Tabs.Main:AddLeftGroupbox("Aim", "crosshair")
box:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Tooltip = "test toggle",
    Callback = function(v) print("toggle ->", v) end })
box:AddSlider("FOV", { Text = "FOV", Default = 90, Min = 0, Max = 360, Rounding = 0,
    Callback = function(v) print("slider ->", v) end })
box:AddDropdown("Part", { Text = "Hit Part", Values = { "Head", "Torso", "Random" }, Default = "Head",
    Callback = function(v) print("dropdown ->", v) end })
box:AddDivider()
box:AddButton({ Text = "Notify", Func = function() Library:Notify({ Title = "Y2k", Description = "button works!" }) end })
box:AddLabel("ESP Color"):AddColorPicker("ESPColor", { Default = Color3.fromRGB(0,255,255),
    Callback = function(c) print("color ->", c) end })
box:AddLabel("Aim Key"):AddKeyPicker("AimKey", { Default = "E", Text = "Aim",
    Callback = function() print("keybind fired") end })

local right = Tabs.Main:AddRightGroupbox("Misc", "shield")
right:AddToggle("Fly", { Text = "Fly", Default = true, Callback = function(v) print("fly", v) end })
right:AddButton({ Text = "Unload", Func = function() Library:Unload() end })

task.wait(1)
warn("=== VALUES (what your cheats read) ===")
warn("SilentAim.Value = " .. tostring(Library.Toggles.SilentAim.Value))
warn("FOV.Value = " .. tostring(Library.Options.FOV.Value))
warn("Part.Value = " .. tostring(Library.Options.Part.Value))
warn("ESPColor.Value = " .. tostring(Library.Options.ESPColor.Value))
