---@diagnostic disable: lowercase-global, missing-global-doc
local old_print = print
local old_game_print = GamePrint
local function report(text)
	local err_msg = "[Lamas Stats]: error - " .. (text or "unknown error")
	old_print("\27[31m[Lamas Stats Error]\27[0m")
	old_print(err_msg)
	old_game_print(err_msg)
end

local nest, gold, grass

---@diagnostic disable: name-style-check
---@class shift_predictor
---@field cooldown integer
---@field max_shifts integer
---@field shifts shift[]
---@field private current_predict_iter number
---@field is_using_pouch_shift boolean
---@field is_single_pass boolean
local shift_predictor = {
	cooldown = 0,
	max_shifts = 20,
	current_predict_iter = 1,
	shifts = {},
}

local last_shift_result
local flask

-- Holds the prediction env for the duration of parse(); referenced by all helpers.
local shift_env

---Set null/interceptor shadows on env for prediction run.
local function redefine_env_functions(env)
	local nil_fn = function() end
	local fn_to_nil = {
		"GameCreateParticle",
		"GlobalsSetValue",
		"EntityRemoveIngestionStatusEffect",
		"GameTriggerMusicFadeOutAndDequeueAll",
		"GameTriggerMusicEvent",
		"EntityLoad",
		"EntityAddChild",
		"GamePrint",
		"GamePrintImportant",
		"EntityCreateNew",
		"EntityAddComponent",
		"EntityAddComponent2",
		"ConvertMaterialEverywhere",
		"print",
		"GameTextGet",
		"CrossCall",
	}

	for i = 1, #fn_to_nil do
		env[fn_to_nil[i]] = nil_fn
	end

	local real_cell_factory = CellFactory_GetType
	env.CellFactory_GetType = function(material)
		if not material then
			report(
				"Some mod broke fungal shifts, shift number: "
					.. shift_predictor.current_predict_iter
					.. ", tried to shift material: "
					.. tostring(material)
			)
			return nest
		end
		return real_cell_factory(material)
	end

	-- Anti-NT sync: return false for NT_sync_shift, nil (falsy) for everything else.
	env.GameHasFlagRun = function(flag)
		if flag == "NT_sync_shift" then return false end
	end
end

---Bruteforce cooldown value; sets shift_predictor.cooldown.
local function determine_cooldown()
	local passed_frame_check
	local frame = 0

	shift_env.GlobalsGetValue = function(key)
		if key == "fungal_shift_last_frame" then return 180000 - frame end
		if key == "fungal_shift_iteration" then
			passed_frame_check = true
			return 5000
		end
	end

	shift_env.GameGetFrameNum = function()
		return 180000
	end

	-- Starting from 180000, decreasing frame by one and checking if frame check was passed
	for _ = 1, 180000 do
		passed_frame_check = false
		shift_env.fungal_shift(1, 0, 0, false)
		if passed_frame_check then
			shift_predictor.cooldown = frame
			return
		end
		frame = frame + 1
	end
	-- Failover, wtf happened?
	shift_predictor.cooldown = 0
end

local function detect_single_pass_deterministic()
	local converted = false
	shift_env.ConvertMaterialEverywhere = function()
		converted = true
	end

	-- Save env values (loaded into env by fungal_shift's dependency scripts) before overriding.
	local saved_get_held = shift_env.get_held_item_material
	local saved_pick = shift_env.pick_random_from_table_weighted

	-- Neutralise flask logic so it cannot override from/to and corrupt the detection.
	shift_env.get_held_item_material = function()
		return 0
	end

	-- Strategy: force the first while-loop iteration to fail (from == to -> no
	-- conversion), then force the second iteration to succeed (from ~= to).
	-- If converted == true after the run, the implementation retried, meaning
	-- it is NOT single-pass deterministic.
	local call_count = 0
	shift_env.pick_random_from_table_weighted = function()
		call_count = call_count + 1
		-- call 3 is the "from" pick of the second iteration; use a material
		-- that differs from water so the conversion check passes on retry.
		if call_count == 3 then return { materials = { "lava" }, material = "lava" } end
		return { materials = { "water" }, material = "water" }
	end

	shift_env.fungal_shift(1, 0, 0, true)

	shift_env.pick_random_from_table_weighted = saved_pick
	shift_env.get_held_item_material = saved_get_held

	return not converted
end

---Bruteforce max shift count; sets shift_predictor.max_shifts.
local function determine_max_shift()
	local converted

	shift_env.ConvertMaterialEverywhere = function()
		converted = true
	end

	for _ = 1, 200 do
		converted = false
		shift_env.fungal_shift(1, 0, 0, false)
		-- If it didn't convert - it was failed
		if not converted then
			shift_predictor.max_shifts = shift_predictor.current_predict_iter - 1
			return
		end
		-- Elsewise increasing current "iteration"
		shift_predictor.current_predict_iter = shift_predictor.current_predict_iter + 1
	end
	-- Failover, wtf happened?
	shift_predictor.max_shifts = 200
end

---Does fungal shift with flask
---@param material integer
local function do_fungal_shift_with_material(material)
	flask = material
	last_shift_result = {
		from = {},
	}
	shift_env.fungal_shift(1, 0, 0, true)
end

---Checks for failed shifts with flask from
---@param last_shift_without_flask shift
---@return shift
local function check_for_failed_shift_with_flask_from(last_shift_without_flask)
	-- If "to" wasn't changed - it's a correct shift
	if last_shift_result.to == last_shift_without_flask.to then
		last_shift_without_flask.flask = "from"

		-- Forcing fail shift using same material as "to"
		do_fungal_shift_with_material(last_shift_result.to)

		last_shift_without_flask.force_failed = last_shift_result
		return last_shift_without_flask

		-- Shift was failed
	else
		local correct_shift = last_shift_result
		correct_shift.flask = "from"

		-- "from" is empty because it's the same material as "to"
		correct_shift.from = nil

		-- previous shift is the failed one
		correct_shift.failed = last_shift_without_flask

		-- -- Forcing another kind of failed shift with same material
		do_fungal_shift_with_material(last_shift_result.to)
		correct_shift.force_failed = last_shift_result

		return correct_shift
	end
end

---Checks for failed shifts with flask to
---@param last_shift_without_flask shift this shift without using a flask
---@return shift
local function check_for_failed_shift_with_flask_to(last_shift_without_flask)
	-- Gettings amount of from materials
	local from_count = #last_shift_result.from

	-- If there's 2 or more from materials - shift can not fail
	if from_count > 1 then
		-- Choose longest "from" list, otherwise it could exclude some results from group (for example toxic sludge, poison -> toxic sludge)
		last_shift_without_flask.from = #last_shift_without_flask.from > from_count and last_shift_without_flask.from or last_shift_result.from
		last_shift_without_flask.flask = "to"
		return last_shift_without_flask

		-- If "from" material is same with or without flask - it's a normal flask shift
	elseif last_shift_result.from[1] == last_shift_without_flask.from[1] then
		local correct_shift = last_shift_without_flask
		correct_shift.flask = "to"
		-- Forcing fail shift using same material as "from"
		do_fungal_shift_with_material(last_shift_result.from[1])

		correct_shift.force_failed = last_shift_result
		return correct_shift

		-- It's a failed shift
	else
		local correct_shift = last_shift_result

		-- "To" is empty because it's the same material
		correct_shift.to = nil
		correct_shift.flask = "to"

		-- Failed shift is the one without a flask
		correct_shift.failed = last_shift_without_flask

		-- Forcing another kind of failed shift with same material
		do_fungal_shift_with_material(last_shift_result.from[1])

		correct_shift.force_failed = last_shift_result
		return correct_shift
	end
end

---Fake shift to get flask shifts
---@return shift
local function check_for_flask_shift()
	-- Writing old value as shift without a flask
	local last_shift_without_flask = last_shift_result

	-- Shifting with nest
	do_fungal_shift_with_material(nest)

	-- Material "to" was changed to flask, calculating failed shift
	if last_shift_result.to == flask then return check_for_failed_shift_with_flask_to(last_shift_without_flask) end
	-- Material "from" was changed to flask, calculating failed shift
	if last_shift_result.from[1] == flask then return check_for_failed_shift_with_flask_from(last_shift_without_flask) end

	-- Shift wasn't changed, returning as is
	return last_shift_result
end

---Fake shift to get seed shifts
---@return shift
local function get_shift_materials()
	-- Clearing last_shift_result
	last_shift_result = {
		from = {},
	}
	-- Setting no flask (air)
	flask = 0
	shift_env.fungal_shift(1, 0, 0, true)

	-- Something failed
	if not last_shift_result.from[1] or not last_shift_result.to then
		report("couldn't parse shift list #" .. shift_predictor.current_predict_iter)
	end
	-- Checking for flasks
	return check_for_flask_shift()
end

---Checks if pouch shift is possible
---@return boolean
local function is_pouch_shift_possible()
	local file = "data/scripts/magic/fungal_shift.lua"
	local content = ModTextFileGetContent(file)
	if content:find('"powder_stash"') then return true end
	return false
end

---Gets results of greedy shift
---@param i integer
local function get_greedy_shift_results(i)
	if shift_predictor.shifts[i].flask ~= "to" then return end

	shift_predictor.shifts[i].greedy = {}
	shift_predictor.current_predict_iter = i

	do_fungal_shift_with_material(gold)
	local gold_success = last_shift_result.to == gold
	shift_predictor.shifts[i].greedy.gold = last_shift_result.to

	do_fungal_shift_with_material(grass)
	local grass_success = last_shift_result.to == grass
	shift_predictor.shifts[i].greedy.grass = last_shift_result.to

	shift_predictor.shifts[i].greedy.success = gold_success or grass_success
end

---Parses data from fungal_shift.lua
function shift_predictor:parse()
	local make_env = dofile_once("mods/lamas_stats/files/lib/prediction_env.lua")
	local env = make_env()
	shift_env = env

	nest = CellFactory_GetType("nest_static")
	gold = CellFactory_GetType("gold")
	grass = CellFactory_GetType("grass_holy")

	redefine_env_functions(env)

	-- Load fungal_shift.lua fresh into env so fungal_shift() lives in env, not _G.
	env.fungal_shift = nil
	env.dofile("data/scripts/magic/fungal_shift.lua")

	-- Gets shift cooldown
	determine_cooldown()

	-- Cooldown value was set, we don't need to work with cooldown anymore
	shift_env.GameGetFrameNum = function()
		return 0
	end
	shift_env.GlobalsGetValue = function(key, default)
		if key == "fungal_shift_iteration" then return shift_predictor.current_predict_iter - 1 end
		return default
	end

	-- Gets max shift
	determine_max_shift()
	self.is_single_pass = detect_single_pass_deterministic()

	-- Starting to parse materials, overriding convertMaterial function so it would return what was converted
	shift_env.ConvertMaterialEverywhere = function(material_from_type, material_to_type)
		last_shift_result.from[#last_shift_result.from + 1] = material_from_type
		last_shift_result.to = material_to_type
	end

	-- Overwriting a function to return a set material instead of held material
	shift_env.get_held_item_material = function() ---@diagnostic disable-line: lowercase-global
		return flask
	end

	-- Getting 200 shifts (because fuck you)
	for i = 1, 200 do
		shift_predictor.current_predict_iter = i
		shift_predictor.shifts[i] = get_shift_materials()
	end

	self.is_using_pouch_shift = is_pouch_shift_possible()

	if self.is_using_pouch_shift then
		for i = 1, 200 do
			get_greedy_shift_results(i)
		end
	end

	-- Removing vars
	last_shift_result = nil ---@diagnostic disable-line: cast-local-type
	flask = nil ---@diagnostic disable-line: cast-local-type
	shift_env = nil ---@diagnostic disable-line: cast-local-type
end

return shift_predictor
