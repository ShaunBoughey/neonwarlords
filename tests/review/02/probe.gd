extends Node
## Section 02 logic probe: neuronet rules/costs, ability rules, template audit.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
	print(("OK   " if c else "FAIL ") + m)

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Probe")
	# ---- neuronet table
	var gdd_cost := [null, [1, 50], [1, 100], [2, 150], [2, 200], [3, 250], [3, 300], [3, 350]]
	for l in range(1, 8):
		check(Data.NN_COST[l] == gdd_cost[l], "NN cost layer %d = %s" % [l, str(Data.NN_COST[l])])
	var n := 0
	for car in Data.NN_CAREERS:
		check(Data.NEURONET[car].size() == 7, car + " has 7 layers")
		for layer in Data.NEURONET[car]:
			check(layer.size() == 2, "2 skills per layer")
			n += layer.size()
	check(n == 42, "42 skills")
	# ---- rules
	Game.add_warlord("brother_grin", true)
	var w: Dictionary = Game.S.roster[-1]
	Game.add_item(["mf", 1], 100000); Game.add_item(["mf", 2], 100000); Game.add_item(["mf", 3], 100000)
	var mf1 := Game.item_count(["mf", 1])
	check(Game.nn_add(w, "munitions") != "", "layer 2 locked before layer 1: " + Game.nn_can(w, "munitions"))
	check(Game.nn_add(w, "precision") == "", "add precision 1")
	check(mf1 - Game.item_count(["mf", 1]) == 50, "cost 50 T1")
	check(Game.nn_add(w, "blitz") != "", "1 of 2 per career: " + Game.nn_can(w, "blitz"))
	check(Game.nn_add(w, "precision") == "", "precision 2")
	check(Game.nn_add(w, "precision") != "", "max 2 points: " + Game.nn_can(w, "precision"))
	check(Game.nn_add(w, "plating") == "", "protection L1")
	check(Game.nn_add(w, "plating") == "", "protection L1 x2")
	check(Game.nn_add(w, "malware") != "", "layer cap 4: " + Game.nn_can(w, "malware"))
	var s0 := Game.compute_stats(w)
	var w2 := w.duplicate(true); w2.nn = {}
	var s1 := Game.compute_stats(w2)
	check(is_equal_approx(s0.cc - s1.cc, 10.0), "precision 2pt = +10 CC (%.1f)" % (s0.cc - s1.cc))
	print("  arm with/without plating: %s / %s" % [s0.arm, s1.arm])
	var before := Game.item_count(["mf", 1])
	Game.S.cur.trinium = 1000
	var rerr := Game.nn_reset(w)
	print("  reset: '%s' refund T1 %d" % [rerr, Game.item_count(["mf", 1]) - before])
	# ---- abilities
	Game.add_warlord("sister_cackle", true)
	var a: Dictionary = Game.S.roster[-1]
	Game.add_warlord("sister_cackle", true)
	var d: Dictionary = Game.S.roster[-1]
	var ab0 := (a.ab as Dictionary).duplicate()
	check(Game.feed_duplicate(a, d.uid, "gospel_glitch") == "", "feed dup")
	var tot := 0
	for k in a.ab: tot += int(a.ab[k]) - int(ab0[k])
	check(tot == 3, "dup = +3 levels total (%d) %s" % [tot, str(a.ab)])
	Game.add_item(["stimm", "rare"], 2)
	Game.add_warlord("pontiff_ruckus", true)
	var e: Dictionary = Game.S.roster[-1]
	check(Game.use_stimm(e, "benediction", "rare") != "", "epic needs >= epic stimm")
	Game.add_item(["stimm", "epic"], 1)
	check(Game.use_stimm(e, "benediction", "epic") == "", "epic stimm on epic +1")
	check(int(e.ab.benediction) == 2, "level 2")
	# ---- template audit
	for id in Warlords.T:
		var t: Dictionary = Warlords.T[id]
		var c := {"active": 0, "passive": 0, "leader": 0, "reinforce": 0}
		for ab in t.abilities: c[ab.type] += 1
		var acts: Array = t.abilities.filter(func(x): return x.type == "active")
		var probs := []
		if c.active > 3: probs.append("actives %d>3" % c.active)
		if c.leader > 1: probs.append("leaders %d" % c.leader)
		if c.reinforce > 2: probs.append("reinforce %d" % c.reinforce)
		if acts.is_empty(): probs.append("no active")
		elif int(acts[0].cd) != 0: probs.append("A1 cd %d" % acts[0].cd)
		for i in range(1, acts.size()):
			if int(acts[i].cd) <= 0 and not acts[i].get("auto", false): probs.append("A%d cd 0" % (i + 1))
		for ab in acts:
			if float(ab.mult) <= 0.0 and (ab.fx as Array).is_empty() and not ab.has("special"): probs.append(ab.id + " does nothing")
			var desc: String = ab.desc
			if desc.begins_with("Attack") and float(ab.mult) <= 0.0: probs.append(ab.id + " says Attack but mult 0")
			if not desc.begins_with("Attack") and float(ab.mult) > 0.0 and not desc.contains("ttack"): probs.append(ab.id + " deals dmg but desc has no attack")
		print("TPL %s [%s %s%s] A%d P%d L%d R%d %s" % [id, t.rarity, t.cls, " enemy" if t.get("enemy_only", false) else "", c.active, c.passive, c.leader, c.reinforce, ("PROB: " + ", ".join(probs)) if probs.size() else ""])
	print("PROBE DONE fails: %d" % fails)
	get_tree().quit()
