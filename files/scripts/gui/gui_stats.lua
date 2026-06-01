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
---@field enabled boolean
---@field fps number
---@field fps_last_update_time number
---@field fps_last_frame number
---@field speed number
---@field speed_last_x number
---@field speed_last_y number

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

-- Widest glyph among the characters a number can contain. Lazily measured and
-- cached (font/glyph metrics don't change with language).
local number_glyph_width

---Measures and caches the widest digit glyph width.
---@private
---@return number
function stats:number_glyph_width()
	if number_glyph_width then return number_glyph_width end
	local widest = 0
	for char in ("-0123456789"):gmatch(".") do
		local glyph = self:get_text_dim(char)
		if glyph > widest then widest = glyph end
	end
	number_glyph_width = widest
	return widest
end

---Width a numeric string occupies once placed in a fixed digit-grid cell, so
---its rendered width never changes unless the digit count changes.
---@private
---@param str string
---@return number
function stats:number_cell_width(str)
	return #str * self:number_glyph_width()
end

---Draws a number left-aligned in a fixed-width cell (see number_cell_width) so the
---text after it doesn't shift as the player moves.
---@private
---@param str string
function stats:number_cell(str)
	local cell = self:number_cell_width(str)
	local natural = self:get_text_dim(str)
	self:text(str)
	if cell > natural then self:spacing(cell - natural) end
end

---Draws one stat entry at the cursor, reserving at least `reserved` px of width
---so a changing value doesn't shove later entries around. Returns whether the
---slot is hovered and the screen-space anchor for a centered tooltip.
---@private
---@param text string
---@param reserved number
---@return boolean hovered, number tooltip_center_x, number tooltip_y
function stats:entry(text, reserved)
	local natural = self:get_text_dim(text)
	local width = math.max(reserved, natural)
	local screen_x, screen_y = self:cursor_screen()
	-- Hover/anchor use the visible text width; `reserved` is only layout padding.
	local hovered = self:is_hovered_cursor(natural, 11)
	self:text(text)
	if width > natural then self:spacing(width - natural) end
	return hovered, screen_x + natural / 2, screen_y + 20
end

---Draws fungal cooldown if in cooldown
---@private
---@return boolean
function stats:stats_fungal()
	if not self.config.stats_show_fungal_cooldown or self.fungal_cd <= 0 then return false end
	self:spacing(1)
	local screen_x, screen_y = self:cursor_screen()
	local hovered = self:is_hovered_cursor(9, 11)
	self:leaf(9, 11, function()
		self:add_option_for_next(self.OPT_NON_INTERACTIVE)
		self:image("data/ui_gfx/status_indicators/fungal_shift.png", { dy = -3, dx = -5 })
	end)
	if self:tooltip(hovered, { id = "stats_fungal" }) then
		self:text(T.lamas_stats_fungal_cooldown .. " " .. self.fungal_cd)
		self:tooltip_end(screen_x + 6.5, screen_y + 20, true)
	end
	return true
end

---Draws biome stat
---@private
---@return boolean
function stats:stats_biome()
	if not self.config.stats_show_player_biome then return false end
	local biome = BiomeMapGetName(self.player_x, self.player_y)
	if biome == "_EMPTY_" then biome = T.lamas_stats_unknown end
	local text = T.lamas_stats_location .. ": " .. self:locale(biome)
	self:entry(text, self:get_text_dim(text))
	return true
end

---Draws position stat tooltip
---@private
function stats:stats_position_tooltip()
	local world_string = T.lamas_stats_stats_pw
	local position_string = T.lamas_stats_stats_pw_main
	local player_par_x = GetParallelWorldPosition(self.player_x, self.player_y)
	if player_par_x > 0 then
		position_string = T.lamas_stats_stats_pw_east .. " " .. player_par_x
	elseif player_par_x < 0 then
		position_string = T.lamas_stats_stats_pw_west .. " " .. -player_par_x
	end
	self:color_gray()
	self:text(T.lamas_stats_position_toggle)

	if not self.config.stats_position_expanded then
		self:text("X: " .. tostring(math.floor(self.player_x)))
		self:text("Y: " .. tostring(math.floor(self.player_y)))
	end

	self:text(world_string .. " - " .. position_string)

	if self.stats.position_pw_east > 0 or self.stats.position_pw_west < 0 then
		self:text(T.lamas_stats_farthest .. " " .. T.lamas_stats_stats_pw_west .. ": " .. -self.stats.position_pw_west)
		self:text(T.lamas_stats_farthest .. " " .. T.lamas_stats_stats_pw_east .. ": " .. self.stats.position_pw_east)
	end
end

---Draws position stat
---@private
---@return boolean
function stats:stats_position()
	if not self.config.stats_show_player_pos then return false end
	local position_string = T.lamas_stats_position
	local expanded = self.config.stats_position_expanded

	-- Total width is computed up-front so hover/click/tooltip use one stable
	-- rect, and each coordinate gets its own fixed cell (no jitter on move).
	local x = tostring(math.floor(self.player_x))
	local y = tostring(math.floor(self.player_y))
	local x_label_w = self:get_text_dim("  X:")
	local y_label_w = self:get_text_dim(", Y:")
	local total = self:get_text_dim(position_string)
	if expanded then
		total = total + x_label_w + self:number_cell_width(x) + y_label_w + self:number_cell_width(y)
	else
		total = total + 5
	end

	local screen_x, screen_y = self:cursor_screen()
	local hovered = self:is_hovered_cursor(total, 11)

	if hovered then
		-- Absorb the click so it doesn't fall through to the game (shooting).
		self:block_input(screen_x, screen_y, total, 11)
		if self:is_left_clicked() then
			self.config.stats_position_expanded = not expanded
			self.mod:SetModSetting("stats_position_expanded", self.config.stats_position_expanded)
		end
	end

	self:text(position_string)
	if expanded then
		self:text("  X:")
		self:number_cell(x)
		self:text(", Y:")
		self:number_cell(y)
	else
		self:spacing(5)
	end

	if self:tooltip(hovered, { id = "stats_pos" }) then
		self:stats_position_tooltip()
		self:tooltip_end(screen_x + total / 2, screen_y + 20, true)
	end
	return true
end

---Draws kills stat tooltip
---@private
function stats:stats_kill_tooltip()
	self:text(T.lamas_stats_progress_kills .. " " .. StatsGetValue("enemies_killed"))
	self:text(T.lamas_stats_progress_kills_innocent .. " " .. GlobalsGetValue("HELPLESS_KILLS", "0"))
end

---Draws kills stat
---@private
---@return boolean
function stats:stats_kills()
	if not self.config.stats_showkills then return false end
	local kill_string = T.lamas_stats_progress_kills
	local kills = StatsGetValue("enemies_killed") or "0"
	local reserved = self:get_text_dim(kill_string) + math.min(self:get_text_dim(kills), 18) + 6
	local hovered, tooltip_x, tooltip_y = self:entry(kill_string .. " " .. kills, reserved)
	if self:tooltip(hovered, { id = "stats_kills" }) then
		self:stats_kill_tooltip()
		self:tooltip_end(tooltip_x, tooltip_y, true)
	end
	return true
end

---Draws time stat tooltip
---@private
function stats:stats_time_tooltip()
	local stats_list = {
		self:locale("$menu_stats"),
		self:locale("$stat_time ") .. StatsGetValue("playtime_str"),
		self:locale("$stat_places_visited ") .. StatsGetValue("places_visited"),
		self:locale("$stat_gold ") .. StatsGetValue("gold_all"),
		self:locale("$stat_items_found ") .. StatsGetValue("items"),
		T.lamas_stats_hearts_find .. " " .. StatsGetValue("heart_containers"),
		T.lamas_stats_projectiles_shot .. " " .. StatsGetValue("projectiles_shot"),
		T.lamas_stats_kicks .. " " .. StatsGetValue("kicks"),
		T.lamas_stats_damage_taken .. " " .. math.ceil(StatsGetValue("damage_taken") * 25),
	}
	local longest = self:get_longest_text(stats_list, "stats_list")
	local head_w = self:get_text_dim(stats_list[1])
	self:text(stats_list[1], { dx = (longest - head_w) / 2 })
	for i = 2, #stats_list do
		self:text(stats_list[i])
	end
end

---Draws time stat
---@private
---@return boolean
function stats:stats_time()
	if not self.config.stats_showtime then return false end
	local time_string = self:locale("$stat_time ")
	local reserved = self:get_text_dim(time_string) + 44
	local time = StatsGetValue("playtime_str")
	local hovered, tooltip_x, tooltip_y = self:entry(time_string .. time, reserved)
	if self:tooltip(hovered, { id = "stats_time" }) then
		self:stats_time_tooltip()
		self:tooltip_end(tooltip_x, tooltip_y, true)
	end
	return true
end

---Draws FPS
---@private
---@return boolean
function stats:stats_fps()
	if not self.config.stats_fps then return false end
	local current_frame = GameGetFrameNum()
	if current_frame % 30 == 0 then
		local current_time = GameGetRealWorldTimeSinceStarted()
		local fps = (current_frame - self.stats.fps_last_frame) / (current_time - self.stats.fps_last_update_time)
		self.stats.fps = math.min(60, math.floor(fps + 0.5))
		self.stats.fps_last_frame = current_frame
		self.stats.fps_last_update_time = current_time
	end
	self:entry("FPS: " .. self.stats.fps, self:get_text_dim("FPS: 60"))
	return true
end

local display_speed = "0"

---Draws player speed
---@private
---@return boolean
function stats:stats_speed()
	if not self.config.stats_show_speed then return false end
	local px, py = self.player_x, self.player_y
	local dx = px - self.stats.speed_last_x
	local dy = py - self.stats.speed_last_y
	local speed = math.sqrt(dx * dx + dy * dy)

	self.stats.speed = (self.stats.speed * 0.9) + (speed * 0.1)

	self.stats.speed_last_x = px
	self.stats.speed_last_y = py

	local speed_string = self:locale("$inventory_speed: ")
	local speed_string_width = self:get_text_dim(speed_string)

	local speed_px_per_sec = self.stats.speed * self.stats.fps
	local interval = math.max(1, math.min(60, math.floor(math.sqrt(speed_px_per_sec) / 8)))
	-- slower update at high velocity to remove flickering
	if GameGetFrameNum() % interval == 0 then display_speed = string.format("%.0f", speed_px_per_sec) end

	local reserved = speed_string_width + math.min(18, self:get_text_dim(display_speed)) + 6
	self:entry(speed_string .. display_speed, reserved)
	return true
end

---Draws stats
---@private
function stats:stats_draw()
	local x = self.header.pos_x + 20
	local y = self.header.pos_y

	local stat_fns = {
		self.stats_fungal,
		self.stats_fps,
		self.stats_time,
		self.stats_kills,
		self.stats_position,
		self.stats_speed,
		self.stats_biome,
	}

	self:layout_at(x, y, function()
		self:begin_row(function()
			for i = 1, #stat_fns do
				if stat_fns[i](self) then self:spacing(7) end
			end
		end)
	end)
end

return stats
