---@class materials_shifted
---@field from number
---@field to number

---@class fungal_reader
---@field shifted materials_shifted[]
local reader = {
	shifted = {}
}

function reader:get_shifted_materials()
	local world_state_entity = GameGetWorldStateEntity()
	local world_state_component = EntityGetFirstComponent(world_state_entity, "WorldStateComponent")
	if not world_state_component then return end
	local past_materials = ComponentGetValue2(world_state_component, "changed_materials") or {} ---@type string[]
	if not past_materials[1] then return end
	local already_readed = #self.shifted * 2
	for i = already_readed, #past_materials, 2 do
		local index = #self.shifted + 1
		self.shifted[index] = {
			from = CellFactory_GetType(past_materials[i]),
			to = CellFactory_GetType(past_materials[i + 1])
		}
	end
end

return reader
