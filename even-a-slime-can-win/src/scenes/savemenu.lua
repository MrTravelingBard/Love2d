-- savemenu scene

local gfx = require("gfx")
local scene = require("scene")
local ui = require("ui")

local M = {}
local sel, delay

function M.enter()
	sel, delay = 1, 30
end

function M.update()
	if delay > 0 then delay = delay - 1 return end
	local action
	sel, action = ui.control(sel, 0)
	if action == "confirm" or action == "back" then
        scene.switch(require("scenes/mainmenu"))
	end
end

function M.draw()
	gfx.cls()
	if delay > 0 then return end
	ui.draw_centered("placeholder save menu", 16, 7)
	ui.draw_centered("to return to main menu", 94, 7)
	ui.draw_centered("press z or x",102,7)
end

return M