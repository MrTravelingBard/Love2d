-- Party manager
-- Shared party state (members, herbs, gold, overworld position) and member stat/title logic.

local flags = require("systems/flags")
local titles = require("data/titles")
local skills = require("data/skills")
local config = require("data/config")

local M = { members = {}, herb = 0, gold = 0 }

-- stat modifier slots:
-- 1=str 2=dex 3=con 4=mag 5=atk 6=def 7=spd 8=matk 9=mdef 10=maxhp 11=maxmp
function M.new_temp_stats()
	local t = {}
	for i = 1, 11 do t[i] = 0 end
	return t
end

function M.new_game(members)
	M.members = members
	M.herb, M.gold = 0, 0
	M.x, M.y = config.start.x, config.start.y
	M.dx, M.dy = 0, -1
	M.sprite_offset, M.flip_x = 0, false
	M.set_leader()
end

function M.set_leader()
	M.sprite = M.members[1].sprite
end

-- spec: { name=, title=, str=, dex=, con=, mag= }  (stats default to config.base_stats)
function M.new_member(spec)
	local base = config.base_stats
	local t = assert(titles.defs[spec.title], "unknown title: " .. tostring(spec.title))
	local m = {
		name = spec.name, title = spec.title,
		title_pretty = t.name, sprite = t.sprite,
		mastered_titles = {},
		maxhp = 5, hp = 5, maxmp = 0, mp = 0,
		atk = 1, def = 1, spd = 1, matk = 1, mdef = 1,
		str = spec.str or base.str, dex = spec.dex or base.dex,
		con = spec.con or base.con, mag = spec.mag or base.mag,
		str_total = 0, dex_total = 0, con_total = 0, mag_total = 0,
		maxhp_total = 0, maxmp_total = 0,
		status = {},
		temp_stats = M.new_temp_stats(),
		skills = assert(skills.pools[spec.title], "no skill pool for title: " .. spec.title),
		herb_uses = 0
	}
	if spec.title == "red" then m.mastered_titles.red = true end
	return M.refresh_stats(m)
end

-- recompute derived stats. refresh=false: full heal (new member). refresh=true: keep current hp/mp.
function M.refresh_stats(m, refresh)
	local ts = m.temp_stats
	local t_str, t_dex, t_con, t_mag = ts[1], ts[2], ts[3], ts[4]
	local t_atk, t_def, t_spd, t_matk, t_mdef = ts[5], ts[6], ts[7], ts[8], ts[9]
	local t_maxhp, t_maxmp = ts[10], ts[11]
	local maxhp_start, maxmp_start = m.maxhp, m.maxmp

	m.str_total, m.dex_total = m.str + t_str, m.dex + t_dex
	m.con_total, m.mag_total = m.con + t_con, m.mag + t_mag

	m.atk = m.str_total * 2 + t_atk
	m.def = m.con_total * 2 + t_def
	m.spd = m.dex_total * 2 + t_spd
	m.matk = m.mag_total * 2 + t_matk
	m.mdef = m.mag_total * 2 + t_mdef

	m.maxhp_total = math.max(1, math.max(1, m.con_total) * 5 + t_maxhp)
	m.maxmp_total = math.max(0, m.maxmp + t_maxmp)

	for _, s in ipairs(m.skills) do
		if s.id == "red" or s.id == "once_red" then
			m.maxmp_total = math.max(1, m.mag_total) * 5 + t_maxmp
		end
		if s.id == "legacy" then m.maxhp_total = m.maxhp_total * 3 end
	end

	if refresh then
		local hpdiff = m.maxhp_total - maxhp_start
		local mpdiff = m.maxmp_total - maxmp_start
		if hpdiff > 0 then m.hp = m.hp + hpdiff end -- gaining max hp also gains hp
		if mpdiff > 0 then m.mp = m.mp + mpdiff end
		m.maxhp, m.maxmp = m.maxhp_total, m.maxmp_total
		m.hp = math.min(m.hp, m.maxhp) -- losing max hp clamps hp
		m.mp = math.min(m.mp, m.maxmp)
		return m
	end

	m.maxhp, m.maxmp = m.maxhp_total, m.maxmp_total
	m.hp, m.mp = m.maxhp, m.maxmp
	return m
end

-- ---- titles ----
function M.is_title_unlocked(m, key)
	local unlock = titles.defs[key].unlock
	if not unlock then return true end
	return unlock(m, flags.values) and true or false
end

-- titles a member may swap into (always includes their current one)
function M.available_title_keys(m)
	m = m or {}
	local out = {}
	for _, k in ipairs(titles.order) do
		if k == m.title or M.is_title_unlocked(m, k) then out[#out + 1] = k end
	end
	return out
end

function M.apply_title_swap(m, new_title)
	m.mastered_titles[m.title] = true
	m.title = new_title
	m.title_pretty = titles.defs[new_title].name
	m.sprite = titles.defs[new_title].sprite
	m.skills = skills.pools[new_title]
	M.refresh_stats(m, true)
	M.set_leader()
end

-- ---- helpers ----
function M.heal_full()
	for _, m in ipairs(M.members) do m.hp, m.mp = m.maxhp, m.maxmp end
end

function M.wiped()
	for _, m in ipairs(M.members) do
		if m.hp > 0 then return false end
	end
	return true
end

return M