---@class (exact) perk_data
---@field ui_name string
---@field ui_description string
---@field perk_icon string
---@field picked_count number

---@class (exact) perks_parser
---@field data_perks {[string]:perk_data}
---@field data_list string[]
---@field total_amount number
local perks = {
	data_perks = {},
	data_list = {},
	total_amount = 0
}

---Add perks to the list
local function add_perk(perk_data)
	perks.data_list[#perks.data_list + 1] = perk_data.id
	perks.data_perks[perk_data.id] = {
		ui_name = perk_data.ui_name,
		ui_description = perk_data.ui_description,
		perk_icon = perk_data.perk_icon,
		picked_count = 0
	}
end

---Parse perks in sandbox
function perks:parse()
	-- Starting sandbox to not load any globals
	local sandbox = dofile("mods/lamas_stats/files/lib/sandbox.lua") ---@type ML_sandbox
	sandbox:start_sandbox()

	-- Redefining some functions so fungal shift would do nothing
	dofile_once = dofile
	perk_list = {}
	dofile("data/scripts/perks/perk_list.lua")

	for i = 1, #perk_list do
		local perk = perk_list[i]
		add_perk(perk)
	end

	perks.data_perks["lamas_stats_unknown"] = {
		ui_name = "???",
		ui_description = "???",
		perk_icon = "data/items_gfx/perk.png",
		picked_count = 0
	}

	table.sort(perks.data_list)

	-- Reverting globals to its formal state
	sandbox:end_sandbox()
end

---Returns perk data if exist
---@param id string
---@return perk_data
function perks:get_data(id)
	return self.data_perks[id] or self.data_perks["lamas_stats_unknown"]
end

---Updates currently owned perks
function perks:get_current_list()
	self.total_amount = 0
	for i = 1, #self.data_list do
		local id = self.data_list[i]
		local pickup_count = tonumber(GlobalsGetValue("PERK_PICKED_" .. id .. "_PICKUP_COUNT", "0")) or 0
		self.total_amount = self.total_amount + pickup_count
		self.data_perks[id].picked_count = pickup_count
	end
end

return perks
