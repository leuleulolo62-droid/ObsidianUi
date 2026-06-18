-- ============================================================================
-- ObsidianUi -> MacLib compatibility shim.
-- Appended after the MacLib library (which defines `MacLib`). Returns `Library`.
-- Lets scripts written for ObsidianUi (CreateWindow/AddTab/AddLeftGroupbox/AddToggle/...)
-- drive the new MacLib (Y2k) UI unchanged. Library.Toggles/Options stay live so cheat
-- logic keeps reading .Value.
-- ============================================================================

local Library = {
	Toggles = {},
	Options = {},
	ShowCustomCursor = false,
	ForceCheckbox = false,
	ToggleKeybind = nil,
	KeybindFrame = { Holder = nil },
	NotifySide = "Right",
	Unloaded = false,
}

-- Y2k background worker: ONE serialized loop does presence, the ban/blacklist
-- kick-check, AND remote logging. All HTTP goes through this single thread so the
-- executor's HTTP is never called concurrently (concurrent calls throw an
-- uncatchable C++ exception on some executors). Logs are QUEUED (never sent from
-- the LogService handler), and our own async/C++/http noise is filtered so it can
-- never feed back into itself.
do
	local KEY_API = "https://y2kscript.xyz"
	local Players = game:GetService("Players")
	local HttpService = game:GetService("HttpService")
	local function enc(s) local ok, r = pcall(function() return HttpService:UrlEncode(s) end) return ok and r or s end
	local function safeGet(u) local ok, b = pcall(function() return game:HttpGet(u) end) if ok and type(b) == "string" then return b end end

	local logQ, qn, lastMsg, lastT = {}, 0, "", 0
	local BLOCK = { "async work", "C++ exception", "HttpGet", "Http requests", "lacking capability", "Stack Begin", "Stack End", "/log?", "/check?", "/presence?", "y2kscript.xyz" }
	local function blocked(s) for _, p in ipairs(BLOCK) do if string.find(s, p, 1, true) then return true end end return false end
	pcall(function()
		game:GetService("LogService").MessageOut:Connect(function(msg, mt)
			local s = tostring(msg)
			if blocked(s) then return end                       -- never queue our own HTTP/async noise
			local isY2k = s:find("Y2[Kk]") ~= nil
			local level = (mt == Enum.MessageType.MessageError and "error")
				or (mt == Enum.MessageType.MessageWarning and isY2k and "warn")
				or (isY2k and "info") or nil
			if not level then return end
			s = s:sub(1, 250)
			local now = os.clock()
			if s == lastMsg and (now - lastT) < 3 then return end  -- dedupe
			lastMsg, lastT = s, now
			if qn < 30 then qn = qn + 1; logQ[qn] = level .. "|" .. s end  -- QUEUE only, no HTTP here
		end)
	end)

	local function revoke(reason)
		pcall(function() if Library and Library.Unload then Library:Unload() end end)
		pcall(function() Players.LocalPlayer:Kick("\n[Y2k] Access revoked  —  " .. tostring(reason) .. "\n") end)
	end

	task.spawn(function()
		local hwid = "unknown"
		pcall(function() hwid = (gethwid and gethwid()) or (get_hwid and get_hwid())
			or game:GetService("RbxAnalyticsService"):GetClientId() end)
		hwid = tostring(hwid)
		local started = os.time()
		local uid, uname = 0, "?"
		pcall(function() uid = Players.LocalPlayer.UserId; uname = Players.LocalPlayer.Name end)
		local gname = "?"
		pcall(function() gname = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)

		local strikes, done = 0, false
		while not done do
			task.wait(90)
			pcall(function()  -- every HTTP below runs ONE AT A TIME in this single thread
				local key = (getgenv and getgenv().SCRIPT_KEY) or ""
				if key == "" then return end
				safeGet(KEY_API .. "/presence?hwid=" .. enc(hwid) .. "&uid=" .. enc(tostring(uid))
					.. "&name=" .. enc(tostring(uname)) .. "&game=" .. enc(tostring(gname))
					.. "&key=" .. enc(tostring(key)) .. "&started=" .. tostring(started))
				-- feed the license badge the REAL remaining time + % of total (for colour)
				local raw = safeGet(KEY_API .. "/timeleft?key=" .. enc(tostring(key)) .. "&hwid=" .. enc(hwid))
				if raw and Library._win and Library._win.SetLicense then
					local rem, total = tostring(raw):match("^(%-?%d+)|(%d+)")
					rem, total = tonumber(rem), tonumber(total)
					if rem and rem < 0 then
						pcall(function() Library._win:SetLicense(99999, 1) end)        -- lifetime
					elseif rem then
						local pct = (total and total > 0) and (rem / total) or 1
						pcall(function() Library._win:SetLicense(rem / 3600, pct) end)
					end
				end
				local drained = 0
				while qn > 0 and drained < 4 do
					local item = logQ[1]; table.remove(logQ, 1); qn = qn - 1; drained = drained + 1
					local lvl, m = item:match("^(.-)|(.*)$")
					safeGet(KEY_API .. "/log?level=" .. enc(lvl or "info") .. "&hwid=" .. enc(hwid)
						.. "&game=" .. enc(gname) .. "&key=" .. enc(key) .. "&msg=" .. enc(m or ""))
				end
				local res = safeGet(KEY_API .. "/check?key=" .. enc(tostring(key)) .. "&hwid=" .. enc(hwid) .. "&t=" .. tostring(os.time()))
				if type(res) ~= "string" then return end
				if res == "banned" or res == "blacklisted" then
					done = true; revoke(res)
				elseif res ~= "ok" then
					strikes = strikes + 1
					if strikes >= 2 then done = true; revoke(res) end
				else
					strikes = 0
				end
			end)
		end
	end)
end

-- lucide icon resolver (same sprite-sheet lib ObsidianUi used)
local _lucideOk, _Lucide = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"))()
end)
local function resolveIcon(name)
	local fallback = { Image = "rbxassetid://18821914323" }
	if not name or not _lucideOk or not _Lucide then return fallback end
	local ok, ic = pcall(function() return _Lucide.GetAsset(name) end)
	if ok and type(ic) == "table" and ic.Url then
		return { Image = ic.Url, ImageRectOffset = ic.ImageRectOffset, ImageRectSize = ic.ImageRectSize }
	end
	return fallback
end

local function keyFromString(s)
	if typeof(s) == "EnumItem" then return s end
	if type(s) ~= "string" or s == "" or s == "None" then return nil end
	local ok, k = pcall(function() return Enum.KeyCode[s] end)
	if ok and k then return k end
	return nil
end

-- shared entry factory: holds .Value, :OnChanged, :SetValue, :GetState, :SetText
local function newEntry(default)
	local e = { Value = default, _cbs = {} }
	function e:OnChanged(fn) if fn then table.insert(self._cbs, fn) end return self end
	function e:_fire(v) self.Value = v for _, cb in ipairs(self._cbs) do task.spawn(function() pcall(cb, v) end) end end
	function e:GetState() return self.Value end
	function e:SetText(_) end
	function e:Set(v) if self._set then self._set(v) end end
	function e:SetValue(v) if self._set then self._set(v) end end
	return e
end

------------------------------------------------------------------ Library:Notify
function Library:Notify(a, b, c)
	local title, desc, time
	if type(a) == "table" then
		title, desc, time = a.Title, a.Description, a.Time
	else
		title, desc, time = "Notification", tostring(a), b
	end
	if Library._win then
		pcall(function()
			Library._win:Notify({ Title = title or "Notification", Description = desc or "", Lifetime = time or 4 })
		end)
	end
	local n = {}
	function n:ChangeTitle(t) end
	function n:ChangeDescription(d) end
	return n
end
Library.Notify = Library.Notify

function Library:Unload()
	Library.Unloaded = true
	if Library._win then pcall(function() Library._win:Unload() end) end
	if Library._onUnload then pcall(Library._onUnload) end
end
function Library:OnUnload(fn) Library._onUnload = fn end
function Library:SetNotifySide(s) Library.NotifySide = s end
function Library:SetDPIScale(n) if Library._win then pcall(function() Library._win:SetScale((tonumber(n) or 100) / 100) end) end end
function Library:SetCursorColor() end
function Library:SetWatermark() end
function Library:SetWatermarkVisibility() end
function Library:UpdateColorsUsingRegistry() end
Library.SetWatermark = Library.SetWatermark
Library.SetWatermarkVisibility = Library.SetWatermarkVisibility

------------------------------------------------------------------ Groupbox
local function makeGroupbox(sec)
	local G = {}

	function G:AddLabel(arg)
		local text = type(arg) == "table" and (arg.Text or arg.Body or "") or tostring(arg or "")
		local lbl = sec:Label({ Text = text })
		-- chainable: a label can carry a colorpicker / keypicker
		local chain = {}
		function chain:AddColorPicker(idx, o) return G:_colorpicker(idx, o) end
		function chain:AddKeyPicker(idx, o) return G:_keypicker(idx, o) end
		function chain:SetText(t) pcall(function() if lbl and lbl.UpdateText then lbl:UpdateText(t) end end) end
		return chain
	end

	function G:AddDivider() sec:Divider() return G end

	function G:AddButton(arg, b)
		-- forms: AddButton({Text,Func,...}) or AddButton("Text", func)
		local text, func, tip
		if type(arg) == "table" then text, func, tip = arg.Text, arg.Func or arg.Callback, arg.Tooltip
		else text, func = tostring(arg), b end
		local btn = sec:Button({ Name = text or "Button", Tooltip = tip, Callback = function() if func then pcall(func) end end })
		local chain = {}
		function chain:AddButton(a2, b2) return G:AddButton(a2, b2) end
		function chain:SetText(t) pcall(function() btn:UpdateName(t) end) end
		return chain
	end

	function G:AddToggle(idx, o)
		o = o or {}
		local e = newEntry(o.Default and true or false)
		local tog = sec:Toggle({
			Name = o.Text or idx,
			Default = o.Default and true or false,
			Tooltip = o.Tooltip,
			Callback = function(v) e:_fire(v) if o.Callback then task.spawn(function() pcall(o.Callback, v) end) end end,
		}, idx)
		e._set = function(v) pcall(function() tog:UpdateState(v and true or false) end) end
		Library.Toggles[idx] = e
		local chain = { _tog = tog }
		function chain:AddKeyPicker(kidx, ko)
			ko = ko or {}
			pcall(function() tog:Keybind({ Default = keyFromString(ko.Default), Callback = ko.Callback }) end)
			local ke = newEntry(ko.Default or "None")
			Library.Options[kidx] = ke
			return chain
		end
		function chain:AddColorPicker(cidx, co)
			co = co or {}
			pcall(function() tog:Colorpicker({ Default = co.Default or Color3.new(1, 1, 1), Callback = co.Callback }) end)
			local ce = newEntry(co.Default or Color3.new(1, 1, 1))
			Library.Options[cidx] = ce
			return chain
		end
		function chain:OnChanged(fn) e:OnChanged(fn) return chain end
		function chain:SetValue(v) e:SetValue(v) return chain end
		return chain
	end

	function G:AddSlider(idx, o)
		o = o or {}
		local e = newEntry(o.Default or o.Min or 0)
		local sld = sec:Slider({
			Name = o.Text or idx,
			Default = o.Default or o.Min or 0,
			Minimum = o.Min or 0,
			Maximum = o.Max or 100,
			Precision = o.Rounding or 0,
			DisplayMethod = "Round",
			Tooltip = o.Tooltip,
			Callback = function(v) e:_fire(v) if o.Callback then task.spawn(function() pcall(o.Callback, v) end) end end,
		}, idx)
		e._set = function(v) pcall(function() sld:UpdateValue(v) end) end
		Library.Options[idx] = e
		return e
	end

	function G:AddDropdown(idx, o)
		o = o or {}
		local e = newEntry(o.Default)
		local dd = sec:Dropdown({
			Name = o.Text or idx,
			Options = o.Values or {},
			Default = o.Default,
			Multi = o.Multi,
			Tooltip = o.Tooltip,
			Callback = function(v) e:_fire(v) if o.Callback then task.spawn(function() pcall(o.Callback, v) end) end end,
		}, idx)
		e._set = function(v) pcall(function() dd:UpdateSelection(v) end) end
		e.AddItem = function(_, item) pcall(function() dd:InsertOptions({ item }) end) end
		e.SetValues = function(_, vals) pcall(function() dd:ClearOptions() dd:InsertOptions(vals) end) end
		Library.Options[idx] = e
		return e
	end

	function G:AddInput(idx, o)
		o = o or {}
		local e = newEntry(o.Default or "")
		local inp = sec:Input({
			Name = o.Text or idx,
			Default = o.Default or "",
			Placeholder = o.Placeholder,
			Tooltip = o.Tooltip,
			Callback = function(v) e:_fire(v) if o.Callback then task.spawn(function() pcall(o.Callback, v) end) end end,
		}, idx)
		e._set = function(v) pcall(function() inp:UpdateText(v) end) end
		Library.Options[idx] = e
		return e
	end

	-- direct (non-chained) colorpicker/keypicker too
	function G:_colorpicker(idx, o)
		o = o or {}
		local e = newEntry(o.Default or Color3.new(1, 1, 1))
		local cp = sec:Colorpicker({
			Name = o.Title or o.Text or "Color",
			Default = o.Default or Color3.new(1, 1, 1),
			Callback = function(col, a) e:_fire(col) if o.Callback then task.spawn(function() pcall(o.Callback, col, a) end) end end,
		}, idx)
		e._set = function(v) pcall(function() cp:SetColor(v) end) end
		Library.Options[idx] = e
		return e
	end
	function G:_keypicker(idx, o)
		o = o or {}
		local e = newEntry(o.Default or "None")
		pcall(function()
			sec:Keybind({ Name = o.Text or "Keybind", Default = keyFromString(o.Default), Callback = o.Callback }, idx)
		end)
		Library.Options[idx] = e
		return e
	end
	G.AddColorPicker = function(self, idx, o) return G:_colorpicker(idx, o) end
	G.AddKeyPicker = function(self, idx, o) return G:_keypicker(idx, o) end

	return G
end

------------------------------------------------------------------ Tab + Tabbox
local function makeTab(tab)
	local T = { _tab = tab }
	function T:AddLeftGroupbox(name) local s = tab:Section({ Side = "Left" }) if name then s:Header({ Name = name }) end return makeGroupbox(s) end
	function T:AddRightGroupbox(name) local s = tab:Section({ Side = "Right" }) if name then s:Header({ Name = name }) end return makeGroupbox(s) end
	-- Tabboxes approximated: a groupbox whose :AddTab returns the same groupbox (flattened)
	local function tabbox(side)
		local s = tab:Section({ Side = side })
		local gb = makeGroupbox(s)
		local box = {}
		function box:AddTab(tabName) if tabName then s:Divider({ Text = tabName }) end return gb end
		return box
	end
	function T:AddLeftTabbox() return tabbox("Left") end
	function T:AddRightTabbox() return tabbox("Right") end
	return T
end

------------------------------------------------------------------ Y2k Terminal
-- Draggable console (own ScreenGui, so it's NOT stuck to the UI). Captures
-- print/warn/error via LogService, Lucide icon per level, background tinted to
-- the active preset. Built lazily on first toggle.
local Y2kTerm
local function getY2kTerm()
	if Y2kTerm then return Y2kTerm end
	local LogService = game:GetService("LogService")
	local UIS = game:GetService("UserInputService")
	local function setIcon(obj, name, col)
		local i = resolveIcon(name)
		obj.Image = i.Image
		obj.ImageRectOffset = i.ImageRectOffset or Vector2.new()
		obj.ImageRectSize = i.ImageRectSize or Vector2.new()
		if col then obj.ImageColor3 = col end
	end
	local sg = Instance.new("ScreenGui")
	sg.Name = "Y2kTerminal" sg.ResetOnSpawn = false sg.DisplayOrder = 9998 sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- wrap = draggable root that does NOT clip (so the glow halo shows). It appears
	-- on the RIGHT by default. f (inside) clips the actual content.
	local wrap = Instance.new("Frame")
	wrap.Name = "Wrap" wrap.Size = UDim2.fromOffset(470, 300) wrap.AnchorPoint = Vector2.new(1, 0.5)
	wrap.Position = UDim2.new(1, -20, 0.5, 0) wrap.BackgroundTransparency = 1 wrap.BorderSizePixel = 0 wrap.Visible = false wrap.Parent = sg

	local glow = Instance.new("ImageLabel")  -- shining blurred halo (matches the UI outline)
	glow.Name = "Glow" glow.BackgroundTransparency = 1 glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.5) glow.Size = UDim2.new(1, 64, 1, 64)
	glow.Image = (MacLib.GetIcon and MacLib.GetIcon("shadow")) or "" glow.ImageColor3 = MacLib.OutlineColor or Color3.fromRGB(91, 124, 255)
	glow.ImageTransparency = 0.42 glow.ScaleType = Enum.ScaleType.Slice glow.SliceCenter = Rect.new(246, 246, 266, 266)
	glow.ZIndex = 0 glow.Visible = MacLib.OutlineEnabled glow.Parent = wrap
	task.spawn(function() pcall(function() game:GetService("TweenService"):Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { ImageTransparency = 0.7 }):Play() end) end)

	local f = Instance.new("Frame")
	f.Name = "Win" f.Size = UDim2.fromScale(1, 1) f.Position = UDim2.fromScale(0.5, 0.5) f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(11, 11, 15) f.BackgroundTransparency = 0.04 f.BorderSizePixel = 0 f.ClipsDescendants = true f.ZIndex = 1 f.Parent = wrap
	local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 12) fc.Parent = f
	local stroke = Instance.new("UIStroke") stroke.Color = MacLib.OutlineColor or Color3.fromRGB(91, 124, 255) stroke.Transparency = 0.45 stroke.Parent = f

	local bg = Instance.new("Frame") bg.Size = UDim2.fromScale(1, 1) bg.BackgroundTransparency = 1 bg.ZIndex = 0 bg.Parent = f
	local function redraw()
		for _, c in ipairs(bg:GetChildren()) do c:Destroy() end
		if MacLib.BackgroundAnim == "None" then return end
		local tint = Instance.new("Frame") tint.Size = UDim2.fromScale(1, 1) tint.BorderSizePixel = 0
		tint.BackgroundColor3 = MacLib.WaveColor or Color3.fromRGB(91, 124, 255) tint.BackgroundTransparency = 0.93 tint.ZIndex = 0 tint.Parent = bg
		local gr = Instance.new("UIGradient") gr.Rotation = 90 gr.Transparency = NumberSequence.new(0.86, 1) gr.Parent = tint
	end
	redraw() table.insert(MacLib._bgCallbacks, redraw)

	local head = Instance.new("Frame") head.Size = UDim2.new(1, 0, 0, 40) head.BackgroundTransparency = 1 head.ZIndex = 2 head.Parent = f
	local tIcon = Instance.new("ImageLabel") tIcon.BackgroundTransparency = 1 tIcon.Size = UDim2.fromOffset(16, 16) tIcon.Position = UDim2.fromOffset(14, 12) tIcon.ZIndex = 3 tIcon.Parent = head
	setIcon(tIcon, "terminal", Color3.fromRGB(170, 195, 255))
	local title = Instance.new("TextLabel") title.BackgroundTransparency = 1 title.Position = UDim2.fromOffset(38, 0) title.Size = UDim2.new(1, -130, 1, 0) title.Text = "Terminal" title.Font = Enum.Font.GothamMedium title.TextSize = 14 title.TextColor3 = Color3.fromRGB(235, 240, 255) title.TextXAlignment = Enum.TextXAlignment.Left title.ZIndex = 3 title.Parent = head
	local function iconBtn(name, xoff, col)
		local b = Instance.new("ImageButton") b.BackgroundTransparency = 1 b.AutoButtonColor = false b.Size = UDim2.fromOffset(18, 18) b.AnchorPoint = Vector2.new(1, 0.5) b.Position = UDim2.new(1, xoff, 0, 20) b.ZIndex = 3 b.Parent = head
		setIcon(b, name, col or Color3.fromRGB(165, 178, 210)) return b
	end
	local pauseBtn = iconBtn("circle-pause", -72, Color3.fromRGB(165, 178, 210))
	local clearBtn = iconBtn("trash-2", -44)
	local closeBtn = iconBtn("x", -16, Color3.fromRGB(255, 140, 150))

	local scroll = Instance.new("ScrollingFrame") scroll.Position = UDim2.fromOffset(0, 42) scroll.Size = UDim2.new(1, 0, 1, -42) scroll.BackgroundTransparency = 1 scroll.BorderSizePixel = 0 scroll.ScrollBarThickness = 3 scroll.ScrollBarImageColor3 = MacLib.OutlineColor or Color3.fromRGB(91, 124, 255) scroll.CanvasSize = UDim2.new() scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y scroll.ZIndex = 2 scroll.Parent = f
	local pd = Instance.new("UIPadding") pd.PaddingLeft = UDim.new(0, 12) pd.PaddingRight = UDim.new(0, 12) pd.PaddingBottom = UDim.new(0, 8) pd.Parent = scroll
	local ll = Instance.new("UIListLayout") ll.Padding = UDim.new(0, 3) ll.SortOrder = Enum.SortOrder.LayoutOrder ll.Parent = scroll

	local LV = {
		[Enum.MessageType.MessageOutput] = { "chevron-right", Color3.fromRGB(185, 195, 215) },
		[Enum.MessageType.MessageInfo] = { "info", Color3.fromRGB(120, 200, 255) },
		[Enum.MessageType.MessageWarning] = { "triangle-alert", Color3.fromRGB(255, 205, 110) },
		[Enum.MessageType.MessageError] = { "circle-x", Color3.fromRGB(255, 120, 140) },
	}
	local count = 0
	local function addLine(msg, mt)
		local meta = LV[mt] or LV[Enum.MessageType.MessageOutput]
		count = count + 1
		local row = Instance.new("Frame") row.BackgroundTransparency = 1 row.Size = UDim2.new(1, 0, 0, 0) row.AutomaticSize = Enum.AutomaticSize.Y row.LayoutOrder = count row.ZIndex = 2 row.Parent = scroll
		local li = Instance.new("ImageLabel") li.BackgroundTransparency = 1 li.Size = UDim2.fromOffset(13, 13) li.Position = UDim2.fromOffset(0, 3) li.ZIndex = 3 li.Parent = row
		setIcon(li, meta[1], meta[2])
		local tl = Instance.new("TextLabel") tl.BackgroundTransparency = 1 tl.Position = UDim2.fromOffset(20, 0) tl.Size = UDim2.new(1, -20, 0, 0) tl.AutomaticSize = Enum.AutomaticSize.Y tl.Text = "[" .. os.date("%H:%M:%S") .. "]  " .. tostring(msg) tl.Font = Enum.Font.Code tl.TextSize = 12 tl.TextColor3 = meta[2] tl.TextXAlignment = Enum.TextXAlignment.Left tl.TextYAlignment = Enum.TextYAlignment.Top tl.TextWrapped = true tl.ZIndex = 3 tl.Parent = row
		if count > 200 then local fr = scroll:FindFirstChildWhichIsA("Frame") if fr then fr:Destroy() end end
		task.defer(function() pcall(function() scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y) end) end)
	end
	local paused = false
	pcall(function() LogService.MessageOut:Connect(function(m, t) if (not paused) and wrap.Visible then addLine(m, t) end end) end)
	pauseBtn.MouseButton1Click:Connect(function() paused = not paused setIcon(pauseBtn, paused and "play" or "circle-pause") end)
	clearBtn.MouseButton1Click:Connect(function() for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end count = 0 end)
	closeBtn.MouseButton1Click:Connect(function() wrap.Visible = false pcall(function() Library.Toggles.Y2kTerminal:SetValue(false) end) end)

	local dragging, dragStart, startPos, stuck = false, nil, nil, false
	head.InputBegan:Connect(function(inp) if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and not stuck then dragging = true dragStart = inp.Position startPos = wrap.Position end end)
	UIS.InputChanged:Connect(function(inp) if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then local d = inp.Position - dragStart wrap.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end end)
	UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then dragging = false end end)

	pcall(function() sg.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
	if not sg.Parent then pcall(function() sg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end) end

	local RunService = game:GetService("RunService")
	local followConn
	Y2kTerm = {
		gui = sg, frame = f, wrap = wrap, stroke = stroke, glow = glow,
		show = function(v) wrap.Visible = v and true or false end,
		setOutline = function(on) pcall(function() glow.Visible = on and true or false end) end,  -- shining glow follows the UI-outline toggle
		setColor = function(c) pcall(function() stroke.Color = c glow.ImageColor3 = c end) end,
		setStick = function(on)
			stuck = on and true or false
			if followConn then followConn:Disconnect() followConn = nil end
			if on then
				wrap.AnchorPoint = Vector2.new(0, 0.5)
				followConn = RunService.Heartbeat:Connect(function()  -- continuously follow the window
					local b = MacLib._base
					if not b or not b.Parent then return end
					local ap, sz = b.AbsolutePosition, b.AbsoluteSize
					wrap.Position = UDim2.fromOffset(ap.X + sz.X + 16, ap.Y + sz.Y / 2)
				end)
			else
				wrap.AnchorPoint = Vector2.new(1, 0.5)
				wrap.Position = UDim2.new(1, -20, 0.5, 0)
			end
		end,
	}
	return Y2kTerm
end

------------------------------------------------------------------ Appearance tab (the Y2k customizer)
local function addAppearance(win, tab)
	local s = tab:Section({ Side = "Left" })
	s:Header({ Name = "Appearance" })
	s:Divider({ Text = "Preset" })
	s:Dropdown({ Name = "Theme Preset", Options = MacLib.ThemePresetOrder, Default = "Y2k",
		Callback = function(n)
			local p = MacLib:ApplyThemePreset(n)
			if p then
				pcall(function() MacLib.Options.Y2kAccent:SetColor(p.Accent, false) end)
				pcall(function() MacLib.Options.Y2kBg:SetColor(p.Background, false) end)
				pcall(function() MacLib.Options.Y2kTxt:SetColor(p.Text, false) end)
			end
		end }, "Y2kPreset")
	s:Divider({ Text = "Colors" })
	s:Colorpicker({ Name = "Accent", Default = MacLib.Theme.Accent, Callback = function(c) MacLib:SetThemeColor("Accent", c) end }, "Y2kAccent")
	s:Colorpicker({ Name = "Background", Default = MacLib.Theme.Background, Callback = function(c) MacLib:SetThemeColor("Background", c) end }, "Y2kBg")
	s:Colorpicker({ Name = "Text", Default = MacLib.Theme.Text, Callback = function(c) MacLib:SetThemeColor("Text", c) end }, "Y2kTxt")
	local s2 = tab:Section({ Side = "Right" })
	s2:Header({ Name = "Background FX" })
	s2:Dropdown({ Name = "Animation", Options = MacLib.BackgroundAnimOptions, Default = MacLib.BackgroundAnim or "Grid",
		Callback = function(n) MacLib:SetBackgroundAnim(n) end }, "Y2kAnim")
	s2:Toggle({ Name = "Enabled", Default = true, Callback = function(o) MacLib:SetWaves(o) end }, "Y2kWaves")
	s2:Colorpicker({ Name = "FX Color", Default = MacLib.WaveColor, Callback = function(c) MacLib:SetWaveColor(c) end }, "Y2kFxColor")
	s2:Slider({ Name = "FX Speed", Default = 1, Minimum = 0.2, Maximum = 4, Precision = 1, DisplayMethod = "Round",
		Callback = function(v) MacLib:SetWaveSpeed(v) end }, "Y2kFxSpeed")
	s2:Divider({ Text = "Outline" })
	s2:Toggle({ Name = "UI Outline", Default = MacLib.OutlineEnabled, Callback = function(o) MacLib:SetOutline(o) if Y2kTerm then Y2kTerm.setOutline(o) end end }, "Y2kOutline")
	s2:Colorpicker({ Name = "Outline Color", Default = MacLib.OutlineColor, Callback = function(c) MacLib:SetOutlineColor(c) if Y2kTerm then Y2kTerm.setColor(c) end end }, "Y2kOutlineColor")
	s2:Colorpicker({ Name = "UI Background", Default = (MacLib._base and MacLib._base.BackgroundColor3) or Color3.fromRGB(9, 9, 11),
		Callback = function(c) MacLib:SetUIBackgroundColor(c) end }, "Y2kUIBg")
	s2:Divider({ Text = "Terminal" })
	s2:Toggle({ Name = "Terminal", Default = false, Callback = function(o) local t = getY2kTerm() t.setOutline(MacLib.OutlineEnabled) t.setColor(MacLib.OutlineColor) t.show(o) end }, "Y2kTerminal")
	s2:Toggle({ Name = "Stick Terminal to UI", Default = false, Callback = function(o) getY2kTerm().setStick(o) end }, "Y2kTermStick")
	s2:Divider({ Text = "Window" })
	s2:Toggle({ Name = "Lock Window", Default = false, Callback = function(st) pcall(function() win:SetLocked(st) end) end }, "Y2kLock")
	s2:Button({ Name = "Unload Script", Callback = function() pcall(function() Library:Unload() end) end })
end

-- settings / config / parametres tabs all collapse into one "Settings" tab
local function isSettingsCat(name)
	local n = tostring(name):lower()
	return n:find("setting") or n:find("param") or n:find("config")
end

------------------------------------------------------------------ CreateWindow
-- Real game name (cached). Used as the window subtitle on every script.
local _y2kGameName
local function y2kGameName()
	if _y2kGameName ~= nil then return _y2kGameName end
	local ok, info = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
	end)
	_y2kGameName = (ok and info and info.Name) or false
	return _y2kGameName
end

function Library:CreateWindow(info)
	info = info or {}
	-- every script: fixed brand title + the real game name as the subtitle
	local win = MacLib:Window({
		Title = "Y2k Script",
		Subtitle = y2kGameName() or info.Footer or "discord.gg/EFFKrfFkPQ",
		Size = info.Size or UDim2.fromOffset(720, 560),
		Keybind = info.ToggleKeybind or Enum.KeyCode.RightControl,
		ShowUserInfo = true,
		AcrylicBlur = true,
	})
	Library._win = win
	pcall(function() MacLib:SetFolder(info.Folder or "Y2kScript") end)  -- so config save/load works
	local tg = win:TabGroup()
	local first = true
	local W = {}
	function W:AddTab(name, icon)
		-- merge every settings/config tab into one shared "Settings" tab (with appearance)
		if isSettingsCat(name) then
			if not Library._settingsTab then
				local ic = resolveIcon("settings")
				local tab = tg:Tab({ Name = "Settings", Image = ic.Image, ImageRectOffset = ic.ImageRectOffset, ImageRectSize = ic.ImageRectSize })
				if first then first = false pcall(function() tab:Select() end) end
				local ok, err = pcall(addAppearance, win, tab)
				if not ok then warn("[Y2k] Appearance failed: " .. tostring(err)) end
				Library._settingsTab = makeTab(tab)
			end
			return Library._settingsTab
		end
		local ic = resolveIcon(icon)
		local tab = tg:Tab({ Name = name, Image = ic.Image, ImageRectOffset = ic.ImageRectOffset, ImageRectSize = ic.ImageRectSize })
		if first then first = false pcall(function() tab:Select() end) end
		return makeTab(tab)
	end
	W.AddKeyTab = W.AddTab
	return W
end

return Library
