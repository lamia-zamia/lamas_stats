---@class textbox
---@field gui gui
---@field selection_start integer?
---@field selection_end integer?
local textbox = {
	controls_disabled = false,
	inputting = false,
	held_key = nil,
	next_repeat_time = 0,
	caret_force_visible_until = 0,
	selection_start = nil,
	selection_end = nil,
}

local img = "mods/lamas_stats/files/gfx/ui_9piece_scrollbar.png"
local img_hl = "mods/lamas_stats/files/gfx/ui_9piece_textbox.png"
local caret = "mods/lamas_stats/files/gfx/caret.png"
local max_chars = 15

local keycodes = {
	backspace = 42,
	mouse_left = 1,
	enter = 88,
	return_key = 40,
	left = 80,
	right = 79,
	delete = 76,
	shift_l = 225,
	shift_r = 229,
	ctrl_l = 224,
	ctrl_r = 228,
	a = 4,
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

---Clears selection
---@private
function textbox:clear_selection()
	self.selection_start = nil
	self.selection_end = nil
end

---Deletes selected
---@private
---@param text string
---@return string
function textbox:delete_selection(text)
	local selection_start, selection_end = self.selection_start, self.selection_end
	if not selection_start or not selection_end then return text end

	local s = math.min(selection_start, selection_end)
	local e = math.max(selection_start, selection_end)

	text = text:sub(1, s - 1) .. text:sub(e)

	self.cursor_pos = s
	self:clear_selection()
	return text
end

---Moves cursor
---@param new_pos integer
---@param shift_held boolean
function textbox:apply_selection_movement(new_pos, shift_held)
	if shift_held then
		self.selection_start = self.selection_start or self.cursor_pos
		self.selection_end = new_pos
	else
		self:clear_selection()
	end
	self.cursor_pos = new_pos
end

---Processes key presses
---@private
---@param text string
---@return string
function textbox:process_keys(text)
	if not self.inputting then return text end
	local now = GameGetFrameNum()

	-- selection: ctrl+a
	if InputIsKeyDown(keycodes.ctrl_l) or InputIsKeyDown(keycodes.ctrl_r) then -- ctrl keys
		if InputIsKeyJustDown(keycodes.a) then -- 'a'
			self.selection_start = 1
			self.selection_end = #text + 1
			self.cursor_pos = self.selection_end
			self.caret_force_visible_until = now + 30
			return text
		end
	end

	-- shift + left/right selection
	local shift = InputIsKeyDown(keycodes.shift_l) or InputIsKeyDown(keycodes.shift_r) -- both shift keys

	if self:key_repeat(now, keycodes.left) then
		local new_pos = math.max(1, self.cursor_pos - 1)
		self:apply_selection_movement(new_pos, shift)
		self.caret_force_visible_until = now + 30
		return text
	end

	if self:key_repeat(now, keycodes.right) then
		local new_pos = math.min(#text + 1, self.cursor_pos + 1)
		self:apply_selection_movement(new_pos, shift)
		self.caret_force_visible_until = now + 30
		return text
	end

	-- backspace
	if self:key_repeat(now, keycodes.backspace) then
		if self.selection_start then return self:delete_selection(text) end
		if #text > 0 and self.cursor_pos > 1 then
			text = text:sub(1, self.cursor_pos - 2) .. text:sub(self.cursor_pos)
			self.cursor_pos = math.max(1, self.cursor_pos - 1)
		end
		return text
	end

	-- delete key (delete the symbol under the cursor)
	if self:key_repeat(now, keycodes.delete) then
		if self.selection_start then return self:delete_selection(text) end
		if self.cursor_pos <= #text then text = text:sub(1, self.cursor_pos - 1) .. text:sub(self.cursor_pos + 1) end
		return text
	end

	-- normal character input
	for key, value in pairs(keycodes_lookup) do
		if self:key_repeat(now, key) then
			if self.selection_start then text = self:delete_selection(text) end
			local before = text:sub(1, self.cursor_pos - 1)
			local after = text:sub(self.cursor_pos)
			text = before .. value .. after
			self.cursor_pos = self.cursor_pos + 1
			return text
		end
	end

	return text
end

function textbox:draw_selection(x, y, z, text)
	if not self.selection_start or not self.selection_end then return end

	local s = math.min(self.selection_start, self.selection_end)
	local e = math.max(self.selection_start, self.selection_end)
	if s == e then return end

	local before = text:sub(1, s - 1)
	local selected = text:sub(s, e - 1)

	local before_w = GuiGetTextDimensions(self.gui, before)
	local selected_w = GuiGetTextDimensions(self.gui, selected)

	GuiZSetForNextWidget(self.gui, z + 1)
	GuiColorSetForNextWidget(self.gui, 0.3, 0.3, 1.0, 1)

	GuiImage(self.gui, 100, x + before_w, y, "mods/lamas_stats/vfs/white.png", 0.8, selected_w, 10)
end

---@param x number
---@param y number
---@param z number
---@param width number
---@param height number
---@param text string
---@return string
function textbox:draw_textbox(x, y, z, width, height, text)
	GuiZSetForNextWidget(self.gui, z + 2)
	GuiImageNinePiece(self.gui, 100, x, y, width, height, 1, self.inputting and img_hl or img)
	local _, _, hovered = GuiGetPreviousWidgetInfo(self.gui)
	local clicked = InputIsMouseButtonJustDown(keycodes.mouse_left)

	if hovered and clicked then
		self.inputting = true
		if not self.cursor_pos then self.cursor_pos = #text + 1 end
	end

	self:draw_selection(x, y, z, text)

	GuiZSetForNextWidget(self.gui, z)
	GuiText(self.gui, x, y, text)

	if not self.inputting then return text end

	local frame = GameGetFrameNum()
	local caret_visible = frame < self.caret_force_visible_until or ((math.floor(frame / 30)) % 2) == 0
	if caret_visible then
		local caret_pos = GuiGetTextDimensions(self.gui, text:sub(1, self.cursor_pos - 1)) - 1
		caret_pos = math.max(0, caret_pos - 1)
		GuiImage(self.gui, 100, x + caret_pos + 1, y, caret, 0.6, 1)
	end

	self:disable_controls()

	if (not hovered and clicked) or InputIsKeyJustDown(keycodes.enter) or InputIsKeyJustDown(keycodes.return_key) then
		self.inputting = false
		self:enable_controls()
		return text
	end

	text = self:process_keys(text)
	if #text > max_chars then
		text = text:sub(1, math.min(#text, max_chars))
		self.cursor_pos = math.min(#text + 1, math.max(1, self.cursor_pos))
	end
	return text:sub(1, math.min(#text, max_chars))
end

return textbox
