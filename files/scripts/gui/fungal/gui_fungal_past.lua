---@class (exact) LS_Gui
local past = {}

---Draws tooltip for past shift
---@private
---@param shift shift
---@param i number
function past:FungalDrawPastTooltip(shift, i)
	self:AddOption(self.c.options.Layout_NextSameLine)
	local y = 0

	local offset_from = self:FungalGetLongestTextInShift(shift, 0, 0)


	self:Text(0, y, string.format(_T.lamas_stats_shift .. " %02d", i))
	y = y + 10

	local x = 3
	self.fungal.row_count = self:FungalCalculateRowCount(shift.from, shift.to, false)

	self:FungalDrawFromMaterials(x, y, shift.from, false)
	x = x + offset_from + 15
	self:FungalDrawArrow(x, y)
	x = x + 15
	self:FungalDrawToMaterial(x, y, shift.to, false)

	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

function past:FungalDrawPast()
	for i = 1, self.fs.current_shift do
		local shift = self.fs.past_shifts[i]

		if not shift then return end --do something

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

		if hovered then
			self:ShowTooltip(self.menu.start_x + self.fungal.width + 12, self.menu.start_y + 3,
				self.FungalDrawPastTooltip,
				shift, i)
		end

		self.fungal.y = self.fungal.y + height + 1
		self.fungal.x = 3
	end
end

return past