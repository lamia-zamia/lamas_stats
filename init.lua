--[[	game hooks start here]]
function OnModPreInit()
	if ModSettingGet("lamas_stats.enable_perks_autoupdate") then --hooking perks refresh into game events
		AppendFunction("data/scripts/perks/perk.lua", "if ( no_perk_entity == false ) then", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
		AppendFunction("data/scripts/perks/perk.lua", "perk_spawn( x, y, perk_id )", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
	end

end

function OnPlayerSpawned(player_entity)
	local lamas_stats_menu_enabled = false
	if ModSettingGet("lamas_stats.enabled_at_start") == true then
		ReOpenGUI()
	else
		CloseGUI() --in case if menu was loaded during
	end
end

function OnWorldPostUpdate()
    if InputIsKeyJustDown(ModSettingGet("lamas_stats.input_key")) == true then 
        if (lamas_stats_menu_enabled == false) then
			OpenGUI()
        else
			CloseGUI()
        end
    end
	if lamas_stats_menu_enabled == true and ModSettingGet("lamas_stats.setting_changed") then
		ReOpenGUI()
		ModSettingSet("lamas_stats.setting_changed", false)
	end
end

function OnPlayerDied()
	CloseGUI()
end
--[[	end of game hook]]
--[[	custom functions start here]]
function OpenGUI()
--123
    EntityLoad("mods/lamas_stats/files/info_gui.xml")
	lamas_stats_menu_enabled = true
end

function CloseGUI()
    EntityKill(EntityGetWithName("lamas_stats_info_gui"))
	lamas_stats_menu_enabled = false
end

function ReOpenGUI()
	CloseGUI()
	OpenGUI()
end

function AppendFunction(file, search, add)
	local content = ModTextFileGetContent(file)
	local first, last = content:find(search, 0, true)
	local before = content:sub(1, last)
	local after = content:sub(last + 1)
	local new = before .. "\n" .. add .. "\n" .. after
	ModTextFileSetContent(file, new)
end