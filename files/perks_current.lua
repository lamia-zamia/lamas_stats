--- @diagnostic disable: lowercase-global, missing-global-doc, undefined-global

function gui_perks_show_perks_on_screen(gui)
	GuiLayoutBeginHorizontal(gui, 0, 0, false)
	for i, perk in ipairs(perks_onscreen) do
		local tooltip_name = GameTextGetTranslatedOrNot(perks_data[perk.perk_id].ui_name)
		local tooltip_desc = GameTextGetTranslatedOrNot(perks_data[perk.perk_id].ui_description)
		GuiZSetForNextWidget(gui, GuiZ - 1)
		GuiImage(gui, id(), 0, 0, perks_data[perk.perk_id].perk_icon, 1, perks_scale) -- displaying img by id

		if perk.cast ~= nil then
			tooltip_desc = tooltip_desc .. "\n" .. "==== " .. T.lamas_stats_perks_always_cast .. " ===="
			tooltip_desc = tooltip_desc .. "\n" .. GameTextGetTranslatedOrNot(actions_data[perk.cast].name)
			tooltip_desc = tooltip_desc .. "\n" .. GameTextGetTranslatedOrNot(actions_data[perk.cast].description)
		end
		GuiTooltip(gui, tooltip_name, tooltip_desc)
	end
	GuiLayoutEnd(gui)
end

function gui_perks_get_perks_on_screen()
	perks_onscreen = {}

	local x, y = EntityGetTransform(player)
	local all_perks = EntityGetInRadiusWithTag(x, y, 500, "item_perk")

	for i, perk_entity in ipairs(all_perks) do
		local entity_x, entity_y = EntityGetTransform(perk_entity)
		local perkComponent = EntityGetFirstComponent(perk_entity, "VariableStorageComponent")
		local perk_id = nil

		if perkComponent == nil then
			perk_id = "lamas_unknown"
		else
			perk_id = ComponentGetValue2(perkComponent, "value_string")
		end
		perks_onscreen[i] = {}
		perks_onscreen[i].perk_id = perk_id
		perks_onscreen[i].x = entity_x
		perks_onscreen[i].y = entity_y
		perks_onscreen[i].pos = i
		perks_onscreen[i].lottery = false
		perks_onscreen[i].cast = nil
		if ModSettingGet("lamas_stats.enable_nearby_lottery") and tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100")) > 1 then
			SetRandomSeed(entity_x, entity_y)
			local rand = Random(1, 100)
			local perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100"))
			if (perk_id == "PERKS_LOTTERY") then perk_destroy_chance = perk_destroy_chance / 2 end
			if rand > perk_destroy_chance then perks_onscreen[i].lottery = true end
		end
		if ModSettingGet("lamas_stats.enable_nearby_alwayscast") and perk_id == "ALWAYS_CAST" then
			local good_cards = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
			SetRandomSeed(entity_x, entity_y)
			local card = good_cards[Random(1, #good_cards)]

			local r = Random(1, 100)
			local level = 6

			if (r <= 50) then
				local p = Random(1, 100)
				if (p <= 86) then
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_MODIFIER, 666)
				elseif (p <= 93) then
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_STATIC_PROJECTILE, 666)
				elseif (p < 100) then
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_PROJECTILE, 666)
				else
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_UTILITY, 666)
				end
			end
			perks_onscreen[i].cast = card

		end
	end
	table.sort(perks_onscreen, function(a, b) return a.x < b.x end)
end
