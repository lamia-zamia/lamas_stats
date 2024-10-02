local helper = {} ---@class LS_Gui

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

return helper
