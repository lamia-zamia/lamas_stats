_T = dofile_once("mods/lamas_stats/translations/translation.lua") ---Translation strings
local gui = dofile_once("mods/lamas_stats/files/scripts/gui/gui_main.lua") ---@type LS_Gui

local white_pixel = "mods/lamas_stats/vfs/white.png"
local custom_img_id = ModImageMakeEditable(white_pixel, 1, 1)
ModImageSetPixel(custom_img_id, 0, 0, -1) --white

---On mod init
function OnModInit()
	-- dofile_once("mods/lamas_stats/files/appens_to_gamefiles.lua")
end

---On mod postinit
function OnModPostInit()
	-- dofile_once("mods/lamas_stats/files/common.lua")
end

---After OnModPostInit
function OnMagicNumbersAndWorldSeedInitialized()
	-- original_material_properties = dofile_once("mods/lamas_stats/files/material_graphics.lua")
end

---Idk why it's called before initialized
function OnWorldPostUpdate()
	gui:loop()
end

---?
function OnPlayerSpawned()
	gui:GetSettings()
	-- dofile_once("mods/lamas_stats/files/perks_vanilla_icons.lua")
end

---Fetch settings
function OnPausedChanged()
	gui:GetSettings()
end