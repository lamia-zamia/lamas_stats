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

---@class (exact) LS_Gui
---@field private menu LS_Gui_menu
local menu = {
	menu = { ---@diagnostic disable-line: missing-fields
		start_x = 16,
		start_y = 48,
		pos_y = 44,
		opened = false,
		header = "",
		fungal = false,
		perks = false,
		kys = false,
		current_window = nil
	}
}

---Sets width if it's higher than current width
---@private
---@param value number
function menu:MenuSetWidth(value)
	self.menu.width = math.max(self.menu.width, value)
end

---Adds clickable button
---@param text string
---@param tooltip_text string
---@param fn function
function menu:MenuAddButton(text, tooltip_text, fn)
	if self.menu.current_window == fn then
		self:DrawButton(self.menu.pos_x, self.menu.pos_y, self.z - 1, text, false)
		if self:IsHovered() and self:IsLeftClicked() then
			self.menu.current_window = nil
		end
	elseif self:IsButtonClicked(self.menu.pos_x, self.menu.pos_y, self.z - 1, text, tooltip_text) then
		self:FakeScrollBox_Reset()
		self.menu.current_window = fn
	end
	self.menu.pos_x = self.menu.pos_x + self:GetTextDimension(text) + 9
end

---Draw menu
---@private
function menu:MenuDraw()
	self.menu.pos_x = self.menu.start_x
	self.menu.pos_y = self.menu.start_y + 15
	self.menu.width = self:GetTextDimension(self.menu.header)

	if self.menu.fungal then self:MenuAddButton(_T.FungalShifts, "", self.FungalScrollbox) end
	if self.menu.perks then self:MenuAddButton(_T.Perks, "", self.mod.GetGlobalNumber) end
	if self.menu.kys then self:MenuAddButton(_T.KYS_Suicide, "", self.KysDraw) end

	self:MenuSetWidth(self.menu.pos_x - self.menu.start_x - 9)
	self.menu.pos_y = self.menu.pos_y + 15

	self.menu.pos_x = self.menu.start_x
	if self.menu.current_window then self.menu.current_window(self) end

	self:Draw9Piece(self.menu.start_x - 6, self.menu.start_y - 1, self.z + 50, self.menu.width + 12,
		self.menu.pos_y - self.menu.start_y + 2)
	self:TextCentered(self.menu.start_x, self.menu.start_y, self.menu.header, self.menu.width)
end

---Fetch settings
---@private
function menu:MenuGetSettings()
	self.menu.header = self.mod:GetSettingString("lamas_menu_header")
	self.menu.fungal = self.mod:GetSettingBoolean("enable_fungal")
	self.menu.perks = self.mod:GetSettingBoolean("enable_perks")
	self.menu.kys = self.mod:GetSettingBoolean("KYS_Button")
end

return menu
