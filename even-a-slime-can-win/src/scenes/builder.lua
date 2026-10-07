-- Builder scene
-- Party builder: pick a title and a 3-letter name for each of the four members.

local gfx = require("gfx")
local input = require("input")
local scene = require("scene")
local game = require("game")
local party = require("systems/party")
local titles = require("data/titles")
local skills = require("data/skills")
local config = require("data/config")
local text = require("ui/text")
local panel = require("ui/panel")

local M = {}

local NAME_CHARS = "abcdefghijklmnopqrstuvwxyz"
local slots, cursor, mode, char_pos, skill_cursor, delay

local function set_char(s, pos, ch)
	return s:sub(1, pos - 1) .. ch .. s:sub(pos + 1)
end

local function cycle_char(c, dir)
	local i = (c ~= "" and NAME_CHARS:find(c, 1, true)) or 1
	i = (i - 1 + dir) % #NAME_CHARS + 1
	return NAME_CHARS:sub(i, i)
end

-- a throwaway member built from slot i, used for the preview stats
local function preview(i)
	local b = slots[i]
	local key = party.available_title_keys()[b.title]
	local name = b.name ~= "" and b.name or "???"
	return party.new_member({ name = name, title = key }), key
end

local function start_game()
	local pool = {}
	for i, n in ipairs(config.default_names) do pool[i] = n end

	local members = {}
	for i = 1, config.party_size do
		if slots[i].name == "" then
			slots[i].name = table.remove(pool, love.math.random(#pool))
		end
		members[i] = (preview(i))
	end
	game.new(members)
	scene.switch(require("scenes/overworld"))
end

function M.enter()
	slots = {}
	for i = 1, config.party_size do slots[i] = { name = "", title = 1 } end
	cursor, mode, char_pos, skill_cursor = 1, "main", 1, 1
	delay = 10
end

-- ---- update ----
function M.update()
	if delay > 0 then delay = delay - 1 return end
	local start_row = config.party_size + 1

	if mode == "main" then
		if input.btnp(2) then cursor = (cursor - 2) % start_row + 1 end
		if input.btnp(3) then cursor = cursor % start_row + 1 end

		if cursor == start_row then
			if input.btnp(4) then start_game() end
			return
		end

		local b = slots[cursor]
		local nkeys = #party.available_title_keys()
		if input.btnp(0) then b.title = (b.title - 2) % nkeys + 1 end
		if input.btnp(1) then b.title = b.title % nkeys + 1 end
		if input.btnp(4) then
			mode, char_pos = "name", 1
			if b.name == "" then b.name = string.rep("a", config.name_length) end
		end
		if input.btnp(5) then mode, skill_cursor = "skills", 1 end

	elseif mode == "name" then
		local b = slots[cursor]
		local len = config.name_length
		if input.btnp(1) then char_pos = char_pos % len + 1 end
		if input.btnp(0) then char_pos = (char_pos - 2) % len + 1 end
		local c = b.name:sub(char_pos, char_pos)
		if input.btnp(2) then b.name = set_char(b.name, char_pos, cycle_char(c, -1)) end
		if input.btnp(3) then b.name = set_char(b.name, char_pos, cycle_char(c, 1)) end
		if input.btnp(4) or input.btnp(5) then mode = "main" end

	elseif mode == "skills" then
		local _, key = preview(cursor)
		local list = skills.pools[key]
		if input.btnp(2) then skill_cursor = (skill_cursor - 2) % #list + 1 end
		if input.btnp(3) then skill_cursor = skill_cursor % #list + 1 end
		if input.btnp(4) then mode = "skill_detail" end
		if input.btnp(5) then mode = "main" end

	else -- skill_detail
		if input.btnp(4) or input.btnp(5) then mode = "skills" end
	end
end

-- ---- draw ----
local function draw_name_box()
	local b = slots[cursor]
	panel.draw(28, 50, 99, 70, 0)
	gfx.print("enter name", 32, 53, 7)
	for i = 1, config.name_length do
		local blink = (i == char_pos) and (love.timer.getTime() * 4) % 2 < 1
		gfx.print(b.name:sub(i, i), 48 + (i - 1) * 8, 62, blink and 5 or 7)
	end
end

local function draw_skill_list()
	local _, key = preview(cursor)
	panel.draw(18, 16, 109, 104, 0)
	gfx.print("skills", 21, 19, 7)
	for i, s in ipairs(skills.pools[key]) do
		local y = 28 + (i - 1) * 8
		if i == skill_cursor then gfx.rectfill(19, y - 2, 108, y + 6, 1) end
		gfx.print(s.name, 21, y, s.type == "active" and 7 or 15)
	end
	gfx.print("z view  x back", 21, 98, 6)
end

local function draw_skill_detail()
	local _, key = preview(cursor)
	local s = skills.pools[key][skill_cursor]
	panel.draw(0, 28, 127, 92, 0)
	gfx.print(s.name, 3, 31, 7)
	gfx.print(s.type, 3, 38, 6)
	gfx.print(text.wrap_string(s.desc), 3, 46, 7)
	gfx.print("z/x back", 3, 86, 6)
end

function M.draw()
	gfx.cls()
	gfx.print("build your party", 4, 2, 7)
	gfx.line(0, 9, 127, 9, 5)

	for i = 1, config.party_size do
		local b = slots[i]
		local y = 12 + (i - 1) * 23
		if i == cursor then gfx.rectfill(0, y - 1, 127, y + 19, 1) end
		local m, key = preview(i)
		gfx.spr(m.sprite, 4, y)
		local name = b.name ~= "" and b.name or "???"
		gfx.print(name .. " " .. titles.defs[key].name, 14, y, 7)
		gfx.print("str" .. m.str .. " dex" .. m.dex .. " con" .. m.con .. " mag" .. m.mag, 14, y + 7, 13)
		gfx.print("hp" .. m.maxhp .. " mp" .. m.maxmp .. " atk" .. m.atk .. " def" .. m.def, 14, y + 14, 6)
	end

	if cursor == config.party_size + 1 then gfx.rectfill(0, 106, 127, 114, 1) end
	text.draw_centered("> start game <", 108, 10)
	gfx.print("< > title  z name  x skills", 4, 122, 6)

	if mode == "name" then draw_name_box() end
	if mode == "skills" then draw_skill_list() end
	if mode == "skill_detail" then draw_skill_detail() end
end

return M