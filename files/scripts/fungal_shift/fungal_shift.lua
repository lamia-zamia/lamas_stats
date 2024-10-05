---@class (exact) shift
---@field from? number[]
---@field to? number
---@field flask? string
---@field failed? shift

---@class fungal_shift
---@field predictor shift_predictor
---@field shifted fungal_reader
---@field max_shifts number
---@field cooldown number
local fs = {
	predictor = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_predictor.lua"),
	shifted = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_past_getter.lua"),
	max_shifts = 20,
}

function fs:Init()
	self.predictor:parse()
	self.shifted:get_shifted_materials()
	self.max_shifts = self.predictor.max_shifts
	self.cooldown = self.predictor.cooldown
end

return fs