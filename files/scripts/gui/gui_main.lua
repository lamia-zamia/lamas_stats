---@class (exact) LS_Gui:UI_class
---@field private mod mod_util
---@field private show boolean
---@field private hotkey number
---@field private player entity_id|nil
---@field private player_x number
---@field private player_y number
---@field private fungal_cd number
---@field private z number
---@field private fs fungal_shift
---@field private alt boolean
---@field private shift_hold number
---@field private perks perk_helpers
---@field private actions action_parser
---@field private mat material_parser
---@field private max_height number
---@field private default_tooltip string
---@field private textbox textbox
local gui = dofile_once("mods/lamas_stats/files/lib/ui_lib.lua")
gui.buttons.img = "mods/lamas_stats/files/gfx/ui_9piece_button.png"
gui.buttons.img_hl = "mods/lamas_stats/files/gfx/ui_9piece_button_highlight.png"
gui.scroll.scroll_img = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar.png"
gui.scroll.scroll_img_hl = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar_hl.png"
gui.default_tooltip = "mods/lamas_stats/files/gfx/ui_9piece_tooltip_darkest.png"
gui.tooltip_img = gui.default_tooltip
gui.c.default_9piece = "mods/lamas_stats/files/gfx/ui_9piece_main.png"
gui.mod = dofile_once("mods/lamas_stats/files/scripts/mod_util.lua")
gui.perks = dofile_once("mods/lamas_stats/files/scripts/perks/perk.lua")
gui.actions = dofile_once("mods/lamas_stats/files/scripts/gun_parser.lua")
gui.show = false
gui.z = -900
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
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks.lua",
	"mods/lamas_stats/files/scripts/gui/gui_config.lua",
	"mods/lamas_stats/files/scripts/gui/materials/gui_materials.lua",
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		gui[k] = v
	end
end

gui.textbox = dofile_once("mods/lamas_stats/files/scripts/gui/materials/textbox.lua")
gui.textbox.gui = gui.gui

---Fetches common data
---@private
function gui:FetchData()
	self.player_x, self.player_y = ENTITY_GET_TRANSFORM(self.player)
	if GameGetFrameNum() % 60 == 0 then self:ScanPWPosition() end
	local shift_num = self.mod:GetGlobalNumber("fungal_shift_iteration", 0) + 1
	if self.fs.current_shift ~= shift_num then
		self.fs.current_shift = shift_num
		self:FungalShiftListChanged()
	end
	self.fungal_cd = self:GetFungalShiftCooldown()
end

---Fetches settings
---@param did_language_changed boolean
function gui:GetSettings(did_language_changed)
	self.hotkey = self.mod:GetSettingNumber("input_key")
	self.stats.position_pw_west = self.mod:GetGlobalNumber("lamas_stats_farthest_west")
	self.stats.position_pw_east = self.mod:GetGlobalNumber("lamas_stats_farthest_east")
	self:HeaderGetSettings()
	self:FungalGetSettings(did_language_changed)
	self:ConfigGetSettings(did_language_changed)
	self:materials_update(did_language_changed)
	self.max_height = self.mod:GetSettingNumber("max_height")
end

---Gets data after materials are done
function gui:PostBiomeInit()
	local custom_img_id = ModImageMakeEditable("mods/lamas_stats/vfs/white.png", 1, 1)
	ModImageSetPixel(custom_img_id, 0, 0, -1) -- white
	self.mat:parse()
end

---Gets data after worlds exist
function gui:PostWorldInit()
	self.perks:Init()
	self.actions:parse()
	self.mat:convert()
	self.fs:Init()
	self:GetSettings(true)
	self.show = self.mod:GetSettingBoolean("overlay_enabled")
	self.menu.opened = self.mod:GetSettingBoolean("menu_enabled")
end

---Sets alt mode when shift is holded
---@private
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

---Main function to draw gui
function gui:Loop()
	self:StartFrame()
	if InputIsKeyJustDown(self.hotkey) then self.show = not self.show end
	self.player = ENTITY_GET_WITH_TAG("player_unit")[1]

	if not self.player then return end

	if self.textbox.controls_disabled then self.textbox:enable_controls() end

	if not self.show or GameIsInventoryOpen() then return end

	self:FetchData()
	self:DetermineAltMode()

	GuiZSet(self.gui, self.z - 100)
	self:HeaderDraw()
	if self.config.stats_enable then self:StatsDraw() end
	if self.menu.opened then self:MenuDraw() end
end

return gui
