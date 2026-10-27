extends Node
## Audit 02 probe: targeted neuronet / combat checks. Read-only for game code.

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Audit02")
	nn_rules()
	combat()
	print("PROBE02 DONE")
	get_tree().quit(0)

func P(s): print("P02 " + str(s))

func mkw(id: String, nn := {}) -> Dictionary:
	var w: Dictionary = Game.add_warlord(id, true)
	w.nn = nn
	return w

func nn_rules() -> void:
	var w := mkw("scrapjaw")
	P("mf counts t1/t2/t3: %d %d %d" % [Game.item_count(["mf", 1]), Game.item_count(["mf", 2]), Game.item_count(["mf", 3])])
	Game.add_item(["mf", 1], 100000); Game.add_item(["mf", 2], 100000); Game.add_item(["mf", 3], 100000)
	P("layer2 before layer1: " + Game.nn_can(w, "munitions"))
	P("add precision: '" + Game.nn_add(w, "precision") + "'")
	P("pair rule blitz: " + Game.nn_can(w, "blitz"))
	Game.nn_add(w, "precision")
	P("precision 3rd: " + Game.nn_can(w, "precision"))
	Game.nn_add(w, "plating"); Game.nn_add(w, "plating")
	P("5th point layer1: " + Game.nn_can(w, "malware"))
	var before := Game.item_count(["mf", 3])
	for id in ["munitions", "munitions", "egocentric", "egocentric", "essenceShield", "essenceShield", "guardian", "guardian", "bloodFrenzy", "bloodFrenzy", "parry", "parry", "openOpp", "openOpp", "galvanized"]:
		var e := Game.nn_add(w, id)
		if e != "": P("add %s err %s" % [id, e])
	P("t3 spent for 3 L5 points: %d (expect 750)" % (before - Game.item_count(["mf", 3])))
	P("siphon max: %d wrath max: %d" % [Data.NN_BY_ID.siphon.max, Data.NN_BY_ID.wrath.max])

func two(a_nn: Dictionary, b_nn: Dictionary, seed := 1) -> Battle:
	var b := Battle.new()
	var a := Battle.make_unit(mkw("scrapjaw", a_nn), 0)
	var a2 := Battle.make_unit(mkw("brother_grin"), 0)
	var e := Battle.make_unit(mkw("scrapjaw", b_nn), 1)
	var e2 := Battle.make_unit(mkw("brother_grin"), 1)
	b.setup([a, a2], [[e, e2]], {"seed": seed})
	b.start()
	return b

func combat() -> void:
	# Adaptive Networks: target resists (hack < fw) - does it heal?
	var b := two({}, {"adaptive": 2})
	var src: Dictionary = b.units[0]; var tgt: Dictionary = b.units[2]
	src.base.hack = 0; tgt.base.fw = 100; tgt.hp = tgt.max_hp * 0.5
	var hp0: float = tgt.hp
	b._place_debuff(src, tgt, {"id": "armDown", "turns": 2, "chance": 100, "l": 0}, {})
	P("adaptive on resist healed: %s (debuff landed %s)" % [tgt.hp > hp0, b.has_debuff(tgt, "armDown")])
	# block debuffs + hacking too low: GDD order says hack check first (resist), code says block
	tgt.buffs.append({"id": "blockDebuffs", "v": 0, "turns": 2, "src": tgt.uid})
	b.take_events()
	b._place_debuff(src, tgt, {"id": "armDown", "turns": 2, "chance": 100, "l": 0}, {})
	P("blocked+lowhack event: %s" % str(b.take_events().map(func(x): return x.e)))
	P("adaptive on block healed: %s" % (tgt.hp > hp0))
	# fwDown skips check
	tgt.buffs.clear()
	b._place_debuff(src, tgt, {"id": "fwDown", "turns": 2, "chance": 100, "l": 1}, {})
	P("fwDown lands with hack0<fw: %s, fw now %.0f" % [b.has_debuff(tgt, "fwDown"), b.eff(tgt, "fw")])
	# stupefy hacking -50
	src.base.hack = 500
	b._place_debuff(src, tgt, {"id": "stupefy", "turns": 2, "chance": 100, "l": 0}, {})
	tgt.base.hack = 80
	P("stupefy hack 80 -> %.0f" % b.eff(tgt, "hack"))
	# mark target x2, consumed
	tgt.debuffs.clear(); tgt.buffs.clear()
	var ab: Dictionary = b.basic(src)
	var r1 := []; var r2 := []
	for i in 200:
		tgt.hp = tgt.max_hp * 10; tgt.max_hp = tgt.hp; tgt.first_hit = false
		r1.append(b._attack(src, tgt, ab, {"crit": false, "kill": false, "hit": {}}, true))
		tgt.debuffs.append({"id": "mark", "v": 2.0, "turns": 2, "src": src.uid})
		r2.append(b._attack(src, tgt, ab, {"crit": false, "kill": false, "hit": {}}, true))
	P("mark ratio avg: %.2f (crit noise), mark left %s" % [avg(r2) / avg(r1), b.has_debuff(tgt, "mark")])
	# Bleed spread via DDoS: hit stored
	var b2 := two({"ddos": 2}, {})
	var s2: Dictionary = b2.units[0]; s2.base.hack = 999; s2.nn["ddos"] = 2
	var t2a: Dictionary = b2.units[2]; var t2b: Dictionary = b2.units[3]
	var spread := 0
	for i in 60:
		t2a.debuffs.clear(); t2b.debuffs.clear()
		b2._place_debuff(s2, t2a, {"id": "bleed", "turns": 2, "chance": 100, "l": 1}, {"hit": {t2a.uid: 10000.0}})
		for d in t2b.debuffs:
			if d.id == "bleed":
				spread += 1
				if i < 60 and spread == 1: P("spread bleed hit basis: %s" % d.hit)
	P("ddos 20%% spread count/60: %d" % spread)
	# Guardian angel
	var b3 := two({}, {})
	var g: Dictionary = b3.units[1]; g.nn["guardian"] = 2
	var t3: Dictionary = b3.units[0]
	var gh: float = g.hp
	b3._deal(b3.units[2], t3, 1000.0, false)
	P("guardian took %.0f of 1000" % (gh - g.hp))
	# Prepared defense
	var b4 := two({}, {"prepared": 2})
	var a4: Dictionary = b4.units[0]; var d4: Dictionary = b4.units[2]
	var x1 := []; var x2 := []
	for i in 200:
		d4.first_hit = true; d4.hp = 1e9; d4.max_hp = 1e9
		x1.append(b4._attack(a4, d4, b4.basic(a4), {"crit": false, "kill": false, "hit": {}}, true))
		x2.append(b4._attack(a4, d4, b4.basic(a4), {"crit": false, "kill": false, "hit": {}}, true))
	P("prepared first/second ratio: %.2f (expect ~0.80)" % (avg(x1) / avg(x2)))
	# Foresight overshield
	var b5 := two({"foresight": 2}, {})
	P("foresight shields ally: %.0f vs 10%% max hp %.0f" % [b5.total_shield(b5.units[1]), b5.units[0].max_hp * 0.1])
	# Formations
	var w6 := mkw("brother_grin"); var w7 := mkw("scrapjaw", {"formations": 2})
	var u6 := Battle.make_unit(w6, 0); var u7 := Battle.make_unit(w7, 0)
	var arm6: float = u6.base.arm
	var b6 := Battle.new(); b6.setup([u6, u7], [[Battle.make_unit(mkw("scrapjaw"), 1)]], {"seed": 3}); b6.start()
	P("formations ally arm %.0f -> %.0f (+10%% of %.0f)" % [arm6, u6.base.arm, u7.base.arm])
	# Turn meter pause: extra turn keeps others
	# Compute-stats neuronet stacking: plating 10% + gear pct
	var w8 := mkw("scrapjaw"); var s0: float = Game.compute_stats(w8).arm
	w8.nn = {"plating": 2, "galvanized": 2}
	P("armour nn 30%%: %.0f -> %.0f (x%.3f)" % [s0, Game.compute_stats(w8).arm, Game.compute_stats(w8).arm / s0])
	# Adware/personal ads
	var b9 := two({"adware": 1}, {})
	var s9: Dictionary = b9.units[0]; s9.base.hack = 999; var t9: Dictionary = b9.units[2]
	var ext := 0
	for i in 400:
		t9.debuffs.clear(); t9.immune.clear()
		b9._place_debuff(s9, t9, {"id": "armDown", "turns": 2, "chance": 100, "l": 0}, {})
		if not t9.debuffs.is_empty() and t9.debuffs[0].turns == 3: ext += 1
	P("adware extra-turn rate %.0f%% (expect 35)" % (ext / 4.0))
	# Siphon Essence at 30%%
	var b10 := two({"siphon": 1}, {})
	var s10: Dictionary = b10.units[0]; s10.hp = s10.max_hp * 0.2; var h10: float = s10.hp
	var t10: Dictionary = b10.units[2]; t10.hp = 1e9; t10.max_hp = 1e9
	var dd := b10._attack(s10, t10, b10.basic(s10), {"crit": false, "kill": false, "hit": {}}, true)
	P("siphon healed %.0f of dealt %.0f" % [s10.hp - h10, dd])
	# Medical learning
	var b11 := two({}, {"medLearning": 2})
	var e11: Dictionary = b11.units[2]; e11.hp = e11.max_hp * 0.5; var h11: float = e11.hp
	var a11: Dictionary = b11.units[0]; a11.hp = a11.max_hp * 0.5
	b11._heal(a11, a11, 1000.0, true)
	P("medLearning healed %.0f (expect 10%% of heal)" % (e11.hp - h11))

func avg(a: Array) -> float:
	var s := 0.0
	for x in a: s += float(x)
	return s / max(1, a.size())
