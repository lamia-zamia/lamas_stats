---@class (exact) LS_Gui_materials
---@field y number
---@field reaction_y number
---@field visible_types { [number]:boolean}
---@field current_recipe integer?
---@field filter string
---@field width number
---@field width_reaction number
---@field reaction_show_output boolean
---@field scroll_height number
---@field current_tag string?
---@field reaction_scroll_height number
---@field tag_height number
---@field reaction_box_last_pos number

---@class (exact) LS_Gui
---@field materials LS_Gui_materials
local materials = {
	materials = {
		y = 0,
		visible_types = {},
		current_recipe = nil,
		current_tag = nil,
		reaction_y = 0,
		filter = "",
		width = 200,
		width_reaction = 256,
		reaction_show_output = false,
		scroll_height = 100,
		reaction_scroll_height = 100,
		tag_height = 10,
		reaction_box_last_pos = 10,
	},
}

local margin = 3
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

local reactions_data = setmetatable({}, { __mode = "k" }) ---@type {[string]:gui_reaction_data}
local filtered_materials = nil

---Returns true if passed name contains tag
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

---Returns longest material name from an array of reaction datas
---@private
---@param reaction_datas reactions_data[]
---@return number
function materials:reaction_datas_get_longest_name(reaction_datas)
	local max = 0
	for _, material_name, _ in self.mat.each_reaction_material_names(reaction_datas) do
		max = math.max(max, self:GetTextDimension(truncate(material_name)))
		if not is_tag(material_name) then
			local material_data = self.mat:get_data_by_id(material_name)
			max = math.max(max, self:GetTextDimension(self:FungalGetName(material_data)))
		end
	end
	return max
end

---Replaces partial reactions with the material itself
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
		-- plain tag [tag]
		if has_tag then
			list[i] = material_id
			return
		end
		-- partial match (e.g., material_name maps to something with suffix)
		local partial_match = self.mat.is_partial_match(material_name, material_id)
		if partial_match then
			list[i] = partial_match
			return
		end
	else
		-- tag + suffix
		if has_tag then
			local replace_name = material_id .. suffix
			if self.mat:does_material_exist(replace_name) then list[i] = replace_name end
			return
		-- reverse: material_id already has suffix
		elseif material_id:sub(-#suffix) == suffix then
			local base = material_id:sub(1, #material_id - #suffix)
			if base ~= "" and self.mat:material_has_tag(base, tag) then list[i] = material_id end
		end
	end
end

---Gets reaction data and replaces tag if its the material itself
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

---Gathers reaction data and whats not
---@param material_id string
---@private
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

---Gets reaction data
---@param material_id string
---@return gui_reaction_data
function materials:get_reaction_data(material_id)
	if not reactions_data[material_id] then self:gather_reaction_data(material_id) end
	return reactions_data[material_id]
end

---Draws material centered
---@param x number
---@param y number
---@param material_data material_data
---@param width number
---@param alt boolean?
function materials:draw_material_centered(x, y, material_data, width, alt)
	local material_name = alt and truncate(material_data.id) or self:FungalGetName(material_data)
	local name_offset = (width - self:GetTextDimension(material_name)) / 2
	self:FungalDrawIcon(x + name_offset - 9, y, material_data)
	self:Text(x + name_offset, y, material_name)
end

---Draws material row in reaction
---@param x number
---@param y number
---@param material string
---@param width number
function materials:draw_reaction_row(x, y, material, width)
	if is_tag(material) then
		local text_width = self:GetTextDimension(material)
		local text_x = x + (width - text_width) / 2
		if self:reactions_is_hoverbox_hovered(text_x, y, text_width, 10) then
			self:ColorYellow()
			if self:IsLeftClicked() then
				self.materials.current_tag = material
				GamePlaySound("ui", "ui/button_click", 0, 0)
			end
		end
		self:Text(text_x, y, material)
	else
		self:draw_material_centered(x, y, self.mat:get_data_by_id(material), width, self.alt)
	end
end

---Checks if this element is within reactions window
---@private
---@param y number
---@param height number
---@return boolean
function materials:is_this_within_reaction_window(y, height)
	return y + height > 0 and y < self.materials.reaction_scroll_height
end

---Returns true if hovered
---@param x number
---@param y number
---@param width number
---@param height number
---@return boolean?
function materials:reactions_is_hoverbox_hovered(x, y, width, height)
	if y + height / 2 > 0 and y + height / 2 < self.materials.reaction_scroll_height then
		local box_x = self.menu.start_x + self.menu.width + 15 + x + margin
		local box_y = self.menu.start_y + 37.5 + y + margin
		-- self:Draw9Piece(box_x, box_y, -999999999, width, height)
		return self:IsHoverBoxHovered(box_x, box_y, width, height, true)
	end
end

---Shows probability and isreq
---@param probability number
---@param is_req boolean?
function materials:show_probability(probability, is_req)
	local speed_text = string.format("%s: %d", T.speed, probability)
	local speed_w = self:GetTextDimension(speed_text)
	local req_text = T.req_text
	local req_w = self:GetTextDimension(req_text)

	local x = is_req and (req_w - speed_w) / 2 or 0

	self:Text(x, 0, speed_text)

	if is_req then
		self:Color(1, 0.5, 0)
		self:Text(0, 0, req_text)
	end
end

---@param reaction reactions_data
function materials:show_reaction(reaction)
	local y = self.materials.reaction_y
	local rows = #reaction.inputs
	local height = 11 * rows
	self.materials.reaction_y = self.materials.reaction_y + height
	if not self:is_this_within_reaction_window(y, height) then return end

	local x = 0
	local gap = 15
	local arrow_w = 8
	local width = (self.materials.width_reaction - gap) / 2

	local horizontal_center = 10 * (rows - 1) / 2

	-- left column
	for i, input in ipairs(reaction.inputs) do
		self:draw_reaction_row(x, y + 10 * (i - 1), input, width)
	end

	-- gap
	x = x + width - margin
	local arrow_x = x + (gap - arrow_w) / 2
	if reaction.is_req then self:Color(1, 0.5, 0) end
	self:Image(arrow_x, y + horizontal_center, "mods/lamas_stats/files/gfx/arrow.png")
	if self:reactions_is_hoverbox_hovered(arrow_x, y + horizontal_center, arrow_w, arrow_w) then
		self:ShowTooltipCenteredX(0, 15, self.show_probability, reaction.probability, reaction.is_req)
	end

	-- right column
	x = x + gap
	for i, output in ipairs(reaction.outputs) do
		self:draw_reaction_row(x, y + 10 * (i - 1), output, width)
	end
end

---Draws a separator line
---@private
function materials:draw_reaction_separator()
	local y = self.materials.reaction_y - 1
	if self:is_this_within_reaction_window(y, 1) then self:Image(0, y, self.c.px, 0.4, self.materials.width_reaction - margin * 3, 1) end
end

---Draws reactions
---@private
function materials:show_reactions()
	self.materials.reaction_y = 1 - self.scroll.y
	local material = self.mat:get_data(self.materials.current_recipe)
	local reaction_data = self:get_reaction_data(material.id)
	local reactions = self.materials.reaction_show_output and reaction_data.producing or reaction_data.using
	self.materials.width_reaction = math.max(200, math.min(reaction_data.max_length * 2 + 50, 400))

	if #reactions > 0 then
		self:draw_reaction_separator()
		for _, reaction in ipairs(reactions) do
			self:show_reaction(reaction)
			self:draw_reaction_separator()
		end
	else
		self:Text(0, self.materials.reaction_y, "None")
		self.materials.reaction_y = self.materials.reaction_y + 11
	end

	self:Text(0, self.materials.reaction_y + self.scroll.y, "")
end

---Draws material tags, tooltip
---@private
---@param tags material_tags
function materials:draw_material_tags(tags)
	for tag, _ in pairs(tags) do
		self:Text(0, 0, tag)
	end
end

---Draws output/input button
---@private
---@param x number
---@param y number
---@param width number
---@param label string
---@param is_active boolean
---@param on_click boolean
function materials:draw_reaction_toggle_button(x, y, width, label, is_active, on_click)
	local text_width = self:GetTextDimension(label)
	local text_offset = (width - text_width) / 2

	if not is_active then self:AddOptionForNext(self.c.options.ForceFocusable) end
	self:Draw9Piece(x, y + 2, self.z + 4, width, 8, self.buttons.img)

	if is_active then
		self:ColorYellow()
	elseif self:IsHovered() and self:IsLeftClicked() then
		self.materials.reaction_show_output = on_click
		self.materials.current_tag = nil
		GamePlaySound("ui", "ui/button_click", 0, 0)
	end

	self:Text(x + text_offset, y + 1, label)
end

---Draws reaction window
---@private
function materials:draw_reaction_window()
	local material_type = self.materials.current_recipe
	if not material_type then return end

	local x = self.menu.start_x + self.menu.width + 15
	local y = self.menu.start_y - 1
	local width = self.materials.width_reaction
	self:Draw9Piece(x, y, self.z + 5, width, 32)
	if self:IsHovered() then self:BlockInput() end

	local material_data = self.mat:get_data(material_type)

	local close_text = T.close
	local close_width = self:GetTextDimension(close_text)
	local close_x = x + width - close_width - 3
	local close_y = y + 3
	if self:IsButtonClicked(close_x, close_y, self.z + 4, close_text, T.close_d) then
		GamePlaySound("ui", "ui/button_click", 0, 0)
		self.materials.current_recipe = nil
		self.materials.current_tag = nil
		return
	end

	-- draw tags?
	if material_data.tags then
		local tags_text = "[tags]"
		local tags_width = self:GetTextDimension(tags_text)
		local pos_x = close_x - tags_width - 5
		if self:IsHoverBoxHovered(pos_x, y, tags_width, 10) then
			self:ShowTooltipCenteredX(0, 20, self.draw_material_tags, material_data.tags)
			self:ColorYellow()
		end
		self:Text(pos_x, y, tags_text)
	end

	-- draw material name
	self:draw_material_centered(x, y, material_data, width)
	y = y + 10

	-- draw material id
	local material_id = string.format("(%s)", material_data.id)
	local id_offset = (width - self:GetTextDimension(material_id)) / 2
	self:ColorGray()
	self:Text(x + id_offset, y, material_id)
	y = y + 10

	local reaction_data = self:get_reaction_data(material_data.id)

	-- buttons
	local buttons_width = width / 2 - margin * 2
	local is_output = self.materials.reaction_show_output
	local using_string = string.format("%s (%d)", T.using, #reaction_data.using)
	self:draw_reaction_toggle_button(x + margin, y, buttons_width, using_string, not is_output, false)
	local producing_string = string.format("%s (%d)", T.producing, #reaction_data.producing)
	self:draw_reaction_toggle_button(x + margin * 3 + buttons_width, y, buttons_width, producing_string, is_output, true)

	self:ScrollBox(
		x + margin,
		y + 20,
		self.z + 5,
		width - margin * 2,
		self.materials.reaction_scroll_height,
		self.c.default_9piece,
		margin,
		margin,
		self.show_reactions
	)
	self.materials.reaction_box_last_pos = self:GetPrevious().y
end

---Checks if material should be shown
---@param material_index integer
---@return boolean?
function materials:is_material_in_filter(material_index)
	local material = self.mat:get_data(material_index)
	if not self.materials.visible_types[material.type] then return end
	local filter = self.materials.filter
	for _, name in ipairs({ material.id, material.ui_name, self:Locale(material.ui_name) }) do
		if name:lower():find(filter) then return true end
	end
end

---Shows material tooltip on hover
---@private
---@param material_index integer
function materials:show_material_tooltip(material_index)
	if material_index == self.materials.current_recipe then return end
	local y = 0
	self:AddOption(self.c.options.Layout_NextSameLine)

	local material = self.mat:get_data(material_index)
	local reaction_data = self:get_reaction_data(material.id)
	self:FungalDrawSingleMaterial(0, y, material_index, true)
	y = y + 10
	self:Text(0, y, string.format("%s: %d, %s: %d", T.using, #reaction_data.using, T.producing, #reaction_data.producing))
	y = y + 10
	if not self.materials.current_recipe then
		self:ColorGray()
		self:Text(0, y, T.reaction_window_d)
		y = y + 10

		self:ColorGray()
		self:Text(0, y, T.PressShiftToSeeMore)
	end
	self:RemoveOption(self.c.options.Layout_NextSameLine)
end

---Draws single material
---@param y number
---@param material_index integer
function materials:materials_draw_material(y, material_index)
	if not self:fungal_is_element_visible(y, 10) then
		self.materials.y = self.materials.y + 10
		return
	end

	local hoverbox_visible = y + 5 > 0 and y + 10 < self.max_height
	local hovered = hoverbox_visible and self:IsHoverBoxHovered(self.menu.start_x - 6, self.menu.pos_y + y + 7, self.fungal.width - 20, 9.9)

	local material_data = self.mat:get_data(material_index)
	self:FungalDrawIcon(0, y, material_data)
	local material_name = self:FungalGetName(material_data)

	if self.materials.current_recipe == material_index then
		if hovered then
			self:Color(0.6, 1, 0.4)
		else
			self:Color(0.4, 1, 0.6)
		end
	elseif hovered then
		self:ColorYellow()
	end
	self:Text(9, y, material_name)
	self:ColorGray()
	self:Text(12 + self:GetTextDimension(material_name), y, "(" .. material_data.id .. ")")

	if hovered then
		local tooltip_y = self.materials.current_recipe and 10 or self.menu.start_y + 3
		local tooltip_x = self.menu.start_x + self.menu.width + 18
		self.tooltip_img = "mods/lamas_stats/files/gfx/ui_9piece_tooltip.png"
		self.tooltip_reset = false
		self:ShowTooltip(tooltip_x, tooltip_y, self.show_material_tooltip, material_index, self.materials.current_recipe)
		self.tooltip_img = self.default_tooltip
		if self:IsLeftClicked() then
			self.materials.current_recipe = material_index
			self.materials.current_tag = nil
		end
		if self:IsRightClicked() then
			self.materials.current_recipe = nil
			self.materials.current_tag = nil
		end
	end

	self.materials.y = self.materials.y + 10
end

---Gets filtered material list
---@private
---@return integer[]
function materials:get_filtered_materials()
	if not filtered_materials then
		local result = {}
		for material_index, _ in pairs(self.mat.data) do
			if self:is_material_in_filter(material_index) then result[#result + 1] = material_index end
		end
		filtered_materials = result
	end
	return filtered_materials
end

---Draws materials list
---@private
function materials:materials_draw_list()
	self.materials.y = 1 - self.scroll.y

	for _, material_index in ipairs(self:get_filtered_materials()) do
		self:materials_draw_material(self.materials.y, material_index)
	end

	self:Text(0, self.materials.y + self.scroll.y, "")
end

---Draws filter checkboxes
---@private
function materials:materials_draw_checkboxes()
	local x = self.menu.pos_x
	for material_type, type_name in ipairs(material_types) do
		if self:IsDrawCheckbox(x, self.menu.pos_y - 1, type_name, self.materials.visible_types[material_type]) and self:IsMouseClicked() then
			self.materials.visible_types[material_type] = not self.materials.visible_types[material_type]
			filtered_materials = nil
		end
		x = x + self:GetTextDimension(type_name) + 18
	end
end

---Draws searchbox
---@private
function materials:materials_textbox()
	local text = string.format("%s:", T.search)
	local text_width = self:GetTextDimension(text)
	self:Text(self.menu.pos_x, self.menu.pos_y, text)
	local new_text = self.textbox:draw_textbox(self.menu.pos_x + text_width + 5, self.menu.pos_y, self.z + 1, 100, 9, self.materials.filter)
	if new_text ~= self.materials.filter then
		self.materials.filter = new_text
		filtered_materials = nil
	end
end

function materials:materials_draw_tagged_materials()
	local material_list = self.mat.get_tagged_materials(self.materials.current_tag)
	local y = 1 - self.scroll.y
	for _, material_name in ipairs(material_list) do
		if y + 10 > 0 and y < self.materials.tag_height then self:FungalDrawSingleMaterial(0, y, CellFactory_GetType(material_name), true) end
		y = y + 10
	end
	self:Text(0, y + self.scroll.y, "")
end

function materials:materials_show_tagged_materials()
	if not self.materials.current_tag then return end
	local x = self.menu.start_x + self.menu.width + 15
	local y = self.menu.start_y + self.materials.reaction_scroll_height + 41 + margin * 2
	y = math.min(y, self.materials.reaction_box_last_pos + margin * 2 + 2)
	self:Draw9Piece(x, y, self.z + 5, self.materials.width_reaction, 10)
	if self:IsHovered() then self:BlockInput() end
	local text_width = self:GetTextDimension(self.materials.current_tag)
	self:Text(x + (self.materials.width_reaction - text_width) / 2, y, self.materials.current_tag)

	local close_text = "[X]"
	local close_width = self:GetTextDimension(close_text)
	local close_x = x + self.materials.width_reaction - close_width
	if self:IsHoverBoxHovered(close_x, y, close_width, 10) then
		self:ColorYellow()
		if self:IsLeftClicked() then
			GamePlaySound("ui", "ui/button_click", 0, 0)
			self.materials.current_tag = nil
			return
		end
	end
	self:Text(close_x, y, close_text)

	self:ScrollBox(
		x + margin,
		y + 12 + margin * 2,
		self.z + 5,
		self.materials.width_reaction - margin * 2,
		self.materials.tag_height - 11 - margin * 5,
		self.c.default_9piece,
		margin,
		margin,
		self.materials_draw_tagged_materials
	)
end

---Draws materials window
function materials:materials_draw_window()
	self:materials_draw_checkboxes()
	self.menu.pos_y = self.menu.pos_y + 12
	local header_start = self.menu.pos_y
	self:materials_textbox()
	self.menu.pos_y = self.menu.pos_y + 12
	self:MenuSetWidth(self.materials.width)
	self:AddOption(self.c.options.NonInteractive)

	local pos_x = self.menu.start_x - 3
	local pos_y = self.menu.pos_y + 7
	local header_height = self.menu.pos_y - header_start

	self.materials.scroll_height = self.max_height - header_height
	self.materials.reaction_scroll_height = self.max_height + 12
	if self.materials.current_tag then
		local list = self.mat.get_tagged_materials(self.materials.current_tag)
		local desired = #list * 10 + 27
		local limit = self.materials.reaction_scroll_height * 0.6
		self.materials.tag_height = math.max(37, math.min(desired, limit))
		self.materials.reaction_scroll_height = self.materials.reaction_scroll_height - self.materials.tag_height
	end
	self:ScrollBox(
		pos_x,
		pos_y,
		self.z + 5,
		self.materials.width + 6,
		self.materials.scroll_height,
		self.c.default_9piece,
		margin,
		margin,
		self.materials_draw_list
	)
	self:draw_reaction_window()
	self:materials_show_tagged_materials()
	self:RemoveOption(self.c.options.NonInteractive)
end

---Updates materials gui stuff
---@param did_language_changed boolean
function materials:materials_update(did_language_changed)
	if did_language_changed then reactions_data = setmetatable({}, { __mode = "k" }) end
end

return materials
