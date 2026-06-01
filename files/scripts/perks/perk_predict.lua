---@diagnostic disable: lowercase-global, unused-local, missing-global-doc

---@class perk_predict
---@field future_perks string[][]
---@field reroll_perks string[][]
---@field max_perks number
---@field private env table
local predict = {
	future_perks = {},
	max_perks = 0,
	reroll_perks = {},
	perk_index = 1,
	reroll_index = 1,
	mountain_index = 1,
	mountain_visits = 0,
}

function predict:UpdatePerkList()
	self.max_perks = 0
	self.future_perks = {}
	self.perk_index = tonumber(GlobalsGetValue("TEMPLE_NEXT_PERK_INDEX")) or 1
	self.mountain_visits = (tonumber(GlobalsGetValue("HOLY_MOUNTAIN_VISITS")) or 0) + 1
	self.env.perk_spawn = function(x, y, perk_id, dont_remove_other_perks_) ---@diagnostic disable-line: duplicate-set-field
		local arr = predict.future_perks[predict.mountain_index]
		arr[#arr + 1] = perk_id
	end

	for i = 1, 8 do
		self.mountain_index = i
		self.future_perks[i] = {}
		self.env.perk_spawn_many(0, 0)
		self.max_perks = math.max(self.max_perks, #self.future_perks[i])
		self.mountain_visits = self.mountain_visits + 1
	end

	local perks = self.env.perk_get_spawn_order()
	self.reroll_perks = {}
	self.reroll_index = tonumber(GlobalsGetValue("TEMPLE_REROLL_PERK_INDEX")) or #perks
	self.env.perk_spawn = function(x, y, perk_id, dont_remove_other_perks_) ---@diagnostic disable-line: duplicate-set-field
		local arr = predict.reroll_perks[predict.mountain_index]
		arr[#arr + 1] = perk_id
	end

	for i = 1, 8 do
		self.mountain_index = i
		self.reroll_perks[i] = {}
		self.env.perk_reroll_perks()
	end
end

function predict:Init()
	local make_env = dofile_once("mods/lamas_stats/files/lib/prediction_env.lua")
	local env = make_env()
	self.env = env

	env.GlobalsGetValue = function(key, default_value)
		if key == "TEMPLE_NEXT_PERK_INDEX" then return predict.perk_index end
		if key == "HOLY_MOUNTAIN_VISITS" then return predict.mountain_visits end
		if key == "TEMPLE_REROLL_PERK_INDEX" then return predict.reroll_index end
		return GlobalsGetValue(key, default_value)
	end

	env.GlobalsSetValue = function(key, value)
		if key == "TEMPLE_NEXT_PERK_INDEX" then
			predict.perk_index = tonumber(value) --[[@as number]]
		end
		if key == "TEMPLE_REROLL_PERK_INDEX" then
			predict.reroll_index = tonumber(value) --[[@as number]]
		end
	end

	---Redefined to nil
	env.GameAddFlagRun = function() end

	env.EntityKill = function() end

	---@param tag string
	---@return entity_id[]
	env.EntityGetWithTag = function(tag)
		if tag == "perk" then
			local player = EntityGetWithTag("player_unit")[1]
			if not player then return predict.future_perks[1] end
			local x, y = EntityGetTransform(player)
			local entities = EntityGetInRadiusWithTag(x, y, 250, "item_perk")
			return #entities > 0 and entities or predict.future_perks[1]
		end
		return EntityGetWithTag(tag)
	end

	env.EntityGetTransform = function()
		return 0, 0
	end

	env.dofile_once("data/scripts/perks/perk.lua") -- ugh
end

return predict
