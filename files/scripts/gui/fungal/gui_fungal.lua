--- @class (exact) LS_Gui_fungal
--- @field x number
--- @field y number
--- @field offset LS_Gui_fungal_offset
--- @field future boolean to show future window or not
--- @field past boolean
--- @field row_count number
--- @field width number

--- @class (exact) LS_Gui
--- @field private fungal LS_Gui_fungal
local fungal = {
	fungal = { --- @diagnostic disable-line: missing-fields
		current_shift = 1,
		offset = {}, --- @diagnostic disable-line: missing-fields
	},
}

local modules = {
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_helper.lua",
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_future.lua",
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_past.lua",
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_aplc.lua",
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		fungal[k] = v
	end
end

--- Draws from materials
--- @private
--- @param x number
--- @param y number
--- @param from number[]
--- @param flask boolean
--- @param draw_id? boolean
function fungal:FungalDrawFromMaterials(x, y, from, flask, draw_id)
	if not from then
		local center = self:FungalGetShiftWindowOffset(1)
		self:FungalDrawHeldMaterial(x, y + center, { 0.8, 0, 0 })
	else
		local count = #from
		local rows = count + (flask and 1 or 0)
		local y_offset = self:FungalGetShiftWindowOffset(rows)
		if flask then
			self:FungalDrawHeldMaterial(x, y + y_offset)
			y_offset = y_offset + 10
		end
		for i = 1, count do
			self:FungalDrawSingleMaterial(x, y + y_offset, from[i], draw_id)
			y_offset = y_offset + 10
		end
	end
end

--- Draws to material
--- @private
--- @param x number
--- @param y number
--- @param to number
--- @param flask boolean
--- @param draw_id? boolean
function fungal:FungalDrawToMaterial(x, y, to, flask, draw_id)
	if not to then
		local center = self:FungalGetShiftWindowOffset(1)
		self:FungalDrawHeldMaterial(x, y + center, { 0.8, 0, 0 })
	else
		local y_offset = self:FungalGetShiftWindowOffset(flask and 2 or 1)
		if flask then
			self:FungalDrawHeldMaterial(x, y + y_offset)
			y_offset = y_offset + 10
		end
		self:FungalDrawSingleMaterial(x, y + y_offset, to, draw_id)
	end
end

--- Main function to draw shifts
--- @private
function fungal:FungalDraw()
	self.fungal.x = 3
	self.fungal.y = 1 - self.scroll.y

	self:AddOption(self.c.options.NonInteractive)

	if self.fungal.past and self.fs.current_shift > 1 then self:FungalDrawPast() end

	if self.fungal.future and self.fs.current_shift <= self.fs.max_shifts then self:FungalDrawFuture() end

	self:RemoveOption(self.c.options.NonInteractive)
	self:Text(0, self.fungal.y + self.scroll.y, "")
end

--- Draws checkboxes and shifts
function fungal:FungalDrawWindow()
	if self:IsDrawCheckbox(self.menu.pos_x, self.menu.pos_y - 1, T.EnableFungalPast, self.fungal.past) then
		if self:IsMouseClicked() then
			self.fungal.past = not self.fungal.past
			self.mod:SetModSetting("enable_fungal_past", self.fungal.past)
		end
	end
	if self:IsDrawCheckbox(self.menu.pos_x + self.fungal.offset.past, self.menu.pos_y - 1, T.EnableFungalFuture, self.fungal.future) then
		if self:IsMouseClicked() then
			self.fungal.future = not self.fungal.future
			self.mod:SetModSetting("enable_fungal_future", self.fungal.future)
		end
	end
	if self.fs.aplc then self:FungalApLcDraw(self.menu.start_x + self.fungal.width - 21, self.menu.start_y + 3) end

	self.menu.pos_y = self.menu.pos_y + 12
	self:ScrollBox(self.menu.start_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self.FungalDraw)
	self:MenuSetWidth(self.scroll.width - 6)
end

--- Initialize data for fungal shift
function fungal:FungalInit()
	self:FungalUpdateWindowDims()
	self.fungal.past = self.mod:GetSettingBoolean("enable_fungal_past")
	self.fungal.future = self.mod:GetSettingBoolean("enable_fungal_future")
	self.scroll.width = self.fungal.width
end

return fungal
