---@class (exact) LS_Gui_fungal_offset
---@field shift number offset after shift i: text
---@field group_of number offset after group_of text

---@class (exact) LS_Gui_fungal
---@field x number
---@field y number
---@field current_shift number
---@field offset LS_Gui_fungal_offset
---@field width number

---@class (exact) LS_Gui
---@field private fungal LS_Gui_fungal
local fungal = {
	fungal = {
		current_shift = 1,
		x = 0,
		y = 0,
		offset = {
			shift = 20,
			group_of = 20
		},
		width = 0
	}
}

---@param color {r:number, g:number, b:number, a:number}
function fungal:FungalPotionColor(color)
	self:Color(color.r, color.g, color.b, color.a)
end

---@param material_type number
function fungal:FungalDrawIcon(material_type)
	local data = self.mat:get_data(material_type)
	if data.color then
		self:FungalPotionColor(data.color)
	end
	self:Image(self.fungal.x, self.fungal.y, data.icon)
	self.fungal.x = self.fungal.x + 9
end

---@param material_types number[]
function fungal:FungalDrawIcons(material_types)
	for i = 1, #material_types do
		self:FungalDrawIcon(material_types[i])
	end
end

--[[	Display From]]
function gui_fungal_shift_display_from(gui, material)
	if material.flask == "from" then       --if flask was flagged
		if current_shifts < material.number then --if it's future shift
			gui_fungal_shift_add_potion_icon(gui)
			if material.failed == nil then
				GuiTextRed(gui, 0, 0, _T.lamas_stats_or .. " ", fungal_shift_scale)
			else
				GuiTextRed(gui, 0, 0, _T.lamas_stats_flask, fungal_shift_scale)
				GuiText(gui, 0, 0, "*", fungal_shift_scale)
				GuiEndAutoBoxNinePiece(gui, 0, 0, 0, false, 0, empty_png, empty_png)
				GuiTooltipLamas(gui, 0, 0, guiZ, gui_fungal_shift_display_from_tooltip, material)
				return
			end
		else
			GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
		end
	end

	if material.flask == "from_fail" then
		GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1)
	end

	if ModSettingGet("lamas_stats.fungal_group_type") == "group" then
		if #material.from > 1 then
			GuiText(gui, 0, 0, _T.lamas_stats_fungal_group_of, fungal_shift_scale)
		else
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[material.from[1]].name),
				fungal_shift_scale)
		end
	end

	for _, mat in ipairs(material.from) do
		if ModSettingGet("lamas_stats.fungal_group_type") == "full" then
			if material.flask == "from_fail" then GuiColorSetForNextWidget(gui, 1, 1, 0.698, 1) end
			GuiText(gui, 0, 0, GameTextGetTranslatedOrNot(original_material_properties[mat].name), fungal_shift_scale)
		end
		gui_fungal_shift_add_color_potion_icon(gui, mat)
	end
end

function gui_fungal_shift_display_future_shifts(gui)
	local nextshifttext = _T.lamas_stats_fungal_next_shift
	if (current_shifts < maximum_shifts) and (current_shifts > show_shift_start_from - 2) then
		GuiText(gui, 0, 0, "---- " .. nextshifttext .. " ----", fungal_shift_scale)
	end

	for i = start, maximum_shifts, 1 do
		gui_fungal_shift_display_from(gui, future_shifts[i])
		gui_fungal_shift_display_to(gui, future_shifts[i])
		if i == current_shifts + 1 and i < maximum_shifts then
			GuiLayoutBeginHorizontal(gui, 0, 0, 0, 0, 0)
			GuiText(gui, 0, 0, "---- ", fungal_shift_scale)
			GuiText(gui, GuiGetTextDimensions(gui, nextshifttext, fungal_shift_scale), 0, " ----", fungal_shift_scale)
			GuiLayoutEnd(gui)
		end
		if i % show_shifts_per_screen == 0 then break end
	end
end

---Draws material name and icon
---@private
---@param material_type number
function fungal:FungalDrawSingleMaterial(material_type)
	local data = self.mat:get_data(material_type)
	local name = self:Locale(data.ui_name)
	self:Text(self.fungal.x, self.fungal.y, name)
	self.fungal.x = self.fungal.x + self:GetTextDimension(name)
	self:FungalDrawIcon(material_type)
end

---Draws from materials
---@private
---@param from number[]
function fungal:FungalDrawFromMaterials(from)
	local count = #from
	if count > 1 then
		self:Text(self.fungal.x, self.fungal.y, _T.lamas_stats_fungal_group_of)
		self.fungal.x = self.fungal.x + self.fungal.offset.group_of
		self:FungalDrawIcons(from)
	else
		self:FungalDrawSingleMaterial(from[1])
	end
end

---Draws a shift number
---@private
---@param shift number
function fungal:FungalDrawShiftNumber(shift)
	self:Text(self.fungal.x, self.fungal.y, _T.lamas_stats_shift .. " " .. shift .. ":")
	self.fungal.x = self.fungal.x + self.fungal.offset.shift
end

function fungal:FungalDraw()
	self.fungal.x = 0
	self.fungal.y = 0 - self.scroll.y
	local max_width = 0

	for i = self.fungal.current_shift, 100 do
		local shift = self.sp.shifts[i]
		self:FungalDrawShiftNumber(i)

		self:FungalDrawFromMaterials(shift.from)

		self:Text(self.fungal.x, self.fungal.y, " -> ")
		self.fungal.x = self.fungal.x + 15

		self:FungalDrawSingleMaterial(shift.to)

		self.fungal.y = self.fungal.y + 10
		max_width = math.max(max_width, self.fungal.x)
		self.fungal.x = 0
	end
	self.fungal.width = max_width
	self:Text(0, self.fungal.y + self.scroll.y, "")
end

function fungal:FungalGetSettings()
	self.fungal.offset.shift = self:GetTextDimension(_T.lamas_stats_shift .. "100: ")
	self.fungal.offset.group_of = self:GetTextDimension(_T.lamas_stats_fungal_group_of)
end

function fungal:FungalScrollbox()
	self.scroll.width = self.fungal.width
	self.scroll.height_max = 200
	self:FakeScrollBox(self.menu.pos_x - 1, self.menu.pos_y + 11, self.z + 5, self.c.default_9piece, 5, self.FungalDraw)
end

return fungal
