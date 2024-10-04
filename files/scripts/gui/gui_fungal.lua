---@class (exact) LS_Gui_fungal_offset
---@field shift number offset after shift i: text
---@field group_of number offset after group_of text
---@field or_flask number offset after or_flask text

---@class (exact) LS_Gui_fungal
---@field x number
---@field y number
---@field current_shift number
---@field offset LS_Gui_fungal_offset
---@field future boolean to show future window or not
---@field row_count number

---@class (exact) LS_Gui
---@field private fungal LS_Gui_fungal
local fungal = {
	fungal = { ---@diagnostic disable-line: missing-fields
		current_shift = 1,
		offset = {}, ---@diagnostic disable-line: missing-fields
	}
}

---Returns an offset to draw a column
---@param count number
---@return number
function fungal:FungalGetShiftWindowOffset(count)
	return (self.fungal.row_count - count) * 5
end

---@param color {r:number, g:number, b:number, a:number}
function fungal:FungalPotionColor(color)
	self:Color(color.r, color.g, color.b, color.a)
end

---Draws potion icon
---@private
---@param x number
---@param y number
---@param material_type number
function fungal:FungalDrawIcon(x, y, material_type)
	local data = self.mat:get_data(material_type)
	if data.color then
		self:FungalPotionColor(data.color)
	end
	self:Image(x, y, data.icon)
	-- self.fungal.x = self.fungal.x + 9
end

---Draws potions icons
--@private
--@param material_types number[]
-- function fungal:FungalDrawIcons(material_types)
-- 	for i = 1, #material_types do
-- 		self:FungalDrawIcon(material_types[i])
-- 	end
-- end

--[[	Display From ]]
-- function gui_fungal_shift_display_from(gui, material)
-- 	if material.flask == "from" then       --if flask was flagged
-- 		if current_shifts < material.number then --if it's future shift
-- 			gui_fungal_shift_add_potion_icon(gui)
-- 			if material.failed == nil then
-- 				GuiTextRed(gui, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
-- 			else
-- 				GuiTextRed(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
-- 				GuiText(gui, 0, 0, "*", fungal_shift_scale)
-- 				GuiEndAutoBoxNinePiece(gui, 0, 0, 0, false, 0, empty_png, empty_png)
-- 				GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_shift_display_from_tooltip, material)
-- 				return
-- 			end
-- 		else
-- 			GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
-- 		end
-- 	end

-- 	if material.flask == "from_fail" then
-- 		GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
-- 	end

-- 	if ModSettingGet("lamas_stats.fungal_group_type") == "group" then
-- 		if #material.from > 1 then
-- 			GuiText(gui, 0, 0, _T.lamas_stats_fungal_group_of, fungal_shift_scale)
-- 		else
-- 			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.from[1]].name),
-- 				fungal_shift_scale)
-- 		end
-- 	end

-- 	for _, mat in ipairs(material.from) do
-- 		if ModSettingGet("lamas_stats.fungal_group_type") == "full" then
-- 			if material.flask == "from_fail" then GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1) end
-- 			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
-- 		end
-- 		gui_fungal_shift_add_color_potion_icon(gui, mat)
-- 	end
-- end

-- function gui_fungal_shift_display_future_shifts(gui)
-- 	local nextshifttext = _T.lamas_stats_fungal_next_shift
-- 	if (current_shifts < maximum_shifts) and (current_shifts > show_shift_start_from - 2) then
-- 		GuiText(gui, 0, 0, "---- " .. nextshifttext .. " ----", fungal_shift_scale)
-- 	end

-- 	for i = start, maximum_shifts, 1 do
-- 		gui_fungal_shift_display_from(gui, future_shifts[i])
-- 		gui_fungal_shift_display_to(gui, future_shifts[i])
-- 		if i == current_shifts + 1 and i < maximum_shifts then
-- 			GuiLayoutBeginHorizontal(gui, 0, 0, 0, 0, 0)
-- 			GuiText(gui, 0, 0, "---- ", fungal_shift_scale)
-- 			GuiText(gui, GuiGetTextDimensions(gui, nextshifttext, fungal_shift_scale), 0, " ----", fungal_shift_scale)
-- 			GuiLayoutEnd(gui)
-- 		end
-- 		if i % show_shifts_per_screen == 0 then break end
-- 	end
-- end

---Draws material name and icon
---@private
---@param x number
---@param y number
---@param material_type number
function fungal:FungalDrawSingleMaterial(x, y, material_type)
	local data = self.mat:get_data(material_type)
	local name = self:Locale(data.ui_name)
	self:Text(x, y, name)
	-- self.fungal.x = self.fungal.x + self:GetTextDimension(name)
	self:FungalDrawIcon(x + self:GetTextDimension(name), y, material_type)
end

---Draws from materials
---@private
---@param from number[]
---@param flask boolean
function fungal:FungalDrawFromMaterials(from, flask)
	if not from then
		local center = self:FungalGetShiftWindowOffset(1)
		self:Color(0.8, 0, 0)
		self:Text(self.fungal.x, self.fungal.y + center, "*")
	else
		local count = #from
		local rows = count + (flask and 1 or 0)
		local y = self:FungalGetShiftWindowOffset(rows)
		if flask then
			self:FungalDrawFlaskAvailablity(self.fungal.x, self.fungal.y + y)
			y = y + 10
		end
		for i = 1, count do
			self:FungalDrawSingleMaterial(self.fungal.x, self.fungal.y + y, from[i])
			y = y + 10
		end
	end
	--
	-- if count > 1 then
	-- 	-- self:Text(self.fungal.x, self.fungal.y, _T.lamas_stats_fungal_group_of)
	-- 	-- self.fungal.x = self.fungal.x + self.fungal.offset.group_of
	-- 	self:FungalDrawIcons(from)
	-- else
	-- 	self:FungalDrawSingleMaterial(from[1])
	-- end
end

---Draws to material
---@private
---@param to number
---@param flask boolean
function fungal:FungalDrawToMaterial(to, flask)
	if not to then
		local center = self:FungalGetShiftWindowOffset(1)
		self:Color(0.8, 0, 0)
		self:Text(self.fungal.x, self.fungal.y + center, "*")
		-- self.fungal.x = self.fungal.x + 5
	else
		local y = self:FungalGetShiftWindowOffset(flask and 2 or 1)
		-- local y = 0
		if flask then
			self:FungalDrawFlaskAvailablity(self.fungal.x, self.fungal.y + y)
			y = y + 10
		end
		self:FungalDrawSingleMaterial(self.fungal.x, self.fungal.y + y, to)
		-- if shift.flask == "to" then self:FungalDrawFlaskAvailablity() end
	end
end

---Draws flask shift indicator
---@param x number
---@param y number
function fungal:FungalDrawFlaskAvailablity(x, y)
	self:Text(x, y, _T.lamas_stats_or)
	self:Image(x + self.fungal.offset.or_flask, y, "data/items_gfx/potion.png")
end

---Draws a shift number
---@private
---@param shift number
function fungal:FungalDrawShiftNumber(shift)
	local center = self:FungalGetShiftWindowOffset(1)
	self:Text(self.fungal.x, self.fungal.y + center, string.format(_T.lamas_stats_shift .. " %02d:", shift))
	self.fungal.x = self.fungal.x + self.fungal.offset.shift
end

---Removes duplicate entries
---@private
---@param from number[]
---@return number[]
function fungal:FungalSanitizeFromShifts(from)
	if not from or #from == 1 then
		self.fungal.row_count = 1
		return from
	end
	local arr = {}
	for i = 1, #from do
		local data = self.mat:get_data(from[i])
		if not data.static then
			arr[#arr + 1] = from[i]
		end
	end
	self.fungal.row_count = #arr
	return arr
end

function fungal:FungalDraw()
	self.fungal.x = 0
	self.fungal.y = 0 - self.scroll.y
	local max_width = 0

	for i = self.fungal.current_shift, 20 do
		local shift = self.sp.shifts[i]

		local from = self:FungalSanitizeFromShifts(shift.from)
		if shift.flask == "from" then
			self.fungal.row_count = self.fungal.row_count + 1
		end
		if shift.flask == "to" and self.fungal.row_count == 1 then
			self.fungal.row_count = self.fungal.row_count + 1
		end
		-- if i == 1 then print(self.fungal.row_count, self:FungalGetShiftWindowOffset(3)) end

		local height = self.fungal.row_count * 10 + 1
		self:AddOptionForNext(self.c.options.NonInteractive)
		self:SetZ(self.z + 50)
		self:Color(0, 0, 0)
		if i % 2 == 1 then
			self:Color(0.3, 0.3, 0.3)
		end
		self:Image(self.fungal.x - 50, self.fungal.y, self.c.px, 0.5, 640, height)
		
		self:FungalDrawShiftNumber(i)

		self:FungalDrawFromMaterials(from, shift.flask == "from")
		-- if shift.flask == "from" then self:FungalDrawFlaskAvailablity() end
		self.fungal.x = self.fungal.x + 90
		local center = self:FungalGetShiftWindowOffset(1)
		self:Text(self.fungal.x, self.fungal.y + center, " -> ")
		self.fungal.x = self.fungal.x + 30
		
		self:FungalDrawToMaterial(shift.to, shift.flask == "to")
		self.fungal.x = self.fungal.x + 90
		-- if not shift.to then
		-- 	self:Color(0.8, 0, 0)
		-- 	self:Text(self.fungal.x, self.fungal.y, "*")
		-- 	self.fungal.x = self.fungal.x + 5
		-- else
		-- 	-- self:FungalDrawSingleMaterial(shift.to)
		-- 	if shift.flask == "to" then self:FungalDrawFlaskAvailablity() end
		-- end

		self.fungal.y = self.fungal.y + height
		max_width = math.max(max_width, self.fungal.x)
		self.fungal.x = 0
	end
	self.scroll.width = max_width
	self:MenuSetWidth(max_width - 6)
	self:Text(0, self.fungal.y + self.scroll.y, "")
end

function fungal:FungalGetSettings()
	self.fungal.offset.shift = self:GetTextDimension(_T.lamas_stats_shift .. "000: ")
	self.fungal.offset.group_of = self:GetTextDimension(_T.lamas_stats_fungal_group_of)
	self.fungal.offset.or_flask = self:GetTextDimension(_T.lamas_stats_or)
end

function fungal:FungalDrawWindow()
	if self:IsDrawCheckbox(self.menu.pos_x, self.menu.pos_y - 1, "Future", self.fungal.future) then
		if self:IsMouseClicked() then
			self.fungal.future = not self.fungal.future
		end
	end
	self.menu.pos_y = self.menu.pos_y + 12
	self:FakeScrollBox(self.menu.pos_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, self.FungalDraw)
end

return fungal
