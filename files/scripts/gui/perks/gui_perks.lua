---@class LS_Gui_perks
---@field x number
---@field y number
---@field current_window function|nil

---@class (exact) LS_Gui
---@field perk LS_Gui_perks
local pg = {
	perk = {
		x = 0,
		y = 0,
		current_window = nil
	}
}

---Draws stats for perks
function pg:PerksDrawStats()
	local extra_perk = self.perks.data_perks["EXTRA_PERK"]
	local perks_lottery = self.perks.data_perks["PERKS_LOTTERY"]
	local reroll_count = self.mod:GetGlobalNumber("TEMPLE_PERK_REROLL_COUNT")

	if self.perks.total_amount > 0 then
		local text = string.format(_T.Perks .. ": %d", self.perks.total_amount)
		self:Text(self.perk.x, self.perk.y, text)
		local offset = self:GetTextDimension(text)
		self.perk.x = self.perk.x + offset + 4
	end

	if reroll_count > 0 then
		local text = tostring(reroll_count)
		local offset = self:GetTextDimension(text)
		self:Image(self.perk.x, self.perk.y - 2.5, "mods/lamas_stats/files/gfx/reroll_machine.png", 1, 1)
		self.perk.x = self.perk.x + 17
		self:Text(self.perk.x, self.perk.y, text)
		self.perk.x = self.perk.x + offset + 4
	end

	if extra_perk.picked_count > 0 then
		local text = tostring(extra_perk.picked_count)
		local offset = self:GetTextDimension(text)
		self:Image(self.perk.x, self.perk.y - 2.5, extra_perk.perk_icon, 1, 1)
		self.perk.x = self.perk.x + 17
		self:Text(self.perk.x, self.perk.y, text)
		self.perk.x = self.perk.x + offset + 4
	end

	if perks_lottery.picked_count > 0 then
		local chance = 100 - math.floor(self.mod:GetGlobalNumber("TEMPLE_PERK_DESTROY_CHANCE", 100))
		local text = chance .. "%"
		local offset = self:GetTextDimension(text)
		self:Image(self.perk.x, self.perk.y - 2.5, perks_lottery.perk_icon, 1, 1)
		self.perk.x = self.perk.x + 17
		self:Text(self.perk.x, self.perk.y, text)
		self.perk.x = self.perk.x + offset + 4
	end


	self.perk.x = 0
	-- tostring(100 - math.floor(GlobalsGetValue("TEMPLE_PERK_DESTROY_CHANCE", "100"))) .. "%"
end

---Adds clickable button
---@param text string
---@param fn function
function pg:PerksAddButton(text, fn)
	if self.perk.current_window == fn then
		self:DrawButton(self.perk.x, self.perk.y, self.z - 1, text, false,
			"mods/lamas_stats/files/gfx/ui_9piece_button_alt.png")
		if self:IsHovered() and self:IsLeftClicked() then
			self.perk.current_window = nil
		end
	else
		self:DrawButton(self.perk.x, self.perk.y, self.z - 1, text, true,
			"mods/lamas_stats/files/gfx/ui_9piece_button_alt.png",
			"mods/lamas_stats/files/gfx/ui_9piece_button_alt_highlight.png")
		if self:IsHovered() and self:IsLeftClicked() then
			self:FakeScrollBox_Reset()
			self.scroll.height_max = 200
			self.perk.current_window = fn
		end
	end
	self.perk.x = self.perk.x + self:GetTextDimension(text) + 9
end

---Draws stats and perks window
function pg:PerksDrawWindow()
	self.perk.x = self.menu.start_x
	self.perk.y = self.menu.pos_y + 7
	-- if self:IsDrawCheckbox(self.menu.pos_x, self.menu.pos_y - 1, _T.EnableFungalPast, self.fungal.past) then
	-- 	if self:IsMouseClicked() then
	-- 		self.fungal.past = not self.fungal.past
	-- 		self.mod:SetModSetting("enable_fungal_past", self.fungal.past)
	-- 	end
	-- end
	-- if self:IsDrawCheckbox(self.menu.pos_x + self.fungal.offset.past, self.menu.pos_y - 1, _T.EnableFungalFuture, self.fungal.future) then
	-- 	if self:IsMouseClicked() then
	-- 		self.fungal.future = not self.fungal.future
	-- 		self.mod:SetModSetting("enable_fungal_future", self.fungal.future)
	-- 	end
	-- end
	self:Draw9Piece(self.menu.start_x - 6, self.menu.pos_y + 4, self.z + 49, self.scroll.width + 6, 17)
	self:PerksAddButton("Current", print)
	self:PerksAddButton("Predict", function() end)
	self:PerksDrawStats()

	-- self.menu.pos_y = self.menu.pos_y + 15
	-- self:FakeScrollBox(self.menu.pos_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self)
	self:MenuSetWidth(self.scroll.width - 6)
end

---Initialize data for perks
function pg:PerksInit()
	self.perks:get_current_list()
	-- self:FungalUpdateWindowDims()
	-- self.fungal.past = self.mod:GetSettingBoolean("enable_fungal_past")
	-- self.fungal.future = self.mod:GetSettingBoolean("enable_fungal_future")
	-- self.scroll.width = self.fungal.width
end

return pg
