---@diagnostic disable: lowercase-global, unused-local, missing-global-doc

---@class perk_predict
---@field future_perks string[][]
---@field reroll_perks string[][]
---@field max_perks number
local predict = {
	future_perks = {},
	max_perks = 0,
	reroll_perks = {},
	perk_index = 1,
	reroll_index = 1,
	mountain_index = 1,
	mountain_visits = 0,
}

local globals_get_value

function predict:UpdatePerkList()
	self.max_perks = 0
	self.future_perks = {}
	self.perk_index = tonumber(GLOBALS_GET_VALUE("TEMPLE_NEXT_PERK_INDEX")) or 1
	self.mountain_visits = (tonumber(GLOBALS_GET_VALUE("HOLY_MOUNTAIN_VISITS")) or 0) + 1
	function perk_spawn(x, y, perk_id, dont_remove_other_perks_)
		local arr = predict.future_perks[predict.mountain_index]
		arr[#arr + 1] = perk_id
	end

	for i = 1, 8 do
		self.mountain_index = i
		self.future_perks[i] = {}
		perk_spawn_many(0, 0)
		self.max_perks = math.max(self.max_perks, #self.future_perks[i])
		self.mountain_visits = self.mountain_visits + 1
	end

	local perks = perk_get_spawn_order()
	self.reroll_perks = {}
	self.reroll_index = tonumber(GLOBALS_GET_VALUE("TEMPLE_REROLL_PERK_INDEX")) or #perks
	function perk_spawn(x, y, perk_id, dont_remove_other_perks_)
		local arr = predict.reroll_perks[predict.mountain_index]
		arr[#arr + 1] = perk_id
	end

	for i = 1, 8 do
		self.mountain_index = i
		self.reroll_perks[i] = {}
		perk_reroll_perks()
	end
end

function predict:Init()
	globals_get_value = GlobalsGetValue
	function GlobalsGetValue(key, default_value)
		if key == "TEMPLE_NEXT_PERK_INDEX" then return predict.perk_index end
		if key == "HOLY_MOUNTAIN_VISITS" then return predict.mountain_visits end
		if key == "TEMPLE_REROLL_PERK_INDEX" then return predict.reroll_index end
		return globals_get_value(key, default_value)
	end

	function GlobalsSetValue(key, value)
		if key == "TEMPLE_NEXT_PERK_INDEX" then
			predict.perk_index = tonumber(value) --[[@as number]]
		end
		if key == "TEMPLE_REROLL_PERK_INDEX" then
			predict.reroll_index = tonumber(value) --[[@as number]]
		end
	end

	---Redefined to nil
	function GameAddFlagRun() end

	function EntityKill() end

	---@param tag string
	---@return entity_id[]
	function EntityGetWithTag(tag)
		if tag == "perk" then
			local player = ENTITY_GET_WITH_TAG("player_unit")[1]
			if not player then return predict.future_perks[1] end
			local x, y = ENTITY_GET_TRANSFORM(player)
			local entities = EntityGetInRadiusWithTag(x, y, 250, "item_perk")
			return #entities > 0 and entities or predict.future_perks[1]
		end
		return ENTITY_GET_WITH_TAG(tag)
	end

	function EntityGetTransform()
		return 0, 0
	end

	dofile("data/scripts/perks/perk.lua") -- ugh
end

return predict
