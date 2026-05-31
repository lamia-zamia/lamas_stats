---@class (exact) LS_Gui
---@field kys {show: boolean, hide_after: boolean}
local kys = {
	kys = {
		show = false,
		hide_after = true,
	},
}

---Draws the "kill yourself" confirmation window (centered on screen).
---@private
function kys:kys_draw()
	local warn = T.KYS_Suicide_Warn
	local btn = T.KYS_Button
	local warn_w = self:get_text_dim(warn)
	local btn_w = self:get_text_dim(btn)

	local x, y = self:calculate_center(warn_w + 8, 34)
	self:set_z(self.z + 55)
	self:begin_window(x, y, function()
		self:color(1, 1, 0)
		self:text(warn)
		self:spacing(6)
		self:color(1, 0, 0)
		local clicked = false
		-- Centre the button under the (wider) warning via a leading gap.
		self:begin_row(function()
			self:spacing((warn_w - btn_w) / 2)
			clicked = self:button(btn, true)
		end)
		if clicked then
			ModSettingSetNextValue("lamas_stats.show_kys_menu", false, false)
			ModSettingSet("lamas_stats.show_kys_menu", false)
			local gsc_id = ENTITY_GET_FIRST_COMPONENT_INCLUDING_DISABLED(self.player, "GameStatsComponent")
			if not gsc_id then return end
			ComponentSetValue2(gsc_id, "extra_death_msg", T.KYS_Suicide)
			ENTITY_KILL(self.player)
		end
	end, nil, "kys")
end

return kys
