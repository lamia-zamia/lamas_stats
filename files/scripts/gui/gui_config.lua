--- @class LS_Gui_config
--- @field config_list {[string]:string[]}
--- @field unfolded {[string]:boolean}
--- @field y number
--- @field width number
--- @field [string] boolean

--- @class LS_Gui
--- @field config LS_Gui_config
local config = {
	config = {
		y = 0,
		width = 10,
		config_list = {
			Menu = {
				"show_fungal_menu",
				"show_perks_menu",
				"show_kys_menu",
			},
			Stats = {
				"stats_enable",
				"stats_show_fungal_cooldown",
				"stats_showtime",
				"stats_showkills",
				"stats_show_player_pos",
				"stats_position_expanded",
				"stats_show_player_biome"
			},
			Perks = {
				"enable_nearby_perks",
				"enable_nearby_lottery",
				"enable_nearby_always_cast",
			}
		},
		unfolded = {
			Menu = true,
			Stats = true,
			Perks = true
		}
	}
}

function config:ConfigIsHovered()
	return self:IsHoverBoxHovered(self.menu.start_x - 3, self.menu.pos_y + self.config.y + 7, self.scroll.width, 9)
end

function config:ConfigDrawCategory(category)
	local folded = not self.config.unfolded[category]
	local img = folded and "data/ui_gfx/button_fold_close.png" or "data/ui_gfx/button_fold_open.png"
	local category_text = T[category]
	local dim = self:GetTextDimension(category_text)
	local hovered = self:ConfigIsHovered()
	if hovered then self:Color(1, 1, 0.7) end
	self:Text(0, self.config.y, category_text)
	if hovered then self:Color(1, 1, 0.7) end
	self:Image(dim, self.config.y, img)
	if hovered and self:IsLeftClicked() then
		self.config.unfolded[category] = not self.config.unfolded[category]
	end
end

function config:ConfigDrawConfig(entry)
	local value = self.mod:GetSettingBoolean(entry)
	local text = T[entry]
	local text_dim = self:GetTextDimension(text)
	local hovered = self:ConfigIsHovered()
	if hovered then self:ColorYellow() end
	self:Text(8, self.config.y, text)
	self:Draw9Piece(self.menu.start_x + text_dim + 9, self.menu.pos_y + self.config.y + 9, self.z, 6, 6,
		hovered and self.buttons.img_hl or self.buttons.img)
	if value then
		self:Color(0, 0.8, 0)
		self:Text(text_dim + 13, self.config.y, "V")
	else
		self:Color(0.8, 0, 0)
		self:Text(text_dim + 13, self.config.y, "X")
	end
	if hovered and self:IsMouseClicked() then
		self.config[entry] = not self.config[entry]
		self.mod:SetModSetting(entry, self.config[entry])
	end
end

function config:ConfigDrawConfigs(category)
	local entries = self.config.config_list[category]
	for i = 1, #entries do
		self:ConfigDrawConfig(entries[i])
		self.config.y = self.config.y + 12
	end
end

function config:ConfigDraw()
	self.config.y = 0 - self.scroll.y
	for category, _ in pairs(self.config.config_list) do
		self:ConfigDrawCategory(category)
		self.config.y = self.config.y + 10
		if self.config.unfolded[category] then
			self:ConfigDrawConfigs(category)
		end
	end
	self.scroll.width = math.max(self.menu.width + 6, self.config.width)
	self:Text(0, self.config.y + self.scroll.y + 10, "")
end

function config:ConfigDrawScrollBox()
	self:ScrollBox(self.menu.start_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self.ConfigDraw)
	self:MenuSetWidth(self.scroll.width - 6)
end

--- Fetch settings
--- @private
function config:ConfigGetSettings()
	local max = 0
	for category, _ in pairs(self.config.config_list) do
		local entries = self.config.config_list[category]
		for j = 1, #entries do
			local config_key = entries[j]
			self.config[config_key] = self.mod:GetSettingBoolean(config_key)
			max = math.max(max, self:GetTextDimension(T[config_key]) + 22)
		end
	end
	self.config.width = max
end

function config:ConfigInit()
	self:ConfigGetSettings()
end

return config
