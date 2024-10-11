--- @diagnostic disable: lowercase-global, missing-global-doc, unused-local, redefined-local, unbalanced-assignments, undefined-global
local how_many_into_future = ModSettingGet("lamas_stats.future_perks_amount")
local future_perks, future_index, reroll_index
display_future, display_reroll = false, false
local perks_predict_scale = 1
local perks_predict_icon_scale = 1 * perks_predict_scale

function gui_perks_show_future_perks(gui)
	local perk_count, index, title, step, showperk, index = nil

	if display_reroll then
		showperk = reroll_perks
		title = _T.lamas_stats_perks_reroll
		button = _T.lamas_stats_perks_next

		-- index = {}
		if #perks_onscreen > 0 then
			perk_count = #perks_onscreen
		else
			perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))
		end
		index = reroll_index
		step = -1
	else
		showperk = future_perks
		title = _T.lamas_stats_perks_next
		button = _T.lamas_stats_perks_reroll
		perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))
		step = 1
		index = future_index
	end
	GuiLayoutBeginHorizontal(gui, 0, 0)
	GuiText(gui, 0, 0, "---- " .. title .. " ----", perks_scale)
	if GuiButton(gui, id(), 0, 0, "[" .. button .. "]", perks_scale) then
		gui_perks_refresh_perks()
		display_reroll = not display_reroll
	end
	GuiLayoutEnd(gui)

	for i = 1, how_many_into_future do -- how many mountains to display
		local index_differential = (perk_count * (i - 1)) * step
		GuiLayoutBeginHorizontal(gui, 0, 0)
		for i, idx in ipairs(index) do
			local index_iterator = idx + index_differential
			GuiImage(gui, id(), 0, 0, perks_data[showperk[index_iterator]].perk_icon, 1, perks_predict_icon_scale) -- displaying img by id
			GuiTooltip(gui, perks_data[showperk[index_iterator]].ui_name,
				perks_data[showperk[index_iterator]].ui_description)
		end
		GuiLayoutEnd(gui)
	end
end

function gui_perks_get_reroll_perks()
	reroll_perks = {} -- emptying old array
	local next_perk_index = tonumber(GlobalsGetValue("TEMPLE_REROLL_PERK_INDEX", #perks))
	local perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))
	how_many_into_future = ModSettingGet("lamas_stats.future_perks_amount")
	for i = 1, how_many_into_future * perk_count do -- gathering perks for display, rows * perks per temple
		local perk_id = perks[next_perk_index]
		if perk_id == nil then                -- if we got empty response, which happens usually when we hit an end of perk deck
			next_perk_index = #perks          -- starting from start
			perk_id = perks[next_perk_index]
		end
		while perk_id == "" do -- the game forcefully sets perk_id into "" if it rolled non-stackable perk, so we are increasing perk index untill we get an valid or null perk
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
		for i = 1, #perks_onscreen do
			table.insert(reroll_index, #reroll_perks - perks_onscreen[i].pos + 1)
		end
	else
		for i = 1, perk_count do
			table.insert(reroll_index, #reroll_perks - i + 1)
		end
	end

end

function gui_perks_get_future_perks() -- function for calculating future perk and writing them into a variable so we don't have to query them every frame
	future_perks = {}                 -- emptying old array
	local next_perk_index = tonumber(GlobalsGetValue("TEMPLE_NEXT_PERK_INDEX", "1"))
	local perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))

	how_many_into_future = ModSettingGet("lamas_stats.future_perks_amount")
	for i = 1, how_many_into_future * perk_count do -- gathering perks for display, rows * perks per temple
		local perk_id = perks[next_perk_index]
		if perk_id == nil then                 -- if we got empty response, which happens usually when we hit an end of perk deck
			next_perk_index = 1                -- starting from start
			perk_id = perks[next_perk_index]
		end
		while perk_id == "" do -- the game forcefully sets perk_id into "" if it rolled non-stackable perk, so we are increasing perk index untill we get an valid or null perk
			next_perk_index = next_perk_index + 1
			perk_id = perks[next_perk_index]
			if perk_id == nil then -- if we got empty response, which happens usually when we hit an end of perk deck
				next_perk_index = 1 -- starting from start
				perk_id = perks[next_perk_index]
			end
		end

		table.insert(future_perks, perk_id)
		next_perk_index = next_perk_index + 1
	end
	future_index = {}
	for i = 1, perk_count do
		table.insert(future_index, i)
	end
end
