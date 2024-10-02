---@class LS_Gui_menu
---@field pos_x number
---@field pos_y number
---@field opened boolean
---@field header string

---@class LS_Gui
---@field private menu LS_Gui_menu
local menu = {
	menu = {
		pos_x = 2,
		pos_y = 12,
		opened = false,
		header = ""
	}
}

---Draw menu
---@private
function menu:MenuDraw()
	self.menu.pos_x = 2
	self.menu.pos_y = 12
	self:Text(self.menu.pos_x, self.menu.pos_y, self.menu.header)

	-- if ModSettingGet("lamas_stats.stats_position") == "merged" then
	-- 	GuiText(gui_menu, 0, 0, " ")
	-- 	local _, _, _, x, y = GuiGetPreviousWidgetInfo(gui_menu)
	-- 	GuiLayoutBeginLayer(gui_menu)
	-- 	GUI_Stats(gui_menu, id(), x, y)
	-- 	GuiLayoutEndLayer(gui_menu)
	-- end

	-- for _, button in ipairs(lamas_stats_main_menu_buttons) do
	-- 	if GuiButton(gui_menu, id(), 0, 0, button.ui_name) then
	-- 		button.action()
	-- 	end
	-- end
	-- GuiLayoutEnd(gui_menu) --layer1
end

---Fetch settings
---@private
function menu:MenuGetSettings()
	self.menu.header = self.mod:GetSettingString("lamas_menu_header")
end

return menu
