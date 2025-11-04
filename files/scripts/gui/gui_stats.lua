--- @class (exact) LS_Gui_stats
--- @field time boolean
--- @field kills boolean
--- @field position boolean
--- @field position_toggle boolean
--- @field position_pw boolean
--- @field position_pw_west number
--- @field position_pw_east number
--- @field biome boolean
--- @field shift_cd boolean
--- @field x number
--- @field y number
--- @field enabled boolean
--- @field fps number
--- @field fps_last_update_time number
--- @field fps_last_frame number
--- @field speed number
--- @field speed_last_x number
--- @field speed_last_y number

--- @class (exact) LS_Gui
--- @field private stats LS_Gui_stats
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
		fps = 0,
		fps_last_update_time = 0,
		fps_last_frame = 0,
		fps_delta = 0,
		speed = 0,
		speed_last_x = 0,
		speed_last_y = 0,
	},
}

--- Shows tooltip and colors text to gray
--- @private
--- @param width number
--- @param tooltip fun(self:table)
function stats:IfStatEntryHovered(width, tooltip)
	if self:IsHoverBoxHovered(self.stats.x, self.stats.y, width, 11, true) then self:ShowTooltipCenteredX(0, 20, tooltip) end
end

--- Draws fungal cooldown if in cooldown
--- @private
--- @return boolean
function stats:StatsFungal()
	if not self.config.stats_show_fungal_cooldown or self.fungal_cd <= 0 then return false end
	self:AddOptionForNext(self.c.options.NonInteractive)
	self:Image(self.stats.x - 3, self.stats.y - 3, "data/ui_gfx/status_indicators/fungal_shift.png")
	if self:IsHoverBoxHovered(self.stats.x - 3, self.stats.y - 3, 13, 13, true) then
		self.tooltip_reset = false
		self:ShowTooltipTextCenteredX(0, 23, T.lamas_stats_fungal_cooldown .. " " .. self.fungal_cd)
	end
	self.stats.x = self.stats.x + 15
	return true
end

--- Draws biome stat
--- @private
--- @return boolean
function stats:StatsBiome()
	if not self.config.stats_show_player_biome then return false end
	local biome = BiomeMapGetName(self.player_x, self.player_y)
	if biome == "_EMPTY_" then biome = T.lamas_stats_unknown end
	local text = T.lamas_stats_location .. ": " .. self:Locale(biome)
	local text_width = self:GetTextDimension(text)
	self:Text(self.stats.x, self.stats.y, text)
	self.stats.x = self.stats.x + text_width + 10
	return true
end

--- Draws position stat tooltip
--- @private
function stats:StatsPositionTooltip()
	local world_string = T.lamas_stats_stats_pw
	local position_string = T.lamas_stats_stats_pw_main
	local player_par_x = GetParallelWorldPosition(self.player_x, self.player_y)
	if player_par_x > 0 then
		position_string = T.lamas_stats_stats_pw_east .. " " .. player_par_x
	elseif player_par_x < 0 then
		position_string = T.lamas_stats_stats_pw_west .. " " .. -player_par_x
	end
	self:ColorGray()
	self:Text(0, 0, T.lamas_stats_position_toggle)

	if not self.config.stats_position_expanded then
		self:Text(0, 0, "X: " .. tostring(math.floor(self.player_x)))
		self:Text(0, 0, "Y: " .. tostring(math.floor(self.player_y)))
	end

	self:Text(0, 0, world_string .. " - " .. position_string)

	if self.stats.position_pw_east > 0 or self.stats.position_pw_west < 0 then
		self:Text(0, 0, T.lamas_stats_farthest .. " " .. T.lamas_stats_stats_pw_west .. ": " .. -self.stats.position_pw_west)
		self:Text(0, 0, T.lamas_stats_farthest .. " " .. T.lamas_stats_stats_pw_east .. ": " .. self.stats.position_pw_east)
	end
end

--- Draws position stat
--- @private
--- @return boolean
function stats:StatsPosition()
	if not self.config.stats_show_player_pos then return false end
	local position_string = T.lamas_stats_position
	local position_string_width = self:GetTextDimension(position_string)
	local offset = position_string_width + 5
	self:Text(self.stats.x, self.stats.y, position_string)

	if self.config.stats_position_expanded then
		local x = tostring(math.floor(self.player_x))
		local y = tostring(math.floor(self.player_y))
		local stat_max = math.max(#x, #y) * 8
		self:Text(self.stats.x + offset, self.stats.y, "X:" .. x .. ",")
		offset = offset + stat_max + 5
		self:Text(self.stats.x + offset, self.stats.y, "Y:" .. y)
		offset = offset + stat_max
	end

	if self:IsHoverBoxHovered(self.stats.x, self.stats.y, offset, 11) and self:IsLeftClicked() then
		self.config.stats_position_expanded = not self.config.stats_position_expanded
		self.mod:SetModSetting("stats_position_expanded", self.config.stats_position_expanded)
	end

	self:IfStatEntryHovered(offset, self.StatsPositionTooltip)

	self.stats.x = self.stats.x + offset
	return true
end

--- Draws kills stat tooltip
--- @private
function stats:StatsKillTooltip()
	self:Text(0, 0, T.lamas_stats_progress_kills .. " " .. StatsGetValue("enemies_killed"))
	self:Text(0, 0, T.lamas_stats_progress_kills_innocent .. " " .. GLOBALS_GET_VALUE("HELPLESS_KILLS", "0"))
end

--- Draws kills stat
--- @private
--- @return boolean
function stats:StatsKills()
	if not self.config.stats_showkills then return false end
	local kill_string = T.lamas_stats_progress_kills
	local kill_string_width = self:GetTextDimension(kill_string)
	local kills = StatsGetValue("enemies_killed") or "0"
	local kills_width = self:GetTextDimension(kills)
	local offset = kill_string_width + math.min(kills_width, 18) + 6
	self:IfStatEntryHovered(offset, self.StatsKillTooltip)
	self:Text(self.stats.x, self.stats.y, kill_string .. " " .. kills)

	self.stats.x = self.stats.x + offset
	return true
end

--- Draws time stat tooltip
--- @private
function stats:StatsTimeTooltip()
	local stats_list = {
		self:Locale("$menu_stats"),
		self:Locale("$stat_time ") .. StatsGetValue("playtime_str"),
		self:Locale("$stat_places_visited ") .. StatsGetValue("places_visited"),
		self:Locale("$stat_gold ") .. StatsGetValue("gold_all"),
		self:Locale("$stat_items_found ") .. StatsGetValue("items"),
		T.lamas_stats_hearts_find .. " " .. StatsGetValue("heart_containers"),
		T.lamas_stats_projectiles_shot .. " " .. StatsGetValue("projectiles_shot"),
		T.lamas_stats_kicks .. " " .. StatsGetValue("kicks"),
		T.lamas_stats_damage_taken .. " " .. math.ceil(StatsGetValue("damage_taken") * 25),
	}
	local longest = self:GetLongestText(stats_list, "stats_list")
	self:TextCentered(0, 0, stats_list[1], longest)
	for i = 2, #stats_list do
		self:Text(0, 0, stats_list[i])
	end
end

--- Draws time stat
--- @private
--- @return boolean
function stats:StatsTime()
	if not self.config.stats_showtime then return false end
	local time_string = self:Locale("$stat_time ")
	local time_string_width = self:GetTextDimension(time_string)
	local time = StatsGetValue("playtime_str")
	local offset = time_string_width + 44
	self:IfStatEntryHovered(offset, self.StatsTimeTooltip)
	self:Text(self.stats.x, self.stats.y, time_string .. time)
	self.stats.x = self.stats.x + offset
	return true
end

--- Draws FPS
--- @private
--- @return boolean+
function stats:FPS()
	local current_frame = GameGetFrameNum()
	if current_frame % 30 == 0 then
		local current_time = GameGetRealWorldTimeSinceStarted()
		local fps = (current_frame - self.stats.fps_last_frame) / (current_time - self.stats.fps_last_update_time)
		self.stats.fps = math.min(60, math.floor(fps + 0.5))
		self.stats.fps_last_frame = current_frame
		self.stats.fps_last_update_time = current_time
	end
	if not self.config.stats_fps then return false end
	self:Text(self.stats.x, self.stats.y, "FPS: " .. self.stats.fps)
	self.stats.x = self.stats.x + 30
	return true
end

local display_speed = "0"

---Draws player speed
---@private
---@return boolean
function stats:StatsSpeed()
	if not self.config.stats_show_speed then return false end
	local px, py = self.player_x, self.player_y
	local dx = px - self.stats.speed_last_x
	local dy = py - self.stats.speed_last_y
	local speed = math.sqrt(dx * dx + dy * dy)

	self.stats.speed = (self.stats.speed * 0.9) + (speed * 0.1)

	self.stats.speed_last_x = px
	self.stats.speed_last_y = py

	local speed_string = self:Locale("$inventory_speed: ")
	local speed_string_width = self:GetTextDimension(speed_string)

	local speed_px_per_sec = self.stats.speed * self.stats.fps
	local interval = math.max(1, math.min(60, math.floor(math.sqrt(speed_px_per_sec) / 8)))
	-- slower update at high velocity to remove flickering
	if GameGetFrameNum() % interval == 0 then display_speed = string.format("%.0f", speed_px_per_sec) end

	local display_speed_width = math.min(18, self:GetTextDimension(display_speed)) + 6

	self:Text(self.stats.x, self.stats.y, speed_string .. display_speed)
	self.stats.x = self.stats.x + speed_string_width + display_speed_width
	return true
end

--- Draws stats
--- @private
function stats:StatsDraw()
	self.stats.x = self.header.pos_x + 20
	self.stats.y = self.header.pos_y

	local stat_fns = {
		self.FPS,
		self.StatsFungal,
		self.StatsTime,
		self.StatsKills,
		self.StatsPosition,
		self.StatsSpeed,
		self.StatsBiome,
	}

	local count = #stat_fns
	for i = 1, count do
		local shown = stat_fns[i](self)
		if shown and i < count then
			-- self:Text(self.stats.x, self.stats.y, "|")
			self.stats.x = self.stats.x + 7
		end
	end
end

return stats
