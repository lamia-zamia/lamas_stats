local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua") ---@type nxml
local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter
local colors = dofile_once("mods/lamas_stats/files/scripts/color_helper.lua") ---@type colors
nxml.error_handler = function() end

local full_data = {}

---@alias index_table {[string]:integer[]}
---@class (exact) reaction_index
---@field input index_table
---@field output index_table
---@field tag_input index_table
---@field tag_output index_table
local reaction_index = {
	input = {},
	output = {},
	tag_input = {},
	tag_output = {},
}

local tagged_materials = {} ---@type {[string]:string[]}
local partial_matches = {} ---@type {[string]:{original:string, match:string}}
local generate_icons = ModSettingGet("lamas_stats.generate_icons")

---@alias material_tags {[string]:boolean}

---@class reactions_data
---@field inputs string[]
---@field outputs string[]
---@field is_req boolean
---@field probability number

local reactions = {} ---@type reactions_data[]

---@class (exact) material_data
---@field id string
---@field ui_name string
---@field color material_colors?
---@field icon string
---@field parent string?
---@field static boolean
---@field type material_types
---@field tags material_tags

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

local magic_tags = {
	[mat.material_types.liquid] = "[any_liquid]",
	[mat.material_types.sand] = "[any_powder]",
}
local magic_tags_index = {}
for _, v in pairs(magic_tags) do
	magic_tags_index[v] = true
end

---@param name string
---@param material string
---@param png string
---@return string
local function create_virtual_icon(name, material, png)
	local png_img_id, png_img_w, png_img_h = ModImageMakeEditable(png, 0, 0)
	local material_img_id, material_img_w, material_img_h = ModImageMakeEditable(material, 0, 0)
	local virtual_path = string.format("mods/lamas_stats/vfs/%s.png", name)
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
		if texture and generate_icons then return create_virtual_icon(element.attr.name, texture, textures[type]) end
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
		if is_liquid and attributes.liquid_sand == "1" then return mat.material_types.sand end
		return mat.material_types[cell_type]
	end
	if attributes._parent and full_data[attributes._parent] then return get_material_type(full_data[attributes._parent].attr) end
	return mat.material_types.liquid
end

---Inserts value into index table
---@param index table
---@param key string
---@param value any
local function insert_to_index(index, key, value)
	index[key] = index[key] or {}
	for _, v in ipairs(index[key]) do
		if v == value then return end
	end
	table.insert(index[key], value)
end

---Gets material tags
---@param attributes table
---@param material_type material_types
---@return material_tags
local function get_material_tags(attributes, material_type)
	local tags_table = {
		["[*]"] = true,
	}
	local magic_tag = magic_tags[material_type]
	if magic_tag then tags_table[magic_tag] = true end

	local tags = attributes.tags or (attributes._parent and full_data[attributes._parent] and full_data[attributes._parent].attr.tags)
	if not tags then return tags_table end

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
		tags = get_material_tags(attributes, type),
	}
end

---Parses tag
---@param str string
---@return string?, string?
function mat.parse_tagged_cell(str)
	local tag, suffix = str:match("^(%[[^%]]+%])(.*)$")
	return tag, suffix -- suffix may be "", "_molten", "_rust", etc
end

---Expands partial tag and adds to reaction index table if exist
---@private
---@param tag string
---@param suffix string?
---@param base_table { [string]: integer[] }
---@param index integer
local function expand_partial_tag(tag, suffix, base_table, index)
	if not suffix or suffix == "" then return end
	for _, base in ipairs(tagged_materials[tag] or {}) do
		local generated = base .. suffix
		if full_data[generated] then
			insert_to_index(base_table, generated, index)
			insert_to_index(partial_matches, tag, { original = base, match = generated })
			insert_to_index(tagged_materials, tag .. suffix, generated)
		end
	end
end

---Adds reaction to index table
---@param is_input boolean
---@param material string
---@param index integer
local function reaction_add_to_index_table(is_input, material, index)
	local tag, suffix = mat.parse_tagged_cell(material)

	-- pick correct base table
	local base_table = is_input and reaction_index.input or reaction_index.output

	-- if this is a tag entry, store it as-is
	if tag then
		insert_to_index(is_input and reaction_index.tag_input or reaction_index.tag_output, material, index)
		expand_partial_tag(tag, suffix, base_table, index)
		return
	end

	-- normal material
	insert_to_index(base_table, material, index)
end

---Parses a reaction element
---@param element element
---@param is_req boolean
local function parse_reaction(element, is_req)
	local attributes = element.attr

	local this_reaction_index = #reactions + 1
	local inputs, outputs = {}, {}

	for i = 1, 3 do
		local input_cell = attributes["input_cell" .. i]
		local output_cell = attributes["output_cell" .. i]
		if not input_cell or not output_cell then break end
		if input_cell == "" or output_cell == "" then break end
		inputs[#inputs + 1] = input_cell
		outputs[#outputs + 1] = output_cell
		reaction_add_to_index_table(true, input_cell, this_reaction_index)
		reaction_add_to_index_table(false, output_cell, this_reaction_index)
	end
	reactions[this_reaction_index] = {
		inputs = inputs,
		outputs = outputs,
		is_req = is_req,
		probability = tonumber(attributes.probability) or 0,
	}
end

---Parses a file and gets nxml element
---@param file string
---@return element?
local function get_file(file)
	local success, result = pcall(nxml.parse, ModTextFileGetContent(file))
	if not success then
		reporter:Report("couldn't parse material file " .. file)
		return
	end
	return result
end

---Parses material list
function mat:parse()
	-- parsing files to nxml elements
	local parsed_files = {}
	for _, file in ipairs(ModMaterialFilesGet()) do
		local parse_result = get_file(file)
		if parse_result then parsed_files[#parsed_files + 1] = parse_result end
	end

	-- parsing materials and writing them all to temporary table (children bad)
	for _, parsed_file in ipairs(parsed_files) do
		for _, element_name in ipairs({ "CellData", "CellDataChild" }) do
			for elem in parsed_file:each_of(element_name) do
				full_data[elem:get("name")] = elem
			end
		end
	end

	-- parsing materials
	for _, v in pairs(full_data) do
		parse_material(v)
	end

	-- this is liquid, but not liquid? wtf nolla
	mat.buffer.air.tags["[any_liquid]"] = nil
	for material_id, material_data in pairs(mat.buffer) do
		for tag, _ in pairs(material_data.tags) do
			insert_to_index(tagged_materials, tag, material_id)
		end
	end

	-- parsing reactions after we finished parsing materials
	for _, parsed_file in ipairs(parsed_files) do
		for elem in parsed_file:each_of("Reaction") do
			parse_reaction(elem, false)
		end
		for elem in parsed_file:each_of("ReqReaction") do
			parse_reaction(elem, true)
		end
	end

	parsed_files = nil
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
	return self.buffer[material_id] or invalid_material
end

---Checks if material exist
---@param material_id string
---@return boolean?
function mat:does_material_exist(material_id)
	if self.buffer[material_id] then return true end
end

---Gets reactions
---@private
---@param material_id string
---@param index_direct index_table
---@param index_tag index_table
---@return reactions_data[]
function mat.get_reaction(material_id, index_direct, index_tag)
	local result = {}
	local seen = {}
	for _, reaction_id in ipairs(index_direct[material_id] or {}) do
		if not seen[reaction_id] then
			result[#result + 1] = reactions[reaction_id]
			seen[reaction_id] = true
		end
	end
	for tag, _ in pairs(mat:get_data_by_id(material_id).tags or {}) do
		for _, reaction_id in ipairs(index_tag[tag] or {}) do
			if not seen[reaction_id] then
				result[#result + 1] = reactions[reaction_id]
				seen[reaction_id] = true
			end
		end
	end
	return result
end

---@param material_id string
---@return reactions_data[]
function mat:get_reactions_using(material_id)
	return mat.get_reaction(material_id, reaction_index.input, reaction_index.tag_input)
end

---@param material_id string
---@return reactions_data[]
function mat:get_reactions_producing(material_id)
	return mat.get_reaction(material_id, reaction_index.output, reaction_index.tag_output)
end

---Does this material has this tag
---@param material_id string
---@param tag string
---@return boolean?
function mat:material_has_tag(material_id, tag)
	if magic_tags_index[tag] then return end
	local material_data = self:get_data_by_id(material_id)
	return material_data.tags and material_data.tags[tag]
end

---Iterates all material names of a reaction
---@param reaction_datas reactions_data[]
---@return fun():table?, string?, integer?  -- (reaction.material_list, material_name, index)
function mat.each_reaction_material_names(reaction_datas)
	local this_reaction_index = 1 -- which reaction we are on
	local material_index = 0 -- inside that list
	local reaction_types = { "inputs", "outputs" }
	local type_index = 1

	return function()
		while true do
			-- no more reactions
			local reaction = reaction_datas[this_reaction_index]
			if not reaction then return nil end

			-- get current type (inputs or outputs)
			local material_list = reaction[reaction_types[type_index]]

			-- advance inside the list
			material_index = material_index + 1

			-- element exists? return it
			if material_list and material_list[material_index] then return material_list, material_list[material_index], material_index end

			-- list exhausted → move to outputs
			if type_index == 1 then
				type_index = 2
				material_index = 0
			else
				-- outputs exhausted → move to next reaction
				this_reaction_index = this_reaction_index + 1
				type_index = 1
				material_index = 0
			end
		end
	end
end

---Returns original name for partial tags
---@param tag string
---@param material_name string
---@return string?
function mat.is_partial_match(tag, material_name)
	for _, result in ipairs(partial_matches[tag] or {}) do
		if result.match == material_name then return result.original end
	end
end

---Returns list of materials with tag
---@param tag string
---@return string[]
function mat.get_tagged_materials(tag)
	return tagged_materials[tag] or {}
end

return mat
