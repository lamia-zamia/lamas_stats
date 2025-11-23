local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua") ---@type nxml
local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter
local colors = dofile_once("mods/lamas_stats/files/scripts/color_helper.lua") ---@type colors
nxml.error_handler = function() end

local full_data = {}
local reaction_input_index = {}
local reaction_output_index = {}
local reaction_input_tag_index = {}
local reaction_output_tag_index = {}

---@alias material_tags {[string]:boolean}

---@class reactions_data
---@field inputs string[]
---@field outputs string[]

local reactions = {} ---@type reactions_data[]

---@class (exact) material_data
---@field id string
---@field ui_name string
---@field color material_colors?
---@field icon string
---@field parent string?
---@field static boolean
---@field type material_types
---@field tags material_tags?

---@class material_parser
---@field private buffer {[string]: material_data}|nil
---@field private invalid material_data
---@field data {[number]: material_data|nil}
---@field material_types material_types_enum
local mat = {
	buffer = {},
	data = {},
	material_types = dofile_once("mods/lamas_stats/files/scripts/material_types.lua"),
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
		local text_y = y % material_img_h
		for x = 0, png_img_w do
			local text_x = x % material_img_w
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
local function get_element_color(element)
	local graphics = element:first_of("Graphics")
	if graphics and graphics.attr.color then return graphics.attr.color end
	return element.attr.wang_color
end

---Returns material_colors
---@param element element
---@param ignore_alpha boolean?
---@return material_colors
local function get_material_color(element, ignore_alpha)
	local material_color = colors.abgr_to_rgb(get_element_color(element))
	if ignore_alpha then material_color.a = 1 end
	return material_color
end

---Returns texture file if any
---@param element element
---@return string?
local function get_texture(element)
	local graphics = element:first_of("Graphics")
	if not graphics then return end
	local texture = graphics.attr.texture_file
	if texture and texture ~= "" then return texture end
end

local textures = {
	[mat.material_types.solid] = "mods/lamas_stats/files/gfx/solid.png",
	[mat.material_types.sand] = "mods/lamas_stats/files/gfx/pile.png",
	[mat.material_types.gas] = "mods/lamas_stats/files/gfx/gas.png",
	[mat.material_types.static] = "mods/lamas_stats/files/gfx/solid_static.png",
	[mat.material_types.fire] = "mods/lamas_stats/files/gfx/fire.png",
}

---@param element element
---@param type material_types
---@return string, material_colors?
local function get_icon(element, type)
	local texture = get_texture(element)
	if textures[type] then
		if texture then return create_virtual_icon(element.attr.name, texture, textures[type]) end
		return textures[type], get_material_color(element)
	end
	return "data/items_gfx/potion.png", get_material_color(element, true)
end

---Gets material type
---@param attributes table
---@return material_types
local function get_material_type(attributes)
	local cell_type = attributes.cell_type
	if cell_type and mat.material_types[cell_type] then
		-- is it solid
		if mat.material_types[cell_type] == mat.material_types.solid then return mat.material_types.solid end
		if
			attributes.convert_to_box2d_material
			or attributes.solid_break_to_type
			or attributes.solid_static_type == "1"
			or attributes.platform_type == "1"
		then
			return mat.material_types.static
		end
		local is_liquid = mat.material_types[cell_type] == mat.material_types.liquid
		-- local is_gas = mat.material_types[cell_type] == mat.material_types.gas
		-- -- is it static liquid/gas
		-- if (is_liquid or is_gas) and attributes.liquid_static == "1" then return mat.material_types.static end
		if is_liquid and attributes.liquid_sand == "1" then return mat.material_types.sand end
		return mat.material_types[cell_type]
	end
	if attributes._parent and full_data[attributes._parent] then return get_material_type(full_data[attributes._parent].attr) end
	return mat.material_types.liquid
end

---Gets material tags
---@param attributes table
---@return material_tags?
local function get_material_tags(attributes)
	local tags = attributes.tags or (attributes._parent and full_data[attributes._parent] and full_data[attributes._parent].attr.tags)
	if not tags then return end
	local tags_table = {}
	for tag in tags:gmatch("([^,]+)") do
		tags_table[tag] = true
	end
	return tags_table
end

---Parses an xml material element
---@param element element
local function parse_material(element)
	local attributes = element.attr
	local material_id = attributes.name
	if not material_id then return end

	local type = get_material_type(attributes)

	local material_icon, material_color = get_icon(element, type)
	mat.buffer[material_id] = {
		id = material_id,
		ui_name = attributes.ui_name or material_id,
		icon = material_icon,
		color = material_color,
		static = not not material_id:find("_static$"),
		parent = attributes._parent,
		type = type,
		tags = get_material_tags(attributes),
	}
end

---Is this string a tag
---@param value string
---@return boolean
---@nodiscard
local function is_this_tag(value)
	return value:sub(1, 1) == "[" and value:sub(-1) == "]"
end

---Adds reaction to index table
---@param is_input boolean
---@param material string
---@param index integer
local function reaction_add_to_index_table(is_input, material, index)
	local index_table
	if is_this_tag(material) then
		index_table = is_input and reaction_input_tag_index or reaction_output_tag_index
	else
		index_table = is_input and reaction_input_index or reaction_output_index
	end

	if not index_table[material] then index_table[material] = {} end
	local idx_table = index_table[material]
	idx_table[#idx_table + 1] = index
end

---Parses a reaction element
---@param element element
local function parse_reaction(element)
	local attributes = element.attr

	local reaction_index = #reactions + 1
	reactions[reaction_index] = {
		inputs = {},
		outputs = {},
	}
	for i = 1, 3 do
		local input_cell = attributes["input_cell" .. i]
		local output_cell = attributes["output_cell" .. i]
		if not input_cell or not output_cell then break end
		table.insert(reactions[reaction_index].inputs, input_cell)
		reaction_add_to_index_table(true, input_cell, reaction_index)
		table.insert(reactions[reaction_index].outputs, output_cell)
		reaction_add_to_index_table(false, output_cell, reaction_index)
	end
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
	for reaction in result:each_of("Reaction") do
		parse_reaction(reaction)
	end
end

---Parses material list
function mat:parse()
	local files = ModMaterialFilesGet()
	for i = 1, #files do
		parse_file(files[i])
	end

	for _, v in pairs(full_data) do
		parse_material(v)
	end

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

---Returns data
---@param material_id string
---@return material_data
function mat:get_data_by_id(material_id)
	return self:get_data(CellFactory_GetType(material_id))
end

---@param material_id string
---@return reactions_data[]
function mat:get_reactions_using(material_id)
	local result = {}
	for _, rid in ipairs(reaction_input_index[material_id] or {}) do
		result[#result + 1] = reactions[rid]
	end
	for tag, _ in pairs(mat:get_data_by_id(material_id).tags or {}) do
		for _, rid in ipairs(reaction_input_tag_index[tag] or {}) do
			result[#result + 1] = reactions[rid]
		end
	end
	return result
end

---@param material_id string
---@return reactions_data[]
function mat:get_reactions_producing(material_id)
	local result = {}
	for _, rid in ipairs(reaction_output_index[material_id] or {}) do
		result[#result + 1] = reactions[rid]
	end
	for tag, _ in pairs(mat:get_data_by_id(material_id).tags or {}) do
		for _, rid in ipairs(reaction_output_tag_index[tag] or {}) do
			result[#result + 1] = reactions[rid]
		end
	end
	return result
end

return mat
