-- noita_gui: minimal GUI framework for Noita mods

---@alias cursor {x:number, y:number, line_w:number, line_h:number, dir:integer}
---@alias dimensions {w:number, h:number}
---@alias tooltip_cmd {kind:integer, x:number, y:number, width:number, height:number, text:string?, scale:number?, font:string?, sprite:string?, alpha:number?, scale_x:number?, scale_y:number?, z_index:integer?, color:number[]?}

---@class noita_gui_options
---@field text_font string
---@field text_scale number
---@field z_index integer
---@field ninepiece_sprite string
---@field ninepiece_sprite_hl string?
---@field tooltip_sprite string
---@field tooltip_border number outward expansion of the tooltip frame beyond content+margin (default 3)
---@field button_sprite string
---@field button_sprite_hl string
---@field scrollbar_width number width of a scrollbox's scrollbar
---@field scrollbar_track_sprite string? sprite for the bar's track/channel (nil = none)
---@field scrollbar_thumb_sprite string sprite for the draggable thumb
---@field scrollbar_thumb_sprite_hl string? sprite for the thumb when hovered or dragging
---@field scrollbar_min_thumb number minimum thumb height in px
---@field scroll_step number px the wheel scrolls a hovered scrollbox per notch
---@field window_padding number default inner padding of a window (opts.padding overrides)

---@class (exact) noita_gui
---@field private __index noita_gui?
---@field private gui gui
---@field private _tooltip_gui gui
---@field private gui_id integer
---@field private _tooltip_gui_id integer
---@field private cursor cursor
---@field private cursor_stack cursor[]
---@field options noita_gui_options
---@field mouse {x:number, y:number}
---@field dim {x:number, y:number}
---@field private _measure_depth integer
---@field private _scrolls {[string]: scrollbox_table}
---@field private _hovered_id_this_frame integer?
---@field private _hovered_id_last_frame integer?
---@field private _clip_stack dimensions[]
---@field private _clip_origin_x number screen-space x of innermost active clip container
---@field private _clip_origin_y number screen-space y of innermost active clip container
---@field private _clip_origin_stack {x:number, y:number}[]
---@field _scroll_y number current scroll offset, set by begin_scrollbox
---@field z_index integer
---@field OPT_NON_INTERACTIVE integer
---@field OPT_ALWAYS_CLICKABLE integer
---@field OPT_FORCE_FOCUSABLE integer
---@field OPT_SAME_LINE integer
---@field SCALE_FRAMES integer frames the scale-in lasts (windows/tooltips)
---@field ALPHA_FRAMES integer frames the fade-in lasts (windows/tooltips)
---@field SCALE_FROM number starting scale of the scale-in (1 = no scaling at all)
---@field ANIMATE boolean master switch for all animation (false = everything snaps instantly)
---@field TOOLTIP_MARGIN number padding between tooltip content and its frame
---@field TOOLTIP_Z integer z the tooltip is drawn at (very front)
---@field BUTTON_PAD number horizontal padding inside the example button
---@field MIN_TEXT_ALPHA number tiny nonzero floor so faded text doesn't pop opaque (Noita quirk)
---@field FADE_OUT_SPEEDUP number tooltip text fades out this many times faster than in
---@field RESIZE_SPEED number per-frame fraction a window frame eases toward a new size
---@field SCROLL_SPEED number per-frame fraction a scrollbox eases toward its target offset
---@field private _rec tooltip_cmd[]? active tooltip recording buffer (nil = not recording)
---@field private _rec_color number[]? pending color for the next recorded widget
---@field private _rec_id string|number? animation key for the tooltip being recorded
---@field private _rec_sframes integer? scale duration for the tooltip being recorded
---@field private _rec_aframes integer? alpha duration for the tooltip being recorded
---@field private _rec_sprite string? 9-piece sprite override for the tooltip being recorded
---@field private _rec_margin number? margin override for the tooltip being recorded
---@field private _rec_border number? border override for the tooltip being recorded
---@field private _tt_pending {cmds:tooltip_cmd[], ax:number, ay:number, center:boolean, id:string|number?, sframes:integer?, aframes:integer?, sprite:string?, margin:number?, border:number?}? tooltip queued for end-of-frame draw
---@field private _tt_active {key:string|number, cmds:tooltip_cmd[], ax:number, ay:number, center:boolean, sframes:integer, aframes:integer, scale_p:number, alpha_p:number, target:number, sprite:string?, margin:number?, border:number?}? tooltip currently animating in/out
---@field private _pending_color number[]? deferred color, applied by the next draw primitive
---@field private _draw_alpha number global alpha multiplier (for fade animations)
---@field private _anim {[string]: {start:integer, frame:integer, w:number?, h:number?}} per-key animation + smoothed window size
---@field private _frame integer frame counter (for animation-state cleanup)
---@field private _window_index integer draw-order counter so each window gets its own z layer
---@field private _groups {[string]: {target_w: number, frame: integer}} per-group width state (natural max from last frame)
---@field private _active_group_target number? prev-frame group target width; nil = not inside a window_group
---@field private _active_group_accum number? running max of natural widths contributed this group pass
---@field private _window_fill_w number? available inner width set by the enclosing window before its fn runs
local ui = {}
ui.__index = ui

local DIR_H = 1 -- horizontal (row)
local DIR_V = 2 -- vertical (column)

-- tooltip command kinds (int constants; string compares are expensive)
local CMD_TEXT = 1
local CMD_IMAGE = 2
local CMD_NINEPIECE = 3

ui.OPT_NON_INTERACTIVE = 2
ui.OPT_ALWAYS_CLICKABLE = 3
ui.OPT_FORCE_FOCUSABLE = 7
ui.OPT_SAME_LINE = 14 -- Layout_NextSameLine

-- module-level caches, survive across frames and are shared across all ui instances.
-- clear_cache() on any instance flushes them for all; this is intentional (saves memory,
-- avoids redundant entries for the same text rendered by different instances).
local _text_dim_cache = {} ---@type {[string]:{[number]:{[string]:dimensions}}}
local _text_dim_count = 0 -- unique-entry counter; flushed when it exceeds _TEXT_DIM_LIMIT
local _TEXT_DIM_LIMIT = 16384
local _image_dim_cache = {} ---@type {[number]:{[string]:dimensions}}
local _longest_text_cache = {} ---@type {[string]:number}
local _longest_text_count = 0
local _LONGEST_TEXT_LIMIT = 512
local _measure_cache = {} ---@type {[string]:dimensions}
local _measure_count = 0
local _MEASURE_LIMIT = 512
local _split_cache = {} ---@type {[string]:{[number]:{[number]:{[string]:string[]}}}}
local _split_count = 0
local _SPLIT_LIMIT = 4096

-- Module-level because GuiGetScreenDimensions returns the game's virtual resolution
-- (a game constant, not per-instance). Set once on first ui:new(); all instances share it.
local virtual_width, virtual_height = 1280, 720

---Creates a new UI instance. Call once and reuse across frames.
---@return noita_gui
function ui:new()
	---@diagnostic disable-next-line: missing-fields
	local instance = { ---@type noita_gui
		gui = GuiCreate(),
		_tooltip_gui = GuiCreate(),
		gui_id = 1000,
		_tooltip_gui_id = 1000,
		cursor = { x = 0, y = 0, line_w = 0, line_h = 0, dir = DIR_V },
		cursor_stack = {},
		options = {
			text_font = "",
			text_scale = 1,
			z_index = -9000,
			ninepiece_sprite = "data/ui_gfx/decorations/9piece0_gray.png",
			tooltip_sprite = "data/ui_gfx/decorations/9piece0_gray.png",
			tooltip_border = 3,
			button_sprite = "data/ui_gfx/decorations/9piece0_gray.png",
			button_sprite_hl = "data/ui_gfx/decorations/9piece0.png",
			scrollbar_width = 4,
			scrollbar_track_sprite = nil,
			scrollbar_thumb_sprite = "data/ui_gfx/decorations/9piece0_gray.png",
			scrollbar_thumb_sprite_hl = "data/ui_gfx/decorations/9piece0.png",
			scrollbar_min_thumb = 12,
			scroll_step = 10,
			window_padding = 4,
		},
		mouse = { x = 0, y = 0 },
		dim = { x = 640, y = 360 },
		_measure_depth = 0,
		z_index = -9000,
		_scrolls = {},
		_clip_stack = {},
		_clip_origin_x = 0,
		_clip_origin_y = 0,
		_clip_origin_stack = {},
		_scroll_y = 0,
		_draw_alpha = 1,
		_anim = {},
		_frame = 0,
		_window_index = 0,
		_groups = {},
		_active_group_target = nil,
		_active_group_accum = nil,
		_window_fill_w = nil,
		SCALE_FRAMES = 10,
		ALPHA_FRAMES = 15,
		SCALE_FROM = 0.2,
		ANIMATE = true,
		TOOLTIP_MARGIN = 6,
		TOOLTIP_Z = -10000,
		BUTTON_PAD = 4,
		MIN_TEXT_ALPHA = 0.004,
		FADE_OUT_SPEEDUP = 2.5,
		RESIZE_SPEED = 0.35,
		SCROLL_SPEED = 0.4,
	}
	setmetatable(instance, self)
	virtual_width, virtual_height = GuiGetScreenDimensions(instance.gui)
	return instance
end

---Call at the start of every frame.
function ui:start_frame()
	GuiStartFrame(self.gui)
	GuiStartFrame(self._tooltip_gui)
	self.dim.x, self.dim.y = GuiGetScreenDimensions(self.gui)
	self.z_index = self.options.z_index
	GuiZSet(self.gui, self.z_index)
	GuiOptionsAdd(self.gui, ui.OPT_NON_INTERACTIVE)

	self._hovered_id_this_frame = nil
	self.mouse.x, self.mouse.y = self:_get_mouse_pos()
	self.gui_id = 1000
	self._tooltip_gui_id = 1000
	self._scroll_y = 0
	self:_clear_cursor(0, 0)
	self.cursor_stack = {}
	self._clip_stack = {}
	self._clip_origin_x = 0
	self._clip_origin_y = 0
	self._clip_origin_stack = {}
	self._rec = nil
	self._rec_color = nil
	self._rec_id = nil
	self._rec_sframes = nil
	self._rec_aframes = nil
	self._tt_pending = nil
	self._pending_color = nil
	self._draw_alpha = 1
	self._window_index = 0
	self._frame = self._frame + 1
	self:_prune_anim()
	self:_prune_groups()
	if _text_dim_count > _TEXT_DIM_LIMIT then
		_text_dim_cache = {}
		_text_dim_count = 0
	end
	if _split_count > _SPLIT_LIMIT then
		_split_cache = {}
		_split_count = 0
	end
	if _measure_count > _MEASURE_LIMIT then
		_measure_cache = {}
		_measure_count = 0
	end
	if _longest_text_count > _LONGEST_TEXT_LIMIT then
		_longest_text_cache = {}
		_longest_text_count = 0
	end
end

---Call at the end of every frame (draws queued tooltip, plays hover sound).
function ui:end_frame()
	self:_flush_tooltip()
	if self._hovered_id_this_frame ~= self._hovered_id_last_frame then
		if self._hovered_id_this_frame then GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_select", 0, 0) end
	end
	self._hovered_id_last_frame = self._hovered_id_this_frame
end

---Clears all dimension caches (call on language change, etc.).
function ui:clear_cache()
	_text_dim_cache = {}
	_text_dim_count = 0
	_image_dim_cache = {}
	_longest_text_cache = {}
	_longest_text_count = 0
	_measure_cache = {}
	_measure_count = 0
	_split_cache = {}
	_split_count = 0
end

---Returns the raw Noita gui handle.
---@return gui
function ui:handle()
	return self.gui
end

---Refreshes screen dimensions without resetting layout (for measurements outside the draw loop).
function ui:fetch_dimensions()
	GuiStartFrame(self.gui)
	self.dim.x, self.dim.y = GuiGetScreenDimensions(self.gui)
end

---@private
---@return integer
function ui:id()
	self.gui_id = self.gui_id + 1
	return self.gui_id
end

---@private
function ui:_is_measuring()
	return self._measure_depth > 0
end

---@private
function ui:_is_drawing(width, height)
	if self:_is_measuring() then return false end
	if self._rec then return true end -- recording tooltip content: always "draw" (into buffer)
	if #self._clip_stack == 0 then return true end
	local clip = self._clip_stack[#self._clip_stack]
	width = width or 0
	height = height or 0
	local start_x, end_x = self.cursor.x, self.cursor.x + width
	local start_y, end_y = self.cursor.y, self.cursor.y + height
	if end_y <= 0 or start_y >= clip.h then return false end
	if end_x <= 0 or start_x >= clip.w then return false end
	return true
end

---@private
function ui:_get_mouse_pos()
	local screen_x, screen_y = InputGetMousePosOnScreen()
	local ratio_x, ratio_y = self.dim.x / virtual_width, self.dim.y / virtual_height
	return screen_x * ratio_x, screen_y * ratio_y
end

---@private
function ui:_clear_cursor(x, y, dir)
	local cursor = self.cursor
	cursor.x = x
	cursor.y = y
	cursor.line_w = 0
	cursor.line_h = 0
	cursor.dir = dir or DIR_V
end

---@private
function ui:_restore_cursor(saved)
	local cursor = self.cursor
	cursor.x = saved.x
	cursor.y = saved.y
	cursor.line_w = saved.line_w
	cursor.line_h = saved.line_h
	cursor.dir = saved.dir
end

---Saves the cursor and clears it to (x, y, dir); each argument defaults to the current cursor value.
---@private
---@param x number?
---@param y number?
---@param dir integer?
function ui:_push_cursor(x, y, dir)
	local cursor = self.cursor
	self.cursor_stack[#self.cursor_stack + 1] = { x = cursor.x, y = cursor.y, line_w = cursor.line_w, line_h = cursor.line_h, dir = cursor.dir }
	self:_clear_cursor(x or cursor.x, y or cursor.y, dir or cursor.dir)
end

---Pops and restores the cursor saved by the matching `_push_cursor`.
---@private
function ui:_pop_cursor()
	self:_restore_cursor(table.remove(self.cursor_stack))
end

---@private
function ui:_advance_cursor(width, height)
	local cursor = self.cursor
	if cursor.dir == DIR_V then
		cursor.y = cursor.y + height
		cursor.line_h = cursor.line_h + height
		cursor.line_w = math.max(cursor.line_w, width)
	elseif cursor.dir == DIR_H then
		cursor.x = cursor.x + width
		cursor.line_w = cursor.line_w + width
		cursor.line_h = math.max(cursor.line_h, height)
	end
end

---@private
function ui:_mouse_in_rect(x, y, width, height)
	local mouse_x, mouse_y = self.mouse.x, self.mouse.y
	return mouse_x >= x and mouse_x < x + width and mouse_y >= y and mouse_y < y + height
end

---Adds blank space in the current layout direction.
---@param amount number pixels
function ui:spacing(amount)
	if self.cursor.dir == DIR_V then
		self.cursor.y = self.cursor.y + amount
		self.cursor.line_h = self.cursor.line_h + amount
	else
		self.cursor.x = self.cursor.x + amount
		self.cursor.line_w = self.cursor.line_w + amount
	end
end

---@private
function ui:_layout(dir, fn)
	self:_push_cursor(nil, nil, dir)

	fn()

	local used_width, used_height = self.cursor.line_w, self.cursor.line_h
	self:_pop_cursor()

	-- Advance parent in the OPPOSITE axis (a row stacks downward, a column sideways)
	if dir == DIR_H then
		self.cursor.y = self.cursor.y + used_height
		self.cursor.line_h = self.cursor.line_h + used_height
		self.cursor.line_w = math.max(self.cursor.line_w, used_width)
	else
		self.cursor.x = self.cursor.x + used_width
		self.cursor.line_w = self.cursor.line_w + used_width
		self.cursor.line_h = math.max(self.cursor.line_h, used_height)
	end
end

---Lay out children left-to-right. Advances parent cursor downward afterward.
---@param fn fun()
function ui:begin_row(fn)
	self:_layout(DIR_H, fn)
end

---Lay out children top-to-bottom. Advances parent cursor rightward afterward.
---@param fn fun()
function ui:begin_column(fn)
	self:_layout(DIR_V, fn)
end

---Right-aligns fn's content within row_w; must be called inside a begin_row.
---@param row_w number  total row width to fill within
---@param fn fun()
function ui:row_fill_right(row_w, fn)
	local fn_w = self:measure(fn)
	self:spacing(math.max(0, row_w - self.cursor.line_w - fn_w))
	fn()
end

---Centered row within width; fn runs twice (measure + draw).
---@param width number
---@param fn fun()
function ui:begin_centered_row(width, fn)
	-- Measure in DIR_H so the content's natural row width is captured correctly.
	self:_push_cursor(nil, nil, DIR_H)
	self._measure_depth = self._measure_depth + 1
	fn()
	self._measure_depth = self._measure_depth - 1
	local content_w = self.cursor.line_w
	self:_pop_cursor()
	self:begin_row(function()
		self:spacing(math.max(0, (width - content_w) / 2))
		fn()
	end)
end

---Fixed-size cell; advances the parent cursor (unlike begin_row/column which advance the parent on the cross axis).
---@param width number
---@param height number
---@param fn fun()
function ui:leaf(width, height, fn)
	if self:_is_drawing(width, height) then
		self:_push_cursor(nil, nil, DIR_H)
		fn()
		self:_pop_cursor()
	end
	self:_advance_cursor(width, height)
end

---Draws fn at the cursor without advancing it; use for backgrounds/overlays. Nothing draws during measure passes.
---@param fn fun()
---@return number width, number height
function ui:overlay(fn)
	self:_push_cursor(nil, nil, self.cursor.dir)
	fn()
	local width, height = self.cursor.line_w, self.cursor.line_h
	self:_pop_cursor()
	return width, height
end

---@class window_options
---@field padding number?
---@field id string? stable animation key (defaults to the position)
---@field scale_frames integer? scale-in duration (defaults to SCALE_FRAMES)
---@field alpha_frames integer? fade-in duration (defaults to ALPHA_FRAMES)
---@field min_width number? grow the window to at least this width
---@field min_height number? grow the window to at least this height

---@private Draws a framed, animated, input-blocking window at (x, y).
---Returns its size. Does not touch the parent cursor.
---@param x number
---@param y number
---@param fn fun()
---@param opts window_options?
---@return number width, number height
function ui:_window_at(x, y, fn, opts)
	local padding = (opts and opts.padding) or self.options.window_padding
	local animation_key = (opts and opts.id) or ("win:" .. x .. "," .. y)
	-- Same key, two durations: scale and alpha animate independently.
	local scale_progress = self:anim_progress(animation_key, (opts and opts.scale_frames) or self.SCALE_FRAMES)
	local alpha_progress = self:anim_progress(animation_key, (opts and opts.alpha_frames) or self.ALPHA_FRAMES)

	local min_w = (opts and opts.min_width) or 0
	local group_target = self._active_group_target or 0
	local saved_fill_w = self._window_fill_w

	-- When inside a group with a non-zero target, pre-measure this window's NATURAL
	-- content width (fill_w=0) so fill-inflated widths don't feed back into the group
	-- target and stall shrinking. Only needed when group_target>0 (fill is non-zero).
	local natural_w
	if self._active_group_accum ~= nil and group_target > 0 then
		self._window_fill_w = 0
		local saved_accum = self._active_group_accum
		self._active_group_accum = nil -- prevent nested windows from redundant passes
		self:_push_cursor(x + padding, y + padding)
		self._measure_depth = self._measure_depth + 1
		fn()
		self._measure_depth = self._measure_depth - 1
		natural_w = self.cursor.line_w + padding * 2
		self:_pop_cursor()
		self._active_group_accum = saved_accum
	end

	-- Set fill width for the real draw pass.
	self._window_fill_w = math.max(0, math.max(min_w, group_target) - padding * 2)

	self:_push_cursor(x + padding, y + padding)

	-- Content fades in (linear alpha). Buttons etc. still hit-test normally.
	local previous_alpha = self._draw_alpha
	self._draw_alpha = previous_alpha * alpha_progress
	fn()
	self._draw_alpha = previous_alpha

	local content_w = self.cursor.line_w + padding * 2
	local used_width = math.max(content_w, min_w, group_target)
	local used_height = math.max(self.cursor.line_h + padding * 2, (opts and opts.min_height) or 0)
	self:_pop_cursor()
	self._window_fill_w = saved_fill_w
	-- Report the natural (uninflated) content width so the group target reflects
	-- actual content size, not fill expansion.
	if self._active_group_accum ~= nil then self._active_group_accum = math.max(self._active_group_accum, natural_w or content_w) end

	-- Smooth the *drawn* frame toward the real size so width/height changes
	-- (e.g. the bar matching an opened window) glide instead of snapping. Layout
	-- and the returned size stay true, so only the frame's empty padding tweens.
	local state = self._anim[animation_key]
	local frame_w, frame_h = used_width, used_height
	if state.w == nil or not self.ANIMATE then
		state.w, state.h = used_width, used_height
	else
		state.w = state.w + (used_width - state.w) * self.RESIZE_SPEED
		state.h = state.h + (used_height - state.h) * self.RESIZE_SPEED
		if math.abs(state.w - used_width) < 0.5 then state.w = used_width end
		if math.abs(state.h - used_height) < 0.5 then state.h = used_height end
		frame_w, frame_h = state.w, state.h
	end

	-- Each window gets its own z layer (draw order) so adjacent/stacked window
	-- frames never share a z and flicker. More-negative = more in front, so a
	-- later window sits above an earlier one.
	local depth = self._window_index
	self._window_index = depth + 1
	local frame_z = self.z_index + 100 - depth

	-- Background frame scales in from its centre (only the nine-piece scales,
	-- matching vanilla); scale is eased, alpha stays linear.
	local scale = self.SCALE_FROM + (1 - self.SCALE_FROM) * self:ease_out(scale_progress)
	local scaled_width = frame_w * scale
	local scaled_height = frame_h * scale
	self:ninepiece_at(
		x + (frame_w - scaled_width) / 2,
		y + (frame_h - scaled_height) / 2,
		scaled_width,
		scaled_height,
		{ alpha = alpha_progress, z = frame_z }
	)

	self:block_input(x, y, used_width, used_height)
	return used_width, used_height
end

---Creates a window at an absolute (x, y). Returns actual (width, height).
---Does NOT advance the parent cursor (use for HUD / self-positioned windows).
---@param x number
---@param y number
---@param fn fun()
---@param padding number?
---@param id string? stable animation key (defaults to the position)
---@param scale_frames integer? scale-in duration (defaults to SCALE_FRAMES)
---@param alpha_frames integer? fade-in duration (defaults to ALPHA_FRAMES)
---@return number width, number height
function ui:begin_window(x, y, fn, padding, id, scale_frames, alpha_frames)
	return self:_window_at(x, y, fn, { padding = padding, id = id, scale_frames = scale_frames, alpha_frames = alpha_frames })
end

---Flowing window at cursor; advances the cursor past it.
---@param fn fun()
---@param opts window_options?
---@return number width, number height
function ui:window(fn, opts)
	local x, y = self.cursor.x, self.cursor.y
	local used_width, used_height = self:_window_at(x, y, fn, opts)
	self:_advance_cursor(used_width, used_height)
	return used_width, used_height
end

---Runs fn at absolute (x, y) without a background or cursor advance.
---@param x number
---@param y number
---@param fn fun()
function ui:layout_at(x, y, fn)
	self:_push_cursor(x, y)
	fn()
	self:_pop_cursor()
end

---Overlaps the previous window's bottom border by 1px so two vertically-stacked
---windows visually share their border instead of showing a double-thick seam.
---Call between consecutive window() calls that should appear connected.
function ui:window_join()
	self:spacing(-1)
end

---Groups sibling windows so they share a common width floor without a feedback cycle.
---Each window() inside fn measures its natural (unconstrained) content width; the max
---across all members becomes every member's implicit min_width next frame. Self-framed
---or non-window content can contribute via window_group_contribute().
---@param id string stable key (one entry per group in _groups, persists across frames)
---@param fn fun()
function ui:window_group(id, fn)
	local state = self._groups[id]
	if not state then
		state = { target_w = 0, frame = 0 }
		self._groups[id] = state
	end
	state.frame = self._frame
	local saved_target = self._active_group_target
	local saved_accum = self._active_group_accum
	self._active_group_target = state.target_w
	self._active_group_accum = 0
	fn()
	state.target_w = self._active_group_accum
	self._active_group_target = saved_target
	self._active_group_accum = saved_accum
end

---Contributes width to the active window_group accumulator (for self-framed windows outside window()).
---No-op when called outside a window_group.
---@param width number
function ui:window_group_contribute(width)
	if self._active_group_accum ~= nil then self._active_group_accum = math.max(self._active_group_accum, width) end
end

---Returns the group's shared-width target from the previous frame (0 if unknown).
---@param id string
---@return number
function ui:window_group_target(id)
	local state = self._groups[id]
	return state and state.target_w or 0
end

---Available inner width from the enclosing window's group target; use to fill-to-parent without feedback.
---@return number
function ui:fill_width()
	return self._window_fill_w or 0
end

---Returns cached text dimensions (width, height).
---@param text string
---@param scale number?
---@param font string?
---@return number width, number height
---@nodiscard
function ui:get_text_dim(text, scale, font)
	scale = scale or self.options.text_scale
	font = font or self.options.text_font
	local font_cache = _text_dim_cache[font]
	if not font_cache then
		font_cache = {}
		_text_dim_cache[font] = font_cache
	end
	local scale_cache = font_cache[scale]
	if not scale_cache then
		scale_cache = {}
		font_cache[scale] = scale_cache
	end
	local cached = scale_cache[text]
	if cached then return cached.w, cached.h end
	local width, height = GuiGetTextDimensions(self.gui, text, scale, 2, font)
	scale_cache[text] = { w = width, h = height }
	_text_dim_count = _text_dim_count + 1
	return width, height
end

---Returns cached image dimensions (width, height).
---@param sprite string
---@param scale number?
---@return number width, number height
---@nodiscard
function ui:get_image_dim(sprite, scale)
	scale = scale or 1
	local scale_cache = _image_dim_cache[scale]
	if not scale_cache then
		scale_cache = {}
		_image_dim_cache[scale] = scale_cache
	end
	local cached = scale_cache[sprite]
	if cached then return cached.w, cached.h end
	local width, height = GuiGetImageDimensions(self.gui, sprite, scale)
	scale_cache[sprite] = { w = width, h = height }
	return width, height
end

---Corner size of a 9-piece sprite; GuiImageNinePiece expands the drawn rect outward by this on every side.
---@param sprite string
---@return number
---@nodiscard
function ui:ninepiece_border(sprite)
	local sprite_w = self:get_image_dim(sprite)
	return sprite_w / 3
end

---Returns the width of the longest string in an array. Result is cached by key + language.
---@param array string[]
---@param key string stable cache key
---@return number width
function ui:get_longest_text(array, key)
	if _longest_text_cache[key] then return _longest_text_cache[key] end
	local longest = 0
	for _, text in ipairs(array) do
		local width = self:get_text_dim(text)
		if width > longest then longest = width end
	end
	_longest_text_cache[key] = longest
	_longest_text_count = _longest_text_count + 1
	return longest
end

---Splits text into lines that fit within max_width pixels. Result is cached by key.
---@param text string
---@param max_width number
---@param scale number?
---@param font string?
---@return string[]
function ui:split_string(text, max_width, scale, font)
	scale = scale or self.options.text_scale
	font = font or self.options.text_font
	local font_cache = _split_cache[font]
	if not font_cache then
		font_cache = {}
		_split_cache[font] = font_cache
	end
	local scale_cache = font_cache[scale]
	if not scale_cache then
		scale_cache = {}
		font_cache[scale] = scale_cache
	end
	local width_cache = scale_cache[max_width]
	if not width_cache then
		width_cache = {}
		scale_cache[max_width] = width_cache
	end
	local cached = width_cache[text]
	if cached then return cached end
	local lines = {}
	local current_line = ""
	for word in text:gmatch("%S+") do
		local test_line = (current_line == "") and word or (current_line .. " " .. word)
		if self:get_text_dim(test_line, scale, font) > max_width then
			if current_line ~= "" then lines[#lines + 1] = current_line end
			current_line = word
		else
			current_line = test_line
		end
	end
	if current_line ~= "" then lines[#lines + 1] = current_line end
	width_cache[text] = lines
	_split_count = _split_count + 1
	return lines
end

---Runs fn without drawing to measure its cursor extent.
---@param fn fun()
---@return number width, number height
function ui:measure(fn)
	self:_push_cursor()
	self._measure_depth = self._measure_depth + 1
	fn()
	self._measure_depth = self._measure_depth - 1
	local width, height = self.cursor.line_w, self.cursor.line_h
	self:_pop_cursor()
	return width, height
end

---measure() with the result cached by a stable key (cleared by clear_cache).
---Worth it for expensive content measured every frame (e.g. big scrollboxes).
---@param key string
---@param fn fun()
---@return number width, number height
function ui:measure_cached(key, fn)
	local cached = _measure_cache[key]
	if cached then return cached.w, cached.h end
	local width, height = self:measure(fn)
	_measure_cache[key] = { w = width, h = height }
	_measure_count = _measure_count + 1
	return width, height
end

---@private Appends a command to the tooltip recording buffer and clears pending color.
---@param cmd tooltip_cmd
function ui:_record(cmd)
	self._rec[#self._rec + 1] = cmd
	self._rec_color = nil
end

---Draws text at an absolute position (bypasses cursor).
---@param x number
---@param y number
---@param text string
---@param scale number?
---@param font string?
function ui:text_at(x, y, text, scale, font)
	scale = scale or self.options.text_scale
	font = font or self.options.text_font
	if self._rec then
		local width, height = self:get_text_dim(text, scale, font)
		self:_record({
			kind = CMD_TEXT,
			x = x,
			y = y,
			width = width,
			height = height,
			text = text,
			scale = scale,
			font = font,
			color = self._rec_color,
		})
		return
	end
	self:_apply_color()
	GuiText(self.gui, x, y, text, scale, font)
end

---@class text_options
---@field scale number?
---@field font string?
---@field dx number?
---@field dy number?

---Draws text centered within width.
---@param text string
---@param width number
---@param opts text_options?
function ui:text_centered(text, width, opts)
	local scale = opts and opts.scale or self.options.text_scale
	local font = opts and opts.font or self.options.text_font
	local tw = self:get_text_dim(text, scale, font)
	local dx = math.max(0, (width - tw) / 2)
	if opts then
		self:text(text, { scale = opts.scale, font = opts.font, dy = opts.dy, dx = (opts.dx or 0) + dx })
	else
		self:text(text, { dx = dx })
	end
end

---Draws text at cursor position and advances cursor.
---@param text string
---@param opts text_options?
function ui:text(text, opts)
	local scale, font, offset_x, offset_y = self.options.text_scale, self.options.text_font, 0, 0
	if opts then
		scale = opts.scale or scale
		font = opts.font or font
		offset_x = opts.dx or 0
		offset_y = opts.dy or 0
	end
	local text_width, text_height = self:get_text_dim(text, scale, font)
	local advance_width, advance_height = text_width + offset_x, text_height + offset_y
	if self:_is_drawing(advance_width, advance_height) then
		self:text_at(self.cursor.x + offset_x, self.cursor.y + offset_y, text, scale, font)
	else
		self._pending_color = nil -- consume so it can't leak onto a later widget
	end
	self:_advance_cursor(advance_width, advance_height)
end

---Draws an image at an absolute position (bypasses cursor).
---@param x number
---@param y number
---@param sprite string
---@param alpha number?
---@param scale_x number?
---@param scale_y number?
---@param angle number?  rotation in radians, 0 = no rotation
function ui:image_at(x, y, sprite, alpha, scale_x, scale_y, angle)
	alpha = alpha or 1
	scale_x = scale_x or 1
	scale_y = scale_y or scale_x
	angle = angle or 0
	if self._rec then
		local width, height = self:get_image_dim(sprite, scale_x)
		self:_record({
			kind = CMD_IMAGE,
			x = x,
			y = y,
			width = width,
			height = height,
			sprite = sprite,
			alpha = alpha,
			scale_x = scale_x,
			scale_y = scale_y,
			color = self._rec_color,
		})
		return
	end
	self:_apply_tint()
	GuiImage(self.gui, self:id(), x, y, sprite, alpha * self._draw_alpha, scale_x, scale_y, angle, 2)
end

---@class image_options
---@field alpha number?
---@field scale_x number?
---@field scale_y number?
---@field dx number?
---@field dy number?
---@field angle number?  rotation in radians (CCW positive); 90/270 deg swaps bounding box

---Draws an image at cursor position and advances cursor.
---@param sprite string
---@param opts image_options?
function ui:image(sprite, opts)
	local alpha, scale_x, scale_y, offset_x, offset_y, angle = 1, 1, 1, 0, 0, 0
	if opts then
		alpha = opts.alpha or 1
		scale_x = opts.scale_x or 1
		scale_y = opts.scale_y or scale_x
		offset_x = opts.dx or 0
		offset_y = opts.dy or 0
		angle = opts.angle or 0
	end
	local image_width, image_height = self:get_image_dim(sprite, scale_x)
	-- For 90 or 270 degree rotations the bounding box swaps width and height.
	local adv_w, adv_h = image_width, image_height
	if angle ~= 0 then
		local q = math.floor(math.abs(angle) / (math.pi / 2) + 0.5) % 2
		if q == 1 then
			adv_w = math.floor(image_height * scale_y / scale_x + 0.5)
			adv_h = image_width
		end
	end
	local advance_width = math.max(adv_w + offset_x, 0)
	local advance_height = math.max(adv_h + offset_y, 0)
	if self:_is_drawing(advance_width, advance_height) then
		local draw_x = self.cursor.x + offset_x
		local draw_y = self.cursor.y + offset_y
		-- Shift origin so the rotated image lands inside the bounding box.
		-- CCW 90 (angle > 0): origin must be at the right edge of the box.
		-- CW 90  (angle < 0): origin must be at the bottom edge of the box.
		if angle ~= 0 then
			local q = math.floor(math.abs(angle) / (math.pi / 2) + 0.5) % 2
			if q == 1 then
				if angle > 0 then
					draw_x = draw_x + adv_w
				else
					draw_y = draw_y + image_width
				end
			end
		end
		self:image_at(draw_x, draw_y, sprite, alpha, scale_x, scale_y, angle)
	else
		self._pending_color = nil -- consume so it can't leak onto a later widget
	end
	self:_advance_cursor(advance_width, advance_height)
end

---Draws a sprite via overlay (no row-height inflation) then reserves its width.
---@param sprite string
---@param opts image_options?
function ui:icon_inline(sprite, opts)
	local icon_width = self:overlay(function()
		self:image(sprite, opts)
	end)
	self:spacing(icon_width + 1)
end

---@class ninepiece_options
---@field sprite string?
---@field highlight string?
---@field z integer?
---@field alpha number?
---@field margin number? expand the frame this far outward past (x,y,w,h) (default 0)
---@field border number? override the auto-detected sprite corner size
---@field dx number? x offset
---@field dy number? y offset

---Draws a nine-piece sprite at an absolute position (bypasses cursor).
---@param x number
---@param y number
---@param width number
---@param height number
---@param opts ninepiece_options?
function ui:ninepiece_at(x, y, width, height, opts)
	local sprite = self.options.ninepiece_sprite
	local highlight_sprite = nil
	local widget_z = self.z_index + 100
	local alpha = 1
	local margin = 0
	local border
	if opts then
		sprite = opts.sprite or sprite
		highlight_sprite = opts.highlight
		widget_z = opts.z or widget_z
		alpha = opts.alpha or 1
		margin = opts.margin or 0
		border = opts.border
		x = x + (opts.dx or 0)
		y = y + (opts.dy or 0)
	end
	border = border or self:ninepiece_border(sprite)
	-- Noita draws the 9-piece's border pieces OUTSIDE the rect we pass (each side
	-- grows by the sprite's corner size). Inset by that so (x,y,w,h) is exactly
	-- the visual rect; a positive `margin` lets the frame grow back outward.
	local inset = border - margin
	if inset ~= 0 then
		x = x + inset
		y = y + inset
		width = math.max(width - inset * 2, 0)
		height = math.max(height - inset * 2, 0)
	end
	if self._rec then
		self:_record({
			kind = CMD_NINEPIECE,
			x = x,
			y = y,
			width = width,
			height = height,
			sprite = sprite,
			alpha = alpha,
			z_index = widget_z,
			color = self._rec_color,
		})
		return
	end
	-- Noita's GuiImageNinePiece ignores the GuiBeginScrollContainer translation
	-- that GuiText/GuiImage receive, so inside a clip we add the clip origin
	-- ourselves to land at the same screen position as sibling text/images.
	-- Outside any clip the origin is 0, so this is a no-op there.
	-- Snap to whole pixels: fractional text widths / scale-animation values
	-- otherwise make the frame land ±1px off its content some frames.
	local screen_x = x + self._clip_origin_x
	local screen_y = y + self._clip_origin_y
	GuiZSetForNextWidget(self.gui, widget_z)
	local draw_sprite = sprite
	if highlight_sprite and self:is_hovered_at(screen_x, screen_y, width, height) then draw_sprite = highlight_sprite end
	self:_apply_tint()
	GuiImageNinePiece(self.gui, self:id(), screen_x, screen_y, width, height, alpha * self._draw_alpha, draw_sprite, draw_sprite)
end

---Draws a nine-piece sprite at cursor position and advances cursor.
---@param width number
---@param height number
---@param opts ninepiece_options?
function ui:ninepiece(width, height, opts)
	if self:_is_drawing(width, height) then
		self:ninepiece_at(self.cursor.x, self.cursor.y, width, height, opts)
	else
		self._pending_color = nil -- consume so it can't leak onto a later widget
	end
end

---@param x number  screen (or container-relative) x
---@param y number
---@param width number
---@param height number
---@param play_hover_sound boolean?
---@return boolean
---@nodiscard
function ui:is_hovered_at(x, y, width, height, play_hover_sound)
	if self:_is_measuring() then return false end
	if not self:_mouse_in_rect(x, y, width, height) then return false end
	-- Reject hits that fall outside the active clip rectangle: a widget scrolled
	-- out of a scrollbox must not register as hovered just because the mouse is
	-- over where it would have been.
	local clip = self._clip_stack[#self._clip_stack]
	if clip then
		local mouse_x, mouse_y = self.mouse.x, self.mouse.y
		local clip_x, clip_y = self._clip_origin_x, self._clip_origin_y
		-- > not >= intentionally: a mouse on the exact border pixel is still inside,
		-- so widgets flush with the clip edge remain hoverable without a 1px dead zone.
		if mouse_x < clip_x or mouse_x > clip_x + clip.w or mouse_y < clip_y or mouse_y > clip_y + clip.h then return false end
	end
	if play_hover_sound then self._hovered_id_this_frame = self:id() end
	return true
end

---Hover check using the current cursor position translated to screen space via clip origin.
---Works correctly both inside and outside clip containers.
---@param width number
---@param height number
---@param play_hover_sound boolean?
---@return boolean
---@nodiscard
function ui:is_hovered_cursor(width, height, play_hover_sound)
	return self:is_hovered_at(self._clip_origin_x + self.cursor.x, self._clip_origin_y + self.cursor.y, width, height, play_hover_sound)
end

---Returns true if the left mouse button was just pressed this frame.
---@return boolean
function ui:is_left_clicked()
	return InputIsMouseButtonJustDown(1)
end

---Returns true if the right mouse button was just pressed this frame.
---@return boolean
function ui:is_right_clicked()
	return InputIsMouseButtonJustDown(2)
end

---Returns true if either mouse button was just pressed this frame.
---@return boolean
function ui:is_mouse_clicked()
	return self:is_left_clicked() or self:is_right_clicked()
end

---Returns true while the left mouse button is held.
---@return boolean
function ui:is_mouse_down()
	return InputIsMouseButtonDown(1)
end

---Info about the last Noita widget drawn (for interop with raw Gui* calls).
---@return {lc:boolean, rc:boolean, hovered:boolean, x:number, y:number, w:number, h:number}
---@nodiscard
function ui:get_previous()
	local left_click, right_click, hovered, x, y, width, height = GuiGetPreviousWidgetInfo(self.gui)
	return { lc = left_click, rc = right_click, hovered = hovered, x = x, y = y, w = width, h = height }
end

---Returns the center screen position for a widget of given size.
---@param width number
---@param height number
---@return number x, number y
function ui:calculate_center(width, height)
	return (self.dim.x - width) / 2, (self.dim.y - height) / 2
end

---Screen-space cursor position (accounts for clip origin).
---@return number x, number y
---@nodiscard
function ui:cursor_screen()
	return self._clip_origin_x + self.cursor.x, self._clip_origin_y + self.cursor.y
end

---Container-local cursor position; use instead of cursor_screen when calling image_at/text_at inside a clip.
---@return number x, number y
---@nodiscard
function ui:cursor_local()
	return self.cursor.x, self.cursor.y
end

---True during a measure pass; guard image_at/text_at calls with this to avoid drawing during measurement.
---@return boolean
---@nodiscard
function ui:is_measuring()
	return self:_is_measuring()
end

function ui:color(red, green, blue, alpha)
	if self._rec then
		self._rec_color = { red, green, blue, alpha or 1 }
		return
	end
	self._pending_color = { red, green, blue, alpha or 1 }
end

---@private Applies the deferred color (if any) and the global alpha multiplier
---to the next widget. Called by every live draw primitive.
function ui:_apply_color()
	local draw_alpha = self._draw_alpha
	local color = self._pending_color
	if color then
		GuiColorSetForNextWidget(self.gui, color[1], color[2], color[3], math.max(color[4] * draw_alpha, self.MIN_TEXT_ALPHA))
		self._pending_color = nil
	elseif draw_alpha < 1 then
		GuiColorSetForNextWidget(self.gui, 1, 1, 1, math.max(draw_alpha, self.MIN_TEXT_ALPHA))
	end
end

---@private Applies only a deferred color tint (no alpha fade, caller handles that). For image/nine-piece.
function ui:_apply_tint()
	local color = self._pending_color
	if color then
		GuiColorSetForNextWidget(self.gui, color[1], color[2], color[3], color[4])
		self._pending_color = nil
	end
end

function ui:add_option(option)
	if self._rec then return end
	GuiOptionsAdd(self.gui, option)
end
function ui:add_option_for_next(option)
	if self._rec then return end
	GuiOptionsAddForNextWidget(self.gui, option)
end
function ui:remove_option(option)
	if self._rec then return end
	GuiOptionsRemove(self.gui, option)
end
function ui:set_z_for_next(z_value)
	if self._rec then return end
	GuiZSetForNextWidget(self.gui, z_value)
end
function ui:set_z(z_value)
	if self._rec then return end
	self.z_index = z_value
	GuiZSet(self.gui, z_value)
end

-- animation: vanilla GuiAnimate is buggy; rolling our own.
-- Keyed by stable string, 0..1 over N frames; state discarded when not used for a frame.

---Ease-out cubic. Apply at the call site (e.g. to scale).
---@param progress number 0..1
---@return number 0..1
function ui:ease_out(progress)
	local inverse = 1 - progress
	return 1 - inverse * inverse * inverse
end

---Returns LINEAR progress 0..1 for an animation key, starting it if new.
---Calling this twice with the SAME key but different `frames` is supported and
---intended: both share one start frame, so alpha and scale can run at separate
---speeds off the same animation.
---@param key string
---@param frames integer? duration in frames (defaults to SCALE_FRAMES)
---@return number
function ui:anim_progress(key, frames)
	local state = self._anim[key]
	if not state then
		state = { start = self._frame, frame = self._frame }
		self._anim[key] = state
	end
	state.frame = self._frame
	if not self.ANIMATE then return 1 end
	local progress = (self._frame - state.start) / (frames or self.SCALE_FRAMES)
	if progress < 0 then
		progress = 0
	elseif progress > 1 then
		progress = 1
	end
	return progress
end

---Drops animation state not touched last frame (so re-shown elements replay).
---@private
function ui:_prune_anim()
	for key, state in pairs(self._anim) do
		if state.frame < self._frame - 1 then self._anim[key] = nil end
	end
end

---Drops window_group state not touched last frame (prevents unbounded growth with dynamic ids).
---@private
function ui:_prune_groups()
	for key, state in pairs(self._groups) do
		if state.frame < self._frame - 1 then self._groups[key] = nil end
	end
end

---Translates every $key in a string, re-running so a translation that itself
---contains $keys is expanded too. Bounded passes guard against a malformed or
---self-referential translation looping forever.
---@param str string
---@return string
function ui:locale(str)
	for _ = 1, 8 do
		local before = str
		local count
		str, count = str:gsub("%$%w[%w_]+", GameTextGetTranslatedOrNot)
		-- Done when there was nothing left to expand, or a pass changed nothing
		-- (an untranslatable key that maps to itself).
		if count == 0 or str == before then break end
	end
	return str
end

---Places an invisible clickable container to absorb scroll/click input.
---@param x number
---@param y number
---@param width number
---@param height number
function ui:block_input(x, y, width, height)
	if not self:_mouse_in_rect(x, y, width, height) then return end
	-- ID 2 is stable by design: GuiAnimateAlphaFadeIn suppresses Noita's scroll-
	-- container white-flash, and the animation id must not change frame to frame.
	local id = 2
	GuiAnimateBegin(self.gui)
	GuiAnimateAlphaFadeIn(self.gui, id, 0, 0, true)
	GuiOptionsAddForNextWidget(self.gui, ui.OPT_ALWAYS_CLICKABLE)
	GuiBeginScrollContainer(self.gui, id, x, y, width, height, false, 0, 0)
	GuiAnimateEnd(self.gui)
	GuiEndScrollContainer(self.gui)
end

---Clips draw to a screen-space rectangle. Tracks clip origin for correct hover detection.
---@param x number screen x
---@param y number screen y
---@param width number
---@param height number
---@param fn fun()
function ui:begin_clip_at(x, y, width, height, fn)
	local saved_origin = { x = self._clip_origin_x, y = self._clip_origin_y }
	self._clip_origin_stack[#self._clip_origin_stack + 1] = saved_origin
	self._clip_origin_x = self._clip_origin_x + x
	self._clip_origin_y = self._clip_origin_y + y

	self._clip_stack[#self._clip_stack + 1] = { w = width, h = height }

	-- Visual clip via Noita's scroll container (with scroll disabled).
	-- ID 10 is stable by design (same reason as block_input's ID 2).
	-- Nesting begin_clip_at inside begin_clip_at is not supported.
	GuiAnimateBegin(self.gui)
	GuiAnimateAlphaFadeIn(self.gui, 10, 0, 0, true)
	GuiBeginAutoBox(self.gui)
	GuiBeginScrollContainer(self.gui, 10, x, y, width, height, false, 0, 0)
	GuiEndAutoBoxNinePiece(self.gui)
	GuiAnimateEnd(self.gui)
	fn()
	GuiEndScrollContainer(self.gui)

	self._clip_stack[#self._clip_stack] = nil

	local restored_origin = table.remove(self._clip_origin_stack)
	self._clip_origin_x = restored_origin.x
	self._clip_origin_y = restored_origin.y
end

---@private
function ui:_begin_clip(x, y, width, height, fn)
	if self:_is_measuring() then
		fn()
		return
	end
	self:_push_cursor(self.cursor.x - x, self.cursor.y - y)
	self:begin_clip_at(x, y, width, height, fn)
	self:_pop_cursor()
end

---@class scrollbox_options
---@field bar_width number? overrides options.scrollbar_width
---@field sprite string? background nine-piece behind the whole scrollbox
---@field track_sprite string? overrides options.scrollbar_track_sprite
---@field thumb_sprite string? overrides options.scrollbar_thumb_sprite
---@field thumb_sprite_hl string? overrides options.scrollbar_thumb_sprite_hl (hovered/dragging thumb)
---@field margin number? inner padding between the scrollbox edges and its content

---@class (exact) scrollbox_table
---@field scroll_x number
---@field scroll_y number
---@field target_y number
---@field is_dragging boolean
---@field _drag_offset number
---@field _scroll_vel number

---Clears the saved scroll state for a scrollbox so it starts from the top next frame.
---@param string_id string  same id passed to begin_scrollbox
function ui:reset_scroll(string_id)
	self._scrolls[string_id] = nil
end

---Cursor-positioned scrollbox. Draws content via fn, clips to height, adds scrollbar if needed.
---@param string_id string stable id
---@param width number
---@param height number
---@param fn fun()
---@param opts scrollbox_options?
---@return number content_width, number content_height
function ui:begin_scrollbox(string_id, width, height, fn, opts)
	local content_width, content_height = self:measure(fn)
	if self:_is_measuring() then
		-- Advance so the enclosing window's natural-width measurement (used by window_group)
		-- sees the scrollbox content size, allowing the panel to auto-size correctly.
		self:_advance_cursor(content_width, content_height)
		return content_width, content_height
	end

	local bar_width = (opts and opts.bar_width) or self.options.scrollbar_width
	local background_sprite = (opts and opts.sprite)
	local track_sprite = (opts and opts.track_sprite) or self.options.scrollbar_track_sprite
	local thumb_sprite = (opts and opts.thumb_sprite) or self.options.scrollbar_thumb_sprite
	local thumb_sprite_hl = (opts and opts.thumb_sprite_hl) or self.options.scrollbar_thumb_sprite_hl
	local margin = (opts and opts.margin) or 0
	-- Never reserve empty space below content; cap the clip region at content size.
	height = math.min(height, content_height + margin * 2)

	local start_x, start_y = self.cursor.x, self.cursor.y
	local inner_height = height - margin * 2

	if background_sprite then self:ninepiece_at(start_x, start_y, width, height, { sprite = background_sprite }) end

	-- Scrollbar only when content overflows by more than a few pixels; minor
	-- measurement imprecision clips silently rather than triggering scroll UI.
	local has_scrollbar = content_height > inner_height + 4
	if not has_scrollbar then
		-- No scroll state or stale offset. Clip only when content overflows slightly.
		self:_push_cursor(start_x + margin, start_y + margin)
		if content_height > inner_height then
			self:_begin_clip(start_x + margin, start_y + margin, width - margin * 2, inner_height, fn)
		else
			fn()
		end
		self:_pop_cursor()
		self._scroll_y = 0
		self:_advance_cursor(width, height)
		return content_width, content_height
	end

	-- Content overflows significantly: clip with scrollbar.
	local scroll = self._scrolls[string_id]
	if not scroll then
		scroll = { scroll_x = 0, scroll_y = 0, is_dragging = false, _drag_offset = 0, target_y = 0, _scroll_vel = 0 }
		self._scrolls[string_id] = scroll
	end

	-- Content is clipped to leave the bar its own column, so it never draws under the scrollbar.
	local visible_content_width = width - bar_width
	self:_update_and_draw_scrollbar(
		scroll,
		start_x,
		start_y,
		width,
		height,
		margin,
		content_height,
		bar_width,
		track_sprite,
		thumb_sprite,
		thumb_sprite_hl
	)

	self:_push_cursor(start_x + margin, start_y + margin - scroll.scroll_y)
	self:_begin_clip(start_x + margin, start_y + margin, visible_content_width - margin * 2, inner_height, fn)
	self:_pop_cursor()

	self._scroll_y = scroll.scroll_y
	self:_advance_cursor(width, height)
	return content_width, content_height
end

---@private
function ui:_update_and_draw_scrollbar(
	scroll,
	start_x,
	start_y,
	width,
	height,
	margin,
	content_height,
	bar_width,
	track_sprite,
	thumb_sprite,
	thumb_sprite_hl
)
	local inner_height = height - margin * 2
	local bar_x = start_x + width - bar_width
	local bar_y = start_y + margin
	local bar_height = inner_height
	local visible_ratio = inner_height / content_height
	local thumb_height = math.max(self.options.scrollbar_min_thumb, bar_height * visible_ratio)
	local max_thumb_offset = bar_height - thumb_height
	local max_scroll = math.max(0, content_height - inner_height)

	-- The two conversions between scroll offset and thumb pixel offset, in one
	-- place (used for hit-testing the target and drawing the smoothed thumb).
	local function thumb_of(offset)
		return (max_scroll > 0) and ((offset / max_scroll) * max_thumb_offset) or 0
	end
	local function scroll_of(thumb)
		return (max_scroll > 0) and ((thumb / max_thumb_offset) * max_scroll) or 0
	end

	-- Thumb position for hit-testing tracks the target (responsive to input).
	local thumb_y = thumb_of(scroll.target_y)

	local mouse_down = self:is_mouse_down()
	if not mouse_down then scroll.is_dragging = false end

	if scroll.is_dragging then
		local dragged_thumb_y = math.max(0, math.min(self.mouse.y - scroll._drag_offset, max_thumb_offset))
		scroll.target_y = scroll_of(dragged_thumb_y)
	end

	-- Velocity decays every frame so acceleration clears quickly when scrolling stops.
	scroll._scroll_vel = math.max(0, (scroll._scroll_vel or 0) - 0.3)

	local hovered = self:_mouse_in_rect(start_x, start_y, width, height)
	if hovered then
		local step = self.options.scroll_step
		-- First ~3 rapid notches stay at plain step (dead zone); beyond that, acceleration
		-- scales with content so small lists feel gentle and large lists snappy.
		-- Cap raised to 12 so max speed (effective vel = 12-4 = 8) stays the same.
		local vel_mult = math.max(0.05, math.min(0.3, content_height / 1500))
		local accel = math.max(0, scroll._scroll_vel - 4) * vel_mult
		if InputIsMouseButtonDown(4) then
			scroll.target_y = scroll.target_y - math.floor(step * (1 + accel))
			scroll._scroll_vel = math.min(scroll._scroll_vel + 2, 12)
		end
		if InputIsMouseButtonDown(5) then
			scroll.target_y = scroll.target_y + math.floor(step * (1 + accel))
			scroll._scroll_vel = math.min(scroll._scroll_vel + 2, 12)
		end
		local bar_hovered = self:_mouse_in_rect(bar_x, bar_y, bar_width, bar_height)
		if bar_hovered and mouse_down then
			local thumb_hovered = self:_mouse_in_rect(bar_x, bar_y + thumb_y, bar_width, thumb_height)
			if thumb_hovered then
				if not scroll.is_dragging then
					scroll.is_dragging = true
					scroll._drag_offset = self.mouse.y - thumb_y
				end
			else
				local click_offset = self.mouse.y - bar_y
				local target_thumb_y = math.max(0, math.min(click_offset - thumb_height * 0.5, max_thumb_offset))
				scroll.target_y = scroll_of(target_thumb_y)
			end
		end
	end

	scroll.target_y = math.max(0, math.min(scroll.target_y, max_scroll))
	scroll.scroll_y = math.max(0, math.min(scroll.scroll_y, max_scroll))
	if self.ANIMATE then
		scroll.scroll_y = scroll.scroll_y + (scroll.target_y - scroll.scroll_y) * self.SCROLL_SPEED
		if math.abs(scroll.target_y - scroll.scroll_y) < 0.5 then scroll.scroll_y = scroll.target_y end
	else
		scroll.scroll_y = scroll.target_y
	end

	-- Drawn thumb follows the smoothed offset, so thumb and content glide together.
	local drawn_thumb_y = thumb_of(scroll.scroll_y)
	local thumb_hovered = self:_mouse_in_rect(bar_x, bar_y + thumb_y, bar_width, thumb_height)
	local drawn_thumb_sprite = (thumb_sprite_hl and (thumb_hovered or scroll.is_dragging)) and thumb_sprite_hl or thumb_sprite
	if track_sprite then self:ninepiece_at(bar_x, bar_y, bar_width, bar_height, { z = self.z_index - 10, sprite = track_sprite }) end
	self:ninepiece_at(bar_x, bar_y + drawn_thumb_y, bar_width, thumb_height, { z = self.z_index - 11, sprite = drawn_thumb_sprite })
end

-- Immediate-mode tooltips; open with tooltip(active), fill with primitives, close with tooltip_end().
-- Content is recorded and replayed at end_frame() into a separate gui handle (no id conflicts).

---@class tooltip_options
---@field id string|number? stable animation key (so dynamic text doesn't restart the fade); numbers avoid per-widget string allocation
---@field scale_frames integer? scale-in duration (defaults to SCALE_FRAMES)
---@field alpha_frames integer? fade-in duration (defaults to ALPHA_FRAMES)
---@field sprite string? 9-piece sprite override (defaults to options.tooltip_sprite)
---@field margin number? padding override (defaults to TOOLTIP_MARGIN)
---@field border number? outward expansion of the frame beyond content+margin (defaults to options.tooltip_border)

---Begins a tooltip block. Returns true while it should be filled.
---Usage:
---  if ui:tooltip(hovered) then
---      ui:text("line")
---      ui:tooltip_end()      -- or ui:tooltip_end(x, y) for a fixed anchor
---  end
---@param active boolean usually the widget's hovered state
---@param opts tooltip_options?
---@return boolean recording
function ui:tooltip(active, opts)
	if not active or self:_is_measuring() then return false end
	self._rec = {}
	self._rec_color = nil
	self._rec_id = opts and opts.id
	self._rec_sframes = opts and opts.scale_frames
	self._rec_aframes = opts and opts.alpha_frames
	self._rec_sprite = opts and opts.sprite
	self._rec_margin = opts and opts.margin
	self._rec_border = opts and opts.border
	self:_push_cursor(0, 0, DIR_V)
	return true
end

---Closes the current tooltip block and queues it for end-of-frame drawing.
---Anchor defaults to the mouse position; pass explicit screen coords to pin it.
---When `center` is true, `anchor_x` is treated as the desired horizontal center
---of the tooltip box instead of its left edge.
---@param anchor_x number?
---@param anchor_y number?
---@param center boolean?
function ui:tooltip_end(anchor_x, anchor_y, center)
	local commands = self._rec
	self._rec = nil
	self._rec_color = nil
	self:_pop_cursor()
	if not commands or #commands == 0 then return end
	self._tt_pending = {
		cmds = commands,
		ax = anchor_x or (self.mouse.x + 14),
		ay = anchor_y or (self.mouse.y + 4),
		center = center or false,
		id = self._rec_id,
		sframes = self._rec_sframes,
		aframes = self._rec_aframes,
		sprite = self._rec_sprite,
		margin = self._rec_margin,
		border = self._rec_border,
	}
	self._rec_id = nil
	self._rec_sframes = nil
	self._rec_aframes = nil
	self._rec_sprite = nil
	self._rec_margin = nil
	self._rec_border = nil
end

---@private Draws the queued tooltip (called from end_frame)
function ui:_flush_tooltip()
	local pending = self._tt_pending
	self._tt_pending = nil
	local tt = self._tt_active

	if pending then
		-- Caller-supplied id is stable across dynamic text; else a structural sig.
		local key = pending.id
		if not key then
			local h = #pending.cmds
			for i = 1, #pending.cmds do
				local c = pending.cmds[i]
				h = (h * 31 + c.kind) % 2147483647
				local s = c.text or c.sprite
				if s then
					for j = 1, #s do
						h = (h * 31 + s:byte(j)) % 2147483647
					end
				end
			end
			key = h
		end
		if not tt or tt.key ~= key then
			tt = { key = key, scale_p = 0, alpha_p = 0 }
			self._tt_active = tt
		end
		tt.cmds = pending.cmds
		tt.ax, tt.ay, tt.center = pending.ax, pending.ay, pending.center
		tt.sframes = pending.sframes or self.SCALE_FRAMES
		tt.aframes = pending.aframes or self.ALPHA_FRAMES
		tt.sprite = pending.sprite
		tt.margin = pending.margin
		tt.border = pending.border
		tt.target = 1 -- fade in / stay
	elseif tt then
		tt.target = 0 -- not requested this frame, fade out
	else
		return
	end

	-- 0 = hidden, 1 = shown; symmetric fade with separate scale/alpha durations.
	local function step(progress, frames)
		if progress < tt.target then return math.min(tt.target, progress + 1 / frames) end
		if progress > tt.target then return math.max(tt.target, progress - 1 / frames) end
		return progress
	end
	if self.ANIMATE then
		tt.scale_p = step(tt.scale_p, tt.sframes)
		tt.alpha_p = step(tt.alpha_p, tt.aframes)
	else
		tt.scale_p, tt.alpha_p = tt.target, tt.target
	end

	if tt.target == 0 and tt.alpha_p <= 0 and tt.scale_p <= 0 then
		self._tt_active = nil -- fully faded out
		return
	end

	local commands = tt.cmds
	local alpha_progress = tt.alpha_p
	-- Text fades out faster than the frame: the frame also shrinks while closing,
	-- so a same-rate text fade reads as lingering. Fade-IN is unchanged.
	local text_alpha = alpha_progress
	if tt.target == 0 then text_alpha = alpha_progress ^ self.FADE_OUT_SPEEDUP end

	local min_x, min_y = math.huge, math.huge
	local max_x, max_y = -math.huge, -math.huge
	for i = 1, #commands do
		local command = commands[i]
		if command.x < min_x then min_x = command.x end
		if command.y < min_y then min_y = command.y end
		if command.x + command.width > max_x then max_x = command.x + command.width end
		if command.y + command.height > max_y then max_y = command.y + command.height end
	end

	local margin = tt.margin or self.TOOLTIP_MARGIN
	local total_width = (max_x - min_x) + margin * 2
	local total_height = (max_y - min_y) + margin * 2

	local box_x = tt.center and (tt.ax - total_width / 2) or tt.ax
	local box_y = tt.ay
	if box_x + total_width > self.dim.x then box_x = self.dim.x - total_width end
	if box_y + total_height > self.dim.y then box_y = self.dim.y - total_height end
	if box_x < 0 then box_x = 0 end
	if box_y < 0 then box_y = 0 end

	local offset_x = box_x + margin - min_x
	local offset_y = box_y + margin - min_y

	local saved_gui, saved_gui_id = self.gui, self.gui_id
	self.gui = self._tooltip_gui
	self.gui_id = self._tooltip_gui_id

	-- Frame + content scale together about the box centre, so the whole tooltip
	-- zooms from its middle (content doesn't drift, it stays anchored to centre).
	local scale = self.SCALE_FROM + (1 - self.SCALE_FROM) * self:ease_out(tt.scale_p)
	local centre_x = box_x + total_width / 2
	local centre_y = box_y + total_height / 2

	-- Background frame: scale eased, alpha linear.
	-- GuiImageNinePiece extends the frame outward by the sprite's corner size on
	-- every side. Inset the rect by (sprite_corner - tooltip_border) so the visual
	-- frame lands at content+margin expanded outward by tooltip_border on each side.
	local sprite = tt.sprite or self.options.tooltip_sprite
	local sprite_corner = self:ninepiece_border(sprite)
	local tooltip_border = tt.border or self.options.tooltip_border
	local inset = sprite_corner - tooltip_border
	local frame_w = (total_width - inset * 2) * scale
	local frame_h = (total_height - inset * 2) * scale
	GuiZSetForNextWidget(self.gui, self.TOOLTIP_Z + 1)
	GuiImageNinePiece(self.gui, self:id(), centre_x - frame_w / 2, centre_y - frame_h / 2, frame_w, frame_h, alpha_progress, sprite, sprite)

	for i = 1, #commands do
		local command = commands[i]
		local draw_x = centre_x + (command.x + offset_x - centre_x) * scale
		local draw_y = centre_y + (command.y + offset_y - centre_y) * scale
		if command.kind == CMD_TEXT then
			local color = command.color
			GuiColorSetForNextWidget(
				self.gui,
				color and color[1] or 1,
				color and color[2] or 1,
				color and color[3] or 1,
				math.max((color and color[4] or 1) * text_alpha, self.MIN_TEXT_ALPHA)
			)
			GuiZSetForNextWidget(self.gui, self.TOOLTIP_Z)
			GuiText(self.gui, draw_x, draw_y, command.text, (command.scale or 1) * scale, command.font)
		elseif command.kind == CMD_IMAGE then
			if command.color then GuiColorSetForNextWidget(self.gui, command.color[1], command.color[2], command.color[3], command.color[4]) end
			GuiZSetForNextWidget(self.gui, self.TOOLTIP_Z)
			GuiImage(
				self.gui,
				self:id(),
				draw_x,
				draw_y,
				command.sprite,
				(command.alpha or 1) * alpha_progress,
				(command.scale_x or 1) * scale,
				(command.scale_y or 1) * scale,
				0,
				2
			)
		elseif command.kind == CMD_NINEPIECE then
			if command.color then GuiColorSetForNextWidget(self.gui, command.color[1], command.color[2], command.color[3], command.color[4]) end
			GuiZSetForNextWidget(self.gui, command.z_index or self.TOOLTIP_Z)
			GuiImageNinePiece(
				self.gui,
				self:id(),
				draw_x,
				draw_y,
				command.width * scale,
				command.height * scale,
				(command.alpha or 1) * alpha_progress,
				command.sprite,
				command.sprite
			)
		end
	end

	self._tooltip_gui_id = self.gui_id
	self.gui = saved_gui
	self.gui_id = saved_gui_id
end

-- Example widgets built from the public API.

---@class button_options
---@field sprite string?
---@field sprite_hl string?
---@field silent boolean?
---@field min_width number?  expand the ninepiece to at least this width; text is centered inside

---Button widget; returns clicked, hovered.
---@param text string
---@param active boolean
---@param opts button_options?
---@return boolean clicked, boolean hovered
function ui:button(text, active, opts)
	local sprite = (opts and opts.sprite) or self.options.button_sprite
	local highlight_sprite = (opts and opts.sprite_hl) or self.options.button_sprite_hl
	local silent = opts and opts.silent

	local text_width = self:get_text_dim(text)
	local button_width = math.max(text_width + self.BUTTON_PAD * 2, (opts and opts.min_width) or 0)
	local hovered = self:is_hovered_cursor(button_width, 11, active)
	local clicked = hovered and self:is_left_clicked()
	if clicked and not silent then GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0) end

	self:leaf(button_width, 12, function()
		-- Text gets amore-front z so the caller's global GuiZSet can't bury it.
		local background_sprite = (hovered and active) and highlight_sprite or sprite
		self:ninepiece(button_width, 12, { z = self.z_index, sprite = background_sprite, margin = 1, dy = -1 })
		if not active then self:color(0.6, 0.6, 0.6) end
		self:set_z_for_next(self.z_index - 1)
		self:text(text, { dx = math.floor((button_width - text_width) / 2) })
	end)

	return clicked, hovered
end

---Checkbox widget; returns whether it was toggled.
---@param text string
---@param value boolean current state
---@return boolean clicked
function ui:checkbox(text, value)
	local gap = 2
	local box = 11
	local total_width = self:get_text_dim(text) + gap + box
	local hovered = self:is_hovered_cursor(total_width, box)
	local clicked = hovered and self:is_mouse_clicked()
	if clicked then GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0) end

	self:leaf(total_width, box, function()
		local box_z = self.z_index - 1
		local text_z = self.z_index - 2

		if hovered then self:color(1, 1, 0.7) end
		self:set_z_for_next(text_z)
		self:text(text)
		self:spacing(gap)

		-- ninepiece doesn't advance the cursor, so after the box we're still at
		-- its origin; spacing then re-centres the state glyph on top of it.
		local box_sprite = hovered and self.options.button_sprite_hl or self.options.button_sprite
		self:ninepiece(box + 1, box + 1, { sprite = box_sprite, z = box_z, dx = -1, dy = -1 })
		local glyph = value and "V" or "X"
		local glyph_w, glyph_h = self:get_text_dim(glyph)
		self:spacing((box - glyph_w) / 2)
		self:color(value and 0 or 0.8, value and 0.8 or 0, 0)
		self:set_z_for_next(text_z)
		self:text(glyph, { dy = (box - glyph_h) / 2 })
	end)

	return clicked
end

return ui
