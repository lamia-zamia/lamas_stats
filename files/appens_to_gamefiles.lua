if ModSettingGet("lamas_stats.enable_perks_autoupdate") then --hooking perks refresh into game events
	AddAfterText("data/scripts/perks/perk.lua", "if ( no_perk_entity == false ) then", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
	AddBeforeText("data/scripts/perks/perk.lua", "if dont_remove_other_perks then", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
end

if ModSettingGet("lamas_stats.current_perks_hide_vanilla") then
	local remove_string = "local entity_ui = EntityCreateNew%( \"\" %).-EntityAddChild%( entity_who_picked, entity_ui %)"
	ReplaceText("data/scripts/perks/perk.lua", remove_string, "-- lamas_stats removed")
end