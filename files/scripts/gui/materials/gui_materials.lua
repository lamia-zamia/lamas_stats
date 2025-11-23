---@class (exact) LS_Gui_materials
---@field y number
---@field reaction_y number
---@field visible_types { [number]:boolean}
---@field current_recipe integer?
---@field showing_recipe integer?
---@field filter string
---@field width number
---@field width_reaction number

---@class (exact) LS_Gui
---@field materials LS_Gui_materials
local materials = {
	materials = {
		y = 0,
		visible_types = {},
		current_recipe = nil,
		reaction_y = 0,
		filter = "",
		width = 200,
		width_reaction = 256,
	},
}

local material_types_enum = dofile_once("mods/lamas_stats/files/scripts/material_types.lua") ---@type material_types_enum
local material_types = {}
for k, v in pairs(material_types_enum) do
	material_types[v] = k
	materials.materials.visible_types[v] = true
end

---@param x number
---@param y number
---@param reaction reactions_data
function materials:show_reaction(x, y, reaction)
	for _, input in ipairs(reaction.inputs) do
		-- self:FungalDrawSingleMaterial(x, y, CellFactory_GetType(input), false)
		self:Text(x, y, input)
		x = x + self:GetTextDimension(input) + 5
	end
	self:Text(x, y, "->")
	x = x + 25
	for _, output in ipairs(reaction.outputs) do
		-- self:FungalDrawSingleMaterial(x, y, CellFactory_GetType(output), false)
		self:Text(x, y, output)
		x = x + self:GetTextDimension(output) + 5
	end
end

function materials:show_reactions()
	self.materials.reaction_y = 1 - self.scroll.y
	local material = self.mat:get_data(self.materials.showing_recipe)
	-- self:FungalDrawSingleMaterial(0, self.materials.reaction_y, self.materials.showing_recipe, true)
	local x = 0
	self.materials.reaction_y = self.materials.reaction_y + 15

	local reactions_using = self.mat:get_reactions_using(material.id)
	if #reactions_using > 0 then
		self:Text(x + 30, self.materials.reaction_y, "using")
		self.materials.reaction_y = self.materials.reaction_y + 15
		for _, reaction in ipairs(reactions_using) do
			self:show_reaction(x, self.materials.reaction_y, reaction)
			self.materials.reaction_y = self.materials.reaction_y + 11
		end
	end

	local reactions_producing = self.mat:get_reactions_producing(material.id)
	if #reactions_producing > 0 then
		self:Text(x + 30, self.materials.reaction_y, "producing")
		self.materials.reaction_y = self.materials.reaction_y + 15
		for _, reaction in ipairs(reactions_producing) do
			self:show_reaction(x, self.materials.reaction_y, reaction)
			self.materials.reaction_y = self.materials.reaction_y + 11
		end
	end

	self:Text(0, self.materials.reaction_y + self.scroll.y, "")
end

---@param tags material_tags
function materials:draw_material_tags(tags)
	for tag, _ in pairs(tags) do
		self:Text(0, 0, tag)
		-- tag_offset = tag_offset + self:GetTextDimension(tag) + 3
	end
end

function materials:draw_reaction_window()
	local material_type = self.materials.showing_recipe
	if not material_type then return end

	local x = self.menu.start_x + self.menu.width + 15
	local y = self.menu.start_y - 1
	local width = self.materials.width_reaction
	self:Draw9Piece(x, y, self.z + 5, width, 30)

	local material_data = self.mat:get_data(material_type)

	-- draw tags?
	if material_data.tags then
		local tags_text = "[tags]"
		local tags_width = self:GetTextDimension(tags_text)
		self:Text(x + width - tags_width, y, tags_text)
		if self:IsHovered() then self:ShowTooltipCenteredX(0, 20, self.draw_material_tags, material_data.tags) end
	end

	-- draw material name
	local material_name = self:FungalGetName(material_data)
	local name_offset = (width - self:GetTextDimension(material_name)) / 2
	self:FungalDrawIcon(x + name_offset - 9, y, material_data)
	self:Text(x + name_offset, y, material_name)
	y = y + 10

	-- draw material id
	local material_id = string.format("(%s)", material_data.id)
	local id_offset = (width - self:GetTextDimension(material_id)) / 2
	self:ColorGray()
	self:Text(x + id_offset, y, material_id)
	y = y + 10

	self:ScrollBox(x + 3, y + 18, self.z + 5, width - 6, 200, self.c.default_9piece, 3, 3, self.show_reactions)
end

function materials:is_material_in_filter(material_index)
	local material = self.mat:get_data(material_index)
	if not self.materials.visible_types[material.type] then return end
	local filter = self.materials.filter
	if material.id:find(filter) then return true end
	if material.ui_name:find(filter) then return true end
	if self:Locale(material.ui_name):find(filter) then return true end
end

---Draws single material
---@param y number
---@param material_index integer
function materials:materials_draw_material(y, material_index)
	-- local material_type = self.mat:get_data(material_index).type
	if not self:is_material_in_filter(material_index) then return end

	if not self:fungal_is_element_visible(y, 10) then
		self.materials.y = self.materials.y + 10
		return
	end

	self:FungalDrawSingleMaterial(0, y, material_index, true)

	local hovered = self:IsHoverBoxHovered(self.menu.start_x - 6, self.menu.pos_y + y + 7, self.fungal.width - 3, 10)
	if hovered then
		self.materials.showing_recipe = material_index
		if self:IsLeftClicked() then self.materials.current_recipe = material_index end
	end

	self.materials.y = self.materials.y + 10
end

---Draws materials list
---@private
function materials:materials_draw_list()
	self:AddOption(self.c.options.NonInteractive)

	self.materials.y = 1 - self.scroll.y

	self.materials.showing_recipe = self.materials.current_recipe
	for material_index, _ in pairs(self.mat.data) do
		self:materials_draw_material(self.materials.y, material_index)
	end

	self:RemoveOption(self.c.options.NonInteractive)
	self:Text(0, self.materials.y + self.scroll.y, "")
end

function materials:materials_draw_checkboxes()
	local x = self.menu.pos_x
	for material_type, type_name in ipairs(material_types) do
		if self:IsDrawCheckbox(x, self.menu.pos_y - 1, type_name, self.materials.visible_types[material_type]) and self:IsMouseClicked() then
			self.materials.visible_types[material_type] = not self.materials.visible_types[material_type]
		end
		x = x + self:GetTextDimension(type_name) + 18
	end
end

function materials:materials_textbox()
	self.menu.pos_y = self.menu.pos_y + 12
	local text = "Search:"
	local text_width = self:GetTextDimension(text)
	self:Text(self.menu.pos_x, self.menu.pos_y, text)
	self.materials.filter = self.textbox:draw_textbox(self.menu.pos_x + text_width + 5, self.menu.pos_y, self.z + 1, 100, 9, self.materials.filter)
end

---Draws materials window
function materials:materials_draw_window()
	self:materials_draw_checkboxes()
	self:materials_textbox()
	self:MenuSetWidth(self.materials.width)

	self.menu.pos_y = self.menu.pos_y + 12
	self:ScrollBox(
		self.menu.start_x - 3,
		self.menu.pos_y + 7,
		self.z + 5,
		self.materials.width + 6,
		self.max_height,
		self.c.default_9piece,
		3,
		3,
		self.materials_draw_list
	)
	self:draw_reaction_window()
end

-- function materials:update() end

return materials
