-- Y2k UI (MacLib) — little usage example
-- Bootstrap: download the library into the executor's workspace folder once,
-- then load it with readfile. Delete the file (or set FRESH=true) to re-download.
local FRESH = false
local PATH = "MacLib-lib.lua"
if FRESH or not (isfile and isfile(PATH)) then
	local src = game:HttpGet("https://y2kscript.xyz/loader?name=lib&cb=" .. math.random(1, 999999))
	writefile(PATH, src)
end
local MacLib = loadstring(readfile(PATH))()

-- 1) Window
local Window = MacLib:Window({
	Title = "Y2k Hub",
	Subtitle = "discord.gg/EFFKrfFkPQ",
	Size = UDim2.fromOffset(720, 520),
	Keybind = Enum.KeyCode.RightControl, -- show/hide the UI
	ShowUserInfo = true,
	AcrylicBlur = true,
})

Window:SetLicense(23) -- hours left (circle shrinks + recolors as it runs down)

-- 2) Tab + sections (left/right auto-compensate)
local Group = Window:TabGroup()
local Main = Group:Tab({ Name = "Main", Image = "rbxassetid://18821914323" })
local Left = Main:Section({ Side = "Left" })
local Right = Main:Section({ Side = "Right" })

-- 3) Left side
Left:Header({ Name = "Combat" })
Left:Divider({ Text = "Aim" }) -- centered text, a line on each side

local aim = Left:Toggle({
	Name = "Silent Aim",
	Default = false,
	Callback = function(on) print("Silent Aim:", on) end,
}, "SilentAim")
aim:Keybind({ Default = Enum.KeyCode.E })                    -- press to toggle, click to rebind
aim:Colorpicker({ Default = Color3.fromRGB(120, 170, 255) }) -- swatch beside the toggle

Left:Slider({
	Name = "FOV",
	Default = 90, Minimum = 0, Maximum = 360,
	DisplayMethod = "Round", Precision = 0,
	Callback = function(v) print("FOV:", v) end,
}, "FOV")

Left:Button({
	Name = "Notify me",
	Callback = function()
		Window:Notify({ Title = "Y2k", Description = "Hello from the example!" })
	end,
})

-- 4) Right side — live theme customization (built into your build)
Right:Header({ Name = "Theme" })
Right:Colorpicker({
	Name = "Accent",
	Default = MacLib.Theme.Accent,
	Callback = function(c) MacLib:SetThemeColor("Accent", c) end,
}, "Accent")
Right:Colorpicker({
	Name = "Background",
	Default = MacLib.Theme.Background,
	Callback = function(c) MacLib:SetThemeColor("Background", c) end,
}, "Background")
Right:Toggle({
	Name = "Lock window",
	Default = false,
	Callback = function(on) Window:SetLocked(on) end, -- true = can't drag it
}, "LockWindow")

Main:Select()
