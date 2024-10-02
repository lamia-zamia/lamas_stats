_T = dofile_once("mods/lamas_stats/translations/translation.lua")
potion_png = "data/items_gfx/potion.png"
pile_png = "mods/lamas_stats/files/pile.png"
solid_static_png = "mods/lamas_stats/files/solid_static.png"
virtual_dir = "mods/lamas_stats/files/virtual/"

function UpdateCommonVariables()
	worldcomponent = EntityGetFirstComponent(GameGetWorldStateEntity(),"WorldStateComponent") --get component of worldstate
end

function GuiTextGray(gui, x, y, text, scale)
	GuiColorSetForNextWidget(gui, 0.7, 0.7, 0.7, 1)
	GuiText(gui, x, y, text, scale)
end

function GuiTextRed(gui, x, y, text, scale)
	GuiColorSetForNextWidget(gui, 1, 0.2, 0, 1)
	GuiText(gui, x, y, text, scale)
end

local gui_tooltip_size_cache = setmetatable({}, { __mode = "k" })

local function ReturnZeroOrMinus(value)
	if value <= 10 then return value - 10
	else return 0 end
end

local function GuiTooltipLamasValidateTooltipCache(x, y, z, action, passable_table, key)
	if not gui_tooltip_size_cache[key] then
		local phantom_gui = GuiCreate()
		local offscreen_offset = 1000
		GuiStartFrame(phantom_gui)
		GuiLayoutBeginVertical(phantom_gui, x + offscreen_offset, y + offscreen_offset, true)
		action(phantom_gui, passable_table)
		GuiLayoutEnd(phantom_gui)
		local screen_w,screen_h = GuiGetScreenDimensions(phantom_gui)
		local _,_,_,x,y,w,h = GuiGetPreviousWidgetInfo(phantom_gui)
		GuiDestroy(phantom_gui)
		gui_tooltip_size_cache[key] = {x = ReturnZeroOrMinus(screen_w - x - w + offscreen_offset), y = ReturnZeroOrMinus(screen_h - y - h + offscreen_offset)}
	end
end

function GuiTooltipLamas(gui, x, y, z, action, passable_table)
	local _,_,gui_hovered,gui_x,gui_y,gui_w,gui_h = GuiGetPreviousWidgetInfo(gui)
	if gui_hovered then --immitating tooltip
		local key = tostring(action) .. tostring(passable_table)
		GuiTooltipLamasValidateTooltipCache(gui_x + gui_w + x + 10, gui_y + (gui_h/2) + y, z, action, passable_table, key)
		GuiZSet(gui,-100)
		GuiAnimateBegin(gui)
		GuiAnimateScaleIn(gui, 555, 0.1, false)
		
		GuiLayoutBeginLayer(gui)
		GuiBeginAutoBox(gui)
		
		GuiLayoutBeginVertical(gui, gui_x + gui_w + x + 10, gui_y + (gui_h/2) + y + gui_tooltip_size_cache[key].y, true)
		action(gui, passable_table)
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