local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter

---@alias greedy_shift {gold:integer, grass:integer, success:boolean}

---@class (exact) failed_shift
---@field from? integer[]
---@field to? integer

---@class (exact) shift
---@field from? integer[]
---@field to? integer
---@field flask? string
---@field failed? failed_shift
---@field force_failed? failed_shift
---@field greedy? greedy_shift

---@class fungal_shift
---@field predictor shift_predictor
---@field shifted fungal_reader
---@field max_shifts integer
---@field cooldown number
---@field past_shifts shift
---@field current_shift integer
---@field aplc APLC_recipes|false
---@field shift_indexed integer
local fs = {
	predictor = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_predictor.lua"),
	shifted = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_past_getter.lua"),
	max_shifts = 20,
	past_shifts = {},
	current_shift = 0,
	shift_indexed = 1,
}

---Checks is shift is identical to failed shift
---@private
---@param shift failed_shift
---@return boolean
---@nodiscard
function fs:IsShiftIdenticalToFailed(shift)
	for i = 1, #shift.from do
		local index = self.shift_indexed + i - 1
		local shifted_materials = self.shifted.materials[index]
		if not shifted_materials then return false end
		local material_from = shift.from[i]
		if material_from ~= shifted_materials.from or shift.to ~= shifted_materials.to then return false end
	end
	return true
end

---Gets "from" materials that does not equal to "to"
---@private
---@param from integer[]
---@param to integer
---@return integer[]
---@nodiscard
function fs:SanitizeFromMaterials(from, to)
	local seed_shift_from_count = #from
	if seed_shift_from_count > 1 then
		local unique_from = {}
		for i = 1, seed_shift_from_count do
			local material_from = from[i]
			if material_from ~= to then unique_from[#unique_from + 1] = material_from end
		end
		return unique_from
	end

	return from
end

---Additional check for shift in case with Apotheosis cursed liquid
---@private
---@param past_shift shift
---@return boolean
function fs:ApotheosisCheckFrom(past_shift)
	local cursed = CellFactory_GetType("apotheosis_cursed_liquid_red")
	local cursed_static = CellFactory_GetType("apotheosis_cursed_liquid_red_static")
	local from = self.shifted.materials[self.shift_indexed].from
	if from == cursed or from == cursed_static then
		past_shift.from = { cursed, cursed_static }
		self.shift_indexed = self.shift_indexed + 2
		return true
	end
	return false
end

---Analize past shift
---@private
---@param shift_number integer
function fs:AnalysePastShift(shift_number)
	self.past_shifts[shift_number] = {}
	local past_shift = self.past_shifts[shift_number]

	past_shift.from = {}
	past_shift.to = self.shifted.materials[self.shift_indexed].to

	local seed_shift = self.predictor.shifts[shift_number]

	-- Checking if shift is identical to failed shift
	if seed_shift.failed and self:IsShiftIdenticalToFailed(seed_shift.failed) then
		-- set it as failed
		past_shift.from = seed_shift.failed.from
		self.shift_indexed = self.shift_indexed + #seed_shift.failed.from
		return
	end

	-- Checking if shift is identical to force failed shift
	if seed_shift.force_failed and self:IsShiftIdenticalToFailed(seed_shift.force_failed) then
		-- set it as failed
		past_shift.from = seed_shift.force_failed.from
		past_shift.flask = "force_failed"
		self.shift_indexed = self.shift_indexed + #seed_shift.force_failed.from
		return
	end

	-- Excluding same materials from "from" as "to" (in case with group shifts such as toxic, poison -> toxic would have only poison -> toxic)
	local unique_from = self:SanitizeFromMaterials(seed_shift.from, past_shift.to)

	-- Checking if shifted "to" is different from seed
	if past_shift.to ~= seed_shift.to and seed_shift.flask == "to" then
		past_shift.flask = "to"
		past_shift.from = unique_from
		self.shift_indexed = self.shift_indexed + #past_shift.from
		return
	end

	-- Checking if shifted from is different from seed
	for j = 1, #unique_from do
		local material_type = unique_from[j]
		local shifted_from = self.shifted.materials[self.shift_indexed].from

		if shifted_from ~= material_type then
			if seed_shift.flask == "from" then
				past_shift.flask = "from"
				-- Apotheosis compatibility
				if ModIsEnabled("Apotheosis") and self:ApotheosisCheckFrom(past_shift) then return end

				if j == 1 then -- foolproofing cases where first material matching shifted material
					past_shift.from[#past_shift.from + 1] = shifted_from
					self.shift_indexed = self.shift_indexed + 1
				end
				break
			end
		end
		past_shift.from[#past_shift.from + 1] = shifted_from
		self.shift_indexed = self.shift_indexed + 1
	end
end

---Analize past shifts
function fs:AnalysePastShifts()
	if #self.predictor.shifts < self.current_shift then
		reporter:Report("There was an error reading world shifts")
		return
	end
	self.shifted:GetShiftedMaterials()
	for i = #self.past_shifts + 1, self.current_shift - 1 do
		if not self.shifted.materials[self.shift_indexed] then
			reporter:Report(T.lamas_stats_fungal_predict_error .. ", " .. i)
			return
		end
		self:AnalysePastShift(i)
	end
end

---Gets APLC recipe if success
function fs:GetApLcRecipe()
	local aplc = dofile_once("mods/lamas_stats/files/scripts/aplc.lua") ---@type APLC
	local aplc_recipe = aplc:get()
	if aplc.failed then
		self.aplc = false
	else
		self.aplc = aplc_recipe
	end
end

function fs:GetApoElixirRecipe()
	self.apo_elixir = dofile_once("mods/lamas_stats/files/scripts/apo_elixir.lua")
end

---Init fungal shifts
function fs:Init()
	self:GetApLcRecipe()
	if ModIsEnabled("Apotheosis") then self:GetApoElixirRecipe() end

	local comp_worldstate = EntityGetFirstComponent(GameGetWorldStateEntity(), "WorldStateComponent")
	if comp_worldstate and ComponentGetValue2(comp_worldstate, "EVERYTHING_TO_GOLD") then
		self.max_shifts = 20
		self.cooldown = 18000
		return -- do nothing in case everything is gold
	end
	self.predictor:parse()
	self.max_shifts = self.predictor.max_shifts
	self.cooldown = self.predictor.cooldown
end

return fs
