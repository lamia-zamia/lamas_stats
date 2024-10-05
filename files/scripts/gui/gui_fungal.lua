---@class (exact) LS_Gui_fungal_offset
---@field shift number offset after shift i: text
---@field from number offset after from
---@field to number offset after to
---@field past number
---@field future number

---@class (exact) LS_Gui_fungal
---@field x number
---@field y number
---@field current_shift number
---@field offset LS_Gui_fungal_offset
---@field future boolean to show future window or not
---@field past boolean
---@field row_count number
---@field width number

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
end

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
	self:FungalDrawIcon(x, y, material_type)
	self:Text(x + 9, y, data.ui_name)
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
	self.fungal.x = self.fungal.x + self.fungal.offset.from
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
	else
		local y = self:FungalGetShiftWindowOffset(flask and 2 or 1)
		if flask then
			self:FungalDrawFlaskAvailablity(self.fungal.x, self.fungal.y + y)
			y = y + 10
		end
		self:FungalDrawSingleMaterial(self.fungal.x, self.fungal.y + y, to)
	end
	self.fungal.x = self.fungal.x + self.fungal.offset.to
end

---Draws flask shift indicator
---@param x number
---@param y number
function fungal:FungalDrawFlaskAvailablity(x, y)
	self:Image(x, y, "mods/lamas_stats/files/gfx/held_material.png")
	self:Text(x + 9, y, "Held Material")
end

---Draws a shift number
---@private
---@param shift number
function fungal:FungalDrawShiftNumber(shift)
	local center = self:FungalGetShiftWindowOffset(1)
	self:Text(self.fungal.x, self.fungal.y + center, string.format(_T.lamas_stats_shift .. " %02d", shift))
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

function fungal:FungalDrawFuture()
	for i = self.fungal.current_shift, 20 do
		local shift = self.fs.predictor.shifts[i]

		local from = self:FungalSanitizeFromShifts(shift.from)
		if shift.flask == "from" then
			self.fungal.row_count = self.fungal.row_count + 1
		end
		if shift.flask == "to" and self.fungal.row_count == 1 then
			self.fungal.row_count = self.fungal.row_count + 1
		end

		local height = self.fungal.row_count * 10 + 1

		local color = i % 2 == 0 and 0.4 or 0.6
		self:SetZ(self.z + 4)
		self:Color(color, color, color)
		self:Image(self.fungal.x - 3, self.fungal.y - 1, self.c.px, 0.2, 640, height)

		self:FungalDrawShiftNumber(i)

		self:FungalDrawFromMaterials(from, shift.flask == "from")

		local center = self:FungalGetShiftWindowOffset(1)
		self:Text(self.fungal.x, self.fungal.y + center, " -> ")
		self.fungal.x = self.fungal.x + 15

		self:FungalDrawToMaterial(shift.to, shift.flask == "to")

		self.fungal.y = self.fungal.y + height
		self.fungal.x = 3
	end
end

function fungal:FungalDraw()
	self.fungal.x = 3
	self.fungal.y = 1 - self.scroll.y

	self:AddOption(self.c.options.NonInteractive)

	if self.fungal.future then self:FungalDrawFuture() end

	self:RemoveOption(self.c.options.NonInteractive)
	self:Text(0, self.fungal.y + self.scroll.y, "")
end

function fungal:FungalUpdateWindowDims()
	local max_from = 0
	local max_to = 0
	for i = 1, 20 do
		local shift = self.fs.predictor.shifts[i]
		for j = 1, #shift.from do
			local data = self.mat:get_data(shift.from[j])
			local name = self:Locale(data.ui_name)
			max_from = math.max(max_from, self:GetTextDimension(name))
		end
		local name = self:Locale(self.mat:get_data(shift.to).ui_name)
		max_to = math.max(max_to, self:GetTextDimension(name))
	end

	self.fungal.offset.shift = self:GetTextDimension(_T.lamas_stats_shift .. "000")
	self.fungal.offset.from = max_from + 9
	self.fungal.offset.to = max_to + 9
	self.fungal.offset.past = self:GetTextDimension(_T.EnableFungalPast) + 15
	self.fungal.offset.future = self:GetTextDimension(_T.EnableFungalFuture) + 15

	self.scroll.width = math.max(self.fungal.offset.shift + self.fungal.offset.from + 30 + self.fungal.offset.to + 3,
		self.fungal.offset.past + self.fungal.offset.future)
end

---Fetches settings
function fungal:FungalGetSettings()
	self:FungalUpdateWindowDims()
end

function fungal:FungalDrawWindow()
	if self:IsDrawCheckbox(self.menu.pos_x, self.menu.pos_y - 1, _T.EnableFungalPast, self.fungal.past) then
		if self:IsMouseClicked() then
			self.fungal.past = not self.fungal.past
			self.mod:SetModSetting("enable_fungal_past", self.fungal.past)
		end
	end
	if self:IsDrawCheckbox(self.menu.pos_x + self.fungal.offset.past, self.menu.pos_y - 1, _T.EnableFungalFuture, self.fungal.future) then
		if self:IsMouseClicked() then
			self.fungal.future = not self.fungal.future
			self.mod:SetModSetting("enable_fungal_future", self.fungal.future)
		end
	end
	self.menu.pos_y = self.menu.pos_y + 12
	self:FakeScrollBox(self.menu.pos_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self
		.FungalDraw)
	self:MenuSetWidth(self.scroll.width - 6)
end

---Initialize data for fungal shift
function fungal:FungalInit()
	self:FungalUpdateWindowDims()
	self.fungal.past = self.mod:GetSettingBoolean("enable_fungal_past")
	self.fungal.future = self.mod:GetSettingBoolean("enable_fungal_future")
	self.scroll.width = self.scroll.width
end

return fungal
