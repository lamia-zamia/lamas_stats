--- @class perk_scanner
--- @field nearby_entities entity_id[]
--- @field nearby_data table
local scanner = {
	nearby_entities = {},
	nearby_data = {}
}

function scanner:Scan()
	local player = EntityGetWithTag("player_unit")[1]
	if not player then return end
	local x, y = EntityGetTransform(player)
	self.nearby_entities = EntityGetInRadiusWithTag(x, y, 500, "item_perk")
end

--- Predicts perk lottery result
--- @param entity_id entity_id
--- @return boolean
function scanner:IsLotteryWon(entity_id)
	local x, y = EntityGetTransform(entity_id)
	SetRandomSeed(x, y)
	local rand = Random(1, 100)
	local perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100"))
	-- if(perk_id == "PERKS_LOTTERY") then perk_destroy_chance = perk_destroy_chance / 2 end
	return rand > perk_destroy_chance
end

--- Returns perk id from entity
--- @param entity_id entity_id
--- @return string
function scanner:GetPerkId(entity_id)
	local perk_component = EntityGetFirstComponent(entity_id, "VariableStorageComponent")
	if not perk_component then return "lamas_stats_unknown" end
	return ComponentGetValue2(perk_component, "value_string")
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
-- 		perks_onscreen[i].lottery = false
-- 		perks_onscreen[i].cast = nil
-- 		if ModSettingGet("lamas_stats.enable_nearby_lottery") and tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100")) > 1 then
-- 			SetRandomSeed(entity_x, entity_y)
-- 			local rand = Random(1, 100)
-- 			local perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100"))
-- 			if(perk_id == "PERKS_LOTTERY") then perk_destroy_chance = perk_destroy_chance / 2 end
-- 			if rand > perk_destroy_chance then perks_onscreen[i].lottery = true end
-- 		end
-- 		if ModSettingGet("lamas_stats.enable_nearby_alwayscast") and perk_id == "ALWAYS_CAST" then
-- 			local good_cards = { "DAMAGE", "CRITICAL_HIT", "HOMING", "SPEED", "ACID_TRAIL", "SINEWAVE" }
-- 			SetRandomSeed(entity_x, entity_y)
-- 			local card = good_cards[Random(1, #good_cards)]

-- 			local r = Random( 1, 100 )
-- 			local level = 6

-- 			if( r <= 50 ) then
-- 				local p = Random(1,100)
-- 				if( p <= 86 ) then
-- 					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_MODIFIER, 666 )
-- 				elseif( p <= 93 ) then
-- 					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_STATIC_PROJECTILE, 666 )
-- 				elseif ( p < 100 ) then
-- 					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_PROJECTILE, 666 )
-- 				else
-- 					card = GetRandomActionWithType(entity_x, entity_y, level, ACTION_TYPE_UTILITY, 666 )
-- 				end
-- 			end
-- 			perks_onscreen[i].cast = card

-- 		end
-- 	end
-- 	table.sort(perks_onscreen, function(a, b) return a.x < b.x end)
-- end
