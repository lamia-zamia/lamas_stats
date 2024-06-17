dofile_once("data/scripts/magic/fungal_shift.lua") --for materials list
dofile_once("mods/lamas_stats/files/fungal_past.lua")
dofile_once("mods/lamas_stats/files/fungal_future.lua")

local past_shifts = {} --table of past shifts (real one)
local future_shifts = {} --table of future shifts

function gui_fungal_shift()
	local gui_id = 1000
	function id()
		gui_id = gui_id + 1
		return gui_id
	end
	
	GuiBeginAutoBox(gui_menu)
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y, false, 0, 0) --layer1
	local guiZ = 900
	GuiZSet(gui_menu,guiZ)

	GuiText(gui_menu, 0, 0, "==== " .. _T.FungalShifts .. " ====", fungal_shift_scale)
	
	GuiLayoutBeginHorizontal(gui_menu,0,0, false)
	gui_menu_switch_button(gui_menu, id(), fungal_shift_scale, gui_menu_main_display_loop) --return

	gui_do_refresh_button(gui_menu, id(), fungal_shift_scale, UpdateFungalVariables)

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

	GuiZSetForNextWidget(gui_menu, guiZ + 100)
	GuiEndAutoBoxNinePiece(gui_menu, 1, 130, 0, false, 0, screen_png, screen_png)
end

function gui_fungal_show_aplc_recipes()
	GuiBeginAutoBox(gui_menu)
	GuiText(gui_menu, 0, 0, "[", fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon("midas_precursor")
	gui_fungal_shift_add_color_potion_icon("magic_liquid_hp_regeneration_unstable")
	GuiText(gui_menu, 0, 0, "]", fungal_shift_scale)
	GuiEndAutoBoxNinePiece(gui_menu,0,0,0,0,0,empty_png,empty_png)
	GuiTooltipLamas(gui_menu, 50, 0, guiZ, gui_fungal_show_aplc_recipes_tooltip)
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

function gui_fungal_shift_get_seed_shifts(iter, convert_tries) --calculate shifts based on seed (code is copied from game itself)
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

function gui_fungal_shift_display_from(material)
	GuiBeginAutoBox(gui_menu)
	local tooltiptext = ""
	if material.flask == "from" then --if flask was flagged
		if current_shifts < material.number then --if it's future shift
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_possible .. "\n"
			-- gui_fungal_shift_add_flask_shift()
			gui_fungal_shift_add_potion_icon()
			GuiColorSetForNextWidget(gui_menu, 1, 0.2, 0, 1)
			GuiText(gui_menu, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
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

function gui_fungal_shift_display_to_tooltip_greedy(gui, tooltip)
	if not ModIsEnabled("Apotheosis") then
		if ModSettingGet("lamas_stats.enable_fungal_greedy_tip") then
			GuiColorSetForNextWidget(gui_menu, 0.7, 0.7, 0.7, 1)
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_greedy, fungal_shift_scale)
		end
		if ModSettingGet("lamas_stats.enable_fungal_greedy_gold") then
			GuiLayoutBeginHorizontal(gui, 0, 0)
			gui_fungal_shift_add_color_potion_icon("gold")
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot("$mat_gold") .. " ->", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(tooltip.material.greedy_mat)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[tooltip.material.greedy_mat].name), fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
		if ModSettingGet("lamas_stats.enable_fungal_greedy_grass") then
			GuiLayoutBeginHorizontal(gui, 0, 0)
			gui_fungal_shift_add_color_potion_icon("grass_holy")
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot("$mat_grass_holy") .. " ->", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(tooltip.material.grass_holy)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[tooltip.material.grass_holy].name), fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
	end
end

function gui_fungal_shift_display_to_tooltip(gui, tooltip)
	GuiLayoutBeginVertical(gui, 0, 0)
	GuiLayoutBeginHorizontal(gui, 0, 0)
	if tooltip.material.failed ~= nil then
		-- gui_fungal_shift_add_color_potion_icon(material.to)
		-- todo
	else
		gui_fungal_shift_add_color_potion_icon(tooltip.material.to)
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[tooltip.material.to].name), fungal_shift_scale)
		GuiColorSetForNextWidget(gui_menu, 0.7, 0.7, 0.7, 1)
		GuiText(gui, 0, 0, " (" .. _T.lamas_stats_ingame_name .. ": " .. tooltip.material.to .. ")", fungal_shift_scale)
	end
	GuiLayoutEnd(gui)
	
	if tooltip.shift ~= nil then
		GuiLayoutBeginHorizontal(gui, 0, 0)
		gui_fungal_shift_add_potion_icon()
		if tooltip.shift == "possible" then
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_possible .. "!", fungal_shift_scale)
			GuiLayoutEnd(gui)
			gui_fungal_shift_display_to_tooltip_greedy(gui, tooltip)
		else
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_shift_used, fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
	end
	GuiLayoutEnd(gui)
end

function gui_fungal_shift_display_to(material)	
	GuiText(gui_menu, 0, 0, "-> ", fungal_shift_scale)
	local tooltip = {}
	tooltip.material = material
	GuiBeginAutoBox(gui_menu)
	if material.flask == "to" then
		if current_shifts < material.number then --if it's future shift
			gui_fungal_shift_add_potion_icon()
			tooltip.shift = "possible"
			if material.greedy_success then	GuiColorSetForNextWidget(gui_menu, 0.7, 0.2, 1, 1)
			else GuiColorSetForNextWidget(gui_menu, 1, 0.2, 0, 1) end
			GuiText(gui_menu, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
		else --past shift
			GuiColorSetForNextWidget(gui_menu, 1, 1, 0.698, 1)
			tooltip.shift = "used"
		end
	end
	
	if material.failed ~= nil then
		GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot("$item_potion"), fungal_shift_scale)
	else
		GuiText(gui_menu, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.to].name), fungal_shift_scale)
		gui_fungal_shift_add_color_potion_icon(material.to)
	end
	
	GuiEndAutoBoxNinePiece(gui_menu,0,0,0,0,0,empty_png,empty_png)
	-- GuiTooltip(gui_menu,"",tooltiptext)
	GuiTooltipLamas(gui_menu, 50, 0, guiZ, gui_fungal_shift_display_to_tooltip, tooltip)
	GuiText(gui_menu, 0, 0, "", fungal_shift_scale)
end

function gui_fungal_shift_get_shifts()
	gui_fungal_shift_get_past_shifts()
	if ModSettingGet("lamas_stats.enable_fungal_future") then
		gui_fungal_shift_get_future_shifts()
	end
end

function UpdateFungalVariables()
	fungal_shift_scale = ModSettingGet("lamas_stats.fungal_scale")
	gui_fungal_shift_get_shifts()
end

function gui_fungal_shift_add_color_potion_icon(material)
	if original_material_properties[material].icon == potion_png then
		SetColor(original_material_properties[material].color)
	end
	gui_fungal_shift_add_potion_icon(original_material_properties[material].icon)
end

function gui_fungal_shift_add_potion_icon(icon)
	icon = icon or potion_png
	GuiImage(gui_menu, id(), 0, 0, icon, 1, fungal_shift_scale)
end

function SetColor(material)
	GuiColorSetForNextWidget(gui_menu,material.red,material.green,material.blue,material.alpha)
end