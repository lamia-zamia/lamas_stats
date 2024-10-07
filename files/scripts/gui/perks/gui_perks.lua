---@class (exact) LS_Gui
local pg = {}

function pg:PerksDrawStats()

end

---Draws stats and perks window
function pg:PerksDrawWindow()
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
	self.menu.pos_y = self.menu.pos_y + 12
	self:FakeScrollBox(self.menu.pos_x - 3, self.menu.pos_y + 7, self.z + 5, self.c.default_9piece, 3, 3, self
		.FungalDraw)
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