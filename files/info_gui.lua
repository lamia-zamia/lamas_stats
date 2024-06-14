dofile_once("mods/lamas_stats/files/common.lua")
dofile_once("mods/lamas_stats/translations/translation.lua")

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
	local gui_id = 100
	local function id()
		gui_id = gui_id + 1
		return gui_id
	end
	
	GuiZSet(gui_menu,800)
	GuiLayoutBeginHorizontal(gui_top, stat_pos_x, stat_pos_y, false, 0, 0)
	if GuiButton(gui_top, id(), 0, 0, top_text) then
		ToggleMenu()
	end
	GuiLayoutEnd(gui_top)
	if ModSettingGet("lamas_stats.stats_position") == "on top" then
		local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui_top)
		GUI_Stats(gui_top, id(), x+20, y)
	end
end

function gui_menu_main_display_loop()
	local gui_id = 100
	local function id()
		gui_id = gui_id + 1
		return gui_id
	end
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y) --layer1
	GuiZSet(gui_menu,800)
	GuiText(gui_menu, 0, 0, ModSettingGet("lamas_stats.lamas_menu_header"))

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
	GuiLayoutEnd(gui_menu) --layer1
end

function ToggleMenu()
	if menu_opened then
		gui_menu_function = nil
		top_text = "[L]"
		menu_opened = false
	else
		gui_menu_function = gui_menu_main_display_loop
		top_text = "[*]"
		menu_opened = true
	end
end

local function PopulateButtons()
	lamas_stats_main_menu_buttons = {}
	if ModSettingGet("lamas_stats.enable_fungal") == true then
		dofile_once("mods/lamas_stats/files/fungal.lua")
		table.insert(lamas_stats_main_menu_buttons,
		{
			ui_name = "[" .. _T.FungalShifts .. "]",
			action = function() 
				gui_fungal_shift_get_shifts()
				gui_menu_function = gui_fungal_shift 
				end,
		})
	end
	if ModSettingGet("lamas_stats.enable_perks") == true then
		dofile_once("mods/lamas_stats/files/perks.lua")
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
			ui_name = "[" .. _T.KYScat .. "]",
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
	
	GuiColorSetForNextWidget(gui_menu,1,0,0,1)
	if GuiButton(gui_menu, id(), 0, 0, "[" .. _T.KYScat .. "]", 1) then
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
	end
end

local function LamasStatsApplySettings()
	stat_pos_x = ModSettingGet("lamas_stats.overlay_x")
	stat_pos_y = ModSettingGet("lamas_stats.overlay_y")
	PopulateStatsList()
	PopulateButtons()
	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		APLC_table = dofile_once("mods/lamas_stats/files/APLC.lua")
	end
end

function GuiStartFrameWithChecks(gui_frame, gui_function)
	if player then --if player is even alive
		if gui_frame ~= nil then GuiStartFrame(gui_frame) end
		if gui_function ~= nil and GameIsInventoryOpen() == false and lamas_stats_menu_enabled then
			gui_function()
		end
	end
end

--[[		main loop		]]
function lamas_stats_main_loop() 
	--hotkey
	if InputIsKeyJustDown(ModSettingGet("lamas_stats.input_key")) then 
		lamas_stats_menu_enabled = not lamas_stats_menu_enabled
	end
	
	--overlay
	GuiStartFrameWithChecks(gui_top, gui_top_function)

	--menu
	GuiStartFrameWithChecks(gui_menu, gui_menu_function)

	--apply settings
	if ModSettingGet("lamas_stats.setting_changed") then
		LamasStatsApplySettings()
		ModSettingSet("lamas_stats.setting_changed", false)
	end
end

--[[		these are executed once on load		]]
LamasStatsApplySettings()
gui_top_function = gui_top_main_display_loop