extends Node
## Audit 08: parse + grant every shop row and battle-pass reward, check limits and BP rules.

func _flat(d: Dictionary, pre: String, out: Dictionary) -> void:
	for k in d:
		if d[k] is Dictionary:
			_flat(d[k], pre + str(k) + ".", out)
		elif typeof(d[k]) in [TYPE_INT, TYPE_FLOAT]:
			out[pre + str(k)] = float(d[k])

func _snap() -> Dictionary:
	var o := {}
	_flat(Game.S.cur, "cur.", o)
	_flat(Game.S.items, "it.", o)
	o.erase("cur.energy_t")
	o["#equip"] = Game.S.equip.size()
	o["#neons"] = Game.S.neons.size()
	o["#roster"] = Game.S.roster.size()
	o["bp.merits"] = float(Game.S.bp.merits)
	return o

func _diff(a: Dictionary, b: Dictionary) -> String:
	var parts := []
	for k in b:
		var d = b[k] - a.get(k, 0.0)
		if d != 0:
			parts.append("%s%+d" % [k, int(d)])
	return ", ".join(parts)

func _equip_desc(n0: int) -> String:
	var m := {}
	for i in range(n0, Game.S.equip.size()):
		var it: Dictionary = Game.S.equip[i]
		var k := "%s R%d %s" % [it.kind, it.rank, it.rarity]
		m[k] = m.get(k, 0) + 1
	return str(m)

func _neon_desc(n0: int) -> String:
	var m := {}
	for i in range(n0, Game.S.neons.size()):
		var k := "R%d" % int(Game.S.neons[i].rank)
		m[k] = m.get(k, 0) + 1
	return str(m)

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Audit")
	Game.S.settings.free_iap = true
	Game.S.shop_bought = {}
	print("=== SHOP ===")
	for sec in Data.GDD.shop:
		var rows: Array = Data.GDD.shop[sec]
		for i in rows.size():
			var row: Array = rows[i]
			Game.S.cur.trinium = 100000
			Game.S.cur.heist = 0
			var a := _snap()
			var e0: int = Game.S.equip.size()
			var n0: int = Game.S.neons.size()
			var got := Game.shop_buy(sec, i)
			var b := _snap()
			b["cur.trinium"] += 0
			print("%s | %s | %s | lim=%s\n   parse: %s\n   delta: %s\n   equip: %s neons: %s" % [sec, row[0], row[1], str(row[3]), U.rewards_text(U.parse_rewards(row[1])) if not String(row[1]).contains("Minor") else "deeds special", _diff(a, b), _equip_desc(e0), _neon_desc(n0)])
			# limit check
			var lim = row[3]
			if typeof(lim) != TYPE_STRING:
				var buys := 1
				for t in 10:
					Game.S.cur.trinium = 100000
					if Game.shop_buy(sec, i).is_empty():
						break
					buys += 1
				var ui_key := "%s|%d" % [sec, i]
				print("   LIMIT: bought %d (limit %d); Game count=%d; shop.gd UI key count=%d" % [buys, int(lim), Game.shop_bought_count(sec, i), int(Game.S.shop_bought.get(ui_key, 0))])
	print("=== BATTLE PASS ===")
	var unk := 0
	for row in Data.GDD.battlePass:
		for c in [1, 2]:
			var t := String(row[c])
			if t == "":
				continue
			var rs := U.parse_rewards(t)
			var a := _snap()
			var e0: int = Game.S.equip.size()
			var n0: int = Game.S.neons.size()
			Game.grant(rs)
			var b := _snap()
			var ks := rs.map(func(r): return r.k)
			if "unknown" in ks: unk += 1
			print("BP %d %s | %s -> %s | %s %s %s" % [int(row[0]), "paid" if c == 2 else "free", t, U.rewards_text(rs), _diff(a, b), _equip_desc(e0) if Game.S.equip.size() > e0 else "", _neon_desc(n0) if Game.S.neons.size() > n0 else ""])
	print("BP unknown rows: %d, rows total: %d" % [unk, Data.GDD.battlePass.size()])
	# BP rules
	print("=== BP RULES ===")
	print("season info: ", Game.bp_season_info())
	Game.S.bp.premium = false
	Game.S.bp.merits = 30 * 20
	print("plus25 at lvl30 before:", Game.bp_level())
	Game.bp_buy_premium(true)
	print("plus25 at lvl30 after:", Game.bp_level(), " premium=", Game.S.bp.premium)
	Game.S.bp.merits = 0
	Game.bp_buy_premium(true)
	print("plus25 at lvl0 after:", Game.bp_level())
	print("daily:", Game.S.bp.daily, " weekly:", Game.S.bp.weekly)
	# weekly full completion value
	var tot := 4 * Data.BP_WEEKLY_MERITS + Data.BP_WEEKLY_BONUS
	var dtot := 5 * Data.BP_DAILY_MERITS + Data.BP_DAILY_BONUS
	print("weekly total %d, daily total %d; season max merits ~ %d (levels %d)" % [tot, dtot, 70 * dtot + 10 * tot, (70 * dtot + 10 * tot) / 20])
	# reroll twice
	var w0: String = Game.S.bp.weekly[0]
	Game.S.bp.wreroll = -1
	print("reroll1:'%s' reroll2:'%s'" % [Game.bp_reroll_weekly(w0), Game.bp_reroll_weekly(Game.S.bp.weekly[1])])
	# claim paid w/o premium
	Game.S.bp.premium = false
	Game.S.bp.claimed_paid = []
	Game.S.bp.merits = 2000
	print("paid claim w/o premium: ", Game.bp_claim(1, true))
	# den loss tracking
	print("PROBE DONE")
	get_tree().quit(0)
