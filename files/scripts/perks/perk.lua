--- @class perk_helpers
--- @field current perks_parser
--- @field nearby perk_scanner
--- @field total_amount number
local perk = {
	data = dofile_once("mods/lamas_stats/files/scripts/perks/perk_data_parser.lua"),
	nearby = dofile_once("mods/lamas_stats/files/scripts/perks/perk_nearby_scanner.lua")
}

--- Updates currently owned perks
function perk:GetCurrentList()
	self.total_amount = 0
	for i = 1, #self.data.list do
		local id = self.data.list[i]
		local pickup_count = tonumber(GlobalsGetValue("PERK_PICKED_" .. id .. "_PICKUP_COUNT", "0")) or 0
		self.total_amount = self.total_amount + pickup_count
		self.data.perks[id].picked_count = pickup_count
	end
end

return perk
