---@class materials_shifted
---@field from integer
---@field to integer

---@class fungal_reader
---@field materials materials_shifted[]
---@field indexed integer
local reader = {
	materials = {},
	indexed = 1
}

function reader:GetShiftedMaterials()
	local world_state_entity = GameGetWorldStateEntity()
	local world_state_component = EntityGetFirstComponent(world_state_entity, "WorldStateComponent")
	if not world_state_component then return end
	local past_materials = ComponentGetValue2(world_state_component, "changed_materials") or {} ---@type string[]

	local already_readed = #self.materials * 2
	for i = already_readed + 1, #past_materials, 2 do
		self.materials[#self.materials + 1] = {
			from = CellFactory_GetType(past_materials[i]),
			to = CellFactory_GetType(past_materials[i + 1])
		}
	end
end

return reader
