-- Dialogue boxes. The overworld calls start() when O is pressed next to an NPC,
-- then update()/draw() while M.active.
--
-- Battles: set M.hooks.start_battle = function(def) ... end  (def = entry.battle from data/npcs.lua,
-- e.g. { group="rats_x2", win_sets={"enemies_defeated"} }). It runs after the box closes.

local gfx = require("gfx")
local input = require("input")
local flags = require("systems/flags")
local facing = require("systems/facing")
local text = require("ui/text")
local panel = require("ui/panel")

local M = { active = false, page = 1, hooks = {} }

local BOX = { x = 4, y = 88, w = 120, h = 36, pad = 4, name_h = 8 }

-- first entry whose flag conditions pass
function M.find_entry(npc)
	for _, entry in ipairs(npc.dialogue or {}) do
		if flags.check(entry.requires, entry.forbids) then return entry end
	end
	return nil
end

local function set_page(n)
	M.page = n
	M.wrapped = text.wrap_string(M.entry.pages[n], true) -- wrap once per page, not per frame
end

-- party_dx/dy: the direction the party is facing; the NPC turns to face back at them
function M.start(npc, party_dx, party_dy)
	local entry = M.find_entry(npc)
	if not entry then return false end

	npc.saved_facing = { sprite_offset = npc.sprite_offset, flip_x = npc.flip_x }
	local dir = facing.from_delta(-(party_dx or 0), -(party_dy or 0))
	if dir then facing.apply(npc, dir) end

	M.active, M.npc, M.entry = true, npc, entry
	set_page(1)
	return true
end

function M.advance()
	if not M.active then return end
	if M.page < #M.entry.pages then
		set_page(M.page + 1)
	else
		M.close()
	end
end

function M.close()
	local npc, entry = M.npc, M.entry
	if npc and npc.saved_facing then
		npc.sprite_offset = npc.saved_facing.sprite_offset
		npc.flip_x = npc.saved_facing.flip_x
		npc.saved_facing = nil
	end
	M.active, M.npc, M.entry, M.wrapped = false, nil, nil, nil

	if entry then
		flags.set_all(entry.sets)
		if entry.battle and M.hooks.start_battle then M.hooks.start_battle(entry.battle) end
	end
end

function M.update()
	if not M.active then return end
	if input.btnp(4) then M.advance() end
end

function M.draw()
	if not M.active then return end
	local bx, by, bw, bh, p = BOX.x, BOX.y, BOX.w, BOX.h, BOX.pad

	gfx.rectfill(bx + 2, by + 2, bx + bw + 2, by + bh + 2, 0) -- drop shadow
	panel.draw(bx, by, bx + bw, by + bh)

	if M.npc and M.npc.name then
		local nw = #M.npc.name * text.CHAR_W + p * 2
		panel.draw(bx, by - BOX.name_h, bx + nw, by)
		gfx.print(M.npc.name, bx + p, by - BOX.name_h + 2, 7)
	end

	gfx.print(M.wrapped, bx + p, by + p, 7)

	if (love.timer.getTime() * 4) % 2 < 1 then
		panel.arrow_down(bx + bw - 9, by + bh - 7, 6)
	end
end

return M