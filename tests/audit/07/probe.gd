extends Node
## Audit 07 probe: reward parsing for every row in the section + core rules.

func _ready() -> void:
	await get_tree().process_frame
	U.clock_base = 1767600000.0   # Mon 2026-01-05 08:00 UTC
	Game.reset_save()
	Game.new_game("Audit07")
	var out: Array = []
	for r in Data.GDD.playerLevels:
		out.append(["PL%d" % r[0], r[2]])
	for p in Data.GDD.jobs:
		for j in Data.GDD.jobs[p]:
			out.append(["JOB-" + p, j[1]])
	for c in Data.GDD.ambitions:
		for a in Data.GDD.ambitions[c]:
			out.append(["AMB-%s-%d-%d" % [c, a[0], a[1]], a[3]])
	var i := 0
	for l in Data.GDD.login:
		i += 1
		out.append(["LOGIN%d" % i, l])
	for o in out:
		print("PARSE\t%s\t%s\t%s" % [o[0], o[1], JSON.stringify(U.parse_rewards(o[1]))])
	# ambition progress per row (fresh account)
	for c in Data.GDD.ambitions:
		for a in Data.GDD.ambitions[c]:
			print("AMBPROG\t%s\t%s\t%s" % [c, a[2], str(Game.ambition_progress(c, a[2]))])
	for c in Data.GDD.ambitions:
		print("AMBLIST\t%s\tvisible=%d" % [c, Game.ambitions_list(c).size()])
	# player level: XP and rewards
	Game.S.cur.energy = 10
	var mail0: int = Game.S.inbox.size()
	Game.add_pxp(100)
	print("PXP lvl=%d xp=%d energy=%d mail=%s" % [Game.S.player.level, Game.S.player.xp, Game.cur("energy"), JSON.stringify(Game.S.inbox[Game.S.inbox.size()-1].rewards if Game.S.inbox.size() > mail0 else [])])
	var e0: int = Game.cur("energy")
	var x0: int = Game.S.player.xp
	Game.spend("energy", 8)
	print("SPEND8 pxp delta=%d" % (Game.S.player.xp - x0))
	# run to max
	Game.add_pxp(10000000)
	print("PXPMAX lvl=%d maxed=%s" % [Game.S.player.level, str(Game.S.player.get("maxed", false))])
	var titles: Array = []
	for m in Game.S.inbox:
		if String(m.title).begins_with("Player Level") or String(m.title).begins_with("Max"):
			titles.append(m.title)
	print("LVLMAILS %d first=%s last=%s" % [titles.size(), titles[0], titles[titles.size()-1]])
	# last mail rewards (row 100)
	for m in Game.S.inbox:
		if m.title == "Max Player Level":
			print("ROW100 " + JSON.stringify(m.rewards))
	# pit loss / tiers
	for t in range(1, 14):
		print("PITLOSS t%d=%d" % [t, Data.pit_loss(t)])
	print("PITTIER 99=%d 100=%d 2999=%d 3000=%d" % [Game.pit_tier(99), Game.pit_tier(100), Game.pit_tier(2999), Game.pit_tier(3000)])
	# safehouse
	var w: Dictionary = Game.S.roster[0]
	var al: String = Game.tpl(w).align
	var s0 := Game.compute_stats(w)
	Game.S.safehouse[al] = {"hpP": 10, "armP": 10, "fpP": 10, "cd": 10, "hack": 10, "fw": 10}
	var s1 := Game.compute_stats(w)
	print("SAFE align=%s hp %d->%d arm %d->%d fp %d->%d cd %s->%s hack %d->%d fw %d->%d" % [al, s0.hp, s1.hp, s0.arm, s1.arm, s0.fp, s1.fp, str(s0.cd), str(s1.cd), s0.hack, s1.hack, s0.fw, s1.fw])
	Game.S.safehouse[al] = {}
	Game.S.cur.pitCoin = 100000
	var spent := 0
	for k in 10:
		var pc0: int = Game.cur("pitCoin")
		Game.safehouse_upgrade("neutral", "hack")
		spent += pc0 - Game.cur("pitCoin")
	print("SAFECOST total=%d lv=%d err11=%s" % [spent, Game.safehouse_level("neutral", "hack"), Game.safehouse_upgrade("neutral", "hack")])
	# login: miss days, no reset
	Game.S.login.progress = 0
	var a := Game.claim_login()
	U.time_offset += 86400.0 * 5
	Game.tick()
	print("LOGIN after miss progress=%d claimed=%s idx=%d" % [Game.S.login.progress, str(Game.S.login.claimed), Game.login_index()])
	Game.S.login.progress = 30
	Game.S.login.claimed = false
	var r31 := Game.claim_login()
	print("LOGIN31 " + JSON.stringify(r31) + " next idx=%d" % Game.login_index())
	# jobs: complete-all daily
	U.time_offset += 86400.0
	Game.tick()
	for ev in ["pitBrawl", "den", "plazaBuy", "recruit", "equip8", "warlordLevel", "hideoutEquip"]:
		Game.track(ev, 400)
	var n := 0
	for j in Game.jobs_list("daily"):
		if j.i < 7:
			n += 1
			Game.claim_job("daily", j.i)
	var all_d: Dictionary = Game.jobs_list("daily")[7]
	print("JOBALL daily cur=%d target=%d" % [all_d.cur, all_d.target])
	Game.claim_job("daily", 7)
	print("JOBWEEK dailyAll=%s" % str(Game.jobs_list("weekly")[0].cur))
	# currencies after daily refresh
	Game.S.cur.heist = 0
	Game.S.cur.bounty = 0
	Game.S.cur.brawl = 0
	Game.S.cur.energy = 0
	Game.S.cur.energy_t = U.now()
	U.time_offset += 86400.0
	Game.tick()
	print("DAILY heist=%d bounty=%d brawl=%d royal=%d energy=%d" % [Game.cur("heist"), Game.cur("bounty"), Game.cur("brawl"), Game.cur("royal"), Game.cur("energy")])
	# contracts / scrap
	var ok := true
	for rar in ["common", "uncommon", "rare", "epic", "legendary"]:
		print("BYRAR %s=%d" % [rar, Warlords.by_rarity(rar).size()])
	# recruited counter at start
	Game.reset_save()
	Game.new_game("Audit07b")
	print("START recruited=%d consumed=%d roster=%d" % [Game.stat("recruited"), Game.stat("consumed"), Game.S.roster.size()])
	print("START amb Recruit25=%s" % str(Game.ambition_progress("Warlord", "Recruit 25 Warlords")))
	print("START amb Rank10toR2=%s" % str(Game.ambition_progress("Warlord", "Rank 10 Warlords to Rank 2")))
	Game.reset_save()
	print("PROBE DONE")
	get_tree().quit(0)
