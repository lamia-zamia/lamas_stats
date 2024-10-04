local ui_lib = dofile_once("mods/lamas_stats/files/lib/ui_lib.lua") ---@type UI_class
local bar = ui_lib:New() ---@class bar:UI_class

local data = {
	x = 200,
	y = 200,
	width = 60,
	height = 8,
	z = -100
}
bar.data = data

--  ####################### bar #######################


---Bar background color
---@private
function bar:BarColorBackground()
	self:Color(0.5, 0.5, 0.5)
end

---Bar color
---@private
function bar:BarColor()
	self:Color(1, 0.6, 0.6)
end

---Draw the background of the bar
---@private
---@param x number
---@param y number
---@param scale_x number
---@param scale_y number
function bar:DrawBackGround(x, y, scale_x, scale_y)
	self:SetZ(self.data.z + 3)
	self:BarColorBackground()
	self:Image(x, y, self.c.px, 0.85, scale_x, scale_y)
end

---Draw the experience filler
---@private
---@param x number
---@param y number
---@param scale_x number
---@param scale_y number
function bar:DrawFiller(x, y, scale_x, scale_y)
	local multiplier = 0.6 --- Filled percentage, from 0 to 1
	self:SetZ(self.data.z + 1)
	self:BarColor()
	self:Image(x, y, self.c.px, 1, scale_x * multiplier, scale_y)
end

---Draw border around the bar
---@private
---@param x number
---@param y number
---@param scale_x number
---@param scale_y number
function bar:DrawBorder(x, y, scale_x, scale_y)
	self:SetZ(self.data.z + 2)
	self:Color(0.4752, 0.2768, 0.2215)
	self:Image(x, y, self.c.px, 0.85, scale_x, scale_y)
end

function bar:BarTooltip()
	self:Text(0, 0, "this is a tooltip")
	self:Image(0, 0, "data/items_gfx/potion.png")
	self:Color(1, 0, 1)
	self:Image(0, 0, "data/items_gfx/potion.png")
end

---Draw horizontal bar
---@private
function bar:DrawBar()
	self:DrawBorder(self.data.x, self.data.y - 1, self.data.width + 0.25, 1)                       --top
	self:DrawBorder(self.data.x, self.data.y, 1, 1 + self.data.height)                            --left
	self:DrawBorder(self.data.x, self.data.y + self.data.height, self.data.width + 0.25, 1)      --bottom
	self:DrawBorder(self.data.x + self.data.width - 0.75, self.data.y - 1, 1, 2 + self.data.height) --right

	self:DrawBackGround(self.data.x + 1, self.data.y, self.data.width - 1.75, self.data.height)
	self:DrawFiller(self.data.x + 1, self.data.y, self.data.width - 1.75, self.data.height)
	if self:IsHoverBoxHovered(self.data.x, self.data.y, self.data.width, self.data.height, true) then
		local cache = self:GetTooltipData(0, 0, self.BarTooltip)
		self:ShowTooltip(self.data.x - cache.width, self.data.y, self.BarTooltip)
	end
end

function bar:loop()
	self:StartFrame()

	if false then return end -- add some checks to not draw a bar (when there's no player entity or whatever)

	GuiZSet(self.gui, self.data.z)
	self:AddOption(self.c.options.NonInteractive)
	self:DrawBar()
end

return bar