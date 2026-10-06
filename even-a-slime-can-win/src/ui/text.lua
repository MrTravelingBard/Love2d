-- Text helpers

local gfx = require("gfx")
local M = {}

M.CHAR_W, M.LINE_H = 4, 6
M.LIMIT_FULL = 31      -- chars per line on a full-width screen
M.LIMIT_DIALOGUE = 29  -- chars per line inside the dialogue box

-- word-wrap to `limit` characters per line; returns one string with "\n" breaks
function M.wrap(str, limit)
	local lines, cur = {}, ""
	for word in str:gmatch("%S+") do
		if cur == "" then
			cur = word
		elseif #cur + 1 + #word <= limit then
			cur = cur .. " " .. word
		else
			lines[#lines + 1] = cur
			cur = word
		end
	end
	if cur ~= "" then lines[#lines + 1] = cur end
	return table.concat(lines, "\n")
end

-- same signature as the PICO-8 version, for easy porting
function M.wrap_string(str, is_dialogue)
	return M.wrap(str, is_dialogue and M.LIMIT_DIALOGUE or M.LIMIT_FULL)
end

function M.draw_centered(str, y, c)
	local w = gfx.W or 128
	gfx.print(str, w / 2 - #str * M.CHAR_W / 2, y or 60, c or 7)
end

-- divider line + hint text along the bottom edge
function M.footer(hint)
	gfx.line(0, 120, 127, 120, 5)
	gfx.print(hint, 4, 122, 6)
end

return M