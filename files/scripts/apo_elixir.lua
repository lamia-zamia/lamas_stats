local reporter = dofile_once("mods/lamas_stats/files/scripts/error_reporter.lua") ---@type error_reporter
local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua") ---@type nxml

---@class apo_elixir_recipe
---@field mats integer[]
---@field prob number
---@field result integer

local elixir = {}

---Get materials
---@param data element
---@return apo_elixir_recipe?
function elixir:get_recipe(data)
	for reaction in data:each_of("Reaction") do
		if reaction:get("output_cell1") == "apotheosis_hidden_liquid_magic_catalyst" then
			local cell1 = reaction:get("input_cell1")
			local cell2 = reaction:get("input_cell2")
			local cell3 = reaction:get("input_cell3")
			local prob = reaction:get("probability")
			if not cell1 or not cell2 or not cell3 or not prob then return nil end
			return {
				mats = {
					CellFactory_GetType(cell1),
					CellFactory_GetType(cell2),
					CellFactory_GetType(cell3),
				},
				prob = tonumber(prob),
				result = CellFactory_GetType("apotheosis_hidden_liquid_magic_catalyst"),
			}
		end
	end
	return nil
end

---Parse material file
---@return apo_elixir_recipe?
function elixir:parse()
	local success, data = pcall(nxml.parse, ModTextFileGetContent("mods/Apotheosis/files/scripts/materials/secret_materials.xml"))
	if success then
		return self:get_recipe(data)
	else
		reporter:Report("Couldn't parse Apotheosis Elixir recipe, error:\n" .. data)
	end
	return nil
end

return elixir:parse()
