---@diagnostic disable: name-style-check
dofile_once("data/scripts/lib/mod_settings.lua")

local mod_id = "lamas_stats"
local mod_prfx = mod_id .. "."
local T = {}
local D = {}
local current_language_last_frame = nil

local mod_id_hash = 0
for i = 1, #mod_id do
	local char = mod_id:sub(i, i)
	mod_id_hash = mod_id_hash + char:byte() * i
end

local gui_id = mod_id_hash * 1000
local function id()
	gui_id = gui_id + 1
	return gui_id
end

-- ###########################################
-- ############		Helpers		##############
-- ###########################################

local U = {
	whitebox = "data/debug/whitebox.png",
	empty = "data/debug/empty.png",
	offset = 0,
	max_y = 300,
	min_y = 50,
	keycodes = {},
	keycodes_file = "data/scripts/debug/keycodes.lua",
	waiting_for_input = false,
}
do -- helpers
	---@param setting_name setting_id
	---@param value setting_value
	function U.set_setting(setting_name, value)
		ModSettingSet(mod_prfx .. setting_name, value)
		ModSettingSetNextValue(mod_prfx .. setting_name, value, false)
	end

	---@param setting_name setting_id
	---@return setting_value?
	function U.get_setting(setting_name)
		return ModSettingGet(mod_prfx .. setting_name)
	end

	---@param setting_name setting_id
	---@return setting_value?
	function U.get_setting_next(setting_name)
		return ModSettingGetNextValue(mod_prfx .. setting_name)
	end

	---@param array mod_settings_global|mod_settings
	---@param gui? gui
	---@return number
	function U.calculate_elements_offset(array, gui)
		if not gui then
			gui = GuiCreate()
			GuiStartFrame(gui)
		end
		local max_width = 10
		for _, setting in ipairs(array) do
			if setting.category_id then
				local cat_max_width = U.calculate_elements_offset(setting.settings, gui)
				max_width = math.max(max_width, cat_max_width)
			end
			if setting.ui_name then
				local name_length = GuiGetTextDimensions(gui, setting.ui_name)
				max_width = math.max(max_width, name_length)
			end
		end
		GuiDestroy(gui)
		return max_width + 3
	end

	---@param all boolean reset all
	function U.set_default(all)
		for setting, value in pairs(D) do
			if U.get_setting(setting) == nil or all then U.set_setting(setting, value) end
		end
	end

	---gather keycodes from game file
	function U.gather_key_codes()
		U.keycodes = {}
		U.keycodes[0] = GameTextGetTranslatedOrNot("$menuoptions_configurecontrols_action_unbound")
		local keycodes_all = ModTextFileGetContent(U.keycodes_file)
		for line in keycodes_all:gmatch("Key_.-\n") do
			local _, key, code = line:match("(Key_)(.+) = (%d+)")
			U.keycodes[code] = key:upper()
		end
	end

	function U.pending_input()
		for code, _ in pairs(U.keycodes) do
			if InputIsKeyJustDown(code) then return code end
		end
	end

	---Resets settings
	function U.reset_settings()
		local count = ModSettingGetCount()
		local setting_list = {}
		for i = 0, count do
			local setting_id = ModSettingGetAtIndex(i)
			if setting_id and setting_id:find("^lamas_stats%.") then setting_list[#setting_list + 1] = setting_id end
		end
		for i = 1, #setting_list do
			ModSettingRemove(setting_list[i])
		end

		U.set_default(true)
	end
end

-- ###########################################
-- ##########		GUI Helpers		##########
-- ###########################################

local G = {}
do -- gui helpers
	function G.button_options(gui)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.ClickCancelsDoubleClick)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.HandleDoubleClickAsClick)
	end

	---@param gui gui
	---@param hovered boolean
	function G.yellow_if_hovered(gui, hovered)
		if hovered then GuiColorSetForNextWidget(gui, 1, 1, 0.7, 1) end
	end

	---@param gui gui
	---@param x_pos number
	---@param text string
	---@param color? table
	---@return boolean
	---@nodiscard
	function G.button(gui, x_pos, text, color)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, x_pos, 0, "")
		local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
		text = "[" .. text .. "]"
		local width, height = GuiGetTextDimensions(gui, text)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x, y, width, height, 0)
		local clicked, _, hovered = GuiGetPreviousWidgetInfo(gui)
		if color then
			local r, g, b = unpack(color)
			GuiColorSetForNextWidget(gui, r, g, b, 1)
		end
		G.yellow_if_hovered(gui, hovered)
		GuiText(gui, x_pos, 0, text)
		return clicked
	end

	---@param setting_name setting_id
	---@param value setting_value
	---@param default setting_value
	function G.on_clicks(setting_name, value, default)
		if InputIsMouseButtonJustDown(1) then U.set_setting(setting_name, value) end
		if InputIsMouseButtonJustDown(2) then
			GamePlaySound("ui", "ui/button_click", 0, 0)
			U.set_setting(setting_name, default)
		end
	end

	---@param gui gui
	---@param setting_name setting_id
	function G.toggle_checkbox_boolean(gui, setting_name)
		local text = T[setting_name]
		local _, _, _, prev_x, y, prev_w = GuiGetPreviousWidgetInfo(gui)
		local x = prev_x + prev_w + 1
		local value = U.get_setting_next(setting_name)
		local offset_w = GuiGetTextDimensions(gui, text) + 8

		GuiZSetForNextWidget(gui, -1)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x + 2, y, offset_w, 10, 10, U.empty, U.empty) -- hover box
		local _, _, hovered = GuiGetPreviousWidgetInfo(gui)
		G.tooltip(gui, setting_name)

		GuiZSetForNextWidget(gui, 1)
		GuiImageNinePiece(gui, id(), x + 2, y + 2, 6, 6) -- check box

		GuiText(gui, 4, 0, "")
		if value then
			GuiColorSetForNextWidget(gui, 0, 0.8, 0, 1)
			GuiText(gui, 0, 0, "V")
			GuiText(gui, 0, 0, " ")
			G.yellow_if_hovered(gui, hovered)
		else
			GuiColorSetForNextWidget(gui, 0.8, 0, 0, 1)
			GuiText(gui, 0, 0, "X")
			GuiText(gui, 0, 0, " ")
			G.yellow_if_hovered(gui, hovered)
		end
		GuiText(gui, 0, 0, text)
		if hovered then G.on_clicks(setting_name, not value, D[setting_name]) end
	end

	---@param gui gui
	---@param setting mod_setting_number
	---@return number, number
	function G.mod_setting_number(gui, setting)
		GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
		local _, _, _, x_start, y_start = GuiGetPreviousWidgetInfo(gui)
		local w = GuiGetTextDimensions(gui, setting.ui_name)
		local value = tonumber(U.get_setting_next(setting.id)) or setting.value_default
		local multiplier = setting.value_display_multiplier or 1
		local value_new =
			GuiSlider(gui, id(), U.offset - w + 6, 0, "", value, setting.value_min, setting.value_max, setting.value_default, multiplier, " ", 64)
		GuiColorSetForNextWidget(gui, 0.81, 0.81, 0.81, 1)
		local format = setting.format or ""
		GuiText(gui, 3, 0, tostring(math.floor(value * multiplier)) .. format)
		GuiLayoutEnd(gui)
		local _, _, _, x_end, _, t_w = GuiGetPreviousWidgetInfo(gui)
		GuiImageNinePiece(gui, id(), x_start, y_start, x_end - x_start + t_w, 8, 0, U.empty, U.empty)
		G.tooltip(gui, setting.id, setting.scope)
		return value, value_new
	end

	---@param gui gui
	---@param setting_name setting_id
	---@param scope? mod_setting_scopes
	function G.tooltip(gui, setting_name, scope)
		local description = T[setting_name .. "_d"]
		local value = U.get_setting_next(setting_name)
		local value_now = U.get_setting(setting_name)

		if value ~= value_now then
			if scope == MOD_SETTING_SCOPE_RUNTIME_RESTART then
				if description then
					GuiTooltip(gui, description, "$menu_modsettings_changes_restart")
				else
					GuiTooltip(gui, "$menu_modsettings_changes_restart", "")
				end
				return
			elseif scope == MOD_SETTING_SCOPE_NEW_GAME then
				if description then
					GuiTooltip(gui, description, "$menu_modsettings_changes_worldgen")
				else
					GuiTooltip(gui, "$menu_modsettings_changes_worldgen", "")
				end
				return
			end
		end

		if description then GuiTooltip(gui, description, "") end
	end
end
-- ###########################################
-- ########		Settings GUI		##########
-- ###########################################

local S = {}
do -- Settings GUI
	---@param setting mod_setting_number
	---@param gui gui
	function S.mod_setting_number_integer(_, gui, _, _, setting)
		local value, value_new = G.mod_setting_number(gui, setting)
		value_new = math.floor(value_new + 0.5)
		if value ~= value_new then U.set_setting(setting.id, value_new) end
	end

	function S.mod_setting_better_boolean(_, gui, _, _, setting)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
		G.tooltip(gui, setting.id)
		GuiLayoutBeginHorizontal(gui, U.offset, 0, true, 0, 0)
		GuiText(gui, 7, 0, "")
		for _, setting_id in ipairs(setting.checkboxes) do
			G.toggle_checkbox_boolean(gui, setting_id)
		end
		GuiLayoutEnd(gui)
	end

	function S.get_input(_, gui, _, _, setting)
		local current_key = "[" .. U.keycodes[U.get_setting("input_key")] .. "]"
		if U.waiting_for_input then
			current_key = GameTextGetTranslatedOrNot("$menuoptions_configurecontrols_pressakey")
			local new_key = U.pending_input()
			if new_key then
				U.set_setting("input_key", new_key)
				U.waiting_for_input = false
			end
		end

		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)

		GuiLayoutBeginHorizontal(gui, U.offset, 0, true, 0, 0)
		GuiText(gui, 8, 0, "")
		local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui)
		local w, h = GuiGetTextDimensions(gui, current_key)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x, y, w, h, 0)
		local _, _, hovered = GuiGetPreviousWidgetInfo(gui)
		if hovered then
			GuiColorSetForNextWidget(gui, 1, 1, 0.7, 1)
			GuiTooltip(gui, T.Hotkey_d, GameTextGetTranslatedOrNot("$menuoptions_reset_keyboard"))
			if InputIsMouseButtonJustDown(1) then U.waiting_for_input = true end
			if InputIsMouseButtonJustDown(2) then
				GamePlaySound("ui", "ui/button_click", 0, 0)
				U.set_setting("input_key", D.input_key)
				U.waiting_for_input = false
			end
		end
		GuiText(gui, 0, 0, current_key)

		GuiLayoutEnd(gui)
	end

	function S.reset_stuff(_, gui, _, _, setting)
		local fn = U[setting.id]
		if not fn then
			GuiText(gui, mod_setting_group_x_offset, 0, "ERR")
			return
		end
		if G.button(gui, mod_setting_group_x_offset, T.reset, { 1, 0.4, 0.4 }) then fn() end
	end
end

-- ###########################################
-- ########		Translations		##########
-- ###########################################

local translations = {
	["English"] = {
		Hotkey = "Hotkey",
		Hotkey_d = "Hotkey to enable overlay",
		overlay_enabled = "Overlay",
		overlay_enabled_d = "Should the overlay be enabled on spawn",
		menu_enabled = "Menu",
		menu_enabled_d = "Open menu by default",
		StartEnabled = "Start enabled",
		overlay_x = "Overlay X position",
		overlay_y = "Overlay Y position",
		max_height = "Maximum height",
		reset_settings = "Reset settings",
		reset = "Reset",
	},
	["русский"] = {
		Hotkey = "Горячая клавиша",
		Hotkey_d = "Горячая клавиша для включения оверлея",
		overlay_enabled = "Оверлей",
		overlay_enabled_d = "Настройки оверлея",
		menu_enabled = "Меню",
		menu_enabled_d = "Открывать меню по умолчанию",
		StartEnabled = "Включать при старте",
		overlay_x = "Позиция X оверлея",
		overlay_y = "Позиция Y оверлея",
		max_height = "Макс высота",
		reset_settings = "Сбросить настройки",
		reset = "Сбросить",
	},
	["日本語"] = {
		Hotkey = "ホットキー",
		Hotkey_d = "オーバーレイを有効にするホットキー",
		overlay_enabled = "オーバーレイ",
		overlay_enabled_d = "オーバーレイ設定",
		menu_enabled = "メニュー",
		menu_enabled_d = "デフォルトでメニューを開く",
		StartEnabled = "起動時に有効化",
		overlay_x = "オーバーレイのX位置",
		overlay_y = "オーバーレイのY位置",
		max_height = "最高高さ",
		reset_settings = "設定をリセット",
		reset = "リセット",
	},
}

local mt = {
	__index = function(t, k)
		local currentLang = GameTextGetTranslatedOrNot("$current_language")
		if currentLang == "русский(Neonomi)" or currentLang == "русский(Сообщество)" then -- compatibility with custom langs
			currentLang = "русский"
		end
		if currentLang == "自然な日本語" then currentLang = "日本語" end
		if not translations[currentLang] then currentLang = "English" end
		return translations[currentLang][k]
	end,
}
setmetatable(T, mt)

-- ###########################################
-- #########		Settings		##########
-- ###########################################

D = {
	input_key = "60",
	overlay_enabled = true,
	menu_enabled = false,
	overlay_x = 13,
	overlay_y = 8,
	max_height = 180,
	show_fungal_menu = true,
	show_perks_menu = true,
	show_kys_menu = false,
	enable_fungal_past = true,
	enable_fungal_future = false,
	stats_enable = true,
	stats_showtime = true,
	stats_showkills = true,
	stats_show_player_pos = false,
	stats_position_expanded = true,
	stats_show_player_biome = false,
	stats_show_fungal_cooldown = true,
	stats_fps = false,
	stats_show_speed = false,
	enable_nearby_perks = true,
	enable_nearby_lottery = true,
	enable_nearby_always_cast = true,
}

local function build_settings()
	---@type mod_settings_global
	local settings = {
		{
			id = "input_key",
			not_setting = true,
			ui_name = T.Hotkey,
			ui_description = T.HotkeyDesc,
			value_default = D.input_key,
			ui_fn = S.get_input,
		},
		{
			not_setting = true,
			id = "enable_at_start",
			ui_fn = S.mod_setting_better_boolean,
			ui_name = T.StartEnabled,
			checkboxes = { "overlay_enabled", "menu_enabled" },
		},
		{
			id = "overlay_x",
			ui_name = T.overlay_x,
			value_default = D.overlay_x,
			value_min = 0,
			value_max = 640,
			ui_fn = S.mod_setting_number_integer,
		},
		{
			id = "overlay_y",
			ui_name = T.overlay_y,
			ui_description = T.overlay_y_desc,
			value_default = D.overlay_y,
			value_min = 0,
			value_max = 360,
			ui_fn = S.mod_setting_number_integer,
		},
		{
			id = "max_height",
			ui_name = T.max_height,
			value_default = D.max_height,
			value_min = 50,
			value_max = 250,
			ui_fn = S.mod_setting_number_integer,
		},
		{
			category_id = "reset_settings_cat",
			ui_name = T.reset_settings,
			foldable = true,
			_folded = true,

			settings = {
				{
					id = "reset_settings",
					not_setting = true,
					ui_name = T.ResetSettings,
					ui_fn = S.reset_stuff,
				},
			},
		},
	}
	U.offset = U.calculate_elements_offset(settings)
	return settings
end

-- ###########################################
-- #############		Meh		##############
-- ###########################################

---@param init_scope number
function ModSettingsUpdate(init_scope)
	if U.get_setting("overlay_enabled") == nil then U.reset_settings() end
	U.set_default(false)
	U.waiting_for_input = false
	local current_language = GameTextGetTranslatedOrNot("$current_language")
	if current_language ~= current_language_last_frame then mod_settings = build_settings() end
	current_language_last_frame = current_language
end

---@return number
function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

---@param gui gui
---@param in_main_menu boolean
function ModSettingsGui(gui, in_main_menu)
	GuiIdPushString(gui, mod_prfx)
	gui_id = mod_id_hash * 1000
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
	GuiIdPop(gui)
end

U.gather_key_codes()

---@type mod_settings_global
mod_settings = build_settings()
