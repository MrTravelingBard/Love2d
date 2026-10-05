-- Dialogue entries are checked top to bottom; the first one whose conditions pass is used.
--   must_have    = { "flag", ... }   all of these flags must be set
--   cannot_have  = { "flag", ... }   none of these flags may be set
--   pages        = { "text", ... }
--   sets         = { "flag", ... }   flags set when the dialogue closes
--   battle       = { group = "rats_x2", win_sets = { "flag" } } battle starts when the dialogue closes 
-- Win_sets: set only if the party wins
-- Moves: when `must_have` passes, the NPC walks `steps` once.
-- Steps: r/l/u/d, or f_<dir> to turn and face a direction.

local function list(s)
	local t = {}
	for w in s:gmatch("[^,]+") do t[#t + 1] = w end
	return t
end

return {
	{
		name = "rix the guardian", x = 12, y = 8, sprite = 1, facing = "r",
		dialogue = {
			{
				cannot_have = { "quest_started" },
				pages = {
					"the colony is under attack! monsters from the east!",
					"please, you must help us before it is too late!",
				},
				sets = { "quest_started" },
			},
			{
				must_have = { "quest_started" }, cannot_have = { "enemies_defeated" },
				pages = { "here they come!" },
				battle = { group = "rats_x2", win_sets = { "enemies_defeated" } },
			},
			{
				must_have = { "enemies_defeated" }, cannot_have = { "elder_spoken_to" },
				pages = {
					"you did it! you pushed them back!",
					"the elder will want to speak with you.",
				},
			},
			{
				pages = { "the colony is safe once more thanks to you." },
			},
		},
		moves = {
			{ must_have = { "elder_spoken_to" }, steps = list("r,r,r,r,r,r,r,d,f_r"), speed = 0.5 },
		},
	},

	{
		name = "nib the once-red", x = 6, y = 1, sprite = 29,
		dialogue = {
			{
				cannot_have = { "enemies_defeated" },
				pages = { "sorry, i'm busy right now collecting my mana for spells if you fail." },
			},
			{
				must_have = { "enemies_defeated" },
				pages = {
					"good, you defeated them. i thought a static bolt would be needed.",
					"you have potential. perhaps i can teach you true power in the future.",
				},
			},
		},
	},

	{
		name = "lib the metalsworn", x = 2, y = 11, sprite = 57,
		dialogue = {
			{
				pages = {
					"sorry, i'm focused on absorbing this metal. it takes a lot of effort",
					"but it will be worth it to become a metal slime. all that power.",
					"though it's been many years since we've seen any...",
				},
			},
		},
	},

	{
		name = "zig the hero", x = 4, y = 1, sprite = 8,
		dialogue = {
			{
				cannot_have = { "enemies_defeated" },
				pages = {
					"use the skills i taught you to defeat the enemies at the gate.",
					"i believe in you.",
				},
			},
			{
				must_have = { "enemies_defeated" },
				pages = {
					"well done! but don't get sloppy. you still have much to learn.",
					"i will teach you all that i know soon enough. you'll need every advantage you can get for the battles to come.",
				},
			},
		},
	},

	{
		name = "gab the guardian", x = 10, y = 6, sprite = 1,
		dialogue = {
			{
				pages = {
					"another fight is coming. i'd rather skip it if i'm being honest.",
					"i want to protect our people of course, but not dying is also nice.",
				},
			},
		},
		moves = {
			{ must_have = { "elder_spoken_to" }, steps = list("d,d,r,r,r,r,r,r,r,r,r,u,u,f_r"), speed = 0.6 },
		},
	},

	{
		name = "rax the guardian", x = 2, y = 3, sprite = 8, facing = "r",
		dialogue = {
			{
				cannot_have = { "rax_intro" },
				pages = {
					"i guard the sacred spawning pool of our people.",
					"it is truly an honor but also a great responsibility.",
				},
				sets = { "rax_intro" },
			},
			{
				pages = {
					"if you venture to the rat tunnels, take care not to get lost in its turns.",
					"some tunnels lead nowhere merely traps they will use to close in on you.",
				},
			},
		},
	},

	{
		name = "bab", x = 8, y = 7, sprite = 1, facing = "l",
		dialogue = {
			{
				cannot_have = { "herb_collected" },
				pages = {
					"see that green herb? eventually you'll be able to collect them.",
					"they are healing items and may even unlock some interesting powers.",
				},
			},
		},
	},

	{
		name = "gog", x = 10, y = 3, sprite = 1, facing = "r",
		dialogue = {
			{
				pages = {
					"zig is much older than he looks. which one? they used to be one in the same.",
					"that was back before they divided. zig has been a legend since before i spawned.",
				},
			},
		},
	},

	{
		name = "mub", x = 5, y = 11, sprite = 1, facing = "u",
		dialogue = {
			{
				pages = {
					"we haven't heard from the southern colony in awhile.",
					"we sent them our gold to fuel their defenses after all their losses during the last war with the rats.",
					"of the five slime colonies only we two remain. i hope they are safe. eldest preserve us.",
				},
			},
		},
	},

	{
		name = "nax", x = 8, y = 2, sprite = 1,
		dialogue = {
			{
				pages = {
					"nib and zig are powerful enough to drive off the rats. in their prime, they could even ward off humans.",
					"i worry though for the cost of using power has it's toll.",
					"even greats like nib and zig must eventually retire to the spawning pool.",
				},
			},
		},
	},

	{
		name = "fin", x = 2, y = 4, sprite = 1, facing = "r",
		dialogue = {
			{
				pages = {
					"zig the elder has been sharing the lore of our people with me.",
					"he was once known as the loremaster before he divided.",
					"i wonder if he means to pass the title...",
				},
			},
		},
	},

	{
		name = "zig the elder", x = 5, y = 1, sprite = 1,
		dialogue = {
			{
				cannot_have = { "enemies_defeated", "elder_spoken_to" },
				pages = { "our survival relies on you four. such a burden despite your youth..." },
			},
			{
				must_have = { "enemies_defeated" }, cannot_have = { "elder_spoken_to" },
				pages = {
					"thank you for dealing with those assailants.",
					"your bravery and strength will take you far.",
				},
				sets = { "elder_spoken_to" },
			},
			{
				must_have = { "elder_spoken_to" },
				pages = {
					"would you like to hear the old stories of our people?",
					"the eldest, the dragon, the garuda, the hero, or the lost kings?",
					"no? maybe next time then.",
				},
			},
		},
	},
}