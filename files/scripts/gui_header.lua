---@class LS_Gui
local header = {
	header = {
		pos_x = 13,
		pos_y = 8
	}
}

function header:HeaderDraw()
	if self:IsTextButtonClicked(self.header.pos_x, self.header.pos_y, self.menu.opened and "*" or "L") then
		self.menu.opened = not self.menu.opened
	end
end

return header
