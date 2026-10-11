-- Intro scene

local gfx = require("gfx")
local input = require("input")
local scene = require("scene")
local ui = require("ui")

local M = {}
local timer

local function love_splash()
	ui.draw_centered("built with love2d",60,14)
end

local function studio_splash()
	ui.draw_centered("a mr traveling bard production")
end

function M.enter()
	gfx.pal(0, 128, 1) -- screen color 0 becomes the dark brown "secret" color 128
	timer = 120
end

function M.update()
	timer = timer - 1
	if input.btnp(4) or timer <= 0 then
		scene.switch(require("scenes/mainmenu"))
	end
end

function M.draw()
	gfx.cls()
	if timer > 60 then
		love_splash()
	else 
		studio_splash()
	end
end

return M