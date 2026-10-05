-- `order` is the order titles appear in the party builder / swap screen.
-- `unlock` is optional. A title with no unlock function is always available.
-- unlock functions receive members and flags.

local M = {}

M.order = {
	"quick_blow", "immortal", "eldest", "slip_master", "coiled",
	"constrictor", "red", "once_red", "metal_sworn", "metal", 
    "green", "purple", "kingslayer"
}

M.defs = {
	quick_blow  = { name = "the quick blow",       sprite = 1 },
	immortal    = { name = "the immortal",         sprite = 8 },
    eldest      = { name = "the eldest's legacy",  sprite = 1 },
	slip_master = { name = "the slip master",      sprite = 1 },
	coiled      = { name = "the coiled one",       sprite = 1 },
    constrictor = { name = "the constrictor",      sprite = 1 },
	red         = { name = "the red",              sprite = 15 },

	once_red = {
		name = "the once red", sprite = 29,
		-- must have been red before
		unlock = function(m, flags)
			return (m.mastered_titles and m.mastered_titles.red) or false
		end,
	},

	metal_sworn = { name = "the metalsworn", sprite = 57 },

	metal = {
		name = "the metal", sprite = 50,
		-- must have mastered metal_sworn and used absorb 10+ times
		unlock = function(m, flags)
			local mastered = m.mastered_titles and m.mastered_titles.metal_sworn
			local uses = (m.skill_uses and m.skill_uses.absorb) or 0
			return (mastered and uses >= 10) or false
		end
	},

    green = {
        name = "the green", sprite = 22,
        -- must have used 10+ herbs
        unlock = function(m, flags)
            local uses = m.herb_uses or 0
            return uses >=10 or false
        end
    },

    purple = {
        name = "the purple", sprite = 43,
        -- must have unlocked the purple ritual with Nib
        unlock = function(m, flags)
            return flags.purple_ritual_unlocked == true
        end
    },

	kingslayer = {
		name = "the kingslayer", sprite = 36,
		-- must have defeated the rat king
		unlock = function(m, flags)
			return flags.rat_king_defeated == true
		end
	}
}

return M