---@alias material_colors {r:number, g:number, b:number, a:number}

---@class colors
local colors = {}

---Split abgr
---@param abgr_int integer
---@return number red, number green, number blue, number alpha
function colors.abgr_split(abgr_int)
	local r = bit.band(abgr_int, 0xFF)
	local g = bit.band(bit.rshift(abgr_int, 8), 0xFF)
	local b = bit.band(bit.rshift(abgr_int, 16), 0xFF)
	local a = bit.band(bit.rshift(abgr_int, 24), 0xFF)

	return r, g, b, a
end

---Merge rgb
---@param r number
---@param g number
---@param b number
---@param a number
---@return integer color
function colors.abgr_merge(r, g, b, a)
	return bit.bor(bit.band(r, 0xFF), bit.lshift(bit.band(g, 0xFF), 8), bit.lshift(bit.band(b, 0xFF), 16), bit.lshift(bit.band(a, 0xFF), 24))
end

---Converts string abgr to rgba
---@param color string
---@return material_colors
function colors.abgr_to_rgb(color)
	local b, g, r, a = colors.abgr_split(tonumber(color, 16))
	return { r = r / 255, g = g / 255, b = b / 255, a = a / 255 }
end

---Normalize colors
---@param color1 integer
---@param color2 integer
---@return integer
function colors.multiply(color1, color2)
	local s_r, s_g, s_b, s_a = colors.abgr_split(color1)
	local d_r, d_g, d_b, d_a = colors.abgr_split(color2)
	return colors.abgr_merge(s_r * d_r / 255, s_g * d_g / 255, s_b * d_b / 255, s_a * d_a / 255)
end

return colors
