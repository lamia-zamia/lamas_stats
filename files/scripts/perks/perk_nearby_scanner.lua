--- @class nearby_perks_data
--- @field id string
--- @field lottery? boolean
--- @field cast? string
--- @field x number x position of perk to sort them how they appears in game
--- @field spawn_order number used to determine reroll position more accurately 

--- @class perk_scanner
--- @field entities entity_id[]
--- @field data nearby_perks_data
local scanner = {
	entities = {},
	data = {} ---@diagnostic disable-line: missing-fields
}

--- Scans nearby entities
function scanner:Scan()
	local player = EntityGetWithTag("player_unit")[1]
	if not player then return end
	local x, y = EntityGetTransform(player)
	self.entities = EntityGetInRadiusWithTag(x, y, 250, "item_perk")
end

--- Parses entities found nearby
function scanner:ParseEntities()
	local parsed = {}
	for i = 1, #self.entities do
		local entity_id = self.entities[i]
		local x, y = EntityGetTransform(entity_id)
		local id = self:GetPerkId(entity_id)
		parsed[#parsed + 1] = {
			x = x,
			id = id,
			lottery = self:IsLotteryWon(x, y, id),
			cast = id == "ALWAYS_CAST" and self:PredictAlwaysCast(x, y) or nil,
			spawn_order = i
		}
	end
	table.sort(parsed, function(a, b) return a.x < b.x end)
	self.data = parsed
end

--- Predicts perk lottery result
--- @private
--- @param x number
--- @param y number
--- @param id string
--- @return boolean
function scanner:IsLotteryWon(x, y, id)
	local perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100")) or 100
	SetRandomSeed(x, y)
	local rand = Random(1, 100)
	if id == "PERKS_LOTTERY" then perk_destroy_chance = perk_destroy_chance / 2 end
	return rand > perk_destroy_chance
end

--- Returns perk id from entity
--- @private
--- @param entity_id entity_id
--- @return string
function scanner:GetPerkId(entity_id)
	local perk_component = EntityGetFirstComponent(entity_id, "VariableStorageComponent")
	if not perk_component then return "lamas_stats_unknown" end
	return ComponentGetValue2(perk_component, "value_string")
end

--- Returns an action id that always cast will grant
--- @private
--- @param x number
--- @param y number
--- @return string
function scanner:PredictAlwaysCast(x, y)
	local good_cards = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
	SetRandomSeed(x, y)
	local card = good_cards[Random(1, #good_cards)]

	local r = Random(1, 100)
	local level = 6

	if r <= 50 then
		local p = Random(1, 100)
		if p <= 86 then
			card = GetRandomActionWithType(x, y, level, ACTION_TYPE_MODIFIER, 666)
		elseif p <= 93 then
			card = GetRandomActionWithType(x, y, level, ACTION_TYPE_STATIC_PROJECTILE, 666)
		elseif p < 100 then
			card = GetRandomActionWithType(x, y, level, ACTION_TYPE_PROJECTILE, 666)
		else
			card = GetRandomActionWithType(x, y, level, ACTION_TYPE_UTILITY, 666)
		end
	end
	return card
end

return scanner
-- function gui_perks_get_perks_on_screen()
-- 	perks_onscreen = {}

-- 	local x,y = EntityGetTransform(player)
-- 	local all_perks = EntityGetInRadiusWithTag(x, y, 500, "item_perk")

-- 	for i,perk_entity in ipairs(all_perks) do
-- 		local entity_x,entity_y = EntityGetTransform(perk_entity)
-- 		local perkComponent = EntityGetFirstComponent(perk_entity, "VariableStorageComponent")
-- 		local perk_id = nil

-- 		if perkComponent == nil then
-- 			perk_id = "lamas_unknown"
-- 		else
-- 			perk_id = ComponentGetValue2(perkComponent, "value_string")
-- 		end
-- 		perks_onscreen[i] = {}
-- 		perks_onscreen[i].perk_id = perk_id
-- 		perks_onscreen[i].x = entity_x
-- 		perks_onscreen[i].y = entity_y
-- 		perks_onscreen[i].pos = i
-- 		end
-- 	end
-- 	table.sort(perks_onscreen, function(a, b) return a.x < b.x end)
-- end
