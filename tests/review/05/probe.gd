extends Node
## GDD 05 combat probe (logic only): NW_SAVE=05 godot --headless --path . res://tests/review/05/Probe.tscn -- --nwtest

var b: Battle
var fails := 0

func ok(name: String, cond: bool, info := "") -> void:
	print(("PASS " if cond else "FAIL ") + name + ("  " + info if info != "" else ""))
	if not cond:
		fails += 1

func fresh() -> Array:
	var enc := Content.build_campaign(0, 0, 6)
	b = Battle.new()
	var a: Array = []
	for wv in enc.waves:
		var arr: Array = []
		for u in wv:
			arr.append(u.duplicate(true))
		a.append(arr)
	var allies: Array = []
	for u in a[0]:
		var c: Dictionary = u.duplicate(true)
		c.side = 0
		allies.append(c)
	b.setup(allies, [a[0]], {})
	for u in b.units:
		u.max_hp = float(u.base.hp)
		u.hp = u.max_hp
	return [b.side_units(0)[0], b.side_units(1)[0]]

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	# -------- typical armour values (to judge ARMOUR_K against the GDD example)
	for id in ["deacon_chainz", "hammer_of_four"]:
		if Warlords.get_t(id) == null:
			continue
		var w := Game.add_warlord(id, true)
		w.rank = 6
		for lv in [1, 30, 60]:
			w.level = lv
			var st := Game.compute_stats(w)
			print("STAT %s L%d R%d arm=%d fp=%d hp=%d hack=%d fw=%d spd=%d" % [id, lv, w.rank, st.arm, st.fp, st.hp, st.hack, st.fw, st.spd])
	var arm := 1518.0
	print("GDD example: armour 1518 -> code mitigation %.1f%% (GDD says 50%%)" % (100.0 * min(Battle.MAX_MITIGATION, arm / (arm + Battle.ARMOUR_K))))
	var arm2 := arm * 0.95
	print("GDD example with 5%% pen: code %.1f%% (GDD 45%%) -> 5437 dmg becomes %d (GDD 2990)" % [100.0 * arm2 / (arm2 + Battle.ARMOUR_K), int(5437 * (1.0 - arm2 / (arm2 + Battle.ARMOUR_K)))])

	# -------- buffs
	var p := fresh(); var x: Dictionary = p[0]; var e: Dictionary = p[1]
	var s0 := b.eff(x, "spd")
	b._place_buff(x, x, {"id": "spdUp", "turns": 2, "l": 0}, true)
	ok("Speed Up small +15%", is_equal_approx(b.eff(x, "spd"), s0 * 1.15))
	b._place_buff(x, x, {"id": "spdUp", "turns": 2, "l": 1}, true)
	ok("Speed Up large +30% (refresh keeps max, no stack)", is_equal_approx(b.eff(x, "spd"), s0 * 1.30))
	var h0 := b.eff(x, "hack")
	b._place_buff(x, x, {"id": "hackUp", "turns": 2, "l": 0}, true)
	ok("Hacking Up +40 flat", is_equal_approx(b.eff(x, "hack"), h0 + 40))
	var c0 := b.eff(x, "cc")
	b._place_buff(x, x, {"id": "ccUp", "turns": 2, "l": 1}, true)
	ok("Crit Chance Up +30", is_equal_approx(b.eff(x, "cc"), min(100.0, c0 + 30)))
	# continuous heal
	x.hp = x.max_hp * 0.5
	b._place_buff(x, x, {"id": "contHeal", "turns": 2, "l": 0}, true)
	var hp0: float = x.hp
	b._turn_start(x)
	ok("Continuous Heal 10% max HP at turn start", absf(x.hp - hp0 - round(x.max_hp * 0.10)) <= 1.0, "%d -> %d" % [hp0, x.hp])
	# block debuffs
	b._place_buff(e, e, {"id": "blockDebuffs", "turns": 2, "l": 0}, true)
	b._place_debuff(x, e, {"id": "armDown", "turns": 2, "chance": 100, "l": 0}, {})
	ok("Block Debuffs stops a debuff", not b.has_debuff(e, "armDown"))
	var tm0: float = e.tm
	x.base.hack = 9999.0
	b._tm(x, e, -30.0, false)
	print("INFO Block Debuffs vs Reduce Turn Meter: tm %.0f -> %.0f (%s)" % [tm0, e.tm, "blocked" if e.tm == tm0 else "NOT blocked"])
	# overshield, reflect, unkillable
	p = fresh(); x = p[0]; e = p[1]
	b._shield(x, e, 500.0, 2)
	var ehp: float = e.hp
	b._absorb_and_apply(x, e, 300.0, false)
	ok("Overshield absorbs damage", e.hp == ehp and is_equal_approx(b.total_shield(e), 200.0))
	b._place_buff(e, e, {"id": "unkillable", "turns": 2, "l": 0}, true)
	b._absorb_and_apply(x, e, e.hp + 99999.0, false)
	ok("Unkillable keeps 1 HP", e.alive and e.hp == 1.0)
	# -------- debuffs
	p = fresh(); x = p[0]; e = p[1]
	x.base.hack = 9999.0
	var a0 := b.eff(e, "arm")
	b._place_debuff(x, e, {"id": "armDown", "turns": 2, "chance": 100, "l": 1}, {})
	ok("Armour Down large -50%", is_equal_approx(b.eff(e, "arm"), a0 * 0.5))
	var fw0 := b.eff(e, "fw")
	x.base.hack = 0.0
	e.base.fw = 9999.0
	for i in 20:
		b._place_debuff(x, e, {"id": "fwDown", "turns": 2, "chance": 100, "l": 0}, {})
	ok("Firewall Down ignores Hack vs Firewall", b.has_debuff(e, "fwDown"))
	var res := 0
	for i in 200:
		var q := fresh(); q[0].base.hack = 0.0; q[1].base.fw = 50.0
		b._place_debuff(q[0], q[1], {"id": "armDown", "turns": 2, "chance": 100, "l": 0}, {})
		if not b.has_debuff(q[1], "armDown"):
			res += 1
	print("INFO Hack 0 vs Firewall 50: resisted %d/200 (code: resist chance = fw - hack, cap 85)" % res)
	# poison / bleed
	p = fresh(); x = p[0]; e = p[1]; x.base.hack = 9999.0
	b._place_debuff(x, e, {"id": "poison", "turns": 2, "chance": 100, "l": 0}, {})
	b._place_debuff(x, e, {"id": "poison", "turns": 2, "chance": 100, "l": 1}, {})
	ehp = e.hp
	b._turn_start(e)
	ok("Poison 2.5% + 5% max HP stack", absf((ehp - e.hp) - (round(e.max_hp * 0.025) + round(e.max_hp * 0.05))) <= 2.0, "lost %d of %d" % [ehp - e.hp, e.max_hp])
	p = fresh(); x = p[0]; e = p[1]; x.base.hack = 9999.0
	b._place_debuff(x, e, {"id": "bleed", "turns": 2, "chance": 100, "l": 1}, {"hit": {e.uid: 1000.0}})
	ehp = e.hp
	b._turn_start(e)
	ok("Bleed 5% of the hit", absf((ehp - e.hp) - 50.0) <= 1.0, "lost %d" % [ehp - e.hp])
	# stun / shock / stupefy
	p = fresh(); x = p[0]; e = p[1]; x.base.hack = 9999.0
	b._place_debuff(x, e, {"id": "stun", "turns": 1, "chance": 100, "l": 0}, {})
	ok("Stun skips the turn", not b._turn_start(e))
	b._end_turn(e, false)
	ok("Stun expires after the skipped turn", not b.has_debuff(e, "stun"))
	var skips := 0
	for i in 400:
		var q := fresh(); q[0].base.hack = 9999.0
		b._place_debuff(q[0], q[1], {"id": "shock", "turns": 1, "chance": 100, "l": 0}, {})
		if not b._turn_start(q[1]):
			skips += 1
	ok("Shock small ~25% skip", skips > 70 and skips < 130, "%d/400" % skips)
	skips = 0
	for i in 400:
		var q := fresh(); q[0].base.hack = 9999.0
		var h1 := b.eff(q[1], "hack")
		b._place_debuff(q[0], q[1], {"id": "stupefy", "turns": 1, "chance": 100, "l": 0}, {})
		if i == 0:
			ok("Stupefy -50 hacking", is_equal_approx(b.eff(q[1], "hack"), max(0.0, h1 - 50)))
		if not b._turn_start(q[1]):
			skips += 1
	ok("Stupefy ~35% skip", skips > 110 and skips < 170, "%d/400" % skips)
	# mark / break / heal block / block buffs / enraged / cd increase
	p = fresh(); x = p[0]; e = p[1]; x.base.hack = 9999.0
	b._place_debuff(x, e, {"id": "mark", "turns": 2, "chance": 100, "l": 0}, {})
	ok("Mark placed with x2", b.has_debuff(e, "mark") and b._debuff_sum(e, "mark") == 2.0)
	b._place_debuff(x, e, {"id": "break", "turns": 2, "chance": 100, "l": 1}, {})
	ok("Break large 25%", b._debuff_sum(e, "break") == 25.0)
	b._place_debuff(x, e, {"id": "healBlock", "turns": 2, "chance": 100, "l": 0}, {})
	e.hp = e.max_hp * 0.5; ehp = e.hp
	b._heal(x, e, 500.0, true)
	ok("Heal Block stops healing", e.hp == ehp)
	b._place_debuff(x, e, {"id": "blockBuffs", "turns": 2, "chance": 100, "l": 0}, {})
	b._place_buff(e, e, {"id": "fpUp", "turns": 2, "l": 0}, true)
	ok("Block Buffs stops buffs", not b.has_buff(e, "fpUp"))
	b._place_debuff(x, e, {"id": "enraged", "turns": 2, "chance": 100, "l": 0}, {})
	e.tm = Battle.TM_FULL + 1
	for u in b.units:
		if u != e: u.tm = 0.0
	var t = b.next_turn()
	ok("Enraged forces basic on the enrager", t != null and t.get("forced_target", "") == x.uid and t.get("forced_ab", "") == b.basic(e).id)
	print("\nFAILS: %d" % fails)
	get_tree().quit()
