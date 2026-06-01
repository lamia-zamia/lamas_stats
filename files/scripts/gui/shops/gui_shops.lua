---@class (exact) LS_Gui_shops
---@field tip_x number         screen x right of the shops window (panel anchor)
---@field tip_y number         screen y level with the menu header (panel anchor)
---@field content_w number     inner pixel width of the shops scrollbox
---@field pinned_wand shop_item? wand item pinned for persistent detail view, nil = none
---@field hovered_wand shop_item? wand item hovered this frame, nil if none (reset each frame)

---@class (exact) LS_Gui
---@field private shops LS_Gui_shops
local sg = {
	shops = {
		tip_x = 0,
		tip_y = 0,
		content_w = 0,
		pinned_wand = nil,
		hovered_wand = nil,
	},
}

local WAND_ICON = "data/ui_gfx/perk_icons/wand_experimenter.png"
local INV = "data/ui_gfx/inventory/"
-- Width of one item cell: 16px icon + 1px gap
local ITEM_W = 17
-- Height of one item cell: 16px icon + 1px gap + ~8px price text
local ITEM_H = 26
-- Width of the mountain index label column
local LABEL_W = 14
-- Minimum number of item widths to reserve for the panel
local MIN_ITEMS_SHOWN = 5
-- Scale factor for spell slot cells (1 = original 20px background sprites).
-- Change this to resize all spell slots in the wand detail panel.
local SPELL_SCALE = 0.8
local SPELL_SIZE = 20 * SPELL_SCALE -- cell side in px
local SPELL_INSET = math.max(1, math.floor(2 * SPELL_SCALE + 0.5)) -- icon inset inside cell
-- Icon drawn slightly smaller than the bg so it sits visually inset from the box edge.
local ICON_SCALE = SPELL_SCALE * 0.95
-- Width of one spell slot cell: scaled cell + 1px gap
local SPELL_PITCH = SPELL_SIZE
-- Uniform scale applied to wand sprites in the detail panel
local WAND_SCALE = 2

-- Stat rows in display order. locale keys use $ prefix for GameTextGetTranslatedOrNot.
-- time=true  : value is in frames; show as seconds normally, frames in alt mode
-- signed=true: show + sign for positive values (cast delay)
-- is_bool    : value is 0/1; show Yes/No via $menu_yes/$menu_no
-- spread     : show with one decimal and "deg"
local WAND_STATS = {
	{ key = "shuffle_deck_when_empty", icon = INV .. "icon_gun_shuffle.png", locale = "$inventory_shuffle", is_bool = true },
	{ key = "actions_per_round", icon = INV .. "icon_gun_actions_per_round.png", locale = "$inventory_actionspercast" },
	{
		key = "fire_rate_wait",
		icon = INV .. "icon_fire_rate_wait.png",
		locale = "$inventory_castdelay",
		time = true,
		signed = true,
	},
	{ key = "reload_time", icon = INV .. "icon_gun_reload_time.png", locale = "$inventory_rechargetime", time = true },
	{ key = "mana_max", icon = INV .. "icon_mana_max.png", locale = "$inventory_manamax" },
	{ key = "mana_charge_speed", icon = INV .. "icon_mana_charge_speed.png", locale = "$inventory_manachargespeed" },
	{ key = "deck_capacity", icon = INV .. "icon_gun_capacity.png", locale = "$inventory_capacity" },
	{ key = "spread_degrees", icon = INV .. "icon_spread_degrees.png", locale = "$inventory_spread", spread = true },
}
local AC_ICON = INV .. "icon_gun_permanent_actions.png"

-- Maps ACTION_TYPE_* constant to its type-specific background sprite.
local ITEM_BG = {
	[0] = INV .. "item_bg_projectile.png",
	[1] = INV .. "item_bg_static_projectile.png",
	[2] = INV .. "item_bg_modifier.png",
	[3] = INV .. "item_bg_draw_many.png",
	[4] = INV .. "item_bg_material.png",
	[5] = INV .. "item_bg_other.png",
	[6] = INV .. "item_bg_utility.png",
	[7] = INV .. "item_bg_passive.png",
}
local SPELL_BOX = INV .. "hover_info_empty_slot.png"

---Format a numeric stat value for display.
---@param stat table  entry from WAND_STATS
---@param v number
---@param alt boolean  true = show frames for time stats instead of seconds
---@return string
local function fmt_stat(stat, v, alt)
	if stat.spread then
		local r = math.floor(v * 10 + 0.5) / 10
		return tostring(r) .. " deg"
	elseif stat.time then
		local n = math.floor(v + 0.5)
		if alt then return (stat.signed and n > 0 and "+" or "") .. n .. "f" end
		local s = v / 60
		if stat.signed then return string.format("%s%.2fs", s > 0 and "+" or "", s) end
		return string.format("%.2fs", s)
	end
	return tostring(math.floor(v + 0.5))
end

---Draw a single spell icon with a three-layer background (box + type bg + icon),
---hover-zoom, and spell name tooltip.
---Layers are z-sorted so box renders behind type bg, icon on top.
---@private
---@param spell_id string
---@param tip_key integer  stable tooltip key unique in this scrollbox pass
---@param box boolean? draw box
function sg:shops_draw_spell(spell_id, tip_key, box)
	local data = self.actions:get_data(spell_id)
	local type_bg = ITEM_BG[data.type] or INV .. "item_bg_other.png"
	local hovered = self:is_hovered_cursor(SPELL_SIZE, SPELL_SIZE)
	local pop = hovered and 1.0 or 0
	self:leaf(SPELL_SIZE, SPELL_SIZE, function()
		-- z_index is the global GuiZSet base (~-9000). Window ninepieces land at
		-- z_index+100-depth (~-8900), so content must be MORE negative to render in front.
		-- Layer 1: generic box (furthest back, still in front of window frame)
		if box then
			self:set_z_for_next(self.z_index - 1)
			self:image(SPELL_BOX, { scale_x = SPELL_SCALE })
		end
		-- Layer 2: type-specific background (middle).
		-- When box was drawn it advanced the cursor by SPELL_SIZE, so go back by that
		-- amount. Without box the cursor is still at cell start, so dx = 0.
		local bg_dx = box and -SPELL_SIZE or 0
		self:set_z_for_next(self.z_index - 2)
		self:image(type_bg, { dx = bg_dx, scale_x = SPELL_SCALE, alpha = 0.75 })
		-- Layer 3: spell icon (front), SPELL_INSET inset; hover pops it slightly.
		-- ICON_SCALE is smaller than SPELL_SCALE so the icon sits inset from the bg edge.
		self:set_z_for_next(self.z_index - 3)
		self:image(data.sprite, { dx = -(SPELL_SIZE - SPELL_INSET) - pop, dy = SPELL_INSET - pop, scale_x = ICON_SCALE * (hovered and 1.15 or 1) })
	end)
	self:spacing(-1)
	if hovered and self:tooltip(true, { id = tip_key }) then
		self:text(self:locale(data.name))
		if self.alt then
			self:color_gray()
			self:text(spell_id)
		end
		self:tooltip_end(self.shops.tip_x, self.shops.tip_y, false)
	end
end

---Draw a wrapping grid of spell icons, padding with empty boxes up to capacity.
---@private
---@param spells string[]
---@param per_row integer
---@param base_key integer
---@param capacity integer  total deck slots; extra slots beyond #spells are drawn empty
function sg:shops_draw_spell_grid(spells, per_row, base_key, capacity)
	if capacity == 0 then return end
	local i = 1
	while i <= capacity do
		local row_start = i
		self:begin_row(function()
			for _ = 1, per_row do
				if i > capacity then break end
				if spells[i] then
					self:shops_draw_spell(spells[i], base_key + i, true)
				else
					self:leaf(SPELL_SIZE, SPELL_SIZE, function()
						self:set_z_for_next(self.z_index - 1)
						self:image(SPELL_BOX, { scale_x = SPELL_SCALE })
					end)
					self:spacing(-1)
				end
				i = i + 1
			end
		end)
		if i == row_start then break end
	end
end

---Draw the wand detail body: two-column stats + wand sprite, then spell sections.
---@private
---@param stats {[string]:number}
---@param spells string[]
---@param always_cast string[]
---@param sprite string?  wand sprite path, nil = fallback icon
---@param per_row integer  deck spell icons per row
---@param alt boolean      alt mode: show frames instead of seconds
function sg:shops_draw_wand_body(stats, spells, always_cast, sprite, per_row, alt)
	-- Two-column stats: icons+labels on the left, values on the right, so all values
	-- start at the same x position regardless of label length.
	self:begin_row(function()
		self:begin_column(function()
			for _, s in ipairs(WAND_STATS) do
				self:begin_row(function()
					-- dy=2 aligns the 7px icon with the text baseline
					self:image(s.icon, { dy = 2 })
					self:spacing(2)
					self:text(self:locale(s.locale))
				end)
				self:spacing(-2)
			end
		end)

		self:spacing(6)

		self:begin_column(function()
			for _, s in ipairs(WAND_STATS) do
				local v = stats[s.key]
				if s.is_bool then
					-- nil = shuffle (Noita default = on)
					self:text(self:locale(v == 0 and "$menu_no" or "$menu_yes"))
				elseif v == nil then
					self:color_gray()
					self:text("?")
				else
					self:text(fmt_stat(s, v, alt))
				end
				self:spacing(-2)
			end
		end)

		-- Wand sprite to the right of the stats block.
		-- Rotated 270 degrees (CW 90), scaled up for readability.
		self:spacing(8)
		self:begin_column(function()
			self:image(sprite or WAND_ICON, { angle = -math.pi / 2, scale_x = WAND_SCALE })
		end)
	end)

	-- Always-cast section: label and spell icons inline on the same row.
	if #always_cast > 0 then
		self:spacing(4)
		self:begin_row(function()
			-- Wrap label in a column so it can be vertically centered against the
			-- spell cell height. AC_ICON is 7px + dy=2 = 9px advance; text ~9px.
			local label_dy = math.max(0, math.floor((SPELL_SIZE - 9) / 2))
			self:begin_column(function()
				self:spacing(label_dy)
				self:begin_row(function()
					self:image(AC_ICON, { dy = 2 })
					self:spacing(2)
					self:text(T.shops_wand_always_cast)
				end)
			end)
			self:spacing(4)
			for i, spell_id in ipairs(always_cast) do
				self:shops_draw_spell(spell_id, 60000 + i)
			end
		end)
	end

	-- Deck spells grid with empty slots for unused capacity.
	local capacity = math.max(#spells, stats.deck_capacity and math.floor(stats.deck_capacity + 0.5) or 0)
	if capacity > 0 then
		self:spacing(4)
		self:shops_draw_spell_grid(spells, per_row, 70000, capacity)
	end

	if capacity == 0 and #always_cast == 0 then
		self:spacing(2)
		self:color_gray()
		self:text(T.shops_no_data)
	end
end

---Draw a single shop item cell (icon + price).
---Wand cells are left-clickable to pin; hovering a wand shows its detail panel.
---@private
---@param item shop_item
---@param tip_key integer  stable numeric tooltip key, unique within one scrollbox pass
function sg:shops_draw_item(item, tip_key)
	local cell_sprite = item.is_wand and WAND_ICON or self.actions:get_data(item.id).sprite
	local hovered = self:is_hovered_cursor(ITEM_W - 1, ITEM_H)
	local is_pinned = item.is_wand and (self.shops.pinned_wand == item)

	self:leaf(ITEM_W, ITEM_H, function()
		self:begin_column(function()
			if is_pinned then self:color(0.6, 1, 0.6) end
			self:image(cell_sprite)
			self:spacing(1)
			if item.is_cheap then self:color(1, 0.85, 0.25) end
			self:text(tostring(item.price), { scale = 0.7 })
		end)
	end)

	if item.is_wand and not self:is_measuring() then
		if hovered then
			self.shops.hovered_wand = item
			if self:is_left_clicked() then
				self.shops.pinned_wand = is_pinned and nil or item
			elseif self:is_right_clicked() then
				self.shops.pinned_wand = nil
			end
		end
	end

	-- Wands show a full detail panel on hover; only tooltip non-wand items.
	if not item.is_wand and hovered and self:tooltip(true, { id = tip_key }) then
		self:text(self:locale(self.actions:get_data(item.id).name))
		if item.is_cheap then
			self:spacing(3)
			self:color(1, 0.85, 0.25)
			self:text(T.shops_sale)
		end
		self:tooltip_end(self.shops.tip_x, self.shops.tip_y, false)
	end
end

---Draw one mountain row: index label followed by all item cells.
---@private
---@param mountain shop_mountain
---@param mountain_index integer  1-based display number
function sg:shops_draw_mountain(mountain, mountain_index)
	self:begin_row(function()
		self:leaf(LABEL_W, ITEM_H, function()
			self:text(tostring(mountain_index))
		end)
		for item_i, item in ipairs(mountain.items) do
			self:shops_draw_item(item, mountain_index * 64 + item_i)
		end
	end)
	self:spacing(2)
end

---Draw the wand detail side panel for the active wand (pinned or hovered).
---Positioned to the right of the shops window. Called from shops_draw_overlays.
---@private
function sg:shops_draw_wand_panel()
	local wand = self.shops.pinned_wand or self.shops.hovered_wand
	if not wand then return end

	local is_pinned = wand == self.shops.pinned_wand
	local m = self.menu
	local stats = wand.stats or {}
	local spells = wand.spells or {}
	local always_cast = wand.always_cast or {}

	self:layout_at(self.shops.tip_x, m.start_y, function()
		-- window_group shares the wider of header/body content across both windows.
		-- begin_scrollbox advances the cursor during measure (noita_gui fix) so the
		-- group pre-measure pass picks up the body content width automatically.
		self:window_group("shops_wand_panel", function()
			self:begin_column(function()
				local _, hdr_h = self:window(function()
					self:begin_row(function()
						self:text(T.shops_wand)
						local lvl = stats.gun_level
						if lvl then
							self:spacing(2)
							self:color_gray()
							self:text("Lv." .. math.floor(lvl + 0.5))
						end
						if is_pinned then
							-- fill_width() is the group-shared inner width; pushes button right.
							self:row_fill_right(self:fill_width(), function()
								if self:button(T.close, true) then self.shops.pinned_wand = nil end
							end)
						end
					end)
					self:spacing(-2)
				end, { id = "shops_wand_header" })

				self:window_join()

				self:window(function()
					local body_w = math.max(1, self:fill_width())
					local per_row = math.max(1, math.floor(body_w / SPELL_PITCH))
					local scroll_cap = math.max(20, self.max_height - hdr_h + 1)
					self:begin_scrollbox("shops_wand_body", body_w, scroll_cap, function()
						self:shops_draw_wand_body(stats, spells, always_cast, wand.sprite, per_row, self.alt)
					end)
				end, { id = "shops_wand_body" })
			end)
		end)
	end)
end

---Draw the holy mountain shops panel (header + scrollbox).
function sg:shops_draw_window()
	-- Reset each frame; set during item drawing when a wand cell is under cursor.
	self.shops.hovered_wand = nil

	local m = self.menu
	local mountains = self.shop_pred.mountains
	local min_content = LABEL_W + MIN_ITEMS_SHOWN * ITEM_W
	local min_w = m._just_switched and min_content or math.max(m.shared_width, min_content)

	local header_width, header_h = self:window(function()
		self:text(T.Shops)
	end, { id = "shops_header", min_width = min_w })

	self.shops.tip_x = m.start_x + header_width + 2
	self.shops.tip_y = m.start_y - 1

	local scrollbox_cap = math.max(20, self.max_height - header_h + 1)

	self:window_join()
	self:window(function()
		local inner_w = math.max(min_content, self:fill_width())
		self.shops.content_w = inner_w
		self:begin_scrollbox("shops_list", inner_w, scrollbox_cap, function()
			if #mountains == 0 then
				self:text(T.shops_no_data)
				return
			end
			for i, mountain in ipairs(mountains) do
				self:shops_draw_mountain(mountain, i)
			end
		end)
	end, { id = "shops_window", min_width = header_width })

	self:menu_feed_width(math.max(min_w, header_width))
end

---Draw the wand detail overlay; called outside window_group so it doesn't affect shared width.
function sg:shops_draw_overlays()
	self:shops_draw_wand_panel()
end

return sg
