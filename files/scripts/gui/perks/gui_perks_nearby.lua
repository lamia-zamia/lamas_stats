---@class (exact) LS_Gui
local pg = {}

---Perks tooltip
---@private
---@param nearby_perk nearby_perks_data
function pg:PerksNearbyTooltip(nearby_perk)
	local perk = self.perks.data:get_data(nearby_perk.id)
	local ui_name = self:Locale(perk.ui_name)
	local description_lines = self:SplitString(self:Locale(perk.ui_description), 200)
	local picked_count = T.PerkCount .. ": " .. perk.picked_count
	local id = self.alt and string.format("(%s)", perk.id) or ""
	local reminder = self.alt and "" or T.PressShiftToSeeMore
	local always_cast = nearby_perk.cast and T.lamas_stats_perks_always_cast .. ":" or ""
	local longest = self:GetLongestText({ ui_name, id, reminder, always_cast }, perk.id .. id)
	longest = math.max(longest, self:GetLongestText(description_lines, perk.ui_description))
	local name_pos = (longest - self:GetTextDimension(ui_name)) / 2
	self:AddOptionForNext(self.c.options.Layout_NextSameLine)
	self:Image(name_pos - 6, 0, perk.perk_icon, 1, 0.625)
	self:Text(name_pos + 6, 0, ui_name)
	if nearby_perk.lottery and self.config.enable_nearby_lottery then
		self:Color(0.58, 0.85, 0.88)
		self:TextCentered(0, 0, "[" .. T.LotteryWin .. "]", longest)
	end
	if self.alt then
		self:ColorGray()
		self:TextCentered(0, 0, id, longest)
	end
	for i = 1, #description_lines do
		self:Color(0.8, 0.8, 0.8)
		self:TextCentered(0, 0, description_lines[i], longest)
	end

	if nearby_perk.cast and self.config.enable_nearby_always_cast then
		local cast_length = self:GetTextDimension(always_cast)
		local cast_pos = (longest - cast_length) / 2 - 6
		local cast_data = self.actions:get_data(nearby_perk.cast)
		self:AddOptionForNext(self.c.options.Layout_NextSameLine)
		self:Text(cast_pos, 3, always_cast)
		self:Image(cast_pos + cast_length + 3, 3, cast_data.sprite, 1, 0.625)
		if self.alt then
			self:TextCentered(0, 5, self:Locale(cast_data.name), longest)
			self:ColorGray()
			self:TextCentered(0, 0, "(" .. nearby_perk.cast .. ")", longest)
			local cast_description = self:SplitString(self:Locale(cast_data.description), longest)
			for i = 1, #cast_description do
				self:Color(0.8, 0.8, 0.8)
				self:TextCentered(0, 0, cast_description[i], longest)
			end
		end
	end

	if self.alt then
		self:TextCentered(0, 5, picked_count, longest)
		self:ColorGray()
		self:TextCentered(0, 0, T.Max .. ": " .. perk.max, longest)
	end

	if not self.alt then
		self:ColorGray()
		self:TextCentered(0, 5, T.PressShiftToSeeMore, longest)
	end
end

---Draws nearby perks
---@private
function pg:PerksDrawNearby()
	local x = self.menu.start_x - 3
	for i = 1, #self.perks.nearby.data do
		if x > self.menu.width then
			x = self.menu.start_x - 3
			self.perk.y = self.perk.y + 17
		end
		local nearby_perk = self.perks.nearby.data[i] ---@type nearby_perks_data
		local perk_data = self.perks.data:get_data(nearby_perk.id)
		local hovered = self:IsHoverBoxHovered(x, self.perk.y, 16, 16)
		self:PerksDrawPerk(x, self.perk.y, hovered, perk_data, self.PerksNearbyTooltip, nearby_perk, self.alt)
		if nearby_perk.lottery then
			self:SetZ(self.z - 50)
			self:Image(x, self.perk.y, "mods/lamas_stats/files/gfx/lottery_glow.png", 1, 1)
		end
		x = x + 17
	end
end

return pg
