dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("mods/lamas_stats/files/common.lua")
dofile_once("mods/lamas_stats/translations/translation.lua")

gui_top_frame = nil
gui_top = GuiCreate()

stat_pos_x = ModSettingGet("lamas_stats.overlay_x")
stat_pos_y = ModSettingGet("lamas_stats.overlay_y")

if ModSettingGet("lamas_stats.enable_fungal_recipes") then
	APLC_table = dofile_once("mods/lamas_stats/files/APLC.lua")
end

menu_pos_x = 2
menu_pos_y = 12
local lamas_stats_main_menu_buttons = {}
local lamas_stats_main_menu_list = {}
local top_text = "[L]"

menu_opened = false

function gui_do_return_button(scale, menu)
	scale = scale or 1
	menu = menu or gui_main
	if GuiButton(gui, 99999, 0, 0, "[" .. _T.lamas_stat_return .. "]", scale) then
		gui_menu = menu
	end
end

function gui_do_refresh_button(scale, action)
	if GuiButton(gui, 999, 0, 0, "[" .. GameTextGetTranslatedOrNot("$menu_mods_refresh") .. "]", scale) then --refresh
		action()
		GamePrint(_T.lamas_stat_refresh_text)
	end
end

function gui_top_main()
	GuiZSet(gui,800)
	GuiLayoutBeginHorizontal(gui_top, stat_pos_x, stat_pos_y, false, 0, 0)

	if GuiButton(gui_top, 101, 0, 0, top_text) then
		ToggleMenu()
	end
	GuiLayoutEnd(gui_top)
	if ModSettingGet("lamas_stats.stats_position") == "on top" then
		local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui_top)
		GUI_Stats(gui_top, x+20, y)
	end
end

function GUI_Stats(gui, x, y)
	for i,stat in ipairs(lamas_stats_main_menu_list) do
		stat(i, gui, x, y)
	end
end

function ToggleMenu()
	if menu_opened then
		GuiDestroy(gui)
		gui_menu = nil
		gui = nil
		top_text = "[L]"
		menu_opened = false
	else
		menu_opened = true
		gui = GuiCreate()
		gui_menu = gui_main
		top_text = "[*]"
	end
end

function gui_main()
	GuiLayoutBeginVertical(gui, menu_pos_x, menu_pos_y) --layer1
	GuiZSet(gui,800)
	GuiText(gui, 0, 0, ModSettingGet("lamas_stats.lamas_menu_header"))

	if ModSettingGet("lamas_stats.stats_position") == "merged" then
		GuiText(gui,0,0," ")
		local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui)
		
		GuiLayoutBeginLayer(gui)
		GUI_Stats(gui, x, y)
		
		GuiLayoutEndLayer(gui) 
	end
	
	local hax_btn_id = 123
	for i,it in ipairs(lamas_stats_main_menu_buttons) do
		GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
		if GuiButton(gui, hax_btn_id, 0, 0, it.ui_name) then
			it.action()
		end
		hax_btn_id = hax_btn_id + 1
		GuiLayoutEnd(gui)
	end
	
	GuiLayoutEnd(gui) --layer1
end



local function PopulateButtons()
	if ModSettingGet("lamas_stats.enable_fungal") == true then
		dofile_once("mods/lamas_stats/files/fungal.lua")
		table.insert(lamas_stats_main_menu_buttons,
		{
			ui_name = "[" .. _T.FungalShifts .. "]",
			action = function() 
				gui_fungal_shift_get_shifts()
				gui_menu = gui_fungal_shift 
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
				gui_menu = gui_perks_main
				end,
		})
	end
end

local function PopulateMenuText()
	
	if ModSettingGet("lamas_stats.stats_enable") then
		dofile_once("mods/lamas_stats/files/stats.lua")
		table.insert(lamas_stats_main_menu_list,ShowStart)
			
		if ModSettingGet("lamas_stats.stats_showtime") then table.insert(lamas_stats_main_menu_list,ShowTime) end
		if ModSettingGet("lamas_stats.stats_showkills") then table.insert(lamas_stats_main_menu_list,ShowKill) end
		
		if ModSettingGet("lamas_stats.stats_show_fungal_cooldown") then 
			if ModSettingGet("lamas_stats.stats_show_fungal_order") == "first" then table.insert(lamas_stats_main_menu_list,2,ShowFungal) 
			else table.insert(lamas_stats_main_menu_list,ShowFungal) end
		end	
		
		if ModSettingGet("lamas_stats.stats_show_player_pos") then table.insert(lamas_stats_main_menu_list, ShowPlayerPos) end
		
		if ModSettingGet("lamas_stats.stats_show_player_biome") then table.insert(lamas_stats_main_menu_list, ShowPlayerBiome) end
		
		table.insert(lamas_stats_main_menu_list,ShowEnd)
	end
end

local function LamasStatsPopulateMenu()
	PopulateMenuText()
	PopulateButtons()
end

function get_player()
  return (EntityGetWithTag( "player_unit" ) or {})[1]
end

function get_player_pos()
  local player = get_player()
  if not player then return 0, 0 end
  return EntityGetTransform(player)
end

LamasStatsPopulateMenu()
gui_top_frame = gui_top_main

if ModSettingGet("lamas_stats.lamas_menu_enabled_default") == true then
	ToggleMenu()
end

async_loop(function()
	--overlay
	if player then --if player is even alive
		if gui_top ~= nil then
			GuiStartFrame(gui_top)
		end
		if gui_top_frame ~= nil and GameIsInventoryOpen() == false then
			gui_top_frame()
		end

		--menu
		if gui ~= nil then
			GuiStartFrame(gui)
		end
		if gui_menu ~= nil and GameIsInventoryOpen() == false then
			gui_menu()
		end
	end
	wait(0)
end)
