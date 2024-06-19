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

local function ShowKillTooltip(gui)
	GuiText(gui, 0, 0, _T.lamas_stats_progress_kills .. " " .. StatsGetValue("enemies_killed"))
	GuiText(gui, 0, 0, _T.lamas_stats_progress_kills_innocent .. " " .. GlobalsGetValue("HELPLESS_KILLS",0))
end

function ShowKill(i, gui, id, x, y)
	local transString = _T.lamas_stats_progress_kills
	local width = GuiGetTextDimensions(gui, transString)
	PopulateStats(i, gui, stats_x, y, transString .. " " .. StatsGetValue("enemies_killed"))
	if ModSettingGet("lamas_stats.stats_show_innocent") then
		GuiTooltipLamas(gui, 0, 10, 800, ShowKillTooltip)
	end
	stats_x = stats_x + 30 + width
end

local function ShowTimeHoverTooltip(gui)		
	local stats_list = {}
	table.insert(stats_list, GameTextGetTranslatedOrNot("$menu_stats"))
	table.insert(stats_list, GameTextGetTranslatedOrNot("$stat_time") .. " " .. StatsGetValue("playtime_str"))
	table.insert(stats_list, GameTextGetTranslatedOrNot("$stat_places_visited") .. " " .. StatsGetValue("places_visited"))
	table.insert(stats_list, GameTextGetTranslatedOrNot("$stat_gold") .. " " .. StatsGetValue("gold_all"))
	table.insert(stats_list, GameTextGetTranslatedOrNot("$stat_items_found") .. " " .. StatsGetValue("items"))
	table.insert(stats_list, _T.lamas_stats_hearts_find .. " " .. StatsGetValue("heart_containers"))
	table.insert(stats_list, _T.lamas_stats_projectiles_shot .. " " .. StatsGetValue("projectiles_shot"))
	table.insert(stats_list, _T.lamas_stats_kicks .. " " .. StatsGetValue("kicks"))
	table.insert(stats_list, _T.lamas_stats_damage_taken .. " " .. math.ceil(StatsGetValue("damage_taken") * 25))
	-- table.insert(stats_list, GameTextGetTranslatedOrNot("$action_teleportation") .. ": " .. StatsGetValue("teleports")) --this is bugged
	
	for _,text in ipairs(stats_list) do
		GuiText(gui, 0, 0, text)
	end
end

function ShowTime(i, gui, id, x, y)
	local transString = GameTextGetTranslatedOrNot("$stat_time")
	local width = GuiGetTextDimensions(gui, transString)
	PopulateStats(i, gui, stats_x, y, transString .. " " .. StatsGetValue("playtime_str"))
	GuiTooltipLamas(gui, 0, 10, 800, ShowTimeHoverTooltip)
	stats_x = stats_x + 44 + width
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
	PopulateStats(i, gui, stats_x, y, biome_name .. GameTextGetTranslatedOrNot(biome))
end

local function ShowPlayerPosTooltip(gui)
	local tooltipname = _T.lamas_stats_stats_pw
	local tooltip = _T.lamas_stats_stats_pw_main
	if player_par_x > 0 then
		tooltip = _T.lamas_stats_stats_pw_east .. " " .. player_par_x
	elseif player_par_x < 0 then
		tooltip = _T.lamas_stats_stats_pw_west .. " " .. player_par_x*-1
	end
	GuiText(gui, 0, 0, _T.lamas_stats_position_toggle)
	if not pos_toggle then
		GuiText(gui, 0, 0, "X: " .. tostring(math.floor(player_x)))
		GuiText(gui, 0, 0, "Y: " .. tostring(math.floor(player_y)))
	end
	GuiText(gui, 0, 0, tooltipname .. " - " .. tooltip)
	if ModSettingGet("lamas_stats.stats_show_farthest_pw") then
		if farthestWest > 0 or farthestEast > 0 then
			GuiText(gui, 0, 0, _T.lamas_stats_farthest .. " " .. _T.lamas_stats_stats_pw_west .. ": " .. farthestWest)
			GuiText(gui, 0, 0, _T.lamas_stats_farthest .. " " .. _T.lamas_stats_stats_pw_east .. ": " .. farthestEast)
		end
	end
end

function ShowPlayerPos(i, gui, id, x, y)
	local transString = "|" .. _T.lamas_stats_position
	local width = GuiGetTextDimensions(gui, transString)
	player_x, player_y = get_player_pos()
	player_par_x, player_par_y = GetParallelWorldPosition(player_x, player_y)
	if GuiButton(gui, 105, stats_x, y, transString) then
		pos_toggle = not pos_toggle
	end
	if ModSettingGet("lamas_stats.stats_show_player_pos_pw") then
		GuiTooltipLamas(gui, 0, 10, 800, ShowPlayerPosTooltip)
	end
	stats_x = stats_x + width + 5
	
	if pos_toggle then
		PopulateStats(1, gui, stats_x, y, "X:" .. math.floor(player_x) .. ",")
		stats_x = stats_x + 50
		PopulateStats(1, gui, stats_x, y, "Y:" .. math.floor(player_y))
		stats_x = stats_x + 50
	end
	if ModSettingGet("lamas_stats.stats_show_farthest_pw") then
		if GameGetFrameNum() % 300 == 0 then
			if player_par_x > farthestWest then	
				farthestWest = player_par_x 
				GlobalsSetValue("lamas_stats_farthest_west", farthestWest)
			end
			if player_par_x < farthestEast then	
				farthestEast = player_par_x	* -1
				GlobalsSetValue("lamas_stats_farthest_east", farthestEast)
			end
		end
	end
end

function ShowStart(i, gui, id, x, y)
	stats_x = x
end

function GUI_Stats(gui, id, x, y)
	for i,stat in ipairs(lamas_stats_main_menu_list) do
		stat(i, gui, id, x, y)
	end
end

table.insert(lamas_stats_main_menu_list,ShowStart)
if ModSettingGet("lamas_stats.stats_showtime") then table.insert(lamas_stats_main_menu_list,ShowTime) end
if ModSettingGet("lamas_stats.stats_showkills") then table.insert(lamas_stats_main_menu_list,ShowKill) end
if ModSettingGet("lamas_stats.stats_show_fungal_cooldown") then 
	if ModSettingGet("lamas_stats.stats_show_fungal_order") == "first" then table.insert(lamas_stats_main_menu_list,2,ShowFungal) 
	else table.insert(lamas_stats_main_menu_list,ShowFungal) end
end	
if ModSettingGet("lamas_stats.stats_show_player_pos") then table.insert(lamas_stats_main_menu_list, ShowPlayerPos) end
if ModSettingGet("lamas_stats.stats_show_player_biome") then table.insert(lamas_stats_main_menu_list, ShowPlayerBiome) end