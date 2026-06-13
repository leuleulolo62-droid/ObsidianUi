--[[
	Y2k UI  --  premium black SAMPLE (preview)
	Run in your executor to judge the look before I apply it to every script.
	Clean near-black, hairline borders, airy spacing, minimal accent. Mobile + PC.
	Keeps your toggle / dropdown / textbox behaviour + your GitHub logo.
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

-- ===== your GitHub logo (kept: download + cache locally) =====
local logoUrl      = "https://raw.githubusercontent.com/Y2kScriptBack2Back/Y2k-Script-Back2Back/main/wp14229113.jpg"
local logoFilename = "y2k_logo.jpg"
local logoAsset
local function GetLogoImage()
	if logoAsset then return logoAsset end
	if writefile and getcustomasset and isfile then
		pcall(function()
			if not isfile(logoFilename) then writefile(logoFilename, game:HttpGet(logoUrl)) end
			logoAsset = getcustomasset(logoFilename)
		end)
		if logoAsset then return logoAsset end
	end
	return logoUrl
end

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ===== premium black theme =====
local C = {
	Bg     = Color3.fromRGB(11, 11, 13),
	Panel  = Color3.fromRGB(16, 16, 19),
	Field  = Color3.fromRGB(26, 26, 30),
	Hair   = Color3.fromRGB(255, 255, 255), -- used with high transparency
	Text   = Color3.fromRGB(243, 243, 246),
	Sub    = Color3.fromRGB(124, 124, 134),
	Faint  = Color3.fromRGB(78, 78, 88),
	Accent = Color3.fromRGB(91, 124, 255),
	TogOff = Color3.fromRGB(42, 42, 48),
}
local FONT, FONTB, FONTSB = Enum.Font.Gotham, Enum.Font.GothamBold, Enum.Font.GothamMedium

local function new(cls, props, kids)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do o[k] = v end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	return o
end
local function round(p, r) new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = p }) end
local function hair(p, tr) new("UIStroke", { Color = C.Hair, Transparency = tr or 0.92, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p }) end
local function padAll(p, n) new("UIPadding", { PaddingTop = UDim.new(0,n), PaddingBottom = UDim.new(0,n), PaddingLeft = UDim.new(0,n), PaddingRight = UDim.new(0,n), Parent = p }) end
local function tw(o, props, t, st) TweenService:Create(o, TweenInfo.new(t or 0.16, st or Enum.EasingStyle.Quad), props):Play() end

local parent = (gethui and gethui()) or CoreGui
local old = parent:FindFirstChild("Y2kPremium"); if old then old:Destroy() end
local Screen = new("ScreenGui", { Name = "Y2kPremium", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent })

local view = workspace.CurrentCamera.ViewportSize
local W = IsMobile and math.min(580, view.X - 24) or 660
local H = IsMobile and math.min(370, view.Y - 60) or 440

local Window = new("Frame", { Name = "Window", Size = UDim2.fromOffset(W, H), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = C.Bg, BorderSizePixel = 0, Parent = Screen })
round(Window, 16); hair(Window, 0.9)
new("UISizeConstraint", { MinSize = Vector2.new(440, 300), Parent = Window })
new("ImageLabel", { Image = "rbxassetid://6014261993", ImageColor3 = Color3.new(0,0,0), ImageTransparency = 0.5, ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49,49,450,450), Size = UDim2.new(1,80,1,80), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, ZIndex = 0, Parent = Window })

-- ===== header =====
local Bar = new("Frame", { Size = UDim2.new(1,0,0,50), BackgroundTransparency = 1, Parent = Window })
local logo = new("ImageLabel", { Size = UDim2.fromOffset(22,22), Position = UDim2.new(0,18,0.5,0), AnchorPoint = Vector2.new(0,0.5), BackgroundTransparency = 1, Image = GetLogoImage(), Parent = Bar })
round(logo, 7)
new("TextLabel", { Size = UDim2.new(0,160,1,0), Position = UDim2.new(0,50,0,0), BackgroundTransparency = 1, Text = "Y2k Hub", TextColor3 = C.Text, Font = FONTB, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Parent = Bar })
local closeBtn = new("TextButton", { Size = UDim2.fromOffset(26,26), Position = UDim2.new(1,-16,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = C.Field, Text = "", AutoButtonColor = false, Parent = Bar })
round(closeBtn, 13); hair(closeBtn, 0.88)
new("TextLabel", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, Text = "✕", TextColor3 = C.Sub, Font = FONTB, TextSize = 12, Parent = closeBtn })
-- header hairline
new("Frame", { Size = UDim2.new(1,0,0,1), Position = UDim2.new(0,0,0,50), BackgroundColor3 = C.Hair, BackgroundTransparency = 0.92, BorderSizePixel = 0, Parent = Window })

-- ===== sidebar + content =====
local SIDE = IsMobile and 140 or 162
local Sidebar = new("Frame", { Size = UDim2.new(0,SIDE,1,-51), Position = UDim2.new(0,0,0,51), BackgroundTransparency = 1, Parent = Window })
new("Frame", { Size = UDim2.new(0,1,1,0), Position = UDim2.new(1,0,0,0), BackgroundColor3 = C.Hair, BackgroundTransparency = 0.92, BorderSizePixel = 0, Parent = Sidebar })
local SideList = new("ScrollingFrame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Sidebar })
padAll(SideList, 12); new("UIListLayout", { Padding = UDim.new(0,4), Parent = SideList })

local Content = new("Frame", { Size = UDim2.new(1,-SIDE,1,-51), Position = UDim2.new(0,SIDE,0,51), BackgroundTransparency = 1, Parent = Window })

-- ===== tabs =====
local Tabs, active = {}, nil
local function select(t)
	if active == t then return end
	for _, o in ipairs(Tabs) do
		local on = o == t
		tw(o.btn, { BackgroundTransparency = on and 0.93 or 1 })
		tw(o.lbl, { TextColor3 = on and C.Text or C.Sub })
		tw(o.ico, { ImageColor3 = on and C.Text or C.Faint })
		tw(o.dot, { BackgroundTransparency = on and 0 or 1 })
		o.page.Visible = on
	end
	active = t
end

local function Tab(name, iconId)
	local btn = new("TextButton", { Size = UDim2.new(1,0,0, IsMobile and 40 or 36), BackgroundColor3 = C.Hair, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = SideList })
	round(btn, 9)
	local dot = new("Frame", { Size = UDim2.fromOffset(3,14), Position = UDim2.new(0,0,0.5,0), AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = C.Accent, BorderSizePixel = 0, BackgroundTransparency = 1, Parent = btn })
	round(dot, 2)
	local ico = new("ImageLabel", { Size = UDim2.fromOffset(16,16), Position = UDim2.new(0,12,0.5,0), AnchorPoint = Vector2.new(0,0.5), BackgroundTransparency = 1, Image = iconId or "", ImageColor3 = C.Faint, Parent = btn })
	local lbl = new("TextLabel", { Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,36,0,0), BackgroundTransparency = 1, Text = name, TextColor3 = C.Sub, Font = FONTSB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })

	local page = new("ScrollingFrame", { Size = UDim2.fromScale(1,1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ScrollBarThickness = 2, ScrollBarImageColor3 = C.Faint, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = Content })
	padAll(page, 18); new("UIListLayout", { Padding = UDim.new(0,18), Parent = page })

	local entry = { btn=btn, lbl=lbl, ico=ico, dot=dot, page=page }
	table.insert(Tabs, entry)
	btn.MouseButton1Click:Connect(function() select(entry) end)
	btn.MouseEnter:Connect(function() if active ~= entry then tw(btn, { BackgroundTransparency = 0.96 }) end end)
	btn.MouseLeave:Connect(function() if active ~= entry then tw(btn, { BackgroundTransparency = 1 }) end end)
	if not active then select(entry) end

	local api = {}
	function api:Section(title)
		new("TextLabel", { Size = UDim2.new(1,0,0,14), BackgroundTransparency = 1, Text = string.upper(title), TextColor3 = C.Faint, Font = FONTB, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = page })
		local card = new("Frame", { Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Panel, BorderSizePixel = 0, Parent = page })
		round(card, 12); hair(card, 0.93)
		local col = new("Frame", { Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card })
		padAll(col, 6); new("UIListLayout", { Parent = col })

		local first = true
		local function row(h)
			if not first then
				new("Frame", { Size = UDim2.new(1,-12,0,1), Position = UDim2.new(0,6,0,0), BackgroundColor3 = C.Hair, BackgroundTransparency = 0.94, BorderSizePixel = 0, Parent = col, LayoutOrder = #col:GetChildren() })
			end
			first = false
			local r = new("Frame", { Size = UDim2.new(1,0,0, h or (IsMobile and 42 or 38)), BackgroundColor3 = C.Hair, BackgroundTransparency = 1, BorderSizePixel = 0, Parent = col })
			round(r, 8)
			padAll(r, 8)
			r.MouseEnter:Connect(function() tw(r, { BackgroundTransparency = 0.97 }) end)
			r.MouseLeave:Connect(function() tw(r, { BackgroundTransparency = 1 }) end)
			return r
		end
		local function nameLabel(r, text)
			return new("TextLabel", { Size = UDim2.new(1,-100,1,0), BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = FONTSB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
		end

		local S = {}

		function S:Toggle(text, default, cb)
			local r = row(); nameLabel(r, text)
			local sw = new("TextButton", { Size = UDim2.fromOffset(40,22), Position = UDim2.new(1,-8,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = default and C.Accent or C.TogOff, Text = "", AutoButtonColor = false, Parent = r })
			round(sw, 11)
			local knob = new("Frame", { Size = UDim2.fromOffset(16,16), Position = default and UDim2.new(1,-3,0.5,0) or UDim2.new(0,3,0.5,0), AnchorPoint = Vector2.new(default and 1 or 0, 0.5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = sw })
			round(knob, 8)
			local st = default or false
			sw.MouseButton1Click:Connect(function()
				st = not st
				knob.AnchorPoint = Vector2.new(st and 1 or 0, 0.5)
				tw(sw, { BackgroundColor3 = st and C.Accent or C.TogOff })
				tw(knob, { Position = st and UDim2.new(1,-3,0.5,0) or UDim2.new(0,3,0.5,0) }, 0.18, Enum.EasingStyle.Back)
				if cb then pcall(cb, st) end
			end)
			return S
		end

		function S:Button(text, cb)
			local r = row(IsMobile and 44 or 40)
			local b = new("TextButton", { Size = UDim2.fromScale(1,1), BackgroundColor3 = C.Accent, Text = text, TextColor3 = Color3.new(1,1,1), Font = FONTB, TextSize = 13, AutoButtonColor = false, Parent = r })
			round(b, 9)
			b.MouseButton1Click:Connect(function() tw(b, { BackgroundColor3 = C.Accent:Lerp(Color3.new(1,1,1),0.18) }, 0.08); task.delay(0.1, function() tw(b, { BackgroundColor3 = C.Accent }) end); if cb then pcall(cb) end end)
			return S
		end

		function S:Input(text, placeholder, cb)
			local r = row(); nameLabel(r, text)
			local box = new("Frame", { Size = UDim2.fromOffset(IsMobile and 130 or 160, 28), Position = UDim2.new(1,-8,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = C.Field, BorderSizePixel = 0, Parent = r })
			round(box, 8); hair(box, 0.9)
			local tb = new("TextBox", { Size = UDim2.new(1,-18,1,0), Position = UDim2.fromOffset(9,0), BackgroundTransparency = 1, PlaceholderText = placeholder or "", Text = "", TextColor3 = C.Text, PlaceholderColor3 = C.Faint, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = box })
			tb.FocusLost:Connect(function() if cb then pcall(cb, tb.Text) end end)
			return S
		end

		function S:Dropdown(text, list, cb)
			local r = row(); nameLabel(r, text)
			local dd = new("TextButton", { Size = UDim2.fromOffset(IsMobile and 130 or 160, 28), Position = UDim2.new(1,-8,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = C.Field, Text = "", AutoButtonColor = false, Parent = r })
			round(dd, 8); hair(dd, 0.9)
			local sel = new("TextLabel", { Size = UDim2.new(1,-30,1,0), Position = UDim2.fromOffset(9,0), BackgroundTransparency = 1, Text = list[1] or "...", TextColor3 = C.Text, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = dd })
			new("ImageLabel", { Size = UDim2.fromOffset(11,11), Position = UDim2.new(1,-9,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundTransparency = 1, Image = "rbxassetid://10709790948", ImageColor3 = C.Sub, Parent = dd })
			local menu = new("Frame", { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,1,5), BackgroundColor3 = C.Field, BorderSizePixel = 0, Visible = false, ZIndex = 8, Parent = dd })
			round(menu, 8); hair(menu, 0.86); padAll(menu, 4); new("UIListLayout", { Padding = UDim.new(0,2), Parent = menu })
			for _, opt in ipairs(list) do
				local it = new("TextButton", { Size = UDim2.new(1,0,0,26), BackgroundColor3 = C.Hair, BackgroundTransparency = 1, Text = "  "..opt, TextColor3 = C.Sub, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9, AutoButtonColor = false, Parent = menu })
				round(it, 6)
				it.MouseEnter:Connect(function() tw(it, { BackgroundTransparency = 0.9, TextColor3 = C.Text }) end)
				it.MouseLeave:Connect(function() tw(it, { BackgroundTransparency = 1, TextColor3 = C.Sub }) end)
				it.MouseButton1Click:Connect(function() sel.Text = opt; menu.Visible = false; if cb then pcall(cb, opt) end end)
			end
			dd.MouseButton1Click:Connect(function() menu.Visible = not menu.Visible end)
			return S
		end

		function S:Slider(text, min, max, default, cb)
			local r = row(IsMobile and 50 or 46)
			new("TextLabel", { Size = UDim2.new(1,-60,0,16), BackgroundTransparency = 1, Text = text, TextColor3 = C.Text, Font = FONTSB, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = r })
			local val = new("TextLabel", { Size = UDim2.new(0,60,0,16), Position = UDim2.new(1,0,0,0), AnchorPoint = Vector2.new(1,0), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = C.Sub, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = r })
			local track = new("Frame", { Size = UDim2.new(1,0,0,4), Position = UDim2.new(0,0,1,-4), BackgroundColor3 = C.TogOff, BorderSizePixel = 0, Parent = r })
			round(track, 2)
			local p0 = (default-min)/(max-min)
			local fill = new("Frame", { Size = UDim2.fromScale(p0,1), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Parent = track })
			round(fill, 2)
			local knob = new("Frame", { Size = UDim2.fromOffset(12,12), Position = UDim2.new(p0,0,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = track })
			round(knob, 6)
			local drag = false
			local function set(x)
				local p = math.clamp((x - track.AbsolutePosition.X)/track.AbsoluteSize.X, 0, 1)
				fill.Size = UDim2.fromScale(p,1); knob.Position = UDim2.new(p,0,0.5,0)
				local v = math.floor(min + (max-min)*p + 0.5); val.Text = tostring(v)
				if cb then pcall(cb, v) end
			end
			track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; set(i.Position.X) end end)
			UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then set(i.Position.X) end end)
			UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
			return S
		end

		function S:Label(text)
			local r = row(); r.Size = UDim2.new(1,0,0,0); r.AutomaticSize = Enum.AutomaticSize.Y
			new("TextLabel", { Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = text, TextColor3 = C.Sub, Font = FONT, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = r })
			return S
		end

		return S
	end
	return api
end

-- ===== drag (mouse + touch) =====
do
	local drag, sp, sm
	Bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=true; sp=Window.Position; sm=i.Position end end)
	UserInputService.InputChanged:Connect(function(i) if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then local d=i.Position-sm; Window.Position=UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y) end end)
	UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end end)
end

-- ===== hide / show =====
local hidden = false
local function setHidden(h) hidden=h; Window.Visible = not h end
closeBtn.MouseButton1Click:Connect(function() setHidden(true) end)
closeBtn.MouseEnter:Connect(function() tw(closeBtn, { BackgroundColor3 = Color3.fromRGB(220,70,80) }) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn, { BackgroundColor3 = C.Field }) end)
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.KeyCode == Enum.KeyCode.RightControl then setHidden(not hidden) end end)
local fab = new("TextButton", { Size = UDim2.fromOffset(50,50), Position = UDim2.new(0,16,0.5,0), AnchorPoint = Vector2.new(0,0.5), BackgroundColor3 = C.Bg, Text = "", AutoButtonColor = false, Visible = IsMobile, Parent = Screen })
round(fab, 25); hair(fab, 0.85)
new("ImageLabel", { Size = UDim2.fromOffset(24,24), Position = UDim2.fromScale(0.5,0.5), AnchorPoint = Vector2.new(0.5,0.5), BackgroundTransparency = 1, Image = GetLogoImage(), Parent = fab })
fab.MouseButton1Click:Connect(function() setHidden(not hidden) end)

-- ===== demo content =====
local home = Tab("Home", "rbxassetid://10723407389")
local s1 = home:Section("Main")
s1:Toggle("Auto Farm", false, function(v) print("auto farm", v) end)
s1:Toggle("Auto Collect", true)
s1:Slider("Speed", 16, 250, 80, function(v) print("speed", v) end)
s1:Dropdown("Mode", {"Safe","Fast","Insane"}, function(v) print("mode", v) end)
local s2 = home:Section("Config")
s2:Input("Webhook", "paste url...", function(t) print("webhook", t) end)
s2:Button("Save Config", function() print("saved") end)

local player = Tab("Player", "rbxassetid://10747373176")
local pm = player:Section("Movement")
pm:Slider("WalkSpeed", 16, 500, 16)
pm:Slider("JumpPower", 50, 500, 50)
pm:Toggle("Infinite Jump", false)

local info = Tab("Info", "rbxassetid://10723415903")
info:Section("About"):Label("Y2k Hub - premium black sample.\nRightCtrl hides/shows. Drag the header. Mobile friendly.")

print("[Y2k] premium UI sample loaded - " .. (IsMobile and "MOBILE" or "PC"))
