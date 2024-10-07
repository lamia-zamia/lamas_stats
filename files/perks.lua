---@diagnostic disable: lowercase-global, missing-global-doc, undefined-global
dofile_once("mods/lamas_stats/files/perks_common.lua")
dofile_once("mods/lamas_stats/files/perks_predict.lua")
dofile_once("mods/lamas_stats/files/perks_current.lua")

local display_current = false

function gui_perks_main()
	local gui_id = 1000
	function id()
		gui_id = gui_id + 1
		return gui_id
	end
	GuiBeginAutoBox(gui_menu)
	
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y, false, 0, 0) --layer1
	GuiZ = 900
	GuiZSet(gui_menu, GuiZ)
	GuiText(gui_menu, 0, 0, "==== " .. _T.Perks .. " ====", perks_scale)
	
	--buttons
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	gui_menu_switch_button(gui_menu, id(), perks_scale, gui_menu_main_display_loop) --return
	gui_do_refresh_button(gui_menu, id(), perks_scale, gui_perks_refresh_perks)

	if ModSettingGet("lamas_stats.enable_current_perks") and perks_current_count > 0 then
		if GuiButton(gui_menu, id(), 0, 0, "[" .. _T.lamas_stat_current .. "]", perks_scale) then
			display_current = not display_current
		end
	end
	if ModSettingGet("lamas_stats.enable_future_perks") then
		if GuiButton(gui_menu, id(), 0, 0, "[" .. _T.lamas_stats_perks_next .. "]", perks_scale) then
			display_future = not display_future
		end
	end
	GuiLayoutEnd(gui_menu) 
	--buttons end
	
	if ModSettingGet("lamas_stats.enable_perks_autoupdate") then
		if ModSettingGet("lamas_stats.enable_perks_autoupdate_flag") then --by event
			ModSettingSet("lamas_stats.enable_perks_autoupdate_flag", false)
			gui_perks_refresh_perks()
		end
		if GameGetFrameNum() % 300 == 0 then --update once per 5 second
			gui_perks_refresh_perks()
		end
	end

	gui_perks_show_stats(gui_menu)
	
	if ModSettingGet("lamas_stats.enable_nearby_perks") then 
		gui_perks_show_perks_on_screen(gui_menu)
	end
	
	if display_current then	gui_perks_show_current_perks(gui_menu) end
	
	if display_future then gui_perks_show_future_perks(gui_menu) end
	

	GuiLayoutEnd(gui_menu) --layer1
	GuiZSetForNextWidget(gui_menu, GuiZ+10)
	GuiEndAutoBoxNinePiece(gui_menu, 1, 0, 0, false, 0, screen_png, screen_png)
end

function gui_perks_refresh_perks()
	gui_perks_get_current_perks()
	gui_perks_gather_stats()
	
	gui_perks_get_perks_on_screen()	
	
	if ModSettingGet("lamas_stats.enable_future_perks") then
		perks = perk_get_spawn_order()
		gui_perks_get_future_perks()
		gui_perks_get_reroll_perks()
	end
end