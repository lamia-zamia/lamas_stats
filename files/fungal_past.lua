function gui_fungal_shift_get_past_shifts()
	past_shifts = {}
	local past_materials = ComponentGetValue2(worldcomponent, "changed_materials")
	local shift_number = 1
	current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
	if current_shifts > maximum_shifts then current_shifts = maximum_shifts end
	for i=1,current_shifts,1 do
		local seed_shifts = gui_fungal_shift_get_seed_shifts(i) --getting shift by seed
		local unique_from = {}
		
		past_shifts[i] = {}
		past_shifts[i].flask = ""
		past_shifts[i].number = i
		past_shifts[i].from = {}
		if seed_shifts.to.material == "fail" or past_materials[shift_number+1] == nil then
			past_shifts[i].to = "lamas_failed_shift"
			table.insert(past_shifts[i].from, "lamas_failed_shift")
			past_shifts[i].flask = "lamas_failed_shift"
			goto continue
		end
		past_shifts[i].to = past_materials[shift_number+1]
	--[[	additional check for failed shifts, mainly if shift was happened using "from" flask into the same "to" material ]]
		if seed_shifts.from.flask or seed_shifts.to.flask then
			local temp_failed_shift = gui_fungal_shift_calculate_if_fail(i, seed_shifts)
			local fullmatch = 0 --how many times there was an match between real shift and "failed" shift
			for ii,mat in ipairs(temp_failed_shift.from.materials) do
				local iter = 2*(ii - 1)
				--if real shift is identical to "failed" shift
				if mat == past_materials[shift_number+iter] and past_materials[shift_number+1] == past_materials[shift_number+iter+1] then 
					fullmatch = fullmatch + 1
				else
					break
				end
			end
			if fullmatch == #temp_failed_shift.from.materials then
				if not ModIsEnabled("Apotheosis") then
					past_shifts[i].flask = "from_fail" 
				end
				past_shifts[i].from = temp_failed_shift.from.materials
				shift_number = shift_number + (#past_shifts[i].from) * 2 
				goto continue
			end
		end
	--[[	excluding same materials ]]
		for _,mat in ipairs(seed_shifts.from.materials ) do --adding materials that was shifted except for same material
			if #seed_shifts.from.materials  > 1 then 
				if mat ~= past_shifts[i].to then
					table.insert(unique_from, mat)
				end
			else
				table.insert(unique_from, mat)
			end
		end
	--[[	checking if shifted to is different from seed ]]
		if past_shifts[i].to ~= seed_shifts.to.material then --if "to" material is not the same as in seed
			if seed_shifts.to.flask then 
				past_shifts[i].flask = "to" 
				past_shifts[i].from = unique_from
				shift_number = shift_number + (#past_shifts[i].from) * 2 
				goto continue
			end
		end
	--[[	checking if shifted from is different from seed ]]
		for j,mat in ipairs(unique_from) do
			if past_materials[shift_number] ~= mat then
				if seed_shifts.from.flask then
					past_shifts[i].flask = "from" 
					if j == 1 then --foolproofing cases where first material matching shifted material
						table.insert(past_shifts[i].from, past_materials[shift_number])
						shift_number = shift_number + 2 
					end
					break
				else
					table.insert(past_shifts[i].from, past_materials[shift_number])
					shift_number = shift_number + 2
				end
			else
				table.insert(past_shifts[i].from, past_materials[shift_number])
				shift_number = shift_number + 2
				if past_shifts[i].to ~= past_materials[shift_number+1] then --failproof cases where failed shifts are identical to true shift
					break
				end
			end
		end
		::continue::
	end
end

function gui_fungal_shift_display_past_shifts(gui)
	for _,past_shift in ipairs(past_shifts) do
		if past_shift.flask ~= "lamas_failed_shift" then 
			GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
			GuiText(gui, 0, 0, _T.lamas_stats_shift .. " " .. tostring(past_shift.number) .. ": ", fungal_shift_scale)
			gui_fungal_shift_display_from(gui, past_shift)
			gui_fungal_shift_display_to(gui, past_shift)
			GuiLayoutEnd(gui)	
		end
	end	
end