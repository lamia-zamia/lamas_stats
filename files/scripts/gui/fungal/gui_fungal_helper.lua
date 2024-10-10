--- @class (exact) LS_Gui_fungal_offset
--- @field shift number offset after shift i: text
--- @field from number offset after from
--- @field to number offset after to
--- @field past number
--- @field future number
--- @field held number

--- @class (exact) LS_Gui
local helper = {}

--- Draws a text and returns text dim
--- @private
--- @param x number
--- @param y number
--- @param text string
--- @return number
function helper:FungalText(x, y, text)
	self:Text(x, y, text)
	return (self:GetTextDimension(text))
end

--- Returns true if shift is hovered
--- @private
--- @param x number
--- @param y number
--- @param height number
--- @return boolean
--- @nodiscard
function helper:FungalIsHoverBoxHovered(x, y, height)
	if y + height / 2 > 0 and y + height / 2 < self.scroll.height_max and self:IsHoverBoxHovered(self.menu.start_x + x - 6, self.menu.pos_y + y + 7, self.fungal.width - 3, height, true)
	then
		return true
	end
	return false
end

--- Returns an offset to draw a column
--- @private
--- @param count number
--- @return number
function helper:FungalGetShiftWindowOffset(count)
	return (self.fungal.row_count - count) * 5
end

--- Returns translated material name
--- @private
--- @param material_type integer
--- @return string
--- @nodiscard
function helper:FungalGetName(material_type)
	local locale = self:Locale(self.mat:GetData(material_type).ui_name)
	return string.gsub(" " .. locale, "%W%l", string.upper):sub(2)
end

--- Sets color from data
--- @private
--- @param color {r:number, g:number, b:number, a:number}
function helper:FungalPotionColor(color)
	self:Color(color.r, color.g, color.b, color.a)
end

--- Draws a potion icon
--- @private
--- @param x number
--- @param y number
--- @param material_type integer
function helper:FungalDrawIcon(x, y, material_type)
	local data = self.mat:GetData(material_type)
	if data.color then
		self:FungalPotionColor(data.color)
	end
	self:Image(x, y + 1, data.icon)
end

--- Draws material name and icon
--- @private
--- @param x number
--- @param y number
--- @param material_type integer
--- @param draw_id? boolean
function helper:FungalDrawSingleMaterial(x, y, material_type, draw_id)
	self:FungalDrawIcon(x, y, material_type)
	local material_name = self:FungalGetName(material_type)
	x = x + 9
	self:Text(x, y, material_name)
	if draw_id then
		x = x + self:GetTextDimension(material_name) + 3
		self:ColorGray()
		self:Text(x, y, "(" .. self.mat:GetData(material_type).id .. ")")
	end
end

--- Draws flask shift availablity
--- @private
--- @param x number
--- @param y number
--- @param color? {[1]:number, [2]: number, [3]:number}
function helper:FungalDrawHeldMaterial(x, y, color)
	self:Image(x, y + 1, "mods/lamas_stats/files/gfx/held_material.png")
	if color then self:Color(unpack(color)) end
	self:Text(x + 9, y, T.HeldMaterial)
end

--- Draws a shift number
--- @private
--- @param shift integer
function helper:FungalDrawShiftNumber(shift)
	local center = self:FungalGetShiftWindowOffset(1)
	self:Text(self.fungal.x, self.fungal.y + center, string.format(T.lamas_stats_shift .. " %02d", shift))
	self.fungal.x = self.fungal.x + self.fungal.offset.shift
end

--- Draws an arrow
--- @private
--- @param x number
--- @param y number
function helper:FungalDrawArrow(x, y)
	local center = self:FungalGetShiftWindowOffset(1)
	self:Image(x, y + center, "mods/lamas_stats/files/gfx/arrow.png")
	-- self:Text(x, y + center, "->")
end

--- Removes duplicate static entries from display
--- @private
--- @param from integer[]
--- @return integer[]
function helper:FungalSanitizeFromShifts(from)
	if not from or #from == 1 then return from end
	local arr = {}
	for i = 1, #from do
		local data = self.mat:GetData(from[i])
		if not data.static then
			arr[#arr + 1] = from[i]
		end
	end
	if #arr < 1 then return from end
	return arr
end

--- Returns a length of material name
--- @private
--- @param material integer
--- @param draw_id boolean?
--- @return number
--- @nodiscard
function helper:FungalGetMaterialNameLength(material, draw_id)
	local id = draw_id and self:GetTextDimension("(" .. self.mat:GetData(material).id .. ")") or 0
	return self:GetTextDimension(self:FungalGetName(material)) + 9 + id
end

--- Returns longest material name from array of material types
--- @private
--- @param material_types integer[]
--- @param max number
--- @param draw_id? boolean
--- @return number
--- @nodiscard
function helper:FungalGetLongestMaterialName(material_types, max, draw_id)
	for i = 1, #material_types do
		max = math.max(max, self:FungalGetMaterialNameLength(material_types[i], draw_id))
	end
	return max
end

--- Returns longest string from shift
--- @private
--- @param shift shift|failed_shift
--- @param max_from number
--- @param max_to number
--- @param ignore_flask? boolean
--- @param draw_id? boolean
--- @return number from, number to
function helper:FungalGetLongestTextInShift(shift, max_from, max_to, ignore_flask, draw_id)
	if not shift then return max_from, max_to end
	if shift.flask and not ignore_flask then
		if shift.flask == "to" then
			max_to = math.max(self.fungal.offset.held + 9, max_to)
		else
			max_from = math.max(self.fungal.offset.held + 9, max_from)
		end
	end
	if shift.to then
		max_to = math.max(max_to, self:FungalGetMaterialNameLength(shift.to, draw_id))
	end
	if shift.from then
		max_from = self:FungalGetLongestMaterialName(shift.from, max_from, draw_id)
	end
	return max_from, max_to
end

--- Calculates row count for shift
--- @private
--- @param from integer[]
--- @param to integer
--- @param flask string|false
--- @return integer
function helper:FungalCalculateRowCount(from, to, flask)
	local rows = from and #from or 1
	if flask == "from" and from[1] then rows = rows + 1 end
	if rows == 1 and flask == "to" and to then rows = 2 end
	return rows
end

--- Sets max from and to offset
--- @private
function helper:FungalSetFungalListOffset()
	local max_from = 0
	local max_to = 0
	for i = 1, self.fs.current_shift - 1 do
		max_from, max_to = self:FungalGetLongestTextInShift(self.fs.past_shifts[i], max_from, max_to)
	end
	for i = self.fs.current_shift, self.fs.max_shifts do
		max_from, max_to = self:FungalGetLongestTextInShift(self.fs.predictor.shifts[i], max_from, max_to)
	end

	self.fungal.offset.from = max_from
	self.fungal.offset.to = max_to
end

--- Updates data
--- @private
function helper:FungalShiftListChanged()
	self.fs:AnalysePastShifts()
	self:FungalSetFungalListOffset()
	self.fungal.width = math.max(self.fungal.offset.shift + self.fungal.offset.from + 30 + self.fungal.offset.to + 3,
		self.fungal.offset.past + self.fungal.offset.future)
end

--- Gets longest material name and sets it's width
--- @private
function helper:FungalUpdateWindowDims()
	self.fungal.offset.shift = self:GetTextDimension(T.lamas_stats_shift .. "000")
	self.fungal.offset.past = self:GetTextDimension(T.EnableFungalPast) + 15
	self.fungal.offset.future = self:GetTextDimension(T.EnableFungalFuture) + 15
	self.fungal.offset.held = self:GetTextDimension(T.HeldMaterial)

	self:FungalSetFungalListOffset()

	self.fungal.width = math.max(self.fungal.offset.shift + self.fungal.offset.from + 30 + self.fungal.offset.to + 3,
		self.fungal.offset.past + self.fungal.offset.future)
end

--- Fetches settings
function helper:FungalGetSettings()
	self:FungalUpdateWindowDims()
end

return helper
