local helper = {} ---@class (exact) LS_Gui

---Sets yellow color for next widget
---@private
function helper:ColorYellow()
	self:Color(1, 1, 0.7)
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
---@return number
---@nodiscard
function helper:GetFungalShiftCooldown()
	if self.mod:GetGlobalNumber("fungal_shift_iteration", 0) > 20 then return 0 end

	local last_frame = self.mod:GetGlobalNumber("fungal_shift_last_frame", -1)
	if last_frame < 0 then return 0 end

	local frame = GameGetFrameNum()
	local fungal_cooldown = 300 * 60

	return math.max(math.floor((fungal_cooldown - (frame - last_frame)) / 60), 0)
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
