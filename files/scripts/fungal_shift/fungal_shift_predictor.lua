local old_print = print
local old_game_print = GamePrint
local function report(text)
	local err_msg = "[Lamas Stats]: error - " .. (text or "unknown error")
	old_print("\27[31m[Lamas Stats Error]\27[0m")
	old_print(err_msg)
	old_game_print(err_msg)
end

local nest, gold, grass

--- @diagnostic disable: name-style-check
--- @class shift_predictor
--- @field cooldown integer
--- @field max_shifts integer
--- @field shifts shift[]
--- @field private current_predict_iter number
--- @field is_using_new_shift boolean
local shift_predictor = {
	cooldown = 0,
	max_shifts = 20,
	current_predict_iter = 1,
	shifts = {},
	is_using_new_shift = false
}

local last_shift_result
local flask

--- Redefines functions so they would do nothing
local function redefine_functions()
	local nil_fn = function() end
	local fn_to_nil = { "GameCreateParticle", "GlobalsSetValue", "EntityRemoveIngestionStatusEffect",
		"GameTriggerMusicFadeOutAndDequeueAll", "GameTriggerMusicEvent", "EntityLoad", "EntityAddChild", "GamePrint",
		"GamePrintImportant", "EntityCreateNew", "EntityAddComponent", "EntityAddComponent2", "ConvertMaterialEverywhere", "print", "GameTextGet",
		"CrossCall" }

	for i = 1, #fn_to_nil do
		_G[fn_to_nil[i]] = nil_fn
	end

	local cell_factory_get_type = CellFactory_GetType
	--- @param material string
	--- @return number
	function CellFactory_GetType(material)
		if not material then
			report("Some mod broke fungal shifts, shift number: " ..
				shift_predictor.current_predict_iter .. ", tried to shift material: " .. tostring(material))
			return nest
		end
		return cell_factory_get_type(material)
	end

	dofile_once = dofile
end

--- Bruteforce cooldown value
local function determine_cooldown()
	local passed_frame_check
	local frame = 0

	local globalsGetValue = function(key)
		-- Returning frame 180000 - frame for checks
		if key == "fungal_shift_last_frame" then
			return 180000 - frame
		end
		-- Returning iteration 5000 for it to exit after frame check
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

	-- Starting from 180000, decreasing frame by one and checking if frame check was passed
	for _ = 1, 180000 do
		passed_frame_check = false
		fungal_shift(1, 0, 0, false)
		if passed_frame_check then
			shift_predictor.cooldown = frame
			return
		end
		frame = frame + 1
	end
	-- Failover, wtf happened?
	shift_predictor.cooldown = 0
end

--- Bruteforce max shift count
local function determine_max_shift()
	local converted

	-- Rewriting function to set boolean to true when shift was successful
	local convertMaterialEverywhere = function()
		converted = true
	end
	ConvertMaterialEverywhere = convertMaterialEverywhere

	for _ = 1, 200 do
		converted = false
		fungal_shift(1, 0, 0, false)
		-- If it didn't converted - it was failed
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

--- Does fungal shift with flask
--- @param material integer
local function do_fungal_shift_with_material(material)
	flask = material
	last_shift_result = {
		from = {},
	}
	fungal_shift(1, 0, 0, true)
end

--- Checks for failed shifts with flask from
--- @param last_shift_without_flask shift
--- @return shift
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

--- Checks for failed shifts with flask to
--- @param last_shift_without_flask shift this shift without using a flask
--- @return shift
local function check_for_failed_shift_with_flask_to(last_shift_without_flask)
	-- Gettings amount of from materials
	local from_count = #last_shift_result.from

	-- If there's 2 or more from materials - shift can not fail
	if from_count > 1 then
		-- Chosing longest "from" list, otherwise it could exclude some results from group (for example toxic sludge, poison - > toxic sludge)
		last_shift_without_flask.from = from_count > #last_shift_result.from and last_shift_without_flask.from or
			last_shift_result.from
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

--- Fake shift to get flask shifts
--- @return shift
local function check_for_flask_shift()
	-- Writing old value as shift without a flask
	local last_shift_without_flask = last_shift_result

	-- Shifting with nest
	do_fungal_shift_with_material(nest)

	-- Material "to" was changed to flask, calculating failed shift
	if last_shift_result.to == flask then
		return check_for_failed_shift_with_flask_to(last_shift_without_flask)
	end
	-- Material "from" was changed to flask, calculating failed shift
	if last_shift_result.from[1] == flask then
		return check_for_failed_shift_with_flask_from(last_shift_without_flask)
	end

	-- Shift wasn't changed, returning as is
	return last_shift_result
end

--- Fake shift to get seed shifts
--- @return shift
local function get_shift_materials()
	-- Clearing last_shift_result
	last_shift_result = {
		from = {},
	}
	-- Setting no flask (air)
	flask = 0
	fungal_shift(1, 0, 0, true)

	-- Something failed
	if not last_shift_result.from[1] or not last_shift_result.to then
		report("couldn't parse shift list #" .. shift_predictor.current_predict_iter)
	end
	-- Checking for flasks
	return check_for_flask_shift()
end

--- Checks if pouch shift is possible
--- @return boolean
local function is_pouch_shift_possible()
	local file = "data/scripts/magic/fungal_shift.lua"
	local content = ModTextFileGetContent(file)
	if content:find("\"powder_stash\"") then return true end
	return false
end

--- Gets results of greedy shift
--- @param i integer
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

--- Parses data from fungal_shift.lua
function shift_predictor:Parse()
	-- Starting sandbox to not load any globals
	local sandbox = dofile("mods/lamas_stats/files/lib/sandbox.lua") --- @type ML_sandbox
	sandbox:start_sandbox()

	nest = CellFactory_GetType("nest_static")
	gold = CellFactory_GetType("gold")
	grass = CellFactory_GetType("grass_holy")

	-- Redefining some functions so fungal shift would do nothing
	redefine_functions()
	fungal_shift = nil --- @diagnostic disable-line: assign-type-mismatch
	dofile("data/scripts/magic/fungal_shift.lua")

	-- Gets shift cooldown
	determine_cooldown()

	-- Cooldown value was set, we don't need to work with cooldown anymore
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

	-- Gets max shift
	determine_max_shift()

	-- Starting to parse materials, overriding convertMaterial function so it would return what was converted
	local convertMaterialEverywhere = function(material_from_type, material_to_type)
		last_shift_result.from[#last_shift_result.from + 1] = material_from_type
		last_shift_result.to = material_to_type
	end
	ConvertMaterialEverywhere = convertMaterialEverywhere

	-- Overwriting a function to return a set material instead of hold material
	local _get_held_item_material = function()
		return flask
	end
	get_held_item_material = _get_held_item_material --- @diagnostic disable-line: lowercase-global

	-- Getting 200 shifts (because fuck you)
	for i = 1, 200 do
		shift_predictor.current_predict_iter = i
		shift_predictor.shifts[i] = get_shift_materials()
	end

	self.is_using_new_shift = is_pouch_shift_possible()

	if self.is_using_new_shift then
		for i = 1, 200 do
			get_greedy_shift_results(i)
		end
	end

	-- Removing vars
	last_shift_result = nil --- @diagnostic disable-line: cast-local-type
	flask = nil          --- @diagnostic disable-line: cast-local-type

	-- Reverting globals to its formal state
	sandbox:end_sandbox()
end

return shift_predictor
