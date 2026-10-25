extends Node
## Balance probe: enemy power across late campaign stages vs. a squad at each rank/level band.
## godot --headless --path . res://tests/BalanceProbe.tscn -- --nwtest

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	print("== den bosses (difficulty: den -> boss)")
	for d in 3:
		var bl := "%-12s" % Data.DIFFS[d]
		for loc in 10:
			for u in Content.build_campaign(d, loc, 6).waves[0]:
				if u.boss:
					bl += " %d:%s" % [loc + 1, u.tpl]
		print(bl)
	print("== enemy power (team of 4 / boss stages)")
	for d in 3:
		var line := "%-12s" % Data.DIFFS[d]
		for loc in [0, 4, 7, 9]:
			for st in [0, 6]:
				line += " %d-%d:%s" % [loc + 1, st + 1, U.fmt(Content.enc_power(Content.build_campaign(d, loc, st)))]
		print(line)
	print("== hideout power (trolls / heist)")
	var hl := ""
	for s in [1, 5, 8, 10, 15, 20]:
		hl += " S%d:%s/%s" % [s, U.fmt(Content.enc_power(Content.build_hideout("trolls", s))), U.fmt(Content.enc_power(Content.build_hideout("heist", s)))]
	print(hl)
	print("== player squad power by rank band (4 epics, auto-equipped with gear of matching rank, +16)")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	for band in [3, 4, 5, 6, 7]:
		var rank: int = mini(band, 6)
		var maxed: bool = band == 7
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = rank
			w.level = Data.max_level(rank)
			w.rep = clampi(rank, 0, 6)
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, rank, "legendary" if maxed else "epic")
				it.level = 20 if maxed else 16
				Game.S.equip.append(it)
				Game.equip_on(w, it)
			uids.append(w.uid)
		print("  R%d L%d%s -> team power %s" % [rank, Data.max_level(rank), " legendary +20" if maxed else "", U.fmt(Game.team_power(uids))])
		var row := "     win%% "
		for c in [[1, 9, 6], [2, 0, 0], [2, 4, 6], [2, 9, 0], [2, 9, 6]]:
			var wins := 0
			var turns := 0
			for i in 10:
				var r := _sim(uids, Content.build_campaign(c[0], c[1], c[2]))
				wins += 1 if r[0] == "win" else 0
				turns += r[1]
			row += " %s %d-%d:%d%% (%dt)" % [Data.DIFFS[c[0]].substr(0, 4), c[1] + 1, c[2] + 1, wins * 10, turns / 10]
		print(row)
		Game.S.pit.brawl.opps = []
		var opps: Array = Content.pit_opponents("brawl")
		var prow := "     pit opp powers %s vs mine %s (k %s) |" % [str(opps.map(func(o): return o.power)), U.fmt(Game.team_power(uids)), str(opps.map(func(o): return snappedf(o.k, 0.1)))]
		for oi in [0, 5, 9]:
			var pw := 0
			for i in 8:
				var r := _sim(uids, Content.build_pit("brawl", opps[oi]))
				pw += 1 if r[0] == "win" else 0
			prow += " %d%%" % int(pw * 100.0 / 8)
		print(prow)
	print("== detail: last band vs Mob Boss 10-7")
	var team: Array = Game.S.roster.slice(Game.S.roster.size() - 4).map(func(x): return x.uid)
	for i in 3:
		var enc := Content.build_campaign(1, 9, 6)
		var b := Battle.new()
		b.setup(Content.player_units(team), [enc.waves[0].map(func(u): return u.duplicate(true))], {"turn_limit": 0})
		b.simulate()
		var foes: Array = b.units.filter(func(u): return u.side == 1).map(func(u): return "%s %d%s" % [u.tpl, int(u.hp), "" if u.alive else "x"])
		var mine: Array = b.units.filter(func(u): return u.side == 0).map(func(u): return "%s %d%s" % [u.tpl, int(u.hp), "" if u.alive else "x"])
		print("  %s  turns %d  foes %s  mine %s" % [b.result, b.turn_count, foes, mine])
	get_tree().quit()

func _sim(team: Array, enc: Dictionary) -> Array:
	var b := Battle.new()
	var waves: Array = []
	for wv in enc.waves:
		var arr: Array = []
		for u in wv:
			arr.append(u.duplicate(true))
		waves.append(arr)
	b.setup(Content.player_units(team), waves, {"turn_limit": 0, "enemy_reinforcements": enc.get("enemy_reinf", [])})
	b.simulate()
	return [b.result, b.player_turns]
