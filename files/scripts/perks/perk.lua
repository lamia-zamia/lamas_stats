---@class perk_helpers
---@field data perks_parser
---@field nearby perk_scanner
---@field total_amount number
---@field predict perk_predict
local perk = {
	data = dofile_once("mods/lamas_stats/files/scripts/perks/perk_data_parser.lua"),
	nearby = dofile_once("mods/lamas_stats/files/scripts/perks/perk_nearby_scanner.lua"),
	predict = dofile_once("mods/lamas_stats/files/scripts/perks/perk_predict.lua"),
	total_amount = 0,
}

---Updates currently owned perks
function perk:GetCurrentList()
	self.total_amount = 0
	for i = 1, #self.data.list do
		local id = self.data.list[i]
		local pickup_count = tonumber(GLOBALS_GET_VALUE("PERK_PICKED_" .. id .. "_PICKUP_COUNT", "0")) or 0
		self.total_amount = self.total_amount + pickup_count
		self.data.perks[id].picked_count = pickup_count
	end
	self.predict:UpdatePerkList()
end

function perk:Init()
	self.data:parse()
	self.predict:Init()
end

return perk
