--- @class (exact) LS_Gui
--- @field kys {show: boolean, hide_after: boolean}
local kys = {
	kys = {
		show = false,
		hide_after = true
	}
}

--- Draws kys window
--- @private
function kys:KysDraw()
	local kys_button_string = T.KYS_Button
	local kys_button_string_width = self:GetTextDimension(kys_button_string)
	local kys_warn_string = T.KYS_Suicide_Warn
	local kys_warn_string_width = self:GetTextDimension(kys_warn_string)

	local pos_x, pos_y = self:CalculateCenterInScreen(kys_warn_string_width + 12, 42)
	self:Color(1, 1, 0)
	self:TextCentered(pos_x, pos_y, kys_warn_string, kys_warn_string_width)
	self:Color(1, 0, 0)
	self:DrawButton(pos_x + (kys_warn_string_width - kys_button_string_width) / 2, pos_y + 17, self.z, kys_button_string, true)
	if self:IsHovered() and self:IsLeftClicked() then
		ModSettingSetNextValue("lamas_stats.show_kys_menu", false, false)
		ModSettingSet("lamas_stats.show_kys_menu", false)
		local gsc_id = EntityGetFirstComponentIncludingDisabled(self.player, "GameStatsComponent")
		if not gsc_id then return end
		ComponentSetValue2(gsc_id, "extra_death_msg", T.KYS_Suicide)
		ENTITY_KILL(self.player)
	end
	self:Draw9Piece(pos_x - 6, pos_y - 6, self.z + 55, kys_warn_string_width + 12, 42)
end

return kys
