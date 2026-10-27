extends Node
## Per-hideout late-step sweep. Env NW_IDS="trolls,vultures", NW_STEPS="16,12,8,4,0", NW_TUNE_N=8.
## Prints stage-20 wins for R6 epic+16 and R6 legendary+20 (maxed) squads at each late step.
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Sweep")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var teams := []
	for bd in [[6, "epic", 16], [6, "legendary", 20]]:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = bd[0]; w.level = Data.max_level(bd[0]); w.rep = bd[0]
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, bd[0], bd[1]); it.level = bd[2]
				Game.S.equip.append(it); Game.equip_on(w, it)
			uids.append(w.uid)
		teams.append(uids)
	var n := int(OS.get_environment("NW_TUNE_N"))
	if OS.get_environment("NW_BOSS_LATE") != "":
		Content.HIDEOUT_BOSS_LATE = float(OS.get_environment("NW_BOSS_LATE"))
	# preset per-hideout values: NW_PRESET="id=step[:bosshp],..."
	for kv in OS.get_environment("NW_PRESET").split(",", false):
		var parts := kv.split("=")
		var sv := parts[1].split(":")
		Content.HIDEOUT_LATE_STEP_BY_ID[parts[0]] = int(sv[0])
		if sv.size() > 1:
			Content.HIDEOUT_BOSS_HP_BY_ID[parts[0]] = float(sv[1])
	if OS.get_environment("NW_IDS") == "":
		get_tree().quit()
		return
	for hid in OS.get_environment("NW_IDS").split(","):
		var row := "%-15s" % hid
		for st in OS.get_environment("NW_STEPS").split(","):
			var sv2 := st.split(":")
			Content.HIDEOUT_LATE_STEP_BY_ID[hid] = int(sv2[0])
			Content.HIDEOUT_BOSS_HP_BY_ID[hid] = float(sv2[1]) if sv2.size() > 1 else 1.0
			row += "  step%s: %d/%d" % [st, _wins(teams[0], hid, n), _wins(teams[1], hid, n)]
		print("SW ", row)
	get_tree().quit()

func _wins(team: Array, hid: String, n: int) -> int:
	var w := 0
	for i in n:
		var enc := Content.build_hideout(hid, 20)
		var waves: Array = []
		for wv in enc.waves:
			waves.append(wv.map(func(u): return u.duplicate(true)))
		var b := Battle.new()
		b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0)})
		b.simulate()
		w += 1 if b.result == "win" else 0
	return w
