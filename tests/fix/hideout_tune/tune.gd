extends Node
## Sweep hideout late-game levers. Env NW_TUNE="mid,late,boss_late;..." ; prints stage 15 (R5/R6 epic) and stage 20 (R6 epic/R6 max) win% per hideout.
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Tune")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var teams := {}
	for bd in [[5, "epic", 16], [6, "epic", 16], [6, "legendary", 20]]:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = bd[0]; w.level = Data.max_level(bd[0]); w.rep = bd[0]
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, bd[0], bd[1]); it.level = bd[2]
				Game.S.equip.append(it); Game.equip_on(w, it)
			uids.append(w.uid)
		teams["%d%s" % [bd[0], bd[1][0]]] = uids
	var n := int(OS.get_environment("NW_TUNE_N")) if OS.get_environment("NW_TUNE_N") != "" else 6
	for cfg in OS.get_environment("NW_TUNE").split(";"):
		var v := cfg.split(",")
		Content.HIDEOUT_MID_STEP = int(v[0]); Content.HIDEOUT_LATE_STEP = int(v[1]); Content.HIDEOUT_BOSS_LATE = float(v[2])
		var s15 := [0, 0]; var s20 := [0, 0]; var tot := 0
		var row := ""
		for hid in Content.HIDEOUT_ORDER:
			var c := [_wins(teams["5e"], hid, 15, n), _wins(teams["6e"], hid, 15, n), _wins(teams["6e"], hid, 20, n), _wins(teams["6l"], hid, 20, n)]
			row += " %s %d/%d|%d/%d" % [hid.substr(0, 5), c[0], c[1], c[2], c[3]]
			s15[0] += c[0]; s15[1] += c[1]; s20[0] += c[2]; s20[1] += c[3]; tot += n
		print("cfg %s  s15 R5 %d%% R6e %d%%  s20 R6e %d%% R6max %d%%  ::%s" % [cfg, s15[0] * 100 / tot, s15[1] * 100 / tot, s20[0] * 100 / tot, s20[1] * 100 / tot, row])
	get_tree().quit()

func _wins(team: Array, hid: String, st: int, n: int) -> int:
	var w := 0
	for i in n:
		var enc := Content.build_hideout(hid, st)
		var waves: Array = []
		for wv in enc.waves:
			waves.append(wv.map(func(u): return u.duplicate(true)))
		var b := Battle.new()
		b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0)})
		b.simulate()
		w += 1 if b.result == "win" else 0
	return w
