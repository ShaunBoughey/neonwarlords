extends Node
## Bisect each hideout's late step (stages 16-20) so stage 20 wins ~50% for maxed R6 legendary squads.
## Env NW_IDS="trolls,..."; 3 independently geared squads x NW_TUNE_N fights each per evaluation.
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Bisect")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var teams := []
	for k in 3:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = 6; w.level = Data.max_level(6); w.rep = 6
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, 6, "legendary"); it.level = 20
				Game.S.equip.append(it); Game.equip_on(w, it)
			uids.append(w.uid)
		teams.append(uids)
	var n := int(OS.get_environment("NW_TUNE_N"))
	if OS.get_environment("NW_MODE") == "boss":
		for hid in OS.get_environment("NW_IDS").split(","):
			Content.HIDEOUT_LATE_STEP_BY_ID[hid] = 0
			var flo := 0.5
			var fhi := 1.0
			var flog := ""
			for it in 5:
				var fm := (flo + fhi) / 2.0
				Content.HIDEOUT_BOSS_HP_BY_ID[hid] = fm
				var r := _rate(teams, hid, n)
				flog += " %.3f:%d%%" % [fm, int(r * 100)]
				if r >= 0.5:
					flo = fm
				else:
					fhi = fm
			print("BI %-15s boss %.3f  (%s)" % [hid, flo, flog])
		get_tree().quit()
		return
	for hid in OS.get_environment("NW_IDS").split(","):
		var lo := 0
		var hi := 40
		var log := ""
		while hi - lo > 1:
			var mid := (lo + hi) / 2
			Content.HIDEOUT_LATE_STEP_BY_ID[hid] = mid
			var r := _rate(teams, hid, n)
			log += " %d:%d%%" % [mid, int(r * 100)]
			if r >= 0.5:
				lo = mid
			else:
				hi = mid
		Content.HIDEOUT_LATE_STEP_BY_ID[hid] = lo
		print("BI %-15s step %d  (%s)" % [hid, lo, log])
	get_tree().quit()

func _rate(teams: Array, hid: String, n: int) -> float:
	var w := 0
	for team in teams:
		for i in n:
			var enc := Content.build_hideout(hid, 20)
			var waves: Array = []
			for wv in enc.waves:
				waves.append(wv.map(func(u): return u.duplicate(true)))
			var b := Battle.new()
			b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0)})
			b.simulate()
			w += 1 if b.result == "win" else 0
	return float(w) / (n * teams.size())
