---@class (exact) LS_Gui_materials
---@field y number

---@class (exact) LS_Gui
---@field materials LS_Gui_materials
local materials = {
	materials = {
		y = 0,
	},
}

---Draws single material
---@param y number
---@param material_index integer
function materials:materials_draw_material(y, material_index)
	if not self:fungal_is_element_visible(y, 10) then
		self.materials.y = self.materials.y + 10
		return
	end
	self:FungalDrawSingleMaterial(0, y, material_index, true)
	self.materials.y = self.materials.y + 10
end

---Draws materials list
---@private
function materials:materials_draw_list()
	self:AddOption(self.c.options.NonInteractive)

	self.materials.y = 1 - self.scroll.y
	for material_index, _ in pairs(self.mat.data) do
		self:materials_draw_material(self.materials.y, material_index)
	end

	self:RemoveOption(self.c.options.NonInteractive)
	self:Text(0, self.materials.y + self.scroll.y, "")
end

---Draws materials window
function materials:materials_draw_window()
	self.menu.pos_y = self.menu.pos_y + 12
	self:ScrollBox(self.menu.start_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self.materials_draw_list)
	self:MenuSetWidth(self.scroll.width - 6)
end

return materials
