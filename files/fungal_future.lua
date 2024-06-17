function gui_fungal_shift_insert_future_shifts(i, mats)
	local arr = {}
	arr.flask = ""
	arr.number = i
	arr.from = {}
	for _,mat in ipairs(mats.from.materials) do
		table.insert(arr.from, mat)
		arr.to = mats.to.material
	end
	if mats.from.flask == true then arr.flask = "from" end
	if mats.to.flask == true then 
		arr.flask = "to" 
		arr.greedy_mat = mats.to.greedy_mat
		arr.grass_holy = mats.to.grass_holy
		arr.greedy_success = mats.to.greedy_success
	end
	return arr
end

function gui_fungal_shift_get_future_shifts()
	future_shifts = {}
	current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))

	for i=current_shifts+1,maximum_shifts,1 do
		local seed_shifts = gui_fungal_shift_get_seed_shifts(i)
		future_shifts[i] = gui_fungal_shift_insert_future_shifts(i, seed_shifts)
		if seed_shifts.failed ~= nil then 
			future_shifts[i].failed = gui_fungal_shift_insert_future_shifts(i, seed_shifts.failed) 
		else
			future_shifts[i].failed = nil
		end
	end
end

function gui_fungal_shift_display_future_shifts()
	local nextshifttext = _T.lamas_stats_fungal_next_shift
	
	if current_shifts < maximum_shifts then
		GuiText(gui_menu, 0, 0, "---- " .. nextshifttext .. " ----",fungal_shift_scale)
	end

	for i=current_shifts+1,maximum_shifts,1 do
		GuiLayoutBeginHorizontal(gui_menu,0,0,0,0,0)
		GuiText(gui_menu, 0, 0, _T.lamas_stats_shift .. " " .. tostring(future_shifts[i].number) .. ": ", fungal_shift_scale)
		
		gui_fungal_shift_display_from(future_shifts[i])
		gui_fungal_shift_display_to(future_shifts[i])
		GuiLayoutEnd(gui_menu)
		
		if future_shifts[i].failed ~= nil then --if there could be a failed attempt then say so
			GuiLayoutBeginHorizontal(gui_menu,0,0,0,0,0)
			GuiText(gui_menu, 0, 0, _T.lamas_stats_fungal_if_fail .. " ", fungal_shift_scale)
			gui_fungal_shift_add_potion_icon()
			GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot("$item_potion"),fungal_shift_scale)
			GuiText(gui_menu, 0, 0, " " .. _T.lamas_stats_or .. " ", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(future_shifts[i].to)
			GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[future_shifts[i].to].name) .. ":", fungal_shift_scale)
			GuiLayoutEnd(gui_menu)
			
			GuiLayoutBeginHorizontal(gui_menu,0,0,0,0,0)
			GuiText(gui_menu, 0, 0, _T.lamas_stats_shift .. " " .. tostring(future_shifts[i].number) .. ": ", fungal_shift_scale)
			gui_fungal_shift_display_from(future_shifts[i].failed)
			gui_fungal_shift_display_to(future_shifts[i].failed)	
			GuiLayoutEnd(gui_menu)
		end
		if i == current_shifts+1 and i < maximum_shifts then
			GuiLayoutBeginHorizontal(gui_menu,0,0,0,0,0)
			GuiText(gui_menu, 0, 0, "---- ",fungal_shift_scale) 
			GuiText(gui_menu, GuiGetTextDimensions(gui_menu, nextshifttext, fungal_shift_scale), 0, " ----",fungal_shift_scale)
			GuiLayoutEnd(gui_menu)
		end
	end	
end