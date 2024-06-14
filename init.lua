dofile_once("data/scripts/lib/utilities.lua")

original_material_properties = {} --table of material names and colors, populates from materials.xml

--[[	custom functions that need to be done during init ]]
function AppendFunction(file, search, add)
	local content = ModTextFileGetContent(file)
	local first, last = content:find(search, 0, true)
	local before = content:sub(1, last)
	local after = content:sub(last + 1)
	local new = before .. "\n" .. add .. "\n" .. after
	ModTextFileSetContent(file, new)
end

function lamas_stats_gather_material_name_table() --function to get table of material and whatever
	local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua")
	local materials = "data/materials.xml"
	local xml = nxml.parse(ModTextFileGetContent(materials))
	
	local files = ModMaterialFilesGet()
	for _, file in ipairs(files) do --add modded materials
		if file ~= materials then
			for _, comp in ipairs(nxml.parse(ModTextFileGetContent(file)).children) do
				xml.children[#xml.children+1] = comp
			end
		end
	end
	
	for elem in xml:each_child() do
		if elem.attr["ui_name"] ~= nil then
			original_material_properties[elem.attr["name"]] = {}
			original_material_properties[elem.attr["name"]].name = elem.attr["ui_name"]
			
			original_material_properties[elem.attr["name"]].color = {}
			local graphics = elem:first_of("Graphics")
			
			-- original_material_properties[elem.attr["name"]].graphics = graphics.attr["texture_file"] or potion_png
			if graphics == nil then
				original_material_properties[elem.attr["name"]].color.hex = elem.attr["wang_color"]
				original_material_properties[elem.attr["name"]].graphics = potion_png
			else
				--color
				if graphics.attr["color"] == nil then
					original_material_properties[elem.attr["name"]].color.hex = elem.attr["wang_color"]
				else
					original_material_properties[elem.attr["name"]].color.hex = graphics.attr["color"]
				end
				--graphics
				if graphics.attr["texture_file"] == nil then
					original_material_properties[elem.attr["name"]].graphics = potion_png
				else
					original_material_properties[elem.attr["name"]].graphics = graphics.attr["texture_file"]
				end
			end
		end
	end
	original_material_properties["lamas_failed_shift"] = {}
	original_material_properties["lamas_failed_shift"].name = "fail"
	original_material_properties["lamas_failed_shift"].color = {}
	original_material_properties["lamas_failed_shift"].color.hex = "44b53535"
	for _,mat in pairs(original_material_properties) do
		r,g,b,a = color_abgr_split(tonumber(mat.color.hex,16))
		mat.color.red = b/255 --i have no idea why red and blue is switched in this function
		mat.color.green = g/255
		mat.color.blue = r/255
		mat.color.alpha = a/255
	end
end

--[[	game hooks start here]]
function OnModPreInit()
	lamas_stats_gather_material_name_table() --gather table
	if ModSettingGet("lamas_stats.enable_perks_autoupdate") then --hooking perks refresh into game events
		AppendFunction("data/scripts/perks/perk.lua", "if ( no_perk_entity == false ) then", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
		AppendFunction("data/scripts/perks/perk.lua", "perk_spawn( x, y, perk_id )", "ModSettingSet(\"lamas_stats.enable_perks_autoupdate_flag\", true)")
	end
end

function OnPlayerSpawned(player_entity)
	dofile_once("mods/lamas_stats/files/info_gui.lua") --loading main gui file
end

function OnWorldPostUpdate()
	if lamas_stats_main_loop then lamas_stats_main_loop() end
end