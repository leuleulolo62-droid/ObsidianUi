-- ThemeManager stub (ObsidianUi compat). Theme is handled by MacLib itself; these no-op.
local ThemeManager = {}
function ThemeManager:SetLibrary(l) self.Library = l end
function ThemeManager:SetFolder(_) end
function ThemeManager:SetSubFolder(_) end
function ThemeManager:ApplyToTab(_) end
function ThemeManager:ApplyToGroupbox(_) end
function ThemeManager:CreateGroupBoxes(_) end
function ThemeManager:ApplyTheme(_) end
function ThemeManager:LoadDefault() end
function ThemeManager:SaveDefault(_) end
function ThemeManager:BuildFolderTree() end
function ThemeManager:CreateThemeManager(_) end
return ThemeManager
