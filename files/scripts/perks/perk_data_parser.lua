---@class (exact) perk_data
---@field ui_name string
---@field ui_description string
---@field perk_icon string
---@field picked_count number
---@field id string
---@field max number

---@class perks_parser
---@field perks {[string]:perk_data}
---@field list string[]
local perks = {
	perks = {},
	list = {},
}

---Add perks to the list
local function add_perk(perk_data)
	perks.list[#perks.list + 1] = perk_data.id
	perks.perks[perk_data.id] = {
		id = perk_data.id,
		ui_name = perk_data.ui_name,
		ui_description = perk_data.ui_description,
		perk_icon = perk_data.perk_icon,
		picked_count = 0,
		max = perk_data.stackable_maximum or perk_data.stackable and 128 or 1,
	}
end

---Parse perks in sandbox
function perks:Parse()
	-- Starting sandbox to not load any globals
	local sandbox = dofile("mods/lamas_stats/files/lib/sandbox.lua") ---@type ML_sandbox
	sandbox:start_sandbox()

	-- Redefining some functions so fungal shift would do nothing
	-- dofile_once = dofile
	perk_list = {}
	dofile("data/scripts/perks/perk_list.lua")

	for i = 1, #perk_list do
		local perk = perk_list[i]
		add_perk(perk)
	end

	perks.perks["lamas_stats_unknown"] = {
		ui_name = "???",
		ui_description = "???",
		perk_icon = "data/items_gfx/perk.png",
		picked_count = 0,
		id = "???",
		max = 0,
	}

	table.sort(perks.list)

	-- Reverting globals to its formal state
	sandbox:end_sandbox()
end

---Returns perk data if exist
---@param id string
---@return perk_data
function perks:GetData(id)
	return self.perks[id] or self.perks["lamas_stats_unknown"]
end

return perks
