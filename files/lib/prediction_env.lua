---@diagnostic disable: missing-return-value, return-type-mismatch
---Returns a fresh isolated environment that inherits real API via __index = _G.
---All writes go to the env table, never to _G. dofile/dofile_once are overridden
---to propagate the env to any scripts loaded through them.
---@param overrides? table initial shadow functions to set on the env
---@return table env
local function make_env(overrides)
	local loaded = {}
	local env = setmetatable({}, { __index = _G })

	-- Mirrors do_mod_appends: runs each ModLuaFileAppend file in env.
	local function run_appends(path)
		local appends = ModLuaFileGetAppends(path)
		for _, file in ipairs(appends) do
			if ModDoesFileExist(file) then
				local append_chunk, err = loadfile(file)
				if append_chunk then
					setfenv(append_chunk, env)
					append_chunk()
				else
					print("BOGUS APPEND IN " .. path .. ", file: " .. file .. ", error: " .. err)
				end
			end
		end
	end

	env.dofile = function(path)
		local chunk, err = loadfile(path)
		if chunk == nil then return nil, err end
		setfenv(chunk, env)
		local result = chunk()
		run_appends(path)
		return result
	end

	env.dofile_once = function(path)
		if loaded[path] then return loaded[path][1] end
		local chunk, err = loadfile(path)
		if chunk == nil then return nil, err end
		setfenv(chunk, env)
		local result = chunk()
		loaded[path] = { result }
		run_appends(path)
		return result
	end

	if overrides then
		for k, v in pairs(overrides) do
			env[k] = v
		end
	end

	return env
end

return make_env
