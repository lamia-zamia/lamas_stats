---@class (exact) LS_Gui
local pg = {}

---Draws the alt-mode id line (if any) followed by the wrapped description lines centred within `width`.
---@private
---@param id string
---@param description_lines string[]
---@param width number
function pg:perk_tip_description_block(id, description_lines, width)
	if self.alt then self:perk_tip_line(id, width, true) end
	for i = 1, #description_lines do
		self:perk_tip_line(description_lines[i], width)
	end
end

---Tooltip for an already-picked / predicted perk. Recorded by the immediate-
---mode tooltip block (see perks_icon); lines are centred within the widest line.
---@private
---@param perk perk_data
function pg:perks_current_perk_tooltip(perk)
	local ui_name = self:locale(perk.ui_name)
	local description_lines = self:split_string(self:locale(perk.ui_description), 200)
	local picked_count = T.PerkCount .. ": " .. perk.picked_count
	local id = self.alt and string.format("(%s)", perk.id) or ""
	local reminder = self.alt and "" or T.PressShiftToSeeMore
	local longest = math.max(self:get_text_dim(ui_name), self:get_text_dim(id), self:get_text_dim(reminder))
	longest = math.max(longest, self:get_longest_text(description_lines, perk.ui_description))

	self:perk_tip_header(perk, ui_name, longest)
	self:perk_tip_description_block(id, description_lines, longest)

	self:spacing(2)
	self:color(1, 1, 1)
	self:text_centered(picked_count, longest)

	if self.alt then
		self:perk_tip_line(T.Max .. ": " .. perk.max, longest, true)
	else
		self:alt_hint()
	end
end

---Tooltip for a perk lying on the ground near the player. Adds the lottery tag
---and predicted always-cast spell on top of the normal perk tooltip.
---@private
---@param nearby_perk nearby_perks_data
function pg:perks_nearby_tooltip(nearby_perk)
	local perk = self.perks.data:get_data(nearby_perk.id)
	local ui_name = self:locale(perk.ui_name)
	local description_lines = self:split_string(self:locale(perk.ui_description), 200)
	local picked_count = T.PerkCount .. ": " .. perk.picked_count
	local id = self.alt and string.format("(%s)", perk.id) or ""
	local reminder = self.alt and "" or T.PressShiftToSeeMore
	local always_cast_result = nearby_perk.cast
		or (self.config.always_show_always_cast and self.perks.nearby:PredictAlwaysCast(nearby_perk.x, nearby_perk.y) or nil)
	local always_cast_text = always_cast_result and T.lamas_stats_perks_always_cast .. ":" or nil
	local longest = math.max(self:get_text_dim(ui_name), self:get_text_dim(id), self:get_text_dim(reminder))
	if always_cast_text then longest = math.max(longest, self:get_text_dim(always_cast_text)) end
	longest = math.max(longest, self:get_longest_text(description_lines, perk.ui_description))

	self:perk_tip_header(perk, ui_name, longest)

	if nearby_perk.lottery and self.config.enable_nearby_lottery then
		local lottery = "[" .. T.LotteryWin .. "]"
		self:color(0.58, 0.85, 0.88)
		self:text_centered(lottery, longest)
	end

	self:perk_tip_description_block(id, description_lines, longest)

	if self.config.enable_nearby_always_cast and always_cast_text then
		local cast_data = self.actions:get_data(always_cast_result --[[@as string]])
		self:spacing(3)
		self:perk_tip_line(self:locale("$perk_always_cast"), longest, true)

		-- Always-cast label + spell icon, on one centred row.
		local _, text_height = self:get_text_dim(always_cast_text)
		self:begin_centered_row(longest, function()
			self:text(always_cast_text)
			self:spacing(3)
			self:tooltip_icon_cell(cast_data.sprite, text_height)
		end)

		if self.alt then
			self:perk_tip_line(self:locale(cast_data.name), longest)
			self:perk_tip_line("(" .. always_cast_result .. ")", longest, true)
			local cast_description = self:split_string(self:locale(cast_data.description), longest)
			for i = 1, #cast_description do
				self:perk_tip_line(cast_description[i], longest)
			end
		end
	end

	if self.alt then
		self:spacing(5)
		self:color(1, 1, 1)
		self:text_centered(picked_count, longest)
		self:perk_tip_line(T.Max .. ": " .. perk.max, longest, true)
	else
		self:alt_hint()
	end
end

---Draws the perks physically near the player in wrapping rows (matching
---per_row from the scrollbox), with a glow behind guaranteed lottery wins.
---Tooltip key is numeric (the index), so nothing is allocated per icon/frame.
---@private
function pg:perks_draw_nearby()
	local data = self.perks.nearby.data
	local per_row = self.perk.per_row
	local i = 1
	while i <= #data do
		local row_start = i
		self:begin_row(function()
			for _ = 1, per_row do
				local nearby_perk = data[i] ---@type nearby_perks_data
				if not nearby_perk then break end
				local perk = self.perks.data:get_data(nearby_perk.id)
				local hovered = self:is_hovered_cursor(16, 16)
				if nearby_perk.lottery and self.config.enable_nearby_lottery then
					self:overlay(function()
						self:set_z_for_next(self.z_index - 50)
						self:image("mods/lamas_stats/files/gfx/lottery_glow.png")
					end)
				end
				self:leaf(16, 16, function()
					local pop = hovered and 1.2 or 0
					self:image(perk.perk_icon, { dx = -pop, dy = -pop, scale_x = hovered and 1.15 or 1 })
				end)
				self:spacing(1)
				if hovered and self:tooltip(true, { id = i, sprite = "mods/lamas_stats/files/gfx/ui_9piece_tooltip_darker.png", border = 0 }) then
					self:perks_nearby_tooltip(nearby_perk)
					local ax, ay = self:perk_tip_anchor()
					self:tooltip_end(ax, ay, false)
				end
				i = i + 1
			end
		end)
		if row_start == i then break end
		self:spacing(1)
	end
end

return pg
