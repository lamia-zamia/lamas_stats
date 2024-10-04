local helper = {} ---@class (exact) LS_Gui

---Sets yellow color for next widget
---@private
function helper:ColorYellow()
	self:Color(1, 1, 0.7)
end

---Draws checbox
---@param x number
---@param y number
---@param text string
---@param value boolean
---@return boolean hovered
function helper:IsDrawCheckbox(x, y, text, value)
	local text_dim = self:GetTextDimension(text)
	local hovered = self:IsHoverBoxHovered(x, y + 1, text_dim + 13, 9)
	if hovered then self:ColorYellow() end
	self:Text(x, y, text)
	self:Draw9Piece(x + text_dim + 4, y + 2, self.z, 6, 6, hovered and self.buttons.img_hl or self.buttons.img)
	if value then
		self:Color(0, 0.8, 0)
		self:Text(x + text_dim + 5, y, "V")
	else
		self:Color(0.8, 0, 0)
		self:Text(x + text_dim + 5, y, "X")
	end
	return hovered
end

---Draws text button
---@private
---@param x number
---@param y number
---@param text string
---@return boolean
---@nodiscard
function helper:IsTextButtonClicked(x, y, text)
	text = "[" .. text .. "]"
	local width = self:GetTextDimension(text)
	local clicked = false
	if self:IsHoverBoxHovered(x - 1, y, width + 1.5, 11) then
		self:ColorYellow()
		clicked = self:IsLeftClicked()
	end
	self:Text(x, y, text)
	return clicked
end

---Returns fungal shift cooldown
---@private
---@return number
---@nodiscard
function helper:GetFungalShiftCooldown()
	if self.mod:GetGlobalNumber("fungal_shift_iteration", 0) > self.sp.max_shifts then return 0 end

	local last_frame = self.mod:GetGlobalNumber("fungal_shift_last_frame", -1)
	if last_frame < 0 then return 0 end

	local frame = GameGetFrameNum()

	return math.max(math.floor((self.sp.cooldown - (frame - last_frame)) / 60), 0)
end

---Sets max parallel positions
---@private
function helper:ScanPWPosition()
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

return helper
