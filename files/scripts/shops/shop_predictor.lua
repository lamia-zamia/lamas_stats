---@diagnostic disable: lowercase-global, missing-global-doc, undefined-global

local nil_fn = function() end

---@class shop_item
---@field id string -- spell action id, or wand entity XML path
---@field is_wand boolean
---@field price integer
---@field is_cheap boolean
---@field sprite string? -- wand sprite png path (wands only)
---@field stats {[string]:number}? -- wand stat values: shuffle, capacity, mana_max, etc. (wands only)
---@field spells string[]? -- deck spell ids (wands only)
---@field always_cast string[]? -- always-cast spell ids (wands only)

---@class shop_mountain
---@field world_x number
---@field world_y number
---@field items shop_item[]

---@class shop_predictor
---@field mountains shop_mountain[]
---@field world_width number
---@field private altar_positions {world_x:number, world_y:number}[]
---@field private shop_dx integer?
---@field private shop_dy integer?
---@field private _env table?
---@field private _state table?
local shop_predictor = {
	mountains = {},
	world_width = 0,
	altar_positions = {},
	shop_dx = nil,
	shop_dy = nil,
	_env = nil,
	_state = nil,
}

-- Colors in ABGR format (ModImageGetPixel returns signed int32).
-- bit.tobit converts unsigned hex literals to the matching signed int32.
-- AARRGGBB ff93cb4c -> ABGR 0xff4ccb93  (main holy mountain biome)
local ALTAR_BIOME_COLOR = bit.tobit(0xff4ccb93)
-- AARRGGBB ff33934c -> ABGR 0xff4c9333  (shop spawn trigger pixel in altar.png)
local SHOP_TRIGGER_COLOR = bit.tobit(0xff4c9333)

-- Entity creation/spawning functions nulled in predict() to suppress world side effects.
-- Logic functions (GetRandomAction, SetRandomSeed, Random, GlobalsGetValue) are left real.
local NULL_FUNCTIONS = {
	"EntityKill",
	"EntityAddChild",
	"EntityCreateNew",
	"EntityRemoveIngestionStatusEffect",
	"GameCreateParticle",
	"LoadBackgroundSprite",
	"GameTriggerMusicFadeOutAndDequeueAll",
	"GameTriggerMusicEvent",
	"GamePrint",
	"GamePrintImportant",
	"CrossCall",
	"perk_spawn",
	"perk_spawn_many",
	"perk_reroll_perks",
	"GameAddFlagRun",
	"GlobalsSetValue",
	"RegisterSpawnFunction",
	"EntitySetComponentsWithTagEnabled",
}

---Scan image for first pixel matching target_color; returns pixel coords or nil.
---@param img_id integer
---@param img_w integer
---@param img_h integer
---@param target_color integer
---@return integer? px
---@return integer? py
local function scan_for_first_color(img_id, img_w, img_h, target_color)
	for py = 0, img_h do
		for px = 0, img_w do
			if ModImageGetPixel(img_id, px, py) == target_color then return px, py end
		end
	end
end

---Read biome_offset_y from _biomes_all.xml via nxml.
---@param nxml_lib nxml
---@return integer
local function parse_biome_offset_y(nxml_lib)
	local content = ModTextFileGetContent("data/biome/_biomes_all.xml")
	local ok, root = pcall(nxml_lib.parse, content)
	if not ok then return 14 end
	return tonumber(root.attr.biome_offset_y) or 14
end

---Execute the biome map script inside env to capture PNG path and per-pixel overrides.
---@param env table isolated environment
---@return string? map_img_path
---@return table pixel_overrides  [px][py] = color
local function parse_biome_map_script(env)
	local map_img_path
	local pixel_overrides = {}

	env.BiomeMapSetSize = nil_fn
	env.BiomeMapLoadImage = function(_, _, path)
		map_img_path = path
	end
	env.BiomeMapSetPixel = function(x, y, color)
		if not pixel_overrides[x] then pixel_overrides[x] = {} end
		pixel_overrides[x][y] = color
	end

	env.dofile(MagicNumbersGetValue("BIOME_MAP"))

	return map_img_path, pixel_overrides
end

---Scan biome map image and return world coords for every main altar pixel.
---@param img_id integer
---@param map_w integer
---@param map_h integer
---@param pixel_overrides table
---@param biome_offset_y integer
---@return table positions  list of {world_x, world_y}
local function find_altar_positions(img_id, map_w, map_h, pixel_overrides, biome_offset_y)
	local positions = {}
	for py = 0, map_h do
		for px = 0, map_w do
			local color = ModImageGetPixel(img_id, px, py)
			if pixel_overrides[px] and pixel_overrides[px][py] then color = pixel_overrides[px][py] end
			if color == ALTAR_BIOME_COLOR then
				positions[#positions + 1] = {
					world_x = px * 512 - map_w * 256,
					world_y = (py - biome_offset_y) * 512,
				}
			end
		end
	end
	return positions
end

---Scan biome map for altar positions and altar.png for shop trigger offset.
---Must be called in post_biome_init while ModImage* API is available.
function shop_predictor:scan_map()
	local nxml = dofile_once("mods/lamas_stats/files/lib/nxml.lua")
	local make_env = dofile_once("mods/lamas_stats/files/lib/prediction_env.lua")
	local env = make_env()

	local biome_offset_y = parse_biome_offset_y(nxml)
	local map_img_path, pixel_overrides = parse_biome_map_script(env)

	if not map_img_path then return end

	local map_img_id, map_w, map_h = ModImageMakeEditable(map_img_path, 0, 0)

	if not map_w or not map_h then return end

	self.world_width = map_w * 512
	self.altar_positions = find_altar_positions(map_img_id, map_w, map_h, pixel_overrides, biome_offset_y)

	local altar_img_id, altar_w, altar_h = ModImageMakeEditable("data/biome_impl/temple/altar.png", 0, 0)
	self.shop_dx, self.shop_dy = scan_for_first_color(altar_img_id, altar_w, altar_h, SHOP_TRIGGER_COLOR)
end

---Initialize self._env and self._state on first call; no-op on subsequent calls.
---Sets up all shadow functions, loads temple_altar.lua and gun_procedural.lua into env.
function shop_predictor:_setup_env()
	if self._env then return end

	local make_env = dofile_once("mods/lamas_stats/files/lib/prediction_env.lua")
	local state = {
		captured_scene_x = nil,
		captured_scene_y = nil,
		captured_items = {},
		items_by_eid = {},
		fake_eid = 0,
		pending_cheap = false,
		wand_being_generated = nil,
	}
	self._state = state

	local env = make_env()
	self._env = env

	-- Pre-load gun_procedural so wand init scripts' dofile_once calls hit the env cache,
	-- keeping AddGunAction/Permanent shadows alive during generate_gun execution.
	env.dofile_once("data/scripts/gun/procedural/gun_procedural.lua")

	for i = 1, #NULL_FUNCTIONS do
		env[NULL_FUNCTIONS[i]] = nil_fn
	end

	-- Load temple_altar.lua into env once.
	-- init() and spawn_all_shopitems() will live in env and use env for all global lookups.
	env.dofile_once("data/scripts/biomes/temple_altar.lua")

	-- Shadow LoadPixelScene to capture altar scene origin from init().
	-- Filter altar_top paths to avoid capturing the wrong origin.
	env.LoadPixelScene = function(img_path, _, scene_x, scene_y, _, _)
		if not img_path:find("altar_top", 1, true) and not state.captured_scene_x then
			state.captured_scene_x = scene_x
			state.captured_scene_y = scene_y
		end
	end

	-- Shadow CreateItemActionEntity to capture spell items for the shop list.
	-- When inside wand gen (wand_being_generated set), spells are captured via
	-- AddGunAction/Permanent shadows instead; return a fake eid without recording.
	env.CreateItemActionEntity = function(item_id, _, _)
		state.fake_eid = state.fake_eid + 1
		if state.wand_being_generated then return state.fake_eid end
		local item = { id = item_id, is_wand = false, is_cheap = false, price = 0 }
		state.items_by_eid[state.fake_eid] = item
		state.captured_items[#state.captured_items + 1] = item
		return state.fake_eid
	end

	-- Shadow EntityAddComponent to capture prices from ItemCostComponent.
	local function capture_item_cost(eid, comp_type, params)
		if comp_type == "ItemCostComponent" then
			local item = state.items_by_eid[eid]
			if item then item.price = math.floor(tonumber(params.cost) or 0) end
		end
	end
	env.EntityAddComponent = capture_item_cost
	env.EntityAddComponent2 = capture_item_cost

	env.GetUpdatedEntityID = function()
		if state.wand_being_generated then return state.wand_being_generated.eid end
		return 0
	end

	env.EntityGetTransform = function(eid)
		if state.wand_being_generated and eid == state.wand_being_generated.eid then
			return state.wand_being_generated.x, state.wand_being_generated.y
		end
		return 0, 0
	end

	-- Returns a deterministic fake component id for the wand's AbilityComponent only.
	env.EntityGetFirstComponent = function(eid, comp_type, _)
		if state.wand_being_generated and eid == state.wand_being_generated.eid then
			if comp_type == "AbilityComponent" then return state.wand_being_generated.eid * 100 + 1 end
		end
		return nil
	end

	-- Captures gun_config / gunaction_config stats written by make_wand_from_gun_data.
	env.ComponentObjectSetValue = function(comp, _, key, val)
		if state.wand_being_generated then
			if comp == state.wand_being_generated.eid * 100 + 1 then state.wand_being_generated.item.stats[key] = tonumber(val) or val end
		end
	end

	-- Captures mana/speed written by make_wand_from_gun_data; ignores visual-only keys.
	local WAND_STAT_KEYS = { mana_max = true, mana_charge_speed = true, gun_level = true }
	env.ComponentSetValue = function(comp, key, val)
		if state.wand_being_generated then
			if comp == state.wand_being_generated.eid * 100 + 1 and WAND_STAT_KEYS[key] then
				state.wand_being_generated.item.stats[key] = tonumber(val) or val
			end
		end
	end

	-- Captures wand sprite path from SetWandSprite in make_wand_from_gun_data.
	env.SetWandSprite = function(eid, _, sprite_path)
		if state.wand_being_generated and eid == state.wand_being_generated.eid then state.wand_being_generated.item.sprite = sprite_path end
	end

	-- Deck and always-cast spell capture; replaces gun_action_utils versions so EntityAddChild
	-- (nulled above) is never called with a fake eid.
	env.AddGunAction = function(_, action_id)
		if state.wand_being_generated and action_id ~= "" then
			local s = state.wand_being_generated.item.spells
			s[#s + 1] = action_id
		end
	end

	env.AddGunActionPermanent = function(_, action_id)
		if state.wand_being_generated and action_id ~= "" then
			local ac = state.wand_being_generated.item.always_cast
			ac[#ac + 1] = action_id
		end
	end

	-- Shadow EntityLoad to capture wands (triggering gen script inline) and sale indicators.
	-- Spell order: CreateItemActionEntity -> [sale_indicator] -> EntityAddComponent
	-- Wand order:  [sale_indicator] -> EntityLoad(wand) -> EntityAddComponent
	env.EntityLoad = function(path, x, y)
		if path == "data/entities/buildings/shop_hitbox.xml" then return 0 end
		if path == "data/entities/misc/sale_indicator.xml" then
			local last = state.captured_items[#state.captured_items]
			if last and not last.is_wand then
				last.is_cheap = true
			else
				state.pending_cheap = true
			end
			return 0
		end
		if path:find("entities/items/wand", 1, true) then
			state.fake_eid = state.fake_eid + 1
			local wand_eid = state.fake_eid
			local item = {
				id = path,
				is_wand = true,
				is_cheap = state.pending_cheap,
				price = 0,
				sprite = nil,
				stats = {},
				spells = {},
				always_cast = {},
			}
			state.pending_cheap = false
			state.items_by_eid[wand_eid] = item
			state.captured_items[#state.captured_items + 1] = item
			-- Run the wand's procedural gen script inline so it executes with our shadows active.
			-- gun_procedural.lua is pre-loaded at the top of _setup_env(), so wand scripts'
			-- dofile_once calls hit the env cache and our AddGunAction/Permanent shadows are not overwritten.
			-- Round to nearest integer pixel: Noita snaps entity transforms to the pixel grid
			-- on load. Without this, wands 2+ use float offsets (e.g. trigger_x + 26.4) and
			-- generate_gun seeds with a wrong value. math.floor(v + 0.5) = round-to-nearest.
			state.wand_being_generated = { eid = wand_eid, x = math.floor(x + 0.5), y = math.floor(y + 0.5), item = item }
			local script_path = path:gsub("data/entities/items/", "data/scripts/gun/procedural/"):gsub("%.xml$", ".lua")
			pcall(env.dofile, script_path)
			state.wand_being_generated = nil
			return wand_eid
		end
		return 0
	end
end

---Simulate shop contents for all mountains at the given world x offset.
---Safe to call from post_world_init onwards; re-call when world state changes.
---@param world_x_offset number  0 for main world, negative for west, positive for east
function shop_predictor:predict(world_x_offset)
	if #self.altar_positions == 0 or not self.shop_dx then return end

	self:_setup_env()

	local state = self._state ---@cast state -?
	local env = self._env ---@cast env -?

	local mountains = {}
	for _, pos in ipairs(self.altar_positions) do
		state.captured_scene_x = nil
		state.captured_scene_y = nil
		state.captured_items = {}
		state.items_by_eid = {}
		state.fake_eid = 0
		state.pending_cheap = false

		local shifted_x = pos.world_x + world_x_offset
		env.init(shifted_x, pos.world_y)

		if state.captured_scene_x then
			local trigger_x = state.captured_scene_x + self.shop_dx
			local trigger_y = state.captured_scene_y + self.shop_dy
			env.spawn_all_shopitems(trigger_x, trigger_y)
			mountains[#mountains + 1] = {
				world_x = shifted_x,
				world_y = pos.world_y,
				items = state.captured_items,
			}
		end
	end

	table.sort(mountains, function(a, b)
		return a.world_y < b.world_y
	end)
	self.mountains = mountains
end

return shop_predictor
