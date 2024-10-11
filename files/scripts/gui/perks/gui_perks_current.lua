--- @class (exact) LS_Gui
local pg = {}

--- Perks tooltip
--- @private
--- @param perk perk_data
function pg:PerksCurrentPerkTooltip(perk)
	local ui_name = self:Locale(perk.ui_name)
	local description_lines = self:SplitString(self:Locale(perk.ui_description), 200)
	local picked_count = T.Count .. ": " .. perk.picked_count
	local id = string.format("(%s)", perk.id)
	local longest = #description_lines > 1 and 200 or
		self:GetLongestText({ ui_name, description_lines[1], self.alt and "" or T.PressShiftToSeeMore }, perk.id)

	local name_pos = (longest - self:GetTextDimension(ui_name)) / 2
	self:AddOptionForNext(self.c.options.Layout_NextSameLine)
	self:Image(name_pos - 12, 0, perk.perk_icon, 1, 0.625)
	self:Text(name_pos, 0, ui_name)
	if self.alt then
		self:ColorGray()
		self:TextCentered(0, 0, id, longest)
	end
	for i = 1, #description_lines do
		self:Color(0.8, 0.8, 0.8)
		self:TextCentered(0, 0, description_lines[i], longest)
	end

	self:TextCentered(0, 0, picked_count, longest)
	if self.alt then
		self:ColorGray()
		self:TextCentered(0, 0, T.Max .. ": " .. perk.max, longest)
	end

	if not self.alt then
		self:ColorGray()
		self:TextCentered(0, 0, T.PressShiftToSeeMore, longest)
	end
end

--- Draws perk icon
--- @private
--- @param perk_id string
function pg:PerksDrawCurrentPerk(perk_id)
	local perk = self.perks:GetData(perk_id)
	if perk.picked_count < 1 then return end
	if self.perk.x > 190 then
		self.perk.x = 0
		self.perk.y = self.perk.y + 17
	end
	local hovered = self:PerksIsHoverBoxHovered(self.perk.x, self.perk.y)
	local off = hovered and 1.2 or 0
	self:Image(self.perk.x - off, self.perk.y - off, perk.perk_icon, 1, hovered and 1.15 or 1)
	self.tooltip_reset = false
	if hovered then
		self.tooltip_img = "mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png"
		self:ShowTooltip(self.menu.start_x + self.scroll.width + 12, self.menu.start_y + 3, self.PerksCurrentPerkTooltip,
			perk)
		self.tooltip_img = self.default_tooltip
	end
	self.perk.x = self.perk.x + 17
end

--- Draws current perks
--- @private
function pg:PerksDrawCurrentPerks()
	for i = 1, #self.perks.data_list do
		self:PerksDrawCurrentPerk(self.perks.data_list[i])
	end
	self:Text(self.perk.x, self.perk.y + 16, "")
end

function pg:PerksDrawCurrentPerkScrollBox()
	self:ScrollBox(self.menu.pos_x - 3, self.menu.pos_y + 29, self.z + 5, self.c.default_9piece, 3, 3,
		self.PerksDrawCurrentPerks)
end

return pg
