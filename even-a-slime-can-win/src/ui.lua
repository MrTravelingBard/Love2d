-- UI contains menu, panel, and text related functions
local gfx = require("gfx")
local input = require("input")
local M = {}

M.CHAR_W, M.LINE_H = 4, 6
M.LIMIT_FULL = 31      -- chars per line on a full-width screen
M.LIMIT_DIALOGUE = 29  -- chars per line inside the dialogue box

-- =Menu=

function M.control(sel, count)
    -- up/down moves the selection (wrapping); O confirms, X goes back.
    -- returns new_selection, action  (action is "confirm", "back" or nil)
	if count == 0 then
		sel = 1
	else
		if input.btnp(2) then
			sel = sel - 1
			if sel < 1 then
				sel = count
			end
		end

		if input.btnp(3) then
			sel = sel + 1
			if sel > count then
				sel = 1
			end
		end
	end
   	
    local action = nil
	if input.btnp(4) then
        action = "confirm"
    elseif input.btnp(5) then
        action = "back"
    end
	
    return sel, action
end

-- =Panel=
-- Boxes and small pixel icons
function M.draw(x0, y0, x1, y1, c)
	gfx.rectfill(x0, y0, x1, y1, c or 1)
	gfx.rect(x0, y0, x1, y1, 7)
end

function M.arrow_down(x, y, c)
    -- 5x3 "more text" arrow
	gfx.rectfill(x, y, x + 4, y, c)
	gfx.rectfill(x + 1, y + 1, x + 3, y + 1, c)
	gfx.pset(x + 2, y + 2, c)
end

function M.arrow_right(x, y, c)
    -- 3x5 menu cursor
	gfx.rectfill(x, y, x, y + 4, c)
	gfx.rectfill(x + 1, y + 1, x + 1, y + 3, c)
	gfx.pset(x + 2, y + 2, c)
end

-- =Text=
function M.wrap(str, limit)
	-- word-wrap to `limit` characters per line 
    -- returns one string with "\n" breaks
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

function M.wrap_string(str, is_dialogue)
	return M.wrap(str, is_dialogue and M.LIMIT_DIALOGUE or M.LIMIT_FULL)
end

function M.draw_centered(str, y, c)
	local w = gfx.W or 128
	gfx.print(str, w / 2 - #str * M.CHAR_W / 2, y or 60, c or 7)
end

function M.footer(hint)
    -- divider line + hint text along the bottom edge
	gfx.line(0, 120, 127, 120, 5)
	gfx.print(hint, 4, 122, 6)
end

return M