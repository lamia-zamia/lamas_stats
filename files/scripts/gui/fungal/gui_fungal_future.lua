--- @class (exact) LS_Gui
local future = {}

--- Draws individual shift in tooltip
--- @private
--- @param y number
--- @param shift shift|failed_shift
--- @param offset number
function future:FungalDrawFutureTooltipShift(y, shift, offset)
	local x = 3
	self.fungal.row_count = self:FungalCalculateRowCount(shift.from, shift.to, shift.flask)

	self:FungalDrawFromMaterials(x, y, shift.from, shift.flask == "from", self.alt)
	x = x + offset + (self.alt and 3 or 15)
	self:FungalDrawArrow(x, y)
	x = x + 15
	self:FungalDrawToMaterial(x, y, shift.to, shift.flask == "to", self.alt)
end

--- Draws failed shift in tooltip
--- @private
--- @param y number
--- @param shift shift
--- @param offset number
function future:FungalDrawFutureTooltipShiftFailed(y, shift, offset)
	local x = 0
	x = x + self:FungalText(x, y, T.lamas_stats_fungal_if_fail) + 3
	self:FungalDrawHeldMaterial(x, y, { 1, 1, 0.4 })
	x = x + self.fungal.offset.held + 12
	self:Text(x, y, T.lamas_stats_then)
	y = y + 10

	self:FungalDrawFutureTooltipShift(y, shift.failed, offset)
end

--- Draws force failed shift in tooltip
--- @private
--- @param y number
--- @param shift shift
--- @param offset number
function future:FungalDrawFutureTooltipShiftForceFailed(y, shift, offset)
	local x = 0
	if shift.failed then
		x = x + self:FungalText(x, y, T.OrIf) + 3
	else
		x = x + self:FungalText(x, y, T.lamas_stats_if) + 3
	end
	self:FungalDrawHeldMaterial(x, y, { 0.7, 0.7, 0.7 })
	x = x + self.fungal.offset.held + 12
	x = x + self:FungalText(x, y, T.Is) + 3
	local material = shift.flask == "from" and shift.to or shift.force_failed.from[1]
	self:FungalDrawSingleMaterial(x, y, material)

	self:FungalDrawFutureTooltipShift(y + 10, shift.force_failed, offset)
end

--- Draws greedy information
--- @param y integer
--- @param greedy greedy_shift
--- @param offset number
function future:FungalDrawFutureTooltipGreedy(y, greedy, offset)
	local x = 0
	self:ColorGray()
	self:Text(x, y, T.lamas_stats_fungal_greedy)
	x = x + 3
	y = y + 10
	self.fungal.row_count = 2
	local gold = CellFactory_GetType("gold")
	local grass = CellFactory_GetType("grass_holy")
	self:FungalDrawSingleMaterial(x, y, gold)
	self:FungalDrawSingleMaterial(x, y + 10, grass)
	x = x + offset + 3
	self:FungalDrawArrow(x, y)
	x = x + 15
	self:FungalDrawSingleMaterial(x, y, greedy.gold)
	self:FungalDrawSingleMaterial(x, y + 10, greedy.grass)
end

--- Gets longest material name
--- @private
--- @param shift shift
--- @return number
--- @nodiscard
function future:FungalFutureCalculateOffset(shift)
	local offset_from = self:FungalGetLongestTextInShift(shift, 0, 0, false, self.alt)
	if shift.failed then
		offset_from = self:FungalGetLongestMaterialName(shift.failed.from, offset_from, self.alt)
	end
	if shift.force_failed then
		offset_from = self:FungalGetLongestMaterialName(shift.force_failed.from, offset_from, self.alt)
	end
	return offset_from
end

--- Draws tooltip for future shift
--- @private
--- @param shift shift
--- @param i number
function future:FungalDrawFutureTooltip(shift, i)
	self:AddOption(self.c.options.Layout_NextSameLine)
	local y = 0

	local offset_from = self:FungalFutureCalculateOffset(shift)

	self:Text(0, y, string.format(T.lamas_stats_shift .. " %02d", i))
	y = y + 10

	self:FungalDrawFutureTooltipShift(y, shift, offset_from)
	y = y + 10 * self.fungal.row_count

	if self.fs.predictor.is_using_new_shift then
		if shift.greedy and self.alt then
			self:FungalDrawFutureTooltipGreedy(y, shift.greedy, offset_from)
			y = y + 30
		end
		y = y + 5

		if shift.failed then
			self:FungalDrawFutureTooltipShiftFailed(y, shift, offset_from)
			y = y + 10 * self.fungal.row_count + 15
		end
		if shift.force_failed then
			self:FungalDrawFutureTooltipShiftForceFailed(y, shift, offset_from)
			y = y + 10 * self.fungal.row_count + 15
		end
	end
	if not self.alt then
		self:ColorGray()
		self:Text(0, y, T.PressShiftToSeeMore)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

--- Sets color for future shift row
--- @private
--- @param hovered boolean
--- @param i integer
--- @param greedy greedy_shift
function future:FungalFutureDecideRowColor(hovered, i, greedy)
	local is_greedy_success = greedy and greedy.success
	if is_greedy_success then
		if hovered then
			self:Color(1, 0.5, 1)
		else
			self:Color(1, 0, 1)
		end
		return
	end

	local is_shift_current = i == self.fs.current_shift
	if hovered then
		if is_shift_current then
			self:Color(0.4, 1, 0.5)
		else
			self:Color(0.2, 0.6, 0.7)
		end
		return
	end

	if is_shift_current then
		self:Color(0.6, 1, 0.1)
	else
		local color = i % 2 == 0 and 0.4 or 0.6
		self:Color(color, color, color)
	end
end

--- Draws future shifts
--- @private
function future:FungalDrawFuture()
	for i = self.fs.current_shift, self.fs.max_shifts do
		local shift = self.fs.predictor.shifts[i]
		local from = self:FungalSanitizeFromShifts(shift.from)
		self.fungal.row_count = self:FungalCalculateRowCount(from, shift.to, shift.flask)
		local height = self.fungal.row_count * 10
		local hovered = self:FungalIsHoverBoxHovered(self.fungal.x, self.fungal.y, height)

		self:FungalFutureDecideRowColor(hovered, i, shift.greedy)
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
			self:MenuTooltip("mods/lamas_stats/files/gfx/ui_9piece_tooltip.png", self.FungalDrawFutureTooltip, shift, i)
		end

		self.fungal.y = self.fungal.y + height + 1
		self.fungal.x = 3
	end
end

return future
