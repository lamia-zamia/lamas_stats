---@class (exact) LS_Gui
local future = {}

---Draws individual shift in tooltip
---@private
---@param y number
---@param shift shift
---@param offset number
function future:FungalDrawFutureTooltipShift(y, shift, offset)
	local x = 0
	self.fungal.row_count = self:FungalCalculateRowCount(shift.from, shift.to, shift.flask)
	
	self:FungalDrawFromMaterials(x, y, shift.from, shift.flask == "from")
	x = x + offset + 15
	self:FungalDrawArrow(x, y)
	x = x + 15
	self:FungalDrawToMaterial(x, y, shift.to, shift.flask == "to")
end

---Draws tooltip for future shift
---@private
---@param shift shift
---@param i number
function future:FungalDrawFutureTooltip(shift, i)
	self:AddOption(self.c.options.Layout_NextSameLine)
	local y = 0

	local offset_from, offset_to = self:FungalGetLongestTextInShift(shift, 0, 0)
	offset_from, offset_to = self:FungalGetLongestTextInShift(shift.failed, offset_from, offset_to, true)
	offset_from, offset_to = self:FungalGetLongestTextInShift(shift.force_failed, offset_from, offset_to, true)

	self:Text(0, y, string.format(_T.lamas_stats_shift .. " %02d", i))
	y = y + 10
	self:FungalDrawFutureTooltipShift(y, shift, offset_from)
	y = y + 10 * self.fungal.row_count + 5

	if shift.failed then
		self:Text(0, y, _T.lamas_stats_fungal_if_fail)
		self:FungalDrawFlaskAvailablity(self.fungal.offset.ifnot + 3, y)
		self:Text(self.fungal.offset.ifnot + self.fungal.offset.held + 14, y, _T.lamas_stats_then)
		y = y + 10
		self:FungalDrawFutureTooltipShift(y, shift.failed, offset_from)
		y = y + 10 * self.fungal.row_count + 5
	end
	if shift.force_failed then
		local x = 0
		if shift.failed then
			self:Text(x, y, _T.lamas_stats_or)
			x = x + self.fungal.offset._or + 3
		end
		self:Text(x, y, _T.lamas_stats_if)
		x = x + self.fungal.offset._if + 3
		self:FungalDrawFlaskAvailablity(x, y)
		x = x + self.fungal.offset.held + 10
		self:Text(x, y, "=")
		local material = shift.flask == "from" and shift.to or shift.from[1]
		self:FungalDrawSingleMaterial(x + 5, y, material)
		y = y + 10
		self:FungalDrawFutureTooltipShift(y, shift.force_failed, offset_from)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

---Draws future shifts
---@private
function future:FungalDrawFuture()
	for i = self.fs.current_shift, 20 do
		local shift = self.fs.predictor.shifts[i]
		local from = self:FungalSanitizeFromShifts(shift.from)
		self.fungal.row_count = self:FungalCalculateRowCount(from, shift.to, shift.flask)
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
				shift, i)
		end

		self.fungal.y = self.fungal.y + height + 1
		self.fungal.x = 3
	end
end

return future
