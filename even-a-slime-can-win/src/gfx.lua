local gfx = {}
local W, H = 128, 128
local floor = math.floor

local function hex(h)
  return { tonumber(h:sub(1,2),16)/255, tonumber(h:sub(3,4),16)/255, tonumber(h:sub(5,6),16)/255, 1 }
end

-- indices 0-15 standard, 128-143 "secret" palette
local full = {}
for i, h in ipairs{
  "000000","1D2B53","7E2553","008751","AB5236","5F574F","C2C3C7","FFF1E8",
  "FF004D","FFA300","FFEC27","00E436","29ADFF","83769C","FF77A8","FFCCAA"} do
  full[i-1] = hex(h)
end
for i, h in ipairs{
  "291814","111D35","422136","125359","742F29","49333B","A28879","F3EF7D",
  "BE1250","FF6C24","A8E72E","00B543","065AB5","754665","FF6E59","FF9D81"} do
  full[127+i] = hex(h)
end

local draw_map, screen_map, pen = {}, {}, 7
local canvas, font, scale, ox, oy

local function reset_pal()
  for i = 0, 15 do draw_map[i] = i; screen_map[i] = i end
end

local function col(c)
  c = floor(c or pen) % 16
  love.graphics.setColor(full[screen_map[draw_map[c]]])
end

function gfx.init(fontpath, fontsize)
  love.graphics.setDefaultFilter("nearest", "nearest")
  love.graphics.setLineStyle("rough")
  canvas = love.graphics.newCanvas(W, H)
  font = fontpath and love.graphics.newFont(fontpath, fontsize, "mono")
              or love.graphics.newFont(8, "mono")
  font:setFilter("nearest", "nearest")
  font:setLineHeight(6 / font:getHeight())   -- 6/5 = 1.2
  reset_pal()
  gfx.fit()
end

function gfx.fit()
  local ww, wh = love.graphics.getDimensions()
  scale = math.max(1, floor(math.min(ww / W, wh / H)))
  ox = floor((ww - W * scale) / 2)
  oy = floor((wh - H * scale) / 2)
end

-- wrap your draw code: gfx.begin() ... gfx.finish()
function gfx.begin()
  love.graphics.setCanvas(canvas)
  love.graphics.origin()
  love.graphics.setScissor()
  love.graphics.setFont(font)
end

function gfx.finish()
  love.graphics.setCanvas()
  love.graphics.origin()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setBlendMode("alpha", "premultiplied")
  love.graphics.draw(canvas, ox, oy, 0, scale, scale)
  love.graphics.setBlendMode("alpha")
end

-- palette: pal() resets, pal(a,b) remaps draw color, pal(a,b,1) remaps screen color
function gfx.pal(a, b, p)
  if a == nil then reset_pal() return end
  if p == 1 then screen_map[a] = b else draw_map[a] = b end
end

function gfx.color(c) pen = c end

function gfx.cls(c)
  love.graphics.clear(full[screen_map[draw_map[floor(c or 0) % 16]]])
end

function gfx.camera(x, y)
  love.graphics.origin()
  love.graphics.translate(-floor(x or 0), -floor(y or 0))
end

function gfx.pset(x, y, c)
  col(c); love.graphics.rectangle("fill", floor(x), floor(y), 1, 1)
end

-- PICO-8 coordinates are inclusive, hence the +1
function gfx.rectfill(x0, y0, x1, y1, c)
  if x0 > x1 then x0, x1 = x1, x0 end
  if y0 > y1 then y0, y1 = y1, y0 end
  col(c)
  love.graphics.rectangle("fill", floor(x0), floor(y0), floor(x1)-floor(x0)+1, floor(y1)-floor(y0)+1)
end

function gfx.rect(x0, y0, x1, y1, c)
  if x0 > x1 then x0, x1 = x1, x0 end
  if y0 > y1 then y0, y1 = y1, y0 end
  gfx.rectfill(x0, y0, x1, y0, c); gfx.rectfill(x0, y1, x1, y1, c)
  gfx.rectfill(x0, y0, x0, y1, c); gfx.rectfill(x1, y0, x1, y1, c)
end

function gfx.line(x0, y0, x1, y1, c)
  col(c)
  love.graphics.line(floor(x0)+.5, floor(y0)+.5, floor(x1)+.5, floor(y1)+.5)
end

function gfx.circfill(cx, cy, r, c)
  col(c); cx, cy, r = floor(cx), floor(cy), floor(r)
  for dy = -r, r do
    local dx = floor(math.sqrt(r*r - dy*dy) + 0.5)
    love.graphics.rectangle("fill", cx-dx, cy+dy, dx*2+1, 1)
  end
end

function gfx.print(s, x, y, c)
  col(c); love.graphics.print(tostring(s), floor(x or 0), floor(y or 0))
end

function gfx.print_centered(text,y,c)
	local y=y or 60
	local c=c or 7
	gfx.print(text, 64 - (#text*4)/2, y, c)
end

-- sprites: sheet is a 128x128 image, 8x8 tiles, index 0-255 like PICO-8
local sheet, quads = nil, {}
function gfx.load_sheet(path)
  sheet = love.graphics.newImage(path)
  sheet:setFilter("nearest", "nearest")
  for i = 0, 255 do
    quads[i] = love.graphics.newQuad((i % 16) * 8, floor(i / 16) * 8, 8, 8, sheet:getDimensions())
  end
end

function gfx.spr(n, x, y, w, h, flip_x, flip_y)
  love.graphics.setColor(1, 1, 1, 1)
  local sx, sy = flip_x and -1 or 1, flip_y and -1 or 1
  local wx, wy = (w or 1) * 8, (h or 1) * 8
  -- note: w/h > 1 needs a multi-tile quad; add later if you use it
  love.graphics.draw(sheet, quads[n], floor(x) + (flip_x and 8 or 0), floor(y) + (flip_y and 8 or 0), 0, sx, sy)
end

return gfx