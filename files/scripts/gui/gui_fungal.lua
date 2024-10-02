---@class LS_Gui_fungal

---@class (exact) LS_Gui
local fungal = {}

---@param color {r:number, g:number, b:number, a:number}
function fungal:FungalPotionColor(color)
	self:Color(color.r, color.g, color.b, color.a)
end

---@param x number
---@param y number
---@param data material_data
function fungal:FungalDrawIcon(x, y, data)
	if data.color then
		self:FungalPotionColor(data.color)
	end
	self:Image(x, y, data.icon)
end

function fungal:FungalDraw()
	local x = 0
	local y = 0
	for i = 1, 20 do
		local shift = self.sp.shifts[i]
		self:Text(x, y, "from: ")
		x = x + 30
		for j = 1, #shift.from do
			local data = self.mat:get_data(shift.from[j])
			self:FungalDrawIcon(x, y, data)
			x = x + 10
		end
		self:Text(x, y, " -> to: ")
		x = x + 40

		local data = self.mat:get_data(shift.to[1])
		self:FungalDrawIcon(x, y, data)

		y = y + 10
		x = 0
	end
	-- self:Text(0, 0, "wtf")
	-- if self:IsButtonClicked(0, 30, self.z, "test 1", "") then
	-- 	self.sp:get_shift(1)
	-- end
	-- if self:IsButtonClicked(0, 60, self.z, "test 2", "") then
	-- 	self.sp:get_shift(2)
	-- end
end

function fungal:FungalScrollbox()
	self:FakeScrollBox(self.menu.pos_x - 6, self.menu.pos_y + 6, self.z + 5, self.c.default_9piece, self.FungalDraw)
end

return fungal