-- Mainmenu scene

local gfx = require("gfx")
local scene = require("scene")
local ui = require("ui")
local config = require("data/config")

local M = {}
local OPTIONS = { "new game", "continue" }
local sel, delay

function M.enter()
	sel, delay = 1, 30
end

function M.update()
	if delay > 0 then delay = delay - 1 return end
	local action
	sel, action = ui.control(sel, #OPTIONS)
	if action == "confirm" and OPTIONS[sel] == "new game" then
		gfx.pal() -- back to the normal palette
		scene.switch(require("scenes/builder"))
    elseif action == "confirm" and OPTIONS[sel] == "continue" then
        scene.switch(require("scenes/savemenu"))
	end
end

function M.draw()
	gfx.cls()
	if delay > 0 then return end

	ui.draw_centered("even a", 16, 7)
	ui.draw_centered("slime", 24, 12)
	ui.draw_centered("can win", 32, 7)

	-- a row of bobbing slimes
	local t = love.timer.getTime()
	for i = 0, 8 do
		gfx.spr(1 + i * 7, 8 + i * 13, 64 - math.abs(math.sin(2 * math.pi * (t / 2 + i / 9))) * 3)
	end
	gfx.line(4, 72, 123, 72, 5)

	for n, label in ipairs(OPTIONS) do
		local selected = n == sel
		if selected then gfx.spr(127, 40, 86 + n * 8) end
		gfx.print(label, 48, 88 + n * 8, selected and 7 or 6)
	end

	gfx.print(config.version, 0, 120, 5)
end

return M