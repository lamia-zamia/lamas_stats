local stats_x = nil
local pos_toggle = false
local player_x, player_y = get_player_pos()
local player_par_x, player_par_y = GetParallelWorldPosition(player_x, player_y)
local cooldown,transStringFungal
local farthestWest = tonumber(GlobalsGetValue("lamas_stats_farthest_west", "0"))
local farthestEast = tonumber(GlobalsGetValue("lamas_stats_farthest_east", "0"))

function PopulateStats(i, gui, x, y, str)
	if i > 2 then str = "|" .. str end
	GuiText(gui, x, y, str)
end

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

function ShowPlayerBiome(i, gui, id, x, y)
	player_x, player_y = get_player_pos()
	local biome = BiomeMapGetName(player_x, player_y)
	local par_x = GetParallelWorldPosition(player_x, player_y)
	
	if biome == "_EMPTY_" then biome = _T.lamas_stats_unknown end
	
	local biome_name = _T.lamas_stats_location .. ": "
	if par_x > 0 then
		biome_name = biome_name .. _T.lamas_stats_stats_pw_east .. " "
	elseif par_x < 0 then
		biome_name = biome_name .. _T.lamas_stats_stats_pw_west .. " "
	end
	local text = biome_name .. GameTextGetTranslatedOrNot(biome)
	PopulateStats(i, gui, stats_x, y, text)
	local width = GuiGetTextDimensions(gui, text)
	stats_x = stats_x + 10 + width
end

function ShowStart(i, gui, id, x, y)
	stats_x = x
end

function GUI_Stats(gui, id, x, y)
	for i,stat in ipairs(lamas_stats_main_menu_list) do
		stat(i, gui, id, x, y)
	end
end

function StatsTableInsert()
	if ModSettingGet("lamas_stats.stats_show_player_biome") then table.insert(lamas_stats_main_menu_list, ShowPlayerBiome) end
	if ModSettingGet("lamas_stats.stats_show_fungal_cooldown") then 
		if ModSettingGet("lamas_stats.stats_show_fungal_order") == "first" then table.insert(lamas_stats_main_menu_list,2,ShowFungal) 
		else table.insert(lamas_stats_main_menu_list,ShowFungal) end
	end	
end