---@class (exact) LS_Gui
local ft = {}

local ARROW_WIDTH = 8

-- Shared recipe layout (AP/LC and apothecary-elixir tooltips):
--   result material
--   [6 px indent] ingredient 1
--   [6 px indent] + ingredient 2   (prob%)
--   [6 px indent] ingredient 3

---@private
---@param recipe {result:integer, mats:integer[], prob:integer}
function ft:fungal_recipe_block(recipe)
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
function ft:fungal_ap_lc_tooltip()
	self:fungal_recipe_block(self.fs.aplc.ap)
	self:spacing(8)
	self:fungal_recipe_block(self.fs.aplc.lc)
	self:alt_hint()
end

---@private
function ft:fungal_apo_elixir_tooltip()
	self:fungal_recipe_block(self.fs.apo_elixir)
	self:alt_hint()
end

---@private
---@param shift shift
---@param i integer
function ft:fungal_draw_past_tooltip(shift, i)
	-- row_count drives vertical centering in the column helpers
	self.fungal.row_count = self:fungal_calculate_row_count(shift.from, shift.to, false)

	self:begin_row(function()
		self:color(0.7, 0.7, 0.7)
		self:text(self:fungal_shift_label(i))
		if shift.flask then
			self:spacing(3)
			self:color(0.7, 0.7, 0.6)
			self:text("(" .. T.ShiftHasBeenModified .. ")")
		end
	end)
	self:spacing(3)

	-- from / arrow / to side by side; each column auto-sizes to its widest line.
	self:begin_row(function()
		self:fungal_from_materials_column(shift.from, false, self.alt)
		self:spacing(self.alt and 3 or 15)
		self:fungal_arrow_column()
		self:spacing(ARROW_WIDTH)
		self:fungal_to_materials_column(shift.to, false, self.alt)
	end)

	self:alt_hint()
end

---Draws the main from/arrow/to block for one (sub-)shift.
---Sets fungal.row_count for the caller to read after returning.
---@private
---@param shift shift|failed_shift
---@param max_from_w number? widest from-column across all sub-shifts (for arrow alignment)
---@param indent number? leading pixels before the from-column (default 0)
function ft:fungal_draw_future_tooltip_shift(shift, max_from_w, indent)
	indent = indent or 0
	self.fungal.row_count = self:fungal_calculate_row_count(shift.from, shift.to, shift.flask)
	local actual_from_w, _ = self:fungal_get_longest_text_in_shift(shift, 0, 0, false, self.alt)
	local pad = max_from_w and math.max(0, max_from_w - (indent + actual_from_w)) or 0
	self:begin_row(function()
		if indent > 0 then self:spacing(indent) end
		self:fungal_from_materials_column(shift.from, shift.flask == "from", self.alt)
		self:spacing((self.alt and 3 or 15) + pad)
		self:fungal_arrow_column()
		self:spacing(ARROW_WIDTH)
		self:fungal_to_materials_column(shift.to, shift.flask == "to", self.alt)
	end)
end

---"If fail" sub-block: held material -> result shift.
---@private
---@param shift shift
---@param max_from_w number?
function ft:fungal_draw_future_tooltip_shift_failed(shift, max_from_w)
	self:begin_row(function()
		self:text(T.lamas_stats_fungal_if_fail)
		self:spacing(3)
		self:fungal_held_material_inline_content({ 1, 1, 0.4 })
		self:spacing(3)
		self:text(T.lamas_stats_then)
	end)
	self:spacing(3)
	self:fungal_draw_future_tooltip_shift(shift.failed, max_from_w, 3)
end

---"If force-fail" sub-block: held material IS material -> result shift.
---@private
---@param shift shift
---@param max_from_w number?
function ft:fungal_draw_future_tooltip_shift_force_failed(shift, max_from_w)
	self:begin_row(function()
		local label = shift.failed and T.OrIf or T.lamas_stats_if
		self:text(label)
		self:spacing(3)
		self:fungal_held_material_inline_content({ 0.7, 0.7, 0.7 })
		self:spacing(3)
		self:text(T.Is)
		self:spacing(3)
		local mat = shift.flask == "from" and shift.to or shift.from[1]
		self:material_inline_content(mat, false)
	end)
	self:spacing(3)
	self:fungal_draw_future_tooltip_shift(shift.force_failed, max_from_w, 3)
end

---Greedy sub-block: shows what gold and holy grass shift into.
---@private
---@param greedy greedy_shift
---@param max_from_w number?
function ft:fungal_draw_future_tooltip_greedy(greedy, max_from_w)
	self.fungal.row_count = 2
	self:color_gray()
	self:text(T.lamas_stats_fungal_greedy)
	local gold_type = CellFactory_GetType("gold")
	local grass_type = CellFactory_GetType("grass_holy")
	local greedy_from = { gold_type, grass_type }
	local greedy_col_w = self:fungal_get_longest_material_name(greedy_from, 0)
	local pad = max_from_w and math.max(0, max_from_w - (3 + greedy_col_w)) or 0
	self:begin_row(function()
		self:spacing(3)
		self:fungal_from_materials_column(greedy_from, false, false)
		self:spacing(3 + pad)
		self:fungal_arrow_column()
		self:spacing(15)
		self:begin_column(function()
			self:material_row(greedy.gold)
			self:spacing(1)
			self:material_row(greedy.grass)
			self:spacing(1)
		end)
	end)
end

---@private
---@param shift shift
---@param i integer
function ft:fungal_draw_future_tooltip(shift, i)
	self:begin_row(function()
		self:spacing(3)
		self:text(self:fungal_shift_label(i))
	end)
	self:spacing(3)

	-- Measure all sub-shifts up front so their arrows line up horizontally.
	-- Indented blocks (failed, force-failed, greedy all use 3px) contribute
	-- col_width + 3 so the indent is absorbed into the shared boundary.
	local max_from_w, _ = self:fungal_get_longest_text_in_shift(shift, 0, 0, false, self.alt)
	if not self.fs.predictor.is_single_pass then
		if shift.failed then
			local fw, _ = self:fungal_get_longest_text_in_shift(shift.failed, 0, 0, false, self.alt)
			max_from_w = math.max(max_from_w, fw + 3)
		end
		if shift.force_failed then
			local fw, _ = self:fungal_get_longest_text_in_shift(shift.force_failed, 0, 0, false, self.alt)
			max_from_w = math.max(max_from_w, fw + 3)
		end
	end
	if self.fs.predictor.is_using_pouch_shift and shift.greedy and self.alt then
		local greedy_col_w = self:fungal_get_longest_material_name({ CellFactory_GetType("gold"), CellFactory_GetType("grass_holy") }, 0)
		max_from_w = math.max(max_from_w, greedy_col_w + 3)
	end

	self:fungal_draw_future_tooltip_shift(shift, max_from_w)

	if not self.fs.predictor.is_single_pass then
		if shift.failed then
			self:spacing(4)
			self:fungal_draw_future_tooltip_shift_failed(shift, max_from_w)
		end
		if shift.force_failed then
			self:spacing(4)
			self:fungal_draw_future_tooltip_shift_force_failed(shift, max_from_w)
		end
	end

	if self.fs.predictor.is_using_pouch_shift then
		if shift.greedy and self.alt then
			self:spacing(4)
			self:fungal_draw_future_tooltip_greedy(shift.greedy, max_from_w)
		end
		self:spacing(5)
	end

	self:alt_hint()
end

return ft
