---@class (exact) shift
---@field from? number[]
---@field to? number[]
---@field flask? string

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

local buffer
local flask

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

---Fake shift to get seed shifts
---@return {from:number[], to:number[]}?
local function get_shift_materials()
	buffer = {
		from = {},
		to = {}
	}
	flask = 0
	fungal_shift(1, 0, 0, true)
	return buffer
end

---Checks if flask is usable
---@param shift number
---@return string?
local function get_shift_flask(shift)
	flask = 1
	buffer = {
		from = {},
		to = {}
	}
	fungal_shift(1, 0, 0, true)
	if buffer.from[1] ~= shift_predictor.shifts[shift].from[1] then return "from" end
	if buffer.to[1] ~= shift_predictor.shifts[shift].to[1] then return "to" end
end

---Parses data from fungal_shift.lua
function shift_predictor:parse()
	local sandbox = dofile("mods/lamas_stats/files/lib/sandbox.lua") ---@type ML_sandbox
	sandbox:start_sandbox()

	redefine_functions()
	fungal_shift = nil
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
		buffer.to[#buffer.to + 1] = material_to_type
	end
	ConvertMaterialEverywhere = convertMaterialEverywhere

	local gget_held_item_material = function()
		return flask
	end
	get_held_item_material = gget_held_item_material ---@diagnostic disable-line: lowercase-global
	
	for i = 1, 200 do
		shift_predictor.current_predict_iter = i
		shift_predictor.shifts[i] = get_shift_materials()
		shift_predictor.shifts[i].flask = get_shift_flask(i)
		if shift_predictor.shifts[i].flask then
			-- shift_predictor.shifts[i].failed =
		end
	end

	sandbox:end_sandbox()
end

return shift_predictor
