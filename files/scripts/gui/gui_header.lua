--- @class (exact) LS_Gui
--- @field private header {pos_x: number, pos_y: number}
local header = {
	header = {
		pos_x = 13,
		pos_y = 60
	}
}

--- Draws a header
--- @private
function header:HeaderDraw()
	if self:IsTextButtonClicked(self.header.pos_x, self.header.pos_y, self.menu.opened and "*" or "L") then
		self.menu.opened = not self.menu.opened
	end
end

--- Fetches settings
--- @private
function header:HeaderGetSettings()
	self.header.pos_x = self.mod:GetSettingNumber("overlay_x")
	self.header.pos_y = self.mod:GetSettingNumber("overlay_y")
end

return header
