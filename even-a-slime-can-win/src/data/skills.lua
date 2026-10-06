-- Keyed by skill id. Fields:
--   name, type ("active"/"passive"), desc
--   mp_cost   mana cost (default 0)
--   coin_cost coins spent instead of mana (replaces the old "recover mp" name check)

local function skill(name, type_, desc, extra)
	local s = { name = name, type = type_, desc = desc, mp_cost = 0 }
	for k, v in pairs(extra or {}) do s[k] = v end
	return s
end

local skills = {
	-- quick blow
	stunning   = skill("stunning", "passive", "all attacks have a 25% chance to stun"),
	quick_blow = skill("quick blow", "active", "deals damage to single target with higher spd priority"),

    -- immortal
	immortal   = skill("immortal", "passive", "resurrect at the beginning of the round with 50% hp"),
	revenge    = skill("revenge", "active", "deals damage based on the number of deaths suffered since last use"),

	-- eldest
	legacy     = skill("eldest's legacy", "passive", "increased max hp by 300%"),
	gift       = skill("eldest's gift", "active", "gift a portion of your hp to others as healing with a 1:3 ratio"),

	-- slip master
	slippery    = skill("slippery", "passive", "upon dodging an attack inflict prone on attacker"),
	slip_stance = skill("slip stance", "active", "take a slippery stance which dodges all physical attacks"),

	-- coiled
	capitalize = skill("capitalize", "passive", "deals 2x damage to stunned or proned or constricted enemies"),
	coil       = skill("coil", "active", "charges a powerful attack for x turns and deals x * damage"),

    -- constrictor
	lingering  = skill("lingering impact", "passive", "when a debuff caused directly by you is removed add new debuffs in it's place"),
	constrict  = skill("constrict", "active", "constrict a single target which prevents them from acting based on strength vs target strength"),

	-- red
	red        = skill("red", "passive", "gains access to spells and gains mp based on mag stat 5:1"),
	gold_burn  = skill("gold burn", "passive", "each coin used to regain mp reduces maxhp by 1"),
	recover_mp = skill("recover mp", "active", "use a coin to recover all mp & increase max mp by 3", { coin_cost = 1 }),

	-- once red
	once_red   = skill("once red", "passive", "retains access to spells and mp from being red"),
	mana_dart  = skill("mana dart", "active", "magical damage based on remaining mana", { mp_cost = 1 }),

	-- metal sworn
	metal_sworn = skill("metal sworn", "passive", "once the metal is absorbed a new power will be born"),
	absorb      = skill("absorb", "active", "absorbs some of the metal and restores a low amount of hp to self"),

	-- metal
	metal  = skill("metal", "passive", "all damage taken reduced by 50%"),
	sword  = skill("sword", "active", "deals double damage & can inflict bleeding on a single target"),
	shield = skill("shield", "active", "acts as a shield by taking the hits for the party for a turn"),

    -- green
	green             = skill("green", "passive", "can absorb herbs as charges to be used in healing skills"),
	healing_poultice  = skill("healing poultice", "active", "use 1 charge to heal a single target"),
	the_green         = skill("the green", "active", "use 3 charges to heal the whole party"),

    -- purple
	purple        = skill("purple", "passive", "physical attacks dealt or taken can inflict poison"),
	poison_impact = skill("poison impact", "active", "deals damage based on number of poison stacks on target"),

	-- kingslayer
	kingslayer = skill("kingslayer", "passive", "deal 2x total damage to boss enemies or 3x if they are bleeding"),
	sharpen    = skill("sharpen", "active", "increases a single target's atk stat by 4 (stacks up to 3 times)"),

	-- spells (shop_1)
	fire_dart     = skill("fire dart", "active", "deals minor fire damage to a single target", { mp_cost = 1 }),
	cold_breeze   = skill("cold breeze", "active", "deals minor ice damage to a single target", { mp_cost = 1 }),
	static_bolt   = skill("static bolt", "active", "deals moderate lightning damage to a random target", { mp_cost = 1 }),
	minor_shielding  = skill("minor shielding", "active", "increases a single target's def by 4 (stacks up to 3 times)", { mp_cost = 1 }),

    -- spells (shop_2)
	lesser_fireball  = skill("lesser fireball", "active", "deals moderate fire damage to a single target with a 50% chance to inflict burn", { mp_cost = 1 }),
	lesser_heat      = skill("lesser heat", "active", "if wearing metal a single target takes major fire damage and is inflicted with a def debuff", { mp_cost = 1 }),
	lesser_frost     = skill("lesser frost", "active", "deals moderate ice damage to a single target with a 50% chance to inflict slow", { mp_cost = 1 }),
	lesser_lightning = skill("lesser lightning", "active", "deals major lightning damage to a random target with a 50% chance to inflict stun", { mp_cost = 1 }),
	minor_bulwark = skill("minor bulwark", "active", "increases the whole party's def by 4 (stacks up to 3 times)", { mp_cost = 1 })
}

-- each skill knows its own key (used for passive checks like "red" / "legacy")
for id, s in pairs(skills) do s.id = id end

return skills