---@class textbox
---@field gui gui
local textbox = {
	controls_disabled = false,
	inputting = false,
	held_key = nil,
	next_repeat_time = 0,
	caret_force_visible_until = 0,
}

local caret = "mods/lamas_stats/files/gfx/caret.png"

local keycodes = {
	backspace = 42,
	mouse_left = 1,
	enter = 88,
	left = 80,
	right = 79,
	delete = 76,
}

local keycodes_lookup = {
	[4] = "a",
	[5] = "b",
	[6] = "c",
	[7] = "d",
	[8] = "e",
	[9] = "f",
	[10] = "g",
	[11] = "h",
	[12] = "i",
	[13] = "j",
	[14] = "k",
	[15] = "l",
	[16] = "m",
	[17] = "n",
	[18] = "o",
	[19] = "p",
	[20] = "q",
	[21] = "r",
	[22] = "s",
	[23] = "t",
	[24] = "u",
	[25] = "v",
	[26] = "w",
	[27] = "x",
	[28] = "y",
	[29] = "z",
	[30] = "1",
	[31] = "2",
	[32] = "3",
	[33] = "4",
	[34] = "5",
	[35] = "6",
	[36] = "7",
	[37] = "8",
	[38] = "9",
	[39] = "0",
	[44] = " ",
}

local controls_comp_fields = {
	"mButtonDownLeft",
	"mButtonDownRight",
	"mButtonDownUp",
	"mButtonDownFly",
	"mButtonDownDown",
	"mButtonDownFire",
	"mButtonDownFire2",
	"mButtonDownThrow",
	"mButtonDownInteract",
}

local repeat_initial_delay = 20
local repeat_rate = 2

function textbox:enable_controls()
	local player = ENTITY_GET_WITH_TAG("player_unit")[1]
	if not player then return end
	local controls_component = EntityGetFirstComponent(player, "ControlsComponent")
	if not controls_component then return end
	ComponentSetValue2(controls_component, "enabled", true)
	self.controls_disabled = false
end

function textbox:disable_controls()
	local player = ENTITY_GET_WITH_TAG("player_unit")[1]
	if not player then return end
	local controls_component = EntityGetFirstComponent(player, "ControlsComponent")
	if not controls_component then return end
	ComponentSetValue2(controls_component, "enabled", false)
	for _, field in ipairs(controls_comp_fields) do
		ComponentSetValue2(controls_component, field, false)
	end
	self.controls_disabled = true
end

---function to check repeatable keys
---@private
---@param frame number
---@param key number
---@return boolean
function textbox:key_repeat(frame, key)
	local just_down = InputIsKeyJustDown(key)
	local held = InputIsKeyDown(key)

	if just_down then
		self.held_key = key
		self.next_repeat_time = frame + repeat_initial_delay
		return true
	elseif held and self.held_key == key and frame >= self.next_repeat_time then
		self.next_repeat_time = frame + repeat_rate
		return true
	elseif not held and self.held_key == key then
		self.held_key = nil
	end
	return false
end

---Processes key presses
---@private
---@param text string
---@return string
function textbox:process_keys(text)
	local now = GameGetFrameNum()

	-- backspace
	if self:key_repeat(now, keycodes.backspace) and #text > 0 and self.cursor_pos > 1 then
		text = text:sub(1, self.cursor_pos - 2) .. text:sub(self.cursor_pos)
		self.cursor_pos = math.max(1, self.cursor_pos - 1)
		return text
	end

	-- move cursor left
	if self:key_repeat(now, keycodes.left) then
		self.cursor_pos = math.max(1, self.cursor_pos - 1)
		self.caret_force_visible_until = now + 30
		return text
	end

	-- move cursor right
	if self:key_repeat(now, keycodes.right) then
		self.cursor_pos = math.min(#text + 1, self.cursor_pos + 1)
		self.caret_force_visible_until = now + 30
		return text
	end

	-- normal character input
	for key, value in pairs(keycodes_lookup) do
		if self:key_repeat(now, key) then
			local before = text:sub(1, self.cursor_pos - 1)
			local after = text:sub(self.cursor_pos)
			text = before .. value .. after
			self.cursor_pos = self.cursor_pos + 1
			return text
		end
	end

	-- delete key (delete the symbol under the cursor)
	if self:key_repeat(now, keycodes.delete) and self.cursor_pos <= #text then
		text = text:sub(1, self.cursor_pos - 1) .. text:sub(self.cursor_pos + 1)
		return text
	end

	return text
end

---@param x number
---@param y number
---@param z number
---@param width number
---@param height number
---@param text string
---@return string
function textbox:draw_textbox(x, y, z, width, height, text)
	GuiZSetForNextWidget(self.gui, z + 1)
	GuiImageNinePiece(self.gui, 100, x, y, width, height, 1)
	local _, _, hovered = GuiGetPreviousWidgetInfo(self.gui)
	local clicked = InputIsMouseButtonJustDown(keycodes.mouse_left)

	if hovered and clicked then
		self.inputting = true
		if not self.cursor_pos then self.cursor_pos = #text + 1 end
	end

	GuiZSetForNextWidget(self.gui, z)
	GuiText(self.gui, x, y, text)

	if not self.inputting then return text end

	local frame = GameGetFrameNum()
	local caret_visible = frame < self.caret_force_visible_until or ((math.floor(frame / 30)) % 2) == 0
	if caret_visible then
		local caret_pos = GuiGetTextDimensions(self.gui, text:sub(1, self.cursor_pos - 1)) - 1
		GuiImage(self.gui, 100, x + caret_pos, y, caret, 0.6, 1)
	end

	self:disable_controls()

	if (not hovered and clicked) or InputIsKeyJustDown(keycodes.enter) then
		self.inputting = false
		self:enable_controls()
		return text
	end

	return self:process_keys(text)
end

return textbox
