extends Node
## Audit 04 probe: campaign data, rewards, drops, unlocks, progression claims.

func _ready() -> void:
	await get_tree().process_frame
	Game.new_game("Audit04")
	# progression reward parsing
	for r in Data.GDD.campaignProgress:
		for d in 3:
			var p: Array = U.parse_rewards(String(r[1 + d]))
			print("PROG %d d%d '%s' -> %s" % [int(r[0]), d, r[1 + d], str(p)])
	# energy + build every stage
	var bad := 0
	for d in 3:
		for l in 10:
			for s in 7:
				var e := Content.build_campaign(d, l, s)
				if int(Content.enc_cost(e).energy) != [4, 6, 8][d]: bad += 1
				var lv := int(e.waves[0][0].get("level", -1))
				if lv != int(Data.GDD.campaign[l].stages[s].enemy[d][0]): print("LVMISMATCH ", d, l, s, " ", lv)
	print("ENERGY_BAD ", bad)
	# drop count distribution per difficulty
	for d in 3:
		var hist := {}
		var credits_ok := true
		for i in 3000:
			var enc := Content.build_campaign(d, 2, 3)
			var before := Game.cur("credits")
			var r := Content.campaign_rewards(enc, true)
			var n: int = r.items.size() - 1
			hist[n] = int(hist.get(n, 0)) + 1
		print("DROPS d%d hist(extra items per win) %s" % [d, str(hist)])
		var lose := Content.campaign_rewards(Content.build_campaign(d, 2, 3), false)
		print("LOSE d%d xp %d items %d" % [d, lose.xp, lose.items.size()])
	# unlock chain
	print("UNLOCK d1 before ", Game.campaign_unlocked(1, 0, 0))
	for l in 10:
		for s in 7:
			Game.campaign_record(0, l, s, 3)
	print("UNLOCK d1 after ", Game.campaign_unlocked(1, 0, 0), " total d0 ", Game.campaign_total_stars(0))
	var got := Game.claim_campaign_progress(0, 75)
	print("CLAIM75 ", str(got))
	print("CLAIM75 again ", str(Game.claim_campaign_progress(0, 75)))
	print("CORPO set ", Content.campaign_set(9), " opts ", Data.SETS.size())
	print("PROBE DONE")
	get_tree().quit(0)
