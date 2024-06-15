dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/lamas_stats/files/common.lua")

original_material_properties = {} --table of material names and colors, populates from materials.xml

--[[	custom functions that need to be done during init ]]
function AppendFunction(file, search, add)
	local content = ModTextFileGetContent(file)
	local first, last = content:find(search, 0, true)
	local before = content:sub(1, last)
	local after = content:sub(last + 1)
	local new = before .. "\n" .. add .. "\n" .. after
	ModTextFileSetContent(file, new)
end


--[[	game hooks start here]]
function OnModPreInit()
	
	if ModSettingGet("lamas_stats.enable_perks_autoupdate") then --hooking perks refresh into game events
		AppendFunction("data/scripts/perks/perk.lua", "if ( no_perk_entity == false ) then", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
		AppendFunction("data/scripts/perks/perk.lua", "perk_spawn( x, y, perk_id )", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
	end
end

function OnMagicNumbersAndWorldSeedInitialized()
	lamas_stats_gather_material_name_table = dofile_once("mods/lamas_stats/files/material_graphics.lua")
end

function OnPlayerSpawned(player_entity)
	dofile_once("mods/lamas_stats/files/info_gui.lua") --loading main gui file
end

function OnWorldPostUpdate()
	if lamas_stats_main_loop then lamas_stats_main_loop() end
end