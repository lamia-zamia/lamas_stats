---@class LS_Gui_perks
---@field current integer|nil  index into VIEWS of the open sub-view, nil = none
---@field content_w number  inner pixel width of the perk windows (= header width)
---@field per_row integer  perk icons that fit across content_w (no magic cap)
---@field reroll_count number
---@field scroll_h number  last frame's scrollbox content height (used to detect scrollbar presence for per_row)
---@field tip_x number  screen x for perk tooltips (right of the window)
---@field tip_y number  screen y for perk tooltips (level with the header)
---@field cache perk_cell[][]?  built groups for cache_view (nil = needs build)
---@field cache_view integer?  which view cache holds
---@field cache_dirty boolean  perks data changed; rebuild on next draw

---@class (exact) LS_Gui
---@field perk LS_Gui_perks
local pg = {
	perk = {
		current = 1,
		content_w = 0,
		per_row = 1,
		reroll_count = 0,
		scroll_h = 0,
		tip_x = 0,
		tip_y = 0,
		cache = nil,
		cache_view = nil,
		cache_dirty = true,
	},
}

local PERK_PITCH = 17 -- 16px icon + 1px gap
local GROUP_PAD = 1 -- padding above/below each striped group
local BTN = "mods/lamas_stats/files/gfx/ui_9piece_button_alt.png"
local BTN_HL = "mods/lamas_stats/files/gfx/ui_9piece_button_alt_highlight.png"
local ALWAYS_CAST = "ALWAYS_CAST"

-- A cell is { perk = perk_data, tip = fn(self,arg)?, arg = any }. A group is a
-- cell[]; a view's build() returns group[]. `striped` views (the predicted
-- ones) draw a shaded background per group; `current` is one un-striped group.
-- Selection is by integer index (perk.current) and dispatch is a direct build
-- function ref - no string ids or string-keyed method dispatch on the hot path.
---@alias perk_cell {perk:perk_data, tip:(fun(self:LS_Gui, arg:any))?, arg:any}
---@class perk_view
---@field label string  key into the global T localization table
---@field striped boolean
---@field build fun(self:LS_Gui):perk_cell[][]
---@type perk_view[]  populated after the build methods are defined (see bottom)
local VIEWS = {}

local modules = {
	"mods/lamas_stats/files/scripts/gui/perks/gui_perks_tooltips.lua",
}

for i = 1, #modules do
	local module = dofile_once(modules[i])
	if not module then error("couldn't load " .. modules[i]) end
	for k, v in pairs(module) do
		pg[k] = v
	end
end

---Tooltip anchor: right of the window, level with the menu header.
---@private
---@return number x, number y
function pg:perk_tip_anchor()
	return self.perk.tip_x, self.perk.tip_y
end

---Perk icon cell (16x16) with hover pop; tooltip is numeric-keyed and only opened while hovered.
---@private
---@param perk perk_data
---@param tip_fn fun(self:LS_Gui, arg:any)?
---@param tip_arg any
---@param tip_key number stable tooltip animation key
function pg:perks_icon(perk, tip_fn, tip_arg, tip_key)
	local hovered = self:is_hovered_cursor(16, 16)
	self:leaf(16, 16, function()
		local pop = hovered and 1.2 or 0
		self:image(perk.perk_icon, { dx = -pop, dy = -pop, scale_x = hovered and 1.15 or 1 })
	end)
	self:spacing(PERK_PITCH - 16)
	if
		hovered
		and tip_fn
		and self:tooltip(true, { id = tip_key, sprite = "mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png", border = 0 })
	then
		tip_fn(self, tip_arg)
		local ax, ay = self:perk_tip_anchor()
		self:tooltip_end(ax, ay, false)
	end
end

---Draws one group's cells in wrapping rows; tooltip key = group*4096+slot, never built unless hovered.
---@private
---@param cells perk_cell[]
---@param per_row integer
---@param group integer
function pg:perks_cell_grid(cells, per_row, group)
	local index = 1
	while index <= #cells do
		local row_start = index
		self:begin_row(function()
			for _ = 1, per_row do
				local cell = cells[index]
				if not cell then break end
				self:perks_icon(cell.perk, cell.tip, cell.arg, group * 4096 + index)
				index = index + 1
			end
		end)
		if row_start == index then break end -- safety: nothing drawn
		self:spacing(1)
	end
end

---Draws the selected sub-view; cell/group structure is cached and only rebuilt on data change or view switch.
---@private
function pg:perks_draw_view()
	local p = self.perk
	local view = VIEWS[p.current]
	if not view then return end
	local groups = p.cache
	if not groups or p.cache_dirty or p.cache_view ~= p.current then
		groups = view.build(self)
		p.cache = groups
		p.cache_view = p.current
		p.cache_dirty = false
	end
	local per_row = p.per_row
	for g = 1, #groups do
		local cells = groups[g]
		if view.striped then
			self:spacing(GROUP_PAD)
			self:perks_group_stripe((g % 2 == 0) and 0.25 or 0.65, math.ceil(#cells / per_row))
			self:perks_cell_grid(cells, per_row, g)
		else
			self:perks_cell_grid(cells, per_row, g)
		end
	end
end

---Cells for the "current" view: every perk the player has picked.
---@private
---@return perk_cell[][]
function pg:perks_build_current()
	local list = self:perks_current_list()
	local cells = {}
	for i = 1, #list do
		cells[i] = { perk = list[i], tip = self.perks_current_perk_tooltip, arg = list[i] }
	end
	return { cells }
end

---Cells for the "next" view: one group per predicted future pickup.
---@private
---@return perk_cell[][]
function pg:perks_build_future()
	local future = self.perks.predict.future_perks
	local groups = {}
	for g = 1, #future do
		local ids = future[g]
		local cells = {}
		for j = 1, #ids do
			local perk = self.perks.data:get_data(ids[j])
			cells[j] = { perk = perk, tip = self.perks_current_perk_tooltip, arg = perk }
		end
		groups[g] = cells
	end
	return groups
end

---Cells for the "reroll" view: one group per predicted reroll.
---@private
---@return perk_cell[][]
function pg:perks_build_reroll()
	local reroll = self.perks.predict.reroll_perks
	local groups = {}
	for g = 1, #reroll do
		local ids = reroll[g]
		local cells = {}
		for slot = 1, #ids do
			local perk, tip, arg = self:perks_reroll_slot(g, ids, slot)
			cells[slot] = { perk = perk, tip = tip, arg = arg }
		end
		groups[g] = cells
	end
	return groups
end

---Resolves the icon + tooltip for one slot of a reroll prediction group. Only
---the first group can be matched to on-ground entities (accurate always-cast);
---deeper groups are shown as raw perk data.
---@private
---@param group_index integer
---@param ids string[]
---@param slot integer
---@return perk_data perk, fun(self:LS_Gui, arg:any) tip_fn, any tip_arg
function pg:perks_reroll_slot(group_index, ids, slot)
	if group_index == 1 and self.perks.nearby.entities[slot] then
		local nearby_data = self.perks.nearby.data[slot] ---@type nearby_perks_data
		local perk_id = ids[nearby_data.spawn_order]
		local this_data = {
			x = nearby_data.x,
			y = nearby_data.y,
			id = perk_id,
			cast = perk_id == ALWAYS_CAST and self.perks.nearby:PredictAlwaysCast(nearby_data.x, nearby_data.y) or nil,
		}
		return self.perks.data:get_data(perk_id), self.perks_nearby_tooltip, this_data
	end
	local perk = self.perks.data:get_data(ids[slot])
	return perk, self.perks_current_perk_tooltip, perk
end

---Draws the perks panel (header + scrollbox).
function pg:perks_draw_window()
	local m = self.menu
	local nearby_count = #self.perks.nearby.entities
	self:check_for_updates(nearby_count)

	local header_width, header_h = self:window(function()
		self:spacing(1)
		self:begin_row(function()
			for i = 1, #VIEWS do
				local is_open = self.perk.current == i
				local clicked = self:button(T[VIEWS[i].label] or VIEWS[i].label, not is_open, { sprite = BTN, sprite_hl = BTN_HL })
				self:spacing(2)
				if clicked then
					if is_open then
						self.perk.current = nil
					else
						self:check_for_updates(-1)
						self.perk.current = i
					end
				end
			end
			self:spacing(3)
			self:perks_draw_stats()
		end)
		self:spacing(-1)
		if self.config.enable_nearby_perks and nearby_count > 0 then
			self:spacing(2)
			self:perks_draw_nearby()
		end
	end, { id = "perks_header", min_width = m._just_switched and 0 or m.shared_width })

	-- Scrollbox cap: max_height is the total budget for the whole panel (header + list).
	-- Subtract the header window height so all panels bottom-align at the same screen y.
	local scrollbox_cap = math.max(20, self.max_height - header_h + 1)

	self.perk.tip_x = m.start_x + header_width + 2
	self.perk.tip_y = m.start_y - 1

	if self.perk.current then
		self:window_join()
		self:window(function()
			-- fill_width() = 0 during the group's natural-width pass, so the group
			-- accumulates the true minimum width rather than locking to the previous
			-- panel's inflated width.
			-- A row of n icons spans 17n px (each icon keeps its trailing 1px gap),
			-- so capacity is floor(avail / PITCH) - no +1 (that overflowed the clip
			-- and ate the last slot). Reserve the scrollbar column only when last
			-- frame's content actually overflowed, so we neither waste a slot when
			-- there's no bar nor hide one under it when there is.
			-- On the switch frame, fill_width() is still inflated by the previous panel's
			-- group target. Reusing the previous stable content_w prevents per_row from
			-- jumping to a wide value and reflowing icons for one frame.
			local inner_w = (m._just_switched and self.perk.content_w > 0) and self.perk.content_w or math.max(PERK_PITCH, self:fill_width())
			-- Reset scroll_h on switch so stale overflow from the previous tab doesn't
			-- shrink per_row and inflate content height, which would self-perpetuate.
			if m._just_switched then self.perk.scroll_h = 0 end
			local scrollbar = (self.perk.scroll_h > scrollbox_cap) and (self.options.scrollbar_width or 0) or 0
			self.perk.content_w = inner_w
			self.perk.per_row = math.max(1, math.floor((inner_w - scrollbar) / PERK_PITCH))
			-- Self-size to last frame's content (one-frame lag, but content
			-- height is stable per view) so the box never reserves more
			-- vertical space than it needs, capped at scrollbox_cap.
			local _, content_height = self:begin_scrollbox("perks", inner_w, scrollbox_cap, function()
				self:perks_draw_view()
			end)
			self.perk.scroll_h = content_height
		end, { id = "perks_window", min_width = header_width })
	end
end

---Triggers a data update if nearby perks, children, or reroll count changed.
---@private
---@param current_nearby_perks number
function pg:check_for_updates(current_nearby_perks)
	local reroll_count = self.mod:GetGlobalNumber("TEMPLE_PERK_REROLL_COUNT")
	self.perks.nearby:Scan()
	if
		current_nearby_perks ~= #self.perks.nearby.entities
		or self:check_perk_picked()
		or reroll_count ~= self.perk.reroll_count
	then
		self:perks_update()
	end
	self.perk.reroll_count = reroll_count
end

---Updates perks data and invalidates the view cache.
---@private
function pg:perks_update()
	self.perks:GetCurrentList()
	self.perks.nearby:ParseEntities()
	self.perk.cache_dirty = true
end

---Initializes perks data.
function pg:perks_init()
	self:check_for_updates(-1)
end

---Perks summary row; always drawn (even as zeroes) to keep header width stable.
---@private
function pg:perks_draw_stats()
	local perks_lottery = self.perks.data:get_data("PERKS_LOTTERY")
	local chance = 100 - math.floor(self.mod:GetGlobalNumber("TEMPLE_PERK_DESTROY_CHANCE", 100))

	local total_str = string.format(T.Perks .. ": %d", self.perks.total_amount)
	local reroll_str = tostring(self.perk.reroll_count)
	local chance_str = chance .. "%"

	self:draw_padded(total_str, string.format(T.Perks .. ": %d", 99))
	self:spacing(4)

	self:perks_stat_icon("mods/lamas_stats/files/gfx/reroll_machine.png")
	self:draw_padded(reroll_str, "99")
	self:spacing(4)

	self:perks_stat_icon(perks_lottery.perk_icon)
	self:draw_padded(chance_str, "100%")
end

---Draws text padded to at least the width of `reserved_str`, so the column
---stays stable across value changes (e.g. "3" never narrower than "99").
---@private
---@param str string
---@param reserved_str string
function pg:draw_padded(str, reserved_str)
	local natural = self:get_text_dim(str)
	local width = math.max(natural, self:get_text_dim(reserved_str))
	self:text(str)
	if width > natural then self:spacing(width - natural) end
end

---Stat icon that doesn't inflate row height; reserves its width for following text.
---@private
---@param sprite string
function pg:perks_stat_icon(sprite)
	self:icon_inline(sprite, { dy = -3 })
end

---Tooltip line centered within width.
---@private
---@param text string
---@param width number
---@param gray boolean?
function pg:perk_tip_line(text, width, gray)
	if gray then
		self:color_gray()
	else
		self:color(0.8, 0.8, 0.8)
	end
	self:text_centered(text, width)
end

---Draws the perk icon + name header row, centred within `width`.
---@private
---@param perk perk_data
---@param ui_name string
---@param width number
function pg:perk_tip_header(perk, ui_name, width)
	local icon_width, icon_height = self:get_image_dim(perk.perk_icon, 0.625)
	local _, text_height = self:get_text_dim(ui_name)
	self:begin_centered_row(width, function()
		self:leaf(icon_width, text_height, function()
			self:image(perk.perk_icon, { scale_x = 0.625, dy = (text_height - icon_height) / 2 })
		end)
		self:spacing(3)
		self:text(ui_name)
	end)
end

---Group stripe drawn via overlay (no cursor advance, skipped during scrollbox measure pass).
---@private
---@param shade number
---@param row_count integer
function pg:perks_group_stripe(shade, row_count)
	self:draw_stripe(self.perk.content_w, PERK_PITCH * row_count + GROUP_PAD, shade, 0.1, -GROUP_PAD)
end

---Picked-perk data list (picked_count >= 1) for the "current" view grid.
---@private
---@return perk_data[]
function pg:perks_current_list()
	local list = {}
	for i = 1, #self.perks.data.list do
		local perk = self.perks.data:get_data(self.perks.data.list[i])
		if perk.picked_count >= 1 then list[#list + 1] = perk end
	end
	return list
end

-- Built now that the build methods exist; dispatch is a direct function ref.
VIEWS[1] = { label = "lamas_stat_current", striped = false, build = pg.perks_build_current }
VIEWS[2] = { label = "lamas_stats_perks_next", striped = true, build = pg.perks_build_future }
VIEWS[3] = { label = "lamas_stats_perks_reroll", striped = true, build = pg.perks_build_reroll }

return pg
