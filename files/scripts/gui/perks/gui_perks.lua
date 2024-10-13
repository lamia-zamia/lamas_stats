--- @class LS_Gui_perks
--- @field x number
--- @field y number
--- @field current_window function|nil
--- @field previous_window function|nil
--- @field width number
--- @field scrollbox_start number
--- @field current_children_entities number

--- @class (exact) LS_Gui
--- @field perk LS_Gui_perks
local pg = {
	perk = {
		x = 0,
		y = 0,
		current_window = nil,
		previous_window = nil,
		width = 0,
		scrollbox_start = 0,
		current_children_entities = 0
	}
}

local modules = {
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_header.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_current.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_nearby.lua"
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		pg[k] = v
	end
end
pg.perk.current_window = pg.PerksDrawCurrentPerkScrollBox

--- Returns true if perk is hovered
--- @private
--- @param x number
--- @param y number
--- @return boolean
--- @nodiscard
function pg:PerksIsHoverBoxHovered(x, y)
	if y + 8 > 0 and y + 8 < self.scroll.height_max and self:IsHoverBoxHovered(self.menu.start_x + x - 3, self.perk.scrollbox_start + y, 16, 16)
	then
		return true
	end
	return false
end

--- Draws stats and perks window
function pg:PerksDrawWindow()
	local current_nearby_perks = #self.perks.nearby.entities
	self:CheckForUpdates(current_nearby_perks)

	self.perk.x = self.menu.start_x
	self.perk.y = self.menu.pos_y + 7

	self:PerksAddButton(T.lamas_stat_current, self.PerksDrawCurrentPerkScrollBox)
	self:PerksAddButton(T.lamas_stats_perks_next, function() end)
	self:PerksDrawStats()
	self.perk.y = self.perk.y + 10

	if current_nearby_perks > 0 then
		self.perk.y = self.perk.y + 5
		self:PerksDrawNearby()
		self.perk.y = self.perk.y + 12
	end
	self:Draw9Piece(self.menu.start_x - 6, self.menu.pos_y + 4, self.z + 49, self.scroll.width + 6, self.perk.y - self.menu.pos_y)

	self.perk.scrollbox_start = self.perk.y + 12

	self:AnimateStart(self.perk.previous_window ~= self.perk.current_window)
	if self.perk.current_window then self.perk.current_window(self) end
	self:AnimateE()

	self:MenuSetWidth(self.scroll.width - 6)
	self.perk.previous_window = self.perk.current_window
end

--- Checks if perks needs to update
--- @private
--- @param current_nearby_perks number
function pg:CheckForUpdates(current_nearby_perks)
	self.perks.nearby:Scan()
	local current_children_entities = EntityGetAllChildren(self.player) or {}
	local current_children_count = #current_children_entities
	if current_nearby_perks ~= #self.perks.nearby.entities or current_children_count ~= self.perk.current_children_entities then
		self:PerksUpdate()
	end
	self.perk.current_children_entities = current_children_count
end

--- Updates perks data
--- @private
function pg:PerksUpdate()
	self.perks:GetCurrentList()
	self.perks.nearby:ParseEntities()
end

--- Initialize data for perks
function pg:PerksInit()
	self:PerksUpdate()
	self.scroll.width = 203
end

return pg
