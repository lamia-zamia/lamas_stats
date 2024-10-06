---@diagnostic disable: lowercase-global, missing-global-doc, undefined-global
function gui_fungal_shift()
	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		gui_fungal_show_aplc_recipes(gui_menu)
	end
end