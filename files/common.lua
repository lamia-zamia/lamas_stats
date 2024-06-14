empty_png = "data/ui_gfx/empty.png"
fungal_png = "data/ui_gfx/status_indicators/fungal_shift.png"
potion_png = "data/items_gfx/potion.png"
screen_png = "mods/lamas_stats/files/9piece0_more_transparent.png"
player = EntityGetWithTag("player_unit")[1]

current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
maximum_shifts = ModSettingGet("lamas_stats.fungal_shift_max")
if ModIsEnabled("Apotheosis") then --aphotheosis
	maximum_shifts = maximum_shifts + 1
end

worldcomponent = EntityGetFirstComponent(GameGetWorldStateEntity(),"WorldStateComponent") --get component of worldstate

function ShowFungalCooldown()
    local last_frame = tonumber(GlobalsGetValue("fungal_shift_last_frame", "-1"))
    if last_frame == -1 then 
		return 0 
	end
	
	if tonumber(GlobalsGetValue("fungal_shift_iteration", "0")) >= maximum_shifts then
		return 0
	end

    local frame = GameGetFrameNum()
	
	seconds = math.floor((60*60*5 - (frame - last_frame)) / 60)
	if seconds > 0 then
		return seconds
	else 
		return 0
	end
end

function GuiTooltipLamas(gui, x, y, z, action)
	local _,_,gui_hovered,gui_x,gui_y = GuiGetPreviousWidgetInfo(gui)
	if gui_hovered then --immitating tooltip
		GuiZSet(gui,-100)
		GuiAnimateBegin(gui)
		GuiAnimateScaleIn(gui, 555, 0.1, false)
		GuiLayoutBeginLayer(gui)
		GuiBeginAutoBox(gui)
		
		GuiLayoutBeginVertical(gui, gui_x + x, gui_y + y, true)
		
		action(gui)
		
		GuiLayoutEnd(gui)
		
		GuiZSetForNextWidget(gui, -99)
		GuiEndAutoBoxNinePiece(gui)
		GuiLayoutEndLayer(gui) 
		GuiAnimateEnd(gui)
		GuiZSet(gui, z)
	end
end

function gui_menu_switch_button(gui, id, scale, menu) --gui frame, scale, loop function to display
	if GuiButton(gui, id, 0, 0, "[" .. _T.lamas_stat_return .. "]", scale) then
		gui_menu_function = menu
	end
end

function gui_do_refresh_button(gui, id, scale, action) 
	if GuiButton(gui, id, 0, 0, "[" .. GameTextGetTranslatedOrNot("$menu_mods_refresh") .. "]", scale) then --refresh
		action()
		GamePrint(_T.lamas_stat_refresh_text)
	end
end

function get_player_pos()
	if not player then return 0, 0 end
	return EntityGetTransform(player)
end