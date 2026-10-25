extends Node
## Headless checks: run with  godot --headless --path . res://tests/TestRunner.tscn -- --nwtest

var fails := 0

func _ready() -> void:
	await get_tree().process_frame
	test_reward_parser()
	test_model()
	test_battles()
	print("TESTS DONE, failures: %d" % fails)
	get_tree().quit(1 if fails > 0 else 0)

func check(cond: bool, msg: String) -> void:
	if not cond:
		fails += 1
		print("FAIL: " + msg)

func test_reward_parser() -> void:
	var texts: Array = []
	for r in Data.GDD.playerLevels:
		texts.append(r[2])
	for p in Data.GDD.jobs:
		for j in Data.GDD.jobs[p]:
			texts.append(j[1])
	for c in Data.GDD.ambitions:
		for a in Data.GDD.ambitions[c]:
			texts.append(a[3])
	for b in Data.GDD.battlePass:
		texts.append(b[1])
		texts.append(b[2])
	for l in Data.GDD.login:
		texts.append(l)
	for r in Data.GDD.campaignProgress:
		texts.append_array([r[1], r[2], r[3]])
	for r in Data.GDD.swProgress:
		texts.append(r[1])
	for r in Data.GDD.blackMarket:
		texts.append(r[0])
	for sec in Data.GDD.shop:
		for r in Data.GDD.shop[sec]:
			texts.append(r[1])
	for r in Data.GDD.pitTiers:
		texts.append(r[3])
	for h in Data.GDD.heist:
		for r in h.rows:
			texts.append(r[0])
	for c in Data.GDD.caches:
		for r in Data.GDD.caches[c]:
			texts.append(r[0])
	var unknown := 0
	for t in texts:
		for r in U.parse_rewards(String(t)):
			if r.k == "unknown":
				unknown += 1
				print("  unparsed: '%s'  (in '%s')" % [r.text, t])
	print("reward strings: %d, unknown parts: %d" % [texts.size(), unknown])

func test_model() -> void:
	Game.reset_save()
	Game.new_game("Tester")
	check(Game.S.roster.size() == 5, "starter roster")
	Game.S.items.contract.rare = 20
	for i in 20:
		Game.open_contract("rare")
	check(Game.S.roster.size() == 25, "contracts open")
	var it := Game.gen_equipment("gear", 6, "legendary", "Speed", "boots")
	Game.S.cur.credits = 50000000
	for i in 20:
		Game.equip_level_up(it)
	check(it.level == 20 and it.subs.size() == 4, "equip leveling")
	var w: Dictionary = Game.S.roster[0]
	check(Game.equip_on(w, it) == "", "equip")
	print("speed with boots: %s" % Game.compute_stats(w).spd)
	Game.S.items.mf["1"] = 1000
	check(Game.nn_add(w, "precision") == "", "neuronet add")
	check(Game.nn_add(w, "blitz") != "", "neuronet pair exclusive")
	Game.add_wxp(w, 100000)
	check(w.level == Game.max_level(w), "xp to cap")
	var fodder: Array = Game.S.roster.filter(func(x): return x.rank == w.rank and x.uid != w.uid).map(func(x): return x.uid).slice(0, w.rank)
	Game.S.squads.pit_brawl = []
	Game.S.squads.pit_royal = []
	var err := Game.rank_up(w, fodder)
	print("rank up: '%s' rank now %d" % [err, w.rank])
	Game.S.items.deeds.generic.minor = 50
	for a in Data.ALIGNMENTS:
		Game.S.items.deeds[a].minor = 50
	print("rep up: '%s'" % Game.rep_up(w))
	Game.add_pxp(5000)
	print("player level %d, inbox %d" % [Game.S.player.level, Game.S.inbox.size()])
	for m in Game.S.inbox:
		Game.claim_mail(m)
	for c in Game.S.items.cache.keys():
		Game.S.items.cache[c] = 1
		Game.open_cache(c)
	for p in ["daily", "weekly", "monthly"]:
		Game.jobs_list(p)
	for c in Data.GDD.ambitions:
		Game.ambitions_list(c)
	for i in Data.GDD.blackMarket.size():
		Game.S.cur.pitCoin = 100000
		Game.bm_buy(i)
	for sec in Data.GDD.shop:
		for i in Data.GDD.shop[sec].size():
			Game.S.cur.trinium = 100000
			Game.shop_buy(sec, i)
	Game.plaza_items()
	Game.plaza_buy(0)
	Game.claim_login()
	print("roster %d, equipment %d, neons %d" % [Game.S.roster.size(), Game.S.equip.size(), Game.S.neons.size()])

func strong_team(level: int, rank: int, gear_rank: int) -> Array:
	var ids := ["deacon_chainz", "raiden_x", "issac_vaun", "pontiff_ruckus", "redd_skullfire"]
	var out: Array = []
	for id in ids:
		var w := Game.add_warlord(id, true)
		w.level = level
		w.rank = rank
		w.rep = mini(rank, 6)
		for slot in Data.GEAR_SLOTS:
			var it := Game.add_equipment(Game.make_equipment(slot, gear_rank, "epic", "Speed" if slot in ["weapon", "helmet"] else "Firepower"))
			for i in mini(16, gear_rank * 3):
				Game.equip_level_up(it, true)
			Game.equip_on(w, it)
		out.append(w.uid)
	return out

func run(enc: Dictionary, team: Array, n: int) -> float:
	var wins := 0
	for i in n:
		var b := Battle.new()
		var waves: Array = []
		for wv in enc.waves:
			var arr: Array = []
			for u in wv:
				arr.append(u.duplicate(true))
			waves.append(arr)
		b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0), "seed": 1000 + i})
		if b.simulate() == "win":
			wins += 1
	return float(wins) / n

func test_battles() -> void:
	var fresh: Array = []
	for id in ["brother_grin", "scrapjaw", "intern7", "kage9", "abbot_mayhem"]:
		fresh.append(Game.add_warlord(id, true).uid)
	for st in [0, 3, 6]:
		print("campaign SP 1:%d starters win %.0f%%" % [st + 1, run(Content.build_campaign(0, 0, st), fresh, 20) * 100])
	print("campaign SP 2:1 starters win %.0f%%" % [run(Content.build_campaign(0, 1, 0), fresh, 20) * 100])
	# starters wear the welcome Health set + campaign-like rank 2 gear
	var gi := 0
	for slot in Data.GEAR_SLOTS:
		for u in fresh:
			var it := Game.add_equipment(Game.make_equipment(slot, 2, "uncommon", "Health"))
			Game.equip_on(Game.wl(u), it)
	for lv in [4, 6, 8, 12]:
		for u in fresh:
			Game.wl(u).level = mini(lv, Game.max_level(Game.wl(u)))
		print("starters lv%d: 1:7 %.0f%%  2:1 %.0f%%  2:7 %.0f%%  3:7 %.0f%%" % [lv, run(Content.build_campaign(0, 0, 6), fresh, 20) * 100, run(Content.build_campaign(0, 1, 0), fresh, 20) * 100, run(Content.build_campaign(0, 1, 6), fresh, 20) * 100, run(Content.build_campaign(0, 2, 6), fresh, 20) * 100])
	var mid := strong_team(30, 3, 3)
	var top := strong_team(60, 6, 6)
	for loc in [0, 4, 9]:
		for d in 3:
			print("campaign d%d loc%d st7: mid %.0f%%  top %.0f%%" % [d, loc + 1, run(Content.build_campaign(d, loc, 6), mid, 6) * 100, run(Content.build_campaign(d, loc, 6), top, 6) * 100])
	for id in Content.HIDEOUT_ORDER:
		var line := "hideout %-15s" % id
		for st in [1, 10, 20]:
			line += " s%d mid %3.0f%% top %3.0f%% |" % [st, run(Content.build_hideout(id, st), mid, 4) * 100, run(Content.build_hideout(id, st), top, 4) * 100]
		print(line)
	for st in [1, 10, 20]:
		print("SW stage %d: top %.0f%%" % [st, run(Content.build_sw("trolls", st), top, 4) * 100])
	for st in [1, 2, 3]:
		var b := Battle.new()
		var enc := Content.build_bastion(st)
		b.setup(Content.player_units(top), enc.waves, {"turn_limit": enc.turn_limit, "seed": 5})
		b.simulate()
		print("bastion %d: result %s damage %s" % [st, b.result, U.fmt(b.damage_to_side(1))])
	var opps := Content.pit_opponents("brawl")
	print("pit opponents %d, first power %d" % [opps.size(), opps[0].power])
	print("pit vs weakest: %.0f%%" % [run(Content.build_pit("brawl", opps[0]), top, 4) * 100])
	var enc2 := Content.build_campaign(0, 0, 0)
	print("campaign rewards: %s" % str(Content.campaign_rewards(enc2, true).items.map(func(x): return x.label)))
	for id in Content.HIDEOUT_ORDER:
		Game.S.cur.heist = 5
		print("  %s rewards: %s" % [id, str(Content.hideout_rewards(Content.build_hideout(id, 20), true).items.map(func(x): return x.label))])
	print("sw rewards: %s" % str(Content.sw_rewards(Content.build_sw("trolls", 20), true).items.map(func(x): return x.label)))
