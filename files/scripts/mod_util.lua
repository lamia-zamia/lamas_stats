---@class mod_util
local util = {
	mod_prfx = "lamas_stats."
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

return util
