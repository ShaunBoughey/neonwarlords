extends Node
## Section 10 logic probe (headless): Pit points/brackets/defence/invites, caches, Black Market.

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Probe")
	Game.S.tutorial_done = true
	print("== BM parse")
	for r in Data.GDD.blackMarket:
		print("  ", r[0], " -> ", U.rewards_text(U.parse_rewards(r[0])), " | ", r[1], " ", r[2])
	print("== cache parse")
	for c in ["Meager Cache", "Substantial Cache", "Sublime Cache", "Exalted Cache"]:
		for row in Data.GDD.caches[c]:
			print("  ", c, ": ", row[0], " (", row[1], ") -> ", U.rewards_text(U.parse_rewards(row[0])))
	print("== tier boundaries")
	for pts in [0, 99, 100, 199, 200, 599, 600, 2999, 3000, 9000]:
		print("  ", pts, " -> ", Game.pit_tier(pts), " ", Game.pit_tier_row(pts)[1])
	print("== pit_record")
	var opp := {"id": "x", "name": "Tester"}
	for pts in [100, 600, 1500, 3000]:
		Game.S.pit.brawl.points = pts
		var pc := Game.cur("pitCoin"); var cr := Game.cur("credits")
		Game.pit_record("brawl", true, opp)
		print("  win at %d -> pts %d, +%d credits, +%d PC" % [pts, Game.S.pit.brawl.points, Game.cur("credits") - cr, Game.cur("pitCoin") - pc])
	Game.S.pit.brawl.points = 500
	Game.pit_record("brawl", false, opp)
	print("  loss at 500 -> pts ", Game.S.pit.brawl.points, " log: ", Game.S.pit.brawl.log[0].txt)
	print("== defence sim")
	for mode in ["brawl", "royal"]:
		print("  squad ", mode, " size ", Game.S.squads["pit_" + mode].size())
	var lost := 0; var held := 0; var drop := 0
	for trial in 10:
		Game.S.pit.brawl.points = 1000
		Game.S.pit.brawl.log = []
		Game.S.pit.last_def = U.now() - 3600.0 * 16.0
		Game.S.pit.brawl.opps = []
		Game._simulate_pit_defense()
		for e in Game.S.pit.brawl.log:
			if e.win: held += 1
			else: lost += 1
		drop += 1000 - int(Game.S.pit.brawl.points)
	print("  10x16h: defence held %d, lost %d, total pts lost %d (loss per = %d)" % [held, lost, drop, Data.pit_loss(7)])
	print("== invites")
	Game.S.cur.brawl = 3; Game.S.day = -1; Game.tick()
	print("  daily refill from 3 -> ", Game.cur("brawl"))
	Game.S.cur.brawl = 15; Game.S.day = -1; Game.tick()
	print("  daily refill from 15 -> ", Game.cur("brawl"))
	Game.grant(U.parse_rewards("10x Pit Brawl Invites"))
	print("  after +10 refill item -> ", Game.cur("brawl"), " (cap ", Data.PIT_CAP, ")")
	print("== weekly")
	var before: int = Game.S.inbox.size() if Game.S.has("inbox") else -1
	Game.S.pit.brawl.points = 1500
	Game.S.week = -1; Game.tick()
	var after: int = Game.S.inbox.size() if Game.S.has("inbox") else -1
	print("  inbox %d -> %d; brawl pts after weekly %d" % [before, after, Game.S.pit.brawl.points])
	if Game.S.has("inbox"):
		for m in Game.S.inbox.slice(0, 3):
			print("   mail: ", m.title, " | ", U.rewards_text(m.rewards))
	# targeted counts
	for c in ["Meager Cache", "Exalted Cache"]:
		var n_contract := 0; var n_stimm := 0; var n_cache := 0; var cr_min := 1e12; var cr_max := 0.0; var gear_r := {}; var gear_rk := {}
		var N := 400
		for i in N:
			Game.add_item(["cache", c], 1)
			var eq0: int = Game.S.equip.size()
			var cr0 := Game.cur("credits")
			var res := Game.open_cache(c)
			var dc := Game.cur("credits") - cr0
			cr_min = min(cr_min, dc); cr_max = max(cr_max, dc)
			for r in res:
				var l := String(r.label)
				if l.contains("Contract"): n_contract += 1
				if l.contains("Stimm"): n_stimm += 1
				if l.contains("Cache"): n_cache += 1
			for it in Game.S.equip.slice(eq0):
				gear_r[it.rarity] = int(gear_r.get(it.rarity, 0)) + 1
				gear_rk[it.rank] = int(gear_rk.get(it.rank, 0)) + 1
		print("  %s x%d: contract %.0f%%, stimm %.0f%%, cache %.0f%%, credits %d..%d, gear rarity %s rank %s" % [c, N, 100.0 * n_contract / N, 100.0 * n_stimm / N, 100.0 * n_cache / N, cr_min, cr_max, gear_r, gear_rk])
	print("== black market")
	Game.S.cur.pitCoin = 200000
	for i in Data.GDD.blackMarket.size():
		var pc := Game.cur("pitCoin")
		var res := Game.bm_buy(i)
		var res2 := Game.bm_buy(i)
		print("  [%d] %s: paid %d, got %s | 2nd buy: %s (%s)" % [i, Data.GDD.blackMarket[i][0], pc - Game.cur("pitCoin") - (int(Data.GDD.blackMarket[i][1]) if not res2.is_empty() else 0), U.rewards_text(res) if res.size() and res[0].has("k") else str(res.map(func(r): return r.get("label", r))), "ok" if not res2.is_empty() else "blocked", Game.bm_can_buy(i)])
	print("  energy now ", Game.cur("energy"), " cap ", Data.ENERGY_CAP)
	print("PROBE DONE")
	get_tree().quit()
