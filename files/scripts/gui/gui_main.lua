---@class (exact) LS_Gui:noita_gui
---@field private mod mod_util
---@field private show boolean
---@field private hotkey fun():boolean
---@field private sampler fun():boolean
---@field private player entity_id|nil
---@field private player_x number
---@field private player_y number
---@field private fungal_cd number
---@field private fs fungal_shift
---@field private alt boolean
---@field private shift_hold number
---@field private perks perk_helpers
---@field private actions action_parser
---@field private mat material_parser
---@field private shop_pred shop_predictor
---@field private max_height number
---@field private textbox textbox
---@field c {codes:keycodes, px:string, empty:string} mod-side constants
local gui = dofile_once("mods/lamas_stats/files/lib/noita_gui.lua"):new() ---@cast gui LS_Gui
gui.c = {
	codes = dofile_once("mods/lamas_stats/files/lib/keycodes.lua"),
	px = "mods/lamas_stats/vfs/white.png",
	empty = "data/ui_gfx/empty.png",
}
gui.options.button_sprite = "mods/lamas_stats/files/gfx/ui_9piece_button.png"
gui.options.button_sprite_hl = "mods/lamas_stats/files/gfx/ui_9piece_button_highlight.png"
gui.options.tooltip_sprite = "mods/lamas_stats/files/gfx/ui_9piece_tooltip_darkest.png"
gui.options.ninepiece_sprite = "mods/lamas_stats/files/gfx/ui_9piece_main.png"
gui.options.scrollbar_thumb_sprite = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar.png"
gui.options.scrollbar_thumb_sprite_hl = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar_hl.png"
gui.mod = dofile_once("mods/lamas_stats/files/scripts/mod_util.lua")
gui.perks = dofile_once("mods/lamas_stats/files/scripts/perks/perk.lua")
gui.actions = dofile_once("mods/lamas_stats/files/scripts/gun_parser.lua")
gui.show = false
gui.options.z_index = -9000
gui.fs = dofile_once("mods/lamas_stats/files/scripts/fungal_shift/fungal_shift.lua")
gui.mat = dofile_once("mods/lamas_stats/files/scripts/material_parser.lua")
gui.shop_pred = dofile_once("mods/lamas_stats/files/scripts/shops/shop_predictor.lua")
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
	"mods/lamas_stats/files/scripts/gui/shops/gui_shops.lua",
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		gui[k] = v
	end
end

gui.textbox = dofile_once("mods/lamas_stats/files/scripts/gui/materials/textbox.lua")
gui.textbox.gui = gui:handle()

---Updates player transform, shift counter, and fungal cooldown each frame.
---@private
function gui:fetch_data()
	self.player_x, self.player_y = EntityGetTransform(self.player)
	if GameGetFrameNum() % 60 == 0 then self:scan_pw_position() end
	local shift_num = self.mod:GetGlobalNumber("fungal_shift_iteration", 0) + 1
	if self.fs.current_shift ~= shift_num then
		self.fs.current_shift = shift_num
		self:fungal_shift_list_changed()
	end
	self.fungal_cd = self:get_fungal_shift_cooldown()
end

---Fetches settings
---@param did_language_changed boolean
function gui:get_settings(did_language_changed)
	self:fetch_dimensions()
	self:clear_cache()
	self.hotkey = self.mod:get_hotkey("input_key")
	self.sampler = self.mod:get_hotkey("checker_hey")
	self.stats.position_pw_west = self.mod:GetGlobalNumber("lamas_stats_farthest_west")
	self.stats.position_pw_east = self.mod:GetGlobalNumber("lamas_stats_farthest_east")
	self:header_get_settings()
	self:fungal_get_settings(did_language_changed)
	self:config_get_settings(did_language_changed)
	self:materials_update(did_language_changed)
	self.max_height = self.mod:GetSettingNumber("max_height")
end

---Creates the 1x1 white pixel sprite and initializes material data.
function gui:post_biome_init()
	local custom_img_id = ModImageMakeEditable("mods/lamas_stats/vfs/white.png", 1, 1)
	ModImageSetPixel(custom_img_id, 0, 0, -1) -- white
	self.mat:post_biome_init()
	self.shop_pred:scan_map()
end

---Initializes parsers, loads settings, and restores saved overlay state.
function gui:post_world_init()
	self.perks:Init()
	self.actions:parse()
	self.mat:post_world_init()
	self.fs:Init()
	self:get_settings(true)
	self.show = self.mod:GetSettingBoolean("overlay_enabled")
	self.menu.opened = self.mod:GetSettingBoolean("menu_enabled")
end

---Activates alt mode after shift is held for 30+ frames; clears it on release.
---@private
function gui:determine_alt_mode()
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

---Per-frame entry point: processes input, fetches data, and draws the overlay.
function gui:loop()
	self:start_frame()
	self.player = EntityGetWithTag("player_unit")[1]
	if not self.player then return self:end_frame() end

	if self.textbox.controls_disabled then self.textbox:enable_controls() end

	if self.hotkey() then self.show = not self.show end
	self:check_for_checkers()
	if self:sampler() then gui:spawn_getter() end

	if not self.show or GameIsInventoryOpen() then return self:end_frame() end

	self:fetch_data()
	self:determine_alt_mode()

	self:set_z(self.z_index - 100)
	self:header_draw()
	if self.config.stats_enable then self:stats_draw() end
	if self.menu.opened then self:menu_draw() end
	self:end_frame()
end

return gui
