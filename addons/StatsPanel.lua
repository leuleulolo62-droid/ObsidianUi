-- ============================================================================
--  Y2k Stats Panel  |  theme-matched, draggable live stats panel module
--  Loads alongside ThemeManager / SaveManager. Reads Library.Scheme so it
--  matches the menu (accent / main / font colours). Replaces the per-script
--  hand-rolled CoreGui stat boxes with one consistent component.
--
--  local StatsPanel = loadUI(repo .. "addons/StatsPanel.lua")
--  local p = StatsPanel.new(Library, { title = "MERGE A NUKE" })
--  p:Line("cash", { color = Color3.fromRGB(120,255,140), bold = true })
--  p:Line("merge")
--  p:Set("cash", "Cash: $7.04K")
--  p:Set("merge", "Merge: parked, picking up")
--  p:SetVisible(true)
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

local StatsPanel = {}
StatsPanel.__index = StatsPanel

function StatsPanel.new(Library, opts)
    opts = opts or {}
    local self = setmetatable({ lines = {}, _order = 0 }, StatsPanel)
    local accent = scheme(Library, "AccentColor", Color3.fromRGB(0, 180, 255))
    local bg     = scheme(Library, "MainColor",   Color3.fromRGB(19, 21, 34))
    local fg     = scheme(Library, "FontColor",   Color3.fromRGB(240, 243, 250))
    self.accent, self.fg = accent, fg

    local gui = Instance.new("ScreenGui")
    gui.Name = "\0Y2kStats"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    protect(gui); gui.Parent = host()

    local frame = Instance.new("Frame")
    frame.Name = "Stats"; frame.Active = true; frame.AnchorPoint = Vector2.new(0, 0.5)
    frame.Position = opts.position or UDim2.new(0, 12, 0.5, 0)
    frame.Size = UDim2.fromOffset(opts.width or 244, 0); frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.BackgroundColor3 = bg; frame.BackgroundTransparency = 0.05; frame.BorderSizePixel = 0; frame.Parent = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = accent; stroke.Thickness = 1.4; stroke.Transparency = 0.18; stroke.Parent = frame
    local barFrame = Instance.new("Frame"); barFrame.Size = UDim2.new(0, 3, 1, 0); barFrame.BackgroundColor3 = accent; barFrame.BorderSizePixel = 0; barFrame.ZIndex = 3; barFrame.Parent = frame
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 8); bc.Parent = barFrame

    local content = Instance.new("Frame"); content.BackgroundTransparency = 1; content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y; content.Parent = frame
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 9); pad.PaddingBottom = UDim.new(0, 9); pad.Parent = content
    local list = Instance.new("UIListLayout"); list.Padding = UDim.new(0, 3); list.SortOrder = Enum.SortOrder.LayoutOrder; list.Parent = content
    self.content = content

    if opts.title then
        self:Line("__title", { size = 16, color = accent, bold = true })
        self:Set("__title", opts.title)
    end

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

    self.gui, self.frame = gui, frame
    return self
end

-- declare an ordered line. o = { size, color, bold, rich }
function StatsPanel:Line(id, o)
    if self.lines[id] then return self.lines[id] end
    o = o or {}
    self._order += 1
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.Size = UDim2.new(1, 0, 0, (o.size or 13) + 5); l.LayoutOrder = self._order
    l.Font = o.bold and Enum.Font.GothamBold or Enum.Font.Gotham; l.TextSize = o.size or 13
    l.TextColor3 = o.color or self.fg; l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd; l.RichText = o.rich == true; l.Text = ""; l.Parent = self.content
    self.lines[id] = l
    return l
end
function StatsPanel:Set(id, text)
    local l = self.lines[id] or self:Line(id, {})
    l.Text = text == nil and "" or tostring(text)
end
function StatsPanel:SetColor(id, color) local l = self.lines[id]; if l then l.TextColor3 = color end end
function StatsPanel:SetVisible(b) if self.frame then self.frame.Visible = b ~= false end end
function StatsPanel:Destroy() pcall(function() self.gui:Destroy() end) end

return StatsPanel
