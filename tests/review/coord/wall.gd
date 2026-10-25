extends Node
## Coordinator probe: enemy levels/bosses and win% per Warlord-difficulty den boss for one R5 squad.
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	for band in [[5, "epic", 16], [6, "epic", 16]]:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = band[0]; w.level = Data.max_level(band[0]); w.rep = band[0]
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, band[0], band[1]); it.level = band[2]
				Game.S.equip.append(it); Game.equip_on(w, it)
			uids.append(w.uid)
		print("band R%d power %s" % [band[0], U.fmt(Game.team_power(uids))])
		for d in [1, 2]:
			for loc in 10:
				for st in [0, 6]:
					var enc := Content.build_campaign(d, loc, st)
					var wins := 0
					for i in 6:
						var b := Battle.new()
						var waves: Array = []
						for wv in enc.waves:
							waves.append(wv.map(func(u): return u.duplicate(true)))
						b.setup(Content.player_units(uids), waves, {})
						b.simulate()
						wins += 1 if b.result == "win" else 0
					var last: Array = enc.waves[enc.waves.size() - 1]
					var lv := last.map(func(u): return "%s L%d" % [u.tpl, u.level])
					print("%s %d-%d win %d/6  %s" % [Data.DIFFS[d], loc + 1, st + 1, wins, ", ".join(lv)])
	get_tree().quit()
