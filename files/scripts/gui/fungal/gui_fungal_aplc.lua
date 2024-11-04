--- @class (exact) LS_Gui
local aplc = {}

--- Draws an ap or lc recipe
--- @private
--- @param x number
--- @param y number
--- @param recipe APLC_recipe
function aplc:FungalApLcTooltipDrawRecipe(x, y, recipe)
	self:FungalDrawSingleMaterial(x, y, recipe.result)
	y = y + 11
	x = x + 6
	self:FungalDrawSingleMaterial(x, y, recipe.mats[1], self.alt)
	y = y + 10
	self:ColorGray()
	self:Text(x + 1, y, "+")
	self:FungalDrawSingleMaterial(x + 7, y, recipe.mats[2], self.alt)
	local offset = self:FungalGetMaterialNameLength(recipe.mats[2], self.alt)
	self:ColorGray()
	self:Text(x + offset + 13, y, string.format("(%d%%)", recipe.prob))
	y = y + 10
	self:FungalDrawSingleMaterial(x, y, recipe.mats[3], self.alt)
end

--- Tooltip for aplc
--- @private
function aplc:FungalApLcTooltip()
	self:AddOption(self.c.options.Layout_NextSameLine)
	self:FungalApLcTooltipDrawRecipe(0, 0, self.fs.aplc.ap)
	self:FungalApLcTooltipDrawRecipe(0, 45, self.fs.aplc.lc)
	if not self.alt then
		self:ColorGray()
		self:Text(0, 90, T.PressShiftToSeeMore)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

--- Draws aplc flasks
--- @private
--- @param x number
--- @param y number
function aplc:FungalApLcDraw(x, y)
	self:FungalDrawIcon(x, y, self.fs.aplc.ap.result)
	self:FungalDrawIcon(x + 9, y, self.fs.aplc.lc.result)
	self:AddOptionForNext(self.c.options.ForceFocusable)
	self:Draw9Piece(x, y + 1, self.z + 5, 16, 8, self.buttons.img, self.buttons.img_hl)
	if self:IsHovered() then self:MenuTooltip("mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png", self.FungalApLcTooltip) end
end

return aplc
