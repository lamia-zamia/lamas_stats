--- @class (exact) LS_Gui
local pg = {}

function pg:PerksDrawFuturePerks()
	self.perk.x = 0
	self.perk.y = 0 - self.scroll.y
	for i = 1, #self.perks.predict.future_perks do
		local perks = self.perks.predict.future_perks[i]
		local start_y = self.perk.y
		for j = 1, #perks do
			if self.perk.x + 17 > self.scroll.width then
				self.perk.x = 0
				self.perk.y = self.perk.y + 17
			end
			local perk_id = perks[j]
			local perk_data = self.perks.data:GetData(perk_id)
			local hovered = self:PerksIsHoverBoxHovered(self.perk.x, self.perk.y)
			self:PerksDrawPerk(self.perk.x, self.perk.y, hovered, perk_data, self.PerksCurrentPerkTooltip, perk_data, self.alt)
			self.perk.x = self.perk.x + 17
		end

		self.perk.x = 0
		self.perk.y = self.perk.y + 19
		local color = i % 2 == 0 and 0.1 or 0.2
		self:Color(color, color, color)
		self:SetZ(self.z + 4)
		self:Image(-3, start_y - 2, self.c.px, 0.4, self.scroll.width, self.perk.y - start_y)
	end
	self:Text(self.perk.x, self.perk.y + self.scroll.y, "")
end

function pg:PerksDrawFuturePerkScrollBox()
	self:ScrollBox(self.menu.start_x - 3, self.perk.scrollbox_start, self.z + 5, self.c.default_9piece, 3, 3,
		self.PerksDrawFuturePerks)
end

return pg
