---Returns a fresh isolated environment that inherits real API via __index = _G.
---All writes go to the env table, never to _G. dofile/dofile_once are overridden
---to propagate the env to any scripts loaded through them.
---@param overrides? table initial shadow functions to set on the env
---@return table env
local function make_env(overrides)
	local loaded = {}
	local env = setmetatable({}, { __index = _G })

	env.dofile = function(path)
		local chunk = assert(loadfile(path))
		setfenv(chunk, env)
		return chunk()
	end

	env.dofile_once = function(path)
		if loaded[path] then return loaded[path][1] end
		local chunk = assert(loadfile(path))
		setfenv(chunk, env)
		local result = chunk()
		loaded[path] = { result }
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
