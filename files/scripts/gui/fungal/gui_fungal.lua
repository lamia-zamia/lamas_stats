---@class (exact) LS_Gui_fungal
---@field past boolean
---@field future boolean
---@field row_count integer  current shift row count (centering math uses this; set per-draw)
---@field offset LS_Gui_fungal_offset
---@field content_w number  scrollbox / hover width (set each frame by fungal_draw_window)
---@field tip_x number      screen x for fungal tooltips (right of window)
---@field tip_y number      screen y for fungal tooltips (level with menu header)
---@field shift_fmt string  format string for shift labels; cached to avoid per-row concat

---@class (exact) LS_Gui_fungal_offset
---@field shift number  shift-number text width
---@field from number   widest from-column across all shifts
---@field to number     widest to-column across all shifts
---@field held number   "held material" text width

---@class (exact) LS_Gui
---@field private fungal LS_Gui_fungal
local fg = {
	fungal = { ---@diagnostic disable-line: missing-fields
		past = false,
		future = true,
		row_count = 1,
		offset = {}, ---@diagnostic disable-line: missing-fields
		content_w = 0,
		tip_x = 0,
		tip_y = 0,
		shift_fmt = "",
	},
}

local ARROW_WIDTH = 12
local TOOLTIP_SPRITE = "mods/lamas_stats/files/gfx/ui_9piece_tooltip.png"
local ARROW_SPRITE = "mods/lamas_stats/files/gfx/arrow.png"
local HELD_SPRITE = "mods/lamas_stats/files/gfx/held_material.png"

local modules = {
	"mods/lamas_stats/files/scripts/gui/fungal/gui_fungal_tooltips.lua",
}
for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		fg[k] = v
	end
end

---Tooltip anchor: right of the window, level with the menu header.
---@private
---@return number x, number y
function fg:fungal_tip_anchor()
	return self.fungal.tip_x, self.fungal.tip_y
end

---Shift label, e.g. "Shift 03".
---@private
---@param i integer
---@return string
function fg:fungal_shift_label(i)
	return string.format(self.fungal.shift_fmt, i)
end

---Vertical centering offset for a column with count items.
---@private
---@param count integer
---@return number
function fg:fungal_get_shift_window_offset(count)
	return (self.fungal.row_count - count) * 5
end

---Removes duplicate static entries so the from-column doesn't list the same base material twice.
---@private
---@param from integer[]
---@return integer[]
function fg:fungal_sanitize_from_shifts(from)
	if not from or #from == 1 then return from end
	local arr = {}
	for i = 1, #from do
		local data = self.mat:get_data(from[i])
		if not data.static then arr[#arr + 1] = from[i] end
	end
	return #arr >= 1 and arr or from
end

---Total row count for one shift entry.
---@private
---@param from integer[]
---@param to integer
---@param flask string|false
---@return integer
function fg:fungal_calculate_row_count(from, to, flask)
	local rows = from and math.max(#from, 1) or 1
	if from and flask == "from" then
		rows = rows + 1
	elseif rows == 1 and flask == "to" and to then
		rows = 2
	end
	return rows
end

---Pixel width of one material entry (icon + name [+ id if draw_id]).
---@private
---@param material integer
---@param draw_id boolean?
---@return number
function fg:fungal_get_material_name_length(material, draw_id)
	local mat = self.mat:get_data(material)
	local id_w = draw_id and (3 + self:get_text_dim("(" .. mat.id .. ")")) or 0
	return self:get_text_dim(self:get_material_name(mat)) + 10 + id_w
end

---@private
---@param material_types integer[]
---@param max number
---@param draw_id boolean?
---@return number
function fg:fungal_get_longest_material_name(material_types, max, draw_id)
	for i = 1, #material_types do
		max = math.max(max, self:fungal_get_material_name_length(material_types[i], draw_id))
	end
	return max
end

---@private
---@param shift shift|failed_shift
---@param max_from number
---@param max_to number
---@param ignore_flask boolean?
---@param draw_id boolean?
---@return number from, number to
function fg:fungal_get_longest_text_in_shift(shift, max_from, max_to, ignore_flask, draw_id)
	if not shift then return max_from, max_to end
	if shift.flask and not ignore_flask then
		if shift.flask == "to" then
			max_to = math.max(self.fungal.offset.held + 10, max_to)
		else
			max_from = math.max(self.fungal.offset.held + 10, max_from)
		end
	end
	if shift.to then max_to = math.max(max_to, self:fungal_get_material_name_length(shift.to, draw_id)) end
	if shift.from then max_from = self:fungal_get_longest_material_name(shift.from, max_from, draw_id) end
	return max_from, max_to
end

---Recomputes from/to column widths by scanning all shifts.
---@private
function fg:fungal_set_fungal_list_offset()
	local max_from, max_to = 0, 0
	for i = 1, self.fs.current_shift - 1 do
		max_from, max_to = self:fungal_get_longest_text_in_shift(self.fs.past_shifts[i], max_from, max_to)
	end
	for i = self.fs.current_shift, self.fs.max_shifts do
		max_from, max_to = self:fungal_get_longest_text_in_shift(self.fs.predictor.shifts[i], max_from, max_to)
	end
	self.fungal.offset.from = max_from
	self.fungal.offset.to = max_to
end

---Handles shift number change: re-analyses past shifts and recalculates column widths.
---@private
function fg:fungal_shift_list_changed()
	self.fs:AnalysePastShifts()
	self:fungal_set_fungal_list_offset()
end

---Recalculates text-width offsets on language change.
---@private
function fg:fungal_update_window_dims()
	self.fungal.shift_fmt = T.lamas_stats_shift .. " %02d"
	self.fungal.offset.shift = self:get_text_dim(T.lamas_stats_shift .. "000")
	self.fungal.offset.held = self:get_text_dim(T.HeldMaterial)
	self:fungal_set_fungal_list_offset()
end

---@param did_language_changed boolean
function fg:fungal_get_settings(did_language_changed)
	if did_language_changed then
		self:fungal_update_window_dims()
		self:clear_material_name_cache()
	end
end

---Draws the "held material" placeholder in DIR_H context without an outer begin_row.
---@private
---@param tint number[]?  {r,g,b}
function fg:fungal_held_material_inline_content(tint)
	self:image(HELD_SPRITE, { dy = 1 })
	self:spacing(1)
	if tint then self:color(tint[1], tint[2], tint[3]) end
	self:text(T.HeldMaterial)
end

---Held material row (begin_column context).
---@private
---@param tint number[]?
function fg:fungal_held_material_row(tint)
	self:begin_row(function()
		self:fungal_held_material_inline_content(tint)
	end)
end

---From-materials column, vertically centered within row_count rows.
---@private
---@param from integer[]|nil
---@param flask_from boolean|string
---@param draw_id boolean?
function fg:fungal_from_materials_column(from, flask_from, draw_id)
	self:begin_column(function()
		if not from then
			self:spacing(self:fungal_get_shift_window_offset(1))
			self:fungal_held_material_row({ 0.8, 0, 0 })
		else
			local count = #from + (flask_from and 1 or 0)
			self:spacing(self:fungal_get_shift_window_offset(count))
			if flask_from then self:fungal_held_material_row() end
			for j = 1, #from do
				self:material_row(from[j], draw_id)
			end
		end
	end)
end

---To-material column, vertically centered within row_count rows.
---@private
---@param to integer|nil
---@param flask_to boolean|string
---@param draw_id boolean?
function fg:fungal_to_materials_column(to, flask_to, draw_id)
	self:begin_column(function()
		if not to then
			self:spacing(self:fungal_get_shift_window_offset(1))
			self:fungal_held_material_row({ 0.8, 0, 0 })
		else
			local to_rows = flask_to and 2 or 1
			self:spacing(self:fungal_get_shift_window_offset(to_rows))
			if flask_to then self:fungal_held_material_row() end
			self:material_row(to, draw_id)
		end
	end)
end

---Arrow column, vertically centered within row_count rows.
---@private
function fg:fungal_arrow_column()
	self:begin_column(function()
		self:spacing(self:fungal_get_shift_window_offset(1))
		self:image(ARROW_SPRITE)
	end)
end

---Sets the colored background for one shift row. Applies the color; the caller draws the image.
---@private
---@param hovered boolean
---@param i integer
---@param is_past boolean
---@param greedy greedy_shift?
function fg:fungal_decide_row_color(hovered, i, is_past, greedy)
	if is_past then
		if hovered then
			self:color(0.2, 0.6, 0.7)
		else
			local c = i % 2 == 0 and 0.4 or 0.6
			self:color(c, c, c)
		end
		return
	end
	-- Future shift color: greedy success overrides all
	if greedy and greedy.success then
		self:color(hovered and 1 or 1, hovered and 0.5 or 0, 1)
		return
	end
	local is_current = i == self.fs.current_shift
	if hovered then
		self:color(is_current and 0.4 or 0.2, is_current and 1 or 0.6, is_current and 0.5 or 0.7)
	elseif is_current then
		self:color(0.6, 1, 0.1)
	else
		local c = i % 2 == 0 and 0.4 or 0.6
		self:color(c, c, c)
	end
end

---Fixed-width column leaves keep all arrows and to-materials on the same x axis across rows.
---@private
---@param i integer
---@param shift shift
---@param is_past boolean
function fg:fungal_draw_shift_row(i, shift, is_past)
	local from = self:fungal_sanitize_from_shifts(shift.from)
	local flask = not is_past and shift.flask

	-- row_count drives both the row height and the vertical centering inside each column
	self.fungal.row_count = self:fungal_calculate_row_count(from, shift.to, shift.flask)
	local row_h = self.fungal.row_count * 11
	local content_w = self.fungal.content_w
	local hovered = self:is_hovered_cursor(content_w, row_h)

	-- Past rows get an extra dark underlay so the alternating stripe reads on any background.
	if is_past and not hovered then
		self:overlay(function()
			self:color(0, 0, 0)
			self:set_z_for_next(self.z_index - 101)
			self:image(self.c.px, { alpha = 0.2, scale_x = content_w, scale_y = row_h })
		end)
	end
	self:overlay(function()
		self:fungal_decide_row_color(hovered, i, is_past, shift.greedy)
		self:set_z_for_next(self.z_index + 4)
		self:image(self.c.px, { alpha = 0.2, scale_x = content_w, scale_y = row_h })
	end)

	local off = self.fungal.offset
	self:begin_row(function()
		self:spacing(2)
		-- Shift number: fixed-width leaf so all from-columns start at the same x.
		self:leaf(off.shift, row_h, function()
			self:begin_column(function()
				self:spacing(self:fungal_get_shift_window_offset(1))
				self:text(self:fungal_shift_label(i))
			end)
		end)
		-- From: fixed-width leaf preserving the pre-computed max column width.
		self:leaf(off.from, row_h, function()
			self:fungal_from_materials_column(from, flask == "from", false)
		end)
		self:spacing(2)
		self:leaf(ARROW_WIDTH, row_h, function()
			self:fungal_arrow_column()
		end)
		self:leaf(off.to, row_h, function()
			self:fungal_to_materials_column(shift.to, flask == "to", false)
		end)
	end)

	-- Tooltip: opened only while hovered; numeric id avoids per-row string allocation.
	if hovered and self:tooltip(true, { id = i, sprite = TOOLTIP_SPRITE, border = 0 }) then
		if is_past then
			self:fungal_draw_past_tooltip(shift, i)
		else
			self:fungal_draw_future_tooltip(shift, i)
		end
		local ax, ay = self:fungal_tip_anchor()
		self:tooltip_end(ax, ay, false)
	end
end

---Draws the full past+future shift list inside the scrollbox.
---@private
function fg:fungal_draw_shift_list()
	if self.fungal.past and self.fs.current_shift > 1 then
		for i = 1, self.fs.current_shift - 1 do
			local shift = self.fs.past_shifts[i]
			if not shift then return end
			self:fungal_draw_shift_row(i, shift, true)
		end
	end
	if self.fungal.future and self.fs.current_shift <= self.fs.max_shifts then
		for i = self.fs.current_shift, self.fs.max_shifts do
			local shift = self.fs.predictor.shifts[i]
			if not shift then return end
			self:fungal_draw_shift_row(i, shift, false)
		end
	end
end

---Draws the fungal panel (header + shift-list scrollbox).
function fg:fungal_draw_window()
	local m = self.menu
	local off = self.fungal.offset

	local min_shift_w = 2 + off.shift + off.from + 2 + ARROW_WIDTH + off.to + self.options.window_padding * 2 + self.options.scrollbar_width + 2
	local min_w = m._just_switched and min_shift_w or math.max(m.shared_width, min_shift_w)

	local header_width, header_h = self:window(function()
		self:begin_row(function()
			local past_clicked = self:checkbox(T.EnableFungalPast, self.fungal.past)
			if past_clicked then
				self.fungal.past = not self.fungal.past
				self.mod:SetModSetting("enable_fungal_past", self.fungal.past)
			end
			self:spacing(2)
			local future_clicked = self:checkbox(T.EnableFungalFuture, self.fungal.future)
			if future_clicked then
				self.fungal.future = not self.fungal.future
				self.mod:SetModSetting("enable_fungal_future", self.fungal.future)
			end
		end)
	end, { id = "fungal_header", min_width = min_w })

	self.fungal.tip_x = m.start_x + header_width + 2
	self.fungal.tip_y = m.start_y - 1

	-- Scrollbox cap: max_height is the total budget for the whole panel (header + list).
	-- Subtract the header window height so all panels bottom-align at the same screen y.
	local scrollbox_cap = math.max(20, self.max_height - header_h + 1)
	local min_shift_content = min_shift_w - self.options.window_padding * 2

	-- Scrollbox window: self-sizes to last frame's content height (one-frame lag,
	-- but shift-list height is stable per frame so the lag is invisible).
	self:window_join()
	self:window(function()
		-- fill_width() = 0 during the group's natural-width pass, so the group
		-- accumulates the true minimum column width rather than locking to the
		-- previous panel's inflated width.
		local inner_w = math.max(min_shift_content, self:fill_width())
		self.fungal.content_w = inner_w
		self:begin_scrollbox("fungal_shifts", inner_w, scrollbox_cap, function()
			self:fungal_draw_shift_list()
		end)
	end, { id = "fungal_window", min_width = header_width })

	-- Ensure the menu bar is always at least as wide as the shift-list columns.
	-- window_group handles header/body width sharing, but the menu bar tab strip is
	-- a separate group; feed min_shift_w explicitly so the tab is wide enough.
	self:menu_feed_width(min_shift_w)
end

---Loads saved checkbox states.
function fg:fungal_init()
	self.fungal.past = self.mod:GetSettingBoolean("enable_fungal_past")
	self.fungal.future = self.mod:GetSettingBoolean("enable_fungal_future")
end

return fg
