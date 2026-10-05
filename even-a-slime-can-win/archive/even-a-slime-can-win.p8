pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
--even a slime can win
--by mrtravelingbard

--==global variables==
version,wait,wait_cnt,main_sel="V0.1.1",0,0,1
--for status
section_order={"skills","spells","titles"}
--for dialogue
flags={}
--for battle
battle_state = {
    player_turn=1, 
    enemy_turn=2, 
	anim=3, 
	win=4, 
	lose=5,
	round_end=6
}

--init scenes
function init_intro()
	scene="intro"
	pal(0,128,1)
	set_wait(60)
	_update=update_intro
	_draw=draw_intro
end

function init_mainmenu()
	scene="mainmenu"
	menu_sel=1
	menu_options={"new game"} --continue
	set_wait(30)
	_update=update_mainmenu
	_draw=draw_mainmenu
end

--function init_savemenu()
--	scene="savemenu"
--	menu_sel=1
--	set_wait(30)
--	_update=update_savemenu
--	_draw=draw_savemenu
--end

function init_game()
	scene="game"
	game_win=false
	game_over=false
	menu_active=false
	bbeg_defeated=false
	--setup calls
	init_map()
	init_npcs()
	init_enemies()
	init_enemy_groups()
	init_dialogue()
	init_party()
	init_status()
	set_wait(30)
	_update=update_game
	_draw=draw_game
end

--init game data
function init_titles()
	titles={}
	for t in all(split([[immortal,the immortal,8;quick_blow,the quick blow,1;eldest,the eldest's legacy,1;slip_master,the slip naster,1;coiled,the coiled one,1;red,the red,15;once_red,the once red,29;metal_sworn,the metalsworn,57;metal,the metal,50;kingslayer,the kingslayer,36]],";")) do
		local k,n,s=unpack(split(t))
		titles[k]={name=n, sprite=s}
	end
end

function init_skills()
	skills={
		--immortal
		immortal=init_skill("immortal,passive,0,resurrect at the beginning of the round with 50% hp"),
		revenge=init_skill("revenge,active,0,deals damage based on the number of deaths suffered since last use"),
		--quick_blow
		stunning=init_skill("stunning,passive,0,all attacks have a 25% chance to stun"),
		quick_blow=init_skill("quick blow,active,0,deals damage to single target with higher spd priority"),
		--eldest
		legacy=init_skill("eldest's legacy,passive,0,increased max hp by 300%"),
		gift=init_skill("eldest's gift,active,0,gift a portion of your hp to others as healing with a 1:3 ratio"),
		--slip_master
		slippery=init_skill("slippery,passive,0,upon dodging an attack inflict prone on attacker"),
		slip_stance=init_skill("slip stance,active,0,take a slippery stance which dodges all physical attacks"),
		--coiled
		capitalize=init_skill("capitalize,passive,0,deals 2x damage to stunned or proned or constricted enemies"),
		coil=init_skill("coil,active,0,charges a powerful attack for x turns and deals x * damage"),
		--constrictor
		--lingering=init_skill("lingering impact,passive,0,when a debuff caused directly by you is removed add new debuffs in it's place"),
		--constrict=init_skill("constrict,active,0,constrict a single target which prevents them from acting based on strength vs target strength"),
		--red
		red=init_skill("red,passive,0,gains access to spells and gains mp based on mag stat 5:1"),
		gold_burn=init_skill("gold burn,passive,0,each coin used to regain mp reduces maxhp by 1"),
		recover_mp=init_skill("recover mp,active,1,use a coin to recover all mp & increase max mp by 3"),
		--once_red
		once_red=init_skill("once red,passive,0,retains access to spells and mp from being red"),
		mana_dart=init_skill("mana dart,active,1,magical damage based on remaining mana"),
		--green
		--green=init_skill("green,passive,0,can absorb herbs as charges to be used in healing skills"),
		--healing_poultice=init_skill("healing poultice,active,0,use 1 charge to heal a single target"),
		--the_green=init_skill("the green,active,0,use 3 charges to heal the whole party"),
		--metal_sworn
		metal_sworn=init_skill("metal sworn,passive,0,once the metal is absorbed a new power will be born"),
		absorb=init_skill("absorb,active,0,absorbs some of the metal and restores a low amount of hp to self"),
		--metal
		metal=init_skill("metal,passive,0,all damage taken reduced by 50%"),
		sword=init_skill("sword,active,0,deals double damage & can inflict bleeding on a single target"),
		shield=init_skill("shield,active,0,acts as a shield by taking the hits for the party for a turn"),
		--creeping_death
		--purple=init_skill("purple,passive,0,physical attacks dealt or taken can inflict poison"),
		--poison_impact=init_skill("poison impact,active,0,deals damage based on number of poison stacks on target"),
		--kingslayer
		kingslayer=init_skill("kingslayer,passive,0,deal 2x total damage to boss enemies or 3x if they are bleeding"),
		sharpen=init_skill("sharpen,active,0,increases a single target's atk stat by 4 (stacks up to 3 times)"),
		--spells
		fire_dart=init_skill("fire dart,active,1,deals minor fire damage to a single target"),
		--lesser_fireball=init_skill("lesser fireball,active,1,deals moderate fire damage to a single target with a 50% chance to inflict burn"),
		--lesser_heat=init_skill("lesser heat,active,1,if wearing metal a single target takes major fire damage and is inflicted with a def debuff"),
		cold_breeze=init_skill("cold breeze,active,1,deals minor ice damage to a single target"),
		--lesser_frost=init_skill("lesser frost,active,1,deals moderate ice damage to a single target with a 50% chance to inflict slow"),
		static_bolt=init_skill("static bolt,active,1,deals moderate lightning damage to a random target"),
		--lesser_lightning=init_skill("lesser lightning,active,1,deals major lightning damage to a random target with a 50% chance to inflict stun"),
		--minor_shielding=init_skill("minor shielding,active,1,increases a single target's def by 4 (stacks up to 3 times)"),
		minor_bulwark=init_skill("minor bulwark,active,1,increases the whole party's def by 4 (stacks up to 3 times)")
	}
end

function init_skillpools()
	skill_pools={
		immortal=init_skillpool("immortal,revenge"),
		quick_blow=init_skillpool("stunning,quick_blow"),
		eldest=init_skillpool("legacy,gift"),
		slip_master=init_skillpool("slippery,slip_stance"),
		coiled=init_skillpool("capitalize,coil"),
		--constrictor=init_skillpool("lingering,constrict"),
		red=init_skillpool("red,gold_burn,recover_mp"),
		once_red=init_skillpool("once_red,mana_dart"),
		--green=init_skillpool("green,healing_poultice,the_green"),
		metal_sworn=init_skillpool("metal_sworn,absorb"),
		metal=init_skillpool("metal,sword,shield"),
		--creeping_death=init_skillpool("purple,poison_impact"),
		kingslayer=init_skillpool("kingslayer,sharpen"),
		shop_1=init_skillpool("fire_dart,cold_breeze,static_bolt,minor_bulwark"),
		--shop_2=init_skillpool("lesser_fireball,lesser_heat,lesser_frost,lesser_lightning,minor_bulwark")
	}
end

function init_npcs()
	npcs={}
	init_npc_data("rix the guardian,12,8,1,r",
		{
			init_dlg("!quest_started|the colony is under attack! monsters from the east!;please, you must help us before it is too late!|quest_started"),
			init_dlg("quest_started,!enemies_defeated|here they come!", function()
				start_battle("rats_x2", function(won)
					if won then flags["enemies_defeated"]=true end
				end)
			end),
			init_dlg("enemies_defeated,!elder_spoken_to|you did it! you pushed them back!;the elder will want to speak with you."),
			init_dlg("|the colony is safe once more thanks to you.")
		},
		{ init_move("elder_spoken_to|r,r,r,r,r,r,r,d,f_r|0.5") }
	)

	init_npc_data("nib the once-red,6,1,29",
		{
			init_dlg("!enemies_defeated|sorry, i'm busy right now collecting my mana for spells if you fail."),
			init_dlg("enemies_defeated|good, you defeated them. i thought a static bolt would be needed.;you have potential. perhaps i can teach you true power in the future.")
		}
	)

	init_npc_data("lib the metalsworn,2,11,57",
		{
			init_dlg("|sorry, i'm focused on absorbing this metal. it takes a lot of effort;but it will be worth it to become a metal slime. all that power.;though it's been many years since we've seen any...")
		}
	)

	init_npc_data("zig the hero,4,1,8",
		{
			init_dlg("!enemies_defeated|use the skills i taught you to defeat the enemies at the gate.;i believe in you."),
			init_dlg("enemies_defeated|well done! but don't get sloppy. you still have much to learn.;i will teach you all that i know soon enough. you'll need every advantage you can get for the battles to come.")
		}
	)

	init_npc_data("gab the guardian,10,6,1",
		{
			init_dlg("|another fight is coming. i'd rather skip it if i'm being honest.;i want to protect our people of course, but not dying is also nice.")
		},
		{ init_move("elder_spoken_to|d,d,r,r,r,r,r,r,r,r,r,u,u,f_r|0.6") }
	)

	init_npc_data("rax the guardian,2,3,8,r",
		{
			init_dlg("!rax_intro|i guard the sacred spawning pool of our people.;it is truly an honor but also a great responsibility.|rax_intro"),
			init_dlg("|if you venture to the rat tunnels, take care not to get lost in its turns.;some tunnels lead nowhere merely traps they will use to close in on you.")
		}
	)

	init_npc_data("bab,8,7,1,l",
		{
			init_dlg("!herb_collected|see that green herb? eventually you'll be able to collect them.;they are healing items and may even unlock some interesting powers.")
		}
	)

	init_npc_data("gog,10,3,1,r",
		{
			init_dlg("|zig is much older than he looks. which one? they used to be one in the same.;that was back before they divided. zig has been a legend since before i spawned.")
		}
	)

	init_npc_data("mub,5,11,1,u",
		{
			init_dlg("|we haven't heard from the southern colony in awhile.;we sent them our gold to fuel their defenses after all their losses during the last war with the rats.;of the five slime colonies only we two remain. i hope they are safe. eldest preserve us.")
		}
	)

	init_npc_data("nax,8,2,1",
		{
			init_dlg("|nib and zig are powerful enough to drive off the rats. in their prime, they could even ward off humans.;i worry though for the cost of using power has it's toll.;even greats like nib and zig must eventually retire to the spawning pool.")
		}
	)

	init_npc_data("fin,2,4,1,r",
		{
			init_dlg("|zig the elder has been sharing the lore of our people with me.;he was once known as the loremaster before he divided.;i wonder if he means to pass the title...")
		}
	)

	init_npc_data("zig the elder,5,1,1",
		{
			init_dlg("!enemies_defeated,!elder_spoken_to|our survival relies on you four. such a burden despite your youth..."),
			init_dlg("enemies_defeated,!elder_spoken_to|thank you for dealing with those assailants.;your bravery and strength will take you far.|elder_spoken_to"),
			init_dlg("elder_spoken_to|would you like to hear the old stories of our people?;the eldest, the dragon, the garuda, the hero, or the lost kings?;no? maybe next time then.")
		}
	)
end

function init_party()
	party={
		x=5,
		y=5,
		dx=0, --x facing: -1 (left), 0, 1 (right)
		dy=-1, --y facing: -1 (up), 0, 1 (down)
		sprite=1,
		sprite_offset=0,
		flip_x=false,
		members=build_party_members,
		herb=0,
		gold=0
	}
	party_set_leader()
end

function init_enemies()
	enemy_defs = {
		slime    = init_enemy("slime,1,10,10,0,0,3,1,2,0,0"),
		rat      = init_enemy("rat,66,10,10,0,0,2,2,2,0,0"),
	    rat_king = init_enemy("rat king,69,60,60,10,10,5,5,5,2,2")
	}
end

function init_enemy_groups()
	enemy_groups = {
		--slimes_x2   = {"slime","slime"},
		rats_x2     = {"rat","rat"},
		--rat_king    = {"rat_king"}
	}
end

--init window functions
function init_dialogue()
	dialogue={
		active=false,
		page=1,      
		--text box config
		box_x=4,
		box_y=88,
		box_w=120,
		box_h=36,
		pad=4,
		name_h=8
	}
end

--init helper functions
function init_temp_stats()
	--1=str 2=dex 3=con 4=mag
	--5=atk 6=def 7=spd 8=matk 
	--9=mdef 10=maxhp 11=maxmp
	temp_stats={}
	for i=1,11 do
		add(temp_stats,0)
	end
	return temp_stats
end

function init_skill(string_data)
	local name,type,mp_cost,desc=unpack(split(string_data))
	return {
		name=name,
		type=type,
		mp_cost=mp_cost,
		desc=desc
	}
end

function init_skillpool(string_data)
	local skill_set={}
	for name in all(split(string_data)) do 
		add(skill_set,skills[name])
	end
	return skill_set
end

function init_npc_data(s, dlg, mv)
	local name,x,y,sprite,facing=unpack(split(s))
	local npc={name=name, x=x, y=y, sprite=sprite,
		dialogue=dlg, moves=mv or {},
		px=x*8, py=y*8,
		sprite_offset=0,
		path={}}
	add(npcs, npc)
	if facing then apply_facing(npc, facing) end
	return npc
end

function init_dlg(s, action)
	local req,pages,sets=unpack(split(s,"|"))
	return {cond=make_cond(req), pages=split(pages,";",false), on_end=make_onend(sets,action)}
end

function init_move(s)
	local req,steps,speed=unpack(split(s,"|"))
	return {cond=make_cond(req), steps=steps, speed=speed or 1}
end

function init_member(string_data)
	local name,title,str,dex,con,mag=unpack(split(string_data))
	local member = {
		name=name,
		title=title,
		title_pretty=titles[title].name,
		sprite=titles[title].sprite,
		mastered_titles={},
		maxhp=5,
		hp=5,
		maxmp=0,
		mp=0,
		atk=1,
		def=1,
		spd=1,
		matk=1,
		mdef=1,
		str=str,
		dex=dex,
		con=con,
		mag=mag,
		str_total=0,
		dex_total=0,
		con_total=0,
		mag_total=0,
		maxhp_total=0,
		maxmp_total=0,
		status={},
		temp_stats=init_temp_stats(),
		skills=skill_pools[title]
	}
	if (title=="red") member.mastered_titles={[title]=true}
	member = refresh_stats(member)
	return member
end

function init_enemy(string_data)
	local name,sprite,maxhp,hp,maxmp,mp,atk,def,spd,matk,mdef=unpack(split(string_data))
	return {
        name=name,
        sprite=sprite,
        maxhp=maxhp,
		hp=hp,
        maxmp=maxmp,
        mp=mp,
		atk=atk,
        def=def,
        spd=spd,
        matk=matk,
        mdef=mdef,
        skills={}
    }
end

function init_battle_enemies(group_id)
    local list = {}
    for key in all(enemy_groups[group_id]) do
        add(list, enemy_defs[key])
    end
    return list
end

--main config
_init = init_intro
-->8
--update code

--update scenes
function update_intro()
	if (btnp(4) or wait_check()) init_mainmenu()
end

function update_mainmenu()
	if wait_cnt==1 then
		if menu_control(#menu_options) then
			if menu_sel==1 then 
				pal() 
				init_builder() 
			end
			--if menu_sel==2 then init_savemenu() end
		end
	end
end

--function update_savemenu()
--	if wait_check() then
--		if btnp(4) then
--			init_mainmenu()
--		end
--	end
--end

function update_game()
	if wait_check() then
		if (not game_over) then
			update_map()
			if dialogue.active then
				update_dialogue()
			elseif status.active then
				update_status()
			else
				update_npc_moves()
				update_npcs_walking()
				update_party()
				if btnp(5) then
					init_status()
				end
			end
			check_win_lose()
		else
			if (btnp(5)) extcmd("reset")
		end
	end
end

--update party and window functions
function update_party()
	local movex,movey=0,0
	
	if recover_anim>0 then recover_anim-=1 end
	if herb_anim>0 then herb_anim-=1 end
	if gold_anim>0 then gold_anim-=1 end
	
	if btnp(0) then
	 	party.sprite_offset=2
		movex,party.flip_x=-1,true
	elseif btnp(1) then 
		party.sprite_offset=2
		movex,party.flip_x=1,false
	end

	if btnp(2)	then
		party.sprite_offset=1
		movey=-1
	elseif btnp(3) then
		party.sprite_offset=0
		movey=1
	end

	if movex!=0 or movey!=0 then
		party.dx,party.dy=movex,movey
	end
	
	local newx,newy=party.x+movex,party.y+movey
	
	party_interact(newx,newy)
		
	if can_move(newx,newy) then
		party.x,party.y=mid(0,newx,127),mid(0,newy,63)
	--else
		--sfx(0)
	end
end

function update_dialogue()
	if (not dialogue.active) return
	if (btnp(4)) dialogue_advance()
end

--update helpers
function update_npc_moves()
	for npc in all(npcs) do
		for i=#npc.moves,1,-1 do
			local m=npc.moves[i]
			if m.cond==nil or m.cond() then
				npc.path=build_path(npc.x,npc.y,m.steps)
				npc.walk_speed=m.speed
				del(npc.moves,m)
			end
		end
	end
end

function update_npc_walk(npc)
	local next=npc.path[1]
	if not next then return end

	if next.face then
		if not npc.face_timer then
			apply_facing(npc,next.face)
			npc.face_timer=npc.face_hold or 20
		end
		npc.face_timer-=1
		if npc.face_timer<=0 then
			npc.face_timer=nil
			del(npc.path,next)
		end
		return
	end

	local tx,ty=next[1]*8,next[2]*8
	local dx,dy=tx-npc.px,ty-npc.py
	if ease_toward(npc,"px","py",tx,ty,npc.walk_speed) then
		npc.x,npc.y=next[1],next[2]
		del(npc.path,next)
		return
	end
	if abs(dx)>abs(dy) then
		npc.sprite_offset=2
		npc.flip_x=dx<0
	elseif dy<0 then
		npc.sprite_offset=1
	else
		npc.sprite_offset=0
	end
end

function update_npcs_walking()
	for npc in all(npcs) do
		if #npc.path>0 then update_npc_walk(npc) end
	end
end

function build_path(start_x,start_y,steps)
	local dirs={r={1,0},l={-1,0},u={0,-1},d={0,1}}
	local path={}
	local cx,cy=start_x,start_y
	for step in all(split(steps)) do
		if sub(step,1,2)=="f_" then
			local face_dir=sub(step,3)
			add(path,{face=face_dir})
		else
			local dir=dirs[step]
			cx,cy=cx+dir[1],cy+dir[2]
			add(path,{cx,cy})
		end
	end
	return path
end

function apply_facing(npc,dir)
	if dir=="r" then npc.sprite_offset=2; npc.flip_x=false
	elseif dir=="l" then npc.sprite_offset=2; npc.flip_x=true
	elseif dir=="u" then npc.sprite_offset=1
	elseif dir=="d" then npc.sprite_offset=0
	end
end

function facing_to_dir(dx,dy)
	if dx<0 then return "l"
	elseif dx>0 then return "r"
	elseif dy<0 then return "u"
	elseif dy>0 then return "d"
	end
	return nil
end

function ease_toward(obj,px_key,py_key,tx,ty,speed)
	local dx,dy=tx-obj[px_key],ty-obj[py_key]
	local dist=sqrt(dx*dx+dy*dy)
	if dist<1 then
		obj[px_key],obj[py_key]=tx,ty
		return true
	end
	obj[px_key]+=dx/dist*speed
	obj[py_key]+=dy/dist*speed
	return false
end

-->8
--draw code

--draw scenes
function draw_intro()
	cls()
	draw_centered("a mr traveling bard production")
end

function draw_mainmenu()
	cls()
	
	if wait_check() and wait_cnt<1 then
		wait_cnt+=1
		set_wait(60)
	end
	if wait_cnt==1 then
		draw_centered("even a",16,7)
		draw_centered("slime",24,12)
		draw_centered("can win",32,7)

		for i=0,8 do
			spr(1+i*7,8+i*13,64-abs(sin(time()/2+i/9))*3)
		end
		line(4,72,123,72,5)

		for n=1,#menu_options do
			local s=menu_sel==n
			if (s) spr(127,40,86+n*8)
			print(menu_options[n],48,88+n*8,s and 7 or 6)
		end

		print(version,0,120,5)
	end
end

--function draw_savemenu()
--	cls()
--	if wait_check() then
--		print("placeholder for save menu",0,0,7)
--	end
--end

function draw_game()
	cls()
	if game_over==false then
		if wait_check() then
			draw_map()
			draw_npcs()
			draw_party()
			camera()
			draw_dialogue()
			draw_status()
			--==debug start==

			--==debug end==
		end
	else
		draw_win_lose()
	end
end

--draw party and window functions
function draw_party()
	if recover_anim>0 and recover_anim%4<2 then
		draw_party_aura(12)
	end
	if herb_anim>0 and herb_anim%4<2 then
		draw_party_aura(11)
	end
	if gold_anim>0 and gold_anim%4<2 then
		draw_party_aura(10)
	end
	spr(party.sprite+party.sprite_offset,party.x*8,party.y*8,1.0,1.0,party.flip_x)
end

function draw_party_aura(c)
	local o
	if party.dx==0 then
		o=party.flip_x and 0 or 1
	else
		o=party.dx+(party.flip_x and 1 or 0)
	end
	circfill(party.x*8+3+o,party.y*8+5,4,c)
end

function draw_dialogue()
	if not dialogue.active then return end

	local bx,by,bw,bh,p=dialogue.box_x,dialogue.box_y,dialogue.box_w,dialogue.box_h,dialogue.pad

	rectfill(bx+2,by+2,bx+bw+2,by+bh+2,0)
	draw_panel(bx,by,bx+bw,by+bh)

	if dialogue.npc and dialogue.npc.name then
		local name=dialogue.npc.name
		local nw=#name*4+p*2
		draw_panel(bx,by-dialogue.name_h,bx+nw,by)
		print(name,bx+p,by-dialogue.name_h+2,7)
	end

	local text = wrap_string(dialogue.entry.pages[dialogue.page],true)
	print(text,bx+p,by+p,7)

	if (time()*4)%2<1 then
		print("🅾️",bx+bw-8,by+bh-6,6)
	end
end

function draw_panel(x0,y0,x1,y1,c)
	local c=c or 1
	rectfill(x0,y0,x1,y1,c)
	rect(x0,y0,x1,y1,7)
end

--draw misc
function draw_win_lose()
	camera()
	if game_win then
	 print("★ you win! ★",37,64,7) 
	else 
		print("game over! :(",38,64,7)
 	end
	print("press ❎ to play again",20,72,5)
end

function draw_centered(text,y,c)
	local y=y or 60
	local c=c or 7
	print(text, 64 - (#text*4)/2, y, c)
end

-->8
--dialogue code

function dialogue_find_entry(npc)
	for entry in all(npc.dialogue) do
		if entry.cond==nil or entry.cond() then
			return entry
		end
	end
	return nil
end

function dialogue_start(npc)
	local entry=dialogue_find_entry(npc)
	if entry==nil then return end

	npc.saved_facing={sprite_offset=npc.sprite_offset, flip_x=npc.flip_x}

	local dir=facing_to_dir(-party.dx,-party.dy)
	if dir then apply_facing(npc,dir) end

	dialogue.active=true
	dialogue.npc=npc
	dialogue.entry=entry
	dialogue.page=1
	dialogue.on_end=entry.on_end
end

function dialogue_advance()
	if not dialogue.active then return end

	if dialogue.page < #dialogue.entry.pages then
		dialogue.page+=1
	else
		dialogue_close()
	end
end

function dialogue_close()
	local cb=dialogue.on_end
	local npc=dialogue.npc

	if npc and npc.saved_facing then
		npc.sprite_offset=npc.saved_facing.sprite_offset
		npc.flip_x=npc.saved_facing.flip_x
		npc.saved_facing=nil
	end

	dialogue.active=false
	dialogue.npc=nil
	dialogue.entry=nil
	dialogue.on_end=nil
	if cb then cb() end
end

--dialogue helper functions
function parse_flags(s)
	if not s or s=="" then return nil end
	if type(s)=="table" then return s end
	local t={}
	for tok in all(split(s, ",")) do
		if sub(tok,1,1)=="!" then
			t[sub(tok,2)]=false
		else
			t[tok]=true
		end
	end
	return t
end

function make_cond(reqs)
	local t=parse_flags(reqs)
	if not t then return nil end
	return function()
		for flag,val in next,t do
			if (flags[flag] or false) ~= val then return false end
		end
		return true
	end
end

function make_onend(sets, action)
	local t=parse_flags(sets)
	if not t and not action then return nil	end
	return function()
		if t then
			for flag,val in next,t do flags[flag]=val end
		end
		if action then action()	end
	end
end

-->8
--battle system code

function init_battle(enemy_data)
	battle={
		state=battle_state.player_turn,
		active_char=1,
		active_enemy=1,
		message="your turn!",
		battle_select=1,
		targeting=false,
		target_side="enemy",
		target_select=1,
		anim_timer=0,
		shake={x=0},
		heal_flash={frame=0},
		frames=0,
		popups={},
		player_defends=false,
		enemy_defends=false,
		enemies={},
		battlers={}
	}

	--battlers init
	for m in all(party.members) do
		add(battle.battlers, init_battler(m))
	end

	for e in all(enemy_data) do
		add(battle.enemies, init_battler(e, true))
	end
	
	draw_battle_layout()

	--battle animations init
	anim={
		frames=0,
		maxframes=0
	}

	--setup main functions
	scene="battle"
	menu_sel=1
	set_wait(30)
	_update=update_battle
	_draw=draw_battle
end

--init battle helpers
function init_battler(src, is_enemy)
	local skills=src.skills or {}

	return {
		member=src, -- keep a reference
		name=src.name,
		is_enemy=is_enemy,
		sprite=src.sprite,
		maxhp=src.maxhp,
		hp=src.hp,
		maxmp=src.maxmp,
		mp=src.mp,
		atk=src.atk,
		def=src.def,
		spd=src.spd,
		matk=src.matk,
		mdef=src.mdef,
		temp_stats=init_temp_stats(),
		skills=skills,
		status={}
	}
end

function start_battle(enemy_group_id, on_battle_end)
    local enemy_data = init_battle_enemies(enemy_group_id)
    init_battle(enemy_data)
    battle.on_end = on_battle_end
end

--function start_rat_king_fight()
--	start_battle("rat_king", function(won)
--		if won then flags["rat_king_defeated"]=true end
--	end)
--end

--function use_skill(m,skill_key)
--	m.skill_uses=m.skill_uses or {}
--	m.skill_uses[skill_key]=(m.skill_uses[skill_key] or 0)+1
--end

--update battle scene
function update_battle()
    battle.anim_timer -= 1
    update_damage_popups()
    
	if battle.state==battle_state.anim then
        anim.frames -= 1
        if (anim.frames<=0) anim.done()
        return
    end

    if battle.state==battle_state.player_turn then
		update_battle_menu()
    elseif battle.state==battle_state.enemy_turn then
        update_enemy_turn()
	elseif battle.state==battle_state.round_end then
        if battle.anim_timer<=0 then
            battle.state = battle_state.player_turn
            battle.battle_select = 1
			battle.message = "your turn!"
        end
    elseif battle.state==battle_state.win or battle.state==battle_state.lose then
        if battle.anim_timer<=0 then
			local won=battle.state==battle_state.win
			local cb=battle.on_end
			sync_battle_to_party()
            scene="game"
            _update=update_game
            _draw=draw_game
			if cb then cb(won) end
        end
    end
end

function update_battle_menu()
    if battle.targeting then
        if (btnp(0)) cycle_target(-1)
        if (btnp(1)) cycle_target(1)
        if btnp(5) then
            battle.targeting = false
            return
        end
        if btnp(4) and battle.anim_timer<=0 then
            local actor = battle.battlers[battle.active_char]
            local target = battle.target_side=="enemy" and battle.enemies[battle.target_select] or battle.battlers[battle.target_select]
            if battle.battle_select==1 then
                do_basic_attack(actor, target)
            elseif battle.battle_select==2 then
                do_shield_attack(actor, target)
			elseif battle.battle_select==4 then
				party.herb-=1
				do_heal_skill(actor,target)
            end
            battle.targeting = false
        end
        return
    end

    if btnp(0) then
        battle.battle_select -= 1
        if (battle.battle_select<1) battle.battle_select=4
    end
    if btnp(1) then
        battle.battle_select += 1
        if (battle.battle_select>4) battle.battle_select=1
    end

    if btnp(4) and battle.anim_timer<=0 then
        if battle.battle_select==1 or battle.battle_select==2 then
            battle.targeting = true
            battle.target_side = "enemy"
            battle.target_select = 1
            if (battle.enemies[1].hp<=0) cycle_target(1)
        elseif battle.battle_select==3 then
            battle.message = "coming soon!" --placeholder
        elseif battle.battle_select==4 then
            if (party.herb==0) then 
				battle.message = "no herbs left!"
			else
				battle.targeting = true
				battle.target_side = "party"
				battle.target_select = 1
			end
        end
    end
end

--update battle helpers
function advance_turn()
    repeat
        battle.active_char += 1
        if battle.active_char > #battle.battlers then
            battle.active_char = 1
            battle.active_enemy = 1
            battle.state = battle_state.enemy_turn
            return
        end
    until battle.battlers[battle.active_char].hp > 0
    battle.state = battle_state.player_turn
    battle.battle_select = 1
end

function cycle_target(dir)
    local side = (battle.target_side=="enemy") and battle.enemies or battle.battlers
    local n = #side
    repeat
        battle.target_select += dir
        if battle.target_select > n then battle.target_select = 1 end
        if battle.target_select < 1 then battle.target_select = n end
    until side[battle.target_select].hp > 0
end

function get_alive(side)
    local out={}
    for _,e in inext,side do
        if e.hp>0 then add(out,e) end
    end
    return out
end

function all_dead(side)
    return #get_alive(side)==0
end

function pick_random_alive(side)
    local alive=get_alive(side)
    if #alive==0 then return nil end
    return alive[flr(rnd(#alive))+1]
end

function calc_damage(atk, def, variance)
    variance = variance or 3
    return max(atk + flr(rnd(variance)) - def, 1)
end

function land_hit(target, dmg, msg, color, timer)
	spawn_damage_popup(target.x+4, target.y-4, dmg<0 and -dmg or dmg, color or 8)
	resolve_damage(target, dmg, msg)
	if timer then battle.anim_timer = timer end
end

function sync_battle_to_party()
    for _,b in inext,battle.battlers do
        b.member.hp = b.hp
        b.member.mp = b.mp
    end
end

--update battle action resolutions
function do_basic_attack(user, target)
    local dmg = calc_damage(user.atk, target.def)
	attack_anim(
		user,
		function() 
			land_hit(target, dmg, user.name.." hits "..target.name.." for "..dmg.."!", 8) 
		end,
		finish_player_action
	)
end

function do_shield_attack(user, target)
    local dmg = calc_damage(flr(user.atk/2)+(user.shield_score or 0), target.def)
    play_anim(10,
        function() battle.shake.target=user; battle.shake.x=flr(rnd(3))-1 end,
        function()
            user.status.defending = true
			land_hit(target, dmg, user.name.." guards and hits "..target.name.." for "..dmg.."!", 8) 
			finish_player_action()
        end
    )
end

function do_heal_skill(user, target, heal)
	local target=target or user
	local heal=heal or 5
	heal_anim(
		target, 
		function()
			land_hit(target, -heal, user.name.." heals "..target.name.." for "..heal.."!", 11) 
			finish_player_action()
		end
	)
end

function resolve_damage(target, dmg, msg)
    target.hp = min(max(target.hp - dmg, 0),target.maxhp)
    battle.message = msg
    battle.anim_timer = 30
    battle.shake.target = nil
end

function finish_player_action()
	if all_dead(battle.enemies) then
        battle.state = battle_state.win
        battle.message = "you won!"
        battle.anim_timer = 60
    else
        advance_turn()
    end
end

--update battle enemy turn helpers
function update_enemy_turn()
    if battle.anim_timer > 0 then return end

    local e = battle.enemies[battle.active_enemy]
    if not e or e.hp<=0 then
        advance_enemy_turn()
        return
    end

	e.acting = true

    local target = pick_random_alive(battle.battlers)
    if not target then return end

    local dmg = calc_damage(e.atk, target.def)
    if target.status.defending then dmg = max(flr(dmg/2),1) end

    play_anim(dmg*3,
        function() battle.shake.target=e; battle.shake.x=flr(rnd(3))-1 end,
        function()
            land_hit(target, dmg, e.name.." hits "..target.name.." for "..dmg.."!", 8, 45)
			e.acting = false
			finish_enemy_action()
        end
    )
end

function finish_enemy_action()
    if all_dead(battle.battlers) then
        battle.state = battle_state.lose
        battle.message = "you lost..."
    else
        advance_enemy_turn()
    end
end

function advance_enemy_turn()
    battle.active_enemy += 1
    if battle.active_enemy > #battle.enemies then
        for _,b in inext,battle.battlers do b.status.defending=false end
        battle.active_char = 1
        while battle.battlers[battle.active_char].hp<=0 do
            battle.active_char += 1
        end
        battle.state = battle_state.round_end
        battle.anim_timer = 45
	else
		battle.state = battle_state.enemy_turn
    end
end

--draw battle scene
function draw_battle()
    cls()
	
	--win/lose overlay & battle log
    if battle.state==battle_state.win or battle.state==battle_state.lose then
    	local col=battle.state==battle_state.win and 11 or 8
    	print(battle.message,44,44,col)
	else
		local mx=64-(#battle.message*2)
    	print(battle.message,mx,8,7)
	end

	draw_battle_sprites()
	draw_damage_popups()
    
    --anim override draws on top
    if battle.state==battle_state.anim and anim.fn then
        anim.fn()
    end

	draw_target_cursor()

    --action menu (player turn only)
    if battle.state==battle_state.player_turn then
		local menu_icons = {118, 120, 122, 124}
		local menu_text = split("attack,defend,skills,herb x"..tostring(party.herb))
        for i=1,4 do
            local selected = battle.battle_select==i
			print(selected and menu_text[i] or "",36+(i-1)*12,56,7)
            local spr_id = menu_icons[i] + (selected and 0 or 1)
            spr(spr_id, 42+(i-1)*12, 64)
        end
    end
end

function draw_bar(x,y,val,maxval,col,w)
    w = w or 40
    local fill=max(0,flr((val/maxval)*w)-1)
    if fill>0 then rectfill(x,y,x+fill,y+1,col) end
end

function draw_enemy_row(enemies, center_x, y, padding)
    padding = padding or 4
    local total_w = 0
    for i,e in inext,enemies do
        e.layout_w = #e.name*4 + 2
        total_w += e.layout_w
        if i < #enemies then total_w += padding end
    end

    local x = center_x - total_w/2
    for i,e in inext,enemies do
        e.x = x + e.layout_w/2 - 4
        e.y = y
        e.label_cx = x + e.layout_w/2
        x += e.layout_w + padding
    end
end

function draw_battle_layout()
	draw_enemy_row(battle.enemies, 64, 32, 6)

    local col_w = 32
    for i,b in inext,battle.battlers do
        b.x = col_w*(i-1) + col_w/2 - 4
        b.y = 94
    end
end

function draw_battle_sprites()
	for i,e in inext,battle.enemies do
		if e.hp>0 then
			local shake_x = (battle.shake.target==e) and battle.shake.x or 0
			local bounce_y = e.acting and 2 or 0
			spr(e.anim_sprite or e.sprite, e.x+shake_x, e.y+bounce_y)
			if i == battle.target_select and battle.targeting and battle.target_side=="enemy" then
				draw_bar(e.label_cx-12, e.y-2, e.hp, e.maxhp, 8, 24)
				local nx = e.label_cx - (#e.name*2)
				print(e.name, nx, e.y+11, 7)
			end
		end
	end

    for i,b in inext,battle.battlers do
		local active = (battle.state==battle_state.player_turn and i==battle.active_char)
		local c=7
		if flr((b.hp/b.maxhp)*100)<=33 then
			c=b.hp<=0 and 8 or 10
		end
		local col_start=b.x-8
		if battle.heal_flash.target==b then
			local flash_c=(battle.heal_flash.frame%2==0) and 11 or 7
			draw_bar(col_start, b.y-2, b.hp, b.maxhp, flash_c, 24)
		else
			if active or (i==battle.target_select and battle.target_side=="party") then
            	draw_bar(col_start, b.y-2, b.hp, b.maxhp, 11, 24)
        	end
		end
		local s = b.anim_sprite or (active and b.sprite or b.sprite+1)
		if b.hp<=0 then	
			s=b.sprite+6 
		end
		spr(s, b.x, b.y)
		print(b.name, col_start, b.y+11, c)
		print("hp:"..b.hp, col_start, b.y+18, c)
		print("mp:"..b.mp, col_start, b.y+25, c)
	end
end

function draw_target_cursor()
    if not battle.targeting then return end

    local side = (battle.target_side=="enemy") and battle.enemies or battle.battlers
    local t = side[battle.target_select]
    if not t or t.hp<=0 then return end 

    local bob = flr(sin(time()*2)*2)
    local w = t.w or 8
    local cx = t.x + w/2
	spr(126,cx-2,t.y-16+bob)
end

--battle animations and popups
function play_anim(maxframes,fn,done)
	anim.frames=maxframes
	anim.maxframes=maxframes
	anim.fn=fn
	anim.done=done
	battle.state=battle_state.anim
end

function attack_anim(user, on_hit, done)
    local base_sprite = user.sprite+1
	local frames = {base_sprite,base_sprite+2,base_sprite+3,base_sprite+4,base_sprite+5,base_sprite}
    local ticks_per_frame = 4
    local seq_len = #frames
    local t = 0

    user.anim_sprite = frames[1]

    play_anim(
        seq_len * ticks_per_frame,
        function()
            t += 1
            local idx = min(flr((t-1)/ticks_per_frame)+1, seq_len)
            user.anim_sprite = frames[idx]
            if idx==seq_len and on_hit and not user.anim_hit_done then
                on_hit()
                user.anim_hit_done = true
            end
        end,
        function()
			battle.anim_timer = 30
            user.anim_sprite = nil
            user.anim_hit_done = nil
            if done then done() end
        end
    )
end

function heal_anim(target, on_heal)
    battle.heal_flash.target = target
    battle.heal_flash.frame = 0

    play_anim(
        30,
        function()
            battle.heal_flash.frame += 1
        end,
        function()
            battle.anim_timer = 30
			on_heal()
            battle.heal_flash.target = nil
        end
    )
end

function spawn_damage_popup(x, y, amount, color)
	add(battle.popups, {x=x+flr(rnd(5))-2, y=y, dy=0, val=amount, col=color, timer=30})
end

function update_damage_popups()
    for p in all(battle.popups) do
        p.y -= 0.5
        p.timer -= 1
        if p.timer<=0 then del(battle.popups, p) end
    end
end

function draw_damage_popups()
    for p in all(battle.popups) do
        local s = tostr(p.val)
        local w = #s*4
        print(s, p.x-w/2+1, p.y+1, 0)
        print(s, p.x-w/2, p.y, p.col)
    end
end

-->8
--map code

function init_map()
	--timers
	map_timer=0
	map_anim=15
	recover_anim=0
	herb_anim=0
	gold_anim=0

	--map tile settings
	wall=split([[192,193,194,195,196,197,198,203,205,206
		,208,213,214,215,216,217,218,219,224,229,230,231
		,232,233,238,239,240,245,246,247,249,250]])
	anim1=split("238,254")
	anim2=split("239,255")
	herbs=split("220,221,222")
	gold=split("223,236,237")
	recover=split("238,239,252")	
end

function update_map()
	if (map_timer<0) then
		update_tiles()
		map_timer=map_anim
	end
	map_timer-=1
end

function draw_map()
	mapx=flr(party.x/16)*16
	mapy=flr(party.y/16)*16
	camera(mapx*8,mapy*8)
	
	map(0,0,0,0,128,64)
end

function draw_npcs()
	for npc in all(npcs) do
  		draw_npc(npc.sprite+npc.sprite_offset,npc.px,npc.py,npc.flip_x)
 	end
end

function draw_npc(sprite,px,py,flip_x)
	spr(sprite,px,py,1,1,flip_x)
end

function is_tile(tile_type,x,y)
	tile=mget(x,y)
	for i=1,#tile_type do
		if (tile==tile_type[i]) return true
	end
	return false
end

function can_move(x,y)
	local no_move={wall,herbs,gold}
	for npc in all(npcs) do
		if (x==npc.x and y==npc.y) return false
	end
	for t in all(no_move) do
		if (is_tile(t,x,y)) return false
	end
	return true
end

function swap_tile(x,y)
	tile=mget(x,y)
	mset(x,y,tile+1)
end

function unswap_tile(x,y)
	tile=mget(x,y)
	mset(x,y,tile-1)
end

function update_tiles()
	for x=mapx,mapx+15 do
		for y=mapy,mapy+15 do
			if (is_tile(anim1,x,y)) then
				swap_tile(x,y)
				--sfx(3)
			elseif (is_tile(anim2,x,y)) then
				unswap_tile(x,y)
				--sfx(3)
			end
		end
	end
end

-->8
--party code

function party_interact(x,y)
	targetx=party.x+party.dx
	targety=party.y+party.dy
	
	--check for npc dialogue
	if btnp(4) and dialogue.active==false then 
 		for npc in all(npcs) do
  			if targetx==npc.x and targety==npc.y then
   				dialogue_start(npc) 
   				break
  			end
 		end

		if is_tile(recover,targetx,targety) then
			heal_party_full()
			recover_anim=24
			--sfx(1)
		elseif is_tile(herbs,targetx,targety) then
			local tile=mget(targetx,targety)
			local amt=(tile==222) and 3 or 1
			party.herb+=amt
			mset(targetx,targety,204)
			herb_anim=24
			--sfx(1)
		elseif is_tile(gold,targetx,targety) then
			local tile=mget(targetx,targety)
			local amt=1
			if tile==236 then
				amt=4+flr(rnd(3))
			elseif tile==237 then
				amt=12+flr(rnd(5))
			end
			party.gold+=amt
			mset(targetx,targety,204)
			gold_anim=24
			--sfx(1)
		end
 	end

end

function party_set_leader()
	party.sprite = party.members[1].sprite
end

function refresh_stats(member,refresh)
	--sets all member stats
	local refresh=refresh or false
	local temp_str,temp_dex,temp_con,temp_mag,temp_atk,temp_def,temp_spd,temp_matk,temp_mdef,temp_maxhp,temp_maxmp=unpack(member.temp_stats)
	local maxhp_start,maxmp_start=member.maxhp,member.maxmp
	
	member.str_total=member.str+temp_str
	member.dex_total=member.dex+temp_dex
	member.con_total=member.con+temp_con
	member.mag_total=member.mag+temp_mag
	
	member.atk = (member.str_total * 2) + temp_atk
	member.def = (member.con_total * 2) + temp_def
	member.spd = (member.dex_total * 2) + temp_spd
	member.matk = (member.mag_total * 2) + temp_matk
	member.mdef = (member.mag_total * 2) + temp_mdef
	
	member.maxhp_total=max(1,(max(1,member.con_total) * 5) + temp_maxhp)
	member.maxmp_total=max(0,member.maxmp + temp_maxmp)
	
	for i,s in inext,member.skills do
		if s.name=="red" or s.name=="once red" then
			member.maxmp_total = (max(1,member.mag_total) * 5) + temp_maxmp
		end
		if s.name=="eldest's legacy" then 
			member.maxhp_total*=3
		end
	end
	
	if refresh then
		--if maxhp increases hp increases
		local hpdiff,mpdiff=member.maxhp_total-maxhp_start,member.maxmp_total-maxmp_start
		if hpdiff>0 then
			member.maxhp+=hpdiff
			member.hp+=hpdiff
		end
		if mpdiff>0 then
			member.maxmp+=mpdiff
			member.mp+=mpdiff
		end
		--if maxhp decreases hp decreases to match maxhp if over it
		if member.hp>member.maxhp_total then
			member.maxhp=member.maxhp_total
			member.hp=member.maxhp_total
		end
		if member.mp>member.maxmp_total then
			member.maxmp=member.maxmp_total
			member.mp=member.maxmp_total
		end
		return member
	end
	
	member.maxhp, member.maxmp = member.maxhp_total, member.maxmp_total
	member.hp, member.mp = member.maxhp, member.maxmp
	return member
end

function init_status()
	local setup=status==nil

	status={
		active=not setup,
		mode="list",
		cursor=1,
		item_cursor=1,
		detail_section="skills",
		skill_cursor=1,
		spell_cursor=1,
		title_cursor=1
	}
end

function update_status()
	local mode=status.mode

	if mode=="list" then
		local d=btnp(2) and -1 or (btnp(3) and 1 or 0)
		if d!=0 then
			status.cursor=(status.cursor+d-1)%#party.members+1
		end

		if btnp(4) then
			status.mode="detail"
			status.detail_section="skills"
		end
		if(btnp(5)) status.active=false

	elseif mode=="detail" then
		local m=party.members[status.cursor]
		local sec=status.detail_section or "skills"

		if btnp(0) then
			status.detail_section=next_section(sec,-1)
		elseif btnp(1) then
			status.detail_section=next_section(sec,1)
		end

		sec=status.detail_section
		local list=get_section_list(sec,m)

		local d=btnp(2) and -1 or (btnp(3) and 1 or 0)
		if d!=0 and #list>0 then
			local key=sub(sec,1,-2).."_cursor"
			status[key]=(status[key]+d-1)%#list+1
		end

		if btnp(4) then
			if sec=="titles" then
				status.mode="title_swap"
				local keys=available_title_keys(m)
				status.swap_idx=1
				for i,k in inext,keys do
					if k==m.title then status.swap_idx=i end
				end
			else
				status.mode=sub(sec,1,-2).."_detail" -- "skill_detail"/"spell_detail"
			end
		end
		if(btnp(5)) status.mode="list"

	elseif mode=="title_swap" then
		local m=party.members[status.cursor]
		local keys=available_title_keys(m)
		if (btnp(0)) status.swap_idx=(status.swap_idx-2)%#keys+1
		if (btnp(1)) status.swap_idx=status.swap_idx%#keys+1
		if btnp(4) then
			apply_title_swap(m, keys[status.swap_idx])
			status.mode="detail"
		end
		if (btnp(5)) status.mode="detail"

	else -- skill_detail / spell_detail
		if(btnp(5) or btnp(4)) status.mode="detail"
	end
end

--shared title helpers (also used by the party builder)
function all_title_keys()
	if not cached_title_keys then
		cached_title_keys={}
		for k in next,titles do add(cached_title_keys,k) end
	end
	return cached_title_keys
end

--conditions gating which titles a member can swap into.
--a title with no entry here is always available.
title_unlock_conditions = {
	--must have been red before to become once_red
	once_red = function(m)
		return m.mastered_titles and m.mastered_titles["red"]
	end,
	--must have mastered metal_sworn and used absorb 10+ times
	metal = function(m)
		return m.mastered_titles and m.mastered_titles["metal_sworn"]
			and ((m.skill_uses and m.skill_uses["absorb"]) or 0) >= 10
	end,
	--must have defeated the rat king
	kingslayer = function(m)
		return flags["rat_king_defeated"]==true
	end
}

function is_title_unlocked(m,key)
	local cond=title_unlock_conditions[key]
	if not cond then return true end
	return cond(m) and true or false
end

--titles a given member is currently allowed to swap into
--(always includes their current title, even if a condition
--somehow no longer holds, so they're never stuck with no options)
function available_title_keys(m)
	m=m or {}
	local out={}
	for k in all(all_title_keys()) do
		if k==m.title or is_title_unlocked(m,k) then
			add(out,k)
		end
	end
	return out
end

function apply_title_swap(m,new_title)
	m.mastered_titles=m.mastered_titles or {}
	m.mastered_titles[m.title]=true
	m.title=new_title
	m.title_pretty=titles[new_title].name
	m.sprite=titles[new_title].sprite
	m.skills=skill_pools[new_title]
	refresh_stats(m,true)
end

function draw_status()
	if not status.active then return end

	if status.mode=="list" then
		draw_status_list()
	elseif status.mode=="detail" then
		draw_status_detail(party.members[status.cursor])
	elseif status.mode=="skill_detail" then
		draw_ability_detail(skill_pools[party.members[status.cursor].title][status.skill_cursor])
	elseif status.mode=="title_swap" then
		draw_status_title_swap(party.members[status.cursor])
	--else --spell_detail
		--draw_ability_detail(spell_pools[party.members[status.cursor].title][status.spell_cursor])
	end
end

function draw_status_title_swap(m)
	local tkey=available_title_keys(m)[status.swap_idx]
	cls(0)
	print("swap title",4,2,7)
	line(0,9,127,9,5)

	spr(titles[tkey].sprite,10,15)
	print(m.name.." "..titles[tkey].name,32,18,7)
	
	line(0,31,127,31,5)
	print("skills",4,34,7)
	local list=skill_pools[tkey]
	for i,s in inext,list do
		local y=42+(i-1)*24
		print(s.name,4,y,s.type=="active" and 7 or 15)
		print(wrap_string(s.desc),4,y+6,7)
	end

	line(0,120,127,120,5)
	print("⬅️➡️ title  🅾️ confirm  ❎ back",4,122,6)
end

function draw_status_list()
	cls(0)
	print("party status",4,2,7)
	draw_herb()
	draw_gold()
	line(0,9,127,9,5)

	for i,m in next,party.members do
		local y=12+(i-1)*28

		if i==status.cursor then
			rectfill(0,y-1,127,y+22,1)
		end

		print(m.name.." "..m.title_pretty,4,y,7)

		print("hp "..m.hp.."/"..m.maxhp,4,y+8,8)
		print("mp "..m.mp.."/"..m.maxmp,44,y+8,12)
		spr(m.sprite,106,y+5)

		print("str "..m.str.." dex "..m.dex.." con "..m.con.." mag "..m.mag,4,y+16,13)

		line(0,y+24,127,y+24,5)
	end
	print("🅾️ back",4,122,6)
end

function draw_status_detail(m)
	cls()
	print(m.name,4,2,7)
	print(m.title_pretty,4,9,6)

	line(0,16,127,16,5)
	
	spr(m.sprite,18,24)
	print("hp "..m.hp.."/"..m.maxhp,10,43,8)
	print("mp "..m.mp.."/"..m.maxmp,10,50,12)
	
	local stats=split("str ,str,dex ,dex,con ,con,mag ,mag, atk ,atk, def ,def, spd ,spd,matk ,matk,mdef ,mdef")
	for i=1,9 do
		local x,y=56,22+((i-1)%4)*7
		if(i>4) x,y=94,22+(i-5)*7
		local idx=(i-1)*2+1
		print(stats[idx]..m[stats[idx+1]],x,y,7)
	end
	
	line(0,60,127,60,5)
	
	local sec=status.detail_section or "skills"
	print("skills",4,63,sec=="skills" and 7 or 5)
	print("spells",52,63,sec=="spells" and 7 or 5)
	print("titles",100,63,sec=="titles" and 7 or 5)

	line(0,70,127,70,5)

	local cursor_key=sub(sec,1,-2).."_cursor"
	local cursor=status[cursor_key]
	local list=get_section_list(sec,m)

	for i,s in next,list do
		local y=73+(i-1)*7

		if(i==cursor and sec~="titles") rectfill(0,y-1,127,y+5,1)

		print(s.name,4,y,s.type=="active" and 7 or 15)

		if s.name=="recover mp" then
			print("1 coin",90,y,9)
		elseif s.mp_cost and s.mp_cost>0 then
			print(s.mp_cost.." mp",90,y,12)
		end
	end

	line(0,120,127,120,5)
	local opt=sec=="titles" and "swap" or "view"
	print("⬅️➡️ toggle  🅾️ "..opt.."  ❎ back",4,122,6)
end

function draw_ability_detail(s)
	cls(0)
	print(s.name,4,2,7)
	print(s.type,4,9,6)
	if s.name=="recover mp" then
		print("1 coin",90,9,9)
	elseif s.mp_cost>0 then 
		print("mp cost "..s.mp_cost,90,9,12)
	end
	line(0,16,127,16,5)

	local detail_wrap = wrap_string(s.desc)
	print(detail_wrap,4,20,7)

	line(0,120,127,120,5)
	print("🅾️/❎ back",4,122,6)
end

--helpers for party and status
function get_section_list(sec,m)
	if sec=="skills" then
		return skill_pools[m.title] or {}
	elseif sec=="spells" then
		return (spell_pools and spell_pools[m.title]) or {}
	else -- titles
		local list={}
		for k in next,m.mastered_titles or {} do
			add(list,{name=titles[k].name})
		end
		return list
	end
end

function next_section(sec,dir)
	local idx=1
	for i,v in inext,section_order do
		if v==sec then idx=i break end
	end
	idx=((idx-1+dir)%#section_order)+1
	return section_order[idx]
end

function draw_gold()
	print(party.gold.." coin"..(party.gold>1 and "s" or ""),100,2,9)
end

function draw_herb()
	print(party.herb.." herb"..(party.herb>1 and "s" or ""),70,2,3)
end

-->8
--utility functions

function wait_check()	
	if wait==0 then
		return true
	else
		wait-=1
		return false
	end
end

function set_wait(num)
	wait=num
end

function menu_control(option_cnt)
	if btnp(2) then 
		menu_sel-=1
		if menu_sel<1 then
			menu_sel=option_cnt
		end 
	end
	if btnp(3) then 
		menu_sel+=1 
		if menu_sel>option_cnt then
			menu_sel=1
		end
	end
	if btnp(4) then
		return true
	end
	if btnp(5) then
		return false
	end
end

function check_win_lose()
	if bbeg_defeated then
		game_win,game_over=true,true
	elseif party_wiped() then
		game_win,game_over=false,true
	end
end

function party_wiped()
	for i=1,#party.members do
  		if (party.members[i].hp>0) return false
 	end
 	return true
end

function wrap_string(str,is_dialogue)
	local is_d = is_dialogue or false
	local limit,result,cur_line,word=is_d and 29 or 31,"","",""

	local function add_break()
		if word == "" then return end
		if #cur_line == 0 then
			cur_line = word
		elseif #cur_line + 1 + #word <= limit then
			cur_line = cur_line.." "..word
		else
			result = result..cur_line.."\n"
			cur_line = word
		end
		word = ""
	end

	for i=1,#str do
		local c = sub(str,i,i)
		if c == " " then
			add_break()
		else
			word = word..c
		end
	end
	add_break()

	return result..cur_line
end

function heal_party_full()
    for _,m in inext,party.members do
        m.hp = m.maxhp
        m.mp = m.maxmp
    end
end

--party builder
name_chars="abcdefghijklmnopqrstuvwxyz"
def_names=split"zag,gig,mab,bib,gaz,nim,pib"

function set_char(s,pos,ch)
	return sub(s,1,pos-1)..ch..sub(s,pos+1)
end

function pick(t)
	local n=rnd(t)
	del(t,n)
	return n
end

function cycle_char(c,dir)
	local i=1
	for j=1,#name_chars do
		if sub(name_chars,j,j)==c then i=j end
	end
	i=(i-1+dir)%#name_chars+1
	return sub(name_chars,i,i)
end

function init_builder()
	scene="builder"
	init_titles()
	init_skills()
	init_skillpools()
	builder_party={}
	for i=1,4 do
		add(builder_party,{name="",title=1})
	end
	builder_cursor=1
	builder_mode="main"
	builder_char_pos=1
	builder_skill_cursor=1
	set_wait(10)
	_update=update_builder
	_draw=draw_builder
end

function builder_member(i)
	local b=builder_party[i]
	local tkey=available_title_keys()[b.title]
	local nm=b.name~="" and b.name or "???"
	return init_member(nm..","..tkey..",1,1,1,1"),tkey
end

function start_from_builder()
	build_party_members={}
	for i=1,4 do
		local b=builder_party[i]
		if b.name=="" then b.name=pick(def_names) end
		add(build_party_members,(builder_member(i)))
	end
	init_game()
end

function update_builder()
	if not wait_check() then return end

	if builder_mode=="main" then
		if (btnp(2)) builder_cursor=(builder_cursor-2)%5+1
		if (btnp(3)) builder_cursor=builder_cursor%5+1

		if builder_cursor==5 then
			if (btnp(4)) start_from_builder()
			return
		end

		local b=builder_party[builder_cursor]
		local nkeys=#available_title_keys()
		if (btnp(0)) b.title=(b.title-2)%nkeys+1
		if (btnp(1)) b.title=b.title%nkeys+1
		if btnp(4) then
			builder_mode="name"
			builder_char_pos=1
			if (b.name=="") b.name="aaa"
		end
		if (btnp(5)) builder_mode,builder_skill_cursor="skills",1


	elseif builder_mode=="name" then
		local b=builder_party[builder_cursor]
		if (btnp(1)) builder_char_pos=builder_char_pos%3+1
		if (btnp(0)) builder_char_pos=(builder_char_pos-2)%3+1
		local c=sub(b.name,builder_char_pos,builder_char_pos)
		if (c=="") c="a"
		if (btnp(2)) b.name=set_char(b.name,builder_char_pos,cycle_char(c,-1))
		if (btnp(3)) b.name=set_char(b.name,builder_char_pos,cycle_char(c,1))
		if (btnp(4) or btnp(5)) builder_mode="main"

	elseif builder_mode=="skills" then
		local _,tkey=builder_member(builder_cursor)
		local list=skill_pools[tkey]
		if (btnp(2)) builder_skill_cursor=(builder_skill_cursor-2)%#list+1
		if (btnp(3)) builder_skill_cursor=builder_skill_cursor%#list+1
		if (btnp(4)) builder_mode="skill_detail"
		if (btnp(5)) builder_mode="main"

	else --skill_detail
		if (btnp(4) or btnp(5)) builder_mode="skills"
	end
end

function draw_builder()
	cls()
	print("build your party",4,2,7)
	line(0,9,127,9,5)

	for i=1,4 do
		local b=builder_party[i]
		local y=12+(i-1)*23
		if i==builder_cursor then rectfill(0,y-1,127,y+19,1) end
		local mem,tkey=builder_member(i)
		spr(mem.sprite,4,y)
		local nm=b.name~="" and b.name or "???"
		print(nm.." "..titles[tkey].name,14,y,7)
		print("str"..mem.str.." dex"..mem.dex.." con"..mem.con.." mag"..mem.mag,14,y+7,13)
		print("hp"..mem.maxhp.." mp"..mem.maxmp.." atk"..mem.atk.." def"..mem.def,14,y+14,6)
	end

	if builder_cursor==5 then rectfill(0,106,127,114,1) end
	draw_centered("> start game <",108,10)

	print("⬅️➡️ title 🅾️ name ❎ skills",4,122,6)

	if builder_mode=="name" then draw_builder_name() end
	if builder_mode=="skills" then draw_builder_skills() end
	if builder_mode=="skill_detail" then draw_builder_skill_detail() end
end

function draw_builder_name()
	local b=builder_party[builder_cursor]
	draw_panel(28,50,99,70,0)
	print("enter name",32,53,7)
	for i=1,3 do
		local c=sub(b.name,i,i)
		local blink=(i==builder_char_pos) and (time()*4)%2<1
		print(c,48+(i-1)*8,62,blink and 5 or 7)
	end
end

function draw_builder_skills()
	local _,tkey=builder_member(builder_cursor)
	local list=skill_pools[tkey]
	draw_panel(18,16,109,104,0)
	print("skills",21,19,7)
	for i,s in inext,list do
		local y=28+(i-1)*8
		if i==builder_skill_cursor then rectfill(19,y-2,108,y+6,1) end
		print(s.name,21,y,s.type=="active" and 7 or 15)
	end
	print("🅾️ view ❎ back",21,98,6)
end

function draw_builder_skill_detail()
	local _,tkey=builder_member(builder_cursor)
	local s=skill_pools[tkey][builder_skill_cursor]
	draw_panel(0,28,127,92,0)
	print(s.name,3,31,7)
	print(s.type,3,38,6)
	print(wrap_string(s.desc),3,46,7)
	print("🅾️/❎ back",3,86,6)
end

__gfx__
000000000000000000000000000000000000c0000000c00070000000000000000000000000000000000000000000100000001000700000000000000000000000
00000000000000000000000000000000000d7c00000d7c007000700000000000000000000000000000000000000d6100000d6100700070000000000000000000
0070070000000000000000000000000000dcccc000dcccc0000070700000000000000000000000000000000000d1111000d11110000070700000000000000000
000770000000c0000000c0000000c00000ccccc000ccccc007000070000000000000100000001000000010000011111000111110070000700000000000008000
00077000000d7c00000d7c00000d7c0000ccccc000dcccd0070c0070000c0000000d1100000d1100000d11000011111000d111d00701007000010000000d7800
0070070000d7ccc000d7ccc000d7ccc000dcccd00000000000d7c00000d7c00000d1111000d1111000d1111000d111d00000000000d6100000d6100000d78880
0000000000c1c1c000ccccc000ccc1c000000000000000000d7cccc00d7cccc000161610001111100011161000000000000000000d6111100d61111000818180
0000000000dcccd000dcccd000dcccd00000000000000000cccccccccccccccc00d111d000d111d000d111d00000000000000000111111111111111100d888d0
0000000000000000000080000000800070000000000000000000000000000000000000000000b0000000b0007000000000000000000000000000000000000000
0000000000000000000d7800000d78007000700000000000000000000000000000000000000d7b00000d7b007000700000000000000000000000000000000000
000000000000000000d8888000d88880000070700000000000000000000000000000000000dbbbb000dbbbb00000707000000000000000000000000000000000
0000800000008000008888800088888007000070000000000000b0000000b0000000b00000bbbbb000bbbbb007000070000000000000e0000000e0000000e000
000d7800000d78000088888000d888d00708007000080000000d7b00000d7b00000d7b0000bbbbb000dbbbd0070b0070000b0000000d7e00000d7e00000d7e00
00d7888000d7888000d888d00000000000d7800000d7800000d7bbb000d7bbb000d7bbb000dbbbd00000000000d7b00000d7b00000d7eee000d7eee000d7eee0
008888800088818000000000000000000d7888800d78888000b3b3b000bbbbb000bbb3b000000000000000000d7bbbb00d7bbbb000e1e1e000eeeee000eee1e0
00d888d000d888d00000000000000000888888888888888800dbbbd000dbbbd000dbbbd00000000000000000bbbbbbbbbbbbbbbb00deeed000deeed000deeed0
0000e0000000e0007000000000000000000000000000000000000000000090000000900070000000000000000000000000000000000000000000200000002000
000d7e00000d7e007000700000000000000000000000000000000000000d7900000d79007000700000000000000000000000000000000000000d7200000d7200
00deeee000deeee0000070700000000000000000000000000000000000d9999000d99990000070700000000000000000000000000000000000d2222000d22220
00eeeee000eeeee00700007000000000000090000000900000009000009999900099999007000070000000000000200000002000000020000022222000222220
00eeeee000deeed0070e0070000e0000000d7900000d7900000d79000099999000d999d007090070000900000005720000057200000572000022222000d222d0
00deeed00000000000d7e00000d7e00000d7999000d7999000d7999000d999d00000000000d7900000d7900000572220005722200057222000d222d000000000
00000000000000000d7eeee00d7eeee0009a9a900099999000999a9000000000000000000d7999900d7999900021212000222220002221200000000000000000
0000000000000000eeeeeeeeeeeeeeee00d999d000d999d000d999d0000000000000000099999999999999990052225000522250005222500000000000000000
70000000000000000000000000000000000000000000600000006000700000000000000000000000000000000000000000001000000010007000070000000000
7000700000000000000000000000000000000000000d7600000d7600700070000000000000001000000010000000010000011100000111007000070000000000
000070700000000000000000000000000000000000d6666000d666600000707000000000000111000001110000000100000d7c00000d7c000001000700010000
07000070000000000000600000006000000060000066666000666660070000700000000000006000000060000000c60000dcccc000dcccc00711100700111000
0702007000020000000d7600000d7600000d76000066666000d666d00706007000060000000d6c00000d7c00000d760000ccccc000ccccc00706000700060000
00d7200000d7200000d7666000d7666000d7666000d666d00000000000d7600000d7600000d76cc000d7ccc000d7ccc000ccccc000dcccd000d7c00000d7c000
0d7222200d72222000656560006666600066656000000000000000000d7666600d76666000c1c1c000ccccc000ccc1c000dcccd0000000000d7cccc00d7cccc0
222222222222222200d666d000d666d000d666d00000000000000000666666666666666600dcccd000dcccd000dcccd00000000000000000cccccccccccccccc
00fff00000060000000000000099900000040000000000000dd666000dd666070dd666070dd666000dd666000dd6660a0dd6660a0dd666000dd666000dd66600
0f00f00000666000000000000900900000444000000000000dd666070dd666070dd666070dd666000dd666070dd6660a0dd6660a0dd666000dd666000dd66600
0f00dd000ed6de0000000600090055000e545e00000004000d0006070d0006070d0006070d0006000d0006070d00060a0d00060a0d0006000d0006000d000600
000d66000066600000006e60000544000044400000004e400ddd66070ddd66070ddd66070ddd66000ddd66070ddd660a0ddd660a0ddd66000ddd66000ddd5445
000666000066d000006666d60004440000445000004444a40bdd63070bdd636103dd636103dd630003dd63070bdd636103dd636103dd63000bdd63000bdd4444
00ed6de000dd00f00ff6666000e545e0005500900994444007b3336107b3330103333301033333000333336107b33301033333010333330007b3330007b35445
00066600000f00f0f00000000004440000090090900000000b3dd6010b3dd6000ddd6600777116000ddd66010b3dd6000ddd6600aaa116000b3dd6000b3dd440
00006000000fff000ff0000000004000000999000990000033d0d00033d0d00033d3633033d3633033d3633033d0d00033d3633033d3633033d0d00033d0d000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd66600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0ddd66000b7bdddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bdd630003b3d0dd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07b333003333d0660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3b3dd600333360660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaccccaa776666770000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000acccccca766666670000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4a44a4c6d7dd7d60000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4a44a4c6d7dd7d60000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000caa99aac677667760000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c595595c656556560000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a4a44a4a7d7dd7d70000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaccccaa776666770000000000000000
000000000000000000000000000000000000000000000000aaccccaa77666677aaccccaa77666677aaccccaa77666677aaccccaa776666770000000000000000
000000000000000000000000000000000000000000000000accd6cca76677667ac5555ca76555567acc55cca76655667accc3cca76665667000dd00000007000
000000000000000000000000000000000000000000000000cccd6ccc66677666c564465c657dd756cc5aa5cc66566566ccc3b3cc666565660007700000007700
000000000000000000000000000000000000000000000000cccd6ccc66677666c544445c65dddd56c59a7a5c65d67656cc3b3b3c66565656000770000d777770
000000000000000000000000000000000000000000000000cccd6ccc66677666c564465c657dd756c599aa5c65dd6656cc3b3b3c66565656077777700d777770
000000000000000000000000000000000000000000000000cc5544cc66555566cc5445cc665dd566cc5995cc665dd566ccc3b3cc666565660077770000007700
000000000000000000000000000000000000000000000000acc54cca76655667acc55cca76655667acc55cca76655667accc3cca766656670007700000007000
000000000000000000000000000000000000000000000000aaccccaa77666677aaccccaa77666677aaccccaa77666677aac3ccaa776566770000000000000000
00000004400000000000000440000000000000044000000000555555555555555555555555555555555555555555550055555555511115554555550555555455
04440044440044400444004444004440044400444400444004455555555555555555555555555555555555445555544055555555144441555455500555554555
04444544445444455444454444544445544445444454444004444555555555555555555555554555555555445555444055555555144644155550005545555555
04444554445444555544455444544455554445544454444004444555554555555555555555555555555555555554444055555555144464155500005455555555
00445554455544555544555445554455554455544555440000445554555555555555554555555555555455555555440055555555124444415500005555555545
00555555555555555555555555555555555555555555550000555544555555555555555555555555555555555555550055555555124464414000055455555555
04445555544555555555555555455555555555555555544004445544555554455455555555555445555555554555544055555555512244155000545555455555
44444555544455555555554555445555555555455554444444444555555554455555445555555445555555555554444455555555551111550055555555555545
44444555555555555445555555445555544555555554444444444555545555555555445554555555555544455554444455555555555554555555555555555555
04455554555555555445555555555545544555544555444004455555555555555555545555555555555554455555444055555555555545555b5b555555555555
005555555555555555555555555555555555555445555500005555555555555555555555555555555555555555555500555555554555555555b5555555555555
004455555555455555555555545555555555555455554400004455544555445555445554455544555544555445554400555b5b55555b5b555b5b555555555555
0444455555555555555555555555555555555555555444400444454445544455544445444554445554444544455444405555b5555555b54555555b5b5555a555
044445554455555555545555555555555555455555544440044445444454444554444544445444455444454444544440555b5b55555b5b55b5b555b555559555
04455555445555555555555555555555555555555555544004440044440044400444004444004440044400444400444055555555554555555b555b5b55555555
0055555555555555555555555555555555555555555555000000000440000000000000044000000000000004400000005555555555555545b5b5555555555555
005555555555555555555555555555555555554455555500555544445555555500000000000000000000000000000000555555555a5555a55555555555445555
04445555554555555555555555555555555555445555444055555544555555550000000000000000000000000000000055555555595555955555555555554555
044445555555555555555555555555555455555555544440555555555555555500000000000000000000000000000000555555555555aa555555555555554555
044445555555555555555555555555555555555555544440555555555555555500000000000000000000000000000000555555a555a5995a4555544555555455
004455544555555555555555555555555555555555554400554555555555555500000000000000000000000000000000555555955595aa595455455455554555
0055554445555555555555555555555555555555555555005555555555555555000000000000000000000000000000005a55a5a555a5995a5544555555554555
04445555555555555555555555555555555555555455544055555455555555550000000000000000000000000000000059559595a59555595555555555545455
44444555555545555555555555555555555555555554444455555555555555550000000000000000000000000000000055555555955555555555555555455545
44444555555555555555555555555555555555555554444455555555555555550000000000000000000000000000000055555555000000005555555555555555
04455554555555555555555555555555555455555555444055555555555555550000000000000000000000000000000055040555000000005222555558885555
00555555555555555555555555555555555555444555550055555555555555550000000000000000000000000000000054444455000000005555225555558855
00445555555555555555555555555555555555445555440055555555555555550000000000000000000000000000000040404045000000005555552555555585
04444555555554555555555555555555555555555554444055555555555555550000000000000000000000000000000054444455000000002552252585588585
04444555445555555555555555555555555555555554444055555555555555550000000000000000000000000000000055111555000000002552552585585585
04455555445555555555555555555555555554555555544055555555555555550000000000000000000000000000000055111555000000005255225558558855
00555555555555555555555555555555555555555555550055555555555555550000000000000000000000000000000055555555000000005525555555855555
0000000dd00000000000000dd00000000000000dd00000000055555555555555555555555555555555555555555555005555555551111555d555550555555d55
0ddd00dddd00ddd00ddd00dddd00ddd00ddd00dddd00ddd00dd55555555555555555555555555555555555dd55555dd0555555551dddd1555d5550055555d555
0dddd5dddd5dddd55dddd5dddd5dddd55dddd5dddd5dddd00dddd55555555555555555555555d555555555dd5555ddd0555555551dd6dd1555500055d5555555
0dddd55ddd5ddd5555ddd55ddd5ddd5555ddd55ddd5dddd00dddd55555d55555555555555555555555555555555dddd0555555551ddd6d155500005d55555555
00dd555dd555dd5555dd555dd555dd5555dd555dd555dd0000dd555d55555555555555d555555555555d55555555dd005555555512ddddd155000055555555d5
005555555555555555555555555555555555555555555500005555dd55555555555555555555555555555555555555005555555512dd6dd1d000055d55555555
0ddd55555dd555555555555555d555555555555555555dd00ddd55dd55555dd55d55555555555dd555555555d5555dd0555555555122dd1550005d5555d55555
ddddd5555ddd5555555555d555dd5555555555d5555dddddddddd55555555dd55555dd5555555dd555555555555ddddd555555555511115500555555555555d5
ddddd555555555555dd5555555dd55555dd55555555dddddddddd5555d5555555555dd555d5555555555ddd5555ddddd5555555555555d555555555555555555
0dd5555d555555555dd55555555555d55dd5555dd555ddd00dd555555555555555555d555555555555555dd55555ddd0555555555555d5555b5b555555555555
005555555555555555555555555555555555555dd555550000555555555555555555555555555555555555555555550055555555d555555555b5555555555555
00dd55555555d555555555555d5555555555555d5555dd0000dd555dd555dd5555dd555dd555dd5555dd555dd555dd00555b5b55555b5b555b5b555555555555
0dddd55555555555555555555555555555555555555dddd00dddd5ddd55ddd555dddd5ddd55ddd555dddd5ddd55dddd05555b5555555b5d555555b5b5555a555
0dddd555dd555555555d5555555555555555d555555dddd00dddd5dddd5dddd55dddd5dddd5dddd55dddd5dddd5dddd0555b5b55555b5b55b5b555b555559555
0dd55555dd55555555555555555555555555555555555dd00ddd00dddd00ddd00ddd00dddd00ddd00ddd00dddd00ddd05555555555d555555b555b5b55555555
0055555555555555555555555555555555555555555555000000000dd00000000000000dd00000000000000dd000000055555555555555d5b5b5555555555555
00555555555555555555555555555555555555dd555555005555ddddddddd55500000000005555555555555500000000555555555a5555a555dddd5555dddd55
0ddd555555d555555555555555555555555555dd5555ddd0555555dd5dd5555d0000000000dd5d5d555d55550000000055555555595555955dccccd55dcc7cd5
0dddd5555555555555555555555555555d555555555dddd0555555555555555550dd00000ddd555d5555555500000000555555555555aa55dc77cccddcccc77d
0dddd55555555555555555555555555555555555555dddd055555555555555555ddd00000dd00dd5555555d500000000555555a555a5995ad7ccc7cddcc7cccd
00dd555dd55555555555555555555555555555555555dd0055d55555555555555dd000000000dddd5555555500000000555555955595aa59dccccc7ddc7ccccd
005555ddd555555555555555555555555555555555555500555555555555dd5555550ddd0000dddd555d5555000000005a55a5a555a5995adcc77ccddcccc7cd
0ddd5555555555555555555555555555555555555d555dd055555d555555dd555555dddd0000ddd0555555550000000059559595a59555595dccccd55dcc7cd5
ddddd5555555d555555555555555555555555555555ddddd5555555555555d555dd5dddd000000000dd55dd500000000555555559555555555dddd5555dddd55
ddddd55555555555555555555555555555555555555ddddd5555dd55555555555dd55dd000000000dddd5dd50000000000000000000000000000000000000000
0dd5555d555555555555555555555555555d55555555ddd05555dd5555555dd5555555550ddd0000dddd55550000000000000000000000000000000000000000
00555555555555555555555555555555555555ddd55555005555555555d55dd55555d555dddd0000ddd055550000000000000000000000000000000000000000
00dd5555555555555555555555555555555555dd5555dd005555555d5555555555555555dddd000000000dd50000000000000000000000000000000000000000
0dddd55555555d55555555555555555555555555555dddd0555555dd5555555d5d5555555dd00dd00000ddd50000000000000000000000000000000000000000
0dddd555dd555555555555555555555555555555555dddd0555555dd555555dd5555555dd555ddd00000dd050000000000000000000000000000000000000000
0dd55555dd555555555555555555555555555d5555555dd05d5555dd5ddd55dd5555d55dd5d5dd00000000000000000000000000000000000000000000000000
0055555555555555555555555555555555555555555555005555555dddddd5555555555555555500000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d7c0000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d7ccc000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c0c0c000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000dcccd000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000077707070777077000000777000000770700077707770777000000770777077000000707077707700000000000000000000000000
00000000000000000000000070007070700070700000707000007000700007007770700000007000707070700000707007007070000000000000000000000000
00000000000000000000000077007070770070700000777000007770700007007070770000007000777070700000707007007070000000000000000000000000
00000000000000000000000070007770700070700000707000000070700007007070700000007000707070700000777007007070000000000000000000000000
00000000000000000000000077700700777070700000707000007700777077707070777000000770707070700000777077707070000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007000770077707070000007707770777077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000700707070007070000070007070777070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000070707077007070000070007770707077000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000700707070007770000070707070707070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000007000707077707770000077707070707077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077007707700777077707700707077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700070707070070007007070707070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700070707070070007007070707077000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000700070707070070007007070707070000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000077077007070070077707070077077700000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
c0c1c2c3c2c3c2c3c2c3c4c5000000000000c0c1c2c3c4c3e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d1d2d3d2d3d2d3d2d3d4d5000000000000d0d1d2d3d2d3f8f9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1eee3e3e3e3e3e3cee4e5000000000000e0e1e2e2e2f2e3f8e80000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f1e3e3e3cfe3e3cfe3f4f5000000000000d0d1d2f6d9f1e3e3f8f900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1e3e3e3e3e3e3e3e3e4e5000000000000e0e1e4e500e9eae3e3f8e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f1e3e3e3e3e3cde3e3f4f5000000000000f0f1f4f50000faf7e3ece5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6f1e3e3e3e3e3e3e3e3e4e5000000000000c6c7e4e5000000e9eacacb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0e1e3e3cde3e3dce3e3f4e6c2c3c2c3c2c3e7c7f4f500000000fadadb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1f2f2f2f2f2f2f2f2f2c9c8c9c8c9c8c9e2f2e4e500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f1f2f2f2f2f2f2f2f2f6d9d8d9d8d9d8d9f7f2f4f500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
e0e1e2e2e2e2f2f2c9cacb00000000000000d0d1f2e6e8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f0f1e2e2e2e2f4f6d9dadb00000000000000e0e1f2f2f8f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c6c7c8c9c8c9cacb00000000000000000000f0f1f2def4f50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d6d7d8d9d8d9dadb00000000000000000000c6c7c8c9cacb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000d6d7d8d9dadb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
