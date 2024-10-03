_T = dofile_once("mods/lamas_stats/translations/translation.lua")

function gui_menu_switch_button(gui, id, scale, menu) --gui frame, scale, loop function to display
	if GuiButton(gui, id, 0, 0, "[" .. _T.lamas_stat_return .. "]", scale) then
		gui_menu_function = menu
	end
end

function gui_do_refresh_button(gui, id, scale, action) 
	if GuiButton(gui, id, 0, 0, "[" .. GameTextGetTranslatedOrNot("$menu_mods_refresh") .. "]", scale) then --refresh
		action()
		GamePrint(_T.lamas_stat_refresh_text)
	end
end