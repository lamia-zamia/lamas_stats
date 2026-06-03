---@class (exact) LS_Gui_materials
---@field visible_types { [number]:boolean}
---@field current_recipe integer?
---@field current_tag string?
---@field filter string
---@field width_reaction number   reaction panel width (computed from max material name length)
---@field reaction_show_output boolean
---@field reaction_scroll_height number
---@field tag_height number          tag scrollbox height (previous frame; drives the tag body window)
---@field header_width number   main panel header width from last frame (drives reaction x + shared_width)
---@field tip_x number          screen x for material tooltips (right of the rightmost visible panel)
---@field tip_y number          screen y for material tooltips (level with menu header)
---@field list_h number              actual list scrollbox height this frame (passed to right panel for vertical alignment)
---@field panel_start_y number      cursor y at the start of the main draw (drives reaction panel avail_h)
---@field main_header_h number      height of the main header window (drives reaction scroll height)
---@field reaction_header_h number  height of the reaction header window (previous frame)
---@field actual_reaction_w number  actual reaction header window width (previous frame; keeps body >= header)
---@field tag_header_h number       height of the tag viewer header window (previous frame)
---@field aplc APLC_recipes|false   AP/LC recipe shown in the header (false if parsing failed)
---@field apo_elixir apo_elixir_recipe?  apothecary-elixir recipe (only when Apotheosis is enabled)

---@class (exact) LS_Gui
---@field materials LS_Gui_materials
local materials = {
	materials = {
		visible_types = {},
		current_recipe = nil,
		current_tag = nil,
		filter = "",
		width_reaction = 200,
		reaction_show_output = false,
		list_h = 0,
		panel_start_y = 0,
		reaction_scroll_height = 100,
		tag_height = 10,
		header_width = 200,
		tip_x = 0,
		tip_y = 0,
		main_header_h = 0,
		reaction_header_h = 0,
		actual_reaction_w = 0,
		tag_header_h = 18,
		aplc = false,
	},
}

local ARROW_SPRITE = "mods/lamas_stats/files/gfx/arrow.png"
local ARROW_COL_WIDTH = 15 -- width reserved for the arrow + left/right margin
local TOOLTIP_SPRITE = "mods/lamas_stats/files/gfx/ui_9piece_tooltip.png"
local TOOLTIP_DARKER = "mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png"

local material_types_enum = dofile_once("mods/lamas_stats/files/scripts/material_types.lua") ---@type material_types_enum
local material_types = {}
for k, v in pairs(material_types_enum) do
	material_types[v] = k
	materials.materials.visible_types[v] = true
end

---@class gui_reaction_data
---@field using reactions_data[]
---@field producing reactions_data[]
---@field max_length number

local reactions_data = {} ---@type {[string]:gui_reaction_data}
local filtered_materials = nil

---Returns true if the name is a tag reference like "[tag]".
---@param name string
---@return boolean
local function is_tag(name)
	return name:sub(1, 1) == "["
end

---Truncates a string to a maximum length.
---@param str string
---@param max_len integer?
---@param suffix string?
---@return string
local function truncate(str, max_len, suffix)
	max_len = max_len or 32
	if #str <= max_len then return str end
	suffix = suffix or ".."
	local cut_len = max_len - #suffix
	if cut_len < 0 then cut_len = 0 end
	return string.sub(str, 1, cut_len) .. suffix
end

---Returns longest material name from an array of reaction datas.
---@private
---@param reaction_datas reactions_data[]
---@return number
function materials:reaction_datas_get_longest_name(reaction_datas)
	local max = 0
	for _, material_name, _ in self.mat.each_reaction_material_names(reaction_datas) do
		max = math.max(max, self:get_text_dim(truncate(material_name)))
		if not is_tag(material_name) then
			local material_data = self.mat:get_data_by_id(material_name)
			max = math.max(max, self:get_text_dim(self:get_material_name(material_data)))
		end
	end
	return max
end

---Replaces partial reactions with the material itself.
---@private
---@param material_id string
---@param material_name string
---@param list table
---@param i integer
function materials:reaction_replace_tags(material_id, material_name, list, i)
	local tag, suffix = self.mat.parse_tagged_cell(material_name)
	if not tag then return end

	local has_tag = self.mat:material_has_tag(material_id, tag)

	if not suffix or suffix == "" then
		if has_tag then
			list[i] = material_id
			return
		end
		local partial_match = self.mat.is_partial_match(material_name, material_id)
		if partial_match then
			list[i] = partial_match
			return
		end
	else
		if has_tag then
			local replace_name = material_id .. suffix
			if self.mat:does_material_exist(replace_name) then list[i] = replace_name end
			return
		elseif material_id:sub(-#suffix) == suffix then
			local base = material_id:sub(1, #material_id - #suffix)
			if base ~= "" and self.mat:material_has_tag(base, tag) then list[i] = material_id end
		end
	end
end

---Gets reaction data and replaces tag if its the material itself.
---@private
---@param material_id string
---@param fn fun(self, string):reactions_data[]
---@return reactions_data[]
function materials:get_reaction_replace_tags(material_id, fn)
	local original_data = fn(self, material_id)
	local data = {}

	for i, r in ipairs(original_data) do
		data[i] = {
			inputs = { unpack(r.inputs) },
			outputs = { unpack(r.outputs) },
			is_req = r.is_req,
			probability = r.probability,
		}
	end

	for list, material_name, i in self.mat.each_reaction_material_names(data) do
		self:reaction_replace_tags(material_id, material_name, list, i)
	end
	return data
end

---Gathers reaction data for a material.
---@private
---@param material_id string
function materials:gather_reaction_data(material_id)
	local using = self:get_reaction_replace_tags(material_id, self.mat.get_reactions_using)
	local producing = self:get_reaction_replace_tags(material_id, self.mat.get_reactions_producing)
	local max = 0
	for _, reaction_datas in ipairs({ using, producing }) do
		max = math.max(max, self:reaction_datas_get_longest_name(reaction_datas))
	end
	reactions_data[material_id] = {
		using = using,
		producing = producing,
		max_length = max,
	}
end

---Gets (and lazily computes) reaction data for a material.
---@param material_id string
---@return gui_reaction_data
function materials:get_reaction_data(material_id)
	if not reactions_data[material_id] then self:gather_reaction_data(material_id) end
	return reactions_data[material_id]
end

---Returns true if the material passes the current type filter and text filter.
---@param material_index integer
---@param filter string  pre-lowercased filter text
---@return boolean?
function materials:is_material_in_filter(material_index, filter)
	local material = self.mat:get_data(material_index)
	if not self.materials.visible_types[material.type] then return end
	if material.id:lower():find(filter, 1, true) then return true end
	if material.ui_name:lower():find(filter, 1, true) then return true end
	if self:locale(material.ui_name):lower():find(filter, 1, true) then return true end
end

---Returns (and lazily builds) the filtered material list.
---@private
---@return integer[]
function materials:get_filtered_materials()
	if not filtered_materials then
		local filter = self.materials.filter:lower()
		local result = {}
		for material_index, _ in pairs(self.mat.data) do
			if self:is_material_in_filter(material_index, filter) then result[#result + 1] = material_index end
		end
		filtered_materials = result
	end
	return filtered_materials
end

---Tooltip anchor: right of the rightmost visible panel.
---@private
---@return number x, number y
function materials:materials_tip_anchor()
	return self.materials.tip_x, self.materials.tip_y
end

---Draws a material icon at cursor position with the material's tint color.
---@private
---@param mat material_data
function materials:materials_draw_icon(mat)
	if mat.color then self:color(mat.color.r, mat.color.g, mat.color.b, mat.color.a) end
	self:image(mat.icon, { dy = 1 })
end

---Material row; hover coloring: yellow = hovered, green = selected, bright green = selected+hovered.
---@private
---@param material_index integer
---@param content_w number  full row width (for hover rect)
function materials:materials_draw_material(material_index, content_w)
	local mat = self.mat:get_data(material_index)
	local is_current = self.materials.current_recipe == material_index
	local hovered = self:is_hovered_cursor(content_w, 10)

	self:leaf(content_w, 10, function()
		self:begin_row(function()
			self:materials_draw_icon(mat)
			self:spacing(1)
			local mat_name = self:get_material_name(mat)
			if is_current and hovered then
				self:color(0.6, 1, 0.4)
			elseif is_current then
				self:color(0.4, 1, 0.6)
			elseif hovered then
				self:color_yellow()
			end
			self:text(mat_name)
			self:spacing(3)
			self:color_gray()
			self:text("(" .. mat.id .. ")")
		end)
	end)

	if not self:is_measuring() and hovered then
		if self:is_left_clicked() then
			self.materials.current_recipe = material_index
			self.materials.current_tag = nil
			self:reset_scroll("materials_reactions")
			self.materials.actual_reaction_w = 0
		elseif self:is_right_clicked() then
			self.materials.current_recipe = nil
			self.materials.current_tag = nil
		end

		-- Tooltip only when this item is NOT the open recipe.
		-- Re-read current_recipe: left-click may have just set it to material_index.
		-- When the reaction viewer is open, use the default darkest tooltip sprite so
		-- the popup is readable over the reaction panel; otherwise use the lighter custom one.
		local tip_sprite = self.materials.current_recipe and nil or TOOLTIP_SPRITE
		if self.materials.current_recipe ~= material_index and self:tooltip(true, { id = material_index, sprite = tip_sprite, border = 0 }) then
			local reaction_data = self:get_reaction_data(mat.id)
			self:material_row(material_index, true)
			self:text(string.format("%s: %d, %s: %d", T.using, #reaction_data.using, T.producing, #reaction_data.producing))
			if not self.materials.current_recipe then
				self:color_gray()
				self:text(T.reaction_window_d)
				self:color_gray()
				self:text(T.PressShiftToSeeMore)
			end
			local ax, ay = self:materials_tip_anchor()
			self:tooltip_end(ax, ay, false)
		end
	end
end

---Draws all filtered materials inside the main scrollbox.
---@private
---@param content_w number
function materials:materials_draw_list(content_w)
	for _, material_index in ipairs(self:get_filtered_materials()) do
		self:materials_draw_material(material_index, content_w)
	end
end

---Draws one reaction item (tag link or material icon+name) centered in col_w.
---@private
---@param material string  material id or "[tag]" name
---@param col_w number     column pixel width (for centering)
function materials:materials_draw_reaction_item(material, col_w)
	if is_tag(material) then
		local text_w = self:get_text_dim(material)
		local hovered = false
		self:begin_row(function()
			self:spacing(math.max(0, (col_w - text_w) / 2))
			hovered = self:is_hovered_cursor(text_w, 10)
			if hovered then self:color_yellow() end
			self:text(material)
		end)
		if not self:is_measuring() and hovered and self:is_left_clicked() then
			self.materials.current_tag = material
			self:reset_scroll("materials_tags")
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/button_click", 0, 0)
		end
	else
		local mat = self.mat:get_data_by_id(material)
		local mat_name = self.alt and truncate(mat.id) or self:get_material_name(mat)
		local text_w = self:get_text_dim(mat_name)
		self:begin_row(function()
			self:spacing(math.max(0, (col_w - text_w) / 2 - 9)) -- center text; 9 = icon(8)+gap(1)
			self:materials_draw_icon(mat)
			self:spacing(1)
			self:text(mat_name)
		end)
	end
end

---Reaction row (inputs -> arrow -> outputs); fixed-width leaves keep columns aligned.
---@private
---@param reaction reactions_data
---@param col_w number  width of each input/output column leaf
function materials:materials_draw_reaction(reaction, col_w)
	local rows = math.max(#reaction.inputs, #reaction.outputs)
	local row_h = rows * 10
	local arrow_center_dy = 10 * (rows - 1) / 2

	self:begin_row(function()
		-- Input column
		self:leaf(col_w, row_h, function()
			self:begin_column(function()
				for _, input in ipairs(reaction.inputs) do
					self:materials_draw_reaction_item(input, col_w)
				end
			end)
		end)

		-- Arrow column (vertically centered)
		self:leaf(ARROW_COL_WIDTH, row_h, function()
			self:begin_column(function()
				self:spacing(arrow_center_dy)
				if reaction.is_req then self:color(1, 0.5, 0) end
				local arrow_hovered = self:is_hovered_cursor(8, 8)
				self:image(ARROW_SPRITE)
				if not self:is_measuring() and arrow_hovered and self:tooltip(true) then
					self:text(string.format("%s: %d", T.speed, reaction.probability))
					if reaction.is_req then
						self:color(1, 0.5, 0)
						self:text(T.req_text)
					end
					local ax, ay = self:cursor_screen()
					self:tooltip_end(ax, ay, true)
				end
			end)
		end)

		-- Output column
		self:leaf(col_w, row_h, function()
			self:begin_column(function()
				for _, output in ipairs(reaction.outputs) do
					self:materials_draw_reaction_item(output, col_w)
				end
			end)
		end)
	end)
end

---1px separator line; drawn via overlay so it doesn't inflate row height.
---@private
---@param width number
function materials:materials_separator(width)
	self:overlay(function()
		self:image(self.c.px, { alpha = 0.4, scale_x = width, scale_y = 1 })
	end)
	self:spacing(1)
end

---Reactions list; uses pre-captured data so state can change safely mid-frame.
---@private
---@param reactions reactions_data[]
---@param scrollbox_w number  inner width of the scrollbox (for separator scaling)
function materials:materials_draw_reactions_content(reactions, scrollbox_w)
	local col_w = (scrollbox_w - ARROW_COL_WIDTH) / 2

	if #reactions > 0 then
		for i, reaction in ipairs(reactions) do
			self:materials_draw_reaction(reaction, col_w)
			if i < #reactions then
				self:spacing(1)
				self:materials_separator(scrollbox_w)
			end
		end
	else
		self:text("None")
	end
end

---Draws tagged materials list inside the tag scrollbox.
---@private
function materials:materials_draw_tagged_materials()
	local material_list = self.mat.get_tagged_materials(self.materials.current_tag)
	for _, material_name in ipairs(material_list) do
		self:material_row(CellFactory_GetType(material_name), true)
	end
end

---Right-side reaction and tag panels; layout state captured at call time to isolate button interactions.
---@private
---@param panel_right_x number  screen x where the right panels start
---@param panel_start_y number  screen y shared with the main panel top edge
---@param list_box_h number     actual list scrollbox height this frame (drives avail_h for alignment)
function materials:materials_draw_right_panel(panel_right_x, panel_start_y, list_box_h)
	-- Capture everything we need for this frame's draw now, before any button interactions.
	local recipe_index = self.materials.current_recipe --[[@as integer]]
	local current_tag = self.materials.current_tag
	local reaction_show_output = self.materials.reaction_show_output
	local mat = self.mat:get_data(recipe_index)
	local reaction_data = self:get_reaction_data(mat.id)

	-- Reaction panel width: use the previous frame's actual header width so the body
	-- always matches even when name+buttons overflow the estimated reaction_w.
	self.materials.width_reaction = math.max(200, math.min(reaction_data.max_length * 2 + 50, 400))
	local reaction_w = math.max(self.materials.width_reaction, self.materials.actual_reaction_w)
	local scrollbox_w = reaction_w - self.options.window_padding * 2

	-- Reaction scrollbox height: cap at content height so the panel doesn't stretch
	-- unnecessarily; but allow up to avail_h so it matches the main panel when full.
	-- panel_start_y is where materials content starts (after menu bar + spacing(-1)).
	-- The reaction panel starts at m.start_y, so it has that extra offset available.
	local bar_offset = panel_start_y - self.menu.start_y
	local avail_h = math.max(20, bar_offset + self.materials.main_header_h + list_box_h - self.materials.reaction_header_h)
	local reactions = reaction_show_output and reaction_data.producing or reaction_data.using
	local _, content_h = self:measure(function()
		self:materials_draw_reactions_content(reactions, scrollbox_w)
	end)
	local reaction_scroll_h
	if current_tag then
		-- When a tag panel is open, both scrollboxes together must fill avail_h so
		-- the combined bottom aligns with the main window.
		-- Per-window overhead added by the tag panel:
		--   two spacing(-1) overlaps cancel 2px, tag header window adds thh + 2*pad.
		-- Net budget for the two scrollboxes: avail_h - thh - 2*pad + 2.
		local thh = self.materials.tag_header_h
		local total_split = math.max(30, avail_h - thh - 2 * self.options.window_padding + 2)
		local tag_list = self.mat.get_tagged_materials(current_tag)
		local _, tag_content_h = self:measure(function()
			for _, material_name in ipairs(tag_list) do
				self:material_row(CellFactory_GetType(material_name), true)
			end
		end)
		local tag_scroll_h = math.max(10, math.min(tag_content_h, math.floor(total_split * 0.45)))
		self.materials.tag_height = tag_scroll_h
		reaction_scroll_h = math.max(1, math.min(content_h, total_split - tag_scroll_h))
	else
		reaction_scroll_h = math.max(1, math.min(avail_h, content_h))
	end
	self.materials.reaction_scroll_height = reaction_scroll_h

	local mat_name = self.alt and truncate(mat.id) or self:get_material_name(mat)

	self:layout_at(panel_right_x, self.menu.start_y, function()
		self:begin_column(function()
			local actual_reaction_w, rxh = self:window(function()
				local text_w = self:get_text_dim(mat_name)
				self:begin_row(function()
					self:spacing(math.max(0, (scrollbox_w - text_w) / 2 - 9)) -- 9 = icon(8)+gap(1)
					self:materials_draw_icon(mat)
					self:spacing(1)
					self:text(mat_name)
					self:row_fill_right(scrollbox_w, function()
						if mat.tags then
							-- Plain hoverable text for tags (no ninepiece button frame)
							local tags_text = "[tags]"
							local tags_w = self:get_text_dim(tags_text)
							local tags_hovered = self:is_hovered_cursor(tags_w, 9)
							if tags_hovered then self:color_yellow() end
							self:text(tags_text)
							if tags_hovered and self:tooltip(true) then
								for tag, _ in pairs(mat.tags) do
									self:text(tag)
								end
								self:tooltip_end(nil, nil, true)
							end
							self:spacing(2)
						end
						local close_clicked = self:button(T.close, true)
						if close_clicked then
							self.materials.current_recipe = nil
							self.materials.current_tag = nil
						end
					end)
				end)

				self:spacing(-3)
				local id_text = "(" .. mat.id .. ")"
				self:color_gray()
				self:text_centered(id_text, scrollbox_w)

				-- active=true -> normal (not selected); active=false -> gray (selected)
				local using_text = string.format("%s (%d)", T.using, #reaction_data.using)
				local producing_text = string.format("%s (%d)", T.producing, #reaction_data.producing)
				local gap = 3
				local btn_w = math.max(1, math.floor((scrollbox_w - gap * 3) / 2))
				self:begin_row(function()
					self:spacing(gap)
					local using_clicked = self:button(using_text, reaction_show_output, { min_width = btn_w })
					if using_clicked then
						self.materials.reaction_show_output = false
						self.materials.current_tag = nil
					end
					self:spacing(gap)
					local producing_clicked = self:button(producing_text, not reaction_show_output, { min_width = btn_w })
					if producing_clicked then
						self.materials.reaction_show_output = true
						self.materials.current_tag = nil
					end
				end)
				self:spacing(-2)
			end, { id = "materials_reaction_header", min_width = reaction_w })
			self.materials.actual_reaction_w = actual_reaction_w
			self.materials.reaction_header_h = rxh

			self:window_join()

			-- Use actual_reaction_w so the body always matches the header width.
			local body_scrollbox_w = actual_reaction_w - self.options.window_padding * 2
			self:window(function()
				self:begin_scrollbox("materials_reactions", body_scrollbox_w, reaction_scroll_h, function()
					-- Use captured reaction data: current_recipe may have been cleared above.
					self:materials_draw_reactions_content(reactions, body_scrollbox_w)
				end)
			end, { id = "materials_reaction_body", min_width = actual_reaction_w })

			if current_tag then
				self:window_join()

				local _, tag_hdr_h = self:window(function()
					self:begin_row(function()
						self:spacing(math.max(0, (scrollbox_w - self:get_text_dim(current_tag)) / 2))
						self:text(current_tag)
						self:row_fill_right(scrollbox_w, function()
							local close_tag = self:button(T.close, true)
							if close_tag then self.materials.current_tag = nil end
						end)
					end)
					self:spacing(-2)
				end, { id = "materials_tags_header", min_width = actual_reaction_w })
				self.materials.tag_header_h = tag_hdr_h

				self:window_join()

				local tag_scroll_h = self.materials.tag_height
				self:window(function()
					self:begin_scrollbox("materials_tags", scrollbox_w, tag_scroll_h, function()
						-- Use captured current_tag: state may have changed above.
						local tag_list = self.mat.get_tagged_materials(current_tag)
						for _, material_name in ipairs(tag_list) do
							self:material_row(CellFactory_GetType(material_name), true)
						end
					end)
				end, { id = "materials_tags_body", min_width = actual_reaction_w })
			end
		end)
	end)
end

-- Shared recipe layout (AP/LC and apothecary-elixir tooltips):
--   result material
--   [6 px indent] ingredient 1
--   [6 px indent] + ingredient 2   (prob%)
--   [6 px indent] ingredient 3
---@private
---@param recipe {result:integer, mats:integer[], prob:integer}
function materials:fungal_recipe_block(recipe)
	self:material_row(recipe.result, false)
	self:spacing(2)
	-- Indent the three ingredient lines as a group.
	self:begin_row(function()
		self:spacing(6)
		self:begin_column(function()
			self:material_row(recipe.mats[1], self.alt)
			self:spacing(1)
			-- The "+" line shares a row with ingredient 2 and the probability.
			self:begin_row(function()
				self:color_gray()
				self:text("+")
				self:spacing(2)
				self:material_inline_content(recipe.mats[2], self.alt)
				self:spacing(3)
				self:color_gray()
				self:text(string.format("(%d%%)", recipe.prob))
			end)
			self:spacing(1)
			self:material_row(recipe.mats[3], self.alt)
		end)
	end)
end

---@private
function materials:fungal_ap_lc_tooltip()
	self:fungal_recipe_block(self.materials.aplc.ap)
	self:spacing(8)
	self:fungal_recipe_block(self.materials.aplc.lc)
	self:alt_hint()
end

---@private
function materials:fungal_apo_elixir_tooltip()
	self:fungal_recipe_block(self.materials.apo_elixir)
	self:alt_hint()
end

---AP + LC icon pair with hover highlight and tooltip.
---@private
function materials:fungal_ap_lc_draw()
	local ap_icon = self.mat:get_data(self.materials.aplc.ap.result)
	local lc_icon = self.mat:get_data(self.materials.aplc.lc.result)
	local W, H = 18, 9
	local hovered = self:is_hovered_cursor(W, H)
	local spr = hovered and self.options.button_sprite_hl or self.options.button_sprite
	self:leaf(W, H, function()
		self:overlay(function()
			if ap_icon.color then self:color(ap_icon.color.r, ap_icon.color.g, ap_icon.color.b, ap_icon.color.a) end
			self:image(ap_icon.icon, { dy = 1 })
			if lc_icon.color then self:color(lc_icon.color.r, lc_icon.color.g, lc_icon.color.b, lc_icon.color.a) end
			self:image(lc_icon.icon, { dy = 1 })
		end)
		self:ninepiece(W, H, { z = self.z_index + 5, sprite = spr, margin = 2.5, dx = -1 })
	end)
	if hovered and self:tooltip(true, { sprite = TOOLTIP_DARKER, border = 0 }) then
		self:fungal_ap_lc_tooltip()
		local ax, ay = self:materials_tip_anchor()
		self:tooltip_end(ax, ay, false)
	end
end

---Apothecary-elixir icon with hover highlight and tooltip.
---@private
function materials:fungal_apo_elixir_draw()
	local elixir = self.mat:get_data(self.materials.apo_elixir.result)
	local W, H = 9, 9
	local hovered = self:is_hovered_cursor(W, H)
	local spr = hovered and self.options.button_sprite_hl or self.options.button_sprite
	self:leaf(W, H, function()
		self:overlay(function()
			if elixir.color then self:color(elixir.color.r, elixir.color.g, elixir.color.b, elixir.color.a) end
			self:image(elixir.icon, { dy = 1 })
		end)
		self:ninepiece(W, H, { z = self.z_index + 5, sprite = spr, margin = 1 })
	end)
	if hovered and self:tooltip(true, { sprite = TOOLTIP_DARKER, border = 0 }) then
		self:fungal_apo_elixir_tooltip()
		local ax, ay = self:materials_tip_anchor()
		self:tooltip_end(ax, ay, false)
	end
end

---Draws the materials panel.
function materials:materials_draw_window()
	local m = self.menu
	-- Cursor y here is where materials content starts (after menu bar + spacing(-1)).
	-- Pass it to the reaction panel so both columns share the same top edge.
	local _, panel_start_y = self:cursor_local()
	self.materials.panel_start_y = panel_start_y

	-- On the frame a window opens, don't enforce shared_width (content hasn't measured yet).
	local min_w = m._just_switched and 0 or (m.shared_width or 0)
	local padding = self.options.window_padding

	-- Compute icon row width before the window: measure() uses DIR_H, so each stacked
	-- row must be measured individually (can't measure multiple begin_rows together).
	local icon_inner_w
	if self.materials.apo_elixir or self.materials.aplc then
		local checkboxes_w = self:measure(function()
			for material_type, type_name in ipairs(material_types) do
				self:checkbox(type_name, self.materials.visible_types[material_type])
				self:spacing(2)
			end
		end)
		local search_w = self:measure(function()
			self:text(T.search .. ":")
			self:spacing(5)
			self:leaf(100, 9, function() end)
		end)
		local icons_w = self:measure(function()
			if self.materials.apo_elixir then
				self:fungal_apo_elixir_draw()
				self:spacing(4)
			end
			if self.materials.aplc then self:fungal_ap_lc_draw() end
		end)
		icon_inner_w = math.max(math.max(checkboxes_w, search_w + icons_w), math.max(0, min_w - padding * 2))
	end

	local header_width, main_header_h = self:window(function()
		self:begin_row(function()
			for material_type, type_name in ipairs(material_types) do
				local clicked = self:checkbox(type_name, self.materials.visible_types[material_type])
				if clicked then
					self.materials.visible_types[material_type] = not self.materials.visible_types[material_type]
					filtered_materials = nil
				end
				self:spacing(2)
			end
		end)
		self:spacing(2)

		self:begin_row(function()
			self:text(T.search .. ":")
			self:spacing(5)
			-- cursor_screen() gives the absolute screen position the textbox needs.
			local tx, ty = self:cursor_screen()
			self:leaf(100, 9, function()
				if not self:is_measuring() then
					local new_filter = self.textbox:draw_textbox(tx, ty, self.z_index + 1, 100, 9, self.materials.filter)
					if new_filter ~= self.materials.filter then
						self.materials.filter = new_filter
						filtered_materials = nil
					end
				end
			end)
			if self.materials.apo_elixir or self.materials.aplc then
				self:row_fill_right(icon_inner_w, function()
					if self.materials.apo_elixir then
						self:fungal_apo_elixir_draw()
						self:spacing(4)
					end
					if self.materials.aplc then self:fungal_ap_lc_draw() end
				end)
			end
		end)
	end, { id = "materials_header", min_width = min_w })

	self.materials.header_width = header_width
	self.materials.main_header_h = main_header_h

	self:window_join()

	-- Scrollbox cap: max_height is the total budget for the whole panel (header + list).
	-- Subtract the header window height so all panels bottom-align at the same screen y.
	local scrollbox_cap = math.max(20, self.max_height - main_header_h + 1)
	self:window(function()
		-- fill_width() = 0 during the group's natural-width pass, so the group
		-- accumulates the true content width rather than locking to the previous
		-- panel's inflated width.
		local inner_w = math.max(1, self:fill_width())
		local _, content_h = self:begin_scrollbox("materials_list", inner_w, scrollbox_cap, function()
			self:materials_draw_list(inner_w)
		end)
		self.materials.list_h = math.min(content_h, scrollbox_cap)
	end, { id = "materials_window", min_width = header_width })

	-- Tooltip anchor: always right of the main panel so it doesn't jump when the reaction panel opens.
	self.materials.tip_x = m.start_x + header_width + 2
	self.materials.tip_y = m.start_y
end

---Draws reaction/tag overlay panels; called outside window_group so they don't affect shared width.
---@private
function materials:materials_draw_overlays()
	if not self.materials.current_recipe then return end
	local m = self.menu
	self:materials_draw_right_panel(m.start_x + self.materials.header_width + 2, self.materials.panel_start_y, self.materials.list_h)
end

local checker_spawned = false

---Spawns an entity with material area checkers (bound to hotkey in gui_main.lua).
function materials:spawn_getter()
	checker_spawned = true
	local x, y = DEBUG_GetMouseWorld()
	local parent = EntityCreateNew()
	EntitySetTransform(parent, x, y)
	EntityAddComponent2(parent, "LifetimeComponent", {
		lifetime = 2,
	})
	-- self.mat.data is keyed by CellFactory material type (numeric, 0-based and
	-- possibly gapped with modded materials), so iterate with pairs rather than #.
	for material_type in pairs(self.mat.data) do
		local entity = EntityCreateNew()
		EntitySetTransform(entity, x, y)
		EntityAddComponent2(entity, "LuaComponent", {
			script_material_area_checker_success = "mods/lamas_stats/files/scripts/gui/materials/material_checker.lua",
		})
		local maac = EntityAddComponent2(entity, "MaterialAreaCheckerComponent", {
			material = material_type,
			material2 = material_type,
			look_for_failure = false,
			count_min = 1,
			update_every_x_frame = 1,
		})
		ComponentSetValue2(maac, "area_aabb", 0, 0, 0.1, 0.1)
		EntityAddChild(parent, entity)
	end
end

---Checks if material checkers found anything and opens the materials window on a match.
function materials:check_for_checkers()
	local detector = GlobalsGetValue("LAMAS_STATS_DETECTOR", "")
	local is_found = detector ~= ""
	if is_found then
		self.show = true
		self.menu.opened = true
		self.menu.current = "materials"
		self.materials.current_recipe = tonumber(detector)
		GlobalsSetValue("LAMAS_STATS_DETECTOR", "")
	end
	if checker_spawned then GamePlaySound("data/audio/Desktop/ui.bank", is_found and "ui/item_move_success" or "ui/item_move_denied", 0, 0) end
	checker_spawned = false
end

---Clears reaction data cache on language change.
---@param did_language_changed boolean
function materials:materials_update(did_language_changed)
	if did_language_changed then reactions_data = {} end
end

---Parses the AP/LC and (when Apotheosis is enabled) apothecary-elixir recipes shown
---in the materials header. Called once at world init.
function materials:materials_parse_recipes()
	local aplc = dofile_once("mods/lamas_stats/files/scripts/aplc.lua") ---@type APLC
	local aplc_recipe = aplc:get()
	self.materials.aplc = aplc.failed and false or aplc_recipe
	if ModIsEnabled("Apotheosis") then
		self.materials.apo_elixir = dofile_once("mods/lamas_stats/files/scripts/apo_elixir.lua")
	end
end

return materials
