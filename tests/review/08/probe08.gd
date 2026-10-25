extends Node
## Section 08 logic probe: parses every reward string, Monte-Carlo checks reward odds, costs and the Heist cap.
## NW_SAVE=08 godot --headless --path . res://tests/review/08/Probe08.tscn -- --nwtest

const N := 4000

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe08")
	_parse_checks()
	_cost_checks()
	_heist_cap()
	_synapse()
	_heist()
	_chop()
	_deeds()
	print("PROBE08 DONE")
	get_tree().quit()

func _parse_checks() -> void:
	for st in 20:
		for r in Data.GDD.heist[st].rows:
			var p := U.parse_rewards(String(r[0]))
			if p.size() != 1:
				print("PARSE-FAIL heist s%d '%s' -> %s" % [st + 1, r[0], p])
		for r in Data.GDD.deeds[st].rows:
			var t := String(r[0])
			if t.ends_with("Minor") or t.ends_with("Major") or t.ends_with("Grand"):
				continue
			var p2 := U.parse_rewards(t)
			if p2.size() != 1:
				print("PARSE-FAIL deeds s%d '%s' -> %s" % [st + 1, t, p2])
	print("heist s1 parse: ", U.parse_rewards("1xUC Contract"), U.parse_rewards("1,000,000 Credits"), " deeds: ", U.parse_rewards("1x Rare Contract"))

func _cost_checks() -> void:
	for id in ["synapse", "heist", "chopshop", "deeds_paragon", "deeds_neutral", "deeds_renegade", "deeds_generic"]:
		var line := ""
		for s in [1, 5, 6, 10, 11, 15, 16, 20]:
			line += " s%d=%s" % [s, Content.hideout_cost(id, s)]
		print("COST ", id, line)

func _heist_cap() -> void:
	print("HEIST start plans=", Game.cur("heist"))
	Game.add_cur("heist", 3)
	print("HEIST after +3 reward: ", Game.cur("heist"), " (cap 5)")
	var spent := 0
	for i in 7:
		if Game.pay(Content.hideout_cost("heist", 1)) == "":
			spent += 1
	print("HEIST paid entries from 5: ", spent, " now=", Game.cur("heist"), " can_pay err='", Game.can_pay({"heist": 1}), "'")
	Game.grant([{"k": "heist", "n": 10}])
	print("HEIST after grant 10: ", Game.cur("heist"))
	Game.S.cur.heist = 1
	Game.S.day = int(Game.S.day) - 1
	Game.tick()
	print("HEIST after daily reset from 1: ", Game.cur("heist"))
	Game.S.cur.heist = 5

func _enc(id: String, st: int) -> Dictionary:
	return {"id": id, "stage": st, "mode": "hideout"}

func _synapse() -> void:
	for st in [1, 4, 12, 14, 20]:
		var mn := {1: 99999, 2: 99999, 3: 99999}
		var mx := {1: -1, 2: -1, 3: -1}
		for i in N / 4:
			var before := {}
			for t in [1, 2, 3]: before[t] = Game.item_count(["mf", t])
			Content.hideout_rewards(_enc("synapse", st), true)
			for t in [1, 2, 3]:
				var d := Game.item_count(["mf", t]) - int(before[t])
				mn[t] = mini(mn[t], d); mx[t] = maxi(mx[t], d)
		print("SYNAPSE s%d T1 %d-%d T2 %d-%d T3 %d-%d   gdd %s" % [st, mn[1], mx[1], mn[2], mx[2], mn[3], mx[3], Data.GDD.synapse[st - 1].rows])

func _heist() -> void:
	for st in [1, 5, 11, 20]:
		var hits := {}
		for i in N:
			var c0 := Game.cur("credits")
			var uc0 := Game.item_count(["contract", "uncommon"])
			var r0 := Game.item_count(["contract", "rare"])
			Content.hideout_rewards(_enc("heist", st), true)
			var key := ""
			if Game.cur("credits") != c0: key = "%d Credits" % (Game.cur("credits") - c0)
			elif Game.item_count(["contract", "uncommon"]) != uc0: key = "%dxUC" % (Game.item_count(["contract", "uncommon"]) - uc0)
			elif Game.item_count(["contract", "rare"]) != r0: key = "%dxR" % (Game.item_count(["contract", "rare"]) - r0)
			else: key = "NOTHING"
			hits[key] = int(hits.get(key, 0)) + 1
		var parts: Array = []
		for k in hits: parts.append("%s %.1f%%" % [k, hits[k] * 100.0 / N])
		print("HEIST s%d: %s" % [st, ", ".join(parts)])

func _chop() -> void:
	for st in [1, 6, 10, 11, 20]:
		var ranks := {}; var rars := {}; var slots := {}; var cred := {}
		for i in N / 2:
			var c0 := Game.cur("credits")
			var res := Content.hideout_rewards(_enc("chopshop", st), true)
			cred[Game.cur("credits") - c0] = 1
			var uid = null
			for it in res.items:
				if it.has("equip"): uid = it.equip
			var e = null
			for x in Game.S.equip:
				if x.uid == uid: e = x
			if e == null:
				print("CHOP s%d no implant!" % st); continue
			if e.kind != "implant": print("CHOP s%d wrong kind %s" % [st, e.kind])
			ranks[e.rank] = int(ranks.get(e.rank, 0)) + 1
			rars[e.rarity] = int(rars.get(e.rarity, 0)) + 1
			slots[e.slot] = int(slots.get(e.slot, 0)) + 1
		Game.S.equip.clear()
		print("CHOP s%d credits %s ranks %s rar %s slots %s" % [st, cred.keys(), _pc(ranks, N / 2), _pc(rars, N / 2), _pc(slots, N / 2)])

func _pc(d: Dictionary, n: int) -> String:
	var parts: Array = []
	var ks := d.keys(); ks.sort()
	for k in ks: parts.append("%s %d%%" % [k, int(round(d[k] * 100.0 / n))])
	return ", ".join(parts)

func _deeds() -> void:
	for id in ["deeds_paragon", "deeds_generic"]:
		for st in [1, 4, 6, 10, 20]:
			var al: String = Content.HIDEOUTS[id].align
			var got := {"minor": 0, "major": 0, "grand": 0, "credits": 0, "rare": 0}
			var amt := {"minor": [999, 0], "major": [999, 0], "grand": [999, 0]}
			var credset := {}
			for i in N:
				var b := {}
				for t in ["minor", "major", "grand"]: b[t] = Game.item_count(["deeds", al, t])
				var c0 := Game.cur("credits"); var r0 := Game.item_count(["contract", "rare"])
				Content.hideout_rewards(_enc(id, st), true)
				for t in ["minor", "major", "grand"]:
					var d := Game.item_count(["deeds", al, t]) - int(b[t])
					if d > 0:
						got[t] += 1; amt[t][0] = mini(amt[t][0], d); amt[t][1] = maxi(amt[t][1], d)
				if Game.cur("credits") > c0: got.credits += 1; credset[Game.cur("credits") - c0] = 1
				if Game.item_count(["contract", "rare"]) > r0: got.rare += 1
			print("DEEDS %s s%d minor %.1f%% %s major %.1f%% %s grand %.1f%% %s credits %.0f%% %s rareC %.2f%%" % [id, st,
				got.minor * 100.0 / N, amt.minor, got.major * 100.0 / N, amt.major, got.grand * 100.0 / N, amt.grand, got.credits * 100.0 / N, credset.keys(), got.rare * 100.0 / N])
