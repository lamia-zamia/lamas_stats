dofile_once("mods/lamas_stats/files/scripts/redefined_functions.lua")
T = dofile_once("mods/lamas_stats/translations/translation.lua") --- Translation strings (i hate this)
local gui = dofile_once("mods/lamas_stats/files/scripts/gui/gui_main.lua") --- @type LS_Gui

--- After OnModPostInit
function OnMagicNumbersAndWorldSeedInitialized()
	gui:PostBiomeInit()
end

--- Idk why it's called before initialized
function OnWorldPostUpdate()
	gui:Loop()
end

--- ?
function OnPlayerSpawned()
	gui:PostWorldInit()
end

--- Fetch settings
function OnPausedChanged()
	gui:GetSettings()
end
