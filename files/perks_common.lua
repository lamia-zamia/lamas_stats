dofile_once("data/scripts/perks/perk.lua")
perk_png = "data/items_gfx/perk.png"
reroll_png = "mods/lamas_stats/files/reroll.png"
perks = perk_get_spawn_order() --from default function
perks_onscreen,perks_current_count = nil
perks_scale = 1



local function gui_perks_collate_data_perks() --one-time function for gathering name and icons of perks
	perks_data = {}
	for i,perk in ipairs(perk_list) do
		perks_data[perk.id] = {}
		perks_data[perk.id].ui_name = perk.ui_name
		perks_data[perk.id].ui_description = perk.ui_description
		perks_data[perk.id].perk_icon = perk.perk_icon
	end
	perks_data["lamas_unknown"] = {}
	perks_data["lamas_unknown"].ui_name = _T.lamas_stats_unknown
	perks_data["lamas_unknown"].ui_description = _T.lamas_stats_unknown
	perks_data["lamas_unknown"].perk_icon = perk_png
	return perks_data
end
perks_data = gui_perks_collate_data_perks()

local function gui_perks_collate_data_actions() --one-time function for gathering name and icons of perks
	actions_data = {}
	dofile_once("data/scripts/gun/gun_actions.lua")
	for i,action in ipairs(actions) do
		actions_data[action.id] = {}
		actions_data[action.id].name = action.name
		actions_data[action.id].description = action.description
	end
	return actions_data
end
actions_data = gui_perks_collate_data_actions()