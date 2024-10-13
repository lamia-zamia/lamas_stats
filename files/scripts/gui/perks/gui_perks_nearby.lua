--- @class (exact) LS_Gui
local pg = {}

function pg:PerksDrawNearby()
	local x = self.menu.start_x - 3
	for i = 1, #self.perks.nearby.data do
		if x > 200 then
			x = self.menu.start_x - 3
			self.perk.y = self.perk.y + 17
		end
		local nearby_perk = self.perks.nearby.data[i] --- @type nearby_perks_data
		local perk_data = self.perks.data:GetData(nearby_perk.id)
		self:SetZ(self.z - 50)
		self:Image(x, self.perk.y, perk_data.perk_icon)
		if nearby_perk.lottery then
			self:SetZ(self.z - 51)
			self:Image(x + 10, self.perk.y - 2, "mods/lamas_stats/files/gfx/lottery.png", 1, 1)
		end
		x = x + 17
	end
end

return pg
