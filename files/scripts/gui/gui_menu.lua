--- @class (exact) LS_Gui_menu
--- @field start_x number
--- @field start_y number
--- @field width number
--- @field pos_x number
--- @field pos_y number
--- @field opened boolean
--- @field package header string
--- @field package fungal boolean
--- @field package perks boolean
--- @field package kys boolean
--- @field package current_window function|nil
--- @field package previous_window function|nil

--- @class (exact) LS_Gui
--- @field private menu LS_Gui_menu
local menu = {
	menu = { --- @diagnostic disable-line: missing-fields
		start_x = 16,
		start_y = 48,
		pos_y = 44,
		opened = false,
		header = "",
		fungal = false,
		perks = false,
		kys = false,
		current_window = nil,
		previous_window = nil
	}
}

--- Sets width if it's higher than current width
--- @private
--- @param value number
function menu:MenuSetWidth(value)
	self.menu.width = math.max(self.menu.width, value)
end

--- Adds clickable button
--- @param text string
--- @param fn function
--- @param run? function
function menu:MenuAddButton(text, fn, run)
	if self.menu.current_window == fn then
		self:DrawButton(self.menu.pos_x, self.menu.pos_y, self.z - 1, text, false)
		if self:IsHovered() and self:IsLeftClicked() then
			self.menu.current_window = nil
		end
	else
		self:DrawButton(self.menu.pos_x, self.menu.pos_y, self.z - 1, text, true)
		if self:IsHovered() and self:IsLeftClicked() then
			self:ScrollBoxReset()
			self.scroll.height_max = self.max_height
			if run then run(self) end
			self.menu.current_window = fn
		end
	end
	self.menu.pos_x = self.menu.pos_x + self:GetTextDimension(text) + 9
end

--- Draw menu
--- @private
function menu:MenuDraw()
	self:AnimateB()
	self:AnimateAlpha(0.1, 0.1, false)
	self:AnimateScale(0.1, false)
	self.menu.pos_x = self.menu.start_x
	self.menu.pos_y = self.menu.start_y + 15
	self.menu.width = self:GetTextDimension(self.menu.header)

	if self.menu.fungal then self:MenuAddButton(T.FungalShifts, self.FungalDrawWindow, self.FungalInit) end
	if self.menu.perks then self:MenuAddButton(T.Perks, self.PerksDrawWindow, self.PerksInit) end
	if self.menu.kys then self:MenuAddButton(T.KYS_Suicide, self.KysDraw) end

	self:MenuSetWidth(self.menu.pos_x - self.menu.start_x - 9)
	self.menu.pos_y = self.menu.pos_y + 17

	local reset_anim = self.menu.previous_window ~= self.menu.current_window
	self:AnimateB()
	self:AnimateAlpha(0.1, 0.1, reset_anim)
	self:AnimateScale(0.1, reset_anim)
	self.menu.pos_x = self.menu.start_x

	if self.menu.current_window then self.menu.current_window(self) end

	self:AnimateE()
	self:Draw9Piece(self.menu.start_x - 6, self.menu.start_y - 1, self.z + 50, self.menu.width + 12,
		self.menu.pos_y - self.menu.start_y)

	self:Text(self.menu.start_x, self.menu.start_y, self.menu.header)
	self:AnimateE()
	self.menu.previous_window = self.menu.current_window
end

--- Fetch settings
--- @private
function menu:MenuGetSettings()
	self.menu.header = self.mod:GetSettingString("lamas_menu_header")
	self.menu.fungal = self.mod:GetSettingBoolean("enable_fungal")
	self.menu.perks = self.mod:GetSettingBoolean("enable_perks")
	self.menu.kys = self.mod:GetSettingBoolean("KYS_Button")
end

return menu
