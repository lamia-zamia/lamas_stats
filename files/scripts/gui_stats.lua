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

---Shows tooltip and colors text to gray
---@private
---@param width number
---@param tooltip fun(self:table)
function stats:IfStatEntryHovered(width, tooltip)
	if self:IsHoverBoxHovered(self.stats.x, self.stats.y, width, 11, true) then
		self:ShowTooltipCenteredX(0, 20, tooltip)
		self:Color(1, 1, 0.9)
	end
end

---Draws kills stat tooltip
---@private
function stats:StatsKillTooltip()
	self:Text(0, 0, _T.lamas_stats_progress_kills .. " " .. StatsGetValue("enemies_killed"))
	self:Text(0, 0, _T.lamas_stats_progress_kills_innocent .. " " .. GlobalsGetValue("HELPLESS_KILLS", "0"))
end

---Draws kills stat
---@private
function stats:StatsKills()
	if not self.stats.kills then return end
	local kill_string = _T.lamas_stats_progress_kills
	local kill_string_width = self:GetTextDimension(kill_string)
	local offset = kill_string_width + 30
	self:IfStatEntryHovered(offset, self.StatsKillTooltip)
	self:Text(self.stats.x, self.stats.y, kill_string .. " " .. StatsGetValue("enemies_killed"))

	self.stats.x = self.stats.x + offset
end

---Draws time stat tooltip
---@private
function stats:StatsTimeTooltip()
	local stats_list = {
		self:Locale("$menu_stats"),
		self:Locale("$stat_time ") .. StatsGetValue("playtime_str"),
		self:Locale("$stat_places_visited ") .. StatsGetValue("places_visited"),
		self:Locale("$stat_gold ") .. StatsGetValue("gold_all"),
		self:Locale("$stat_items_found ") .. StatsGetValue("items"),
		_T.lamas_stats_hearts_find .. " " .. StatsGetValue("heart_containers"),
		_T.lamas_stats_projectiles_shot .. " " .. StatsGetValue("projectiles_shot"),
		_T.lamas_stats_kicks .. " " .. StatsGetValue("kicks"),
		_T.lamas_stats_damage_taken .. " " .. math.ceil(StatsGetValue("damage_taken") * 25)
	}
	local longest = self:GetLongestText(stats_list, "stats_list")
	self:TextCentered(0, 0, stats_list[1], longest)
	for i = 2, #stats_list do
		self:Text(0, 0, stats_list[i])
	end
end

---Draws time stat
---@private
function stats:StatsTime()
	if not self.stats.time then return end
	local time_string = self:Locale("$stat_time ")
	local time_string_width = self:GetTextDimension(time_string)
	local time = StatsGetValue("playtime_str")
	local offset = time_string_width + 44
	self:IfStatEntryHovered(offset, self.StatsTimeTooltip)
	self:Text(self.stats.x, self.stats.y, time_string .. time)
	self.stats.x = self.stats.x + offset
end

---Draws stats
---@private
function stats:StatsDraw()
	self.stats.x = self.header.pos_x + 20
	self.stats.y = self.header.pos_y

	local stat_fns = {
		self.StatsTime,
		self.StatsKills
	}

	local count = #stat_fns
	for i = 1, count do
		stat_fns[i](self)
		if i < count then
			self:Text(self.stats.x, self.stats.y, "|")
			self.stats.x = self.stats.x + 5
		end
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
