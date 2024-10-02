local UI_class = dofile_once("mods/lamas_stats/files/lib/ui_lib.lua") ---@type UI_class

---@class (exact) LS_Gui:UI_class
---@field mod mod_util
---@field show boolean
---@field hotkey number
---@field player entity_id|nil
---@field player_x number
---@field player_y number
local gui = UI_class:New()
gui.mod = dofile_once("mods/lamas_stats/files/scripts/mod_util.lua")
gui.show = false

local modules = {
	"mods/lamas_stats/files/scripts/gui_header.lua",
	"mods/lamas_stats/files/scripts/gui_helper.lua",
	"mods/lamas_stats/files/scripts/gui_menu.lua",
	"mods/lamas_stats/files/scripts/gui_stats.lua"
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		gui[k] = v
	end
end

---Fetches common data
---@private
function gui:FetchData()
	self.player_x, self.player_y = EntityGetTransform(self.player)
	if GameGetFrameNum() % 300 == 0 then
		local player_par_x = GetParallelWorldPosition(self.player_x, self.player_y)
		if player_par_x < self.stats.position_pw_east then
			self.stats.position_pw_east = player_par_x
			GlobalsSetValue("lamas_stats_farthest_east", tostring(player_par_x))
		end
		if player_par_x > self.stats.position_pw_west then
			self.stats.position_pw_west = player_par_x
			GlobalsSetValue("lamas_stats_farthest_west", tostring(player_par_x))
		end
	end
end

---Fetches settings
function gui:GetSettings()
	self.hotkey = self.mod:GetSettingNumber("input_key")
	self.stats.position_pw_west = self.mod:GetGlobalNumber("lamas_stats_farthest_west")
	self.stats.position_pw_east = self.mod:GetGlobalNumber("lamas_stats_farthest_east")
	self:MenuGetSettings()
	self:StatsGetSettings()
end

---Main function to draw gui
function gui:loop()
	self:StartFrame()
	if InputIsKeyJustDown(self.hotkey) then
		self.show = not self.show
	end
	self.player = EntityGetWithTag("player_unit")[1]

	if not self.show or not self.player or GameIsInventoryOpen() then return end

	self:FetchData()

	GuiZSet(self.gui, 800)
	self:HeaderDraw()
	self:StatsDraw()
end

return gui
