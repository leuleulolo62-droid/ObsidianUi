-- ============================================================================
--  Y2k Core  |  one-line loader for the whole UI stack
--  Caches the compiled Library + every addon in getgenv() so a RE-execution is
--  instant (no re-compiling the ~200KB MacLib each run — big win for farmers who
--  rejoin / re-run). First run loads once; every run after returns the cache.
--
--  In a script:
--    local Y2k = loadstring(game:HttpGet("https://y2kscript.xyz/lib?f=Core.lua"))()
--    local Library, ThemeManager, SaveManager = Y2k.Library, Y2k.ThemeManager, Y2k.SaveManager
--    local StatsPanel, Watermark, Keybinds     = Y2k.StatsPanel, Y2k.Watermark, Y2k.Keybinds
--    local Toggles, Options                     = Y2k.Toggles, Y2k.Options
-- ============================================================================
local _gg = (getgenv and getgenv()) or shared or _G
local Y2K_VER = "2026.06.27d"  -- bump on any module change so cached sessions reload fresh
if _gg.Y2kCore and _gg.Y2kCore._ver == Y2K_VER then return _gg.Y2kCore end

local repo = "https://y2kscript.xyz/lib?f="

-- robust loader: some lib files return a function-that-returns-the-lib
local function loadUI(url)
    local raw = game:HttpGet(url)
    if type(raw) == "function" then
        local cur = raw
        for _ = 1, 6 do
            if type(cur) ~= "function" then return cur end
            local ok, nx = pcall(function() return cur(game, url) end)
            if not ok then break end
            cur = nx
        end
        if type(cur) ~= "function" then return cur end
        local fn = loadstring(tostring(raw)); if fn then return fn(game) end
        return cur
    end
    return loadstring(raw)()
end

local cb = "&cb=" .. tostring(tick and math.floor(tick()) or 0)

local Library = loadUI(repo .. "Library.lua")
local core = {
    _ver         = Y2K_VER,
    Library      = Library,
    Toggles      = Library.Toggles,
    Options      = Library.Options,
    ThemeManager = loadUI(repo .. "addons/ThemeManager.lua"),
    SaveManager  = loadUI(repo .. "addons/SaveManager.lua"),
    StatsPanel   = loadUI(repo .. "addons/StatsPanel.lua" .. cb),
    Watermark    = loadUI(repo .. "addons/Watermark.lua" .. cb),
    Keybinds     = loadUI(repo .. "addons/Keybinds.lua" .. cb),
    repo         = repo,
    loadUI       = loadUI,
}

-- Mount the module show/hide toggles into a script's SETTINGS tab. This is the
-- ONLY place the stats panel / watermark / keybinds get toggled — no per-feature
-- toggles scattered on other tabs. Pass the live module instances you created:
--   Y2k.modulesGroup(Tabs.Settings, { panel = panel, wm = wm, kb = kb })
function core.modulesGroup(settingsTab, mods, title)
    mods = mods or {}
    local g = settingsTab:AddRightGroupbox(title or "Interface Modules", "layout")
    g:AddLabel({ Text = "Show or hide the on-screen modules. Toggled only from here.", DoesWrap = true })
    if mods.panel then g:AddToggle("Y2kStatsVis", { Text = "Stats Panel", Default = true, Callback = function(v) pcall(function() mods.panel:SetVisible(v) end) end }) end
    if mods.wm    then g:AddToggle("Y2kWmVis",    { Text = "Watermark",   Default = true, Callback = function(v) pcall(function() mods.wm:SetVisible(v) end) end }) end
    if mods.kb    then g:AddToggle("Y2kKbVis",    { Text = "Keybinds",     Default = true, Callback = function(v) pcall(function() mods.kb:SetVisible(v) end) end }) end
    return g
end

-- shared real render-FPS counter (workspace:GetRealPhysicsFPS() is ~locked to 60).
-- Y2k.fps() returns the true frame rate, averaged over 0.5s windows.
do
    local fps, acc, frames = 60, 0, 0
    pcall(function()
        game:GetService("RunService").RenderStepped:Connect(function(dt)
            acc += dt; frames += 1
            if acc >= 0.5 then fps = math.floor(frames / acc + 0.5); acc = 0; frames = 0 end
        end)
    end)
    core.fps = function() return fps end
end

-- single-instance guard (hub-wide): a script calls Y2k.claim("Name") once at the
-- top; if it returns false the script is already running -> abort the re-execute
-- so you never get duplicate UIs / fighting loops. release() on unload frees it.
-- A script calls Y2k.claim("Name") at the top AND Y2k.setUnload("Name", fn) once its
-- unload is defined. Re-running then tears down the previous instance via that unload
-- and reloads fresh -> always the LATEST version, no duplicate UIs / stale keybinds.
_gg.Y2kClaimed = _gg.Y2kClaimed or {}
_gg.Y2kUnloaders = _gg.Y2kUnloaders or {}
function core.claim(name)
    if _gg.Y2kClaimed[name] then
        local fn = _gg.Y2kUnloaders[name]
        if type(fn) == "function" then pcall(fn); _gg.Y2kClaimed[name] = nil; _gg.Y2kUnloaders[name] = nil
        else return false end   -- no unload registered (older script) -> keep old block behavior
    end
    _gg.Y2kClaimed[name] = true
    return true
end
function core.setUnload(name, fn) _gg.Y2kUnloaders = _gg.Y2kUnloaders or {}; _gg.Y2kUnloaders[name] = fn end
function core.release(name) if _gg.Y2kClaimed then _gg.Y2kClaimed[name] = nil end if _gg.Y2kUnloaders then _gg.Y2kUnloaders[name] = nil end end

_gg.Y2kCore = core
return core
