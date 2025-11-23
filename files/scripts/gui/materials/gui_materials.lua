---@class (exact) LS_Gui_materials
---@field y number
---@field reaction_y number
---@field visible_types { [number]:boolean}
---@field current_recipe integer?
---@field showing_recipe integer?
---@field filter string
---@field width number
---@field width_reaction number
---@field reaction_show_output boolean

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
		reaction_show_output = false,
	},
}

local material_types_enum = dofile_once("mods/lamas_stats/files/scripts/material_types.lua") ---@type material_types_enum
local material_types = {}
for k, v in pairs(material_types_enum) do
	material_types[v] = k
	materials.materials.visible_types[v] = true
end

---Draws material centered
---@param x number
---@param y number
---@param material_data material_data
---@param width number
---@param alt boolean?
function materials:draw_material_centered(x, y, material_data, width, alt)
	local material_name = alt and material_data.id or self:FungalGetName(material_data)
	local name_offset = (width - self:GetTextDimension(material_name)) / 2
	self:FungalDrawIcon(x + name_offset - 9, y, material_data)
	self:Text(x + name_offset, y, material_name)
end

---Draws material row in reaction
---@param x number
---@param y number
---@param material string
---@param width number
function materials:draw_reaction_row(x, y, material, width)
	if material:sub(1, 1) == "[" then
		local text_width = self:GetTextDimension(material)
		self:Text(x + (width - text_width) / 2, self.materials.reaction_y, material)
	else
		self:draw_material_centered(x, self.materials.reaction_y, self.mat:get_data_by_id(material), width, self.alt)
	end
end

---@param reaction reactions_data
function materials:show_reaction(reaction)
	local x = 0
	local width = self.materials.width_reaction / #reaction.inputs
	for _, input in ipairs(reaction.inputs) do
		self:draw_reaction_row(x, self.materials.reaction_y, input, width)
		x = x + width
		self:Text(x, self.materials.reaction_y, "+")
	end
	x = 0
	self.materials.reaction_y = self.materials.reaction_y + 10
	for _, output in ipairs(reaction.outputs) do
		self:draw_reaction_row(x, self.materials.reaction_y, output, width)
		x = x + width
	end
	self.materials.reaction_y = self.materials.reaction_y + 11
end

---Draws a separator line
---@private
function materials:draw_reaction_separator()
	self:Image(0, self.materials.reaction_y - 1, self.c.px, 0.4, self.materials.width_reaction - 10, 1)
end

---Draws reactions
---@private
function materials:show_reactions()
	self.materials.reaction_y = 1 - self.scroll.y
	local material = self.mat:get_data(self.materials.showing_recipe)
	local reactions = self.materials.reaction_show_output and self.mat:get_reactions_producing(material.id)
		or self.mat:get_reactions_using(material.id)

	if #reactions > 0 then
		self:draw_reaction_separator()
		for _, reaction in ipairs(reactions) do
			self:show_reaction(reaction)
			self:draw_reaction_separator()
		end
	else
		self:Text(0, self.materials.reaction_y, "None")
		self.materials.reaction_y = self.materials.reaction_y + 11
	end

	self:Text(0, self.materials.reaction_y + self.scroll.y, "")
end

---Draws material tags, tooltip
---@private
---@param tags material_tags
function materials:draw_material_tags(tags)
	for tag, _ in pairs(tags) do
		self:Text(0, 0, tag)
	end
end

---Draws output/input button
---@private
---@param x number
---@param y number
---@param width number
---@param label string
---@param is_active boolean
---@param on_click boolean
function materials:draw_reaction_toggle_button(x, y, width, label, is_active, on_click)
	local text_width = self:GetTextDimension(label)
	local text_offset = (width - text_width) / 2

	if not is_active then self:AddOptionForNext(self.c.options.ForceFocusable) end
	self:Draw9Piece(x, y + 2, self.z + 4, width, 8, self.buttons.img)

	if is_active then
		self:ColorYellow()
	elseif self:IsHovered() and self:IsLeftClicked() then
		self.materials.reaction_show_output = on_click
		GamePlaySound("ui", "ui/button_click", 0, 0)
	end

	self:Text(x + text_offset, y + 1, label)
end

---Draws reaction window
---@private
function materials:draw_reaction_window()
	local material_type = self.materials.showing_recipe
	if not material_type then return end

	local x = self.menu.start_x + self.menu.width + 15
	local y = self.menu.start_y - 1
	local width = self.materials.width_reaction
	self:Draw9Piece(x, y, self.z + 5, width, 32)
	if self:IsHovered() then self:BlockInput() end

	local material_data = self.mat:get_data(material_type)

	-- draw tags?
	if material_data.tags then
		local tags_text = "[tags]"
		local tags_width = self:GetTextDimension(tags_text)
		local pos_x = x + width - tags_width
		local is_hovered = self:IsHoverBoxHovered(pos_x, y, tags_width, 10)
		if is_hovered then
			self:ShowTooltipCenteredX(0, 20, self.draw_material_tags, material_data.tags)
			self:ColorYellow()
		end
		self:Text(x + width - tags_width, y, tags_text)
	end

	-- draw material name
	self:draw_material_centered(x, y, material_data, width)
	y = y + 10

	-- draw material id
	local material_id = string.format("(%s)", material_data.id)
	local id_offset = (width - self:GetTextDimension(material_id)) / 2
	self:ColorGray()
	self:Text(x + id_offset, y, material_id)
	y = y + 10

	-- buttons
	local buttons_width = width / 2 - 6
	local is_output = self.materials.reaction_show_output
	self:draw_reaction_toggle_button(x + 3, y, buttons_width, "Using", not is_output, false)
	self:draw_reaction_toggle_button(x + 9 + buttons_width, y, buttons_width, "Producing", is_output, true)

	self:ScrollBox(x + 3, y + 20, self.z + 5, width - 6, 200, self.c.default_9piece, 3, 3, self.show_reactions)
end

---Checks if material should be shown
---@param material_index integer
---@return boolean?
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

---Draws filter checkboxes
---@private
function materials:materials_draw_checkboxes()
	local x = self.menu.pos_x
	for material_type, type_name in ipairs(material_types) do
		if self:IsDrawCheckbox(x, self.menu.pos_y - 1, type_name, self.materials.visible_types[material_type]) and self:IsMouseClicked() then
			self.materials.visible_types[material_type] = not self.materials.visible_types[material_type]
		end
		x = x + self:GetTextDimension(type_name) + 18
	end
end

---Draws searchbox
---@private
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
	local pos_x = self.menu.start_x - 3
	local pos_y = self.menu.pos_y + 7
	self:ScrollBox(pos_x, pos_y, self.z + 5, self.materials.width + 6, self.max_height, self.c.default_9piece, 3, 3, self.materials_draw_list)
	self:draw_reaction_window()
end

-- function materials:update() end

return materials
