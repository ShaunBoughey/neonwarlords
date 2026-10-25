extends Node
## Review 15 (Monetization): parses every shop / battle pass reward and simulates purchases.

func _ready() -> void:
	Game.reset_save(); Game.new_game("Probe15"); Game._check_bp()
	Game.S.tutorial_done = true
	print("=== SHOP PARSE")
	for sec in Data.GDD.shop:
		for row in Data.GDD.shop[sec]:
			var rs := U.parse_rewards(String(row[1]))
			var bad := rs.filter(func(r): return r.k == "unknown")
			print("%s | %s | %s -> %s %s" % [sec, row[0], row[2], U.rewards_text(rs), ("  !!UNKNOWN" if not bad.is_empty() else "")])
	print("=== BP PARSE")
	for row in Data.GDD.battlePass:
		for col in [1, 2]:
			var t := String(row[col])
			if t == "": continue
			var rs := U.parse_rewards(t)
			var lbl := U.rewards_text(rs)
			var flag := ""
			if rs.any(func(r): return r.k == "unknown"): flag = "  !!UNKNOWN"
			if t.begins_with("10%") and rs[0].k != "xpBoostMinor": flag += "  !!10%->" + rs[0].k
			print("Lv%d %s: %s -> %s%s" % [row[0], "paid" if col == 2 else "free", t, lbl, flag])
	print("=== PURCHASES")
	Game.S.settings.free_iap = true
	for sec in Data.GDD.shop:
		var rows: Array = Data.GDD.shop[sec]
		for i in rows.size():
			var row: Array = rows[i]
			var lim = row[3]
			var tries := (int(lim) + 1) if typeof(lim) != TYPE_STRING else 2
			var got := 0
			for t in tries:
				Game.S.cur.trinium = 100000
				var tb := Game.cur("trinium")
				var out := Game.shop_buy(sec, i)
				if not out.is_empty():
					got += 1
					if t == 0 and String(row[2]).ends_with("Trinium"):
						var spent := tb - Game.cur("trinium")
						if spent != int(String(row[2]).split(" ")[0]):
							print("  !!cost mismatch %s spent %d" % [row[0], spent])
			print("%s: bought %d of %d tries (limit %s)" % [row[0], got, tries, str(lim)])
	# deeds check
	print("paragon deeds minor/major/grand: %d %d %d" % [Game.item_count(["deeds", "paragon", "minor"]), Game.item_count(["deeds", "paragon", "major"]), Game.item_count(["deeds", "paragon", "grand"])])
	# IAP off
	Game.reset_save(); Game.new_game("Probe15"); Game._check_bp()
	Game.S.settings.free_iap = false
	print("IAP off pack ->", Game.shop_buy("Packs", 0).size(), " trinium buy ->", (func(): Game.S.cur.trinium = 100; return Game.shop_buy("Credit Bank", 0).size()).call())
	print("double off ->", Game.buy_double_rewards(), " | premium off ->", Game.bp_buy_premium(false))
	print("=== DOUBLE REWARDS")
	Game.reset_save(); Game.new_game("Probe15"); Game._check_bp()
	Game.S.settings.free_iap = true
	var m0: int = Game.S.mail.size() if Game.S.has("mail") else -1
	Game.add_pxp(Game.pxp_needed())
	var single = Game.S.inbox[0].rewards if not Game.S.inbox.is_empty() else null
	print("buy double:", Game.buy_double_rewards(), " again:", Game.buy_double_rewards())
	Game.add_pxp(Game.pxp_needed())
	var dbl = Game.S.inbox[0].rewards if not Game.S.inbox.is_empty() else null
	print("lv mail single:", JSON.stringify(single))
	print("lv mail double:", JSON.stringify(dbl))
	print("=== BATTLE PASS")
	Game.reset_save(); Game.new_game("Probe15"); Game._check_bp()
	Game.S.settings.free_iap = true
	print("season info:", Game.bp_season_info(), " level at start:", Game.bp_level())
	print("daily ids:", Game.S.bp.daily, " weekly ids:", Game.S.bp.weekly)
	print("claim lv1 free at lvl0 ->", Game.bp_claim(1, false).size())
	Game.bp_add_merits(20)
	print("lvl after 20 merits:", Game.bp_level(), " claim free lv1 ->", Game.bp_claim(1, false).size(), " again ->", Game.bp_claim(1, false).size(), " paid w/o premium ->", Game.bp_claim(1, true).size())
	for c in Game.bp_challenges(false):
		Game.track(Data.BP_DAILY.filter(func(d): return d.id == c.id)[0].ev, c.target)
	var m1 := int(Game.S.bp.merits)
	for c in Game.bp_challenges(false):
		Game.bp_claim_challenge(false, c.id)
	print("daily merits gained:", int(Game.S.bp.merits) - m1, " (expect 100)")
	for c in Game.bp_challenges(true):
		Game.track(Data.BP_WEEKLY.filter(func(d): return d.id == c.id)[0].ev, c.target)
	m1 = int(Game.S.bp.merits)
	for c in Game.bp_challenges(true):
		Game.bp_claim_challenge(true, c.id)
	print("weekly merits gained:", int(Game.S.bp.merits) - m1, " (expect 100)")
	print("buy premium+25:", Game.bp_buy_premium(true), " lvl:", Game.bp_level(), " premium:", Game.S.bp.premium)
	print("paid lv1 ->", Game.bp_claim(1, true), " lv25 free ->", Game.bp_claim(25, false))
	print("has reset-weekly func:", Game.has_method("bp_reset_challenge") or Game.has_method("bp_reroll"))
	Game.S.bp.merits = 100000
	print("lvl cap:", Game.bp_level())
	var n_claim := 0
	for lv in range(1, 101):
		for paid in [false, true]:
			if not Game.bp_claim(lv, paid).is_empty(): n_claim += 1
	print("claimable after full: ", n_claim, " xpBoost:", Game.item_count(["xpBoost"]), " xpBoostMinor:", Game.item_count(["xpBoostMinor"]))
	get_tree().quit()
