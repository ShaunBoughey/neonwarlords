extends Node
## Review 09: Syndicate Wars logic probe (headless).

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe09")
	Game.S.tutorial_done = true
	var fails := 0
	# 1. table: every stage cost + rank range
	for st in range(1, 21):
		var enc := Content.build_sw("vikings", st)
		var row: Dictionary = Data.GDD.syndicateWars[st - 1]
		print("stage %d cost=%s ranks=%s foe=%s lv=%d" % [st, enc.cost, row.ranks, enc.subtitle, enc.waves[0][0].level if enc.waves[0][0] is Dictionary and enc.waves[0][0].has("level") else -1])
	# 2. neon rank distribution, stage 1 and 20, 20000 rolls
	for st in [1, 6, 20]:
		var counts := {}
		var stats := {}
		var N := 20000
		for i in N:
			var r := Content.sw_rewards({"stage": st}, true)
			var ne: Dictionary = Game.S.neons.pop_back()
			counts[ne.rank] = counts.get(ne.rank, 0) + 1
			stats[ne.stat] = stats.get(ne.stat, 0) + 1
		var pct := {}
		for k in counts: pct[k] = snappedf(100.0 * counts[k] / N, 0.1)
		var spct := {}
		for k in stats: spct[k] = snappedf(100.0 * stats[k] / N, 0.1)
		print("stage %d neon rank %%: %s" % [st, pct])
		print("stage %d neon stat %%: %s" % [st, spct])
	var lr := Content.sw_rewards({"stage": 3}, false)
	print("loss reward items: ", lr.items.size(), " xp ", lr.xp)
	# 3. progression rewards parse
	for row in Data.GDD.swProgress:
		var parsed := U.parse_rewards(row[1])
		var bad := parsed.filter(func(p): return p.k == "unknown")
		print("prog %s '%s' -> %s %s" % [row[0], row[1], parsed, "UNKNOWN!" if bad.size() > 0 or parsed.is_empty() else ""])
		if bad.size() > 0 or parsed.is_empty(): fails += 1
	# 4. claim flow
	print("claim with 0 stars: ", Game.claim_sw_progress(15))
	for st in range(1, 6): Game.sw_record("vikings", st, 3)
	print("total stars ", Game.sw_total_stars())
	var got := Game.claim_sw_progress(15)
	print("claim 15: ", got.map(func(x): return x.label))
	print("claim 15 again: ", Game.claim_sw_progress(15))
	Game.sw_record("vikings", 1, 1)
	print("record lower keeps max: ", Game.sw_stars("vikings", 1))
	# legendary + gear set claims
	for s in Data.SYNDICATES:
		for st in range(1, 21): Game.sw_record(s, st, 3)
	print("max total stars (all syndicates) ", Game.sw_total_stars())
	for thr in [150, 195, 360]:
		print("claim %d: %s" % [thr, Game.claim_sw_progress(thr).map(func(x): return x.label)])
	# 5. bounty tokens
	Game.S.cur.bounty = 12
	Game.add_cur("bounty", 5)
	print("bounty cap after +5: ", Game.cur("bounty"))
	print("pay stage 20 x3: ", Game.pay({"bounty": 4}), Game.pay({"bounty": 4}), Game.pay({"bounty": 4}), " left ", Game.cur("bounty"))
	print("pay with 0: '", Game.pay({"bounty": 1}), "'")
	# 6. next_enc
	Game.S.sw.stars = {}
	print("next after unbeaten stage 1: ", Content.next_enc(Content.build_sw("trolls", 1)).is_empty())
	Game.sw_record("trolls", 1, 1)
	print("next after beaten stage 1: ", Content.next_enc(Content.build_sw("trolls", 1)).get("stage"))
	print("lock_syn ", Content.build_sw("trolls", 3).lock_syn, " chevron_turns ", Content.build_sw("trolls", 3).chevron_turns)
	print("feature level sw ", Game.feature_level("sw"))
	print("PROBE09 fails: ", fails)
	get_tree().quit()
