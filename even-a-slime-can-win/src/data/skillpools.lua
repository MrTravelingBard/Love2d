-- Pools of skills, keyed by title id (or shop id).
-- Entries are resolved to the skill tables from data/skills.lua.
-- A typo in a skill key raises an error at load time instead of silently giving nil.
local skills = require("data.skills")

local function pool(...)
	local out = {}
	for _, key in ipairs({ ... }) do
		out[#out + 1] = assert(skills[key], "unknown skill key: " .. tostring(key))
	end
	return out
end

return {
	quick_blow  = pool("stunning", "quick_blow"),
	immortal    = pool("immortal", "revenge"),
    eldest      = pool("legacy", "gift"),
	slip_master = pool("slippery", "slip_stance"),
	coiled      = pool("capitalize", "coil"),
    constrictor = pool("lingering", "constrict"),
	red         = pool("red", "gold_burn", "recover_mp"),
	once_red    = pool("once_red", "mana_dart"),
	metal_sworn = pool("metal_sworn", "absorb"),
	metal       = pool("metal", "sword", "shield"),
    green       = pool("green","healing_poultice","the_green"),
    purple      = pool("purple","poison_impact"),
	kingslayer  = pool("kingslayer", "sharpen"),
    -- spell shops
	shop_1      = pool("fire_dart", "cold_breeze", "static_bolt", "minor_shielding"),
    shop_2      = pool("lesser_fireball","lesser_heat","lesser_frost","lesser_lightning","minor_bulwark")
	-- planned: skill shops
}