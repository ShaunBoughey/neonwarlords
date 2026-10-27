extends Node
## Audit 03 probe: equipment rules, sets in stats and combat, acquisition parsing.
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: " + m)

# GDD matrix (independent copy): P = primary+sub, S = sub only, absent = N/A
const G := {
	"hp":   ["P","S","P","S","P","P","P","P","P"],
	"hpP":  ["P","S","P","S","S","P","S","S","S"],
	"arm":  ["P","P","P","S","S","P","P","P","P"],
	"armP": ["P","S","P","S","S","P","S","S","S"],
	"fp":   ["P","S","P","P","S","P","P","P","P"],
	"fpP":  ["P","S","P","S","S","P","S","S","S"],
	"spd":  ["S","S","S","S","S","P","S","-","S"],
	"cc":   ["P","S","S","S","S","S","-","-","-"],
	"cd":   ["P","S","S","S","S","S","S","P","S"],
	"hack": ["S","S","P","S","S","S","P","S","S"],
	"fw":   ["S","S","P","S","S","S","S","S","P"],
}
const COLS := ["weapon","helmet","chest","gloves","legs","boots","limbs","organs","skeleton"]

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Audit03")
	# matrix
	for ci in COLS.size():
		var slot: String = COLS[ci]
		var pri_seen := {}
		var sub_seen := {}
		for i in 600:
			var it := Game.make_equipment(slot, 6, "legendary")
			pri_seen[it.pri.stat] = true
			var used := {it.pri.stat: true}
			for s in it.subs:
				sub_seen[s.stat] = true
				check(not used.has(s.stat), "dup stat on %s" % slot)
				used[s.stat] = true
		for st in G:
			var cell: String = G[st][ci]
			check(pri_seen.has(st) == (cell == "P"), "%s primary %s: gdd %s seen %s" % [slot, st, cell, pri_seen.has(st)])
			check(sub_seen.has(st) == (cell != "-"), "%s sub %s: gdd %s seen %s" % [slot, st, cell, sub_seen.has(st)])
	print("matrix checked")
	# starting subs + leveling
	for r in Data.RARITIES:
		var it := Game.make_equipment("helmet", 3, r, "Health")
		check(it.subs.size() == Data.SUBS_BY_RARITY[r], "start subs %s" % r)
		var log := []
		for l in 20:
			Game.equip_level_up(it, true)
			log.append(it.subs.size())
		var rolls := 0
		for s in it.subs: rolls += int(s.rolls)
		print("%s: subs after lv5/10/15/20 = %s/%s/%s/%s rolls %d rank %d lvl %d" % [r, log[4], log[9], log[14], log[19], rolls, it.rank, it.level])
		check(Game.equip_level_up(it, true) != "", "cap 20")
	# primary per rank at +0
	for st in Data.PRIMARY:
		for rk in range(1, 7):
			check(Data.primary_value(st, rk, 0) == Data.PRIMARY[st][rk], "primary %s r%d" % [st, rk])
	# cost display sample
	print("level cost R1 0->1 %d, R6 19->20 %d" % [Data.equip_level_cost(1, 0), Data.equip_level_cost(6, 19)])
	# neons
	var g5 := Game.make_equipment("boots", 5, "legendary", "Speed")
	g5.pri.stat = "hp"
	g5.subs = [{"stat": "spd", "val": 5, "rolls": 0, "neon": 0}]
	var n5 := {"uid": "a", "rank": 5, "stat": "spd"}
	var n6 := {"uid": "b", "rank": 6, "stat": "spd"}
	var nfp := {"uid": "c", "rank": 1, "stat": "fp"}
	check(Game.neon_can(g5, n5) == "", "R5 spd on R5")
	check(Game.neon_can(g5, n6) != "", "R6 on R5 rejected")
	check(Game.neon_can(g5, nfp) != "", "no fp sub rejected")
	var g4 := g5.duplicate(true); g4.rank = 4
	check(Game.neon_can(g4, n5) != "", "R5 on R4 rejected")
	check(not Data.NEON_STATS.has("cc") and Data.NEON_STATS.size() == 10, "neon stats")
	var g6 := g5.duplicate(true); g6.rank = 6
	Game.S.neons.append(n5)
	check(Game.apply_neon(g6, n5) == "", "R5 on R6 ok")
	print("neon on R6 spd sub: val %s neon %s" % [g6.subs[0].val, g6.subs[0].neon])
	# primary-stat-only neon (neon matches primary but not a sub)
	var gp := Game.make_equipment("legs", 6, "common", "Health")
	check(Game.neon_can(gp, {"rank": 1, "stat": "hp"}) != "", "neon on primary-only rejected")
	# sets in compute_stats
	var w := Game.add_warlord("brother_grin", true)
	w.level = 1
	var bare := Game.compute_stats(w)
	for sname in Data.STAT_SETS:
		w.gear = {}
		var made := []
		for slot in ["weapon", "helmet"]:
			var it := Game.make_equipment(slot, 1, "common", sname)
			it.pri.stat = "hp" if slot == "weapon" else "arm"
			Game.S.equip.append(it); w.gear[slot] = it.uid; made.append(it)
		var s := Game.compute_stats(w)
		var d := {}
		for k in ["hp", "arm", "fp", "spd", "cc", "cd", "hack", "fw"]:
			if abs(float(s[k]) - float(bare[k])) > 0.01: d[k] = float(s[k]) - float(bare[k])
		print("set %s 2pc delta %s (base hp %s arm %s fp %s spd %s)" % [sname, d, bare.hp, bare.arm, bare.fp, bare.spd])
	w.gear = {}
	# acquisition parse
	var srcs := {"bm": [], "shop": [], "cache": []}
	for r in Data.GDD.blackMarket:
		for p in U.parse_rewards(String(r[0])):
			if p.k in ["gear", "implant", "gearSet", "implantSet"]: srcs.bm.append(p)
	for sec in Data.GDD.shop:
		for r in Data.GDD.shop[sec]:
			for p in U.parse_rewards(String(r[1])):
				if p.k in ["gear", "implant", "gearSet", "implantSet", "neon"]: srcs.shop.append(p)
	print("BM equipment rows: %s" % [srcs.bm])
	print("Shop equipment/neon rows: %s" % [srcs.shop])
	var before: int = Game.S.equip.size()
	Game.add_item(["cache", "Exalted Cache"], 1)
	var cr := Game.open_cache("Exalted Cache")
	print("Exalted cache gave %d rewards, equip +%d" % [cr.size(), Game.S.equip.size() - before])
	# combat effects
	_combat()
	print("PROBE DONE, failures: %d" % fails)
	get_tree().quit(0)

func _unit(side: int, sets: Dictionary) -> Dictionary:
	var w := {"tpl": "brother_grin", "level": 60, "rank": 6, "rep": 0, "ab": {}, "nn": {}, "gear": {}}
	var u := Battle.make_unit(w, side)
	u.sets = sets
	u.base.hack = 500.0
	u.base.fw = 0.0
	return u

func _combat() -> void:
	var tests := ["none", "Energy Drain", "Pain Mirror", "Strike Back", "Plague", "Sanguine", "Discharge", "Trauma", "Goad", "Ripper"]
	for sname in tests:
		var heal := 0.0; var refl := 0.0; var counters := 0; var deb := 0; var dmg := 0.0
		var N := 400
		for i in N:
			var b := Battle.new()
			var a := _unit(0, {sname: 4} if sname not in ["Pain Mirror", "Strike Back"] else {})
			var t := _unit(1, {sname: 4} if sname in ["Pain Mirror", "Strike Back"] else {})
			b.setup([a], [[t]], {"seed": i})
			a.hp = a.max_hp * 0.5
			var hp0: float = a.hp
			b._attack(a, t, b.basic(a), {"crit": false, "kill": false, "hit": {}})
			dmg += t.max_hp - t.hp
			var evs := b.take_events()
			for e in evs:
				if e.get("t", "") == "Counter!": counters += 1
			if sname == "Energy Drain": heal += a.hp - hp0
			if sname == "Pain Mirror": refl += hp0 - a.hp
			if not t.debuffs.is_empty(): deb += 1
		print("%-13s avg dmg %.0f  heal %.1f%%  reflect %.1f%%  counter %.0f%%  debuffed %.0f%%" % [sname, dmg / N, 100 * heal / max(1, dmg), 100 * refl / max(1, dmg), 100.0 * counters / N, 100.0 * deb / N])
	# round start sets
	var b2 := Battle.new()
	var j := _unit(0, {"Jamming": 4}); var sg := _unit(0, {"Safeguard": 4}); var st := _unit(0, {"Stitcher": 4})
	var e1 := _unit(1, {})
	b2.setup([j, sg, st], [[e1]], {"seed": 1})
	b2._round_start_effects(true)
	print("Jamming buffs: %s" % [j.buffs.map(func(x): return [x.id, x.turns])])
	print("Safeguard shields: %s (30%% hp = %.0f)" % [[j, sg, st].map(func(x): return x.buffs.filter(func(y): return y.id == "overshield").map(func(y): return [y.shield, y.turns])), sg.max_hp * 0.3])
	j.hp = j.max_hp * 0.5
	var h0: float = j.hp
	b2._turn_start(st)
	print("Stitcher heal on ally: %.0f (10%% wearer hp = %.0f)" % [j.hp - h0, st.max_hp * 0.1])
