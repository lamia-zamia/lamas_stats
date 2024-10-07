---@diagnostic disable: lowercase-global, missing-global-doc
local perks_stats, perks_current_max_count

local perks_current_scale = ModSettingGet("lamas_stats.current_perks_scale")
local perks_current_icon_scale = 0.7 * perks_current_scale

function gui_perks_show_stats(gui)
	GuiLayoutBeginHorizontal(gui,0,0, false)
	GuiImage(gui, id(), 0, 0, perk_png, 1, perks_scale * 0.7) --displaying img by id
	GuiText(gui, 0, 0, perks_current_count, perks_scale)
	
	for perk,text in pairs(perks_stats) do
		GuiImage(gui, id(), 0, 0, perks_data[perk].perk_icon, 1, perks_scale * 0.7)
		GuiText(gui, 0, 0, text)
	end

	GuiImage(gui, id(), 0, 0, reroll_png, 1, perks_scale * 0.7) --displaying img by id
	GuiText(gui, 0, 0, reroll_count, perks_scale)

	GuiLayoutEnd(gui) 
end

function gui_perks_show_perks_on_screen(gui)
	if perks_onscreen == nil then return end
	if #perks_onscreen > 0 then
		GuiZSetForNextWidget(gui, GuiZ)
		GuiText(gui, 0, 0, "---- " .. _T.lamas_stats_nearby_perks .. " ----", perks_scale)
		
		local width_icon = GuiGetImageDimensions(gui, perks_data["EXTRA_PERK"].perk_icon, perks_scale) 
		GuiLayoutBeginHorizontal(gui,0,0, false)
		for i,perk in ipairs(perks_onscreen) do 
			local tooltip_name = GameTextGetTranslatedOrNot(perks_data[perk.perk_id].ui_name)
			local tooltip_desc = GameTextGetTranslatedOrNot(perks_data[perk.perk_id].ui_description)
			GuiZSetForNextWidget(gui, GuiZ-1)
			GuiImage(gui, id(), 0, 0, perks_data[perk.perk_id].perk_icon, 1, perks_scale) --displaying img by id

			if perk.cast ~= nil then
				tooltip_desc = tooltip_desc .. "\n" .. "==== " .. _T.lamas_stats_perks_always_cast .. " ===="
				tooltip_desc = tooltip_desc .. "\n" .. GameTextGetTranslatedOrNot(actions_data[perk.cast].name)
				tooltip_desc = tooltip_desc .. "\n" .. GameTextGetTranslatedOrNot(actions_data[perk.cast].description)
			end
			GuiTooltip(gui, tooltip_name, tooltip_desc)
			if perk.lottery then
				local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui)
				
				GuiLayoutBeginLayer(gui)
				GuiZSetForNextWidget(gui, GuiZ-2)
				GuiImage(gui, id(), x+(width_icon/1.5), y - (width_icon/6), perks_data["PERKS_LOTTERY"].perk_icon, 1, perks_scale*0.5) --displaying img by id
				GuiLayoutEndLayer(gui) 
			end
		end
		GuiLayoutEnd(gui)
	end
end

function gui_perks_show_current_perks(gui)
	GuiLayoutBeginHorizontal(gui,0,0, false)
	GuiText(gui, 0, 0, "---- " .. _T.lamas_stat_current .. " ----", perks_scale)
	GuiLayoutEnd(gui)
	local rows = 1 
	GuiText(gui, 0, 0, " ", perks_current_scale) --phantom vertical text for next widgets to know where to put themself
	local width_icon = GuiGetImageDimensions(gui, perks_data["EXTRA_PERK"].perk_icon, perks_current_icon_scale) 
	local width_space = GuiGetTextDimensions(gui, " ", perks_current_scale)
	local width_text_max = GuiGetTextDimensions(gui, perks_current_max_count .. "x", perks_current_scale)
	local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui)
	local width_screen = GuiGetScreenDimensions(gui)

	GuiLayoutBeginLayer(gui)
	
	local idx = 1
	for perk_id,count in pairs(perks_current) do
		local text = count .. "x"
		local width_text = GuiGetTextDimensions(gui,text,perks_current_scale)
		GuiText(gui, width_text_max - width_text + x, y, text, perks_current_scale)
		x = x + width_text_max
		
		GuiImage(gui, id(), x, y, perks_data[perk_id].perk_icon, 1, perks_current_icon_scale)
		GuiTooltip(gui, perks_data[perk_id].ui_name, perks_data[perk_id].ui_description)
		
		local _,_,_,x_tmp = GuiGetPreviousWidgetInfo(gui)
		
		if (x_tmp/perks_current_max_width) > width_screen and idx < perks_current_count then
			GuiLayoutEndLayer(gui)
			GuiText(gui, 0, 0, " ", perks_current_scale) --phantom vertical text for next widgets to know where to put themself
			_,_,_,x,y = GuiGetPreviousWidgetInfo(gui)
			GuiLayoutBeginLayer(gui)
		else
			x = x + width_icon + width_space
		end
		idx = idx + 1
	end
	GuiLayoutEndLayer(gui) 
end

function gui_perks_gather_stats()
	gui_perks_gather_stats_owned_perks()
	reroll_count = GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0")
	perks_current_max_width = ModSettingGet("lamas_stats.current_perks_percentage")
	perks_current_scale = ModSettingGet("lamas_stats.current_perks_scale")
	perks_current_icon_scale = 0.7 * perks_current_scale
end

function gui_perks_gather_stats_owned_perks()
	perks_stats = {}
	local extra_perk_count = perks_current["EXTRA_PERK"] or 0
	if extra_perk_count > 0 then perks_stats["EXTRA_PERK"] = tostring(extra_perk_count)	end
	
	local perks_lottery_count = perks_current["PERKS_LOTTERY"] or 0
	if perks_lottery_count > 0 then 
		perks_stats["PERKS_LOTTERY"] = tostring(100 - math.floor(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100"))) .. "%" 
	end
end

function gui_perks_get_perks_on_screen()
	perks_onscreen = {}
	
	local x,y = EntityGetTransform(player)
	local all_perks = EntityGetInRadiusWithTag(x, y, 500, "item_perk")
	
	for i,perk_entity in ipairs(all_perks) do
		local entity_x,entity_y = EntityGetTransform(perk_entity)
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
			if(perk_id == "PERKS_LOTTERY") then perk_destroy_chance = perk_destroy_chance / 2 end
			if rand > perk_destroy_chance then perks_onscreen[i].lottery = true end
		end
		if ModSettingGet("lamas_stats.enable_nearby_alwayscast") and perk_id == "ALWAYS_CAST" then
			local good_cards = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
			SetRandomSeed(entity_x, entity_y)
			local card = good_cards[Random(1, #good_cards)]

			local r = Random( 1, 100 )
			local level = 6

			if( r <= 50 ) then
				local p = Random(1,100)
				if( p <= 86 ) then
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_MODIFIER, 666 )
				elseif( p <= 93 ) then
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_STATIC_PROJECTILE, 666 )
				elseif ( p < 100 ) then
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_PROJECTILE, 666 )
				else
					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_UTILITY, 666 )
				end
			end
			perks_onscreen[i].cast = card
			
		end
	end
	table.sort(perks_onscreen, function(a, b) return a.x < b.x end)
end