-- Battle scene
-- The battle screen: menus, targeting, animations, popups. All the actual rules live in
-- systems/battle_rules.lua; this file decides when things happen and how they look.
--
-- Start one with: battle.start("rats_x2", function(won) ... end)

local gfx = require("gfx")
local input = require("input")
local scene = require("scene")
local party = require("systems/party")
local rules = require("systems/battle_rules")
local enemies = require("data/enemies")
local ui = require("ui/ui")

local M = {}

-- S is the scene state, rebuilt on every enter()
--   mode: "player" (menu) | "anim" | "enemy" | "round_end" | "won" | "lost"
--   timer: frames to pause before the next thing may happen (also blocks menu confirms)
local S

local MENU_ICONS = { 118, 120, 122, 124 } -- sprite for each menu entry (+1 when not selected)
local MENU_COUNT = 4                       -- attack, defend, skills, herb

-- ---- layout ----
local function layout()
	local list, padding = S.state.enemies, 6
	local total = 0
	for i, e in ipairs(list) do
		e.layout_w = #e.name * 4 + 2
		total = total + e.layout_w
		if i < #list then total = total + padding end
	end
	local x = 64 - total / 2
	for _, e in ipairs(list) do
		e.x = x + e.layout_w / 2 - 4
		e.y = 32
		e.label_cx = x + e.layout_w / 2
		x = x + e.layout_w + padding
	end
	for i, b in ipairs(S.state.battlers) do
		b.x = 32 * (i - 1) + 16 - 4
		b.y = 94
	end
end

-- ---- popups ----
local function spawn_popup(x, y, amount, color)
	S.popups[#S.popups + 1] = { x = x + love.math.random(-2, 2), y = y, val = amount, col = color, timer = 30 }
end

local function update_popups()
	for i = #S.popups, 1, -1 do
		local p = S.popups[i]
		p.y = p.y - 0.5
		p.timer = p.timer - 1
		if p.timer <= 0 then table.remove(S.popups, i) end
	end
end

-- ---- animations ----
local function play_anim(frames, fn, done)
	S.anim = { frames = frames, fn = fn, done = done }
	S.mode = "anim"
end

local function shake(battler)
	S.shake.target = battler
	S.shake.x = love.math.random(-1, 1)
end

-- the hit itself: popup, real hp change, message, then a pause
local function land_hit(action, timer)
	local t = action.target
	spawn_popup(t.x + 4, t.y - 4, action.amount, action.kind == "heal" and 11 or 8)
	rules.apply(action)
	S.message = action.message
	S.timer = timer or 30
	S.shake.target = nil
end

local function attack_anim(user, on_hit, done)
	local base = user.sprite + 1
	local frames = { base, base + 2, base + 3, base + 4, base + 5, base }
	local ticks_per_frame = 4
	local t, hit_done = 0, false
	user.anim_sprite = frames[1]

	play_anim(#frames * ticks_per_frame,
		function()
			t = t + 1
			local idx = math.min(math.floor((t - 1) / ticks_per_frame) + 1, #frames)
			user.anim_sprite = frames[idx]
			if idx == #frames and not hit_done then
				hit_done = true
				on_hit()
			end
		end,
		function()
			S.timer = 30
			user.anim_sprite = nil
			done()
		end)
end

local function heal_anim(target, on_heal)
	S.heal_flash.target, S.heal_flash.frame = target, 0
	play_anim(30,
		function() S.heal_flash.frame = S.heal_flash.frame + 1 end,
		function()
			S.timer = 30
			on_heal()
			S.heal_flash.target = nil
		end)
end

-- ---- turn flow ----
local function after_player_action()
	local phase = rules.finish_player_action(S.state)
	if phase == "won" then
		S.mode, S.message, S.timer = "won", "you won!", 60
	elseif phase == "lost" then
		S.mode, S.message = "lost", "you lost..."
	elseif phase == "enemy" then
		S.mode = "enemy"
	else
		S.mode, S.select = "player", 1
	end
end

local function do_attack(actor, target)
	local action = rules.plan_attack(actor, target)
	attack_anim(actor, function() land_hit(action) end, after_player_action)
end

local function do_guard(actor, target)
	local action = rules.plan_guard(actor, target)
	play_anim(10,
		function() shake(actor) end,
		function()
			land_hit(action)
			after_player_action()
		end)
end

local function do_heal(actor, target)
	local action, msg = rules.plan_heal(S.state, actor, target)
	if not action then S.message = msg return end
	heal_anim(target, function()
		land_hit(action)
		after_player_action()
	end)
end

local function update_enemy()
	if S.timer > 0 then return end

	local e = rules.next_enemy(S.state)
	if not e then -- everyone has acted
		S.mode, S.timer = "round_end", 45
		return
	end

	local action = rules.plan_enemy_action(S.state, e)
	if not action then return end
	e.acting = true
	play_anim(action.amount * 3,
		function() shake(e) end,
		function()
			land_hit(action, 45)
			e.acting = false
			if rules.finish_enemy_action(S.state) == "lost" then
				S.mode, S.message = "lost", "you lost..."
			else
				S.mode = "enemy"
			end
		end)
end

-- ---- player menu ----
local function update_menu()
	local st = S.state

	if S.targeting then
		local side = S.target_side == "enemy" and st.enemies or st.battlers
		if input.btnp(0) then S.target_idx = rules.cycle_target(side, S.target_idx, -1) end
		if input.btnp(1) then S.target_idx = rules.cycle_target(side, S.target_idx, 1) end
		if input.btnp(5) then S.targeting = false return end
		if input.btnp(4) and S.timer <= 0 then
			local actor, target = st.battlers[st.active_char], side[S.target_idx]
			S.targeting = false
			if S.select == 1 then do_attack(actor, target)
			elseif S.select == 2 then do_guard(actor, target)
			elseif S.select == 4 then do_heal(actor, target)
			end
		end
		return
	end

	if input.btnp(0) then S.select = (S.select - 2) % MENU_COUNT + 1 end
	if input.btnp(1) then S.select = S.select % MENU_COUNT + 1 end

	if input.btnp(4) and S.timer <= 0 then
		if S.select == 1 or S.select == 2 then
			S.targeting, S.target_side = true, "enemy"
			S.target_idx = rules.first_alive(st.enemies) or 1
		elseif S.select == 3 then
			S.message = "coming soon!" -- skills menu not built yet
		elseif S.select == 4 then
			if party.herb <= 0 then
				S.message = "no herbs left!"
			else
				S.targeting, S.target_side = true, "party"
				S.target_idx = rules.first_alive(st.battlers) or 1
			end
		end
	end
end

-- ---- leaving ----
local function finish()
	local won = S.mode == "won"
	local cb = S.on_end
	rules.sync_to_party(S.state)
	scene.switch(require("scenes/overworld")) -- required here to avoid a load-time cycle
	if cb then cb(won) end
end

-- ---- scene interface ----
function M.start(group_id, on_end)
	scene.switch(M, group_id, on_end)
end

function M.enter(group_id, on_end)
	local state = rules.new(party.members, enemies.make_group(group_id), party)
	S = {
		state = state, on_end = on_end,
		mode = "player", message = "your turn!", timer = 0,
		select = 1, targeting = false, target_side = "enemy", target_idx = 1,
		shake = { target = nil, x = 0 }, heal_flash = { target = nil, frame = 0 },
		popups = {}, anim = { frames = 0 },
	}
	if state.phase == "won" then S.mode, S.message, S.timer = "won", "you won!", 60
	elseif state.phase == "lost" then S.mode, S.message, S.timer = "lost", "you lost...", 45 end
	layout()
end

function M.update()
	S.timer = S.timer - 1
	update_popups()

	local mode = S.mode
	if mode == "anim" then
		local a = S.anim
		if a.fn then a.fn() end
		a.frames = a.frames - 1
		if a.frames <= 0 then a.done() end
	elseif mode == "player" then
		update_menu()
	elseif mode == "enemy" then
		update_enemy()
	elseif mode == "round_end" then
		if S.timer <= 0 then S.mode, S.select, S.message = "player", 1, "your turn!" end
	elseif mode == "won" or mode == "lost" then
		if S.timer <= 0 then finish() end
	end
end

-- ---- drawing ----
local function draw_bar(x, y, val, maxval, col, w)
	w = w or 40
	local fill = math.max(0, math.floor((val / maxval) * w) - 1)
	if fill > 0 then gfx.rectfill(x, y, x + fill, y + 1, col) end
end

local function draw_sprites()
	local st = S.state
	local show_party_target = S.targeting and S.target_side == "party"

	for i, e in ipairs(st.enemies) do
		if e.hp > 0 then
			local sx = (S.shake.target == e) and S.shake.x or 0
			local by = e.acting and 2 or 0
			gfx.spr(e.anim_sprite or e.sprite, e.x + sx, e.y + by)
			if S.targeting and S.target_side == "enemy" and i == S.target_idx then
				draw_bar(e.label_cx - 12, e.y - 2, e.hp, e.maxhp, 8, 24)
				gfx.print(e.name, e.label_cx - #e.name * 2, e.y + 11, 7)
			end
		end
	end

	for i, b in ipairs(st.battlers) do
		local active = S.mode == "player" and i == st.active_char
		local c = 7
		if math.floor((b.hp / b.maxhp) * 100) <= 33 then c = b.hp <= 0 and 8 or 10 end

		local col_start = b.x - 8
		if S.heal_flash.target == b then
			draw_bar(col_start, b.y - 2, b.hp, b.maxhp, (S.heal_flash.frame % 2 == 0) and 11 or 7, 24)
		elseif active or (show_party_target and i == S.target_idx) then
			draw_bar(col_start, b.y - 2, b.hp, b.maxhp, 11, 24)
		end

		local s = b.anim_sprite or (active and b.sprite or b.sprite + 1)
		if b.hp <= 0 then s = b.sprite + 6 end
		local sx = (S.shake.target == b) and S.shake.x or 0
		gfx.spr(s, b.x + sx, b.y)

		gfx.print(b.name, col_start, b.y + 11, c)
		gfx.print("hp:" .. b.hp, col_start, b.y + 18, c)
		gfx.print("mp:" .. b.mp, col_start, b.y + 25, c)
	end
end

local function draw_popups()
	for _, p in ipairs(S.popups) do
		local s = tostring(p.val)
		local w = #s * 4
		gfx.print(s, p.x - w / 2 + 1, p.y + 1, 0)
		gfx.print(s, p.x - w / 2, p.y, p.col)
	end
end

local function draw_cursor()
	if not S.targeting then return end
	local side = S.target_side == "enemy" and S.state.enemies or S.state.battlers
	local t = side[S.target_idx]
	if not t or t.hp <= 0 then return end
	local bob = math.floor(-math.sin(2 * math.pi * love.timer.getTime() * 2) * 2)
	gfx.spr(126, t.x + 4 - 2, t.y - 16 + bob)
end

function M.draw()
	gfx.cls()

	if S.mode == "won" or S.mode == "lost" then
		ui.draw_centered(S.message, 44, S.mode == "won" and 11 or 8)
	else
		gfx.print(S.message, 64 - #S.message * 2, 8, 7)
	end

	draw_sprites()
	draw_popups()
	draw_cursor()

	if S.mode == "player" then
		local labels = { "attack", "defend", "skills", "herb x" .. party.herb }
		for i = 1, MENU_COUNT do
			local selected = S.select == i
			gfx.print(selected and labels[i] or "", 36 + (i - 1) * 12, 56, 7)
			gfx.spr(MENU_ICONS[i] + (selected and 0 or 1), 42 + (i - 1) * 12, 64)
		end
	end
end

return M