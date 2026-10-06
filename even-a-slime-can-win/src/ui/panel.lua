-- Boxes and small pixel icons (drawn with rects, so they don't depend on font glyphs).

local gfx = require("gfx")
local M = {}

function M.draw(x0, y0, x1, y1, c)
	gfx.rectfill(x0, y0, x1, y1, c or 1)
	gfx.rect(x0, y0, x1, y1, 7)
end

-- 5x3 "more text" arrow
function M.arrow_down(x, y, c)
	gfx.rectfill(x, y, x + 4, y, c)
	gfx.rectfill(x + 1, y + 1, x + 3, y + 1, c)
	gfx.pset(x + 2, y + 2, c)
end

-- 3x5 menu cursor
function M.arrow_right(x, y, c)
	gfx.rectfill(x, y, x, y + 4, c)
	gfx.rectfill(x + 1, y + 1, x + 1, y + 3, c)
	gfx.pset(x + 2, y + 2, c)
end

return M