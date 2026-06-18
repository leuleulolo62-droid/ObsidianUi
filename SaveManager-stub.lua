-- SaveManager stub (ObsidianUi compat). BuildConfigSection wires to MacLib's own
-- config UI (which saves/loads the shim's flagged components). The rest no-op safely.
local SaveManager = {}
function SaveManager:SetLibrary(l) self.Library = l end
function SaveManager:SetFolder(f) self.Folder = f if MacLib and MacLib.SetFolder then pcall(function() MacLib:SetFolder(f) end) end end
function SaveManager:SetSubFolder(_) end
function SaveManager:SetIgnoreIndexes(_) end
function SaveManager:IgnoreThemeSettings() end
function SaveManager:SetExclude(_) end
function SaveManager:BuildConfigSection(tab)
	-- tab is the shim's tab wrapper; use the underlying MacLib tab for a real config panel
	if tab and tab._tab and tab._tab.InsertConfigSection then
		pcall(function() tab._tab:InsertConfigSection("Left") end)
	end
end
function SaveManager:LoadAutoloadConfig() if MacLib and MacLib.LoadAutoLoadConfig then pcall(function() MacLib:LoadAutoLoadConfig() end) end end
function SaveManager:SaveConfig(name) if MacLib and MacLib.SaveConfig then pcall(function() MacLib:SaveConfig(name) end) end end
function SaveManager:LoadConfig(name) if MacLib and MacLib.LoadConfig then pcall(function() MacLib:LoadConfig(name) end) end end
function SaveManager:RefreshConfigList() end
function SaveManager:CheckFolderTree() end
function SaveManager:BuildFolderTree() end
return SaveManager
