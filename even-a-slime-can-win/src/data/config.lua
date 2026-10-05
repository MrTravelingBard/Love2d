-- Small constants that used to be scattered through the .p8

return {
    game_title = "Even a Slime Can Win",
	version = "v0.1.1",

    -- window config
    window = {
        width = 768,
        height = 768
    },

	-- where the party spawns (tile coordinates)
	start = { x = 5, y = 5 },

	-- party builder
	party_size = 4,
	name_length = 3,
	default_names = { "zag", "gig", "mab", "bib", "gaz", "nim", "pib" },
	base_stats = { str = 1, dex = 1, con = 1, mag = 1 },

	-- order of the tabs on the status screen
	status_sections = { "skills", "spells", "titles" },
}