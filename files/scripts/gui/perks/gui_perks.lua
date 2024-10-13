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
	if y + 8 > 0 and y + 8 < self.scroll.height_max and self:IsHoverBoxHovered(self.menu.start_x + x - 3, self.menu.pos_y + y + 29, 16, 16)
	then
		return true
	end
	return false
end

--- Draws stats and perks window
function pg:PerksDrawWindow()
	local current_nearby_perks = #self.perks.nearby.entities
	self.perks.nearby:Scan()
	if current_nearby_perks ~= #self.perks.nearby.entities then
		self:PerksUpdate()
	end
	self.perk.x = self.menu.start_x
	self.perk.y = self.menu.pos_y + 7

	local header_height = 17
	if current_nearby_perks > 0 then
		self:PerksDrawNearby()
		header_height = header_height + 18
	end

	self:Draw9Piece(self.menu.start_x - 6, self.menu.pos_y + 4, self.z + 49, self.scroll.width + 6, header_height)
	self:PerksAddButton("Current", self.PerksDrawCurrentPerkScrollBox)
	self:PerksAddButton("Predict", function() end)
	self:PerksDrawStats()

	self.perk.x = 0
	self.perk.y = 0

	self:AnimateStart(self.perk.previous_window ~= self.perk.current_window)
	if self.perk.current_window then self.perk.current_window(self) end
	self:AnimateE()

	self:MenuSetWidth(self.scroll.width - 6)
	self.perk.previous_window = self.perk.current_window
end

function pg:PerksUpdate()
	self.perks:GetCurrentList()
	self.perks.nearby:ParseEntities()
end

--- Initialize data for perks
function pg:PerksInit()
	self:PerksUpdate()
	self.scroll.width = 203
	-- self:FungalUpdateWindowDims()
	-- self.fungal.past = self.mod:GetSettingBoolean("enable_fungal_past")
	-- self.fungal.future = self.mod:GetSettingBoolean("enable_fungal_future")
	-- self.scroll.width = self.fungal.width
end

return pg
