dofile_once("mods/lamas_stats/files/scripts/redefined_functions.lua")
T = dofile_once("mods/lamas_stats/translations/translation.lua") ---Translation strings (i hate this)
local gui = dofile_once("mods/lamas_stats/files/scripts/gui/gui_main.lua") ---@type LS_Gui
local current_language = GameTextGetTranslatedOrNot("$current_language")

imgui = load_imgui and load_imgui({ mod = "lamas_stats", version = "1.0.0" })

---After OnModPostInit
function OnMagicNumbersAndWorldSeedInitialized()
	gui:PostBiomeInit()
end

---Idk why it's called before initialized
function OnWorldPostUpdate()
	gui:Loop()
end

---?
function OnPlayerSpawned()
	gui:PostWorldInit()
end

---Fetch settings
---@param is_paused boolean
function OnPausedChanged(is_paused)
	if not is_paused then return end
	local language = GameTextGetTranslatedOrNot("$current_language")
	local did_language_changed = current_language ~= language
	if did_language_changed then current_language = language end
	gui:GetSettings(did_language_changed)
end
