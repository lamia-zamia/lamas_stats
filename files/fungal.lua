dofile_once("mods/lamas_stats/files/fungal_common.lua")
dofile_once("mods/lamas_stats/files/fungal_past.lua")
dofile_once("mods/lamas_stats/files/fungal_future.lua")

current_shifts = tonumber(GlobalsGetValue("fungal_shift_iteration", "0"))
past_shifts,future_shifts = nil
show_shifts_per_screen = ModSettingGet("lamas_stats.fungal_shift_max")
show_shift_start_from = 1
local show_arrows = false

function gui_fungal_shift()
	local gui_id = 1000
	function id()
		gui_id = gui_id + 1
		return gui_id
	end
	GuiBeginAutoBox(gui_menu)
	GuiLayoutBeginVertical(gui_menu, menu_pos_x, menu_pos_y, false, 0, 0) --layer1
	guiZ = 900
	GuiZSet(gui_menu,guiZ)

	GuiLayoutBeginHorizontal(gui_menu, 0, 0, false)
	GuiText(gui_menu, 0, 0, "==== " .. _T.FungalShifts .. " ====", fungal_shift_scale)
	if show_arrows then
		if show_shift_start_from > 1 then
			if GuiButton(gui_menu, id(), 0, 0, " <", fungal_shift_scale) then
				show_shift_start_from = show_shift_start_from - show_shifts_per_screen
			end
		else
			GuiTextGray(gui_menu, 0, 0, " <", fungal_shift_scale)
		end
		GuiText(gui_menu, 0, 0, tostring(show_shift_start_from + show_shifts_per_screen - 1), fungal_shift_scale)
		if (show_shift_start_from + show_shifts_per_screen) <= maximum_shifts then
			if GuiButton(gui_menu, id(), 0, 0, " >", fungal_shift_scale) then
				show_shift_start_from = show_shift_start_from + show_shifts_per_screen
			end
		else
			GuiTextGray(gui_menu, 0, 0, " >", fungal_shift_scale)
		end
	end
	GuiLayoutEnd(gui_menu)
	
	GuiLayoutBeginHorizontal(gui_menu, 0, 0, false)
	gui_menu_switch_button(gui_menu, id(), fungal_shift_scale, gui_menu_main_display_loop) --return

	gui_do_refresh_button(gui_menu, id(), fungal_shift_scale, UpdateFungalVariables)

	if current_shifts ~= tonumber(GlobalsGetValue("fungal_shift_iteration", "0")) then
		gui_fungal_shift_get_shifts()
	end

	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		gui_fungal_show_aplc_recipes(gui_menu)
	end
	local cooldown = GetFungalCooldown()
	if cooldown > 0 then
		GuiImage(gui_menu, id(), -5, -1, fungal_png, 1, 0.7 * fungal_shift_scale)
		GuiText(gui_menu, 0, 0, _T.lamas_stats_fungal_cooldown .. " " .. cooldown, fungal_shift_scale)
	end
	GuiLayoutEnd(gui_menu)
	if ModSettingGet("lamas_stats.enable_fungal_past") then
		gui_fungal_shift_display_past_shifts(gui_menu)
	end
	if future_shifts ~= nil then
		gui_fungal_shift_display_future_shifts(gui_menu)
	end
	GuiLayoutEnd(gui_menu) --layer1

	GuiZSetForNextWidget(gui_menu, guiZ + 100)
	GuiEndAutoBoxNinePiece(gui_menu, 1, 0, 0, false, 0, screen_png, screen_png)
end

function gui_fungal_shift_get_shifts()
	gui_fungal_shift_get_past_shifts()
	if ModSettingGet("lamas_stats.enable_fungal_future") then
		gui_fungal_shift_get_future_shifts()
	else
		future_shifts = nil
	end
end

function UpdateFungalVariables()
	show_shifts_per_screen = ModSettingGet("lamas_stats.fungal_shift_max")
	if (current_shifts > show_shifts_per_screen) or (future_shifts ~= nil and maximum_shifts > show_shifts_per_screen) then
		show_arrows = true
	else show_arrows = false end
	fungal_shift_scale = tonumber(ModSettingGet("lamas_stats.fungal_scale")) or 1
	gui_fungal_shift_get_shifts()
end