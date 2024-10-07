local ui_class = dofile_once("mods/lamas_stats/files/lib/ui_lib.lua") --- @type UI_class

--- @class (exact) LS_Gui:UI_class
--- @field private mod mod_util
--- @field private show boolean
--- @field private hotkey number
--- @field private player entity_id|nil
--- @field private player_x number
--- @field private player_y number
--- @field private fungal_cd number
--- @field private z number
--- @field private fs fungal_shift
--- @field private alt boolean
--- @field private shift_hold number
--- @field private perks perks_parser
--- @field private actions action_parser
--- @field private mat material_parser
--- @field private max_height number
local gui = ui_class:New()
gui.buttons.img = "mods/lamas_stats/files/gfx/ui_9piece_button.png"
gui.buttons.img_hl = "mods/lamas_stats/files/gfx/ui_9piece_button_highlight.png"
gui.scroll.scroll_img = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar.png"
gui.scroll.scroll_img_hl = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar_hl.png"
gui.tooltip_img = "mods/lamas_stats/files/gfx/ui_9piece_tooltip.png"
gui.c.default_9piece = "mods/lamas_stats/files/gfx/ui_9piece_main.png"
gui.mod = dofile_once("mods/lamas_stats/files/scripts/mod_util.lua")
gui.perks = dofile_once("mods/lamas_stats/files/scripts/perks/perk_data_parser.lua")
gui.actions = dofile_once("mods/lamas_stats/files/scripts/gun_parser.lua")
gui.show = false
gui.z = 900
gui.fs = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift.lua")
gui.mat = dofile_once("mods/lamas_stats/files/scripts/material_parser.lua")
gui.alt = false
gui.shift_hold = 0
gui.max_height = 180

local modules = {
	"mods/lamas_stats/files/scripts/gui/gui_header.lua",
	"mods/lamas_stats/files/scripts/gui/gui_helper.lua",
	"mods/lamas_stats/files/scripts/gui/gui_menu.lua",
	"mods/lamas_stats/files/scripts/gui/gui_stats.lua",
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal.lua",
	"mods/lamas_stats/files/scripts/gui/gui_kys.lua",
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks.lua"
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		gui[k] = v
	end
end

--- Fetches common data
--- @private
function gui:FetchData()
	self.player_x, self.player_y = EntityGetTransform(self.player)
	if GameGetFrameNum() % 60 == 0 then
		self:ScanPWPosition()
	end
	local shift_num = self.mod:GetGlobalNumber("fungal_shift_iteration", 0) + 1
	if self.fs.current_shift ~= shift_num then
		self.fs.current_shift = shift_num
		self:FungalShiftListChanged()
	end
	self.fungal_cd = self:GetFungalShiftCooldown()
end

--- Fetches settings
function gui:GetSettings()
	self.hotkey = self.mod:GetSettingNumber("input_key")
	self.stats.position_pw_west = self.mod:GetGlobalNumber("lamas_stats_farthest_west")
	self.stats.position_pw_east = self.mod:GetGlobalNumber("lamas_stats_farthest_east")
	self:MenuGetSettings()
	self:StatsGetSettings()
	self:HeaderGetSettings()
	self:KysGetSettings()
	self:FungalGetSettings()
	self.scroll.height_max = 200
end

--- Gets data after materials are done
function gui:PostBiomeInit()
	self.mat:Parse()
end

--- Gets data after worlds exist
function gui:PostWorldInit()
	self.perks:Parse()
	self.actions:Parse()
	self.mat:Convert()
	self.fs:Init()
	self:GetSettings()
	self.show = self.mod:GetSettingBoolean("enabled_at_start")
	self.menu.opened = self.mod:GetSettingBoolean("lamas_menu_enabled_default")
end

--- Sets alt mode when shift is holded
--- @private
function gui:DetermineAltMode()
	local hold = InputIsKeyDown(self.c.codes.keyboard.lshift)
	if self.alt and not hold then
		self.alt = false
		self.shift_hold = 0
	end

	if hold and not self.alt then
		if self.shift_hold > 30 then
			self.alt = true
		else
			self.shift_hold = self.shift_hold + 1
		end
	end
end

--- Main function to draw gui
function gui:Loop()
	self:StartFrame()
	if InputIsKeyJustDown(self.hotkey) then
		self.show = not self.show
	end
	self.player = EntityGetWithTag("player_unit")[1]

	if not self.show or not self.player or GameIsInventoryOpen() then return end

	self:FetchData()
	self:DetermineAltMode()

	GuiZSet(self.gui, self.z - 100)
	self:HeaderDraw()
	if self.stats.enabled then self:StatsDraw() end
	self.gui_id = 200000
	if self.menu.opened then self:MenuDraw() end
end

return gui
