-- Definitions are templates. hp/mp start full, so only maxhp/maxmp are stored.

local M = {}

M.defs = {
	slime    = { name = "slime",    sprite = 1,  maxhp = 10, maxmp = 0,  atk = 3, def = 1, spd = 2, matk = 0, mdef = 0 },
	rat      = { name = "rat",      sprite = 66, maxhp = 10, maxmp = 0,  atk = 2, def = 2, spd = 2, matk = 0, mdef = 0 },
	rat_king = { name = "rat king", sprite = 69, maxhp = 60, maxmp = 10, atk = 5, def = 5, spd = 5, matk = 2, mdef = 2, boss = true },
}

M.groups = {
	slimes_x2 = { "slime", "slime" },
	rats_x2   = { "rat", "rat" },
	rat_king  = { "rat_king" },
}

-- Returns fresh copies so a battle can never modify the templates.
function M.make_group(group_id)
	local ids = assert(M.groups[group_id], "unknown enemy group: " .. tostring(group_id))
	local list = {}
	for _, id in ipairs(ids) do
		local copy = {}
		for k, v in pairs(M.defs[id]) do copy[k] = v end
		copy.skills = {}
		list[#list + 1] = copy
	end
	return list
end

return M