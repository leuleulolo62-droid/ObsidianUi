--[[
	RIVALS — Y2k (Obsidian) UI
	Production build. Every feature wraps the game's OWN client Lua layer
	(instance-level method shadowing) or fires a real remote, all pcall-guarded.

	AC posture (recovered from the Luraph VM constant pool): the anti-cheat
	detects hooks via iscclosure/islclosure (closure-type flips) and metatable
	locks, and reports over HttpService. Therefore this script NEVER hookfunction's
	a native/Roblox API function and NEVER hooks a global metamethod. It only
	shadows methods on the game's own Lua class instances (lua closures), reads
	passively, and renders client-side. Server-facing actions stay plausible.

	Lua 5.1-safe Luau: no +=, no continue, no a?b:c ternary.
]]

--// Services
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Lighting         = game:GetService("Lighting")
local Collection       = game:GetService("CollectionService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

--// UI library (Y2k / Obsidian stack)
local repo = "https://y2kscript.xyz/lib?f="
local Library      = loadstring(game:HttpGet(repo .. "Library-y2k.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager-y2k.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager-y2k.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------
local Flags = {
	-- combat
	SilentAim       = false,
	SilentRage      = false,   -- false = legit (FOV gated), true = rage (lock nearest)
	AimFovRadius    = 110,
	AimHitbox       = "Head",  -- Head / Body / Nearest
	AimVisibleCheck = true,
	AimTeamCheck    = true,
	AimPrediction   = 0.0,
	NoSpread        = false,
	NoRecoil        = false,
	Triggerbot      = false,
	TriggerDelay    = 0.03,
	HitboxExpander  = false,
	HitboxSize      = 8,
	ShowFov         = false,
	-- esp
	EspEnabled   = false,
	EspBox       = true,
	EspName      = true,
	EspHealth    = true,
	EspDistance  = true,
	EspTracer    = false,
	EspTeamCheck = true,
	EspMaxDist   = 1000,
	EspColor     = Color3.fromRGB(0, 210, 229),
	-- movement
	WalkSpeedOn = false, WalkSpeed = 16,
	JumpOn      = false, JumpPower = 50,
	InfJump     = false,
	FlyOn       = false, FlySpeed = 60,
	NoclipOn    = false,
	-- player
	AntiAfk   = false,
	CustomFov = false, FovValue = 70,
	Fullbright= false,
	-- game
	AutoQueue = false,
}

local Connections = {}   -- RBXScriptConnections to clean
local Threads     = {}   -- active loop markers
local Restores    = {}   -- functions to undo hooks/resizes on unload
local Drawings    = {}   -- ESP drawing objects per player

local function track(conn)
	Connections[#Connections + 1] = conn
	return conn
end

----------------------------------------------------------------------
-- SAFE RESOLVERS (cached, re-resolved defensively)
----------------------------------------------------------------------
local PS = LocalPlayer:WaitForChild("PlayerScripts")

local function tryRequire(inst)
	if not inst then return nil end
	local ok, mod = pcall(require, inst)
	if ok then return mod end
	return nil
end

local FighterController
local function getFC()
	if FighterController then return FighterController end
	local node = PS:FindFirstChild("Controllers")
	node = node and node:FindFirstChild("FighterController")
	FighterController = tryRequire(node)
	return FighterController
end

local function getFighter()
	local FC = getFC()
	if not FC then return nil end
	local f = rawget(FC, "LocalFighter")
	if f == nil then
		local ok, r = pcall(function() return FC.LocalFighter end)
		if ok then f = r end
	end
	return f
end

-- resolve a remote under ReplicatedStorage.Remotes by path segments
local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
local function getRemote(...)
	if not RemotesFolder then return nil end
	local node = RemotesFolder
	local segs = { ... }
	local i = 1
	while node and i <= #segs do
		node = node:FindFirstChild(segs[i])
		i = i + 1
	end
	return node
end

----------------------------------------------------------------------
-- TARGETING (passive reads only)
----------------------------------------------------------------------
local HITBOX_NAMES = {
	Head = { "HitboxHead", "HitboxHeadSmall", "Head" },
	Body = { "HitboxBody", "HitboxBodySmall", "HumanoidRootPart", "UpperTorso" },
}

local function firstChild(model, names)
	local i = 1
	while i <= #names do
		local p = model:FindFirstChild(names[i])
		if p then return p end
		i = i + 1
	end
	return nil
end

local function isAlive(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return false end
	return char ~= nil
end

local function isEnemy(plr, teamCheck)
	if plr == LocalPlayer then return false end
	if not teamCheck then return true end
	local mine  = LocalPlayer:GetAttribute("TeamID")
	local their = plr:GetAttribute("TeamID")
	if mine == nil or their == nil then return true end
	return mine ~= their
end

local function worldToScreen(pos)
	local v, on = Camera:WorldToViewportPoint(pos)
	return Vector2.new(v.X, v.Y), on, v.Z
end

-- raycast visibility from camera to target, ignoring local + target char
local function isVisible(targetPart, targetChar)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = { Camera }
	if LocalPlayer.Character then filter[#filter + 1] = LocalPlayer.Character end
	if targetChar then filter[#filter + 1] = targetChar end
	params.FilterDescendantsInstances = filter
	local origin = Camera.CFrame.Position
	local dir = targetPart.Position - origin
	local res = Workspace:Raycast(origin, dir, params)
	return res == nil
end

-- choose the best silent-aim target; returns { part=, aimPos=, char= } or nil
local function getSilentTarget()
	local center = Camera.ViewportSize * 0.5
	local best, bestScore
	local players = Players:GetPlayers()
	local i = 1
	while i <= #players do
		local plr = players[i]
		local char = plr.Character
		if char and isAlive(char) and isEnemy(plr, Flags.AimTeamCheck) then
			local wantNames
			if Flags.AimHitbox == "Body" then
				wantNames = HITBOX_NAMES.Body
			else
				wantNames = HITBOX_NAMES.Head
			end
			local part = firstChild(char, wantNames) or firstChild(char, HITBOX_NAMES.Body)
			if part then
				local screen, onScreen, depth = worldToScreen(part.Position)
				if onScreen and depth > 0 then
					local dist = (screen - center).Magnitude
					local pass
					if Flags.SilentRage then
						pass = true
					else
						pass = dist <= Flags.AimFovRadius
					end
					if pass and (not Flags.AimVisibleCheck or isVisible(part, char)) then
						if not bestScore or dist < bestScore then
							bestScore = dist
							-- prediction (lead by velocity)
							local aim = part.Position
							if Flags.AimPrediction > 0 then
								local vel = part.AssemblyLinearVelocity
								aim = aim + vel * Flags.AimPrediction
							end
							best = { part = part, aimPos = aim, char = char }
						end
					end
				end
			end
		end
		i = i + 1
	end
	return best
end

----------------------------------------------------------------------
-- COMBAT HOOKS (instance/singleton method shadowing — no native hooks)
----------------------------------------------------------------------
local K0, K1, K2, K3 = string.char(0), string.char(1), string.char(2), string.char(3)

-- Silent Aim: shadow GetCameraData on the LocalFighter instance so the game's
-- own validated fire path sends our redirected aim. Re-applied on respawn.
local function ensureSilentAimHook()
	local fighter = getFighter()
	if not fighter then return end
	if rawget(fighter, "__y2k_gcd") then return end
	local orig = fighter.GetCameraData     -- resolves the class method
	if type(orig) ~= "function" then return end
	rawset(fighter, "__y2k_gcd", orig)
	fighter.GetCameraData = function(self, ...)
		local cd = orig(self, ...)
		if Flags.SilentAim and self == getFighter() and type(cd) == "table" then
			pcall(function()
				local origin = cd[K0]
				if not origin then return end
				local target = getSilentTarget()
				if target then
					local op = origin.Position
					cd[K1] = CFrame.new(op, target.aimPos)
					if Flags.SilentRage then
						cd[K2] = target.part
						cd[K3] = CFrame.new()
					end
				end
			end)
		end
		return cd
	end
	Restores[#Restores + 1] = function()
		local f = getFighter()
		if f and rawget(f, "__y2k_gcd") then
			f.GetCameraData = rawget(f, "__y2k_gcd")
			rawset(f, "__y2k_gcd", nil)
		end
	end
end

-- No Spread: shadow GetSpread on the GameplayUtility singleton -> identity.
local function ensureNoSpreadHook()
	local GU = tryRequire(ReplicatedStorage.Modules:FindFirstChild("GameplayUtility"))
	if not GU then return end
	if rawget(GU, "__y2k_spread") then return end
	local mt = getmetatable(GU)
	local owner = (mt and rawget(mt, "__index")) or GU
	if type(owner) ~= "table" then owner = GU end
	pcall(setreadonly, owner, false)
	local orig = owner.GetSpread
	if type(orig) ~= "function" then return end
	rawset(GU, "__y2k_spread", true)
	owner.GetSpread = function(self, ...)
		if Flags.NoSpread then return CFrame.new() end
		return orig(self, ...)
	end
	Restores[#Restores + 1] = function()
		pcall(function() owner.GetSpread = orig end)
	end
end

-- No Recoil: replace _Recoil on the Gun item class -> no-op while flagged.
local function ensureNoRecoilHook()
	local node = PS:FindFirstChild("Modules")
	node = node and node:FindFirstChild("ItemTypes")
	node = node and node:FindFirstChild("Gun")
	local GunClass = tryRequire(node)
	if not GunClass then return end
	if rawget(GunClass, "__y2k_recoil") then return end
	pcall(setreadonly, GunClass, false)
	local orig = rawget(GunClass, "_Recoil")
	if type(orig) ~= "function" then return end
	rawset(GunClass, "__y2k_recoil", true)
	GunClass._Recoil = function(self, ...)
		if Flags.NoRecoil then return end
		return orig(self, ...)
	end
	Restores[#Restores + 1] = function()
		pcall(function() GunClass._Recoil = orig end)
	end
end

-- maintenance loop: keep hooks applied across respawns while any combat flag is on
local function startCombatMaintainer()
	if Threads.combat then return end
	Threads.combat = true
	task.spawn(function()
		while Threads.combat do
			pcall(ensureSilentAimHook)
			pcall(ensureNoSpreadHook)
			pcall(ensureNoRecoilHook)
			task.wait(0.5)
		end
	end)
end

----------------------------------------------------------------------
-- TRIGGERBOT (fires the game's own shoot input when aimed at an enemy)
----------------------------------------------------------------------
local function crosshairEnemy()
	-- is the crosshair currently over an enemy hitbox?
	local target = getSilentTarget()
	if not target then return false end
	local center = Camera.ViewportSize * 0.5
	local screen = worldToScreen(target.part.Position)
	return (screen - center).Magnitude <= 18
end

local function startTriggerbot()
	if Threads.trigger then return end
	Threads.trigger = true
	task.spawn(function()
		while Threads.trigger and Flags.Triggerbot do
			local fired = false
			pcall(function()
				if crosshairEnemy() then
					local fighter = getFighter()
					if fighter then
						fighter:Input("StartShooting")
						fired = true
					end
				end
			end)
			if fired then
				task.wait(Flags.TriggerDelay)
			else
				task.wait(0.05)
			end
		end
		Threads.trigger = nil
	end)
end

----------------------------------------------------------------------
-- HITBOX EXPANDER (client raycast aid; restores on disable)
----------------------------------------------------------------------
local expandedParts = {}
local function startHitboxExpander()
	if Threads.hitbox then return end
	Threads.hitbox = true
	task.spawn(function()
		while Threads.hitbox and Flags.HitboxExpander do
			pcall(function()
				local players = Players:GetPlayers()
				local i = 1
				while i <= #players do
					local plr = players[i]
					local char = plr.Character
					if char and isEnemy(plr, true) and isAlive(char) then
						local hb = char:FindFirstChild("HitboxBody")
						if hb and hb:IsA("BasePart") then
							if not expandedParts[hb] then
								expandedParts[hb] = hb.Size
							end
							hb.Size = Vector3.new(Flags.HitboxSize, Flags.HitboxSize, Flags.HitboxSize)
							hb.Transparency = 1
							hb.CanCollide = false
						end
					end
					i = i + 1
				end
			end)
			task.wait(0.4)
		end
		-- restore
		for part, size in pairs(expandedParts) do
			pcall(function() if part and part.Parent then part.Size = size end end)
		end
		expandedParts = {}
		Threads.hitbox = nil
	end)
end

----------------------------------------------------------------------
-- ESP (Drawing API)
----------------------------------------------------------------------
local function newDrawing(class, props)
	local ok, d = pcall(function() return Drawing.new(class) end)
	if not ok then return nil end
	for k, v in pairs(props) do
		pcall(function() d[k] = v end)
	end
	return d
end

local function makeEsp(plr)
	if Drawings[plr] then return Drawings[plr] end
	local set = {
		box     = newDrawing("Square",   { Thickness = 1, Filled = false, Visible = false }),
		boxOut  = newDrawing("Square",   { Thickness = 3, Filled = false, Visible = false, Color = Color3.new(0,0,0) }),
		name    = newDrawing("Text",     { Size = 13, Center = true, Outline = true, Visible = false }),
		dist    = newDrawing("Text",     { Size = 12, Center = true, Outline = true, Visible = false }),
		health  = newDrawing("Line",     { Thickness = 2, Visible = false }),
		healthBg= newDrawing("Line",     { Thickness = 2, Visible = false, Color = Color3.new(0,0,0) }),
		tracer  = newDrawing("Line",     { Thickness = 1, Visible = false }),
	}
	Drawings[plr] = set
	return set
end

local function hideEsp(set)
	for _, d in pairs(set) do
		if d then pcall(function() d.Visible = false end) end
	end
end

local function clearEsp()
	for plr, set in pairs(Drawings) do
		for _, d in pairs(set) do
			if d then pcall(function() d:Remove() end) end
		end
		Drawings[plr] = nil
	end
end

local function updateEsp()
	if not Flags.EspEnabled then
		for _, set in pairs(Drawings) do hideEsp(set) end
		return
	end
	local color = Flags.EspColor
	local players = Players:GetPlayers()
	local i = 1
	while i <= #players do
		local plr = players[i]
		local set = makeEsp(plr)
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local head = char and char:FindFirstChild("Head")
		local valid = false
		if char and hrp and head and plr ~= LocalPlayer and isAlive(char) then
			local enemy = isEnemy(plr, Flags.EspTeamCheck)
			if enemy or not Flags.EspTeamCheck then
				local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
				if dist <= Flags.EspMaxDist then
					local topPos, onTop = worldToScreen(head.Position + Vector3.new(0, 0.7, 0))
					local botPos, onBot = worldToScreen(hrp.Position - Vector3.new(0, 3.2, 0))
					if onTop or onBot then
						valid = true
						local h = math.abs(botPos.Y - topPos.Y)
						local w = h * 0.55
						local x = topPos.X - w / 2
						local y = topPos.Y
						-- box
						if Flags.EspBox then
							set.boxOut.Size = Vector2.new(w, h); set.boxOut.Position = Vector2.new(x, y); set.boxOut.Visible = true
							set.box.Size = Vector2.new(w, h); set.box.Position = Vector2.new(x, y); set.box.Color = color; set.box.Visible = true
						else
							set.box.Visible = false; set.boxOut.Visible = false
						end
						-- name
						if Flags.EspName then
							set.name.Text = plr.DisplayName or plr.Name
							set.name.Position = Vector2.new(topPos.X, y - 15)
							set.name.Color = color; set.name.Visible = true
						else
							set.name.Visible = false
						end
						-- distance
						if Flags.EspDistance then
							set.dist.Text = string.format("%dm", math.floor(dist))
							set.dist.Position = Vector2.new(topPos.X, y + h + 2)
							set.dist.Color = color; set.dist.Visible = true
						else
							set.dist.Visible = false
						end
						-- health bar
						local hum = char:FindFirstChildOfClass("Humanoid")
						if Flags.EspHealth and hum then
							local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
							local hx = x - 4
							set.healthBg.From = Vector2.new(hx, y); set.healthBg.To = Vector2.new(hx, y + h); set.healthBg.Visible = true
							set.health.From = Vector2.new(hx, y + h * (1 - pct)); set.health.To = Vector2.new(hx, y + h)
							set.health.Color = Color3.fromRGB(255 - math.floor(255 * pct), math.floor(255 * pct), 60)
							set.health.Visible = true
						else
							set.health.Visible = false; set.healthBg.Visible = false
						end
						-- tracer
						if Flags.EspTracer then
							set.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
							set.tracer.To = Vector2.new(topPos.X, y + h)
							set.tracer.Color = color; set.tracer.Visible = true
						else
							set.tracer.Visible = false
						end
					end
				end
			end
		end
		if not valid then hideEsp(set) end
		i = i + 1
	end
end

----------------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------------
local function getHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid"), c
end

local function startMovementMaintainer()
	if Threads.move then return end
	Threads.move = true
	track(RunService.Heartbeat:Connect(function()
		if not Threads.move then return end
		local hum = getHum()
		if hum then
			if Flags.WalkSpeedOn then hum.WalkSpeed = Flags.WalkSpeed end
			if Flags.JumpOn then hum.JumpPower = Flags.JumpPower; hum.UseJumpPower = true end
		end
	end))
end

-- infinite jump
track(UserInputService.JumpRequest:Connect(function()
	if Flags.InfJump then
		local hum = getHum()
		if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end
end))

-- fly
local flyVel
local function startFly()
	if Threads.fly then return end
	Threads.fly = true
	task.spawn(function()
		local hum, char = getHum()
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		while Threads.fly and Flags.FlyOn do
			hum, char = getHum()
			hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				if not flyVel then
					flyVel = Instance.new("BodyVelocity")
					flyVel.MaxForce = Vector3.new(1, 1, 1) * 9e9
					flyVel.P = 9e4
					flyVel.Velocity = Vector3.new(0, 0, 0)
					flyVel.Parent = hrp
				end
				local move = Vector3.new(0, 0, 0)
				local cf = Camera.CFrame
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cf.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cf.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cf.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cf.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.new(0, 1, 0) end
				flyVel.Velocity = move * Flags.FlySpeed
			end
			RunService.RenderStepped:Wait()
		end
		if flyVel then flyVel:Destroy(); flyVel = nil end
		Threads.fly = nil
	end)
end

-- noclip
local function startNoclip()
	if Threads.noclip then return end
	Threads.noclip = true
	track(RunService.Stepped:Connect(function()
		if not Flags.NoclipOn then return end
		local char = LocalPlayer.Character
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") and p.CanCollide then
					p.CanCollide = false
				end
			end
		end
	end))
end

----------------------------------------------------------------------
-- PLAYER
----------------------------------------------------------------------
-- anti-afk
track(LocalPlayer.Idled:Connect(function()
	if Flags.AntiAfk then
		pcall(function()
			local vu = game:GetService("VirtualUser")
			vu:CaptureController()
			vu:ClickButton2(Vector2.new())
		end)
	end
end))

-- custom fov / fullbright maintainer
local savedFog
local function startPlayerMaintainer()
	if Threads.player then return end
	Threads.player = true
	track(RunService.RenderStepped:Connect(function()
		if not Threads.player then return end
		if Flags.CustomFov then pcall(function() Camera.FieldOfView = Flags.FovValue end) end
		if Flags.Fullbright then
			Lighting.Brightness = 3
			Lighting.ClockTime = 12
			Lighting.FogEnd = 1e9
			Lighting.GlobalShadows = false
		end
	end))
end

----------------------------------------------------------------------
-- GAME / MISC
----------------------------------------------------------------------
local function joinQueue()
	local rf = getRemote("Matchmaking", "JoinQueue")
	if rf and rf:IsA("RemoteFunction") then
		pcall(function() rf:InvokeServer() end)
	end
end

local function redeemCode(code)
	local rf = getRemote("Data", "RedeemCode")
	if rf and rf:IsA("RemoteFunction") and code and #code > 0 then
		local ok, res = pcall(function() return rf:InvokeServer(code) end)
		if ok then
			Library:Notify({ Title = "Code", Description = "Submitted: " .. code, Time = 4 })
		end
	end
end

local function respawnNow()
	local re = getRemote("Duels", "RespawnNow")
	if re and re:IsA("RemoteEvent") then
		pcall(function() re:FireServer() end)
	end
end

local function startAutoQueue()
	if Threads.queue then return end
	Threads.queue = true
	task.spawn(function()
		while Threads.queue and Flags.AutoQueue do
			pcall(joinQueue)
			task.wait(6)
		end
		Threads.queue = nil
	end)
end

----------------------------------------------------------------------
-- ESP RENDER LOOP
----------------------------------------------------------------------
track(RunService.RenderStepped:Connect(function()
	pcall(updateEsp)
	-- FOV circle
	if Flags.ShowFov then
		if not Drawings.__fov then
			Drawings.__fov = newDrawing("Circle", { Thickness = 1, Filled = false, NumSides = 64, Color = Color3.fromRGB(0,210,229) })
		end
		local c = Drawings.__fov
		if c then
			c.Radius = Flags.AimFovRadius
			c.Position = Camera.ViewportSize * 0.5
			c.Visible = true
		end
	elseif Drawings.__fov then
		Drawings.__fov.Visible = false
	end
end))

track(Players.PlayerRemoving:Connect(function(plr)
	local set = Drawings[plr]
	if set then
		for _, d in pairs(set) do if d then pcall(function() d:Remove() end) end end
		Drawings[plr] = nil
	end
end))

----------------------------------------------------------------------
-- WINDOW + TABS
----------------------------------------------------------------------
Library.ForceCheckbox = false

local Window = Library:CreateWindow({
	Title = "RIVALS",
	Footer = "Y2k Script Back2Back",
	NotifySide = "Right",
	ShowCustomCursor = true,
	Center = true,
	AutoShow = true,
	Resizable = true,
	CornerRadius = 10,
})

local Tabs = {
	Combat   = Window:AddTab("Combat",   "swords"),
	Visuals  = Window:AddTab("Visuals",  "eye"),
	Movement = Window:AddTab("Movement", "activity"),
	Player   = Window:AddTab("Player",   "user"),
	Game     = Window:AddTab("Game",     "package"),
	Configs  = Window:AddTab("Configs",  "database"),
	Settings = Window:AddTab("Settings", "settings"),
	Credits  = Window:AddTab("Credits",  "info"),
}

----------------------------------------------------------------------
-- COMBAT TAB
----------------------------------------------------------------------
local CombatL = Tabs.Combat:AddLeftGroupbox("Aim", "crosshair")
local CombatR = Tabs.Combat:AddRightGroupbox("Combat", "shield")

CombatL:AddToggle("SilentAim", {
	Text = "Silent Aim", Default = false, Risky = true,
	Tooltip = "Redirects the game's own shot to the target. Legit = FOV-gated.",
	Callback = function(v) Flags.SilentAim = v; if v then startCombatMaintainer() end end,
})
CombatL:AddDropdown("AimMode", {
	Text = "Mode", Values = { "Legit", "Rage" }, Default = "Legit",
	Callback = function(v) Flags.SilentRage = (v == "Rage") end,
})
CombatL:AddDropdown("AimHitbox", {
	Text = "Hitbox", Values = { "Head", "Body" }, Default = "Head",
	Callback = function(v) Flags.AimHitbox = v end,
})
CombatL:AddSlider("AimFov", {
	Text = "FOV Radius", Default = 110, Min = 20, Max = 500, Rounding = 0, Suffix = " px",
	Callback = function(v) Flags.AimFovRadius = v end,
})
CombatL:AddSlider("AimPred", {
	Text = "Prediction", Default = 0, Min = 0, Max = 1, Rounding = 2,
	Tooltip = "Lead moving targets (raise for Bow/Sniper projectiles).",
	Callback = function(v) Flags.AimPrediction = v end,
})
CombatL:AddToggle("AimVisible", {
	Text = "Visible Check", Default = true,
	Callback = function(v) Flags.AimVisibleCheck = v end,
})
CombatL:AddToggle("AimTeam", {
	Text = "Team Check", Default = true,
	Callback = function(v) Flags.AimTeamCheck = v end,
})
CombatL:AddToggle("ShowFov", {
	Text = "Draw FOV Circle", Default = false,
	Callback = function(v) Flags.ShowFov = v end,
})

CombatR:AddToggle("NoSpread", {
	Text = "No Spread", Default = false, Risky = true,
	Callback = function(v) Flags.NoSpread = v; if v then startCombatMaintainer() end end,
})
CombatR:AddToggle("NoRecoil", {
	Text = "No Recoil", Default = false,
	Callback = function(v) Flags.NoRecoil = v; if v then startCombatMaintainer() end end,
})
CombatR:AddToggle("Triggerbot", {
	Text = "Triggerbot", Default = false, Risky = true,
	Tooltip = "Fires the game's shoot input when your crosshair is on an enemy.",
	Callback = function(v) Flags.Triggerbot = v; if v then startTriggerbot() end end,
})
CombatR:AddSlider("TrigDelay", {
	Text = "Trigger Delay", Default = 0.03, Min = 0, Max = 0.5, Rounding = 2, Suffix = " s",
	Callback = function(v) Flags.TriggerDelay = v end,
})
CombatR:AddToggle("HitboxExp", {
	Text = "Hitbox Expander", Default = false, Risky = true,
	Callback = function(v) Flags.HitboxExpander = v; if v then startHitboxExpander() end end,
})
CombatR:AddSlider("HitboxSize", {
	Text = "Hitbox Size", Default = 8, Min = 4, Max = 25, Rounding = 0,
	Callback = function(v) Flags.HitboxSize = v end,
})

----------------------------------------------------------------------
-- VISUALS TAB
----------------------------------------------------------------------
local VisL = Tabs.Visuals:AddLeftGroupbox("ESP", "eye")
local VisR = Tabs.Visuals:AddRightGroupbox("World", "map")

VisL:AddToggle("EspEnabled", { Text = "Enable ESP", Default = false,
	Callback = function(v) Flags.EspEnabled = v end })
VisL:AddToggle("EspBox",     { Text = "Boxes",     Default = true,  Callback = function(v) Flags.EspBox = v end })
VisL:AddToggle("EspName",    { Text = "Names",     Default = true,  Callback = function(v) Flags.EspName = v end })
VisL:AddToggle("EspHealth",  { Text = "Health",    Default = true,  Callback = function(v) Flags.EspHealth = v end })
VisL:AddToggle("EspDistance",{ Text = "Distance",  Default = true,  Callback = function(v) Flags.EspDistance = v end })
VisL:AddToggle("EspTracer",  { Text = "Tracers",   Default = false, Callback = function(v) Flags.EspTracer = v end })
VisL:AddToggle("EspTeam",    { Text = "Team Check", Default = true,  Callback = function(v) Flags.EspTeamCheck = v end })
VisL:AddSlider("EspMaxDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 3000, Rounding = 0, Suffix = " m",
	Callback = function(v) Flags.EspMaxDist = v end })
VisL:AddLabel("ESP Color"):AddColorPicker("EspColor", {
	Default = Color3.fromRGB(0, 210, 229), Title = "ESP Color",
	Callback = function(v) Flags.EspColor = v end,
})

VisR:AddToggle("Fullbright", { Text = "Fullbright", Default = false,
	Callback = function(v) Flags.Fullbright = v; if v then startPlayerMaintainer() else Lighting.GlobalShadows = true end end })
VisR:AddToggle("CustomFov", { Text = "Custom FOV", Default = false,
	Callback = function(v) Flags.CustomFov = v; if v then startPlayerMaintainer() end end })
VisR:AddSlider("FovValue", { Text = "FOV", Default = 70, Min = 40, Max = 120, Rounding = 0,
	Callback = function(v) Flags.FovValue = v end })

----------------------------------------------------------------------
-- MOVEMENT TAB
----------------------------------------------------------------------
local MoveL = Tabs.Movement:AddLeftGroupbox("Speed", "activity")
local MoveR = Tabs.Movement:AddRightGroupbox("Aerial", "move-diagonal-2")

MoveL:AddToggle("WalkSpeedOn", { Text = "WalkSpeed", Default = false,
	Callback = function(v) Flags.WalkSpeedOn = v; if v then startMovementMaintainer() else local h=getHum() if h then h.WalkSpeed=16 end end end })
MoveL:AddSlider("WalkSpeed", { Text = "Speed", Default = 16, Min = 16, Max = 120, Rounding = 0,
	Callback = function(v) Flags.WalkSpeed = v end })
MoveL:AddToggle("JumpOn", { Text = "Jump Power", Default = false,
	Callback = function(v) Flags.JumpOn = v; if v then startMovementMaintainer() end end })
MoveL:AddSlider("JumpPower", { Text = "Power", Default = 50, Min = 50, Max = 250, Rounding = 0,
	Callback = function(v) Flags.JumpPower = v end })

MoveR:AddToggle("InfJump", { Text = "Infinite Jump", Default = false,
	Callback = function(v) Flags.InfJump = v end })
MoveR:AddToggle("FlyOn", { Text = "Fly (WASD/Space/Shift)", Default = false, Risky = true,
	Callback = function(v) Flags.FlyOn = v; if v then startFly() end end })
MoveR:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 60, Min = 20, Max = 250, Rounding = 0,
	Callback = function(v) Flags.FlySpeed = v end })
MoveR:AddToggle("NoclipOn", { Text = "Noclip", Default = false, Risky = true,
	Callback = function(v) Flags.NoclipOn = v; if v then startNoclip() end end })

----------------------------------------------------------------------
-- PLAYER TAB
----------------------------------------------------------------------
local PlayL = Tabs.Player:AddLeftGroupbox("Utility", "wrench")

PlayL:AddToggle("AntiAfk", { Text = "Anti AFK", Default = false,
	Callback = function(v) Flags.AntiAfk = v end })
PlayL:AddButton({ Text = "Respawn Now", Tooltip = "Duels: instant respawn", Func = respawnNow })
PlayL:AddButton({ Text = "Reset Character", Func = function()
	local h = getHum(); if h then pcall(function() h.Health = 0 end) end
end })

----------------------------------------------------------------------
-- GAME TAB
----------------------------------------------------------------------
local GameL = Tabs.Game:AddLeftGroupbox("Matchmaking", "swords")
local GameR = Tabs.Game:AddRightGroupbox("Rewards", "package")

GameL:AddButton({ Text = "Join Queue", Func = joinQueue })
GameL:AddToggle("AutoQueue", { Text = "Auto Queue", Default = false,
	Callback = function(v) Flags.AutoQueue = v; if v then startAutoQueue() end end })

GameR:AddInput("CodeBox", { Text = "Redeem Code", Default = "", Placeholder = "code...", Finished = true,
	Callback = function(v) redeemCode(v) end })

----------------------------------------------------------------------
-- SETTINGS TAB
----------------------------------------------------------------------
local Menu = Tabs.Settings:AddLeftGroupbox("Interface", "monitor")

Menu:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = true,
	Callback = function(v) Library.ShowCustomCursor = v end })
Menu:AddDropdown("NotifSide", { Text = "Notify Side", Values = { "Left", "Right" }, Default = "Right",
	Callback = function(v) Library:SetNotifySide(v) end })
Menu:AddDropdown("DPI", { Text = "UI Scale", Values = { "75%", "100%", "125%", "150%" }, Default = "100%",
	Callback = function(v) Library:SetDPIScale(tonumber((v:gsub("%%", "")))) end })
Menu:AddDivider()
Menu:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Toggle Menu" })
Menu:AddButton({ Text = "Unload", Risky = true, Func = function() Library:Unload() end })

Library.ToggleKeybind = Options.MenuKeybind

----------------------------------------------------------------------
-- CREDITS TAB
----------------------------------------------------------------------
local Cred = Tabs.Credits:AddLeftGroupbox("Information", "info")
Cred:AddLabel("RIVALS — Y2k Script Back2Back")
Cred:AddLabel({ Text = "Every feature wraps the game's own client layer or fires a real remote, pcall-guarded.", DoesWrap = true })
Cred:AddLabel("Version: 1.0.0")

----------------------------------------------------------------------
-- ADDONS (theme + config save/load/autoload)
----------------------------------------------------------------------
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("RivalsY2k")
SaveManager:SetFolder("RivalsY2k/configs")
SaveManager:BuildConfigSection(Tabs.Configs)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

----------------------------------------------------------------------
-- CLEAN UNLOAD
----------------------------------------------------------------------
Library:OnUnload(function()
	-- stop all threads
	for k in pairs(Threads) do Threads[k] = nil end
	Flags.SilentAim = false; Flags.NoSpread = false; Flags.NoRecoil = false
	Flags.Triggerbot = false; Flags.HitboxExpander = false
	Flags.EspEnabled = false; Flags.FlyOn = false; Flags.NoclipOn = false
	-- restore hooks / resized parts
	for _, fn in ipairs(Restores) do pcall(fn) end
	for part, size in pairs(expandedParts) do pcall(function() if part and part.Parent then part.Size = size end end) end
	-- drawings
	clearEsp()
	if Drawings.__fov then pcall(function() Drawings.__fov:Remove() end); Drawings.__fov = nil end
	-- connections
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	-- restore camera/lighting
	pcall(function() Lighting.GlobalShadows = true end)
end)

Library:Notify({ Title = "RIVALS", Description = "Loaded. RightShift to toggle.", Time = 5 })
