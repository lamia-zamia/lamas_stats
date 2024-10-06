---@class (exact) shift_predictor
---@field cooldown number
---@field max_shifts number
---@field shifts shift[]
---@field private current_predict_iter number
local shift_predictor = {
	cooldown = 0,
	max_shifts = 20,
	current_predict_iter = 1,
	shifts = {},
}

local buffer ---@type shift
local flask ---@type number
local _GamePrint = GamePrint

---Redefines functions so they would do nothing
local function redefine_functions()
	local nil_fn = function() end
	local fn_to_nil = { "GameCreateParticle", "GlobalsSetValue", "EntityRemoveIngestionStatusEffect",
		"GameTriggerMusicFadeOutAndDequeueAll", "GameTriggerMusicEvent", "EntityLoad", "EntityAddChild", "GamePrint",
		"GamePrintImportant", "EntityCreateNew", "EntityAddComponent", "ConvertMaterialEverywhere", "print" }

	for i = 1, #fn_to_nil do
		_G[fn_to_nil[i]] = nil_fn
	end

	dofile_once = dofile
end

---Bruteforce cooldown value
local function determine_cooldown()
	local passed_frame_check
	local frame = 0
	local globalsGetValue = function(key)
		if key == "fungal_shift_last_frame" then
			return 180000 - frame
		end
		if key == "fungal_shift_iteration" then
			passed_frame_check = true
			return 5000
		end
	end
	GlobalsGetValue = globalsGetValue

	local gameGetFrameNum = function()
		return 180000
	end
	GameGetFrameNum = gameGetFrameNum

	for _ = 1, 180000 do
		passed_frame_check = false
		fungal_shift(1, 0, 0, false)
		if passed_frame_check then
			shift_predictor.cooldown = frame
			return
		end
		frame = frame + 1
	end
	shift_predictor.cooldown = 0
end

---Bruteforce max shift count
local function determina_max_shift()
	local converted

	local convertMaterialEverywhere = function()
		converted = true
	end
	ConvertMaterialEverywhere = convertMaterialEverywhere

	for _ = 1, 200 do
		converted = false
		fungal_shift(1, 0, 0, false)
		if not converted then
			shift_predictor.max_shifts = shift_predictor.current_predict_iter - 1
			return
		end
		shift_predictor.current_predict_iter = shift_predictor.current_predict_iter + 1
	end
	shift_predictor.max_shifts = 200
end

---Checks for failed shifts with flask from
---@param no_flask shift
---@return shift
local function check_for_failed_shift_with_flask_from(no_flask)
	if buffer.to == no_flask.to then
		no_flask.flask = "from"
		return no_flask
	else
		buffer.from = nil
		buffer.failed = no_flask
		return buffer
	end
end

---Checks for failed shifts with flask to
---@param no_flask shift
---@return shift
local function check_for_failed_shift_with_flask_to(no_flask)
	local from_count = #buffer.from
	if from_count > 1 then
		no_flask.from = from_count > #buffer.from and no_flask.from or buffer.from
		no_flask.flask = "to"
		return no_flask
	elseif buffer.from[1] == no_flask.from[1] then
		local correct_shift = no_flask
		flask = buffer.from[1]
		buffer = {
			from = {},
		}
		fungal_shift(1, 0, 0, true)
		correct_shift.force_failed = buffer
		return correct_shift
	else
		local correct_shift = buffer
		correct_shift.to = nil
		correct_shift.flask = "to"
		correct_shift.failed = no_flask
		flask = buffer.from[1]
		buffer = {
			from = {},
		}
		fungal_shift(1, 0, 0, true)
		correct_shift.force_failed = buffer
		return correct_shift
	end
end

---Fake shift to get flask shifts
---@return shift
local function check_for_flask_shift()
	local no_flask = buffer
	buffer = {
		from = {},
	}
	flask = 1
	fungal_shift(1, 0, 0, true)
	if buffer.to == flask then
		return check_for_failed_shift_with_flask_to(no_flask)
	end
	if buffer.from[1] == flask then
		return check_for_failed_shift_with_flask_from(no_flask)
	end
	return buffer
end

---Fake shift to get seed shifts
---@return shift
local function get_shift_materials()
	buffer = {
		from = {},
	}
	flask = 0
	fungal_shift(1, 0, 0, true)
	if not buffer.from[1] or not buffer.to then
		_GamePrint("couldn't parse shift list")
	end
	return check_for_flask_shift()
end

---Parses data from fungal_shift.lua
function shift_predictor:parse()
	local sandbox = dofile("mods/lamas_stats/files/lib/sandbox.lua") ---@type ML_sandbox
	sandbox:start_sandbox()

	redefine_functions()
	fungal_shift = nil ---@diagnostic disable-line: assign-type-mismatch
	dofile("data/scripts/magic/fungal_shift.lua")

	determine_cooldown()

	local gameGetFrameNum = function()
		return 0
	end
	GameGetFrameNum = gameGetFrameNum
	local globalsGetValue = function(key, default)
		if key == "fungal_shift_iteration" then
			return shift_predictor.current_predict_iter - 1
		end
		return default
	end
	GlobalsGetValue = globalsGetValue

	determina_max_shift()

	local convertMaterialEverywhere = function(material_from_type, material_to_type)
		buffer.from[#buffer.from + 1] = material_from_type
		buffer.to = material_to_type
	end
	ConvertMaterialEverywhere = convertMaterialEverywhere

	local _get_held_item_material = function()
		return flask
	end
	get_held_item_material = _get_held_item_material ---@diagnostic disable-line: lowercase-global

	for i = 1, 200 do
		shift_predictor.current_predict_iter = i
		shift_predictor.shifts[i] = get_shift_materials()
	end

	buffer = nil ---@diagnostic disable-line: cast-local-type

	sandbox:end_sandbox()
end

return shift_predictor
