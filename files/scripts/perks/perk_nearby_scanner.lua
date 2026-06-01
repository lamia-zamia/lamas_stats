---@diagnostic disable: missing-global-doc, missing-return, lowercase-global
---@class nearby_perks_data
---@field id string
---@field lottery? boolean
---@field cast? string
---@field x number x position of perk to sort them how they appears in game
---@field y number y position
---@field spawn_order number used to determine reroll position more accurately

---@class perk_scanner
---@field entities entity_id[]
---@field data nearby_perks_data
---@field always_cast fun():string
local scanner = {
	entities = {},
	data = {}, ---@diagnostic disable-line: missing-fields
}

---Scans nearby entities
function scanner:Scan()
	local player = EntityGetWithTag("player_unit")[1]
	if not player then return end
	local x, y = EntityGetTransform(player)
	self.entities = EntityGetInRadiusWithTag(x, y, 350, "perk")
end

---Parses entities found nearby
function scanner:ParseEntities()
	local parsed = {}
	for i = 1, #self.entities do
		local entity_id = self.entities[i]
		local x, y = EntityGetTransform(entity_id)
		local id = self:GetPerkId(entity_id)
		parsed[#parsed + 1] = {
			x = x or i,
			y = y or 0,
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
---@param x number
---@param y number
---@param id string
---@return boolean
function scanner:IsLotteryWon(x, y, id)
	local perk_destroy_chance = tonumber(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100")) or 100
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
---@param x number
---@param y number
---@return string
function scanner:PredictAlwaysCast(x, y)
	local env = setmetatable({}, { __index = _G })

	env.EntityGetTransform = function()
		return x, y, 0, 0, 0
	end
	env.EntityGetFirstComponentIncludingDisabled = function()
		return 90
	end
	env.find_the_wand_held = function()
		return 1
	end
	env.ComponentObjectGetValue = function()
		return 1
	end
	env.EntityGetWandCapacity = function()
		return 20
	end
	env.AddGunActionPermanent = function(_, card)
		env._always_cast_result = card
	end
	env.GamePrintImportant = function() end

	local original_fenv = getfenv(self.always_cast)
	setfenv(self.always_cast, env)
	self.always_cast()
	setfenv(self.always_cast, original_fenv)

	return env._always_cast_result
end

return scanner
