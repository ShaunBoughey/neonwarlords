extends Node
## Campaign difficulty climb probe: win% per den (stage 1 and boss stage) for 3 bands, Mob Boss and Warlord.
## Each cell averages two different epic squads (n fights each).
##   NW_SAVE=07 godot --headless --path . res://tests/review/07/Wall07.tscn -- --nwtest
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Wall07")
	# determinism: build the same stage twice with RNG use in between
	var a: Array = Content.build_campaign(2, 0, 0).waves[0].map(func(u): return u.tpl)
	U.rf(); U.rf()
	var b0: Array = Content.build_campaign(2, 0, 0).waves[0].map(func(u): return u.tpl)
	print("deterministic: ", a == b0, " ", a)
	var epics: Array = Warlords.RECRUITABLE.filter(func(id): return Warlords.get_t(id).rarity == "epic")
	var squads: Array = [epics.slice(0, 4), [epics[4], epics[5], epics[6], epics[3]]]
	print("squads: ", squads)
	var bands := [[5, "epic", 16], [6, "epic", 16], [6, "legendary", 20]]
	var teams: Array = []   # per band: [squad A uids, squad B uids]
	for bd in bands:
		var pair: Array = []
		for tpls in squads:
			var uids: Array = []
			for id in tpls:
				var w := Game.add_warlord(id, true)
				w.rank = bd[0]; w.level = Data.max_level(bd[0]); w.rep = bd[0]
				for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
					var it := Game.make_equipment(slot, bd[0], bd[1]); it.level = bd[2]
					Game.S.equip.append(it); Game.equip_on(w, it)
				uids.append(w.uid)
			pair.append(uids)
		teams.append(pair)
		print("band R%d %s+%d power %s / %s" % [bd[0], bd[1], bd[2], U.fmt(Game.team_power(pair[0])), U.fmt(Game.team_power(pair[1]))])
	var n := int(OS.get_environment("NW_N")) if OS.get_environment("NW_N") != "" else 8
	if OS.get_environment("NW_CB") != "":   # "mb_per_den,wl_base,wl_per_den"
		var cb := OS.get_environment("NW_CB").split(",")
		Content.CAMPAIGN_BONUS = [[0.0, 0.0], [0.0, float(cb[0])], [float(cb[1]), float(cb[2])]]
		print("CAMPAIGN_BONUS ", Content.CAMPAIGN_BONUS)
	if OS.get_environment("NW_WCAP") != "":
		var cp := OS.get_environment("NW_WCAP").split(",")   # "mob_boss_cap,warlord_cap"
		Content.CAMPAIGN_BONUS_CAP = [99.0, float(cp[0]), float(cp[1])]
		print("CAMPAIGN_BONUS_CAP ", Content.CAMPAIGN_BONUS_CAP)
	for d in [1, 2]:
		for st in [0, 6]:
			var line := "%-10s st%d " % [Data.DIFFS[d], st + 1]
			for loc in 10:
				var enc := Content.build_campaign(d, loc, st)
				var cells: Array = []
				for pair in teams:
					var wins := 0
					for team in pair:
						for i in n:
							var b := Battle.new()
							b.setup(Content.player_units(team), enc.waves.map(func(wv): return wv.map(func(u): return u.duplicate(true))), {})
							b.simulate()
							wins += 1 if b.result == "win" else 0
					cells.append(str(int(wins * 100.0 / (2 * n))))
				line += " %d:%s" % [loc + 1, "/".join(cells)]
			print(line)
	get_tree().quit()
