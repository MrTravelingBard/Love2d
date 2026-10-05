local gfx = require("gfx")
local STEP, acc = 1/30, 0
local report = {}

function love.load()
  gfx.init("assets/PICO-8.ttf", 5)
end

function love.resize() gfx.fit() end

function love.update(dt)
  acc = math.min(acc + dt, 0.25)   -- cap so a stall doesn't cause a burst of updates
  while acc >= STEP do
    acc = acc - STEP
    -- game_update()   <- your 30fps logic goes here
  end
end

function love.draw()
  gfx.begin()
  gfx.cls(0)
  gfx.print_centered("a mr travelingbard production", 60)
  gfx.finish()

  -- overlay drawn straight to the window, outside the 128x128 canvas
  love.graphics.setFont(love.graphics.newFont(14))
  love.graphics.setColor(1, 1, 0, 1)
  love.graphics.print(table.concat(report, "\n"), 400, 20)
end