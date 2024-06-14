dofile_once("data/scripts/magic/fungal_shift.lua") --for materials list

local past_shifts = {} --table of past shifts (real one)
local future_shifts = {} --table of future shifts
local fungal_shift_scale = ModSettingGet("lamas_stats.fungal_scale")

function gui_fungal_shift()
	local gui_id = 1000
	function id()
		gui_id = gui_id + 1
		return gui_id
	end
	
	GuiBeginAutoBox(gui_menu)
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y, false, 0, 0) --layer1
	GuiZSet(gui_menu,900)

	GuiText(gui_menu, 0, 0, "==== " .. _T.FungalShifts .. " ====", fungal_shift_scale)
	
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	gui_menu_switch_button(gui_menu, id(), fungal_shift_scale, gui_menu_main_display_loop) --return

	gui_do_refresh_button(gui_menu, id(), fungal_shift_scale, gui_fungal_shift_get_shifts)

	if current_shifts ~= tonumber(GlobalsGetValue("fungal_shift_iteration", "0")) then
		gui_fungal_shift_get_shifts()
	end

	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		gui_fungal_show_aplc_recipes()
	end
	local cooldown = GetFungalCooldown()
	if cooldown > 0 then
		GuiImage(gui_menu, id(), -5, -1, fungal_png, 1, 0.7 * fungal_shift_scale)
		GuiText(gui_menu, 0, 0, _T.lamas_stats_fungal_cooldown .. " " .. cooldown, fungal_shift_scale)
	end
	GuiLayoutEnd(gui_menu)
	if ModSettingGet("lamas_stats.enable_fungal_past") then
		gui_fungal_shift_display_past_shifts()
	end
	if ModSettingGet("lamas_stats.enable_fungal_future") then
		gui_fungal_shift_display_future_shifts()
	end
	GuiLayoutEnd(gui_menu) --layer1

	GuiZSetForNextWidget(gui_menu, 1000)
	GuiEndAutoBoxNinePiece(gui_menu, 1, 130, 0, false, 0, screen_png, screen_png)
	
end

function UpdateFungalVariables()
	fungal_shift_scale = ModSettingGet("lamas_stats.fungal_scale")
	gui_fungal_shift_get_shifts()
end

function gui_fungal_show_aplc_recipes()
	GuiBeginAutoBox(gui_menu)
	GuiText(gui_menu, 0, 0, "[", fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon("midas_precursor")
	gui_fungal_shift_add_color_potion_icon("magic_liquid_hp_regeneration_unstable")
	GuiText(gui_menu, 0, 0, "]", fungal_shift_scale)
	GuiEndAutoBoxNinePiece(gui_menu,0,0,0,0,0,empty_png,empty_png)
	GuiTooltipLamas(gui_menu, 50, 0, 900, gui_fungal_show_aplc_recipes_tooltip)
end

function gui_fungal_show_aplc_recipes_tooltip()
	gui_fungal_show_aplc_recipes_tooltip_add_recipe("midas_precursor", APLC_table.ap)
	gui_fungal_show_aplc_recipes_tooltip_add_recipe("magic_liquid_hp_regeneration_unstable", APLC_table.lc)
end

function gui_fungal_show_aplc_recipes_tooltip_add_recipe(mat_id, mat_table)
	GuiLayoutBeginHorizontal(gui_menu, 0, 0)
	GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat_id].name), fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon(mat_id)
	GuiText(gui_menu, 0, 0, "->", fungal_shift_scale)
	for _,material in ipairs(mat_table) do
		GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material].name), fungal_shift_scale)
		gui_fungal_shift_add_color_potion_icon(material)
	end
	GuiLayoutEnd(gui_menu)
end

function gui_fungal_shift_get_seed_shifts(iter, convert_tries, mat_from, mat_to) --calculate shifts based on seed (code is copied from game itself)
	local _from, _to = nil, nil
    local converted_any = false
    local convert_tries = convert_tries or 0

    while converted_any == false and convert_tries < maximum_shifts do
        local seed2 = 42345 + iter - 1 + 1000*convert_tries --minus one for consistency with other objects
		if ModIsEnabled("Apotheosis") then --aphotheosis used old mechanic
			seed2 = 58925 + iter - 1 + convert_tries
		end
        SetRandomSeed(89346, seed2)
        local rnd = random_create( 9123, seed2 )
        local from = pick_random_from_table_weighted(rnd, materials_from)
        local to = pick_random_from_table_weighted(rnd, materials_to)

        _from = {
            flask = false,
            -- probability = from.probability,
            materials = mat_from or from.materials,
			
        }
        _to = {
            flask = false,
            -- probability = to.probability,
            material = mat_to or to.material,
            greedy_mat = "gold",
            grass_holy = "grass",
			greedy_success = false,
        }
		_failed = nil

		-- if a potion or pouch is equipped, randomly use main material from it as one of the materials
        if random_nexti( rnd, 1, 100 ) <= 75 then -- chance to use flask
            if random_nexti( rnd, 1, 100 ) <= 50 then -- which side will use flask
                _from.flask = true
            else
                _to.flask = true
				if greedy_materials ~= nil then --compatibility with mods?
					-- heh he
					if random_nexti( rnd, 1, 1000 ) ~= 1 then
						_to.greedy_mat = random_from_array(greedy_materials)
						_to.grass_holy = "grass"
					else
						_to.greedy_mat = "gold"
						_to.grass_holy = "grass_holy"
						_to.greedy_success = true
					end
				end
            end
        end
		
		local same_mat = 0
		local apotheosis_cursed_liquid_red_arr = {}
		
		-- local failed_flag = false
		for i=1, #_from.materials do
			if _from.materials[i] == _to.material then
				same_mat = same_mat + 1
			end	
			
			if ModIsEnabled("Apotheosis") then --damn it's ugly
				if _from.materials[i] == "apotheosis_cursed_liquid_red_static" or _from.materials[i] == "apotheosis_cursed_liquid_red" then
					table.insert(apotheosis_cursed_liquid_red_arr, _from.materials[i])
					table.insert(apotheosis_cursed_liquid_red_arr,"apotheosis_cursed_liquid_red_static")
					table.insert(apotheosis_cursed_liquid_red_arr,"apotheosis_cursed_liquid_red")
				end
			end
		end
		
		if same_mat == #_from.materials then --if conversion failed
			if _from.flask or _to.flask then --if flask shift is available
				_failed = gui_fungal_shift_get_seed_shifts(iter, convert_tries + 1)
				converted_any = true
			else
				if ModIsEnabled("Apotheosis") then --damn it's ugly
					_from = {materials ={"fail"}}
					_to = {material = "fail"}
					_failed = nil
					converted_any = true
				end
			end
		else
			converted_any = true
		end
		
        convert_tries = convert_tries + 1
		
		if apotheosis_cursed_liquid_red_arr[1] then --if it was cured liquid from apo
			_from.materials = apotheosis_cursed_liquid_red_arr
		end
    end

    if not converted_any then
        GamePrint(_T.lamas_stats_fungal_predict_error .. " " .. tostring(iter))
    end

    return {from=_from, to=_to, failed = _failed}
end

function gui_fungal_shift_display_from(material)
	GuiBeginAutoBox(gui_menu)
	local tooltiptext = ""
	if material.flask == "from" then --if flask was flagged
		if current_shifts < material.number then --if it's future shift
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_possible .. "\n"
			gui_fungal_shift_add_flask_shift()
			if material.failed ~= nil then
				GuiEndAutoBoxNinePiece(gui_menu,0,0,0,0,0,empty_png,empty_png)
				GuiTooltip(gui_menu,"",tooltiptext)
				return
			end
		else
			GuiColorSetForNextWidget(gui_menu, 1, 1, 0.698, 1)
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_used .. "\n"
		end
	end

	if ModSettingGet("lamas_stats.fungal_group_type") == "group" then
		if #material.from > 1 then
			GuiText(gui_menu, 0, 0, _T.lamas_stats_fungal_group_of, fungal_shift_scale)
		else
			GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.from[1]].name), fungal_shift_scale)
		end
	end
	
	for i,mat in ipairs(material.from) do
		if ModSettingGet("lamas_stats.fungal_group_type") == "full" then
			GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		end
		gui_fungal_shift_add_color_potion_icon(mat)
		tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot(original_material_properties[mat].name)
		tooltiptext = tooltiptext .. ", " .. _T.lamas_stats_ingame_name .. (": ") .. mat .. "\n"
	end

	GuiEndAutoBoxNinePiece(gui_menu,0,0,0,0,0,empty_png,empty_png)

	GuiTooltip(gui_menu,"",tooltiptext)
end

function gui_fungal_shift_display_to(material)	
	GuiText(gui_menu, 0, 0, "-> ", fungal_shift_scale)
	
	local tooltiptext = ""
	local material_to = GameTextGetTranslatedOrNot(original_material_properties[material.to].name)
	local show_to = true
	GuiBeginAutoBox(gui_menu)
	if material.flask == "to" then
		if current_shifts < material.number then --if it's future shift
			gui_fungal_shift_add_potion_icon()
			GuiColorSetForNextWidget(gui_menu, 1, 0.2, 0, 1)
			
			if material.failed ~= nil then
				material_to = GameTextGetTranslatedOrNot("$item_potion")
				show_to = false
			else
				GuiText(gui_menu, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
			end
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_possible .. "\n"
			if ModSettingGet("lamas_stats.enable_fungal_greedy_tip") then
				tooltiptext = tooltiptext .. _T.lamas_stats_fungal_greedy .. "\n"
			end
			if ModSettingGet("lamas_stats.enable_fungal_greedy_gold") then
				tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot("$mat_gold") .. " -> "
				tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot(original_material_properties[material.greedy_mat].name) .. "\n"
			end
			if ModSettingGet("lamas_stats.enable_fungal_greedy_grass") then
				tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot("$mat_grass_holy") .. " -> "
				tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot(original_material_properties[material.grass_holy].name) .. "\n"
			end
			if material.greedy_success then
				GuiColorSetForNextWidget(gui_menu, 0.7, 0.2, 1, 1)
			end
		else --past shift
			GuiColorSetForNextWidget(gui_menu, 1, 1, 0.698, 1)
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_used .. "\n"
		end
	end
	
	GuiText(gui_menu, 0, 0, material_to, fungal_shift_scale)
	

	if show_to then
		gui_fungal_shift_add_color_potion_icon(material.to)
		tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot(original_material_properties[material.to].name)
		tooltiptext = tooltiptext .. ", " .. _T.lamas_stats_ingame_name .. (": ") .. material.to .. "\n"
	end
	
	GuiEndAutoBoxNinePiece(gui_menu,0,0,0,0,0,empty_png,empty_png)
	GuiTooltip(gui_menu,"",tooltiptext)
	GuiText(gui_menu, 0, 0, "", fungal_shift_scale)
end

function gui_fungal_shift_add_flask_shift()
	gui_fungal_shift_add_potion_icon()
	GuiColorSetForNextWidget(gui_menu, 1, 0.2, 0, 1)
	GuiText(gui_menu, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
end

function gui_fungal_shift_get_past_shifts()
	past_shifts = {}
	local past_materials = ComponentGetValue2(worldcomponent, "changed_materials")
	local shift_number = 1

	current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
	if current_shifts > maximum_shifts then current_shifts = maximum_shifts end
	for i=1,current_shifts,1 do
		local seed_shifts = gui_fungal_shift_get_seed_shifts(i) --getting shift by seed
		
		past_shifts[i] = {}
		past_shifts[i].flask = ""
		past_shifts[i].number = i
		past_shifts[i].from = {}

		if seed_shifts.to.material == "fail" then
			past_shifts[i].to = "lamas_failed_shift"
			table.insert(past_shifts[i].from, "lamas_failed_shift")
			goto continue
		end

		past_shifts[i].to = past_materials[shift_number+1]
		
--[[	additional check for failed shifts, mainly if shift was happened using "from" flask into the same "to" material ]]
		if seed_shifts.from.flask then
			local temp_failed_shift = gui_fungal_shift_get_seed_shifts(i, 1) --getting next iteration of seed shift 
			local fullmatch = 0 --how many times there was an match between real shift and "failed" shift
			for ii,mat in ipairs(temp_failed_shift.from.materials) do
				local iter = 2*(ii - 1)
				--if real shift is identical to "failed" shift
				if mat == past_materials[shift_number+iter] then 
					fullmatch = fullmatch + 1
				else
					break
				end
			end
			if fullmatch == #temp_failed_shift.from.materials then 
				-- past_shifts[i].flask = "from_fail" --todo add display of failed shift
				past_shifts[i].from = temp_failed_shift.from.materials
				shift_number = shift_number + (#past_shifts[i].from) * 2 
				goto continue
			end
		end
--[[	excluding same materials ]]
		local unique_from = {}
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
				end
			else
				table.insert(past_shifts[i].from, past_materials[shift_number])
				shift_number = shift_number + 2
			end
		end
		::continue::
	end
end

function gui_fungal_shift_display_past_shifts()
	for _,past_shift in ipairs(past_shifts) do
		GuiLayoutBeginHorizontal(gui_menu,0,0,0,0,0)
		GuiText(gui_menu, 0, 0, _T.lamas_stats_shift .. " " .. tostring(past_shift.number) .. ": ", fungal_shift_scale)
		
		gui_fungal_shift_display_from(past_shift)

		gui_fungal_shift_display_to(past_shift)
		
		GuiLayoutEnd(gui_menu)
				
	end	
end

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
		arr.grass_holy = mats.grass_holy
		arr.greedy_success = mats.to.greedy_success
	end
	
	return arr
end

function gui_fungal_shift_get_future_shifts()
	future_shifts = {}
	current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))

	for i=current_shifts+1,maximum_shifts,1 do
	
		-- print(
		local seed_shifts = gui_fungal_shift_get_seed_shifts(i)
		local from_mat = seed_shifts.from.materials --getting shift by seed
		local from_mat_n = #from_mat --getting number of materials that was shifted
		local to_mat = seed_shifts.to.material

		future_shifts[i] = gui_fungal_shift_insert_future_shifts(i, seed_shifts)
		-- print(tostring(future_shifts[i].failed))
		-- debug_print_table(future_shifts[i].failed)
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

function gui_fungal_shift_get_shifts()
	gui_fungal_shift_get_past_shifts()
	if ModSettingGet("lamas_stats.enable_fungal_future") then
		gui_fungal_shift_get_future_shifts()
	end
end

function gui_fungal_shift_add_color_potion_icon(material)
	-- SetColor(original_material_properties[material].color)
	-- debug_print_table(original_material_properties[material])
	-- original_material_properties[material].icon
	gui_fungal_shift_add_potion_icon(original_material_properties[material].icon)
	
end

function gui_fungal_shift_add_potion_icon(icon)
	-- print(icon)
	icon = icon or potion_png
	GuiImage(gui_menu, id(), 0, 0, icon, 1, fungal_shift_scale)
end

function SetColor(material)
	GuiColorSetForNextWidget(gui_menu,material.red,material.green,material.blue,material.alpha)
end


