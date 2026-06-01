---@class (exact) LS_Gui
---@field private _perk_children_count integer?
---@field private _perk_children_frame integer
---@field private _perk_children_changed boolean
local helper = {
	_perk_children_frame = -1,
	_perk_children_changed = false,
}

local material_name_cache = {}

---Returns true if the player's children entity count changed since last frame.
---Frame-cached: multiple callers in the same frame all see the same result.
---@private
---@return boolean
function helper:check_perk_picked()
	local frame = GameGetFrameNum()
	if frame ~= self._perk_children_frame then
		local count = #(EntityGetAllChildren(self.player) or {})
		self._perk_children_changed = self._perk_children_count ~= nil and count ~= self._perk_children_count
		self._perk_children_count = count
		self._perk_children_frame = frame
	end
	return self._perk_children_changed
end

---Draws a shaded rectangle overlay at the current cursor position without advancing it.
---shade is a grey level (0=black, 1=white).
---@private
---@param width number
---@param height number
---@param shade number
---@param alpha number
---@param dy number?  optional vertical offset (does not affect cursor)
function helper:draw_stripe(width, height, shade, alpha, dy)
	self:overlay(function()
		self:color(shade, shade, shade)
		self:set_z_for_next(self.z_index + 4)
		self:image(self.c.px, { alpha = alpha, scale_x = width, scale_y = height, dy = dy })
	end)
end

---Sets a soft yellow color for the next widget.
---@private
function helper:color_yellow()
	self:color(1, 1, 0.7)
end

---Sets a gray color for the next widget.
---@private
function helper:color_gray()
	self:color(0.6, 0.6, 0.6)
end

---Draws the "press shift to see more" hint, but only when shift-alt mode is off.
---Standard trailer for all tooltips that show extra content in alt mode.
---@private
function helper:alt_hint()
	if not self.alt then
		self:spacing(4)
		self:color_gray()
		self:text(T.PressShiftToSeeMore)
	end
end

---Draws a clickable "[text]" button at an absolute position.
---@private
---@param x number
---@param y number
---@param text string
---@return boolean
---@nodiscard
function helper:is_text_button_clicked(x, y, text)
	text = "[" .. text .. "]"
	local width = self:get_text_dim(text)
	local clicked = false
	if self:is_hovered_at(x - 1, y, width + 1.5, 11, true) then
		self:block_input(x - 1, y, width + 1.5, 11)
		self:color_yellow()
		clicked = self:is_left_clicked()
	end
	self:text_at(x, y, text)
	return clicked
end

---Returns fungal shift cooldown
---@private
---@return number
---@nodiscard
function helper:get_fungal_shift_cooldown()
	if not self.fs.current_shift or self.fs.current_shift > self.fs.max_shifts then return 0 end

	local last_frame = self.mod:GetGlobalNumber("fungal_shift_last_frame", -1)
	if last_frame < 0 then return 0 end

	local frame = GameGetFrameNum()

	return math.max(math.floor((self.fs.cooldown - (frame - last_frame)) / 60), 0)
end

---Updates and persists farthest east/west parallel-world positions.
---@private
function helper:scan_pw_position()
	local player_par_x = GetParallelWorldPosition(self.player_x, self.player_y)
	if player_par_x < self.stats.position_pw_west then
		self.stats.position_pw_west = player_par_x
		GlobalsSetValue("lamas_stats_farthest_west", tostring(player_par_x))
	end
	if player_par_x > self.stats.position_pw_east then
		self.stats.position_pw_east = player_par_x
		GlobalsSetValue("lamas_stats_farthest_east", tostring(player_par_x))
	end
end

---Returns translated + title-cased material name (cached per material id per language).
---@private
---@param material_data material_data
---@return string
function helper:get_material_name(material_data)
	local cached = material_name_cache[material_data.id]
	if cached then return cached end
	local locale = self:locale(material_data.ui_name)
	local name = string.gsub(" " .. locale, "%W%l", string.upper):sub(2)
	material_name_cache[material_data.id] = name
	return name
end

---Clears the material name translation cache. Call on language change.
---@private
function helper:clear_material_name_cache()
	material_name_cache = {}
end

---Draws icon + name [+ id] in the current DIR_H context without an outer begin_row.
---Use inside a begin_row where material is one of several horizontal items.
---@private
---@param mat_type integer
---@param draw_id boolean?
function helper:material_inline_content(mat_type, draw_id)
	local mat = self.mat:get_data(mat_type)
	if mat.color then self:color(mat.color.r, mat.color.g, mat.color.b, mat.color.a) end
	self:image(mat.icon, { dy = 1 })
	self:spacing(1)
	self:text(self:get_material_name(mat))
	if draw_id then
		self:spacing(3)
		self:color_gray()
		self:text("(" .. mat.id .. ")")
	end
end

---Draws one material row (icon + name) advancing parent DOWN. Use inside begin_column.
---@private
---@param mat_type integer
---@param draw_id boolean?
function helper:material_row(mat_type, draw_id)
	self:begin_row(function()
		self:material_inline_content(mat_type, draw_id)
	end)
end

return helper
