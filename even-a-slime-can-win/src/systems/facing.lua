-- Facing break out logic
-- sprite_offset: 0 = down, 1 = up, 2 = side (flip_x for left)

local M = {}

function M.apply(npc, dir)
	if dir == "r" then npc.sprite_offset, npc.flip_x = 2, false
	elseif dir == "l" then npc.sprite_offset, npc.flip_x = 2, true
	elseif dir == "u" then npc.sprite_offset = 1
	elseif dir == "d" then npc.sprite_offset = 0
	end
end

function M.from_delta(dx, dy)
	if dx < 0 then return "l"
	elseif dx > 0 then return "r"
	elseif dy < 0 then return "u"
	elseif dy > 0 then return "d"
	end
	return nil
end

return M