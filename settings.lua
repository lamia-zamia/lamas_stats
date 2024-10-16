--- @diagnostic disable: name-style-check
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
	--- @param setting_name setting_id
	--- @param value setting_value
	function U.set_setting(setting_name, value)
		ModSettingSet(mod_prfx .. setting_name, value)
		ModSettingSetNextValue(mod_prfx .. setting_name, value, false)
	end

	--- @param setting_name setting_id
	--- @return setting_value?
	function U.get_setting(setting_name)
		return ModSettingGet(mod_prfx .. setting_name)
	end

	--- @param setting_name setting_id
	--- @return setting_value?
	function U.get_setting_next(setting_name)
		return ModSettingGetNextValue(mod_prfx .. setting_name)
	end

	--- @param array mod_settings_global|mod_settings
	--- @param gui? gui
	--- @return number
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

	--- @param all boolean reset all
	function U.set_default(all)
		for setting, value in pairs(D) do
			if U.get_setting(setting) == nil or all then
				U.set_setting(setting, value)
			end
		end
	end

	--- gather keycodes from game file
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
			if InputIsKeyJustDown(code) then
				return code
			end
		end
	end

	--- Resets settings
	function U.reset_settings()
		U.set_default(true)
	end
end

-- ###########################################
-- ##########		GUI Helpers		##########
-- ###########################################

local G = {

}
do -- gui helpers
	function G.button_options(gui)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.ClickCancelsDoubleClick)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.HandleDoubleClickAsClick)
	end

	--- @param gui gui
	--- @param hovered boolean
	function G.yellow_if_hovered(gui, hovered)
		if hovered then GuiColorSetForNextWidget(gui, 1, 1, 0.7, 1) end
	end

	--- @param gui gui
	--- @param x_pos number
	--- @param text string
	--- @param color? table
	--- @return boolean
	--- @nodiscard
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

	--- @param setting_name setting_id
	--- @param value setting_value
	--- @param default setting_value
	function G.on_clicks(setting_name, value, default)
		if InputIsMouseButtonJustDown(1) then
			U.set_setting(setting_name, value)
		end
		if InputIsMouseButtonJustDown(2) then
			GamePlaySound("ui", "ui/button_click", 0, 0)
			U.set_setting(setting_name, default)
		end
	end

	--- @param gui gui
	--- @param setting_name setting_id
	function G.toggle_checkbox_boolean(gui, setting_name)
		local text = T[setting_name]
		local _, _, _, prev_x, y, prev_w = GuiGetPreviousWidgetInfo(gui)
		local x = prev_x + prev_w + 1
		local value = U.get_setting_next(setting_name)
		local offset_w = GuiGetTextDimensions(gui, text) + 8

		GuiZSetForNextWidget(gui, -1)
		G.button_options(gui)
		GuiImageNinePiece(gui, id(), x + 2, y, offset_w, 10, 10, U.empty, U.empty) -- hover box
		G.tooltip(gui, setting_name)
		local _, _, hovered = GuiGetPreviousWidgetInfo(gui)
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
		if hovered then
			G.on_clicks(setting_name, not value, D[setting_name])
		end
	end

	--- @param gui gui
	--- @param setting mod_setting_number
	--- @return number, number
	function G.mod_setting_number(gui, setting)
		GuiLayoutBeginHorizontal(gui, 0, 0, true, 0, 0)
		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
		local _, _, _, x_start, y_start = GuiGetPreviousWidgetInfo(gui)
		local w = GuiGetTextDimensions(gui, setting.ui_name)
		local value = tonumber(U.get_setting_next(setting.id)) or setting.value_default
		local multiplier = setting.value_display_multiplier or 1
		local value_new = GuiSlider(gui, id(), U.offset - w + 6, 0, "", value, setting
			.value_min,
			setting.value_max, setting.value_default, multiplier, " ", 64)
		GuiColorSetForNextWidget(gui, 0.81, 0.81, 0.81, 1)
		local format = setting.format or ""
		GuiText(gui, 3, 0, tostring(math.floor(value * multiplier)) .. format)
		GuiLayoutEnd(gui)
		local _, _, _, x_end, _, t_w = GuiGetPreviousWidgetInfo(gui)
		GuiImageNinePiece(gui, id(), x_start, y_start, x_end - x_start + t_w, 8, 0, U.empty, U.empty)
		G.tooltip(gui, setting.id, setting.scope)
		return value, value_new
	end

	--- @param gui gui
	--- @param setting_name setting_id
	--- @param scope? mod_setting_scopes
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

		if description then
			GuiTooltip(gui, description, "")
		end
	end
end
-- ###########################################
-- ########		Settings GUI		##########
-- ###########################################

local S = {

}
do -- Settings GUI
	--- @param setting mod_setting_number
	--- @param gui gui
	function S.mod_setting_number_integer(_, gui, _, _, setting)
		local value, value_new = G.mod_setting_number(gui, setting)
		value_new = math.floor(value_new + 0.5)
		if value ~= value_new then
			U.set_setting(setting.id, value_new)
		end
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
			if InputIsMouseButtonJustDown(1) then
				U.waiting_for_input = true
			end
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
		if G.button(gui, mod_setting_group_x_offset, T.reset, { 1, 0.4, 0.4 }) then
			fn()
		end
	end
end

-- ###########################################
-- ########		Translations		##########
-- ###########################################

local translations =
{
	["English"] = {
		Hotkey = "Hotkey",
		Hotkey_d = "Hotkey to enable overlay",
		overlay_enabled = "Overlay",
		overlay_enabled_d = "Should the overlay be enabled on spawn",
		menu_enabled = "Menu",
		menu_enabled_d = "Open menu by default",
		Overlay = "Overlay",
		OverlayDesc = "Overlay settings",
		StartEnabled = "Start enabled",
		overlay_x = "Overlay X position",
		overlay_y = "Overlay Y position",
		overlay_y_desc = "Why though?",
		Stats = "Stats",
		StatsDesc = "Settings for stats",
		StatsEnable = "Enable stats module",
		StatsPosition = "Stats position",
		StatsInMenu = "In menu",
		StatsOnOverlay = "On overlay",
		StatsShowTime = "Show playtime",
		StatsShowTimeDesc = "Also shows different session stats on hover",
		StatsShowKills = "Show kills",
		StatsShowKillsInnocent = "Show helpless kills",
		StatsShowKillsInnocentDesc = "Hover mouse over kills to show",
		StatsShowFungalCat = "Fungal shift cooldown",
		StatsShowFungalCooldown = "Show fungal shift cooldown",
		StatsShowFungalOrder = "Place in stats for cooldown",
		StatsShowFungalOrderFirst = "First in stats",
		StatsShowFungalOrderLast = "Last in stats",
		StatsShowFungalType = "Display type",
		StatsShowFungalTypeTime = "Show cooldown time",
		StatsShowFungalTypeImage = "Show image and cooldown time on hover",
		StatsShowCustomCat = "Custom stats",
		StatsShowCustomCatDesc = "These will most likely only work in new saves",
		stats_show_farthest_pw = "Remember farthest parallel worlds",
		stats_show_farthest_pwDesc = "Shows how far you've gone to east/west",
		FungalShifts = "Fungal Shifts",
		FungalShiftsDesc = "Settings for fungal shift list",
		EnableFungalModule = "Enable fungal module",
		FungalGroupType = "Shift group style",
		FungalGroupTypeTrue = "Hidden, show on hover",
		FungalGroupTypeFalse = "Show full group",
		FungalGroupTypeDesc = "I recommend hidden style, you can just hower over unknown groups",
		FungalScale = "Fungal shift window scale",
		FungalShiftMax = "Maximum fungal shifts per page",
		FungalShiftMaxDesc = "How many shifts to show per page",
		EnableFungalGreedyTip = "Show greedy shift reminder",
		EnableFungalGreedyTipDesc = "Add text about shifting into gold or divine ground",
		EnableFungalGreedyGold = "Show greedy gold shift",
		EnableFungalGreedyGrass = "Show greedy grass shift",
		GreedyShiftReminder = "read me, it's about greedy shift",
		GreedyShiftReminderDesc =
		"If the shift is going to be successful - \nthe result shift will be coloured purple regardless of other settings.\nIf it's not purple - it's not going to be transformed into gold.",
		LamasMenuSetting = "Menu",
		LamasMenuName = "Menu's header",
		LamasMenuSettingDesc = "Settings for menu that called by pressing main button",
		Perks = "Perks",
		PerksDesc = "Info about perks, predicting perks in HM and rerolls",
		EnablePerks = "Enable perks",
		EnablePerksDesc = "Enable perks module",
		current_perks_cat = "Current perks",
		EnableCurrentPerks = "Show current",
		EnableCurrentPerksDesc = "Shows current perks better than the game",
		current_perks_percentage = "Current max width",
		current_perks_percentageDesc = "How many percent of the screen width to move to a new line after",
		current_perks_scale = "Current scale",
		current_perks_scaleDesc = "You can make current perks smaller",
		current_perks_hide_vanilla = "Hide vanilla's perk HUD",
		EnablefuturePerks = "Predict future",
		EnablefuturePerksDesc =
		"Shows perks that's going to spawn in the next holy mountain.\nPerks spawn on first visit, \nif you skip holy mountain the next mountain will spawn the perks in list.\nAlso predicts rerolls",
		enable_nearby_perks = "Show nearby perks",
		enable_nearby_perksDesc = "To show nearby perks in perks window",
		enable_nearby_lottery = "Show lottery icon",
		enable_nearby_lotteryDesc = "Add lottery icon to perks that you can grab for free",
		nearby_perks_cat = "Nearby perks",
		nearby_predict_cat = "Predict perks",
		future_perks_amount = "How many mountains",
		future_perks_amountDesc = "How far to calculate future perks",
		enable_nearby_alwayscast = "Predict always cast",
		enable_nearby_alwayscastDesc = "Will show you which cast you will get on hover",
		EnablePerksAutoUpdate = "Enable auto-update",
		EnablePerksAutoUpdateDesc = "Update perk list periodically",
		enable_fungal_recipes = "Enable AP/LC recipes",
		enable_fungal_recipesDesc = "Show AP/LC recipes in fungal GUI",
		stats_show_player_pos = "Show player position",
		stats_show_player_posDesc = "Toggleable by clicking on position",
		stats_show_player_pos_pw = "Show PW number",
		stats_show_player_pos_pwDesc = "Show how far you are into PW on hover on position",
		stats_show_player_biome = "Show location",
		stats_show_player_biomeDesc = "Show biome name",
		reset_settings = "Reset settings",
		reset = "Reset",
		KYScat = "Kill yourself",
		KYScatDesc = "Category for suicide, in case you are too far into godrun",
		KYS_Button = "Enable suicide button",
		KYS_ButtonDesc = "To show suicide button or no",
		KYS_Button_Hide = "Hide button after use",
		KYS_Button_HideDesc = "Will set setting above to off after use",
	},
	["русский"] = {
		Hotkey = "Горячая клавиша",
		HotkeyDesc = "Горячая клавиша для включения оверлея",
		Overlay = "Оверлей",
		OverlayDesc = "Настройки оверлея",
		StartEnabled = "Включать при старте",
		StartEnabledDesc = "Должен ли оверлей быть включен при старте",
		overlay_x = "Позиция X оверлея",
		overlay_y = "Позиция Y оверлея",
		overlay_y_desc = "Зочем",
		Stats = "Статистика",
		StatsDesc = "Настройки статистики",
		StatsEnable = "Включить модуль статистики",
		StatsPosition = "Позиция статистики",
		StatsInMenu = "В меню",
		StatsOnOverlay = "На оверлее",
		StatsShowTime = "Показывать время игры",
		StatsShowTimeDesc = "Так же при наведении мышки показывает разные показатели сессии",
		StatsShowKills = "Показывать убийства",
		StatsShowKillsInnocent = "Показывать убийства беспомощных",
		StatsShowKillsInnocentDesc = "Показывает при наведении курсора на убийства",
		StatsShowFungalCat = "Откат грибного сдвига",
		StatsShowFungalCooldown = "Показывать откат грибного сдвига",
		StatsShowFungalOrder = "Место для показа отката",
		StatsShowFungalOrderFirst = "В начале списка",
		StatsShowFungalOrderLast = "В конце списка",
		StatsShowFungalType = "Режим показа",
		StatsShowFungalTypeTime = "Показывать время",
		StatsShowFungalTypeImage = "Показывать иконку и время при наведении",
		StatsShowCustomCat = "Кастомные статы",
		StatsShowCustomCatDesc = "Скорее всего будут работать только на новых сейвах",
		stats_show_farthest_pw = "Запоминать самые дальние миры",
		stats_show_farthest_pwDesc = "Показывает как делеко вы зашли в параллельный мир",
		FungalShifts = "Грибные сдвиги",
		FungalShiftsDesc = "Настройки для списка fungal shift",
		EnableFungalModule = "Включить модуль грибов",
		FungalGroupType = "Стиль групповых сдвигов",
		FungalGroupTypeTrue = "Спрятаны, показать при наведении",
		FungalGroupTypeFalse = "Показать всю группу",
		FungalGroupTypeDesc = "Рекомендую спрятанный стиль, можно навести мышкой чтобы уточнить детали",
		FungalScale = "Масштаб окна грибных сдвигов",
		FungalShiftMax = "Максимальное кол-во сдвигов на странице",
		FungalShiftMaxDesc = "Сколько сдвигов показывать на одной странице",
		EnableFungalGreedyTip = "Показывать напоминание о жадном сдвиге",
		EnableFungalGreedyTipDesc = "Добавляет текст о сдвиге в золото или божественные земли",
		EnableFungalGreedyGold = "Показывать результаты сдвига в золото",
		EnableFungalGreedyGrass = "Показывать результаты сдвига бож.травы",
		GreedyShiftReminder = "прочитай меня, это про жадные сдвиги",
		GreedyShiftReminderDesc =
		"Если сдвиг будет успешный - \nитоговый сдвиг будет окрашен в фиолетовый вне зависимости от настроек.\nЕсли оно не фиолетовое - попытка превратить в золото будет неуспешной",
		LamasMenuSetting = "Меню",
		LamasMenuName = "Заголовок меню",
		LamasMenuSettingDesc = "Настройки меню, вызываемый нажатием главной кнопки",
		LamasMenuEnabledByDefault = "Открывать меню по умолчанию",
		Perks = "Перки",
		PerksDesc = "Информация о перках, предсказании перков в горе и рероллов",
		EnablePerks = "Включить перки",
		EnablePerksDesc = "Включить модуль перков",
		current_perks_cat = "Текущие перки",
		EnableCurrentPerks = "Показывать текущие",
		EnableCurrentPerksDesc = "Показывает текущие перки лучше, чем игра",
		current_perks_percentage = "Максимальная ширина",
		current_perks_percentageDesc = "После скольки процентов от ширины экрана переходить на новую строку",
		current_perks_scale = "Масштаб текущих",
		current_perks_scaleDesc = "Можно сделать текущие перки меньше",
		current_perks_hide_vanilla = "Не показывать иконки перков ваниллы",
		EnablefuturePerks = "Рассчитать будущие",
		EnablefuturePerksDesc =
		"Показывает перки, которые будут заспавлены в будущей горе.\nПерки спавнятся при первом визите, даже если пропустить гору и пойти в следующий\n - заспавнится то, что в списке.\nТак же предсказывает рероллы",
		enable_nearby_perks = "Показывать перки рядом",
		enable_nearby_perksDesc = "Показывать перки рядом в интерфейсе перков",
		enable_nearby_lottery = "Показывать лотерею",
		enable_nearby_lotteryDesc = "Добавляет иконку лотереи к перкам, которые можно взять бесплатно",
		nearby_perks_cat = "Перки рядом",
		nearby_predict_cat = "Будущие перки",
		future_perks_amount = "Сколько гор",
		future_perks_amountDesc = "Как далеко заглядывать в будущее",
		enable_nearby_alwayscast = "Предсказать постоянное заклинание",
		enable_nearby_alwayscastDesc = "При наведении мыши будет показывать какое заклинание получит посох",
		EnablePerksAutoUpdate = "Включить автообновление",
		EnablePerksAutoUpdateDesc = "Периодически обновляет список перков",
		enable_fungal_recipes = "Считать рецепт AP/LC",
		enable_fungal_recipesDesc = "Показывает рецепт AP/LC в интерфейсе грибных сдвигов",
		stats_show_player_pos = "Показывать позицию игрока",
		stats_show_player_posDesc = "Включается нажатием на текст",
		stats_show_player_pos_pw = "Показывать номер ПМ",
		stats_show_player_pos_pwDesc = "Показывать как далеко игрок в ПМ при наведении мыши на позицию",
		stats_show_player_biome = "Показывать локацию",
		stats_show_player_biomeDesc = "Показывает название биома",
		ResetSettings = "Сбросить настройки",
		KYScat = "Убить себя",
		KYScatDesc = "Категория для суицида на случай, если вы слишком неубиваемы",
		KYS_Button = "Включить кнопку суицида",
		KYS_ButtonDesc = "Показывать кнопку суицида или нет",
		KYS_Button_Hide = "Прятать кнопку после использования",
		KYS_Button_HideDesc = "Выставит настройку выше на отключено после использования",
	},
	["日本語"] = {
		Hotkey = "ホットキー",
		HotkeyDesc = "オーバーレイを有効にするホットキー",
		Overlay = "オーバーレイ",
		OverlayDesc = "オーバーレイ設定",
		StartEnabled = "起動時に有効化",
		StartEnabledDesc = "スポーン時にオーバーレイを有効にしますか",
		overlay_x = "オーバーレイのX位置",
		overlay_y = "オーバーレイのY位置",
		overlay_y_desc = "なぜ？",
		Stats = "統計",
		StatsDesc = "統計の設定",
		StatsEnable = "統計モジュールを有効にする",
		StatsPosition = "統計の位置",
		StatsInMenu = "メニュー内",
		StatsOnOverlay = "オーバーレイ上",
		StatsShowTime = "プレイ時間を表示",
		StatsShowTimeDesc = "ホバーで異なるセッションの統計も表示",
		StatsShowKills = "キル数を表示",
		StatsShowKillsInnocent = "無力なキルを表示",
		StatsShowKillsInnocentDesc = "キル数にマウスをホバーすると表示",
		StatsShowFungalCat = "キノコシフトのクールダウン",
		StatsShowFungalCooldown = "キノコシフトのクールダウンを表示",
		StatsShowFungalOrder = "クールダウンの統計内配置",
		StatsShowFungalOrderFirst = "統計内の最初",
		StatsShowFungalOrderLast = "統計内の最後",
		StatsShowFungalType = "表示タイプ",
		StatsShowFungalTypeTime = "クールダウン時間を表示",
		StatsShowFungalTypeImage = "画像とクールダウン時間をホバーで表示",
		StatsShowCustomCat = "カスタム統計",
		StatsShowCustomCatDesc = "これらは新しいセーブでのみ動作する可能性があります",
		stats_show_farthest_pw = "最遠のパラレルワールドを記憶する",
		stats_show_farthest_pwDesc = "どれだけ東/西に行ったかを表示",
		FungalShifts = "キノコシフト",
		FungalShiftsDesc = "キノコシフトリストの設定",
		EnableFungalModule = "キノコモジュールを有効にする",
		FungalGroupType = "シフトグループスタイル",
		FungalGroupTypeTrue = "隠してホバーで表示",
		FungalGroupTypeFalse = "完全なグループを表示",
		FungalGroupTypeDesc = "隠しスタイルをお勧めします、不明なグループにホバーできます",
		FungalScale = "キノコシフトウィンドウのスケール",
		FungalShiftMax = "1ページに表示する最大キノコシフト数",
		FungalShiftMaxDesc = "1ページに表示するシフトの数",
		EnableFungalGreedyTip = "貪欲なシフトのリマインダーを表示",
		EnableFungalGreedyTipDesc = "金や神聖な地面へのシフトに関するテキストを追加",
		EnableFungalGreedyGold = "貪欲な金のシフトを表示",
		EnableFungalGreedyGrass = "貪欲な草のシフトを表示",
		GreedyShiftReminder = "貪欲なシフトについての読み物",
		GreedyShiftReminderDesc = "シフトが成功する場合、結果シフトは他の設定に関係なく紫色になります。\n紫色でない場合、それは金に変換されません。",
		LamasMenuSetting = "メニュー",
		LamasMenuName = "メニューのヘッダー",
		LamasMenuSettingDesc = "メインボタンを押して呼び出されるメニューの設定",
		LamasMenuEnabledByDefault = "デフォルトでメニューを開く",
		Perks = "パーク",
		PerksDesc = "パークに関する情報、HMでのパーク予測とリロール",
		EnablePerks = "パークを有効にする",
		EnablePerksDesc = "パークモジュールを有効にする",
		current_perks_cat = "現在のパーク",
		EnableCurrentPerks = "現在を表示",
		EnableCurrentPerksDesc = "ゲームよりも現在のパークを良く表示",
		current_perks_percentage = "現在の最大幅",
		current_perks_percentageDesc = "画面幅の何パーセントで新しい行に移動するか",
		current_perks_scale = "現在のスケール",
		current_perks_scaleDesc = "現在のパークを小さくすることができます",
		current_perks_hide_vanilla = "バニラのパークHUDを非表示",
		EnablefuturePerks = "未来を予測",
		EnablefuturePerksDesc =
		"次のホーリーマウンテンに出現するパークを表示します。\n初回訪問時にパークがスポーンし、\nホーリーマウンテンをスキップすると次の山にリストのパークがスポーンします。\nリロールも予測します。",
		enable_nearby_perks = "近くのパークを表示",
		enable_nearby_perksDesc = "パークウィンドウに近くのパークを表示する",
		enable_nearby_lottery = "宝くじアイコンを表示",
		enable_nearby_lotteryDesc = "無料で取れるパークに宝くじアイコンを追加",
		nearby_perks_cat = "近くのパーク",
		nearby_predict_cat = "パークを予測",
		future_perks_amount = "いくつの山を計算するか",
		future_perks_amountDesc = "未来のパークをどれだけ計算するか",
		enable_nearby_alwayscast = "常時キャストを予測",
		enable_nearby_alwayscastDesc = "ホバーで得られるキャストを表示",
		EnablePerksAutoUpdate = "自動更新を有効にする",
		EnablePerksAutoUpdateDesc = "定期的にパークリストを更新",
		enable_fungal_recipes = "AP/LCレシピを有効にする",
		enable_fungal_recipesDesc = "菌類GUIにAP/LCレシピを表示",
		stats_show_player_pos = "プレイヤーの位置を表示",
		stats_show_player_posDesc = "位置をクリックして切り替え可能",
		stats_show_player_pos_pw = "PW番号を表示",
		stats_show_player_pos_pwDesc = "位置にホバーするとPWの進行度を表示",
		stats_show_player_biome = "位置を表示",
		stats_show_player_biomeDesc = "バイオーム名を表示",
		ResetSettings = "設定をリセット",
		KYScat = "自殺",
		KYScatDesc = "神ランに入りすぎた場合の自殺カテゴリー",
		KYS_Button = "自殺ボタンを有効にする",
		KYS_ButtonDesc = "自殺ボタンを表示するかどうか",
		KYS_Button_Hide = "使用後にボタンを隠す",
		KYS_Button_HideDesc = "使用後に上記の設定をオフにする",
	},
}

local mt = {
	__index = function(t, k)
		local currentLang = GameTextGetTranslatedOrNot("$current_language")
		if currentLang == "русский(Neonomi)" or currentLang == "русский(Сообщество)" then -- compatibility with custom langs
			currentLang = "русский"
		end
		if currentLang == "自然な日本語" then
			currentLang = "日本語"
		end
		if not translations[currentLang] then
			currentLang = "English"
		end
		return translations[currentLang][k]
	end
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
}

local function build_settings()
	--- @type mod_settings_global
	local settings = {
		{
			id = "input_key",
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
			checkboxes = { "overlay_enabled", "menu_enabled" }
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
			category_id = "reset_settings_cat",
			ui_name = T.reset_settings,
			foldable = true,
			_folded = true,

			settings =
			{
				{
					id = "reset_settings",
					not_setting = true,
					ui_name = T.ResetSettings,
					ui_fn = S.reset_stuff
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

--- @param init_scope number
function ModSettingsUpdate(init_scope)
	if init_scope == 0 then -- On new game
		U.check_for_winstreak()
	end
	U.set_default(false)
	U.waiting_for_input = false
	local current_language = GameTextGetTranslatedOrNot("$current_language")
	if current_language ~= current_language_last_frame then
		mod_settings = build_settings()
	end
	current_language_last_frame = current_language
end

--- @return number
function ModSettingsGuiCount()
	return mod_settings_gui_count(mod_id, mod_settings)
end

--- @param gui gui
--- @param in_main_menu boolean
function ModSettingsGui(gui, in_main_menu)
	GuiIdPushString(gui, mod_prfx)
	gui_id = mod_id_hash * 1000
	mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
	GuiIdPop(gui)
end

U.gather_key_codes()

--- @type mod_settings_global
mod_settings = build_settings()
