local helper = {} ---@class (exact) LS_Gui

---Starts animation
---@private
---@param reset boolean
function helper:AnimateStart(reset)
	self:AnimateB()
	self:AnimateAlpha(0.1, 0.1, reset)
	self:AnimateScale(0.1, reset)
end

---Sets yellow color for next widget
---@private
function helper:ColorYellow()
	self:Color(1, 1, 0.7)
end

---Splits string and returns lines
---@private
---@param text string
---@param length number
---@return string[]
---@nodiscard
function helper:SplitString(text, length)
	local lines = {}
	local current_line = ""
	for word in text:gmatch("%S+") do
		local test_line = (current_line == "") and word or current_line .. " " .. word
		local width = self:GetTextDimension(test_line)
		if width > length then
			lines[#lines + 1] = current_line
			current_line = word
		else
			current_line = test_line
		end
	end

	-- Add the last line if it's not empty
	if current_line ~= "" then lines[#lines + 1] = current_line end

	return lines
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
	if not self.fs.current_shift or self.fs.current_shift > self.fs.max_shifts then return 0 end

	local last_frame = self.mod:GetGlobalNumber("fungal_shift_last_frame", -1)
	if last_frame < 0 then return 0 end

	local frame = GameGetFrameNum()

	return math.max(math.floor((self.fs.cooldown - (frame - last_frame)) / 60), 0)
end

---Sets max parallel positions
---@private
function helper:ScanPWPosition()
	local player_par_x = GetParallelWorldPosition(self.player_x, self.player_y)
	if player_par_x < self.stats.position_pw_west then
		self.stats.position_pw_west = player_par_x
		GLOBALS_SET_VALUE("lamas_stats_farthest_west", tostring(player_par_x))
	end
	if player_par_x > self.stats.position_pw_east then
		self.stats.position_pw_east = player_par_x
		GLOBALS_SET_VALUE("lamas_stats_farthest_east", tostring(player_par_x))
	end
end

return helper
