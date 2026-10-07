-- Battle Rules
-- Battle logic with no drawing, timers or input, so it can be tested on its own.
--
-- Flow, as the scene uses it:
--   state = rules.new(party.members, enemy_list, party)
--   player turn:  action = rules.plan_attack(...)   -- rolls the numbers, changes nothing
--                 ...play animation...
--                 rules.apply(action)               -- hp actually changes here
--                 rules.finish_player_action(state) -- next member, or the enemy phase, or won
--   enemy phase:  enemy = rules.next_enemy(state)   -- nil when the round is over
--                 action = rules.plan_enemy_action(state, enemy) ... rules.apply(action)
--                 rules.finish_enemy_action(state)  -- lost, or move to the next enemy
--   state.phase is "player", "enemy", "won" or "lost".

local M = {}

M.HERB_HEAL = 5
M.rng = nil -- set to function(n) -> integer 0..n-1 to make tests deterministic

local function random_int(n)
	if M.rng then return M.rng(n) end
	local lv = rawget(_G, "love")
	if lv and lv.math then return lv.math.random(0, n - 1) end
	return math.random(0, n - 1)
end

-- ---- sides (lists of battlers) ----
function M.alive(side)
	local out = {}
	for _, b in ipairs(side) do
		if b.hp > 0 then out[#out + 1] = b end
	end
	return out
end

function M.all_dead(side)
	for _, b in ipairs(side) do
		if b.hp > 0 then return false end
	end
	return true
end

function M.random_alive(side)
	local alive = M.alive(side)
	if #alive == 0 then return nil end
	return alive[random_int(#alive) + 1]
end

function M.first_alive(side)
	for i, b in ipairs(side) do
		if b.hp > 0 then return i end
	end
	return nil
end

-- next living index in direction dir (+1/-1), wrapping; unchanged if nobody is alive
function M.cycle_target(side, index, dir)
	local n = #side
	for _ = 1, n do
		index = index + dir
		if index > n then index = 1 end
		if index < 1 then index = n end
		if side[index].hp > 0 then return index end
	end
	return index
end

-- ---- setup ----
local function zero_stats()
	local t = {}
	for i = 1, 11 do t[i] = 0 end
	return t
end

function M.new_battler(src, is_enemy)
	return {
		member = src, -- the party member / enemy template this came from
		name = src.name, is_enemy = is_enemy or false, sprite = src.sprite,
		maxhp = src.maxhp, hp = src.hp or src.maxhp,
		maxmp = src.maxmp or 0, mp = src.mp or src.maxmp or 0,
		atk = src.atk, def = src.def, spd = src.spd, matk = src.matk, mdef = src.mdef,
		temp_stats = zero_stats(),
		skills = src.skills or {},
		status = {},
		herb_uses=src.herb_uses
	}
end

-- items: any table with a .herb count (normally the party module)
function M.new(members, enemy_data, items)
	local state = {
		battlers = {}, enemies = {}, items = items or {},
		phase = "player", round = 1, active_char = 1, active_enemy = 1,
	}
	for _, m in ipairs(members) do state.battlers[#state.battlers + 1] = M.new_battler(m, false) end
	for _, e in ipairs(enemy_data) do state.enemies[#state.enemies + 1] = M.new_battler(e, true) end
	state.active_char = M.first_alive(state.battlers) or 1
	M.check_end(state)
	return state
end

-- ---- damage ----
function M.calc_damage(atk, def, variance)
	return math.max(atk + random_int(variance or 3) - def, 1)
end

-- ---- planning: decide and roll, change nothing ----
function M.plan_attack(user, target)
	local dmg = M.calc_damage(user.atk, target.def)
	return {
		kind = "attack", user = user, target = target, amount = dmg,
		message = user.name .. " hits " .. target.name .. " for " .. dmg .. "!",
	}
end

-- weaker hit that also puts the user on guard (damage taken is halved until the round ends)
function M.plan_guard(user, target)
	local dmg = M.calc_damage(math.floor(user.atk / 2) + (user.shield_score or 0), target.def)
	return {
		kind = "guard", user = user, target = target, amount = dmg,
		message = user.name .. " guards and hits " .. target.name .. " for " .. dmg .. "!",
	}
end

-- spends a herb immediately. returns nil + a message if there are none.
function M.plan_heal(state, user, target, amount)
	if (state.items.herb or 0) <= 0 then return nil, "no herbs left!" end
	state.items.herb = state.items.herb - 1
	user.herb_uses = user.herb_uses + 1
	amount = amount or M.HERB_HEAL
	return {
		kind = "heal", user = user, target = target, amount = amount,
		message = user.name .. " heals " .. target.name .. " for " .. amount .. "!",
	}
end

function M.plan_enemy_action(state, enemy)
	local target = M.random_alive(state.battlers)
	if not target then return nil end
	local dmg = M.calc_damage(enemy.atk, target.def)
	if target.status.defending then dmg = math.max(math.floor(dmg / 2), 1) end
	return {
		kind = "attack", user = enemy, target = target, amount = dmg,
		message = enemy.name .. " hits " .. target.name .. " for " .. dmg .. "!",
	}
end

-- ---- committing ----
-- changes hp. sets action.dealt to the real hp change (negative for healing).
function M.apply(action)
	local t = action.target
	if action.kind == "guard" then action.user.status.defending = true end
	local signed = (action.kind == "heal") and -action.amount or action.amount
	local before = t.hp
	t.hp = math.min(math.max(t.hp - signed, 0), t.maxhp)
	action.dealt = before - t.hp
	return action
end

-- ---- turn flow ----
function M.check_end(state)
	if M.all_dead(state.enemies) then
		state.phase = "won"
	elseif M.all_dead(state.battlers) then
		state.phase = "lost"
	end
	return state.phase
end

function M.finish_player_action(state)
	if M.check_end(state) ~= "player" then return state.phase end
	local i = state.active_char
	repeat
		i = i + 1
		if i > #state.battlers then
			state.active_char, state.active_enemy, state.phase = 1, 1, "enemy"
			return state.phase
		end
	until state.battlers[i].hp > 0
	state.active_char = i
	return state.phase
end

function M.end_round(state)
	for _, b in ipairs(state.battlers) do b.status.defending = false end
	state.round = state.round + 1
	state.active_char = M.first_alive(state.battlers) or 1
	state.active_enemy = 1
	state.phase = "player"
end

-- the living enemy whose turn it is, skipping dead ones. nil means the round just ended.
function M.next_enemy(state)
	while state.active_enemy <= #state.enemies do
		local e = state.enemies[state.active_enemy]
		if e.hp > 0 then return e end
		state.active_enemy = state.active_enemy + 1
	end
	M.end_round(state)
	return nil
end

function M.finish_enemy_action(state)
	if M.check_end(state) ~= "enemy" then return state.phase end
	state.active_enemy = state.active_enemy + 1
	return state.phase
end

-- write hp/mp/herb_uses back to the party members after the battle
function M.sync_to_party(state)
	for _, b in ipairs(state.battlers) do
		b.member.hp = b.hp
		b.member.mp = b.mp
		b.member.herb_uses = b.herb_uses
	end
end

return M