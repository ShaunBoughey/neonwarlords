extends Node
## Review 06: headless logic probe for campaign rules.
##   NW_SAVE=06 godot --headless --path . res://tests/review/06/Probe.tscn -- --nwtest

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe06")
	print("== progression rewards parse")
	for row in Data.GDD.campaignProgress:
		for d in 3:
			var r: Array = U.parse_rewards(String(row[1 + d]))
			var labels := []
			for x in r:
				labels.append(U.reward_label(x) if x.k != "unknown" else "UNKNOWN:" + x.text)
			print("P %d d%d  '%s' -> %s  %s" % [int(row[0]), d, row[1 + d], labels, r])
	print("== enemy levels in built encounters")
	var bad := 0
	for d in 3:
		for loc in 10:
			for st in 7:
				var enc: Dictionary = Content.build_campaign(d, loc, st)
				var e: Array = Data.GDD.campaign[loc].stages[st].enemy[d]
				var units: Array = enc.waves[0]
				var lvls := []
				for u in units:
					lvls.append("%s L%d R%d rep%d%s" % [u.tpl, u.level, u.rank, u.rep, " BOSS" if u.boss else ""])
					if u.rank != mini(int(e[1]), 6) or u.rep != int(e[2]):
						bad += 1
				var lead = units[0]
				if lead.level != int(e[0]):
					bad += 1
					print("LEVEL MISMATCH %d %d:%d gdd=%s lead=%d" % [d, loc + 1, st + 1, e, lead.level])
				if st == 6 or (loc == 0 and st < 2) or loc == 9:
					print("E d%d %s energy=%d turns=%d n=%d : %s" % [d, enc.title, enc.energy, enc.chevron_turns, units.size(), lvls])
	print("enemy rank/rep/level mismatches: ", bad)
	print("== sets")
	for loc in 10:
		print("set loc%d %s -> %s" % [loc + 1, Data.GDD.campaign[loc].set, Content.campaign_set(loc)])
	var days := {}
	for i in 30:
		days[Data.SETS.keys()[(U.day_id() + i) % Data.SETS.size()]] = 1
	print("corpo rotation pool (30 days): ", days.keys())
	print("== unlocks")
	print("d0 1:1 ", Game.campaign_unlocked(0, 0, 0), " d0 1:2 ", Game.campaign_unlocked(0, 0, 1), " d1 1:1 ", Game.campaign_unlocked(1, 0, 0))
	for loc in 10:
		for st in 7:
			Game.campaign_record(0, loc, st, 3)
	print("after d0 clear: d1 1:1 ", Game.campaign_unlocked(1, 0, 0), " d2 1:1 ", Game.campaign_unlocked(2, 0, 0), " total stars d0=", Game.campaign_total_stars(0))
	print("claim 210 d0: ", Game.claim_campaign_progress(0, 210), " again: ", Game.claim_campaign_progress(0, 210))
	print("claim 15 d1 (0 stars): ", Game.claim_campaign_progress(1, 15))
	print("== drop rates (N=20000 per difficulty, stage 1:7)")
	for d in 3:
		var cnt := {}
		var N := 20000
		for i in N:
			var enc := {"mode": "campaign", "d": d, "loc": 0, "st": 6}
			var res: Dictionary = Content.campaign_rewards(enc, true)
			for it in res.items:
				var lab: String = String(it.get("label", "?"))
				var key := "credits" if lab.ends_with("Credits") else ("equip" if it.has("equip") else lab)
				cnt[key] = cnt.get(key, 0) + 1
			if i == 0:
				print("sample d%d: xp=%d items=%s" % [d, res.xp, res.items])
		var pct := {}
		for k in cnt:
			pct[k] = snappedf(100.0 * cnt[k] / N, 0.1)
		print("d%d %s" % [d, pct])
		print("loss xp d%d = %d" % [d, Content.campaign_rewards({"mode": "campaign", "d": d, "loc": 0, "st": 0}, false).xp])
	get_tree().quit()
