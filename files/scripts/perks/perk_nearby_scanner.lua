---@class nearby_perks_data
---@field id string
---@field lottery? boolean
---@field cast? string
---@field x number x position of perk to sort them how they appears in game
---@field spawn_order number used to determine reroll position more accurately

---@class perk_scanner
---@field entities entity_id[]
---@field data nearby_perks_data
local scanner = {
	entities = {},
	data = {}, ---@diagnostic disable-line: missing-fields
}

---Scans nearby entities
function scanner:Scan()
	local player = ENTITY_GET_WITH_TAG("player_unit")[1]
	if not player then return end
	local x, y = ENTITY_GET_TRANSFORM(player)
	self.entities = EntityGetInRadiusWithTag(x, y, 250, "item_perk")
end

---Parses entities found nearby
function scanner:ParseEntities()
	local parsed = {}
	for i = 1, #self.entities do
		local entity_id = self.entities[i]
		local x, y = ENTITY_GET_TRANSFORM(entity_id)
		local id = self:GetPerkId(entity_id)
		parsed[#parsed + 1] = {
			x = x or i,
			id = id,
			lottery = self:IsLotteryWon(x, y, id),
			cast = id == "ALWAYS_CAST" and self:PredictAlwaysCast(x, y) or nil,
			spawn_order = i,
		}
	end
	if #parsed > 1 then table.sort(parsed, function(a, b)
		return a.x < b.x
	end) end
	self.data = parsed
end

---Predicts perk lottery result
---@private
---@param x number
---@param y number
---@param id string
---@return boolean
function scanner:IsLotteryWon(x, y, id)
	local perk_destroy_chance = tonumber(GLOBALS_GET_VALUE("TEMPLE_PERK_DESTROY_CHANCE", "100")) or 100
	SetRandomSeed(x, y)
	local rand = Random(1, 100)
	if id == "PERKS_LOTTERY" then perk_destroy_chance = perk_destroy_chance / 2 end
	return rand > perk_destroy_chance
end

---Returns perk id from entity
---@private
---@param entity_id entity_id
---@return string
function scanner:GetPerkId(entity_id)
	local perk_component = EntityGetFirstComponent(entity_id, "VariableStorageComponent")
	if not perk_component then return "lamas_stats_unknown" end
	return ComponentGetValue2(perk_component, "value_string")
end

---Returns an action id that always cast will grant
---@private
---@param x number
---@param y number
---@return string
function scanner:PredictAlwaysCast(x, y)
	local good_cards = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
	SetRandomSeed(x, y)
	local card = good_cards[Random(1, #good_cards)]

	local r = Random(1, 100)
	local level = 6

	if r <= 50 then
		local p = Random(1, 100)
		if p <= 86 then
			card = GetRandomActionWithType(x, y, level, 2, 666)
		elseif p <= 93 then
			card = GetRandomActionWithType(x, y, level, 1, 666)
		elseif p < 100 then
			card = GetRandomActionWithType(x, y, level, 0, 666)
		else
			card = GetRandomActionWithType(x, y, level, 6, 666)
		end
	end
	return card
end

return scanner
