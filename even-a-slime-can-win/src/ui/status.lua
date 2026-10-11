-- Party status screens: member list -> detail (skills / spells / titles) -> skill detail or title swap.
-- Overworld: status.open() on X, then status.update()/status.draw() while status.active.

local gfx = require("gfx")
local input = require("input")
local party = require("systems/party")
local titles = require("data/titles")
local skills = require("data/skills")
local config = require("data/config")
local ui = require("ui/ui")

local M = { active = false }

local STAT_LABELS = {
	{ "str ", "str" }, { "dex ", "dex" }, { "con ", "con" }, { "mag ", "mag" },
	{ " atk ", "atk" }, { " def ", "def" }, { " spd ", "spd" }, { "matk ", "matk" }, { "mdef ", "mdef" },
}

local function reset_state()
	M.mode = "list" -- list | detail | title_swap | skill_detail
	M.cursor = 1    -- selected party member
	M.section = "skills"
	M.cursors = { skills = 1, spells = 1, titles = 1 }
	M.swap_idx = 1
end
reset_state()

function M.open() reset_state(); M.active = true end
function M.close() M.active = false end

-- ---- helpers ----
local function section_list(sec, m)
	if sec == "skills" then
		return skills.pools[m.title] or {}
	elseif sec == "spells" then
		return {} -- spell pools aren't implemented yet
	else
		local list = {}
		for _, k in ipairs(titles.order) do
			if m.mastered_titles[k] then list[#list + 1] = { name = titles.defs[k].name } end
		end
		return list
	end
end

local function next_section(sec, dir)
	local order = config.status_sections
	local idx = 1
	for i, v in ipairs(order) do
		if v == sec then idx = i end
	end
	return order[(idx - 1 + dir) % #order + 1]
end

local function dpad_y()
	return input.btnp(2) and -1 or (input.btnp(3) and 1 or 0)
end

local function plural(n, word)
	return n .. " " .. word .. (n == 1 and "" or "s")
end

local function cost_text(s)
	if s.coin_cost and s.coin_cost > 0 then return plural(s.coin_cost, "coin"), 9 end
	if s.mp_cost and s.mp_cost > 0 then return s.mp_cost .. " mp", 12 end
	return nil
end

-- ---- update ----
function M.update()
	local mode = M.mode

	if mode == "list" then
		local d = dpad_y()
		if d ~= 0 then M.cursor = (M.cursor + d - 1) % #party.members + 1 end
		if input.btnp(4) then M.mode, M.section = "detail", "skills" end
		if input.btnp(5) then M.close() end

	elseif mode == "detail" then
		local m = party.members[M.cursor]
		if input.btnp(0) then M.section = next_section(M.section, -1)
		elseif input.btnp(1) then M.section = next_section(M.section, 1) end

		local sec = M.section
		local list = section_list(sec, m)
		if M.cursors[sec] > #list then M.cursors[sec] = math.max(1, #list) end -- list may have shrunk

		local d = dpad_y()
		if d ~= 0 and #list > 0 then M.cursors[sec] = (M.cursors[sec] + d - 1) % #list + 1 end

		if input.btnp(4) then
			if sec == "titles" then
				M.mode = "title_swap"
				M.swap_idx = 1
				for i, k in ipairs(party.available_title_keys(m)) do
					if k == m.title then M.swap_idx = i end
				end
			elseif sec == "skills" and #list > 0 then
				M.mode = "skill_detail"
			end
		end
		if input.btnp(5) then M.mode = "list" end

	elseif mode == "title_swap" then
		local m = party.members[M.cursor]
		local keys = party.available_title_keys(m)
		if input.btnp(0) then M.swap_idx = (M.swap_idx - 2) % #keys + 1 end
		if input.btnp(1) then M.swap_idx = M.swap_idx % #keys + 1 end
		if input.btnp(4) then
			party.apply_title_swap(m, keys[M.swap_idx])
			M.mode = "detail"
		end
		if input.btnp(5) then M.mode = "detail" end

	else -- skill_detail
		if input.btnp(4) or input.btnp(5) then M.mode = "detail" end
	end
end

-- ---- draw ----
local function draw_counts()
	gfx.print(plural(party.herb, "herb"), 70, 2, 3)
	gfx.print(plural(party.gold, "coin"), 100, 2, 9)
end

local function draw_list()
	gfx.cls(0)
	gfx.print("party status", 4, 2, 7)
	draw_counts()
	gfx.line(0, 9, 127, 9, 5)

	for i, m in ipairs(party.members) do
		local y = 12 + (i - 1) * 28
		if i == M.cursor then gfx.rectfill(0, y - 1, 127, y + 22, 1) end
		gfx.print(m.name .. " " .. m.title_pretty, 4, y, 7)
		gfx.print("hp " .. m.hp .. "/" .. m.maxhp, 4, y + 8, 8)
		gfx.print("mp " .. m.mp .. "/" .. m.maxmp, 44, y + 8, 12)
		gfx.spr(m.sprite, 106, y + 5)
		gfx.print("str " .. m.str .. " dex " .. m.dex .. " con " .. m.con .. " mag " .. m.mag, 4, y + 16, 13)
		gfx.line(0, y + 24, 127, y + 24, 5)
	end
	ui.footer("z details  x close")
end

local function draw_detail(m)
	gfx.cls(0)
	gfx.print(m.name, 4, 2, 7)
	gfx.print("herb uses: "..m.herb_uses, 64, 2, 3)
	gfx.print(m.title_pretty, 4, 9, 6)
	gfx.line(0, 16, 127, 16, 5)

	gfx.spr(m.sprite, 18, 24)
	gfx.print("hp " .. m.hp .. "/" .. m.maxhp, 10, 43, 8)
	gfx.print("mp " .. m.mp .. "/" .. m.maxmp, 10, 50, 12)

	for i, s in ipairs(STAT_LABELS) do
		local x, y = 56, 22 + ((i - 1) % 4) * 7
		if i > 4 then x, y = 94, 22 + (i - 5) * 7 end
		gfx.print(s[1] .. m[s[2]], x, y, 7)
	end
	gfx.line(0, 60, 127, 60, 5)

	local sec = M.section
	gfx.print("skills", 4, 63, sec == "skills" and 7 or 5)
	gfx.print("spells", 52, 63, sec == "spells" and 7 or 5)
	gfx.print("titles", 100, 63, sec == "titles" and 7 or 5)
	gfx.line(0, 70, 127, 70, 5)

	local list = section_list(sec, m)
	for i, s in ipairs(list) do
		local y = 73 + (i - 1) * 7
		if i == M.cursors[sec] and sec ~= "titles" then gfx.rectfill(0, y - 1, 127, y + 5, 1) end
		gfx.print(s.name, 4, y, s.type == "active" and 7 or 15)
		local cost, col = cost_text(s)
		if cost then gfx.print(cost, 90, y, col) end
	end

	ui.footer("< > toggle  z " .. (sec == "titles" and "swap" or "view") .. "  x back")
end

local function draw_ability(s)
	gfx.cls(0)
	gfx.print(s.name, 4, 2, 7)
	gfx.print(s.type, 4, 9, 6)
	local cost, col = cost_text(s)
	if cost then gfx.print(s.mp_cost and s.mp_cost > 0 and ("mp cost " .. s.mp_cost) or cost, 90, 9, col) end
	gfx.line(0, 16, 127, 16, 5)
	gfx.print(ui.wrap_string(s.desc), 4, 20, 7)
	ui.footer("z/x back")
end

local function draw_title_swap(m)
	local key = party.available_title_keys(m)[M.swap_idx]
	gfx.cls(0)
	gfx.print("swap title", 4, 2, 7)
	gfx.line(0, 9, 127, 9, 5)

	gfx.spr(titles.defs[key].sprite, 10, 15)
	gfx.print(m.name .. " " .. titles.defs[key].name, 32, 18, 7)
	gfx.line(0, 31, 127, 31, 5)

	gfx.print("skills", 4, 34, 7)
	for i, s in ipairs(skills.pools[key]) do
		local y = 42 + (i - 1) * 24
		gfx.print(s.name, 4, y, s.type == "active" and 7 or 15)
		gfx.print(ui.wrap_string(s.desc), 4, y + 6, 7)
	end
	ui.footer("< > title  z confirm  x back")
end

function M.draw()
	if not M.active then return end
	local m = party.members[M.cursor]
	if M.mode == "list" then
		draw_list()
	elseif M.mode == "detail" then
		draw_detail(m)
	elseif M.mode == "skill_detail" then
		draw_ability(section_list("skills", m)[M.cursors.skills])
	elseif M.mode == "title_swap" then
		draw_title_swap(m)
	end
end

return M