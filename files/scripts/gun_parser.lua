---@class (exact) action_data
---@field name string
---@field description string
---@field sprite string

---@class action_parser
---@field data {[string]:action_data}
local actions_data = {
	data = {},
}

---Add perks to the list
local function add_action(action_data)
	actions_data.data[action_data.id] = {
		name = action_data.name or "",
		description = action_data.description or "",
		sprite = action_data.sprite,
	}
end

---Parse perks in sandbox
function actions_data:Parse()
	-- Starting sandbox to not load any globals
	local sandbox = dofile("mods/lamas_stats/files/lib/sandbox.lua") ---@type ML_sandbox
	sandbox:start_sandbox()

	actions = {}
	dofile("data/scripts/gun/gun_actions.lua")

	for i = 1, #actions do
		local action = actions[i]
		add_action(action)
	end

	actions_data.data["lamas_stats_unknown"] = {
		name = "???",
		description = "???",
		sprite = "data/items_gfx/perk.png",
	}

	-- Reverting globals to its formal state
	sandbox:end_sandbox()
end

---Returns action data if exist
---@param id string
---@return action_data
function actions_data:GetData(id)
	return self.data[id] or self.data["lamas_stats_unknown"]
end

return actions_data
