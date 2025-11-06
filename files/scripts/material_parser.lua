local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua") ---@type nxml
local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter
nxml.error_handler = function() end

---@alias material_colors {r:number, g:number, b:number, a:number}

---@class (exact) material_data
---@field id string
---@field ui_name string
---@field color material_colors|false
---@field icon string
---@field static boolean

---@class material_parser
---@field private buffer {[string]: material_data}|nil
---@field private invalid material_data
---@field data {[number]: material_data|nil}
local mat = {
	buffer = {},
	data = {},
}

---Split abgr
---@param abgr_int integer
---@return number red, number green, number blue, number alpha
local function color_abgr_split(abgr_int)
	local r = bit.band(abgr_int, 0xFF)
	local g = bit.band(bit.rshift(abgr_int, 8), 0xFF)
	local b = bit.band(bit.rshift(abgr_int, 16), 0xFF)
	local a = bit.band(bit.rshift(abgr_int, 24), 0xFF)

	return r, g, b, a
end

---Merge rgb
---@param r number
---@param g number
---@param b number
---@param a number
---@return integer color
local function color_abgr_merge(r, g, b, a)
	return bit.bor(bit.band(r, 0xFF), bit.lshift(bit.band(g, 0xFF), 8), bit.lshift(bit.band(b, 0xFF), 16), bit.lshift(bit.band(a, 0xFF), 24))
end

---Normalize colors
---@private
---@param color1 integer
---@param color2 integer
---@return integer
local function multiply_colors(color1, color2)
	local s_r, s_g, s_b, s_a = color_abgr_split(color1)
	local d_r, d_g, d_b, d_a = color_abgr_split(color2)
	return color_abgr_merge(s_r * d_r / 255, s_g * d_g / 255, s_b * d_b / 255, s_a * d_a / 255)
end

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
			-- local c = color_abgr_merge(p_r * m_r / 255, p_g * m_g / 255, p_b * m_b / 255, p_a * m_a / 255)
			local color_multiplied = multiply_colors(color1, color2)
			ModImageSetPixel(custom_img_id, x, y, color_multiplied)
		end
	end
	return virtual_path
end

---Converts string abgr to rgba
---@param color string
---@return material_colors
local function abgr_to_rgb(color)
	local b, g, r, a = color_abgr_split(tonumber(color, 16))
	return { r = r / 255, g = g / 255, b = b / 255, a = a / 255 }
end

---@param element element
---@return string
local function get_icon(element)
	local graphics = element:first_of("Graphics")
	if graphics and graphics.attr.texture_file and graphics.attr.texture_file ~= "" then
		if element.attr.tags and element.attr.tags:find("static") then
			return create_virtual_icon(element.attr.name, graphics.attr.texture_file, "mods/lamas_stats/files/gfx/solid_static.png")
		end
		if element.attr.liquid_sand == "1" then
			return create_virtual_icon(element.attr.name, graphics.attr.texture_file, "mods/lamas_stats/files/gfx/pile.png")
		end
	end
	return "data/items_gfx/potion.png"
end

---Parses an element color
---@param element element
---@return string
local function get_color(element)
	local graphics = element:first_of("Graphics")
	if graphics and graphics.attr.color then return graphics.attr.color end
	return element.attr.wang_color
end

---Parses an xml element
---@param element element
local function parse_element(element)
	if not element.attr.name or not element.attr.ui_name then return end
	local material_icon = get_icon(element)
	local material_color = material_icon == "data/items_gfx/potion.png" and abgr_to_rgb(get_color(element))
	mat.buffer[element.attr.name] = {
		id = element.attr.name,
		ui_name = element.attr.ui_name,
		icon = material_icon,
		color = material_color,
		static = not not element.attr.name:find("_static$"),
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
	local xml = result

	for _, element_name in ipairs({ "CellData", "CellDataChild" }) do
		for elem in xml:each_of(element_name) do
			parse_element(elem)
		end
	end
end

---Parses material list
function mat:parse()
	local files = ModMaterialFilesGet()
	for i = 1, #files do
		parse_file(files[i])
	end

	self.invalid = {
		id = "???",
		ui_name = "???",
		icon = "data/items_gfx/potion_normals.png",
		color = false,
		static = false,
	}

	nxml = nil ---@diagnostic disable-line: cast-local-type
end

---Converts buffer data into actual data
function mat:convert()
	for name, value in pairs(self.buffer) do
		self.data[CellFactory_GetType(name)] = value
	end
	self.buffer = {}
end

---Returns data
---@param material_type number
---@return material_data
function mat:get_data(material_type)
	return self.data[material_type] or self.invalid
end

return mat
