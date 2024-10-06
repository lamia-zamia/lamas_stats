---@class (exact) LS_Gui
local future = {}

---Draws individual shift in tooltip
---@private
---@param y number
---@param shift shift
---@param offset number
function future:FungalDrawFutureTooltipShift(y, shift, offset)
	local x = 3
	self.fungal.row_count = self:FungalCalculateRowCount(shift.from, shift.to, shift.flask)

	self:FungalDrawFromMaterials(x, y, shift.from, shift.flask == "from")
	x = x + offset + 15
	self:FungalDrawArrow(x, y)
	x = x + 15
	self:FungalDrawToMaterial(x, y, shift.to, shift.flask == "to")
end

---Draws failed shift in tooltip
---@private
---@param y number
---@param shift shift
---@param offset number
function future:FungalDrawFutureTooltipShiftFailed(y, shift, offset)
	self:Text(0, y, _T.lamas_stats_fungal_if_fail)
	self:FungalDrawFlaskAvailablity(self.fungal.offset.ifnot + 3, y)
	self:Text(self.fungal.offset.ifnot + self.fungal.offset.held + 14, y, _T.lamas_stats_then)
	y = y + 10

	self:FungalDrawFutureTooltipShift(y, shift.failed, offset)
end

---Draws force failed shift in tooltip
---@private
---@param y number
---@param shift shift
---@param offset number
function future:FungalDrawFutureTooltipShiftForceFailed(y, shift, offset)
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
	local material = shift.flask == "from" and shift.to or shift.force_failed.from[1]
	self:FungalDrawSingleMaterial(x + 5, y, material)

	self:FungalDrawFutureTooltipShift(y + 10, shift.force_failed, offset)
end

---Draws greedy information
---@param y integer
---@param greedy greedy_shift
function future:FungalDrawFutureTooltipGreedy(y, greedy)
	self:FungalDrawSingleMaterial(0, y, greedy.gold)
	self:FungalDrawSingleMaterial(50, y, greedy.grass)
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
	y = y + 10 * self.fungal.row_count
	if not self.fs.predictor.is_using_new_shift then return end

	if shift.greedy then
		self:FungalDrawFutureTooltipGreedy(y, shift.greedy)
		y = y + 10
	end
	y = y + 5

	if shift.failed then
		self:FungalDrawFutureTooltipShiftFailed(y, shift, offset_from)
		y = y + 10 * self.fungal.row_count + 15
	end
	if shift.force_failed then
		self:FungalDrawFutureTooltipShiftForceFailed(y, shift, offset_from)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

---Draws future shifts
---@private
function future:FungalDrawFuture()
	for i = self.fs.current_shift, self.fs.max_shifts do
		local shift = self.fs.predictor.shifts[i]
		local from = self:FungalSanitizeFromShifts(shift.from)
		self.fungal.row_count = self:FungalCalculateRowCount(from, shift.to, shift.flask)
		local height = self.fungal.row_count * 10
		local hovered = self:FungalIsHoverBoxHovered(self.fungal.x, self.fungal.y, height)
		if hovered then
			if i == self.fs.current_shift then
				self:Color(0.4, 1, 0.5)
			else
				self:Color(0.2, 0.6, 0.7)
			end
		elseif i == self.fs.current_shift then
			self:Color(0.6, 1, 0.1)
		else
			local color = i % 2 == 0 and 0.4 or 0.6
			self:Color(color, color, color)
		end
		self:SetZ(self.z + 4)
		self:Image(self.fungal.x - 3, self.fungal.y - 1, self.c.px, 0.2, self.fungal.width - 3, height + 1)

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
