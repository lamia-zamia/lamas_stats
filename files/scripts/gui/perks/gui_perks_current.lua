--- @class (exact) LS_Gui
local pg = {}

--- Draws perk icon
--- @private
--- @param perk_id string
function pg:PerksDrawCurrentPerk(perk_id)
	local perk = self.perks:GetData(perk_id)
	if perk.picked_count < 1 then return end
	self:Image(self.perk.x, self.perk.y, perk.perk_icon)
	-- self:Text(self.perk.x + 17, self.perk.y + 5, string.format("%02d", perk.picked_count))
	self.perk.x = self.perk.x + 30
end

--- Draws current perks
--- @private
function pg:PerksDrawCurrentPerks()
	for i = 1, #self.perks.data_list do
		self:PerksDrawCurrentPerk(self.perks.data_list[i])
	end
end

return pg
