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
local fs = {
	predictor = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_predictor.lua"),
	shifted = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_past_getter.lua"),
	max_shifts = 20,
	past_shifts = {},
	current_shift = 0
}

---Checks is shift is identical to failed shift
---@private
---@param shift failed_shift
---@return boolean
---@nodiscard
function fs:IsShiftIdenticalToFailed(shift)
	for i = 1, #shift.from do
		local material_from = shift.from[i]
		local index = self.shifted.indexed + i - 1
		if material_from ~= self.shifted.materials[index].from or shift.to ~= self.shifted.materials[index].to then
			return false
		end
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
			if material_from ~= to then
				unique_from[#unique_from + 1] = material_from
			end
		end
		return unique_from
	end

	return from
end

---Analize past shift
---@private
---@param shift_number integer
function fs:AnalizePastShift(shift_number)
	self.past_shifts[shift_number] = {}
	local past_shift = self.past_shifts[shift_number]

	past_shift.from = {}
	past_shift.to = self.shifted.materials[self.shifted.indexed].to

	local seed_shift = self.predictor.shifts[shift_number]

	-- Checking if shift is identical to failed shift
	if seed_shift.failed and self:IsShiftIdenticalToFailed(seed_shift.failed) then
		-- set it as failed
		past_shift.from = seed_shift.failed.from
		self.shifted.indexed = self.shifted.indexed + #seed_shift.failed.from
		return
	end

	-- Checking if shift is identical to force failed shift
	if seed_shift.force_failed and self:IsShiftIdenticalToFailed(seed_shift.force_failed) then
		-- set it as failed
		past_shift.from = seed_shift.force_failed.from
		past_shift.flask = "force_failed"
		self.shifted.indexed = self.shifted.indexed + #seed_shift.force_failed.from
		return
	end

	-- Excluding same materials from "from" as "to" (in case with group shifts such as toxic, poison -> toxic would have only poison -> toxic)
	local unique_from = self:SanitizeFromMaterials(seed_shift.from, past_shift.to)

	-- Checking if shifted "to" is different from seed
	if past_shift.to ~= seed_shift.to and seed_shift.flask == "to" then
		past_shift.flask = "to"
		past_shift.from = unique_from
		self.shifted.indexed = self.shifted.indexed + #past_shift.from
		return
	end

	-- Checking if shifted from is different from seed
	for j = 1, #unique_from do
		local material_type = unique_from[j]
		if self.shifted.materials[self.shifted.indexed].from ~= material_type then
			if seed_shift.flask == "from" then
				past_shift.flask = "from"
				-- if past_materials[shift_number] == "apotheosis_cursed_liquid_red_static" or past_materials[shift_number] == "apotheosis_cursed_liquid_red" then
				-- 	table.insert(past_shifts[i].from, "apotheosis_cursed_liquid_red_static")
				-- 	table.insert(past_shifts[i].from, "apotheosis_cursed_liquid_red")
				-- 	shift_number = shift_number + 4
				-- 	break
				-- end
				if j == 1 then --foolproofing cases where first material matching shifted material
					past_shift.from[#past_shift.from + 1] = self.shifted.materials[self.shifted.indexed].from
					self.shifted.indexed = self.shifted.indexed + 1
				end
				break
			else
				past_shift.from[#past_shift.from + 1] = self.shifted.materials[self.shifted.indexed].from
				self.shifted.indexed = self.shifted.indexed + 1
			end
		else
			past_shift.from[#past_shift.from + 1] = self.shifted.materials[self.shifted.indexed].from
			self.shifted.indexed = self.shifted.indexed + 1
			-- if past_shifts[i].to ~= past_materials[shift_number + 1] then --failproof cases where failed shifts are identical to true shift
			-- 	break
			-- end
		end
	end
end

---Analize past shifts
function fs:AnalizePastShifts()
	self.shifted:GetShiftedMaterials()
	for i = #self.past_shifts + 1, self.current_shift - 1 do
		if not self.shifted.materials[self.shifted.indexed] then
			reporter:Report(_T.lamas_stats_fungal_predict_error .. ", " .. i)
			return
		end
		self:AnalizePastShift(i)
	end
end

---Init fungal shifts
function fs:Init()
	self.predictor:parse()
	self.max_shifts = self.predictor.max_shifts
	self.cooldown = self.predictor.cooldown
end

return fs
