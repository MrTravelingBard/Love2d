-- PICO-8 style buttons: 0=left 1=right 2=up 3=down 4=O 5=X
-- Call input.update() once per 30fps tick, and forward love.keypressed to input.keypressed.

local M = {}

local BUTTON_KEYS = {
	[0] = { "left", "a" },
	[1] = { "right", "d" },
	[2] = { "up", "w" },
	[3] = { "down", "s" },
	[4] = { "z", "return" },
	[5] = { "x", "rshift" },
}
local REPEAT_DELAY, REPEAT_RATE = 15, 4 -- PICO-8: repeat after 15 ticks, then every 4

local key_to_btn = {}
for b, keys in pairs(BUTTON_KEYS) do
	for _, k in ipairs(keys) do key_to_btn[k] = b end
end

local held, pressed, down, pending = {}, {}, {}, {}
for b = 0, 5 do held[b], pressed[b], down[b], pending[b] = 0, false, false, false end

-- catches taps shorter than one tick so they are never lost
function M.keypressed(key)
	local b = key_to_btn[key]
	if b then pending[b] = true end
end

function M.update()
	for b = 0, 5 do
		local is_down = false
		for _, k in ipairs(BUTTON_KEYS[b]) do
			if love.keyboard.isDown(k) then is_down = true break end
		end
		down[b], pressed[b] = is_down, false
		if is_down then
			held[b] = held[b] + 1
			if held[b] == 1 then
				pressed[b] = true
			elseif b <= 3 and held[b] > REPEAT_DELAY and (held[b] - REPEAT_DELAY - 1) % REPEAT_RATE == 0 then
				pressed[b] = true -- only the d-pad auto-repeats; O/X don't
			end
		else
			held[b] = 0
			if pending[b] then pressed[b] = true end
		end
		pending[b] = false
	end
end

function M.btn(b) return down[b] end
function M.btnp(b) return pressed[b] end

return M