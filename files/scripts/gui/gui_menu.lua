---@class (exact) LS_Gui_menu
---@field start_x number
---@field start_y number
---@field width number
---@field opened boolean
---@field package header string
---@field current string|nil  id of the open window, nil = none
---@field package previous string|nil
---@field shared_width number  group target from last frame; read by self-framed windows as their min_width floor
---@field bar_width number  the header bar's drawn width (self-framed windows match this)
---@field _just_switched boolean  true for exactly one frame when the open window changes

---@class (exact) LS_Gui
---@field private menu LS_Gui_menu
local menu = {
	menu = { ---@diagnostic disable-line: missing-fields
		start_x = 16,
		start_y = 48,
		width = 0,
		opened = false,
		header = "== LAMA'S STATS ==",
		current = nil,
		previous = nil,
		shared_width = 0,
		bar_width = 0,
		_just_switched = false,
	},
}

---@class menu_window
---@field id string
---@field label string  key into the global T localization table
---@field draw string   method name on LS_Gui
---@field init string?  optional method called once when the window is opened
---@field flag string?  config key gating visibility
---@field modal boolean?  draws itself (screen-centred) instead of flowing under the bar
---@field self_framed boolean?  draws its own window frame(s); the menu does not wrap it
---@field overlay string?  optional method called after window_group, for overlays drawn outside the group

---@type menu_window[]
local WINDOWS = {
	{
		id = "fungal",
		label = "FungalShifts",
		draw = "fungal_draw_window",
		init = "fungal_init",
		flag = "show_fungal_menu",
		self_framed = true,
	},
	{
		id = "perks",
		label = "Perks",
		draw = "perks_draw_window",
		init = "perks_init",
		flag = "show_perks_menu",
		self_framed = true,
	},
	{
		id = "shops",
		label = "Shops",
		draw = "shops_draw_window",
		overlay = "shops_draw_overlays",
		flag = "show_shops_menu",
		self_framed = true,
	},
	{
		id = "materials",
		label = "materials",
		draw = "materials_draw_window",
		overlay = "materials_draw_overlays",
		flag = "show_materials",
		self_framed = true,
	},
	{
		id = "kys",
		label = "KYS_Suicide",
		draw = "kys_draw",
		flag = "show_kys_menu",
		modal = true,
	},
	{
		id = "config",
		label = "config",
		draw = "config_draw_scroll_box",
		init = "config_init",
	},
}

---@type {[string]: menu_window}
local WINDOWS_BY_ID = {}
for i = 1, #WINDOWS do
	WINDOWS_BY_ID[WINDOWS[i].id] = WINDOWS[i]
end

---Contributes this window's width to the shared menu group (call at end of self_framed draw).
---@param header_width number
function menu:menu_feed_width(header_width)
	self:window_group_contribute(header_width)
end

---Draws menu tab buttons.
---@private
function menu:draw_menu_buttons()
	local m = self.menu
	self:begin_row(function()
		for i = 1, #WINDOWS do
			local e = WINDOWS[i]

			if e.flag and not self.config[e.flag] then goto continue end

			local is_open = m.current == e.id
			local clicked = self:button(T[e.label] or e.label, not is_open)
			self:spacing(2)
			if clicked then
				if is_open then
					m.current = nil
				else
					m.current = e.id
					if e.init then self[e.init](self) end
				end
			end

			::continue::
		end
	end)
end

---Draws the menu bar and the open window (if any).
---@private
function menu:menu_draw()
	local m = self.menu
	m.width = self:get_text_dim(m.header)

	local open = m.current and WINDOWS_BY_ID[m.current]

	local inline = open and not open.modal and open
	local modal = open and open.modal and open

	local drawn_id = m.current
	m._just_switched = drawn_id ~= m.previous
	m.shared_width = self:window_group_target("menu")

	self:layout_at(m.start_x, m.start_y, function()
		self:window_group("menu", function()
			self:begin_column(function()
				m.bar_width = self:window(function()
					self:text(m.header)
					self:spacing(4)
					self:draw_menu_buttons()
					self:spacing(-1)
				end, { id = "menu_bar" })

				if inline then
					self:window_join()
					if inline.self_framed then
						self[inline.draw](self)
					else
						self:window(function()
							self[inline.draw](self)
						end, { id = "menu_window" })
					end
				end
			end)
		end)
		-- Overlay is drawn outside the group so its windows don't contribute to the
		-- shared-width target.
		if inline and inline.overlay then self[inline.overlay](self) end
	end)

	if modal then self[modal.draw](self) end
	m.previous = drawn_id
end

return menu
