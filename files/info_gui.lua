local function LamasStatsApplySettings()
	if ModSettingGet("lamas_stats.enable_fungal_recipes") then
		APLC_table = dofile_once("mods/lamas_stats/files/APLC.lua")
	end
end