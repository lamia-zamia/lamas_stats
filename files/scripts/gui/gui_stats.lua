---@class (exact) LS_Gui_stats
---@field time boolean
---@field kills boolean
---@field position boolean
---@field position_toggle boolean
---@field position_pw boolean
---@field position_pw_west number
---@field position_pw_east number
---@field biome boolean
---@field shift_cd boolean
---@field x number
---@field y number
---@field enabled boolean

---@class (exact) LS_Gui
---@field private stats LS_Gui_stats
local stats = {
	stats = {
		time = false,
		kills = false,
		position = false,
		position_toggle = false,
		position_pw = false,
		position_pw_west = 0,
		position_pw_east = 0,
		biome = false,
		shift_cd = false,
		x = 0,
		y = 0,
		enabled = false,
	}
}

---Shows tooltip and colors text to gray
---@private
---@param width number
---@param tooltip fun(self:table)
function stats:IfStatEntryHovered(width, tooltip)
	if self:IsHoverBoxHovered(self.stats.x, self.stats.y, width, 11, true) then
		self:ShowTooltipCenteredX(0, 20, tooltip)
	end
end

---Draws fungal cooldown if in cooldown
---@private
---@return boolean
function stats:StatsFungal()
	if not self.stats.shift_cd or self.fungal_cd <= 0 then return false end
	self:AddOptionForNext(self.c.options.NonInteractive)
	self:Image(self.stats.x - 3, self.stats.y - 3, "data/ui_gfx/status_indicators/fungal_shift.png")
	if self:IsHoverBoxHovered(self.stats.x - 3, self.stats.y - 3, 13, 13, true) then
		self.tooltip_reset = false
		self:ShowTooltipTextCenteredX(0, 23, _T.lamas_stats_fungal_cooldown .. " " .. self.fungal_cd)
	end
	self.stats.x = self.stats.x + 15
	return true
end

---Draws biome stat
---@private
---@return boolean
function stats:StatsBiome()
	if not self.stats.biome then return false end
	local biome = BiomeMapGetName(self.player_x, self.player_y)
	if biome == "_EMPTY_" then biome = _T.lamas_stats_unknown end
	local text = _T.lamas_stats_location .. ": " .. self:Locale(biome)
	local text_width = self:GetTextDimension(text)
	self:Text(self.stats.x, self.stats.y, text)
	self.stats.x = self.stats.x + text_width + 10
	return true
end

---Draws position stat tooltip
---@private
function stats:StatsPositionTooltip()
	local world_string = _T.lamas_stats_stats_pw
	local position_string = _T.lamas_stats_stats_pw_main
	local player_par_x = GetParallelWorldPosition(self.player_x, self.player_y)
	if player_par_x > 0 then
		position_string = _T.lamas_stats_stats_pw_east .. " " .. player_par_x
	elseif player_par_x < 0 then
		position_string = _T.lamas_stats_stats_pw_west .. " " .. -player_par_x
	end
	self:ColorGray()
	self:Text(0, 0, _T.lamas_stats_position_toggle)

	if not self.stats.position_toggle then
		self:Text(0, 0, "X: " .. tostring(math.floor(self.player_x)))
		self:Text(0, 0, "Y: " .. tostring(math.floor(self.player_y)))
	end

	self:Text(0, 0, world_string .. " - " .. position_string)

	if self.stats.position_pw_east < 0 or self.stats.position_pw_west > 0 then
		self:Text(0, 0,
			_T.lamas_stats_farthest .. " " .. _T.lamas_stats_stats_pw_west .. ": " .. self.stats.position_pw_west)
		self:Text(0, 0,
			_T.lamas_stats_farthest .. " " .. _T.lamas_stats_stats_pw_east .. ": " .. -self.stats.position_pw_east)
	end
end

---Draws position stat
---@private
---@return boolean
function stats:StatsPosition()
	if not self.stats.position then return false end
	local position_string = _T.lamas_stats_position
	local position_string_width = self:GetTextDimension(position_string)
	local offset = position_string_width + 5
	self:Text(self.stats.x, self.stats.y, position_string)

	if self.stats.position_toggle then
		local x = tostring(math.floor(self.player_x))
		local y = tostring(math.floor(self.player_y))
		local stat_max = math.max(#x, #y) * 8
		self:Text(self.stats.x + offset, self.stats.y, "X:" .. x .. ",")
		offset = offset + stat_max + 5
		self:Text(self.stats.x + offset, self.stats.y, "Y:" .. y)
		offset = offset + stat_max
	end

	if self:IsHoverBoxHovered(self.stats.x, self.stats.y, offset, 11) and self:IsLeftClicked() then
		self.stats.position_toggle = not self.stats.position_toggle
	end

	if self.stats.position_pw then
		self:IfStatEntryHovered(offset, self.StatsPositionTooltip)
	end

	self.stats.x = self.stats.x + offset
	return true
end

---Draws kills stat tooltip
---@private
function stats:StatsKillTooltip()
	self:Text(0, 0, _T.lamas_stats_progress_kills .. " " .. StatsGetValue("enemies_killed"))
	self:Text(0, 0, _T.lamas_stats_progress_kills_innocent .. " " .. GlobalsGetValue("HELPLESS_KILLS", "0"))
end

---Draws kills stat
---@private
---@return boolean
function stats:StatsKills()
	if not self.stats.kills then return false end
	local kill_string = _T.lamas_stats_progress_kills
	local kill_string_width = self:GetTextDimension(kill_string)
	local offset = kill_string_width + 30
	self:IfStatEntryHovered(offset, self.StatsKillTooltip)
	self:Text(self.stats.x, self.stats.y, kill_string .. " " .. StatsGetValue("enemies_killed"))

	self.stats.x = self.stats.x + offset
	return true
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
---@return boolean
function stats:StatsTime()
	if not self.stats.time then return false end
	local time_string = self:Locale("$stat_time ")
	local time_string_width = self:GetTextDimension(time_string)
	local time = StatsGetValue("playtime_str")
	local offset = time_string_width + 44
	self:IfStatEntryHovered(offset, self.StatsTimeTooltip)
	self:Text(self.stats.x, self.stats.y, time_string .. time)
	self.stats.x = self.stats.x + offset
	return true
end

---Draws stats
---@private
function stats:StatsDraw()
	self.stats.x = self.header.pos_x + 20
	self.stats.y = self.header.pos_y

	local stat_fns = {
		self.StatsFungal,
		self.StatsTime,
		self.StatsKills,
		self.StatsPosition,
		self.StatsBiome
	}

	local count = #stat_fns
	for i = 1, count do
		local shown = stat_fns[i](self)
		if shown and i < count then
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
	self.stats.position_pw = self.mod:GetSettingBoolean("stats_show_player_pos_pw")
	self.stats.biome = self.mod:GetSettingBoolean("stats_show_player_biome")
	self.stats.shift_cd = self.mod:GetSettingBoolean("stats_show_fungal_cooldown")
	self.stats.enabled = self.mod:GetSettingBoolean("stats_enable")
end

return stats