gui_top = GuiCreate()
gui_menu = GuiCreate()

menu_pos_x = 2
menu_pos_y = 12

local top_text = "[L]"
local lamas_stats_menu_enabled = ModSettingGet("lamas_stats.enabled_at_start")

local menu_opened = false
if ModSettingGet("lamas_stats.lamas_menu_enabled_default") then
	local menu_opened = true
	gui_menu_function = gui_menu_main_display_loop
end

function gui_top_main_display_loop()
	if ModSettingGet("lamas_stats.stats_position") == "on top" then
		local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui_top)
		GUI_Stats(gui_top, id(), x+20, y)
	end
end

function gui_menu_main_display_loop()
	if ModSettingGet("lamas_stats.stats_position") == "merged" then
		GuiText(gui_menu,0,0," ")
		local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui_menu)
		GuiLayoutBeginLayer(gui_menu)
		GUI_Stats(gui_menu, id(), x, y)
		GuiLayoutEndLayer(gui_menu) 
	end
	
	for _,button in ipairs(lamas_stats_main_menu_buttons) do
		if GuiButton(gui_menu, id(), 0, 0, button.ui_name) then
			button.action()
		end
	end
end

local function PopulateButtons()
	lamas_stats_main_menu_buttons = {}
	if ModSettingGet("lamas_stats.enable_fungal") then
		dofile_once("mods/lamas_stats/files/fungal.lua")
		UpdateFungalVariables()
		table.insert(lamas_stats_main_menu_buttons,
		{
			ui_name = "[" .. _T.FungalShifts .. "]",
			action = function() 
				UpdateFungalVariables()
				gui_menu_function = gui_fungal_shift 
				end,
		})
	end
	if ModSettingGet("lamas_stats.enable_perks") then
		dofile_once("mods/lamas_stats/files/perks.lua")
		gui_perks_refresh_perks()
		table.insert(lamas_stats_main_menu_buttons,
		{
			ui_name = "[" .. _T.Perks .. "]",
			action = function() 
				gui_perks_refresh_perks()
				gui_menu_function = gui_perks_main
				end,
		})
	end
	
	if ModSettingGet("lamas_stats.KYS_Button") then 
		table.insert(lamas_stats_main_menu_buttons,
		{
			ui_name = "[" .. _T.KYS_Suicide .. "]",
			action = function()
				gui_menu_function = gui_kys_main_loop
				end,
		})
	end
end

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

local function PopulateStatsList()
	lamas_stats_main_menu_list = {}
	if ModSettingGet("lamas_stats.stats_enable") then
		dofile_once("mods/lamas_stats/files/stats.lua")
		StatsTableInsert()
	end
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

--[[		these are executed once on load		]]
LamasStatsApplySettings()
gui_top_function = gui_top_main_display_loop