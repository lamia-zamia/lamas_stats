--- @class (exact) LS_Gui
local past = {}

--- Draws tooltip for past shift
--- @private
--- @param shift shift
--- @param i number
function past:FungalDrawPastTooltip(shift, i)
	self:AddOption(self.c.options.Layout_NextSameLine)
	local y = 0
	local x = 0

	local offset_from = self:FungalGetLongestTextInShift(shift, 0, 0, false, self.alt)

	self:Color(0.7, 0.7, 0.7)
	x = x + self:FungalText(x, y, string.format(T.lamas_stats_shift .. " %02d", i))
	if shift.flask then
		self:Color(0.7, 0.7, 0.6)
		self:Text(x + 3, y, "(" .. T.ShiftHasBeenModified .. ")")
	end
	y = y + 10

	x = 3
	self.fungal.row_count = self:FungalCalculateRowCount(shift.from, shift.to, false)

	self:FungalDrawFromMaterials(x, y, shift.from, false, self.alt)
	x = x + offset_from + (self.alt and 3 or 15)
	self:FungalDrawArrow(x, y)
	x = x + 15
	self:FungalDrawToMaterial(x, y, shift.to, false, self.alt)
	y = y + 10 * self.fungal.row_count + 5

	if not self.alt then
		self:ColorGray()
		self:Text(0, y, T.PressShiftToSeeMore)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

function past:FungalDrawPast()
	for i = 1, self.fs.current_shift do
		local shift = self.fs.past_shifts[i]

		if not shift then return end -- do something

		local from = self:FungalSanitizeFromShifts(shift.from)
		self.fungal.row_count = self:FungalCalculateRowCount(from, shift.to, shift.flask)
		local height = self.fungal.row_count * 10
		local hovered = self:FungalIsHoverBoxHovered(self.fungal.x, self.fungal.y, height)

		if hovered then
			self:Color(0.2, 0.6, 0.7)
		else
			-- Darken past shift
			self:SetZ(self.z - 101)
			self:Color(0, 0, 0)
			self:Image(self.fungal.x - 3, self.fungal.y - 1, self.c.px, 0.2, self.fungal.width - 3, height + 1)

			local color = i % 2 == 0 and 0.4 or 0.6
			self:Color(color, color, color)
		end

		self:SetZ(self.z + 4)
		self:Image(self.fungal.x - 3, self.fungal.y - 1, self.c.px, 0.2, self.fungal.width - 3, height + 1)

		self:FungalDrawShiftNumber(i)
		self:FungalDrawFromMaterials(self.fungal.x, self.fungal.y, from, false)
		self.fungal.x = self.fungal.x + self.fungal.offset.from
		self:FungalDrawArrow(self.fungal.x, self.fungal.y)
		self.fungal.x = self.fungal.x + 15
		self:FungalDrawToMaterial(self.fungal.x, self.fungal.y, shift.to, false)
		self.fungal.x = self.fungal.x + self.fungal.offset.to

		if hovered then self:MenuTooltip("mods/lamas_stats/files/gfx/ui_9piece_tooltip.png", self.FungalDrawPastTooltip, shift, i, self.alt) end

		self.fungal.y = self.fungal.y + height + 1
		self.fungal.x = 3
	end
end

return past
