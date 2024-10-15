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
	local pos_x = self.menu.start_x
	local pos_y = self.menu.pos_y + 36
	local kys_button_string = T.KYS_Button
	local kys_button_string_width = self:GetTextDimension(kys_button_string)
	local kys_warn_string = T.KYS_Suicide_Warn
	local kys_warn_string_width = self:GetTextDimension(kys_warn_string)

	self:Color(1, 1, 0)
	self:TextCentered(pos_x, pos_y, kys_warn_string, kys_warn_string_width)
	pos_y = pos_y + 17
	self:Color(1, 0, 0)
	self:DrawButton(pos_x + (kys_warn_string_width - kys_button_string_width) / 2, pos_y, self.z, kys_button_string, true)
	if self:IsHovered() and self:IsLeftClicked() then
		if self.kys.hide_after then
			ModSettingSetNextValue("lamas_stats.KYS_Button", false, false)
			ModSettingSet("lamas_stats.KYS_Button", false)
		end
		local gsc_id = EntityGetFirstComponentIncludingDisabled(self.player, "GameStatsComponent")
		if not gsc_id then return end
		ComponentSetValue2(gsc_id, "extra_death_msg", T.KYS_Suicide)
		ENTITY_KILL(self.player)
	end
	self:Draw9Piece(pos_x - 6, self.menu.pos_y + 30, self.z + 55, kys_warn_string_width + 12, 42)
end

--- Fetches settings for kys
--- @private
function kys:KysGetSettings()
	self.kys.hide_after = self.mod:GetSettingBoolean("KYS_Button_Hide")
end

return kys
