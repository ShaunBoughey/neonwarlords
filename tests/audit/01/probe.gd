extends Node
## Audit 01 probe: warlord progression (XP table, rank-up, rep, metabolics, stats ranges, alignment).
var fails := 0
func check(c: bool, m: String) -> void:
	if not c:
		fails += 1
		print("FAIL: " + m)

func _ready() -> void:
	await get_tree().process_frame
	# XP table totals per rank (GDD: 6790, 28137, 89922, 267163, 773916, 2220905)
	var gdd_tot := [6790, 28137, 89922, 267163, 773916, 2220905]
	for r in range(1, 7):
		var tot := 0
		for l in range(1, r * 10):
			tot += Data.xp_to_next(l, r)
		print("rank %d total xp %d (gdd %d)" % [r, tot, gdd_tot[r - 1]])
		check(abs(tot - gdd_tot[r - 1]) <= r * 10, "xp total rank %d" % r)
	check(Data.xp_to_next(9, 1) == 1072 and Data.xp_to_next(59, 6) == 202633 and Data.xp_to_next(49, 5) == 78124, "xp spot")
	# alignment distribution
	var dist := {}
	for id in Warlords.RECRUITABLE:
		var t: Dictionary = Warlords.T[id]
		check(t.align in Data.ALIGNMENTS, "align of " + id)
		var k: String = "%s/%s" % [t.rarity, t.align]
		dist[k] = int(dist.get(k, 0)) + 1
		dist[t.align] = int(dist.get(t.align, 0)) + 1
		# base stat ranges
		var rg: Array = Data.BASE_RANGES[t.cls][t.rarity]
		var b: Dictionary = t.base
		check(b.hp >= rg[0][0] and b.hp <= rg[0][1] and b.arm >= rg[1][0] and b.arm <= rg[1][1] and b.fp >= rg[2][0] and b.fp <= rg[2][1], "base range " + id)
		check(b.spd >= 90 and b.spd <= 110 and b.cc == 10.0 and b.cd == 50.0 and b.fw == 30.0 and b.hack == 0, "base fixed " + id)
		# ability counts
		var c := {"active": 0, "passive": 0, "leader": 0, "reinforce": 0}
		for a in t.abilities:
			c[a.type] += 1
		check(c.active <= 3 and c.leader <= 1 and c.reinforce <= 2, "ability caps " + id + str(c))
	print("recruitable %d  dist %s" % [Warlords.RECRUITABLE.size(), str(dist)])
	# new game & progression rules
	Game.new_game("Audit01")
	var w: Dictionary = Game.add_warlord("brother_grin", true)
	check(w.rank == 1, "common starts r1")
	check(Game.add_warlord("raiden_x", true).rank == 5, "legendary starts r5")
	check(Game.add_warlord("venn", true).rank == 4, "epic starts r4")
	var f1: Dictionary = Game.add_warlord("scrapjaw", true)
	check(Game.rank_up(w, [f1.uid]) != "", "rank up blocked below max level")
	Game.add_wxp(w, 6790)
	print("after 6790 xp: lv %d xp %d" % [w.level, w.xp])
	check(w.level == 10, "6790 xp reaches lv10 at r1")
	check(Game.rank_up(w, []) != "", "needs 1 fodder")
	check(Game.rank_up(w, [f1.uid]) == "", "rank up ok")
	check(w.rank == 2 and w.level == 10, "rank 2 keeps level 10")
	# rep cap
	w.rep = 0
	check(Game.can_rep_up(w) == "", "rep 1 affordable with starter deeds: " + Game.can_rep_up(w))
	Game.rep_up(w)
	Game.rep_up(w)
	print("rep now %d (rank %d): next err '%s'" % [w.rep, w.rank, Game.can_rep_up(w)])
	check(w.rep == 2, "rep up twice to rank cap")
	check(Game.can_rep_up(w).find("capped") >= 0, "rep capped at rank")
	# metabolic alignment bonus
	var r: Dictionary = Game.add_warlord("ragnar_volt", true)  # renegade
	var before := int(r.xp)
	Game.use_metabolic(r, "renegade", "minor")
	var a_xp := 0
	for l in range(1, r.level): a_xp += Data.xp_to_next(l, r.rank)
	print("renegade minor on renegade -> lv %d xp %d (total %d)" % [r.level, r.xp, a_xp + int(r.xp)])
	var n: Dictionary = Game.add_warlord("ragnar_volt", true)
	Game.use_metabolic(n, "paragon", "minor")
	var b_xp := 0
	for l in range(1, n.level): b_xp += Data.xp_to_next(l, n.rank)
	print("paragon minor on renegade -> total %d" % (b_xp + int(n.xp)))
	check(a_xp + int(r.xp) == 2250 and b_xp + int(n.xp) == 1500, "metabolic bonus")
	print("generic metabolics owned %d (no UI slot)" % Game.item_count(["metabolic", "generic", "minor"]))
	# stat scaling: level 60 rank 6 rep 6 vs base
	var L: Dictionary = Game.add_warlord("alpha_ramsgate", true)
	var s0 := Game.compute_stats(L)
	L.level = 60; L.rank = 6; L.rep = 6; L.gear = {}
	var s1 := Game.compute_stats(L)
	var tb: Dictionary = Warlords.T.alpha_ramsgate.base
	print("ramsgate base %s  r5l1 %s  r6l60rep6 %s" % [str([tb.hp, tb.arm, tb.fp]), str([s0.hp, s0.arm, s0.fp]), str([s1.hp, s1.arm, s1.fp])])
	# loss xp 20%
	var enc := {"mode": "pit"}
	print("PROBE DONE, failures: %d" % fails)
	get_tree().quit(1 if fails > 0 else 0)
