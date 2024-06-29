local PerksHideGlobalValueString = "lamas_stats_hide_vanilla_icon"

local function CheckGlobal()
	if GlobalsGetValue(PerksHideGlobalValueString, "0") == "0" then return false
	else return true end
end

if ModSettingGet("lamas_stats.enable_current_perks") and ModSettingGet("lamas_stats.current_perks_hide_vanilla") then
	if CheckGlobal() then return
	else
		local child_entity_perks = EntityGetAllChildren(EntityGetWithTag("player_unit")[1], "perk_entity")
		for _,entity_id in ipairs(child_entity_perks) do
			local component_id = EntityGetFirstComponent(entity_id, "UIIconComponent")
			if component_id ~= nil then
				EntityKill(entity_id)
			end
		end
		GlobalsSetValue(PerksHideGlobalValueString, "1")
	end
else
	if CheckGlobal() then
		local player = EntityGetWithTag("player_unit")[1]
		if not perk_list then dofile_once("data/scripts/perks/perk_list.lua") end
		for _,perk in ipairs(perk_list) do
			local flag_name = get_perk_picked_flag_name(perk.id)
			local pickup_count = tonumber(GlobalsGetValue(flag_name .. "_PICKUP_COUNT", "0"))
			local no_remove = perk.do_not_remove or false
			if not no_remove then
				for i=1, pickup_count do
					local entity_ui = EntityCreateNew( "" )
					EntityAddComponent( entity_ui, "UIIconComponent", 
					{ 
						name = perk.ui_name,
						description = perk.ui_description,
						icon_sprite_file = perk.ui_icon
					})
					EntityAddTag( entity_ui, "perk_entity" )
					EntityAddChild( player, entity_ui )
				end
			end
		end
		GlobalsSetValue(PerksHideGlobalValueString, "0")
	else return end
end