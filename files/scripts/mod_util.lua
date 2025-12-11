---@class mod_util
local util = {
	mod_prfx = "lamas_stats.",
}

---Returns string setting
---@param id string
---@return string
function util:GetSettingString(id)
	return tostring(ModSettingGet(self.mod_prfx .. id))
end

---Returns number setting
---@param id string
---@param default? number
---@return number
function util:GetSettingNumber(id, default)
	return tonumber(ModSettingGet(self.mod_prfx .. id)) or default or 0
end

---Returns boolean setting
---@param id string
---@return boolean
function util:GetSettingBoolean(id)
	return ModSettingGet(self.mod_prfx .. id) == true
end

---Returns global number
---@param id string
---@param default? number
---@return number
function util:GetGlobalNumber(id, default)
	return tonumber(GLOBALS_GET_VALUE(id, tostring(default or 0))) or 0
end

---Sets settings
---@param id string
---@param value number|string|boolean
function util:SetModSetting(id, value)
	ModSettingSet(self.mod_prfx .. id, value)
end

---Returns hotkey getter
---@param setting_id string hotkey_id
---@return fun():boolean
function util:get_hotkey(setting_id)
	local code = tonumber(self:GetSettingString(setting_id)) or 0
	local code_type = self:GetSettingString(setting_id .. "_type")
	local fn = code_type == "kb" and InputIsKeyJustDown or InputIsMouseButtonJustDown
	print(code, code_type)
	return function()
		return fn(code)
	end
end

return util
