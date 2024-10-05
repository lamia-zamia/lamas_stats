---@class (exact) LS_Gui_fungal_offset
---@field shift number offset after shift i: text
---@field from number offset after from
---@field to number offset after to
---@field past number
---@field future number

---@class (exact) LS_Gui_fungal
---@field x number
---@field y number
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

local modules = {
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_helper.lua",
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_future.lua",
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		fungal[k] = v
	end
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

---Draws from materials
---@private
---@param x number
---@param y number
---@param from number[]
---@param flask boolean
function fungal:FungalDrawFromMaterials(x, y, from, flask)
	if not from then
		local center = self:FungalGetShiftWindowOffset(1)
		self:FungalDrawFlaskAvailablity(x, y + center, true)
	else
		local count = #from
		local rows = count + (flask and 1 or 0)
		local y_offset = self:FungalGetShiftWindowOffset(rows)
		if flask then
			self:FungalDrawFlaskAvailablity(x, y + y_offset)
			y_offset = y_offset + 10
		end
		for i = 1, count do
			self:FungalDrawSingleMaterial(x, y + y_offset, from[i])
			y_offset = y_offset + 10
		end
	end
end

---Draws to material
---@private
---@param x number
---@param y number
---@param to number
---@param flask boolean
function fungal:FungalDrawToMaterial(x, y, to, flask)
	if not to then
		local center = self:FungalGetShiftWindowOffset(1)
		self:FungalDrawFlaskAvailablity(x, y + center, true)
	else
		local y_offset = self:FungalGetShiftWindowOffset(flask and 2 or 1)
		if flask then
			self:FungalDrawFlaskAvailablity(x, y + y_offset)
			y_offset = y_offset + 10
		end
		self:FungalDrawSingleMaterial(x, y + y_offset, to)
	end
end


function fungal:FungalDrawPast()
	if self.fs.current_shift <= 1 then return end

	for i = 1, self.fs.current_shift do
		local shift = self.fs.past_shifts[i]

		if not shift then return end --do something

		local from = self:FungalSanitizeFromShifts(shift.from)
		-- if shift.flask == "from" then
		-- 	self.fungal.row_count = self.fungal.row_count + 1
		-- end
		-- if shift.flask == "to" and self.fungal.row_count == 1 then
		-- 	self.fungal.row_count = self.fungal.row_count + 1
		-- end

		local height = self.fungal.row_count * 10 + 1

		local color = i % 2 == 0 and 0.4 or 0.6
		self:SetZ(self.z + 4)
		self:Color(color, color, color)
		self:Image(self.fungal.x - 3, self.fungal.y - 1, self.c.px, 0.2, 640, height)

		self:FungalDrawShiftNumber(i)

		self:FungalDrawFromMaterials(self.fungal.x, self.fungal.y, from, false)
		self.fungal.x = self.fungal.x + self.fungal.offset.from

		self:FungalDrawArrow(self.fungal.x, self.fungal.y)
		self.fungal.x = self.fungal.x + 15

		self:FungalDrawToMaterial(self.fungal.x, self.fungal.y, shift.to, false)
		self.fungal.x = self.fungal.x + self.fungal.offset.to

		self.fungal.y = self.fungal.y + height
		self.fungal.x = 3
	end
end

---Main function to draw shifts
---@private
function fungal:FungalDraw()
	self.fungal.x = 3
	self.fungal.y = 1 - self.scroll.y

	self:AddOption(self.c.options.NonInteractive)

	if self.fungal.past then self:FungalDrawPast() end

	if self.fungal.future then self:FungalDrawFuture() end

	self:RemoveOption(self.c.options.NonInteractive)
	self:Text(0, self.fungal.y + self.scroll.y, "")
end

---Draws checkboxes and shifts
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
	self.scroll.width = self.fungal.width
end

return fungal
