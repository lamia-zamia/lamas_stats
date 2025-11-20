---@class materials_shifted
---@field from integer
---@field to integer

---@class (exact) fungal_reader
---@field materials materials_shifted[]
---@field indexed integer
---@field read_count integer
local reader = {
	materials = {},
	indexed = 1,
	read_count = 0,
}

---@private
function reader:ParseShift(from, to)
	self.materials[#self.materials + 1] = {
		from = CellFactory_GetType(from),
		to = CellFactory_GetType(to),
	}
end

if ModIsEnabled("shift_parity") then
	local old = reader.ParseShift
	function reader:ParseShift(from, to)
		if from == "shift_parity" or to == "shift_parity" then return end
		old(self, from, to)
	end
end

function reader:GetShiftedMaterials()
	local world_state_entity = GameGetWorldStateEntity()
	local world_state_component = EntityGetFirstComponent(world_state_entity, "WorldStateComponent")
	if not world_state_component then return end
	local past_materials = ComponentGetValue2(world_state_component, "changed_materials") or {} ---@type string[]

	for i = self.read_count + 1, #past_materials, 2 do
		local from = past_materials[i]
		local to = past_materials[i + 1]
		if from and to then self:ParseShift(from, to) end
		self.read_count = self.read_count + 2
	end
end

return reader
