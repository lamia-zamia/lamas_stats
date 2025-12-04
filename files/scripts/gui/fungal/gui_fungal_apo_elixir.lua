---@class (exact) LS_Gui
local apo_elixir = {}

---Draws an ap or lc recipe
---@private
function apo_elixir:FungalApoElixirTooltipDrawRecipe()
	local x, y = 0, 0
	self:FungalDrawSingleMaterial(x, y, self.fs.apo_elixir.result)
	y = y + 11
	x = x + 6
	self:FungalDrawSingleMaterial(x, y, self.fs.apo_elixir.mats[1], self.alt)
	y = y + 10
	self:ColorGray()
	self:Text(x + 1, y, "+")
	self:FungalDrawSingleMaterial(x + 7, y, self.fs.apo_elixir.mats[2], self.alt)
	local offset = self:FungalGetMaterialNameLength(self.fs.apo_elixir.mats[2], self.alt)
	self:ColorGray()
	self:Text(x + offset + 13, y, string.format("(%d%%)", self.fs.apo_elixir.prob))
	y = y + 10
	self:FungalDrawSingleMaterial(x, y, self.fs.apo_elixir.mats[3], self.alt)
end

---Tooltip for aplc
---@private
function apo_elixir:FungalApoElixirTooltip()
	self:AddOption(self.c.options.Layout_NextSameLine)
	self:FungalApoElixirTooltipDrawRecipe()
	if not self.alt then
		self:ColorGray()
		self:Text(0, 45, T.PressShiftToSeeMore)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

---Draws aplc flasks
---@private
---@param x number
---@param y number
function apo_elixir:FungalApoElixirDraw(x, y)
	local elixir = self.mat:get_data(self.fs.apo_elixir.result)
	self:FungalDrawIcon(x, y, elixir)
	self:AddOptionForNext(self.c.options.ForceFocusable)
	self:Draw9Piece(x, y + 1, self.z + 5, 7, 8, self.buttons.img, self.buttons.img_hl)
	if self:IsHovered() then self:MenuTooltip("mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png", self.FungalApoElixirTooltip) end
end

return apo_elixir
