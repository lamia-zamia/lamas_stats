---@class LS_Gui_fungal

---@class (exact) LS_Gui
local fungal = {}

function fungal:FungalDraw()
	self:Text(0, 0, "wtf")
	self:Text(0, 30, "rly")
end

function fungal:FungalScrollbox()
	self:FakeScrollBox(self.menu.pos_x - 6, self.menu.pos_y + 6, self.z + 5, self.c.default_9piece, self.FungalDraw)
end

return fungal