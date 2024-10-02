function gui_kys_main_loop()
	local gui_id = 100
	local function id()
		gui_id = gui_id + 1
		return gui_id
	end
	
	local scale = 1
	GuiBeginAutoBox(gui_menu)
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y) --layer1
	GuiZSet(gui_menu,800)
	GuiText(gui_menu, 0, 0, ModSettingGet("lamas_stats.lamas_menu_header"))

	gui_menu_switch_button(gui_menu, id(), scale, gui_menu_main_display_loop) --return
	
	GuiColorSetForNextWidget(gui_menu,1,1,0,1)
	GuiText(gui_menu, 0, 0, _T.KYS_Suicide_Warn)
	GuiText(gui_menu, 0, 0, " ")
	GuiColorSetForNextWidget(gui_menu,1,0,0,1)
	if GuiButton(gui_menu, id(), 0, 0, "[" .. _T.KYS_Button .. "]", 1) then
		if ModSettingGet("lamas_stats.KYS_Button_Hide") then
			ModSettingSetNextValue("lamas_stats.KYS_Button", false, false)
		end
		local gsc_id = EntityGetFirstComponentIncludingDisabled(player, "GameStatsComponent")
		ComponentSetValue2(gsc_id, "extra_death_msg", _T.KYS_Suicide)
		EntityKill(player)
	end

	GuiLayoutEnd(gui_menu) --layer1
	GuiZSetForNextWidget(gui_menu, 1000)
	GuiEndAutoBoxNinePiece(gui_menu, 1, 130, 0, false, 0, screen_png, screen_png)
end

local function LamasStatsApplySettings()
	UpdateCommonVariables()
	stat_pos_x = ModSettingGet("lamas_stats.overlay_x")
	stat_pos_y = ModSettingGet("lamas_stats.overlay_y")
	PopulateStatsList()
	PopulateButtons()
	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		APLC_table = dofile_once("mods/lamas_stats/files/APLC.lua")
	end
end