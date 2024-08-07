dofile_once("data/scripts/lib/utilities.lua")

original_material_properties = {} --table of material names and colors, populates from materials.xml

--[[	game hooks start here]]
function OnModPreInit()
	dofile_once("mods/lamas_stats/files/appens_to_gamefiles.lua")
end

function OnModPostInit()
	dofile_once("mods/lamas_stats/files/common.lua")
end

function OnMagicNumbersAndWorldSeedInitialized()
	original_material_properties = dofile_once("mods/lamas_stats/files/material_graphics.lua")
end

function OnPlayerSpawned(player_entity)
	dofile_once("mods/lamas_stats/files/info_gui.lua") --loading main gui file
	dofile_once("mods/lamas_stats/files/perks_vanilla_icons.lua")
end

function OnWorldPostUpdate()
	if lamas_stats_main_loop then lamas_stats_main_loop() end
end