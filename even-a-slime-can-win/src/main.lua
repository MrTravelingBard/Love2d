-- Main 

local gfx = require("gfx")
local input = require("input")
local scene = require("scene")
local game = require("game")
local party = require("systems/party")
local config = require("data/config")

local FONT_PATH, FONT_SIZE = "assets/PICO-8.ttf", 5

-- true = skip intro/menu/builder and drop straight into the overworld with a test party
local DEV_QUICKSTART = false

local STEP = 1 / 30 -- game logic runs at PICO-8's 30 ticks per second
local acc = 0

local function dev_party()
	local members = {}
	for i, title in ipairs({ "immortal", "quick_blow", "eldest", "red" }) do
		members[i] = party.new_member({ name = config.default_names[i], title = title })
	end
	return members
end

function love.load()
	gfx.init(FONT_PATH, FONT_SIZE)
	gfx.load_sheet("assets/sheet.png")
	if DEV_QUICKSTART then
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
	while acc >= STEP do
		acc = acc - STEP
		input.update()
		scene.update()
	end
end

function love.draw()
	gfx.begin()
	scene.draw()
	gfx.finish()
end