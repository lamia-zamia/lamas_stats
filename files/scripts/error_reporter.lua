---@class error_reporter
local reporter = {}

---Spams error everywhere
---@param text string
function reporter:Report(text)
	local err_msg = "[Lamas Stats]: error - " .. (text or "unknown error")
	print("\27[31m[Lamas Stats Error]\27[0m")
	print(err_msg)
	GamePrint(err_msg)
end

return reporter
