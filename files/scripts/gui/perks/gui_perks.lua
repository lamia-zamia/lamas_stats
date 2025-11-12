---@class LS_Gui_perks
---@field x number
---@field y number
---@field current_window function|nil
---@field previous_window function|nil
---@field width number
---@field scrollbox_start number
---@field current_children_entities number
---@field reroll_count number
---@field scroll_height number

---@class (exact) LS_Gui
---@field perk LS_Gui_perks
local pg = {
	perk = {
		x = 0,
		y = 0,
		current_window = nil,
		previous_window = nil,
		width = 0,
		scrollbox_start = 0,
		current_children_entities = 0,
		reroll_count = 0,
		scroll_height = 0,
	},
}

local modules = {
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_header.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_current.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_nearby.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_future.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_reroll.lua",
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		pg[k] = v
	end
end
pg.perk.current_window = pg.PerksDrawCurrentPerkScrollBox

---Returns true if perk is hovered
---@private
---@param x number
---@param y number
---@return boolean
---@nodiscard
function pg:PerksIsHoverBoxHovered(x, y)
	if y + 8 > 0 and y + 8 < self.max_height and self:IsHoverBoxHovered(self.menu.start_x + x - 3, self.perk.scrollbox_start + y, 16, 16) then
		return true
	end
	return false
end

---Draws a perk icon
---@private
---@param x number
---@param y number
---@param hovered boolean
---@param perk perk_data perk data
---@param fn function tooltip
---@param ... any variables to pass to tooltip
function pg:PerksDrawPerk(x, y, hovered, perk, fn, ...)
	local off = hovered and 1.2 or 0
	self:Image(x - off, y - off, perk.perk_icon, 1, hovered and 1.15 or 1)
	self.tooltip_reset = false
	if hovered then self:MenuTooltip("mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png", fn, ...) end
end

---Draws stats and perks window
function pg:PerksDrawWindow()
	self.perk.width = 0
	local current_nearby_perks = #self.perks.nearby.entities
	self:CheckForUpdates(current_nearby_perks)

	self.perk.x = self.menu.start_x
	self.perk.y = self.menu.pos_y + 7

	self:PerksAddButton(T.lamas_stat_current, self.PerksDrawCurrentPerkScrollBox)
	self:PerksAddButton(T.lamas_stats_perks_next, self.PerksDrawFuturePerkScrollBox)
	self:PerksAddButton(T.lamas_stats_perks_reroll, self.PerksDrawRerollPerkScrollBox)
	self:PerksDrawStats()
	self:PerksSetWidth(math.ceil(self.perk.x / 17))
	self:MenuSetWidth(self.perk.width * 17 - 1)
	local start_y = self.perk.y
	self.perk.y = self.perk.y + 10

	if self.config.enable_nearby_perks and current_nearby_perks > 0 then
		self.perk.y = self.perk.y + 5
		self:PerksDrawNearby()
		self.perk.y = self.perk.y + 12
	end
	self.perk.scroll_height = self.max_height - self.perk.y + start_y
	self:Draw9Piece(self.menu.start_x - 6, self.menu.pos_y + 4, self.z + 49, self.menu.width + 12, self.perk.y - self.menu.pos_y)
	if self:IsHoverBoxHovered(self.menu.start_x - 9, self.menu.pos_y + 1, self.menu.width + 12, self.perk.y - self.menu.pos_y + 12, true) then
		self:BlockInput()
	end

	self.perk.scrollbox_start = self.perk.y + 12

	self:AnimateStart(self.perk.previous_window ~= self.perk.current_window)
	if self.perk.current_window then self.perk.current_window(self) end
	self:AnimateE()

	self.perk.previous_window = self.perk.current_window
end

---Checks if perks needs to update
---@private
---@param current_nearby_perks number
function pg:CheckForUpdates(current_nearby_perks)
	local reroll_count = self.mod:GetGlobalNumber("TEMPLE_PERK_REROLL_COUNT")
	self.perks.nearby:Scan()
	local current_children_entities = EntityGetAllChildren(self.player) or {}
	local current_children_count = #current_children_entities
	if
		current_nearby_perks ~= #self.perks.nearby.entities
		or current_children_count ~= self.perk.current_children_entities
		or reroll_count ~= self.perk.reroll_count
	then
		self:PerksUpdate()
	end
	self:PerksSetWidth(current_nearby_perks)
	self:PerksSetWidth(self.perks.predict.max_perks)
	self.perk.current_children_entities = current_children_count
	self.perk.reroll_count = reroll_count
end

---Sets maximum perk amount
---@private
---@param number number
function pg:PerksSetWidth(number)
	self.perk.width = math.min(14, math.max(self.perk.width, number))
end

---Updates perks data
---@private
function pg:PerksUpdate()
	self.perks:GetCurrentList()
	self.perks.nearby:ParseEntities()
end

---Initialize data for perks
function pg:PerksInit()
	self:PerksUpdate()
end

return pg
