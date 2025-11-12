---@class (exact) LS_Gui
local pg = {}

---Draws stats for perks
---@private
function pg:PerksDrawStats()
	local perks_lottery = self.perks.data:get_data("PERKS_LOTTERY")

	if self.perks.total_amount > 0 then
		local text = string.format(T.Perks .. ": %d", self.perks.total_amount)
		self:Text(self.perk.x, self.perk.y, text)
		local offset = self:GetTextDimension(text)
		self.perk.x = self.perk.x + offset + 4
	end

	if self.perk.reroll_count > 0 then
		local text = tostring(self.perk.reroll_count)
		local offset = self:GetTextDimension(text)
		self:Image(self.perk.x, self.perk.y - 2.5, "mods/lamas_stats/files/gfx/reroll_machine.png", 1, 1)
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
end

---Adds clickable button
---@private
---@param text string
---@param fn function
function pg:PerksAddButton(text, fn)
	if self.perk.current_window == fn then
		self:DrawButton(self.perk.x, self.perk.y, self.z - 1, text, false, "mods/lamas_stats/files/gfx/ui_9piece_button_alt.png")
		if self:IsHovered() and self:IsLeftClicked() then self.perk.current_window = nil end
	else
		self:DrawButton(
			self.perk.x,
			self.perk.y,
			self.z - 1,
			text,
			true,
			"mods/lamas_stats/files/gfx/ui_9piece_button_alt.png",
			"mods/lamas_stats/files/gfx/ui_9piece_button_alt_highlight.png"
		)
		if self:IsHovered() and self:IsLeftClicked() then
			self:ScrollBoxReset()
			self:CheckForUpdates(-1)
			self.perk.current_window = fn
		end
	end
	self.perk.x = self.perk.x + self:GetTextDimension(text) + 9
end

return pg
