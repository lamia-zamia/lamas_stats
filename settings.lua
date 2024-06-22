dofile_once("data/scripts/lib/mod_settings.lua")
local waitingForKey = false --flag for async waiting for keypress

local translations =
{
    ["English"] = {
		Hotkey = "Hotkey",
		HotkeyDesc = "Hotkey to enable overlay",
		Overlay = "Overlay",
		OverlayDesc = "Overlay settings",
		StartEnabled = "Start enabled",
		StartEnabledDesc = "Should the overlay be enabled on spawn",
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
		EnableFungalPast = "Show past shifts",
		EnableFungalFuture = "Show future shifts",
		FungalScale = "Fungal shift window scale",
		FungalShiftMax = "Maximal fungal shifts",
		FungalShiftMaxDesc = "Vanilla's default is 20. \nThis does NOT change game's maximum and only affects calculation.\nThis setting is in case you are using other mods.",
		EnableFungalGreedyTip = "Show greedy shift reminder",
		EnableFungalGreedyTipDesc = "Add text about shifting into gold or divine ground",
		EnableFungalGreedyGold = "Show greedy gold shift",
		EnableFungalGreedyGrass = "Show greedy grass shift",
		GreedyShiftReminder = "read me, it's about greedy shift",
		GreedyShiftReminderDesc = "If the shift is going to be successful - \nthe result shift will be coloured purple regardless of other settings.\nIf it's not purple - it's not going to be transformed into gold.",
		LamasMenuSetting = "Menu",
		LamasMenuName = "Menu's header",
		LamasMenuSettingDesc = "Settings for menu that called by pressing main button",
		LamasMenuEnabledByDefault = "Open menu by default",
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
		EnablefuturePerks = "Predict future",
		EnablefuturePerksDesc = "Shows perks that's going to spawn in the next holy mountain.\nPerks spawn on first visit, \nif you skip holy mountain the next mountain will spawn the perks in list.\nAlso predicts rerolls",
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
		ResetSettings = "Reset settings",
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
		EnableFungalPast = "Показывать прошлые сдвиги",
		EnableFungalFuture = "Показывать будущие сдвиги",
		FungalScale = "Масштаб окна грибных сдвигов",
		FungalShiftMax = "Максимальный грибной сдвиг",
		FungalShiftMaxDesc = "Умолчания игры без модов - 20. \nЭта настройка НЕ меняет максимум игры и влияет только на рассчёты.\nЭта настройка на случай если у вас другие моды.",
		EnableFungalGreedyTip = "Показывать напоминание о жадном сдвиге",
		EnableFungalGreedyTipDesc = "Добавляет текст о сдвиге в золото или божественные земли",
		EnableFungalGreedyGold = "Показывать результаты сдвига в золото",
		EnableFungalGreedyGrass = "Показывать результаты сдвига бож.травы",
		GreedyShiftReminder = "прочитай меня, это про жадные сдвиги",
		GreedyShiftReminderDesc = "Если сдвиг будет успешный - \nитоговый сдвиг будет окрашен в фиолетовый вне зависимости от настроек.\nЕсли оно не фиолетовое - попытка превратить в золото будет неуспешной",
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
		EnablefuturePerks = "Рассчитать будущие",
		EnablefuturePerksDesc = "Показывает перки, которые будут заспавлены в будущей горе.\nПерки спавнятся при первом визите, даже если пропустить гору и пойти в следующий\n - заспавнится то, что в списке.\nТак же предсказывает рероллы",
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
}

local _T = setmetatable({}, 
{
	__index = function(t, k)
	local currentLang = GameTextGetTranslatedOrNot("$current_language")
	if currentLang == "русский(Neonomi)" or currentLang == "русский(Сообщество)" then --compatibility with custom langs
		currentLang = "русский"
	end
	if not translations[currentLang] then
		currentLang = "English"
	end
	if not translations[currentLang][k] then
		print(("ERROR: No translation found for key '%s' in language '%s'"):format(k, currentLang))
		currentLang = "English"
	end
	return translations[currentLang][k]
	end
})

local function GatherKeyCodes() --function to get keycodes from game file
	local keycodes = {}
	local keycodes_all = ModTextFileGetContent("data/scripts/debug/keycodes.lua")
	local startgather = false --triger to stop and start of writing keycodes
	for line in keycodes_all:gmatch("[^\r\n]+") do --parsing keycodes
		if string.find(line, "gamepad") then --end of keyboard inputs
			break
		end
		if startgather then
			local temp = {}
			for str in string.gmatch(line, "%S+") do
				table.insert(temp,str)
			end
			-- table.insert(keycodes,{temp[3], temp[1]})
			keycodes[temp[3]] = temp[1]
		end
		if string.find(line,"InputIsButtonDown") then --start of keyboard inputs
			startgather = true
		end
	end
	return keycodes
end

local keycodes = GatherKeyCodes() --gathered combo of keycodes to keyname

function GetInput() --function to wait for input
	waitingForKey = true
	for code,keyname in pairs(keycodes) do 
		if InputIsKeyDown(code) == true then --when key is detected
			ModSettingSet("lamas_stats.input_key",code) -- i have no idea why it doesn't work unless there are two of them
			ModSettingSetNextValue("lamas_stats.input_key",code,false)
			waitingForKey = false
			break
		end
	end
end
--ui for getting hotkey
function InputKeyUI(mod_id, gui, in_main_menu, im_id, setting)
	if waitingForKey == false then
		local value = ModSettingGet(mod_setting_get_id(mod_id,setting)) --getting current setting
		local text = setting.ui_name .. ": " .. keycodes[value]

		if GuiButton(gui, im_id, mod_setting_group_x_offset, 0, text) then
			waitingForKey = true
		end
	else
		GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
		-- menuoptions_configurecontrols_pressakey
		GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name .. ": " .. GameTextGetTranslatedOrNot("$menuoptions_configurecontrols_pressakey"))
		-- GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name .. ": " .. GameTextGetTranslatedOrNot("$lamas_stat_test"))
	end
	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function reminder_about_greedy_shift(mod_id, gui, in_main_menu, im_id, setting)
	GuiColorSetForNextWidget(gui, 0.5, 0.5, 0.5, 1)
	GuiText(gui, mod_setting_group_x_offset, 0, _T.GreedyShiftReminder)
	GuiTooltip(gui,_T.GreedyShiftReminderDesc,"")
end

local mod_id = "lamas_stats"
mod_settings_version = 1

local default = 
{
	["lamas_stats.setting_changed"] = true,
	["input_key"] = "60",
	["enabled_at_start"] = false,
	["overlay_x"] = 2,
	["overlay_y"] = 2,
	["stats_enable"] = true,
	["stats_position"] = "on top",
	["stats_showtime"] = true,
	["stats_showkills"] = true,
	["stats_show_innocent"] = true,
	["stats_show_fungal_cooldown"] = true,
	["stats_show_fungal_order"] = "first",
	["stats_show_fungal_type"] = "image",
	["lamas_menu_header"] = "== LAMA'S STATS ==",
	["lamas_menu_enabled_default"] = false,
	["enable_fungal"] = true,
	["enable_fungal_past"] = true,
	["enable_fungal_future"] = false,
	["fungal_scale"] = 1,
	["fungal_group_type"] = "group",
	["fungal_shift_max"] = 20,
	["enable_fungal_greedy_tip"] = true,
	["enable_fungal_greedy_gold"] = true,
	["enable_fungal_greedy_grass"] = false,
	["enable_perks"] = true,
	["enable_current_perks"] = true,
	["current_perks_percentage"] = 0.5,
	["current_perks_scale"] = 1,
	["enable_future_perks"] = false,
	["enable_nearby_perks"] = true,
	["enable_nearby_lottery"] = false,
	["future_perks_amount"] = 7,
	["enable_nearby_alwayscast"] = false,
	["enable_perks_autoupdate"] = true,
	["enable_fungal_recipes"] = false,
	["stats_show_player_pos"] = false,
	["stats_show_player_pos_pw"] = true,
	["stats_show_player_biome"] = false,
	["KYS_Button"] = false,
	["KYS_Button_Hide"] = true,
	["stats_show_farthest_pw"] = true,
}

function ResetSettings(mod_id, gui, in_main_menu, im_id, setting)
	for key,value in pairs(default) do
		ModSettingSet("lamas_stats." .. key,value) -- i have no idea why it doesn't work unless there are two of them
		ModSettingSetNextValue("lamas_stats." .. key,value,false)
	end
end

--ui for reset settings
function ResetSettingsUI(mod_id, gui, in_main_menu, im_id, setting)
	local text = setting.ui_name
	
	if GuiButton(gui, im_id, mod_setting_group_x_offset, 0, text) then
		ResetSettings(mod_id, gui, in_main_menu, im_id, setting)
	end
end

local function build_settings()
	return {
	{
		id = "input_key",
		ui_name = _T.Hotkey,
		ui_description = _T.HotkeyDesc,
		value_default = default["input_key"],
		scope = MOD_SETTING_SCOPE_RUNTIME,
		ui_fn = InputKeyUI,
	},
	{
		category_id = "overlay",
		ui_name = _T.Overlay,
		ui_description = _T.OverlayDesc,
		foldable = true,
		_folded = true,
		
		settings =
		{
			{
				id = "enabled_at_start",
				ui_name = _T.StartEnabled,
				ui_description = _T.StartEnabledDesc,
				value_default = default["enabled_at_start"],
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "overlay_x",
				ui_name = _T.overlay_x,
				value_default = default["overlay_x"],
				value_min = 0,
				value_max = 100,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "overlay_y",
				ui_name = _T.overlay_y,
				ui_description = _T.overlay_y_desc,
				value_default = default["overlay_y"],
				value_min = 0,
				value_max = 100,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
		},
	},
	{
		category_id = "stats",
		ui_name = _T.Stats,
		ui_description = _T.StatsDesc,
		foldable = true,
		_folded = true,
		
		settings = 
		{
			{
				id = "stats_enable",
				ui_name = _T.StatsEnable,
				value_default = default["stats_enable"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
				
			},
			{
				id = "stats_position",
				ui_name = _T.StatsPosition,
				value_default = default["stats_position"],
				values = {{"merged",_T.StatsInMenu}, {"on top",_T.StatsOnOverlay}},
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "stats_showtime",
				ui_name = _T.StatsShowTime,
				ui_description = _T.StatsShowTimeDesc,
				value_default = default["stats_showtime"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "stats_showkills",
				ui_name = _T.StatsShowKills,
				value_default = default["stats_showkills"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "stats_show_innocent",
				ui_name = _T.StatsShowKillsInnocent,
				ui_description = _T.StatsShowKillsInnocentDesc,
				value_default = default["stats_show_innocent"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "stats_show_player_pos",
				ui_name = _T.stats_show_player_pos,
				ui_description = _T.stats_show_player_posDesc,
				value_default = default["stats_show_player_pos"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "stats_show_player_pos_pw",
				ui_name = _T.stats_show_player_pos_pw,
				ui_description = _T.stats_show_player_pos_pwDesc,
				value_default = default["stats_show_player_pos_pw"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "stats_show_player_biome",
				ui_name = _T.stats_show_player_biome,
				ui_description = _T.stats_show_player_biomeDesc,
				value_default = default["stats_show_player_biome"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				category_id = "stats_show_fungal_category",
				ui_name = _T.StatsShowFungalCat,
				foldable = true,
				_folded = true,
				
				settings = 
				{
					{
						id = "stats_show_fungal_cooldown",
						ui_name = _T.StatsShowFungalCooldown,
						value_default = default["stats_show_fungal_cooldown"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "stats_show_fungal_order",
						ui_name = _T.StatsShowFungalOrder,
						value_default = default["stats_show_fungal_order"],
						values = {{"first",_T.StatsShowFungalOrderFirst}, {"last",_T.StatsShowFungalOrderLast}},
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "stats_show_fungal_type",
						ui_name = _T.StatsShowFungalType,
						value_default = default["stats_show_fungal_type"],
						values = {{"time",_T.StatsShowFungalTypeTime}, {"image",_T.StatsShowFungalTypeImage}},
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
				},
			},
			{
				category_id = "stats_show_custom_category",
				ui_name = _T.StatsShowCustomCat,
				ui_description = _T.StatsShowCustomCatDesc,
				foldable = true,
				_folded = true,
				
				settings = 
				{
					{
						id = "stats_show_farthest_pw",
						ui_name = _T.stats_show_farthest_pw,
						ui_description = _T.stats_show_farthest_pwDesc,
						value_default = default["stats_show_farthest_pw"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
				},
			},
		},
	},
	{
		category_id = "lamas_menu_setting",
		ui_name = _T.LamasMenuSetting,
		ui_description = _T.LamasMenuSettingDesc,
		foldable = true,
		_folded = true,
		
		settings = 
		{
			{
				id = "lamas_menu_header",
				ui_name = _T.LamasMenuName,
				value_default = default["lamas_menu_header"],
				scope =  MOD_SETTING_SCOPE_RUNTIME,
				change_fn = mod_setting_change_callback,
			},
			{
				id = "lamas_menu_enabled_default",
				ui_name = _T.LamasMenuEnabledByDefault,
				value_default = default["lamas_menu_enabled_default"],
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				category_id = "fungal",
				ui_name = _T.FungalShifts,
				ui_description = _T.FungalShiftsDesc,
				foldable = true,
				_folded = true,
				
				settings = 
				{
					{
						id = "enable_fungal",
						ui_name = _T.EnableFungalModule,
						value_default = default["enable_fungal"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "enable_fungal_recipes",
						ui_name = _T.enable_fungal_recipes,
						ui_description = _T.enable_fungal_recipesDesc,
						value_default = default["enable_fungal_recipes"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "fungal_group_type",
						ui_name = _T.FungalGroupType,
						ui_description = _T.FungalGroupTypeDesc,
						value_default = default["fungal_group_type"],
						values = {{"group",_T.FungalGroupTypeTrue}, {"full",_T.FungalGroupTypeFalse}},
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "fungal_shift_max",
						ui_name = _T.FungalShiftMax,
						ui_description = _T.FungalShiftMaxDesc,
						value_default = default["fungal_shift_max"],
						value_min = 20,
						value_max = 100,
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "enable_fungal_past",
						ui_name = _T.EnableFungalPast,
						value_default = default["enable_fungal_past"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "enable_fungal_future",
						ui_name = _T.EnableFungalFuture,
						value_default = default["enable_fungal_future"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "enable_fungal_greedy_tip",
						ui_name = _T.EnableFungalGreedyTip,
						ui_description = _T.EnableFungalGreedyTipDesc,
						value_default = default["enable_fungal_greedy_tip"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "reminder_about_greedy_shift",
						ui_name = _T.GreedyShiftReminder,
						value_default = true,
						ui_fn = reminder_about_greedy_shift,
					},
					{
						id = "enable_fungal_greedy_gold",
						ui_name = _T.EnableFungalGreedyGold,
						value_default = default["enable_fungal_greedy_gold"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "enable_fungal_greedy_grass",
						ui_name = _T.EnableFungalGreedyGrass,
						value_default = default["enable_fungal_greedy_grass"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "fungal_scale",
						ui_name = _T.FungalScale,
						value_default = default["fungal_scale"],
						value_min = 0.7,
						value_max = 1,
						value_display_multiplier = 100,
						value_display_formatting = " $0 %",
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
				},
			},
			{
				category_id = "perks",
				ui_name = _T.Perks,
				ui_description = _T.PerksDesc,
				foldable = true,
				_folded = true,
				
				settings = 
				{
					{
						id = "enable_perks",
						ui_name = _T.EnablePerks,
						ui_description = _T.EnablePerksDesc,
						value_default = default["enable_perks"],
						scope =  MOD_SETTING_SCOPE_RUNTIME,
						change_fn = mod_setting_change_callback,
					},
					{
						id = "enable_perks_autoupdate",
						ui_name = _T.EnablePerksAutoUpdate,
						ui_description = _T.EnablePerksAutoUpdateDesc,
						value_default = default["enable_perks_autoupdate"],
						scope =  MOD_SETTING_SCOPE_RUNTIME_RESTART,
					},
					{
						category_id = "current_perks_cat",
						ui_name = _T.current_perks_cat,
						foldable = true,
						_folded = true,
						
						settings = 
						
						{
							{
								id = "enable_current_perks",
								ui_name = _T.EnableCurrentPerks,
								ui_description = _T.EnableCurrentPerksDesc,
								value_default = default["enable_current_perks"],
								scope =  MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
							{
								id = "current_perks_percentage",
								ui_name = _T.current_perks_percentage,
								ui_description = _T.current_perks_percentageDesc,
								value_default = default["current_perks_percentage"],
								value_min = 0,
								value_max = 0.8,
								value_display_multiplier = 100,
								value_display_formatting = " $0 %",
								scope =  MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
							{
								id = "current_perks_scale",
								ui_name = _T.current_perks_scale,
								ui_description = _T.current_perks_scaleDesc,
								value_default = default["current_perks_scale"],
								value_min = 0.5,
								value_max = 1,
								value_display_multiplier = 100,
								value_display_formatting = " $0 %",
								scope = MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
						},
					},
					{
						category_id = "nearby_perks_cat",
						ui_name = _T.nearby_perks_cat,
						foldable = true,
						_folded = true,
						
						settings = 
						{
							{
								id = "enable_nearby_perks",
								ui_name = _T.enable_nearby_perks,
								ui_description = _T.enable_nearby_perksDesc,
								value_default = default["enable_nearby_perks"],
								scope = MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
							{
								id = "enable_nearby_lottery",
								ui_name = _T.enable_nearby_lottery,
								ui_description = _T.enable_nearby_lotteryDesc,
								value_default = default["enable_nearby_lottery"],
								scope = MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
							{
								id = "enable_nearby_alwayscast",
								ui_name = _T.enable_nearby_alwayscast,
								ui_description = _T.enable_nearby_alwayscastDesc,
								value_default = default["enable_nearby_alwayscast"],
								scope = MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
						},
					},
					{
						category_id = "nearby_predict_cat",
						ui_name = _T.nearby_predict_cat,
						foldable = true,
						_folded = true,
						
						settings = 
						{
							{
								id = "enable_future_perks",
								ui_name = _T.EnablefuturePerks,
								ui_description = _T.EnablefuturePerksDesc,
								value_default = default["enable_future_perks"],
								scope =  MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
							{
								id = "future_perks_amount",
								ui_name = _T.future_perks_amount,
								ui_description = _T.future_perks_amountDesc,
								value_default = default["future_perks_amount"],
								value_min = 1,
								value_max = 13,
								scope = MOD_SETTING_SCOPE_RUNTIME,
								change_fn = mod_setting_change_callback,
							},
						},
					},
				},
			},
			{
				category_id = "KYS",
					ui_name = _T.KYScat,
					ui_description = _T.KYScatDesc,
					foldable = true,
					_folded = true,
					
					settings = 
					{
						{
							id = "KYS_Button",
							ui_name = _T.KYS_Button,
							ui_description = _T.KYS_ButtonDesc,
							value_default = default["KYS_Button"],
							scope = MOD_SETTING_SCOPE_RUNTIME,
							change_fn = mod_setting_change_callback,
						},
						{
							id = "KYS_Button_Hide",
							ui_name = _T.KYS_Button_Hide,
							ui_description = _T.KYS_Button_HideDesc,
							value_default = default["KYS_Button_Hide"],
							scope = MOD_SETTING_SCOPE_RUNTIME,
							change_fn = mod_setting_change_callback,
						},
					},
			},
		},
	},
	{
		category_id = "reset_settings_cat",
		ui_name = _T.ResetSettings,
		foldable = true,
		_folded = true,
		
		settings = 
		{
			{
				id = "reset_settings",
				ui_name = _T.ResetSettings,
				scope = MOD_SETTING_SCOPE_RUNTIME,
				ui_fn = ResetSettingsUI, -- custom widget
			},
		},
	},
	--end of settings
}
end

function mod_setting_change_callback(mod_id, gui, in_main_menu, setting, old_value, new_value) --setting to tell game to restart gui
	ModSettingSet("lamas_stats.setting_changed", true)
end

function ModSettingsUpdate( init_scope )
	waitingForKey = false
	local old_version = mod_settings_get_version( mod_id )
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
	if waitingForKey == true then --async wait for input 
		GetInput()
	end
	
	local current_language = GameTextGetTranslatedOrNot("$current_language")
	
	if current_language ~= current_language_last_frame then
		mod_settings = build_settings()
	end
	current_language_last_frame = current_language
end

mod_settings = build_settings()