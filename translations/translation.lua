translations =
{
    ["English"] = {
		lamas_stat_return = "Return",
		lamas_stat_refresh_text = "List updated",
		lamas_stat_current = "Current",
		lamas_stats_progress_kills = "Kills:",
		lamas_stats_progress_kills_innocent = "Helpless kills:",
		lamas_stats_fungal_cooldown = "CD",
		lamas_stats_fungal_predict_error = "Something went from while trying to resolve shift",
		lamas_stats_fungal_if_fail = "if not",
		lamas_stats_fungal_shift_failed = "Fungal shift was failed",
		lamas_stats_ingame_name = "material id",
		FungalShifts = "Fungal Shifts",
		lamas_stats_fungal_group_of = "group of",
		lamas_stats_fungal_next_shift = "next shift",
		lamas_stats_fungal_failed = "Failed",
		lamas_stats_flask = "Flask",
		lamas_stats_or = "or",
		lamas_stats_if = "if",
		lamas_stats_shift = "shift",
		lamas_stats_farthest = "Farthest",
		lamas_stats_fungal_shift_possible = "Flask shift available",
		lamas_stats_fungal_shift_used = "Flask was used in shift",
		lamas_stats_fungal_greedy = "If gold or holy grass is used in shift",
		Perks = "Perks",
		lamas_stats_nearby_perks = "Nearby perks",
		lamas_stats_perks_next = "Predict",
		lamas_stats_perks_reroll = "Reroll",
		lamas_stats_perks_always_cast = "Will add next spell",
		lamas_stats_stats_pw = "World",
		lamas_stats_stats_pw_west = "West",
		lamas_stats_stats_pw_east = "East",
		lamas_stats_stats_pw_main = "Main",
		lamas_stats_hearts_find = "Hearts found:",
		lamas_stats_projectiles_shot = "Projectile shoot:",
		lamas_stats_kicks = "Kicks:",
		lamas_stats_damage_taken = "Damage taken:",
		lamas_stats_position = "Position",
		lamas_stats_position_toggle = "Click to toggle",
		lamas_stats_location = "Location",
		lamas_stats_unknown = "Unknown",
		KYS_Suicide = "Suicide",
		KYS_Suicide_Warn = "Are you sure? This button will kill you",
		KYS_Button = "Yes, commit seppuku",
    },
	["русский"] = {
		lamas_stat_return = "Назад",
		lamas_stat_refresh_text = "Список обновлён",
		lamas_stat_current = "Текущие",
		lamas_stats_progress_kills = "Убийства:",
		lamas_stats_progress_kills_innocent = "Убито беспомощных:",
		lamas_stats_fungal_cooldown = "КД",
		lamas_stats_fungal_predict_error = "Что-то пошло не так при попытке рассчитать сдвиг",
		lamas_stats_fungal_if_fail = "если не",
		lamas_stats_fungal_shift_failed = "Грибной сдвиг был провальный",
		lamas_stats_ingame_name = "айди материала",		
		FungalShifts = "Грибные сдвиги",
		lamas_stats_fungal_group_of = "группа",
		lamas_stats_fungal_next_shift = "следующий сдвиг",
		lamas_stats_flask = "Пузырёк",
		lamas_stats_or = "или",
		lamas_stats_if = "если",
		lamas_stats_shift = "сдвиг",
		lamas_stats_farthest = "Самый дальний",
		lamas_stats_fungal_shift_possible = "Возможен сдвиг с помощью фляги",
		lamas_stats_fungal_shift_used = "В сдвиге была использована фляга",
		lamas_stats_fungal_greedy = "Если в сдвиге используется золото или божественная земля",
		lamas_stats_fungal_failed = "Неудачно",
		Perks = "Перки",
		lamas_stats_nearby_perks = "Перки рядом",
		lamas_stats_perks_next = "Предсказать",
		lamas_stats_perks_reroll = "Реролл",
		lamas_stats_perks_always_cast = "Добавит следующий спелл",
		lamas_stats_stats_pw = "Мир",
		lamas_stats_stats_pw_west = "Западный",
		lamas_stats_stats_pw_east = "Восточный",
		lamas_stats_stats_pw_main = "Основной",
		lamas_stats_hearts_find = "Найдено сердец:",
		lamas_stats_projectiles_shot = "Сделано выстрелов:",
		lamas_stats_kicks = "Пинков:",
		lamas_stats_damage_taken = "Получено урона:",
		lamas_stats_position = "Позиция",
		lamas_stats_position_toggle = "Кликнуть для переключения",
		lamas_stats_location = "Локация",
		lamas_stats_unknown = "Неизвестно",
		KYS_Suicide = "Суицид",
		KYS_Suicide_Warn = "Точно? Эта кнопка убьёт Мину",
		KYS_Button = "Да, сделать сеппуку",
	},
}

_T = setmetatable({}, 
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
	if translations[currentLang][k] then return translations[currentLang][k]
	else return "ERROR" end
	end
})