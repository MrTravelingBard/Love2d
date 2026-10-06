-- NPC system
-- Live NPC state built from data/npcs.lua: position, facing, scripted walks.

local gfx = require("gfx")
local flags = require("systems/flags")
local facing = require("systems/facing")
local data = require("data/npcs")

local M = { list = {} }

local DIRS = { r = { 1, 0 }, l = { -1, 0 }, u = { 0, -1 }, d = { 0, 1 } }

-- (re)build every NPC from the data; call at new game
function M.init()
	M.list = {}
	for _, d in ipairs(data) do
		local npc = {
			name = d.name, x = d.x, y = d.y, sprite = d.sprite,
			dialogue = d.dialogue,
			moves = {},                 -- copied: a move is removed once it triggers
			px = d.x * 8, py = d.y * 8, -- pixel position (smooth while walking)
			sprite_offset = 0, flip_x = false,
			path = {},
		}
		for i, mv in ipairs(d.moves or {}) do npc.moves[i] = mv end
		if d.facing then facing.apply(npc, d.facing) end
		M.list[#M.list + 1] = npc
	end
end

function M.at(x, y)
	for _, npc in ipairs(M.list) do
		if npc.x == x and npc.y == y then return npc end
	end
	return nil
end

-- steps: {"r","d","f_r",...}  ->  { {x,y}, {face="r"}, ... }
local function build_path(x, y, steps)
	local path = {}
	for _, step in ipairs(steps) do
		if step:sub(1, 2) == "f_" then
			path[#path + 1] = { face = step:sub(3) }
		else
			local d = DIRS[step]
			x, y = x + d[1], y + d[2]
			path[#path + 1] = { x, y }
		end
	end
	return path
end

local function ease_toward(npc, tx, ty, speed)
	local dx, dy = tx - npc.px, ty - npc.py
	local dist = math.sqrt(dx * dx + dy * dy)
	if dist <= speed or dist < 1 then
		npc.px, npc.py = tx, ty
		return true
	end
	npc.px = npc.px + dx / dist * speed
	npc.py = npc.py + dy / dist * speed
	return false
end

local function update_walk(npc)
	local nxt = npc.path[1]
	if not nxt then return end

	if nxt.face then -- turn in place for a moment
		if not npc.face_timer then
			facing.apply(npc, nxt.face)
			npc.face_timer = npc.face_hold or 20
		end
		npc.face_timer = npc.face_timer - 1
		if npc.face_timer <= 0 then
			npc.face_timer = nil
			table.remove(npc.path, 1)
		end
		return
	end

	local tx, ty = nxt[1] * 8, nxt[2] * 8
	local dx, dy = tx - npc.px, ty - npc.py
	if ease_toward(npc, tx, ty, npc.walk_speed or 1) then
		npc.x, npc.y = nxt[1], nxt[2]
		table.remove(npc.path, 1)
		return
	end
	if math.abs(dx) > math.abs(dy) then
		npc.sprite_offset, npc.flip_x = 2, dx < 0
	elseif dy < 0 then
		npc.sprite_offset = 1
	else
		npc.sprite_offset = 0
	end
end

-- start any scripted move whose flag conditions are now met (each fires once)
local function update_moves()
	for _, npc in ipairs(M.list) do
		for i = #npc.moves, 1, -1 do
			local m = npc.moves[i]
			if flags.check(m.requires, m.forbids) then
				npc.path = build_path(npc.x, npc.y, m.steps)
				npc.walk_speed = m.speed
				table.remove(npc.moves, i)
			end
		end
	end
end

function M.update()
	update_moves()
	for _, npc in ipairs(M.list) do
		if #npc.path > 0 then update_walk(npc) end
	end
end

function M.draw()
	for _, npc in ipairs(M.list) do
		gfx.spr(npc.sprite + npc.sprite_offset, npc.px, npc.py, 1, 1, npc.flip_x)
	end
end

return M