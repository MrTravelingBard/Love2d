-- Intro scene

local gfx = require("gfx")
local input = require("input")
local scene = require("scene")
local text = require("ui/text")

local M = {}
local timer

function M.enter()
	gfx.pal(0, 128, 1) -- screen color 0 becomes the dark brown "secret" color 128
	timer = 60
end

function M.update()
	timer = timer - 1
	if input.btnp(4) or timer <= 0 then
		scene.switch(require("scenes.mainmenu"))
	end
end

function M.draw()
	gfx.cls()
	text.draw_centered("a mr traveling bard production")
end

return M