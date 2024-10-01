_T = dofile_once("mods/lamas_stats/translations/translation.lua")
empty_png = "data/ui_gfx/empty.png"
fungal_png = "data/ui_gfx/status_indicators/fungal_shift.png"
potion_png = "data/items_gfx/potion.png"
pile_png = "mods/lamas_stats/files/pile.png"
solid_static_png = "mods/lamas_stats/files/solid_static.png"
screen_png = "mods/lamas_stats/files/9piece0_more_transparent.png"
virtual_dir = "mods/lamas_stats/files/virtual/"
active_mods = ModGetActiveModIDs()

function GetDataFromFile(file, pattern)
	local content = ModTextFileGetContent(file)
	local match = content:match(pattern)
	if not match then
		print("Lama's Stats ERROR: Couldn't find a match \"" .. pattern .. "\" in " .. file)
		return nil
	end
	local evalfile = virtual_dir .. "eval.lua"
	ModTextFileSetContent(evalfile, "return " .. match)
	local f, err = loadfile(evalfile)
	if not f then
		print("Lama's Stats ERROR: " .. err)
		return nil
	end
	return f()
end

fungal_cooldown = GetDataFromFile("data/scripts/magic/fungal_shift.lua", "if frame < last_frame %+ (.-) and not debug_no_limits then")
if not fungal_cooldown then
	fungal_cooldown = GetDataFromFile("data/scripts/magic/fungal_shift.lua", "if frame < last_frame %+ (.-) then") or 0
end
maximum_shifts = GetDataFromFile("data/scripts/magic/fungal_shift.lua", "if iter >= (.-) and not debug_no_limits then") or 100

function UpdateCommonVariables()
	worldcomponent = EntityGetFirstComponent(GameGetWorldStateEntity(),"WorldStateComponent") --get component of worldstate
	player = EntityGetWithTag("player_unit")[1]
end

function GetFungalCooldown()
	local last_frame = tonumber(GlobalsGetValue("fungal_shift_last_frame", "-1"))
	if last_frame == -1 then 
		return 0 
	end
	
	if tonumber(GlobalsGetValue("fungal_shift_iteration", "0")) >= maximum_shifts then
		return 0
	end

	local frame = GameGetFrameNum()
	
	seconds = math.floor((fungal_cooldown - (frame - last_frame)) / 60)
	if seconds > 0 then
		return seconds
	else 
		return 0
	end
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