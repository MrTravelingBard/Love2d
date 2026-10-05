-- Tile numbers are PICO-8 sprite indices (0-255), same as the map data.

local function set(list)
	local s = {}
	for _, v in ipairs(list) do s[v] = true end
	return s
end

local M = {}

M.empty = 204 -- what a pickup tile turns into once collected

M.wall = set{
	192,193,194,195,196,197,198,203,205,206,
	208,213,214,215,216,217,218,219,224,229,230,231,
	232,233,238,239,240,245,246,247,249,250,
}

-- amount gained when interacting with the tile
M.herb = { [220] = 1, [221] = 1, [222] = 3 }
M.gold = { [223] = { 1, 1 }, [236] = { 4, 6 }, [237] = { 12, 16 } } -- {min, max}

-- tiles that heal the party when interacted with
M.recover = set{ 238, 239, 252 }

-- animated tiles: every map_anim ticks, each pair swaps between its two frames
M.anim_pairs = { { 238, 239 }, { 254, 255 } }
M.anim_interval = 15

-- tiles the party can't walk onto: walls, herbs, gold
M.solid = {}
for t in pairs(M.wall) do M.solid[t] = true end
for t in pairs(M.herb) do M.solid[t] = true end
for t in pairs(M.gold) do M.solid[t] = true end

return M