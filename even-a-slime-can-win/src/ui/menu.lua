-- Menu UI logic

local input = require("input")
local M = {}

-- up/down moves the selection (wrapping); O confirms, X goes back.
-- returns new_selection, action  (action is "confirm", "back" or nil)
function M.control(sel, count)
	if input.btnp(2) then
		sel = sel - 1
		if sel < 1 then sel = count end
	end
	if input.btnp(3) then
		sel = sel + 1
		if sel > count then sel = 1 end
	end
	local action = nil
	if input.btnp(4) then action = "confirm" elseif input.btnp(5) then action = "back" end
	return sel, action
end

return M