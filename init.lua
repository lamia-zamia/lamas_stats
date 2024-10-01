-- dofile_once("data/scripts/lib/utilities.lua")

original_material_properties = {} --table of material names and colors, populates from materials.xml

local white_pixel = "mods/lamas_stats/vfs/white.png"
local custom_img_id = ModImageMakeEditable(white_pixel, 1, 1)
ModImageSetPixel(custom_img_id, 0, 0, -1) --white

---On mod init
function OnModInit()
	dofile_once("mods/lamas_stats/files/appens_to_gamefiles.lua")
end

---On mod postinit
function OnModPostInit()
	dofile_once("mods/lamas_stats/files/common.lua")
end

---After OnModPostInit
function OnMagicNumbersAndWorldSeedInitialized()
	original_material_properties = dofile_once("mods/lamas_stats/files/material_graphics.lua")
end

---Idk why it's called before initialized
function OnWorldPostUpdate()
	if lamas_stats_main_loop then lamas_stats_main_loop() end
end

---?
function OnPlayerSpawned()
	dofile_once("mods/lamas_stats/files/info_gui.lua") --loading main gui file
	dofile_once("mods/lamas_stats/files/perks_vanilla_icons.lua")
end
