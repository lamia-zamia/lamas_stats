---@class (exact) LS_Gui
local pg = {}

function pg:PerksDrawRerollPerks()
	self.perk.x = 0
	self.perk.y = 0 - self.scroll.y
	for i = 1, #self.perks.predict.reroll_perks do
		local perks = self.perks.predict.reroll_perks[i]
		local start_y = self.perk.y
		for j = 1, #perks do
			if self.perk.x > self.menu.width then
				self.perk.x = 0
				self.perk.y = self.perk.y + 17
			end
			if i == 1 and self.perks.nearby.entities[j] then -- first reroll row can accurately show always cast
				local nearby_data = self.perks.nearby.data[j] ---@type nearby_perks_data
				local perk_id = perks[nearby_data.spawn_order]
				local this_data = {
					x = nearby_data.x,
					y = nearby_data.y,
					id = perk_id,
					cast = perk_id == "ALWAYS_CAST" and self.perks.nearby:PredictAlwaysCast(nearby_data.x, nearby_data.y) or nil,
				}
				local perk_data = self.perks.data:get_data(perk_id)
				local hovered = self:PerksIsHoverBoxHovered(self.perk.x, self.perk.y)
				self:PerksDrawPerk(self.perk.x, self.perk.y, hovered, perk_data, self.PerksNearbyTooltip, this_data, self.alt)
			else -- everything below is impossible to predict (perk spawn ordering issue), so just show raw perk data
				local perk_id = perks[j]
				local perk_data = self.perks.data:get_data(perk_id)
				local hovered = self:PerksIsHoverBoxHovered(self.perk.x, self.perk.y)
				self:PerksDrawPerk(self.perk.x, self.perk.y, hovered, perk_data, self.PerksCurrentPerkTooltip, perk_data, self.alt)
			end
			self.perk.x = self.perk.x + 17
		end

		self.perk.x = 0
		self.perk.y = self.perk.y + 19
		local color = i % 2 == 0 and 0.1 or 0.2
		self:Color(color, color, color)
		self:SetZ(self.z + 4)
		self:Image(-3, start_y - 2, self.c.px, 0.4, self.menu.width + 3, self.perk.y - start_y)
	end
	self:Text(self.perk.x, self.perk.y + self.scroll.y, "")
end

function pg:PerksDrawRerollPerkScrollBox()
	self:ScrollBox(
		self.menu.start_x - 3,
		self.perk.scrollbox_start,
		self.z + 5,
		self.menu.width + 6,
		self.perk.scroll_height,
		self.c.default_9piece,
		3,
		3,
		self.PerksDrawRerollPerks
	)
end

return pg
