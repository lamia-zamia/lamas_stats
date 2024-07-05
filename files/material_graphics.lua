local original_material_properties = {}

local function lamas_stats_make_custom_potions(name, material, png)
	if ModImageMakeEditable ~= nil then -- needed to avoid error if this file is hotloaded after init
		-- print(material)
		local png_img_id, png_img_w, png_img_h = ModImageMakeEditable(png,0,0)
		local material_img_id, material_img_w, material_img_h = ModImageMakeEditable(material,0,0)
		local virtual_path = virtual_png_dir .. name .. ".png"
		local custom_img_id = ModImageMakeEditable(virtual_path, png_img_w, png_img_h)
		for y=0, png_img_h do 
			local text_y = y
			if y >= material_img_h then text_y = y - material_img_h end --if texture is too small
			for x=0, png_img_w do
				local text_x = x --if texture is too small
				if x >= material_img_w then text_x = x - material_img_w end
				local p_r, p_g, p_b, p_a = color_abgr_split(ModImageGetPixel(png_img_id, x, y))
				local m_r, m_g, m_b, m_a = color_abgr_split(ModImageGetPixel(material_img_id, text_x, text_y))
				local c = color_abgr_merge(p_r * m_r / 255, p_g * m_g / 255, p_b * m_b / 255, p_a * m_a / 255)
				ModImageSetPixel(custom_img_id, x, y, c)
			end
		end
		return virtual_path
	else
		print("couldn't make custom image from " .. material)
		return potion_png
	end
end

local function lamas_stats_set_colors(id, color)
	local r,g,b,a = color_abgr_split(tonumber(color,16))
	original_material_properties[id].color.red = b/255 --i have no idea why red and blue is switched in this function
	original_material_properties[id].color.green = g/255
	original_material_properties[id].color.blue = r/255
	original_material_properties[id].color.alpha = a/255
end

local function lamas_stats_set_icon(elem, graphics)
	if graphics == nil or graphics.attr["texture_file"] == nil or graphics.attr["texture_file"] == "" then
		original_material_properties[elem.attr["name"]].icon = potion_png
	else
		local tags = elem.attr["tags"]
		if tags ~= nil and string.find(tags, "static") then 
			original_material_properties[elem.attr["name"]].icon = lamas_stats_make_custom_potions(elem.attr["name"], graphics.attr["texture_file"], solid_static_png)
		elseif elem.attr["liquid_sand"] == "1" then 
			original_material_properties[elem.attr["name"]].icon = lamas_stats_make_custom_potions(elem.attr["name"], graphics.attr["texture_file"], pile_png)
		else original_material_properties[elem.attr["name"]].icon = potion_png end
	end
end

local function lamas_stats_get_graphics_info(elem)
	local graphics = elem:first_of("Graphics")
	if graphics == nil then
		lamas_stats_set_colors(elem.attr["name"], elem.attr["wang_color"])
		lamas_stats_set_icon(elem)
	else
		--color
		if graphics.attr["color"] == nil then lamas_stats_set_colors(elem.attr["name"], elem.attr["wang_color"])
		else lamas_stats_set_colors(elem.attr["name"], graphics.attr["color"]) end
		--graphics
		lamas_stats_set_icon(elem, graphics)
	end
end

local function lamas_stats_gather_material() --function to get table of material and whatever
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
		
	for _,element_name in ipairs({"CellData","CellDataChild"}) do
		for elem in xml:each_of(element_name) do
			if elem.attr["ui_name"] ~= nil then	
				original_material_properties[elem.attr["name"]] = {}
				original_material_properties[elem.attr["name"]].name = elem.attr["ui_name"]
				
				original_material_properties[elem.attr["name"]].color = {}
				lamas_stats_get_graphics_info(elem)
			end
		end
	end
	original_material_properties["lamas_failed_shift"] = {}
	original_material_properties["lamas_failed_shift"].name = _T.lamas_stats_fungal_failed
	original_material_properties["lamas_failed_shift"].color = {}
	original_material_properties["lamas_failed_shift"].color.red = 1
	original_material_properties["lamas_failed_shift"].color.green = 0
	original_material_properties["lamas_failed_shift"].color.blue = 0
	original_material_properties["lamas_failed_shift"].color.alpha = 1

	return original_material_properties
end

return lamas_stats_gather_material()