-- Game manager
-- Resets all game state for a new run.

local flags = require("systems/flags")
local party = require("systems/party")
local tilemap = require("systems/tilemap")
local npc = require("systems/npc")
local overworld = require("scenes/overworld")

local M = {}

function M.new(members)
	flags.reset()
	party.new_game(members)
	tilemap.reset()
	npc.init()
	overworld.reset()
end

return M