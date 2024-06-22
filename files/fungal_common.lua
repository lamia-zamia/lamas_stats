dofile_once("data/scripts/magic/fungal_shift.lua") --for materials list

local function SetColor(material)
	GuiColorSetForNextWidget(gui_menu,material.red,material.green,material.blue,material.alpha)
end

function gui_fungal_shift_add_potion_icon(gui, icon)
	icon = icon or potion_png
	GuiImage(gui, id(), 0, 0, icon, 1, fungal_shift_scale)
end

function gui_fungal_shift_add_color_potion_icon(gui, material)
	if original_material_properties[material].icon == potion_png then
		SetColor(original_material_properties[material].color)
	end
	gui_fungal_shift_add_potion_icon(gui, original_material_properties[material].icon)
end

function gui_fungal_shift_tooltip_diplay_failed_shift(gui, material, if_mat)
	if ModIsEnabled("Apotheosis") then
		if material.flask == "to" and #material.from > 1 then return end
		GuiLayoutAddVerticalSpacing(gui, 4)
		GuiLayoutBeginHorizontal(gui, 0, 0)
		GuiTextGray(gui, 0, 0, "*" .. _T.lamas_stats_if, fungal_shift_scale)
		gui_fungal_shift_add_potion_icon(gui)
		GuiTextGray(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
		GuiTextGray(gui, 0, 0, "=", fungal_shift_scale)
		gui_fungal_shift_add_color_potion_icon(gui, if_mat)
		GuiTextGray(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[if_mat].name), fungal_shift_scale)
		GuiTextGray(gui, 0, 0, ": " .. _T.lamas_stats_fungal_failed, fungal_shift_scale)
		GuiLayoutEnd(gui)
		return
	end
	if material.failed then 
		local return_flag = (material.failed.flask == "" or (material.failed.from[1] == material.from[1]))
		GuiLayoutAddVerticalSpacing(gui, 4)
		GuiLayoutBeginHorizontal(gui, 0, 0)
		GuiTextGray(gui, 0, 0, "*" .. _T.lamas_stats_fungal_if_fail, fungal_shift_scale)
		gui_fungal_shift_add_potion_icon(gui)
		GuiTextGray(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
		if return_flag then
			GuiTextGray(gui, 0, 0, "" .. _T.lamas_stats_or, fungal_shift_scale)
			gui_fungal_shift_add_potion_icon(gui)
			GuiTextGray(gui, 0, 0, "=", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(gui, if_mat)
			GuiTextGray(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[if_mat].name), fungal_shift_scale)
		end
		GuiTextGray(gui, 0, 0, ":", fungal_shift_scale)
		GuiLayoutEnd(gui)
		GuiLayoutBeginHorizontal(gui, 0, 0)
		for _,mat in ipairs(material.failed.from) do
			gui_fungal_shift_add_color_potion_icon(gui, mat)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		end
		GuiTextGray(gui, 0, 0, "->", fungal_shift_scale)
		gui_fungal_shift_add_color_potion_icon(gui, material.failed.to)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.failed.to].name), fungal_shift_scale)
		GuiLayoutEnd(gui) 
		if return_flag then return end
	end
	local fail_mat = material.failed
	if material.if_fail then fail_mat = material.if_fail end
	if (fail_mat) == nil or (fail_mat.flask == "" and material.failed) then return end 
	GuiLayoutAddVerticalSpacing(gui, 4)
	GuiLayoutBeginHorizontal(gui, 0, 0)
	GuiTextGray(gui, 0, 0, _T.lamas_stats_if, fungal_shift_scale)
	gui_fungal_shift_add_potion_icon(gui)
	GuiTextGray(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
	GuiTextGray(gui, 0, 0, "=", fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon(gui, if_mat)
	GuiTextGray(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[if_mat].name), fungal_shift_scale)
	GuiTextGray(gui, 0, 0, ":", fungal_shift_scale)
	GuiLayoutEnd(gui)
	GuiLayoutBeginHorizontal(gui, 0, 0)
	if fail_mat.flask == "from" then 
		gui_fungal_shift_add_color_potion_icon(gui, if_mat)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[if_mat].name), fungal_shift_scale)
	else
		for _,mat in ipairs(fail_mat.from) do
			gui_fungal_shift_add_color_potion_icon(gui, mat)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		end
	end
	GuiTextGray(gui, 0, 0, "->", fungal_shift_scale)
	if fail_mat.flask == "to" then
		gui_fungal_shift_add_color_potion_icon(gui, if_mat)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[if_mat].name), fungal_shift_scale)
	else
		gui_fungal_shift_add_color_potion_icon(gui, fail_mat.to)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[fail_mat.to].name), fungal_shift_scale)
	end
	GuiLayoutEnd(gui)
end

local function gui_fungal_shift_calculate_if_fail_to_flask_check(if_fail, current_shift)
	local statement1 = if_fail.from.flask and #current_shift.from.materials == 1 and current_shift.from.materials[1] == if_fail.to.material
	local statement2 = if_fail.to.flask and #current_shift.from.materials == 1 and current_shift.from.materials[1] == if_fail.from.materials[1]
	local result = statement1 or statement2
	return result
end

local function gui_fungal_shift_calculate_if_fail_from_flask_check(if_fail, current_shift)
	local statement1 = if_fail.from.flask and current_shift.to.material == if_fail.to.material
	local statement2 = if_fail.to.flask and #if_fail.from.materials == 1 and current_shift.to.material == if_fail.from.materials[1]
	local result = statement1 or statement2
	return result
end

function gui_fungal_shift_calculate_if_fail(i, current_shift)
	local convert_tries = 1
	local if_fail = gui_fungal_shift_get_seed_shifts(i, convert_tries)
	if current_shift.to.flask then
		while (gui_fungal_shift_calculate_if_fail_to_flask_check(if_fail, current_shift)) do
			convert_tries = convert_tries + 1
			if_fail = gui_fungal_shift_get_seed_shifts(i, convert_tries)
		end 
	end
	if current_shift.from.flask then
		while (gui_fungal_shift_calculate_if_fail_from_flask_check(if_fail, current_shift)) do
			convert_tries = convert_tries + 1
			if_fail = gui_fungal_shift_get_seed_shifts(i, convert_tries)
		end
	end
	return if_fail
end

function gui_fungal_shift_get_seed_shifts(iter, convert_tries) --calculate shifts based on seed (code is copied from game itself)
	local _from, _to = nil, nil
	local converted_any = false
	local convert_tries = convert_tries or 0

	while converted_any == false and convert_tries < maximum_shifts do
		local seed2 = 42345 + iter - 1 + 1000*convert_tries --minus one for consistency with other objects
		if ModIsEnabled("Apotheosis") then --aphotheosis uses old mechanic
			seed2 = 58925 + iter - 1 + convert_tries
		end
		SetRandomSeed(89346, seed2)
		local rnd = random_create( 9123, seed2 )
		local from = pick_random_from_table_weighted(rnd, materials_from)
		local to = pick_random_from_table_weighted(rnd, materials_to)

		_from = {
			flask = false,
			-- probability = from.probability,
			materials = from.materials,
			
		}
		_to = {
			flask = false,
			-- probability = to.probability,
			material = to.material,
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

--[[	Display APLC]]
function gui_fungal_show_aplc_recipes(gui)
	GuiBeginAutoBox(gui)
	GuiText(gui, 0, 0, "[", fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon(gui, "midas_precursor")
	gui_fungal_shift_add_color_potion_icon(gui, "magic_liquid_hp_regeneration_unstable")
	GuiText(gui, 0, 0, "]", fungal_shift_scale)
	GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
	GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_show_aplc_recipes_tooltip)
end

function gui_fungal_show_aplc_recipes_tooltip(gui)
	gui_fungal_show_aplc_recipes_tooltip_add_recipe(gui, "midas_precursor", APLC_table.ap, APLC_table.app)
	GuiLayoutAddVerticalSpacing(gui, 4)
	gui_fungal_show_aplc_recipes_tooltip_add_recipe(gui, "magic_liquid_hp_regeneration_unstable", APLC_table.lc, APLC_table.lcp)
end

function gui_fungal_show_aplc_recipes_tooltip_add_recipe(gui, mat_id, mat_table, mat_prob)
	GuiLayoutBeginHorizontal(gui, 0, 0)
	gui_fungal_shift_add_color_potion_icon(gui, mat_id)
	GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat_id].name), fungal_shift_scale)
	GuiText(gui, 0, 0, mat_prob .. "%", fungal_shift_scale)
	GuiLayoutEnd(gui)
	for i,material in ipairs(mat_table) do
		GuiLayoutBeginHorizontal(gui, 0, 0)
		GuiText(gui, 0, 0, "  -", fungal_shift_scale)
		gui_fungal_shift_add_color_potion_icon(gui, material)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material].name), fungal_shift_scale)
		if i == 2 then GuiTextGray(gui, 0, 0, "^", fungal_shift_scale) end
		GuiTextGray(gui, 0, 0, " (" .. _T.lamas_stats_ingame_name .. ": " .. material .. ")", fungal_shift_scale)
		GuiLayoutEnd(gui)
	end
end
--[[	Display From Tooltip]]
function gui_fungal_shift_display_from_tooltip(gui, material)
	GuiLayoutBeginVertical(gui, 0, 0)
	for _,mat in ipairs(material.from) do
		GuiLayoutBeginHorizontal(gui, 0, 0)
		gui_fungal_shift_add_color_potion_icon(gui, mat)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		GuiTextGray(gui, 0, 0, " (" .. _T.lamas_stats_ingame_name .. ": " .. mat .. ")", fungal_shift_scale)
		GuiLayoutEnd(gui)
	end
	if material.flask == "from" then
		GuiLayoutBeginHorizontal(gui, 0, 0)
		gui_fungal_shift_add_potion_icon(gui)
		if current_shifts < material.number then
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_possible .. "!", fungal_shift_scale)
			GuiLayoutEnd(gui)
			gui_fungal_shift_tooltip_diplay_failed_shift(gui, material, material.to)
		else
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_used, fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
	end
	if material.flask == "from_fail" then 
		GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_failed, fungal_shift_scale)
	end
	GuiLayoutEnd(gui)
end
--[[	Display From]]
function gui_fungal_shift_display_from(gui, material)
	GuiBeginAutoBox(gui)
	if material.flask == "from" then --if flask was flagged
		if current_shifts < material.number then --if it's future shift
			gui_fungal_shift_add_potion_icon(gui)
			if material.failed == nil then
				GuiTextRed(gui, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
			else 
				GuiTextRed(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
				GuiText(gui, 0, 0, "*", fungal_shift_scale)
				GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
				GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_shift_display_from_tooltip, material)
				return
			end
		else
			GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
		end
	end

	if material.flask == "from_fail" then
		GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
	end

	if ModSettingGet("lamas_stats.fungal_group_type") == "group" then
		if #material.from > 1 then
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_group_of, fungal_shift_scale)
		else
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.from[1]].name), fungal_shift_scale)
		end
	end
	
	for _,mat in ipairs(material.from) do
		if ModSettingGet("lamas_stats.fungal_group_type") == "full" then
			if material.flask == "from_fail" then GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1) end
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		end
		gui_fungal_shift_add_color_potion_icon(gui, mat)
	end

	GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
	GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_shift_display_from_tooltip, material)
end
--[[	Display To Tooltip]]
function gui_fungal_shift_display_to_tooltip_greedy(gui, material)
	if not ModIsEnabled("Apotheosis") then
		local gold = ModSettingGet("lamas_stats.enable_fungal_greedy_gold")
		local grass = ModSettingGet("lamas_stats.enable_fungal_greedy_grass")
		if gold or grass then 
			GuiLayoutAddVerticalSpacing(gui, 4)
		else return end
		if ModSettingGet("lamas_stats.enable_fungal_greedy_tip") then
			GuiTextGray(gui, 0, 0, _T.lamas_stats_fungal_greedy, fungal_shift_scale)
		end
		if gold then
			GuiLayoutBeginHorizontal(gui, 0, 0)
			gui_fungal_shift_add_color_potion_icon(gui, "gold")
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot("$mat_gold") .. " ->", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(gui, material.greedy_mat)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.greedy_mat].name), fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
		if grass then
			GuiLayoutBeginHorizontal(gui, 0, 0)
			gui_fungal_shift_add_color_potion_icon(gui, "grass_holy")
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot("$mat_grass_holy") .. " ->", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(gui, material.grass_holy)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.grass_holy].name), fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
	end
end

function gui_fungal_shift_display_to_tooltip(gui, material)
	GuiLayoutBeginVertical(gui, 0, 0)
	
	if material.failed == nil or material.flask == "from" then
		GuiLayoutBeginHorizontal(gui, 0, 0)
		gui_fungal_shift_add_color_potion_icon(gui, material.to)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.to].name), fungal_shift_scale)
		GuiTextGray(gui, 0, 0, " (" .. _T.lamas_stats_ingame_name .. ": " .. material.to .. ")", fungal_shift_scale)
		GuiLayoutEnd(gui)
	end
	
	if material.flask == "to" then
		GuiLayoutBeginHorizontal(gui, 0, 0)
		gui_fungal_shift_add_potion_icon(gui)
		if current_shifts < material.number then
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_possible .. "!", fungal_shift_scale)
			GuiLayoutEnd(gui)
			gui_fungal_shift_tooltip_diplay_failed_shift(gui, material, material.from[1])
			gui_fungal_shift_display_to_tooltip_greedy(gui, material)
		else
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_used, fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
	end
	GuiLayoutEnd(gui)
end
--[[	Display To]]
function gui_fungal_shift_display_to(gui, material)	
	GuiText(gui, 0, 0, "->", fungal_shift_scale)
	GuiBeginAutoBox(gui)
	if material.flask == "to" then
		if current_shifts < material.number then --if it's future shift
			gui_fungal_shift_add_potion_icon(gui)
			if material.greedy_success then	GuiColorSetForNextWidget(gui, 0.7, 0.2, 1, 1)
			else GuiColorSetForNextWidget(gui, 1, 0.2, 0, 1) end
			if material.failed == nil then 
				GuiText(gui, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale) 
			else
				GuiText(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
				GuiText(gui, 0, 0, "* ", fungal_shift_scale)
				GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
				GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_shift_display_to_tooltip, material)
				return
			end
		else --past shift
			GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
		end
	end
	
	GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.to].name), fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon(gui, material.to)
	
	GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
	GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_shift_display_to_tooltip, material)
	GuiText(gui, 0, 0, "", fungal_shift_scale)
end