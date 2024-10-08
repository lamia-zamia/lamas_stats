--- @class LS_Gui_perks
--- @field x number
--- @field y number
--- @field current_window function|nil
--- @field previous_window function|nil
--- @field width number

--- @class (exact) LS_Gui
--- @field perk LS_Gui_perks
local pg = {
	perk = {
		x = 0,
		y = 0,
		current_window = nil,
		previous_window = nil,
		width = 0
	}
}

local modules = {
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_header.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_current.lua"
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		pg[k] = v
	end
end

--- Draws stats and perks window
function pg:PerksDrawWindow()
	self.perk.x = self.menu.start_x
	self.perk.y = self.menu.pos_y + 7
	self:Draw9Piece(self.menu.start_x - 6, self.menu.pos_y + 4, self.z + 49, self.scroll.width + 6, 17)
	self:PerksAddButton("Current", self.PerksDrawCurrentPerks)
	self:PerksAddButton("Predict", function() end)
	self:PerksDrawStats()

	self.perk.x = 3
	self.perk.y = 1

	self:AnimateStart(self.perk.previous_window ~= self.perk.current_window)
	if self.perk.current_window then self.perk.current_window(self) end
	self:AnimateE()
	-- self.menu.pos_y = self.menu.pos_y + 15
	-- self:FakeScrollBox(self.menu.pos_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self)
	self:MenuSetWidth(self.scroll.width - 6)
	self.perk.previous_window = self.perk.current_window
end

--- Initialize data for perks
function pg:PerksInit()
	self.perks:GetCurrentList()
	self.perk.width = 0
	-- self:FungalUpdateWindowDims()
	-- self.fungal.past = self.mod:GetSettingBoolean("enable_fungal_past")
	-- self.fungal.future = self.mod:GetSettingBoolean("enable_fungal_future")
	-- self.scroll.width = self.fungal.width
end

return pg
