---@class (exact) LS_Gui_menu
---@field start_x number
---@field start_y number
---@field width number
---@field pos_x number
---@field pos_y number
---@field opened boolean
---@field package header string
---@field package fungal boolean
---@field package perks boolean
---@field package kys boolean
---@field package current_window function|nil
---@field package previous_window function|nil

---@class (exact) LS_Gui
---@field private menu LS_Gui_menu
local menu = {
	menu = { ---@diagnostic disable-line: missing-fields
		start_x = 16,
		start_y = 48,
		pos_y = 44,
		opened = false,
		header = "== LAMA'S STATS ==",
		fungal = false,
		perks = false,
		kys = false,
		current_window = nil,
		previous_window = nil,
	},
}

---Draws tooltip near menu
---@param background string
---@param tooltip_fn function
---@param ... any
function menu:MenuTooltip(background, tooltip_fn, ...)
	self.tooltip_img = background
	self:ShowTooltip(self.menu.start_x + self.menu.width + 18, self.menu.start_y + 3, tooltip_fn, ...)
	self.tooltip_img = self.default_tooltip
end

---Sets width if it's higher than current width
---@private
---@param value number
function menu:MenuSetWidth(value)
	self.menu.width = math.max(self.menu.width, value)
end

---Adds clickable button
---@param text string
---@param fn function
---@param run? function
function menu:MenuAddButton(text, fn, run)
	if self.menu.current_window == fn then
		self:DrawButton(self.menu.pos_x, self.menu.pos_y, self.z - 1, text, false)
		if self:IsHovered() and self:IsLeftClicked() then self.menu.current_window = nil end
	else
		self:DrawButton(self.menu.pos_x, self.menu.pos_y, self.z - 1, text, true)
		if self:IsHovered() and self:IsLeftClicked() then
			-- self:ScrollBoxReset()
			if run then run(self) end
			self.menu.current_window = fn
		end
	end
	self.menu.pos_x = self.menu.pos_x + self:GetTextDimension(text) + 9
end

---Draw menu
---@private
function menu:MenuDraw()
	self:AnimateStart(false)
	self.menu.pos_x = self.menu.start_x
	self.menu.pos_y = self.menu.start_y + 15
	self.menu.width = self:GetTextDimension(self.menu.header)

	if self.config.show_fungal_menu then self:MenuAddButton(T.FungalShifts, self.FungalDrawWindow, self.FungalInit) end
	if self.config.show_perks_menu then self:MenuAddButton(T.Perks, self.PerksDrawWindow, self.PerksInit) end
	if self.config.show_materials then self:MenuAddButton(T.materials, self.materials_draw_window) end
	if self.config.show_kys_menu then self:MenuAddButton(T.KYS_Suicide, self.KysDraw) end
	self:MenuAddButton(T.config, self.ConfigDrawScrollBox, self.ConfigInit)

	self:MenuSetWidth(self.menu.pos_x - self.menu.start_x - 9)
	self.menu.pos_y = self.menu.pos_y + 17

	self:AnimateStart(self.menu.previous_window ~= self.menu.current_window)
	self.menu.pos_x = self.menu.start_x

	if self.menu.current_window then self.menu.current_window(self) end

	self:AnimateE()
	self:Draw9Piece(self.menu.start_x - 6, self.menu.start_y - 1, self.z + 50, self.menu.width + 12, self.menu.pos_y - self.menu.start_y)
	if self:IsHoverBoxHovered(self.menu.start_x - 9, self.menu.start_y - 4, self.menu.width + 18, self.menu.pos_y - self.menu.start_y + 6, true) then
		self:BlockInput()
	end

	self:Text(self.menu.start_x, self.menu.start_y, self.menu.header)
	self:AnimateE()
	self.menu.previous_window = self.menu.current_window
end

return menu
