-- Main 

local gfx = require("gfx")
local input = require("input")
local scene = require("scene")
local game = require("game")
local party = require("systems/party")
local config = require("data/config")

local acc = 0

local function dev_party()
	local members = {}
	for i, title in ipairs({ "immortal", "quick_blow", "eldest", "red" }) do
		members[i] = party.new_member({ name = config.default_names[i], title = title })
	end
	return members
end

function love.load()
	gfx.init(config.font_path, config.font_size)
	gfx.load_sheet("assets/sheet.png")
	if config.dev_quickstart then
		game.new(dev_party())
		scene.switch(require("scenes/overworld"))
	else
		scene.switch(require("scenes/intro"))
	end
end

function love.keypressed(key)
	input.keypressed(key)
end

function love.resize()
	gfx.fit()
end

function love.update(dt)
	acc = math.min(acc + dt, 0.25)
	while acc >= config.game_speed do
		acc = acc - config.game_speed
		input.update()
		scene.update()
	end
end

function love.draw()
	gfx.begin()
	scene.draw()
	gfx.finish()
end