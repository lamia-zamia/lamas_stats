---@class LS_Gui_config
---@field config_order string[]
---@field config_list {[string]:string[]}
---@field unfolded {[string]:boolean}
---@field width number
---@field scroll_h number
---@field [string] boolean

---@class LS_Gui
---@field config LS_Gui_config
local config = {
	config = {
		width = 10,
		scroll_h = 0,
		config_order = { "Menu", "Stats", "Perks" },
		config_list = {
			Menu = {
				"show_fungal_menu",
				"show_perks_menu",
				"show_shops_menu",
				"show_materials",
				"show_kys_menu",
			},
			Stats = {
				"stats_enable",
				"stats_fps",
				"stats_show_fungal_cooldown",
				"stats_showtime",
				"stats_showkills",
				"stats_show_player_pos",
				"stats_position_expanded",
				"stats_show_speed",
				"stats_show_player_biome",
			},
			Perks = {
				"enable_nearby_perks",
				"enable_nearby_lottery",
				"enable_nearby_always_cast",
				"always_show_always_cast",
			},
		},
		unfolded = {
			Menu = true,
			Stats = true,
			Perks = true,
		},
	},
}

---Category header with fold toggle.
---@private
---@param category string
function config:config_draw_category(category)
	local folded = not self.config.unfolded[category]
	local arrow = folded and "data/ui_gfx/button_fold_close.png" or "data/ui_gfx/button_fold_open.png"
	local hovered = self:is_hovered_cursor(self.config.width, 9)

	self:begin_row(function()
		if hovered then self:color(1, 1, 0.7) end
		self:text(T[category])
		self:spacing(2)
		self:image(arrow)
	end)

	if hovered and self:is_left_clicked() then self.config.unfolded[category] = not self.config.unfolded[category] end
	self:spacing(2)
end

---Checkbox row for one boolean setting.
---@private
---@param entry string
function config:config_draw_config(entry)
	local value = self.mod:GetSettingBoolean(entry)
	local clicked = false
	-- A row with a leading gap = the indent (cursor-idiomatic, no dx option).
	self:begin_row(function()
		self:spacing(8)
		clicked = self:checkbox(T[entry], value)
	end)
	if clicked then
		local new_value = not value
		self.config[entry] = new_value
		self.mod:SetModSetting(entry, new_value)
	end
	self:spacing(3)
end

---Scrollable settings list.
---@private
function config:config_draw_scroll_box()
	local scrollbox_w = math.max(self.config.width, self:fill_width())
	local box_h = self.config.scroll_h > 0 and math.min(self.config.scroll_h, self.max_height) or self.max_height
	local _, content_h = self:begin_scrollbox("config", scrollbox_w, box_h, function()
		for _, category in ipairs(self.config.config_order) do
			self:config_draw_category(category)
			if self.config.unfolded[category] then
				local entries = self.config.config_list[category]
				for i = 1, #entries do
					self:config_draw_config(entries[i])
				end
			end
		end
	end)
	self.config.scroll_h = content_h
end

---Fetches and caches settings; re-measures text on language change.
---@private
---@param did_language_changed boolean
function config:config_get_settings(did_language_changed)
	if not did_language_changed then return end
	local max = 0
	for _, category in ipairs(self.config.config_order) do
		local entries = self.config.config_list[category]
		for j = 1, #entries do
			local config_key = entries[j]
			self.config[config_key] = self.mod:GetSettingBoolean(config_key)
			max = math.max(max, self:get_text_dim(T[config_key]) + 25)
		end
	end
	self.config.width = max
end

---Re-measures all setting label widths; called when the config window is opened.
---@private
function config:config_init()
	local max = 0
	for _, category in ipairs(self.config.config_order) do
		for _, key in ipairs(self.config.config_list[category]) do
			max = math.max(max, self:get_text_dim(T[key]) + 25)
		end
	end
	self.config.width = max
end

return config
