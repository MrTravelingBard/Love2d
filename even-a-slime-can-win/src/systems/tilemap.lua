-- Copy of the map (pickups and animation change tiles at runtime).
-- Coordinates are 0-based tile positions, like PICO-8's mget/mset.

local gfx = require("gfx")
local tiles = require("data/tiles")

local M = {}
local rows = {}

-- copy the pristine generated map; call again to reset (e.g. new game)
function M.reset()
	local src = require("data.map")
	rows = {}
	for y, r in ipairs(src.rows) do
		local copy = {}
		for x, t in ipairs(r) do copy[x] = t end
		rows[y] = copy
	end
	M.width, M.height = src.width, src.height
	M.anim_timer = tiles.anim_interval
end

function M.get(x, y)
	local r = rows[y + 1]
	return (r and r[x + 1]) or 0
end

function M.set(x, y, t)
	rows[y + 1] = rows[y + 1] or {}
	local r = rows[y + 1]
	for i = #r + 1, x do r[i] = 0 end -- fill any gap so the row stays a proper array
	r[x + 1] = t
end

function M.is_solid(x, y)
	return tiles.solid[M.get(x, y)] or false
end

-- draw a block of tiles starting at tile (x0, y0); tile 0 is skipped like PICO-8's map()
function M.draw(x0, y0, w, h)
	for y = y0, y0 + h - 1 do
		for x = x0, x0 + w - 1 do
			local t = M.get(x, y)
			if t ~= 0 then gfx.spr(t, x * 8, y * 8) end
		end
	end
end

-- swap animated tiles between their two frames
function M.animate()
	local swap = {}
	for _, p in ipairs(tiles.anim_pairs) do
		swap[p[1]] = p[2]
		swap[p[2]] = p[1]
	end
	for y = 1, #rows do
		local r = rows[y]
		for x = 1, #r do
			local to = swap[r[x]]
			if to then r[x] = to end
		end
	end
end

-- call once per 30fps tick
function M.update()
	M.anim_timer = M.anim_timer - 1
	if M.anim_timer < 0 then
		M.animate()
		M.anim_timer = tiles.anim_interval
	end
end

M.reset()
return M