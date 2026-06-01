---@class (exact) LS_Gui
---@field private header {pos_x: number, pos_y: number}
local header = {
	header = {
		pos_x = 13,
		pos_y = 60,
	},
}

---Draws the [L]/[*] toggle button that opens and closes the menu.
---@private
function header:header_draw()
	if self:is_text_button_clicked(self.header.pos_x, self.header.pos_y, self.menu.opened and "*" or "L") then
		self.menu.opened = not self.menu.opened

		if self.menu.opened then self:menu_call_current_init() end
	end
end

---Loads header overlay position from mod settings.
---@private
function header:header_get_settings()
	self.header.pos_x = self.mod:GetSettingNumber("overlay_x")
	self.header.pos_y = self.mod:GetSettingNumber("overlay_y")
end

return header
