---@class (exact) LS_Gui_stats
---@field time boolean
---@field kills boolean
---@field position boolean
---@field biome boolean
---@field shift_cd boolean
---@field x number
---@field y number

---@class (exact) LS_Gui
---@field private stats LS_Gui_stats
local stats = {
	stats = {
		time = false,
		kills = false,
		position = false,
		biome = false,
		shift_cd = false,
		x = 0,
		y = 0
	}
}


function stats:StatsTime()
	if not self.stats.time then return end
	local time_string = GameTextGetTranslatedOrNot("$stat_time")
	local time = StatsGetValue("playtime_str")
	self:Text(self.stats.x, self.stats.y, time_string .. time)
	self.stats.x = self.stats.x + self:GetTextDimension(time_string) + 44
end

---Draws stats
---@private
function stats:StatsDraw()
	self.stats.x = self.header.pos_x + 20
	self.stats.y = self.header.pos_y

	local stat_fns = {
		self.StatsTime,
	}
	for i = 1, #stat_fns do
		stat_fns[i](self)
	end
end

---Fetches settings
---@private
function stats:StatsGetSettings()
	self.stats.time = self.mod:GetSettingBoolean("stats_showtime")
	self.stats.kills = self.mod:GetSettingBoolean("stats_showkills")
	self.stats.position = self.mod:GetSettingBoolean("stats_show_player_pos")
	self.stats.biome = self.mod:GetSettingBoolean("stats_show_player_biome")
	self.stats.shift_cd = self.mod:GetSettingBoolean("stats_show_fungal_cooldown")
end

return stats
