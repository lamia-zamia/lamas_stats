dofile_once("data/scripts/magic/fungal_shift.lua") --for materials list

local past_shifts = {} --table of past shifts (real one)
local future_shifts = {} --table of future shifts
local original_material_properties = {} --table of material names and colors, populates from materials.xml
local fungal_shift_scale = ModSettingGet("lamas_stats.fungal_scale")

function gui_fungal_shift()
	GuiBeginAutoBox(gui)
	GuiLayoutBeginVertical(gui, menu_pos_x, menu_pos_y, false, 0, 0) --layer1
	GuiZSet(gui,900)

	GuiText(gui, 0, 0, "==== " .. _T.FungalShifts .. " ====", fungal_shift_scale)
	
	GuiLayoutBeginHorizontal(gui,0,0, false)
	gui_do_return_button(fungal_shift_scale, gui_main) --return

	gui_do_refresh_button(fungal_shift_scale, gui_fungal_shift_get_shifts)

	if current_shifts ~= tonumber(GlobalsGetValue("fungal_shift_iteration", "0")) then
		gui_fungal_shift_get_shifts()
	end
	
	GuiImgId = 1100
	
	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		gui_fungal_show_aplc_recipes()
	end
	
	local cooldown = ShowFungalCooldown()
	if cooldown > 0 then
		GuiImage(gui, GuiImgId, -5, -1, fungal_png, 1, 0.7 * fungal_shift_scale)
		GuiText(gui, 0, 0, _T.lamas_stats_fungal_cooldown .. " " .. cooldown)
		GuiImgId = GuiImgId + 1
	end
	GuiLayoutEnd(gui)
	
	if ModSettingGet("lamas_stats.enable_fungal_past") then
		gui_fungal_shift_display_past_shifts()
	end
	
	if ModSettingGet("lamas_stats.enable_fungal_future") then
		gui_fungal_shift_display_future_shifts()
	end
	
	GuiLayoutEnd(gui) --layer1

	GuiZSetForNextWidget(gui, 1000)
	GuiEndAutoBoxNinePiece(gui, 1, 130, 0, false, 0, screen_png, screen_png)
	
end

function gui_fungal_show_aplc_recipes()
	GuiBeginAutoBox(gui)
	GuiText(gui, 0, 0, "[", fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon("midas_precursor")
	gui_fungal_shift_add_color_potion_icon("magic_liquid_hp_regeneration_unstable")
	GuiText(gui, 0, 0, "]", fungal_shift_scale)
	GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
	GuiTooltipLamas(gui, 50, 0, 900, gui_fungal_show_aplc_recipes_tooltip)
end

function gui_fungal_show_aplc_recipes_tooltip()
	gui_fungal_show_aplc_recipes_tooltip_add_recipe("midas_precursor", APLC_table.ap)
	gui_fungal_show_aplc_recipes_tooltip_add_recipe("magic_liquid_hp_regeneration_unstable", APLC_table.lc)
end

function gui_fungal_show_aplc_recipes_tooltip_add_recipe(mat_id, mat_table)
	GuiLayoutBeginHorizontal(gui, 0, 0)
	GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat_id].name), fungal_shift_scale)
	gui_fungal_shift_add_color_potion_icon(mat_id)
	GuiText(gui, 0, 0, "->", fungal_shift_scale)
	for _,material in ipairs(mat_table) do
		GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material].name), fungal_shift_scale)
		gui_fungal_shift_add_color_potion_icon(material)
	end
	GuiLayoutEnd(gui)
end

function gui_fungal_shift_get_seed_shifts(iter, convert_tries) --calculate shifts based on seed (code is copied from game itself)
	local _from, _to = nil, nil
    local converted_any = false
    local convert_tries = convert_tries or 0

    while converted_any == false and convert_tries < maximum_shifts do
        local seed2 = 42345 + iter - 1 + 1000*convert_tries --minus one for consistency with other objects
        SetRandomSeed(89346, seed2)
        local rnd = random_create( 9123, seed2 )
        local from = pick_random_from_table_weighted(rnd, materials_from)
        local to = pick_random_from_table_weighted(rnd, materials_to)

        _from = {
            flask = false,
            probability = from.probability,
            materials = from.materials,
        }
        _to = {
            flask = false,
            probability = to.probability,
            material = to.material,
            greedy_mat = nil,
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

        -- Check for failed attempts
		local same_mat = 0
		for _, mat in ipairs(_from.materials) do
			if mat == _to.material then
				if _from.flask or _to.flask then
					same_mat = same_mat + 1
				end
			end
			if same_mat == #_from.materials then 
				_failed = gui_fungal_shift_get_seed_shifts(iter, convert_tries + 1)
			end
			converted_any = true	
		end

        convert_tries = convert_tries + 1
    end

    if not converted_any then
        GamePrint(_T.lamas_stats_fungal_predict_error .. " " .. tostring(iter))
    end

    return {from=_from, to=_to, failed = _failed}
end

function gui_fungal_shift_display_from(material)
	GuiBeginAutoBox(gui)
	local tooltiptext = ""
	if material.flask == "from" then --if flask was flagged
		if current_shifts < material.number then --if it's future shift
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_possible .. "\n"
			gui_fungal_shift_add_flask_shift()
			if material.failed ~= nil then
				GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
				GuiTooltip(gui,"",tooltiptext)
				return
			end
		else
			GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_used .. "\n"
		end
	end
	
	if ModSettingGet("lamas_stats.fungal_group_type") == "group" then
		if #material.from > 1 then
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_group_of, fungal_shift_scale)
		else
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.from[1]].name), fungal_shift_scale)
		end
	end
		
	
	for i,mat in ipairs(material.from) do
		if ModSettingGet("lamas_stats.fungal_group_type") == "full" then
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		end
		gui_fungal_shift_add_color_potion_icon(mat)
		tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot(original_material_properties[mat].name)
		tooltiptext = tooltiptext .. ", " .. _T.lamas_stats_ingame_name .. (": ") .. mat .. "\n"
	end
	GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)

	GuiTooltip(gui,"",tooltiptext)
end

function gui_fungal_shift_display_to(material)	
	GuiText(gui, 0, 0, "-> ", fungal_shift_scale)
	
	local tooltiptext = ""
	local material_to = GameTextGetTranslatedOrNot(original_material_properties[material.to].name)
	local show_to = true
	GuiBeginAutoBox(gui)
	if material.flask == "to" then
		if current_shifts < material.number then --if it's future shift
			gui_fungal_shift_add_potion_icon()
			GuiColorSetForNextWidget(gui, 1, 0.2, 0, 1)
			
			if material.failed ~= nil then
				material_to = GameTextGetTranslatedOrNot("$item_potion")
				show_to = false
			else
				GuiText(gui, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
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
				GuiColorSetForNextWidget(gui, 0.7, 0.2, 1, 1)
			end
		else --past shift
			GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
			tooltiptext = tooltiptext .. _T.lamas_stats_fungal_shift_used .. "\n"
		end
	end
	
	GuiText(gui, 0, 0, material_to, fungal_shift_scale)
	

	if show_to then
		gui_fungal_shift_add_color_potion_icon(material.to)
		tooltiptext = tooltiptext .. GameTextGetTranslatedOrNot(original_material_properties[material.to].name)
		tooltiptext = tooltiptext .. ", " .. _T.lamas_stats_ingame_name .. (": ") .. material.to .. "\n"
	end
	
	GuiEndAutoBoxNinePiece(gui,0,0,0,0,0,empty_png,empty_png)
	GuiTooltip(gui,"",tooltiptext)
	GuiText(gui, 0, 0, "", fungal_shift_scale)
end

function gui_fungal_shift_add_flask_shift()
	gui_fungal_shift_add_potion_icon()
	GuiColorSetForNextWidget(gui, 1, 0.2, 0, 1)
	GuiText(gui, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
end

function gui_fungal_shift_get_past_shifts()
	past_shifts = {}
	local past_materials = ComponentGetValue2(worldcomponent, "changed_materials")
	local shift_number = 1

	current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
	for i=1,current_shifts,1 do
		local seed_shifts = gui_fungal_shift_get_seed_shifts(i)
		local from_mat = seed_shifts.from.materials --getting shift by seed
		local from_mat_n = table.getn(from_mat) --getting number of materials that was shifted
		local to_mat = seed_shifts.to.material
		
		past_shifts[i] = {}
		past_shifts[i].flask = ""
		past_shifts[i].number = i
		past_shifts[i].from = {}
		for j=1,from_mat_n do
			table.insert(past_shifts[i].from, past_materials[shift_number])
			past_shifts[i].to = past_materials[shift_number+1]
			shift_number = shift_number + 2
			if past_shifts[i].to ~= to_mat then
				if seed_shifts.to.flask == true then past_shifts[i].flask = "to" end
			end
			if past_materials[shift_number-2] ~= from_mat[j] then --if we converted from flask and in seed there was multiple
				if seed_shifts.from.flask == true then past_shifts[i].flask = "from" end
				break
			end
		end
	end
end

function gui_fungal_shift_display_past_shifts()
	for _,past_shift in ipairs(past_shifts) do
		GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
		GuiText(gui, 0, 0, _T.lamas_stats_shift .. " " .. tostring(past_shift.number) .. ": ", fungal_shift_scale)
		
		gui_fungal_shift_display_from(past_shift)

		gui_fungal_shift_display_to(past_shift)
		
		GuiLayoutEnd(gui)
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
		local seed_shifts = gui_fungal_shift_get_seed_shifts(i)
		local from_mat = seed_shifts.from.materials --getting shift by seed
		local from_mat_n = #from_mat --getting number of materials that was shifted
		local to_mat = seed_shifts.to.material

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
		GuiText(gui, 0, 0, "---- " .. nextshifttext .. " ----",fungal_shift_scale)
	end
	for i=current_shifts+1,maximum_shifts,1 do
		GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
		GuiText(gui, 0, 0, _T.lamas_stats_shift .. " " .. tostring(future_shifts[i].number) .. ": ", fungal_shift_scale)
		
		gui_fungal_shift_display_from(future_shifts[i])

		gui_fungal_shift_display_to(future_shifts[i])
				
		GuiLayoutEnd(gui)
		
		if future_shifts[i].failed ~= nil then --if there could be a failed attempt then say so
			GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_if_fail .. " ", fungal_shift_scale)
			gui_fungal_shift_add_potion_icon()
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot("$item_potion"),fungal_shift_scale)
			GuiText(gui, 0, 0, " " .. _T.lamas_stats_or .. " ", fungal_shift_scale)
			gui_fungal_shift_add_color_potion_icon(future_shifts[i].to)
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[future_shifts[i].to].name) .. ":", fungal_shift_scale)
			GuiLayoutEnd(gui)
			
			GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
			GuiText(gui, 0, 0, _T.lamas_stats_shift .. " " .. tostring(future_shifts[i].number) .. ": ", fungal_shift_scale)
			gui_fungal_shift_display_from(future_shifts[i].failed)
			gui_fungal_shift_display_to(future_shifts[i].failed)	
			GuiLayoutEnd(gui)
		end
		
		if i == current_shifts+1 and i < maximum_shifts then
			GuiLayoutBeginHorizontal(gui,0,0,0,0,0)
			GuiText(gui, 0, 0, "---- ",fungal_shift_scale) 
			GuiText(gui, GuiGetTextDimensions(gui, nextshifttext, fungal_shift_scale), 0, " ----",fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
	end	
end

function gui_fungal_shift_get_shifts()
	gui_fungal_shift_get_past_shifts()
	if ModSettingGet("lamas_stats.enable_fungal_future") then
		gui_fungal_shift_get_future_shifts()
	end
end

function gui_fungal_shift_gather_material_name_table() --function to get table of material name and color, called once on menu initialization
	local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua")
	local xml = nxml.parse(ModTextFileGetContent("data/materials.xml"))
	for elem in xml:each_child() do
		if elem.attr["ui_name"] ~= nil then
			original_material_properties[elem.attr["name"]] = {}
			original_material_properties[elem.attr["name"]].name = elem.attr["ui_name"]
			local graphics = elem:first_of("Graphics")
			original_material_properties[elem.attr["name"]].color = {}
			if graphics == nil then
				original_material_properties[elem.attr["name"]].color.hex = elem.attr["wang_color"]
			elseif graphics.attr["color"] == nil then
				original_material_properties[elem.attr["name"]].color.hex = elem.attr["wang_color"]
			else
				original_material_properties[elem.attr["name"]].color.hex = graphics.attr["color"]
			end
		end
	end
	for _,mat in pairs(original_material_properties) do
		r,g,b,a = color_abgr_split(tonumber(mat.color.hex,16))
		mat.color.red = b/255 --i have no idea why red and blue is switched in this function
		mat.color.green = g/255
		mat.color.blue = r/255
		mat.color.alpha = a/255
	end
end

function gui_fungal_shift_add_color_potion_icon(material)
	SetColor(original_material_properties[material].color)
	GuiImage(gui, GuiImgId, 0, 0, potion_png, 1, fungal_shift_scale)
	GuiImgId = GuiImgId + 1
end

function gui_fungal_shift_add_potion_icon()
	GuiImage(gui, GuiImgId, 0, 0, potion_png, 1, fungal_shift_scale)
	GuiImgId = GuiImgId + 1
end

function SetColor(material)
	GuiColorSetForNextWidget(gui,material.red,material.green,material.blue,material.alpha)
end

gui_fungal_shift_gather_material_name_table() --gather table
