extends Node
## Audit 05: do boss debuffs land in real hideout fights? Counts debuff/resist events by enemy-side sources.
func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Audit05b")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	for band in [[3, "rare", 8, 6], [5, "epic", 16, 10], [6, "legendary", 20, 18]]:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = band[0]; w.level = Data.max_level(band[0]); w.rep = band[0]
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, band[0], band[1]); it.level = band[2]
				Game.S.equip.append(it); Game.equip_on(w, it)
			uids.append(w.uid)
		for hid in ["trolls", "vultures", "teratek", "vikings"]:
			var st: int = band[3]
			var land := {}; var resist := 0; var devour := 0; var wins := 0
			var fws: Array = []
			for i in 6:
				var enc := Content.build_hideout(hid, st)
				var b := Battle.new()
				var waves: Array = []
				for wv in enc.waves: waves.append(wv.map(func(u): return u.duplicate(true)))
				b.setup(Content.player_units(uids), waves, {})
				if i == 0: fws = b.side_units(0).map(func(u): return int(u.base.fw))
				b.simulate()
				wins += 1 if b.result == "win" else 0
				for e in b.events:
					if e.get("e") == "debuff":
						var u = b.unit(e.u)
						if u != null and u.side == 0: land[e.id] = land.get(e.id, 0) + 1
					elif e.get("e") == "resist":
						var u2 = b.unit(e.u)
						if u2 != null and u2.side == 0: resist += 1
					elif e.get("e") == "ability" and str(e.get("ab", "")) == "devour": devour += 1
			var boss: Dictionary = Content.build_hideout(hid, st).waves[1][0]
			print("R%d s%d %s win %d/6 bossHack=%d playerFw=%s debuffs landed on player=%s resisted=%d" % [band[0], st, hid, wins, int(boss.base.hack), fws, land, resist])
	print("SIM DONE")
	get_tree().quit()
