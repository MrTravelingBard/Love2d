local game_data = require("data/config")

function love.conf(t)
  t.window.title = game_data.game_title
  t.window.width, t.window.height = game_data.window.width, game_data.window.height
  t.window.resizable = true

  -- Engine-specific boot settings 
  t.console = true
end