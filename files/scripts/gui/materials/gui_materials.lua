---@class (exact) LS_Gui_materials
---@field y number
---@field reaction_y number
---@field visible_types { [number]:boolean}
---@field current_recipe integer?
---@field showing_recipe integer?
---@field filter string

---@class (exact) LS_Gui
---@field materials LS_Gui_materials
local materials = {
	materials = {
		y = 0,
		visible_types = {},
		current_recipe = nil,
		showing_recipe = nil,
		reaction_y = 0,
		filter = "",
	},
}

local material_types_enum = dofile_once("mods/lamas_stats/files/scripts/material_types.lua") ---@type material_types_enum
local material_types = {}
for k, v in pairs(material_types_enum) do
	material_types[v] = k
	materials.materials.visible_types[v] = true
end

function materials:show_reactions()
	if not self.materials.showing_recipe then return end
	self.materials.reaction_y = 1 - self.scroll.y
	local material = self.mat:get_data(self.materials.showing_recipe)
	self:FungalDrawSingleMaterial(0, self.materials.reaction_y, self.materials.showing_recipe, true)
	local reactions = self.mat:get_reactions_using(material.id)
	local x = 0
	self.materials.reaction_y = self.materials.reaction_y + 15

	for _, reaction in ipairs(reactions) do
		for _, input in ipairs(reaction.inputs) do
			self:Text(x, self.materials.reaction_y, input)
			x = x + self:GetTextDimension(input) + 5
		end
		self:Text(x, self.materials.reaction_y, "->")
		x = x + 25
		for _, output in ipairs(reaction.outputs) do
			self:Text(x, self.materials.reaction_y, output)
			x = x + self:GetTextDimension(output) + 5
		end
		x = 0
		self.materials.reaction_y = self.materials.reaction_y + 11
	end
	self:Text(0, self.materials.reaction_y + self.scroll.y, "")
end

function materials:material_in_filter(material_index)
	local material = self.mat:get_data(material_index)
	if not self.materials.visible_types[material.type] then return end
	if material.id:find(self.materials.filter) then return true end
	if material.ui_name:find(self.materials.filter) then return true end
	if self:Locale(material.ui_name):find(self.materials.filter) then return true end
end

---Draws single material
---@param y number
---@param material_index integer
function materials:materials_draw_material(y, material_index)
	-- local material_type = self.mat:get_data(material_index).type
	if not self:material_in_filter(material_index) then return end

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
	self.materials.filter = self.textbox:draw_textbox(self.menu.pos_x, self.menu.pos_y, self.z + 1, 100, 9, self.materials.filter)
end

---Draws materials window
function materials:materials_draw_window()
	self:materials_draw_checkboxes()
	self:materials_textbox()
	self:MenuSetWidth(300)

	self.menu.pos_y = self.menu.pos_y + 12
	self:ScrollBox(
		self.menu.start_x - 3,
		self.menu.pos_y + 7,
		self.z + 5,
		306,
		self.max_height,
		self.c.default_9piece,
		3,
		3,
		self.materials_draw_list
	)
	if self.materials.showing_recipe then
		self:ScrollBox(
			self.menu.start_x + self.menu.width + 18,
			self.menu.start_y + 3,
			self.z + 5,
			250,
			200,
			self.c.default_9piece,
			3,
			3,
			self.show_reactions
		)
	end
end

return materials
