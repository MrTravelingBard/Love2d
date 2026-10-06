-- Overworld scene
-- Walking around the map, talking to NPCs, picking things up, opening the status screen.

local gfx = require("gfx")
local input = require("input")
local party = require("systems/party")
local flags = require("systems/flags")
local npc = require("systems/npc")
local tilemap = require("systems/tilemap")
local tiles = require("data/tiles")
local dialogue = require("ui/dialogue")
local status = require("ui/status")
local battle = require("scenes/battle")

local M = {}

local recover_anim, herb_anim, gold_anim, game_over

function M.reset()
	recover_anim, herb_anim, gold_anim = 0, 0, 0
	game_over = false
end
M.reset()

-- dialogue can end by starting a battle; flags in on_win are set only if the party wins
dialogue.hooks.start_battle = function(def)
	battle.start(def.group, function(won)
		if won then flags.set_all(def.on_win) end
	end)
end

-- ---- party movement and interaction ----
local function can_move(x, y)
	return not npc.at(x, y) and not tilemap.is_solid(x, y)
end

local function interact()
	local tx, ty = party.x + party.dx, party.y + party.dy

	local target = npc.at(tx, ty)
	if target then
		dialogue.start(target, party.dx, party.dy)
		return
	end

	local t = tilemap.get(tx, ty)
	if tiles.recover[t] then
		party.heal_full()
		recover_anim = 24
	elseif tiles.herb[t] then
		party.herb = party.herb + tiles.herb[t]
		tilemap.set(tx, ty, tiles.empty)
		flags.set("herb_collected")
		herb_anim = 24
	elseif tiles.gold[t] then
		local range = tiles.gold[t]
		party.gold = party.gold + love.math.random(range[1], range[2])
		tilemap.set(tx, ty, tiles.empty)
		gold_anim = 24
	end
end

local function update_party()
	local movex, movey = 0, 0

	if recover_anim > 0 then recover_anim = recover_anim - 1 end
	if herb_anim > 0 then herb_anim = herb_anim - 1 end
	if gold_anim > 0 then gold_anim = gold_anim - 1 end

	if input.btnp(0) then
		party.sprite_offset, movex, party.flip_x = 2, -1, true
	elseif input.btnp(1) then
		party.sprite_offset, movex, party.flip_x = 2, 1, false
	end
	if input.btnp(2) then
		party.sprite_offset, movey = 1, -1
	elseif input.btnp(3) then
		party.sprite_offset, movey = 0, 1
	end

	if movex ~= 0 or movey ~= 0 then party.dx, party.dy = movex, movey end

	if input.btnp(4) then interact() end

	local nx, ny = party.x + movex, party.y + movey
	if can_move(nx, ny) then
		party.x = math.max(0, math.min(nx, 127))
		party.y = math.max(0, math.min(ny, 63))
	end
end

-- ---- scene interface ----
function M.update()
	tilemap.update()

	if game_over then
		if input.btnp(5) then love.event.quit("restart") end
		return
	end
	if dialogue.active then
		dialogue.update()
	elseif status.active then
		status.update()
	else
		npc.update()
		update_party()
		if input.btnp(5) then status.open() end
	end

	if party.wiped() then game_over = true end
end

local function draw_aura(c)
	local o
	if party.dx == 0 then
		o = party.flip_x and 0 or 1
	else
		o = party.dx + (party.flip_x and 1 or 0)
	end
	gfx.circfill(party.x * 8 + 3 + o, party.y * 8 + 5, 4, c)
end

local function draw_party()
	if recover_anim > 0 and recover_anim % 4 < 2 then draw_aura(12) end
	if herb_anim > 0 and herb_anim % 4 < 2 then draw_aura(11) end
	if gold_anim > 0 and gold_anim % 4 < 2 then draw_aura(10) end
	gfx.spr(party.sprite + party.sprite_offset, party.x * 8, party.y * 8, 1, 1, party.flip_x)
end

function M.draw()
	gfx.cls(0)
	if game_over then
		gfx.camera()
		gfx.print("game over! :(", 38, 64, 7)
		gfx.print("press x to play again", 20, 72, 5)
		return
	end

	-- the map scrolls in 16x16-tile screens
	local mx, my = math.floor(party.x / 16) * 16, math.floor(party.y / 16) * 16
	gfx.camera(mx * 8, my * 8)
	tilemap.draw(mx, my, 16, 16)
	npc.draw()
	draw_party()
	gfx.camera()

	dialogue.draw()
	status.draw()
end

return M