local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua") ---@type nxml
local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter
local colors = dofile_once("mods/lamas_stats/files/scripts/color_helper.lua") ---@type colors
nxml.error_handler = function() end

local full_data = {}

---@class (exact) material_data
---@field id string
---@field ui_name string
---@field color material_colors?
---@field icon string
---@field is_solid boolean
---@field parent string?
---@field static boolean

---@class material_parser
---@field private buffer {[string]: material_data}|nil
---@field private invalid material_data
---@field data {[number]: material_data|nil}
local mat = {
	buffer = {},
	data = {},
}

---@param name string
---@param material string
---@param png string
---@return string
local function create_virtual_icon(name, material, png)
	local png_img_id, png_img_w, png_img_h = ModImageMakeEditable(png, 0, 0)
	local material_img_id, material_img_w, material_img_h = ModImageMakeEditable(material, 0, 0)
	local virtual_path = "mods/lamas_stats/vfs/" .. name .. ".png"
	local custom_img_id = ModImageMakeEditable(virtual_path, png_img_w, png_img_h)
	for y = 0, png_img_h do
		local text_y = y
		if y >= material_img_h then text_y = y - material_img_h end -- if texture is too small
		for x = 0, png_img_w do
			local text_x = x -- if texture is too small
			if x >= material_img_w then text_x = x - material_img_w end
			local color1 = ModImageGetPixel(png_img_id, x, y)
			local color2 = ModImageGetPixel(material_img_id, text_x, text_y)
			local color_multiplied = colors.multiply(color1, color2)
			ModImageSetPixel(custom_img_id, x, y, color_multiplied)
		end
	end
	return virtual_path
end

---Parses an element color
---@param element element
---@return string
local function get_color(element)
	local graphics = element:first_of("Graphics")
	if graphics and graphics.attr.color then return graphics.attr.color end
	return element.attr.wang_color
end

---@param element element
---@param is_solid boolean
---@return string, material_colors?
local function get_icon(element, is_solid)
	local graphics = element:first_of("Graphics")
	if not graphics then return "data/items_gfx/potion.png", colors.abgr_to_rgb(get_color(element)) end
	local graphics_attributes = graphics.attr
	local has_texture = graphics_attributes.texture_file and graphics_attributes.texture_file ~= ""
	-- if not graphics_attributes.texture_file or graphics_attributes.texture_file == "" then return end
	local element_attributes = element.attr
	if is_solid or element_attributes.tags and element_attributes.tags:find("static") then
		if not has_texture then return "mods/lamas_stats/files/gfx/solid_static.png", colors.abgr_to_rgb(get_color(element)) end
		return create_virtual_icon(element_attributes.name, graphics_attributes.texture_file, "mods/lamas_stats/files/gfx/solid_static.png")
	end
	if element_attributes.liquid_sand == "1" then
		if not has_texture then return "mods/lamas_stats/files/gfx/pile.png", colors.abgr_to_rgb(get_color(element)) end
		return create_virtual_icon(element_attributes.name, graphics_attributes.texture_file, "mods/lamas_stats/files/gfx/pile.png")
	end
	return "data/items_gfx/potion.png", colors.abgr_to_rgb(get_color(element))
end

---Checks if element is solid
---@param attr table<string, string>
---@return boolean
local function is_solid_type(attr)
	if attr.convert_to_box2d_material or attr.solid_break_to_type or attr.cell_type == "solid" then
		return true
	elseif attr._parent then
		return is_solid_type(full_data[attr._parent].attr)
	end
	return false
end

---Parses an xml element
---@param element element
local function parse_element(element)
	local attributes = element.attr
	local material_id = attributes.name
	if not material_id then return end
	local is_solid = is_solid_type(attributes)
	if is_solid then print(material_id) end
	local material_icon, material_color = get_icon(element, is_solid)
	-- local material_color = material_icon == "data/items_gfx/potion.png" and colors.abgr_to_rgb(get_color(element))
	mat.buffer[material_id] = {
		id = material_id,
		ui_name = attributes.ui_name or material_id,
		icon = material_icon,
		color = material_color,
		static = not not material_id:find("_static$"),
		parent = attributes._parent,
		is_solid = is_solid,
	}
end

---Parses a file
---@param file string
local function parse_file(file)
	local success, result = pcall(nxml.parse, ModTextFileGetContent(file))
	if not success then
		reporter:Report("couldn't parse material file " .. file)
		return
	end

	for _, element_name in ipairs({ "CellData", "CellDataChild" }) do
		for elem in result:each_of(element_name) do
			full_data[elem:get("name")] = elem
		end
	end
end

---Parses material list
function mat:parse()
	local files = ModMaterialFilesGet()
	for i = 1, #files do
		parse_file(files[i])
	end

	for k, v in pairs(full_data) do
		parse_element(v)
	end

	-- for _, element_name in ipairs({ "CellData", "CellDataChild" }) do
	-- 	for elem in result:each_of(element_name) do
	-- 		full_data[elem:get("name")] = elem
	-- 	end
	-- end

	nxml = nil ---@diagnostic disable-line: cast-local-type
	full_data = nil
end

---Converts buffer data into actual data
function mat:convert()
	for name, value in pairs(self.buffer) do
		local ui_name = GameTextGetTranslatedOrNot(value.ui_name)
		if ui_name == "" then value.ui_name = value.id end
		self.data[CellFactory_GetType(name)] = value
	end
	self.buffer = {}
end

local invalid_material = {
	id = "???",
	ui_name = "???",
	icon = "data/items_gfx/potion_normals.png",
	color = false,
	static = false,
}

---Returns data
---@param material_type number
---@return material_data
function mat:get_data(material_type)
	return self.data[material_type] or invalid_material
end

return mat
