---@diagnostic disable: lowercase-global, missing-global-doc
function material_area_checker_success(pos_x, pos_y)
	local entity = GetUpdatedEntityID()
	local macc = EntityGetFirstComponent(entity, "MaterialAreaCheckerComponent") ---@cast macc component_id
	local material = ComponentGetValue2(macc, "material")
	GlobalsSetValue("LAMAS_STATS_DETECTOR", material)
	local root = EntityGetRootEntity(entity)
	EntityKill(root)
end
