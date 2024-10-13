local predict = {}

-- function gui_perks_get_future_perks() -- function for calculating future perk and writing them into a variable so we don't have to query them every frame
-- 	future_perks = {}                 -- emptying old array
-- 	local next_perk_index = tonumber(GlobalsGetValue("TEMPLE_NEXT_PERK_INDEX", "1"))
-- 	local perk_count = tonumber(GlobalsGetValue("TEMPLE_PERK_COUNT", "3"))

-- 	how_many_into_future = ModSettingGet("lamas_stats.future_perks_amount")
-- 	for i = 1, how_many_into_future * perk_count do -- gathering perks for display, rows * perks per temple
-- 		local perk_id = perks[next_perk_index]
-- 		if perk_id == nil then                 -- if we got empty response, which happens usually when we hit an end of perk deck
-- 			next_perk_index = 1                -- starting from start
-- 			perk_id = perks[next_perk_index]
-- 		end
-- 		while perk_id == "" do -- the game forcefully sets perk_id into "" if it rolled non-stackable perk, so we are increasing perk index untill we get an valid or null perk
-- 			next_perk_index = next_perk_index + 1
-- 			perk_id = perks[next_perk_index]
-- 			if perk_id == nil then -- if we got empty response, which happens usually when we hit an end of perk deck
-- 				next_perk_index = 1 -- starting from start
-- 				perk_id = perks[next_perk_index]
-- 			end
-- 		end

-- 		table.insert(future_perks, perk_id)
-- 		next_perk_index = next_perk_index + 1
-- 	end
-- 	future_index = {}
-- 	for i = 1, perk_count do
-- 		table.insert(future_index, i)
-- 	end
-- end
