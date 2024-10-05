---@class (exact) LS_Gui
local helper = {}

---Returns true if shift is hovered
---@private
---@param x number
---@param y number
---@param height number
---@return boolean
---@nodiscard
function helper:FungalIsHoverBoxHovered(x, y, height)
	if y + height / 2 > 0 and y + height / 2 < self.scroll.height_max and self:IsHoverBoxHovered(self.menu.pos_x + x, self.menu.pos_y + y + 7, self.fungal.width, height)
	then
		return true
	end
	return false
end

---Returns an offset to draw a column
---@private
---@param count number
---@return number
function helper:FungalGetShiftWindowOffset(count)
	return (self.fungal.row_count - count) * 5
end

---Sets color from data
---@private
---@param color {r:number, g:number, b:number, a:number}
function helper:FungalPotionColor(color)
	self:Color(color.r, color.g, color.b, color.a)
end

---Draws a potion icon
---@private
---@param x number
---@param y number
---@param material_type number
function helper:FungalDrawIcon(x, y, material_type)
	local data = self.mat:get_data(material_type)
	if data.color then
		self:FungalPotionColor(data.color)
	end
	self:Image(x, y, data.icon)
end

---Draws material name and icon
---@private
---@param x number
---@param y number
---@param material_type number
function helper:FungalDrawSingleMaterial(x, y, material_type)
	local data = self.mat:get_data(material_type)
	self:FungalDrawIcon(x, y, material_type)
	self:Text(x + 9, y, data.ui_name)
end

---Draws flask shift availablity
---@private
---@param x number
---@param y number
---@param failed? boolean
function helper:FungalDrawFlaskAvailablity(x, y, failed)
	self:Image(x, y, "mods/lamas_stats/files/gfx/held_material.png")
	if failed then self:Color(0.8, 0, 0) end
	self:Text(x + 9, y, "Held Material")
end

---Draws a shift number
---@private
---@param shift number
function helper:FungalDrawShiftNumber(shift)
	local center = self:FungalGetShiftWindowOffset(1)
	self:Text(self.fungal.x, self.fungal.y + center, string.format(_T.lamas_stats_shift .. " %02d", shift))
	self.fungal.x = self.fungal.x + self.fungal.offset.shift
end

---Draws an arrow
---@private
---@param x number
---@param y number
function helper:FungalDrawArrow(x, y)
	local center = self:FungalGetShiftWindowOffset(1)
	self:Text(x, y + center, "->")
end

---Removes duplicate static entries from display
---@private
---@param from number[]
---@return number[]
function helper:FungalSanitizeFromShifts(from)
	if not from or #from == 1 then return from end
	local arr = {}
	for i = 1, #from do
		local data = self.mat:get_data(from[i])
		if not data.static then
			arr[#arr + 1] = from[i]
		end
	end
	return arr
end

---Returns longest string from shift
---@private
---@param shift shift
---@param max_from number
---@param max_to number
---@return number from, number to
function helper:FungalGetLongestTextInShift(shift, max_from, max_to)
	if not shift then return max_from, max_to end
	if shift.to then
		local name = self.mat:get_data(shift.to).ui_name
		max_to = math.max(self:GetTextDimension(self:Locale(name)), max_to)
	end
	if shift.from then
		for j = 1, #shift.from do
			local data = self.mat:get_data(shift.from[j])
			local name = self:Locale(data.ui_name)
			max_from = math.max(max_from, self:GetTextDimension(name))
		end
	end
	return max_from, max_to
end

---Calculates row count for shift
---@private
---@param from number[]
---@param flask string|false
---@return number
function helper:FungalCalculateRowCount(from, flask)
	local rows = from and #from or 1
	if flask == "from" then rows = rows + 1 end
	if rows == 1 and flask == "to" then rows = 2 end
	return rows
end

---Gets longest material name and sets it's width
---@private
function helper:FungalUpdateWindowDims()
	local max_from = 0
	local max_to = 0
	for i = 1, self.fs.current_shift - 1 do
		max_from, max_to = self:FungalGetLongestTextInShift(self.fs.past_shifts[i], max_from, max_to)
	end
	for i = self.fs.current_shift, self.fs.max_shifts do
		max_from, max_to = self:FungalGetLongestTextInShift(self.fs.predictor.shifts[i], max_from, max_to)
	end

	self.fungal.offset.shift = self:GetTextDimension(_T.lamas_stats_shift .. "000")
	self.fungal.offset.from = max_from + 9
	self.fungal.offset.to = max_to + 9
	self.fungal.offset.past = self:GetTextDimension(_T.EnableFungalPast) + 15
	self.fungal.offset.future = self:GetTextDimension(_T.EnableFungalFuture) + 15

	self.fungal.width = math.max(self.fungal.offset.shift + self.fungal.offset.from + 30 + self.fungal.offset.to + 3,
		self.fungal.offset.past + self.fungal.offset.future)
end

---Fetches settings
function helper:FungalGetSettings()
	self:FungalUpdateWindowDims()
end

return helper
