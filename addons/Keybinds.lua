-- ============================================================================
--  Y2k Keybinds  |  draggable keybind list module, theme-matched to the Y2k UI
--  Reads Library.Scheme so it follows the menu accent/colours.
--
--  local Keybinds = loadUI(repo .. "addons/Keybinds.lua")
--  local kb = Keybinds.new(Library, { title = "Keybinds" })
--  kb:Bind("fly", "Fly", Enum.KeyCode.F, function(active) Cfg.Fly = active end)  -- press F toggles
--  kb:Set("fly", true)        -- reflect external state (updates the on/off dot)
--  kb:SetVisible(true)
-- ============================================================================
local UIS = game:GetService("UserInputService")

local function host()
    local ok, h = pcall(function() return gethui and gethui() end)
    if ok and h then return h end
    return game:GetService("CoreGui")
end
local function protect(gui)
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
    pcall(function() if protectgui then protectgui(gui) end end)
end
local function scheme(Library, key, fb)
    local ok, c = pcall(function() return Library.Scheme[key] end)
    return (ok and typeof(c) == "Color3") and c or fb
end
local function keyName(kc)
    local s = tostring(kc):gsub("Enum.KeyCode.", "")
    return s
end

local Keybinds = {}
Keybinds.__index = Keybinds

function Keybinds.new(Library, opts)
    opts = opts or {}
    local self = setmetatable({ binds = {}, byKey = {}, _order = 0 }, Keybinds)
    local accent = scheme(Library, "AccentColor", Color3.fromRGB(37, 99, 235))
    local bg     = scheme(Library, "MainColor",   Color3.fromRGB(16, 18, 30))
    local fg     = scheme(Library, "FontColor",   Color3.fromRGB(234, 242, 255))
    self.accent, self.fg, self.bg = accent, fg, bg

    local gui = Instance.new("ScreenGui")
    gui.Name = "\0Y2kKeybinds"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    protect(gui); gui.Parent = host()

    local frame = Instance.new("Frame")
    frame.Name = "KB"; frame.Active = true; frame.AnchorPoint = Vector2.new(1, 0)
    frame.Position = opts.position or UDim2.new(1, -12, 0, 120)
    frame.Size = UDim2.fromOffset(opts.width or 196, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = bg; frame.BackgroundTransparency = 0.05; frame.BorderSizePixel = 0; frame.Parent = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = accent; stroke.Thickness = 1.4; stroke.Transparency = 0.18; stroke.Parent = frame
    local barFrame = Instance.new("Frame"); barFrame.Size = UDim2.new(0, 3, 1, 0); barFrame.BackgroundColor3 = accent; barFrame.BorderSizePixel = 0; barFrame.ZIndex = 3; barFrame.Parent = frame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = barFrame

    local content = Instance.new("Frame"); content.BackgroundTransparency = 1; content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y; content.Parent = frame
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 13); pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8); pad.PaddingBottom = UDim.new(0, 8); pad.Parent = content
    local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 6); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = content
    self.content = content

    -- title
    local title = Instance.new("TextLabel"); title.BackgroundTransparency = 1; title.Size = UDim2.new(1, 0, 0, 20); title.LayoutOrder = 0
    title.Font = Enum.Font.GothamBold; title.TextSize = 14; title.TextColor3 = accent; title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = opts.title or "Keybinds"; title.Parent = content

    -- drag
    local dragging, ds, sp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; ds = i.Position; sp = frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)

    -- key dispatch (one listener; fires the matching bind on key press)
    UIS.InputBegan:Connect(function(i, gpe)
        if gpe then return end
        if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local b = self.byKey[i.KeyCode]
        if b then
            b.active = not b.active
            self:_render(b)
            pcall(b.cb, b.active)
        end
    end)

    self.gui, self.frame = gui, frame
    return self
end

function Keybinds:_render(b)
    if b.dot then b.dot.BackgroundColor3 = b.active and Color3.fromRGB(80, 230, 140) or Color3.fromRGB(120, 130, 150) end
end

-- Bind a key to a label + callback. cb(active) fires on each press (toggle).
function Keybinds:Bind(id, label, keyCode, cb)
    self._order += 1
    local row = Instance.new("Frame"); row.BackgroundTransparency = 1; row.Size = UDim2.new(1, 0, 0, 20); row.LayoutOrder = self._order; row.Parent = self.content
    local dot = Instance.new("Frame"); dot.AnchorPoint = Vector2.new(0, 0.5); dot.Position = UDim2.new(0, 0, 0.5, 0); dot.Size = UDim2.fromOffset(7, 7)
    dot.BackgroundColor3 = Color3.fromRGB(120, 130, 150); dot.BorderSizePixel = 0; dot.Parent = row
    local dc = Instance.new("UICorner"); dc.CornerRadius = UDim.new(1, 0); dc.Parent = dot
    local lbl = Instance.new("TextLabel"); lbl.BackgroundTransparency = 1; lbl.Position = UDim2.new(0, 14, 0, 0); lbl.Size = UDim2.new(1, -58, 1, 0)
    lbl.Font = Enum.Font.Gotham; lbl.TextSize = 13; lbl.TextColor3 = self.fg; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextTruncate = Enum.TextTruncate.AtEnd; lbl.Text = label; lbl.Parent = row
    local chip = Instance.new("TextLabel"); chip.AnchorPoint = Vector2.new(1, 0.5); chip.Position = UDim2.new(1, 0, 0.5, 0); chip.Size = UDim2.fromOffset(40, 18)
    chip.BackgroundColor3 = self.accent; chip.BackgroundTransparency = 0.78; chip.Font = Enum.Font.GothamBold; chip.TextSize = 11
    chip.TextColor3 = self.fg; chip.Text = keyName(keyCode); chip.Parent = row
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 5); cc.Parent = chip
    local cs = Instance.new("UIStroke"); cs.Color = self.accent; cs.Transparency = 0.4; cs.Parent = chip

    local b = { id = id, label = label, key = keyCode, cb = cb or function() end, active = false, dot = dot, chip = chip }
    self.binds[id] = b
    self.byKey[keyCode] = b
    return b
end

-- reflect external state on/off (updates the dot) without firing the callback
function Keybinds:Set(id, active)
    local b = self.binds[id]; if not b then return end
    b.active = active and true or false
    self:_render(b)
end
function Keybinds:SetVisible(v) if self.frame then self.frame.Visible = v ~= false end end
function Keybinds:Destroy() pcall(function() self.gui:Destroy() end) end

return Keybinds
