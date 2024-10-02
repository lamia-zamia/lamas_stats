local function ShowFungalTooltip(gui)
	GuiText(gui, 0, 0, transStringFungal .. " " .. cooldown)
end

function ShowFungal(i, gui, id, x, y)
	cooldown = GetFungalCooldown()
	if cooldown > 0 then
		local width = 0
		transStringFungal = _T.lamas_stats_fungal_cooldown
		if ModSettingGet("lamas_stats.stats_show_fungal_type") == "time" then
			width = GuiGetTextDimensions(gui, transStringFungal) + 20
			PopulateStats(i, gui, stats_x, y, transStringFungal .. " " .. cooldown)
		else
			width = GuiGetImageDimensions(gui,fungal_png) - 7
			local x_offset = 0
			if (ModSettingGet("lamas_stats.stats_show_fungal_order")) == "first" then
				x_offset = 5
			else
				x_offset = -3
			end
			GuiImage(gui,id,stats_x - x_offset,y - 2,fungal_png, 1, 0.9)
			GuiTooltipLamas(gui, 0, 10, 800, ShowFungalTooltip)
			PopulateStats(i, gui, stats_x, y, "")
		end
		
		stats_x = stats_x + width
	end
end

function StatsTableInsert()
	if ModSettingGet("lamas_stats.stats_show_fungal_cooldown") then 
		if ModSettingGet("lamas_stats.stats_show_fungal_order") == "first" then table.insert(lamas_stats_main_menu_list,2,ShowFungal) 
		else table.insert(lamas_stats_main_menu_list,ShowFungal) end
	end	
end