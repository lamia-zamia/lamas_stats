local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter
---@class (exact) shift
---@field from? number[]
---@field to? number
---@field flask? string
---@field failed? shift
---@field force_failed? shift

---@class fungal_shift
---@field predictor shift_predictor
---@field shifted fungal_reader
---@field max_shifts number
---@field cooldown number
---@field past_shifts shift
---@field current_shift number
local fs = {
	predictor = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_predictor.lua"),
	shifted = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift_past_getter.lua"),
	max_shifts = 20,
	past_shifts = {},
	current_shift = 0
}


function fs:AnalizePastShifts()
	self.shifted:GetShiftedMaterials()
	local current_pair = 1
	for i = 1, self.current_shift - 1 do
		if not self.shifted.materials[current_pair] then
			reporter("Couldn't find shifted materials for shift " .. i)
			return
		end

		-- Initializing past shift
		self.past_shifts[i] = {}
		local past_shift = self.past_shifts[i]

		past_shift.from = {}
		past_shift.to = self.shifted.materials[current_pair].to

		local seed_shift = self.predictor.shifts[i]



		-- if seed_shifts.flask then
		-- 	local temp_failed_shift = gui_fungal_shift_calculate_if_fail(i, seed_shifts)
		-- 	local fullmatch = 0 --how many times there was an match between real shift and "failed" shift
		-- 	for ii, mat in ipairs(temp_failed_shift.from.materials) do
		-- 		local iter = 2 * (ii - 1)
		-- 		--if real shift is identical to "failed" shift
		-- 		if mat == past_materials[shift_number + iter] and past_materials[shift_number + 1] == past_materials[shift_number + iter + 1] then
		-- 			fullmatch = fullmatch + 1
		-- 		else
		-- 			break
		-- 		end
		-- 	end
		-- 	if fullmatch == #temp_failed_shift.from.materials then
		-- 		past_shifts[i].flask = "from_fail"
		-- 		past_shifts[i].from = temp_failed_shift.from.materials
		-- 		shift_number = shift_number + (#past_shifts[i].from) * 2
		-- 		goto continue
		-- 	end
		-- end

		-- Checking if shifted "to" is different from seed
		if past_shift.to ~= seed_shift.to and seed_shift.flask == "to" then
			past_shift.flask = "to"
			past_shift.from = seed_shift.from
			current_pair = current_pair + #past_shift.from
			goto continue
		end

		--[[	checking if shifted from is different from seed ]]
		for j = 1, #seed_shift.from do
			local material_type = seed_shift.from[j]
			if self.shifted.materials[current_pair].from ~= material_type then
				if seed_shift.flask == "from" then
					past_shift.flask = "from"
					-- if past_materials[shift_number] == "apotheosis_cursed_liquid_red_static" or past_materials[shift_number] == "apotheosis_cursed_liquid_red" then
					-- 	table.insert(past_shifts[i].from, "apotheosis_cursed_liquid_red_static")
					-- 	table.insert(past_shifts[i].from, "apotheosis_cursed_liquid_red")
					-- 	shift_number = shift_number + 4
					-- 	break
					-- end
					if j == 1 then --foolproofing cases where first material matching shifted material
						past_shift.from[#past_shift.from + 1] = self.shifted.materials[current_pair].from
						current_pair = current_pair + 1
					end
					break
				else
					past_shift.from[#past_shift.from + 1] = self.shifted.materials[current_pair].from
					current_pair = current_pair + 1
				end
			else
				past_shift.from[#past_shift.from + 1] = self.shifted.materials[current_pair].from
				current_pair = current_pair + 1
				-- if past_shifts[i].to ~= past_materials[shift_number + 1] then --failproof cases where failed shifts are identical to true shift
				-- 	break
				-- end
			end
		end
		::continue::
	end
end

function fs:Init()
	self.predictor:parse()
	-- self:AnalizePastShifts()
	self.max_shifts = self.predictor.max_shifts
	self.cooldown = self.predictor.cooldown
end

return fs
