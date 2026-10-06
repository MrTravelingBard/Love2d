-- Scene manager
-- One active scene at a time. A scene is a table with optional enter(...), update(), draw().

local M = { current = nil }

function M.switch(scene, ...)
	M.current = scene
	if scene.enter then scene.enter(...) end
end

function M.update()
	local s = M.current
	if s and s.update then s.update() end
end

function M.draw()
	local s = M.current
	if s and s.draw then s.draw() end
end

return M