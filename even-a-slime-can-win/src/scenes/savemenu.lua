-- savemenu scene

local gfx = require("gfx")
local scene = require("scene")
local ui = require("ui/ui")

local M = {}
local OPTIONS = { "back" }
local sel, delay

function M.enter()
	sel, delay = 1, 30
end

function M.update()
	if delay > 0 then delay = delay - 1 return end
	local action
	sel, action = ui.control(sel, #OPTIONS)
	if action == "confirm" or "back" then
        scene.switch(require("scenes/mainmenu"))
	end
end

function M.draw()
	gfx.cls()
	if delay > 0 then return end
	ui.draw_centered("placeholder save menu", 16, 7)
	ui.draw_centered("press z or x to return to main menu", 32, 7)
end

return M