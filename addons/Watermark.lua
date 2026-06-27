-- ============================================================================
--  Y2k Watermark  |  draggable, theme-matched watermark module for the Y2k UI
--  Loads alongside ThemeManager / SaveManager. Reads Library.Scheme so it always
--  matches the menu's accent/colours (including ThemeManager changes at load).
--
--  local Watermark = loadUI(repo .. "addons/Watermark.lua")
--  local wm = Watermark.new(Library, { title = "Y2k" })
--  wm:Set("Merge a Nuke  |  60 fps  |  12 ms")
--  wm:Bind(function() return ("Y2k | %d fps"):format(workspace:GetRealPhysicsFPS()) end, 1)
-- ============================================================================
local RunService = game:GetService("RunService")
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

local Watermark = {}
Watermark.__index = Watermark

function Watermark.new(Library, opts)
    opts = opts or {}
    local self = setmetatable({}, Watermark)
    local accent = scheme(Library, "AccentColor", Color3.fromRGB(0, 180, 255))
    local bg     = scheme(Library, "MainColor",   Color3.fromRGB(19, 21, 34))
    local fg     = scheme(Library, "FontColor",   Color3.fromRGB(240, 243, 250))

    local gui = Instance.new("ScreenGui")
    gui.Name = "\0Y2kWatermark"; gui.IgnoreGuiInset = true; gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    protect(gui); gui.Parent = host()

    local frame = Instance.new("Frame")
    frame.Name = "WM"; frame.AutomaticSize = Enum.AutomaticSize.X; frame.Active = true
    frame.Size = UDim2.fromOffset(0, 30); frame.Position = opts.position or UDim2.fromOffset(16, 16)
    frame.BackgroundColor3 = bg; frame.BackgroundTransparency = 0.05; frame.BorderSizePixel = 0; frame.Parent = gui
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 6); corner.Parent = frame
    local stroke = Instance.new("UIStroke"); stroke.Color = accent; stroke.Thickness = 1.4; stroke.Transparency = 0.15; stroke.Parent = frame
    -- accent bar sits at the very left edge (NOT inside the padded content, so it
    -- never overlaps the text)
    local barFrame = Instance.new("Frame"); barFrame.Size = UDim2.new(0, 3, 1, 0); barFrame.Position = UDim2.new(0, 0, 0, 0)
    barFrame.BackgroundColor3 = accent; barFrame.BorderSizePixel = 0; barFrame.ZIndex = 3; barFrame.Parent = frame
    local content = Instance.new("Frame"); content.BackgroundTransparency = 1; content.AutomaticSize = Enum.AutomaticSize.X; content.Size = UDim2.new(0, 0, 1, 0); content.Parent = frame
    local pad = Instance.new("UIPadding"); pad.PaddingLeft = UDim.new(0, 18); pad.PaddingRight = UDim.new(0, 14); pad.Parent = content
    local label = Instance.new("TextLabel"); label.AutomaticSize = Enum.AutomaticSize.X
    label.BackgroundTransparency = 1; label.Size = UDim2.new(0, 0, 1, 0); label.Font = Enum.Font.GothamBold
    label.TextSize = 14; label.TextColor3 = fg; label.TextXAlignment = Enum.TextXAlignment.Left
    local _t = opts.title or "Y2kScript"; if _t == "Y2k" then _t = "Y2kScript" end
    label.Text = _t; label.Parent = content

    -- drag
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = i.Position; startPos = frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    -- real render FPS (workspace:GetRealPhysicsFPS() is ~locked to 60; this is the
    -- true frame rate, averaged over 0.5s windows)
    self._fps = 60
    local acc, frames = 0, 0
    self._fpsConn = game:GetService("RunService").RenderStepped:Connect(function(dt)
        acc += dt; frames += 1
        if acc >= 0.5 then self._fps = math.floor(frames / acc + 0.5); acc = 0; frames = 0 end
    end)

    self.gui, self.frame, self.label = gui, frame, label
    return self
end

function Watermark:Set(text) if self.label then self.label.Text = tostring(text) end end
function Watermark:SetVisible(b) if self.frame then self.frame.Visible = b ~= false end end
-- live updater: fn returns the text, refreshed every `interval` seconds until destroyed
function Watermark:Bind(fn, interval)
    interval = interval or 1
    task.spawn(function()
        while self.gui and self.gui.Parent do
            local ok, txt = pcall(fn)
            if ok and txt ~= nil then self:Set(txt) end
            task.wait(interval)
        end
    end)
end
-- standard watermark: "<prefix>  |  <game>  |  N fps" with REAL fps, auto-refreshed
function Watermark:Auto(prefix, gameName)
    if not prefix or prefix == "Y2k" then prefix = "Y2kScript" end
    self:Bind(function()
        return ("%s  |  %s  |  %d fps"):format(prefix, gameName or "", self._fps or 60)
    end, 0.5)
    return self
end
function Watermark:Destroy()
    pcall(function() if self._fpsConn then self._fpsConn:Disconnect() end end)
    pcall(function() self.gui:Destroy() end)
end

return Watermark
