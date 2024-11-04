--- @class (exact) LS_Gui
local pg = {}

--- Perks tooltip
--- @private
--- @param perk perk_data
function pg:PerksCurrentPerkTooltip(perk)
	local ui_name = self:Locale(perk.ui_name)
	local description_lines = self:SplitString(self:Locale(perk.ui_description), 200)
	local picked_count = T.PerkCount .. ": " .. perk.picked_count
	local id = self.alt and string.format("(%s)", perk.id) or ""
	local reminder = self.alt and "" or T.PressShiftToSeeMore
	local longest = self:GetLongestText({ ui_name, id, reminder }, perk.id .. id)
	longest = math.max(longest, self:GetLongestText(description_lines, perk.ui_description))
	local name_pos = (longest - self:GetTextDimension(ui_name)) / 2
	self:AddOptionForNext(self.c.options.Layout_NextSameLine)
	self:Image(name_pos - 6, 0, perk.perk_icon, 1, 0.625)
	self:Text(name_pos + 6, 0, ui_name)
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
	else
		self:ColorGray()
		self:TextCentered(0, 5, T.PressShiftToSeeMore, longest)
	end
end

--- Draws perk icon
--- @private
--- @param perk_id string
function pg:PerksDrawCurrentPerk(perk_id)
	local perk = self.perks.data:GetData(perk_id)
	if perk.picked_count < 1 then return end
	if self.perk.x > self.scroll.width then
		self.perk.x = 0
		self.perk.y = self.perk.y + 17
	end
	local hovered = self:PerksIsHoverBoxHovered(self.perk.x, self.perk.y)
	self:PerksDrawPerk(self.perk.x, self.perk.y, hovered, perk, self.PerksCurrentPerkTooltip, perk, self.alt)
	self.perk.x = self.perk.x + 17
end

--- Draws current perks
--- @private
function pg:PerksDrawCurrentPerks()
	self.perk.x = 0
	self.perk.y = 0
	for i = 1, #self.perks.data.list do
		self:PerksDrawCurrentPerk(self.perks.data.list[i])
	end
	self:Text(self.perk.x, self.perk.y + 16, "")
end

function pg:PerksDrawCurrentPerkScrollBox()
	self:ScrollBox(self.menu.start_x - 3, self.perk.scrollbox_start, self.z + 5, self.c.default_9piece, 3, 3, self.PerksDrawCurrentPerks)
end

return pg
