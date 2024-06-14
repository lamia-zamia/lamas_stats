dofile_once("data/scripts/perks/perk.lua")
local perk_png = "data/items_gfx/perk.png"
local reroll_png = "mods/lamas_stats/files/reroll.png"
local perks = perk_get_spawn_order() --from default function

local perks_current_max_width = ModSettingGet("lamas_stats.current_perks_percentage")
local how_many_into_future = ModSettingGet("lamas_stats.future_perks_amount")

local perks_stats,perks_data,actions_data,perks_current,future_perks,perks_onscreen,reroll_perks,future_index,reroll_index,reroll_count = nil
local perks_current_count,perks_current_max_count = nil

local display_current,display_future,display_reroll = false,false

-- scaling
local perks_scale = 1

local perks_predict_scale = 1
local perks_predict_icon_scale = 1 * perks_predict_scale

local perks_current_scale = ModSettingGet("lamas_stats.current_perks_scale")
local perks_current_icon_scale = 0.7 * perks_current_scale

function gui_perks_main()
	GuiBeginAutoBox(gui_menu)
	
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y, false, 0, 0) --layer1
	GuiZSet(gui_menu,900)
	GuiText(gui_menu, 0, 0, "==== " .. _T.Perks .. " ====", perks_scale)
	
	--buttons
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	gui_menu_switch_button(gui_menu, 9999, perks_scale, gui_menu_main_display_loop) --return
	gui_do_refresh_button(gui_menu, perks_scale, gui_perks_refresh_perks)
	
	GuiID = 1100
	GuiZ = 1000
	
	if ModSettingGet("lamas_stats.enable_current_perks") then
		if perks_current_count > 0 then
			if GuiButton(gui_menu, GuiID, 0, 0, "[" .. _T.lamas_stat_current .. "]", perks_scale) then
				display_current = not display_current
			end
			GuiID = GuiID + 1
		end
	end
	
	if ModSettingGet("lamas_stats.enable_future_perks") then
		if GuiButton(gui_menu, GuiID, 0, 0, "[" .. _T.lamas_stats_perks_next .. "]", perks_scale) then
			display_future = not display_future
		end
		GuiID = GuiID + 1
	end
	
	GuiLayoutEnd(gui_menu) 
	--buttons end
	
	if ModSettingGet("lamas_stats.enable_perks_autoupdate") then
		if ModSettingGet("lamas_stats.enable_perks_autoupdate_flag") then
			ModSettingSet("lamas_stats.enable_perks_autoupdate_flag", false)
			gui_perks_refresh_perks()
		end
		if GameGetFrameNum() % 300 == 0 then --update once per 5 second
			gui_perks_refresh_perks()
		end
	end

	gui_perks_show_stats()
	
	if ModSettingGet("lamas_stats.enable_nearby_perks") then 
		gui_perks_show_perks_on_screen()
	end
	
	if display_current then	gui_perks_show_current_perks() end
	
	if display_future then gui_perks_show_future_perks() end
	

	GuiLayoutEnd(gui_menu) --layer1
	GuiZSetForNextWidget(gui_menu, GuiZ+10)
	GuiEndAutoBoxNinePiece(gui_menu, 1, 0, 0, false, 0, screen_png, screen_png)
end

function gui_perks_show_stats()
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	GuiImage(gui_menu, GuiID, 0, 0, perk_png, 1, perks_scale * 0.7) --displaying img by id
	GuiID = GuiID + 1
	GuiText(gui_menu, 0, 0, perks_current_count, perks_scale)
	
	for perk,text in pairs(perks_stats) do
		GuiImage(gui_menu, GuiID, 0, 0, perks_data[perk].perk_icon, 1, perks_scale * 0.7)
		GuiID = GuiID + 1
		GuiText(gui_menu, 0, 0, text)
	end

	GuiImage(gui_menu, GuiID, 0, 0, reroll_png, 1, perks_scale * 0.7) --displaying img by id
	GuiID = GuiID + 1
	GuiText(gui_menu, 0, 0, reroll_count, perks_scale)

	GuiLayoutEnd(gui_menu) 
end

function gui_perks_gather_stats()
	gui_perks_gather_stats_owned_perks()
	reroll_count = GlobalsGetValue("TEMPLE_PERK_REROLL_COUNT", "0")
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
		local perk_id = ComponentGetValue2(perkComponent, "value_string")
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

function gui_perks_show_perks_on_screen()
	if perks_onscreen == nil then return end
	if #perks_onscreen > 0 then
		GuiZSetForNextWidget(gui_menu, GuiZ)
		GuiText(gui_menu, 0, 0, "---- " .. _T.nearby_perks_cat .. " ----", perks_scale)
		
		local width_icon = GuiGetImageDimensions(gui_menu, perks_data["EXTRA_PERK"].perk_icon, perks_scale) 
		GuiLayoutBeginHorizontal(gui_menu,0,0, false)
		for i,perk in ipairs(perks_onscreen) do 
			local tooltip_name = GameTextGetTranslatedOrNot(perks_data[perk.perk_id].ui_name)
			local tooltip_desc = GameTextGetTranslatedOrNot(perks_data[perk.perk_id].ui_description)
			GuiZSetForNextWidget(gui_menu, GuiZ-1)
			GuiImage(gui_menu, GuiID, 0, 0, perks_data[perk.perk_id].perk_icon, 1, perks_scale) --displaying img by id

			GuiID = GuiID + 1
			if perk.cast ~= nil then
				tooltip_desc = tooltip_desc .. "\n" .. "==== " .. _T.lamas_stats_perks_always_cast .. " ===="
				tooltip_desc = tooltip_desc .. "\n" .. GameTextGetTranslatedOrNot(actions_data[perk.cast].name)
				tooltip_desc = tooltip_desc .. "\n" .. GameTextGetTranslatedOrNot(actions_data[perk.cast].description)
			end
			GuiTooltip(gui_menu, tooltip_name, tooltip_desc)
			if perk.lottery then
				local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui_menu)
				
				GuiLayoutBeginLayer(gui_menu)
				GuiZSetForNextWidget(gui_menu, GuiZ-2)
				GuiImage(gui_menu, GuiID, x+(width_icon/1.5), y - (width_icon/6), perks_data["PERKS_LOTTERY"].perk_icon, 1, perks_scale*0.5) --displaying img by id
				GuiID = GuiID + 1
				GuiLayoutEndLayer(gui_menu) 
			end
		end
		GuiLayoutEnd(gui_menu)
	end
end

function gui_perks_show_current_perks()
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	GuiText(gui_menu, 0, 0, "---- " .. _T.lamas_stat_current .. " ----", perks_scale)
	GuiLayoutEnd(gui_menu)
	local rows = 1 
	GuiText(gui_menu, 0, 0, " ", perks_current_scale) --phantom vertical text for next widgets to know where to put themself
	local width_icon = GuiGetImageDimensions(gui_menu, perks_data["EXTRA_PERK"].perk_icon, perks_current_icon_scale) 
	local width_space = GuiGetTextDimensions(gui_menu, " ", perks_current_scale)
	local width_text_max = GuiGetTextDimensions(gui_menu, perks_current_max_count .. "x", perks_current_scale)
	local _,_,_,x,y = GuiGetPreviousWidgetInfo(gui_menu)
	local width_screen = GuiGetScreenDimensions(gui_menu)

	GuiLayoutBeginLayer(gui_menu)
	
	local idx = 1
	for perk_id,count in pairs(perks_current) do
		local text = count .. "x"
		local width_text = GuiGetTextDimensions(gui_menu,text,perks_current_scale)
		GuiText(gui_menu, width_text_max - width_text + x, y, text, perks_current_scale)
		x = x + width_text_max
		
		GuiImage(gui_menu, GuiID, x, y, perks_data[perk_id].perk_icon, 1, perks_current_icon_scale)
		GuiID = GuiID + 1
		GuiTooltip(gui_menu, perks_data[perk_id].ui_name, perks_data[perk_id].ui_description)
		
		local _,_,_,x_tmp = GuiGetPreviousWidgetInfo(gui_menu)
		
		if (x_tmp/perks_current_max_width) > width_screen and idx < perks_current_count then
			GuiLayoutEndLayer(gui_menu)
			GuiText(gui_menu, 0, 0, " ", perks_current_scale) --phantom vertical text for next widgets to know where to put themself
			_,_,_,x,y = GuiGetPreviousWidgetInfo(gui_menu)
			GuiLayoutBeginLayer(gui_menu)
		else
			x = x + width_icon + width_space
		end
		idx = idx + 1
	end
	GuiLayoutEndLayer(gui_menu) 
end

function gui_perks_get_current_perks()
	perks_current = {}
	perks_current_count = 0
	perks_current_max_count = 0
	
	for perk_id in pairs(perks_data) do
		local flag_name = get_perk_picked_flag_name(perk_id)
		local pickup_count = tonumber(GlobalsGetValue(flag_name .. "_PICKUP_COUNT", "0"))
		
		if pickup_count > 0 then
			if pickup_count > perks_current_max_count then perks_current_max_count = pickup_count end
			perks_current[perk_id] = pickup_count
			perks_current_count = perks_current_count + 1
		end
	end
end

function gui_perks_show_future_perks()
	local perk_count,index,title,step,showperk,index = nil
	
	if display_reroll then
		showperk = reroll_perks
		title = _T.lamas_stats_perks_reroll
		button = _T.lamas_stats_perks_next
		
		-- index = {}
		if #perks_onscreen > 0 then
			perk_count = #perks_onscreen
		else
			perk_count = tonumber(GlobalsGetValue( "TEMPLE_PERK_COUNT", "3"))
		end
		index = reroll_index
		step = -1
	else
		showperk = future_perks
		title = _T.lamas_stats_perks_next
		button = _T.lamas_stats_perks_reroll
		perk_count = tonumber(GlobalsGetValue( "TEMPLE_PERK_COUNT", "3"))
		step = 1
		index = future_index
	end
	
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	GuiText(gui_menu, 0, 0, "---- " .. title .. " ----", perks_scale)
	if GuiButton(gui_menu, GuiID, 0, 0, "[" .. button .. "]", perks_scale) then
		gui_perks_refresh_perks()
		display_reroll = not display_reroll
	end
	GuiID = GuiID + 1
	
	GuiLayoutEnd(gui_menu)

	for i=1,how_many_into_future do --how many mountains to display
		local index_differential = (perk_count * (i-1)) * step
		GuiLayoutBeginHorizontal(gui_menu,0,0, false)
			for i,idx in ipairs(index) do
				local index_iterator = idx + index_differential
				GuiImage(gui_menu, GuiID, 0, 0, perks_data[showperk[index_iterator]].perk_icon, 1, perks_predict_icon_scale) --displaying img by id
				GuiTooltip(gui_menu, perks_data[showperk[index_iterator]].ui_name, perks_data[showperk[index_iterator]].ui_description)
				GuiID = GuiID + 1
			end
		GuiLayoutEnd(gui_menu)
	end
end

function gui_perks_get_reroll_perks()
	reroll_perks = {} --emptying old array
	local next_perk_index = tonumber(GlobalsGetValue("TEMPLE_REROLL_PERK_INDEX", #perks))
	local perk_count = tonumber(GlobalsGetValue( "TEMPLE_PERK_COUNT", "3"))
	for i=1,how_many_into_future * perk_count do --gathering perks for display, rows * perks per temple
		local perk_id = perks[next_perk_index]
		if perk_id == nil then --if we got empty response, which happens usually when we hit an end of perk deck
			next_perk_index = #perks --starting from start
			perk_id = perks[next_perk_index]
		end
		while perk_id == "" do --the game forcefully sets perk_id into "" if it rolled non-stackable perk, so we are increasing perk index untill we get an valid or null perk
			next_perk_index = next_perk_index - 1
			
			perk_id = perks[next_perk_index]
			
			if perk_id == nil then 
				next_perk_index = #perks
				perk_id = perks[next_perk_index]
			end
		end
		table.insert(reroll_perks, 1, perk_id) 
		next_perk_index = next_perk_index - 1
	end
	reroll_index = {}
	if #perks_onscreen > 0 then
		for i=1, #perks_onscreen do
			table.insert(reroll_index,#reroll_perks - perks_onscreen[i].pos + 1)
		end
	else
		for i=1, perk_count do
			table.insert(reroll_index,#reroll_perks - i + 1)
		end
	end
	
end

function gui_perks_get_future_perks() -- function for calculating future perk and writing them into a variable so we don't have to query them every frame
	future_perks = {} --emptying old array
	local next_perk_index = tonumber(GlobalsGetValue("TEMPLE_NEXT_PERK_INDEX", "1" ))  
	local perk_count = tonumber(GlobalsGetValue( "TEMPLE_PERK_COUNT", "3"))
	for i=1,how_many_into_future * perk_count do --gathering perks for display, rows * perks per temple
		local perk_id = perks[next_perk_index]
		if perk_id == nil then --if we got empty response, which happens usually when we hit an end of perk deck
			next_perk_index = 1 --starting from start
			perk_id = perks[next_perk_index]
		end
		while perk_id == "" do --the game forcefully sets perk_id into "" if it rolled non-stackable perk, so we are increasing perk index untill we get an valid or null perk
			next_perk_index = next_perk_index + 1
			perk_id = perks[next_perk_index]
			if perk_id == nil then --if we got empty response, which happens usually when we hit an end of perk deck
				next_perk_index = 1 --starting from start
				perk_id = perks[next_perk_index]
			end
		end
		
		table.insert(future_perks,perk_id) 
		next_perk_index = next_perk_index + 1
	end
	future_index = {}
	for i=1,perk_count do
		table.insert(future_index,i)
	end
end

function gui_perks_collate_data_perks() --one-time function for gathering name and icons of perks
	perks_data = {}
	for i,perk in ipairs(perk_list) do
		perks_data[perk.id] = {}
		perks_data[perk.id].ui_name = perk.ui_name
		perks_data[perk.id].ui_description = perk.ui_description
		perks_data[perk.id].perk_icon = perk.perk_icon
	end
end

function gui_perks_collate_data_actions() --one-time function for gathering name and icons of perks
	actions_data = {}
	dofile_once("data/scripts/gun/gun_actions.lua")
	for i,action in ipairs(actions) do
		actions_data[action.id] = {}
		actions_data[action.id].name = action.name
		actions_data[action.id].description = action.description
	end
end

function gui_perks_refresh_perks()
	gui_perks_get_current_perks()
	gui_perks_gather_stats()
	
	gui_perks_get_perks_on_screen()	
	
	if ModSettingGet("lamas_stats.enable_future_perks") then
		perks = perk_get_spawn_order()
		gui_perks_get_future_perks()
		gui_perks_get_reroll_perks()
	end
end

gui_perks_collate_data_perks()
gui_perks_collate_data_actions()
