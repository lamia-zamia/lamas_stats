--- @class (exact) LS_Gui
local pg = {}

function pg:PerksDrawFuturePerks()
	self.perk.x = 0
	self.perk.y = 0 - self.scroll.y
	for i = 1, #self.perks.predict.future_perks do
		local perks = self.perks.predict.future_perks[i]
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
		self.perk.y = self.perk.y + 17
	end
	self:Text(self.perk.x, self.perk.y + self.scroll.y, "")
end

function pg:PerksDrawFuturePerkScrollBox()
	self:ScrollBox(self.menu.start_x - 3, self.perk.scrollbox_start, self.z + 5, self.c.default_9piece, 3, 3,
		self.PerksDrawFuturePerks)
end

return pg
