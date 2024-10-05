---@class (exact) LS_Gui
local future = {}

---Draws tooltip for future shift
---@private
---@param shift shift
function future:FungalDrawFutureTooltip(shift)
	self:AddOption(self.c.options.Layout_NextSameLine)
	local x = 0
	local y = 0
	if shift.flask then
		self:Text(x, y, _T.lamas_stats_fungal_shift_possible .. "!")
		y = y + 15
	end
	self.fungal.row_count = self:FungalCalculateRowCount(shift.from, false)
	local offset_from, offset_to = self:FungalGetLongestTextInShift(shift, 0, 0)
	self:FungalDrawFromMaterials(x, y, shift.from, false)
	x = x + offset_from + 15
	local y_offset = self:FungalGetShiftWindowOffset(1)
	self:Text(x, y + y_offset, "->")
	x = x + 15
	self:FungalDrawToMaterial(x, y, shift.to, false)
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

---Draws future shifts
---@private
function future:FungalDrawFuture()
	for i = self.fs.current_shift, 20 do
		local shift = self.fs.predictor.shifts[i]
		local from = self:FungalSanitizeFromShifts(shift.from)
		self.fungal.row_count = self:FungalCalculateRowCount(from, shift.flask)
		local height = self.fungal.row_count * 10
		local hovered = self:FungalIsHoverBoxHovered(self.fungal.x, self.fungal.y, height)

		if hovered then
			self:Color(0.2, 0.6, 0.7)
		else
			local color = i % 2 == 0 and 0.4 or 0.6
			self:Color(color, color, color)
		end
		self:SetZ(self.z + 4)
		self:Image(self.fungal.x - 3, self.fungal.y - 1, self.c.px, 0.2, 640, height + 1)

		self:FungalDrawShiftNumber(i)
		self:FungalDrawFromMaterials(self.fungal.x, self.fungal.y, from, shift.flask == "from")
		self.fungal.x = self.fungal.x + self.fungal.offset.from
		self:FungalDrawArrow(self.fungal.x, self.fungal.y)
		self.fungal.x = self.fungal.x + 15
		self:FungalDrawToMaterial(self.fungal.x, self.fungal.y, shift.to, shift.flask == "to")
		self.fungal.x = self.fungal.x + self.fungal.offset.to

		if hovered then
			self:ShowTooltip(self.menu.start_x + self.fungal.width + 12, self.menu.start_y + 3,
				self.FungalDrawFutureTooltip,
				shift)
		end

		self.fungal.y = self.fungal.y + height + 1
		self.fungal.x = 3
	end
end

return future
