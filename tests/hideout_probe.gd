extends Node
## Hideout balance probe: win% for every hideout at stages 5/10/15/20 by squad band.
## godot --headless --path . res://tests/HideoutProbe.tscn -- --nwtest

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var bands := [[5, "epic", 16], [6, "epic", 16], [6, "legendary", 20]]
	var teams: Array = []
	for bd in bands:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = bd[0]
			w.level = Data.max_level(bd[0])
			w.rep = bd[0]
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, bd[0], bd[1])
				it.level = bd[2]
				Game.S.equip.append(it)
				Game.equip_on(w, it)
			uids.append(w.uid)
		teams.append(uids)
		print("band R%d %s+%d power %s" % [bd[0], bd[1], bd[2], U.fmt(Game.team_power(uids))])
	print("hideout          stage:  5      10     15     20   (win%% per band R5 / R6 / R6max, avg player turns)")
	for hid in Content.HIDEOUT_ORDER:
		var row := "%-15s" % hid
		for st in [5, 10, 15, 20]:
			var cells: Array = []
			var tt := 0
			for team in teams:
				var w := 0
				for i in 6:
					var r := _sim(team, Content.build_hideout(hid, st))
					w += 1 if r[0] == "win" else 0
					tt += r[1]
				cells.append(str(int(w * 100.0 / 6)))
			row += "  %s(%dt)" % ["/".join(cells), tt / 18]
		print(row)
	get_tree().quit()

func _sim(team: Array, enc: Dictionary) -> Array:
	var b := Battle.new()
	var waves: Array = []
	for wv in enc.waves:
		waves.append(wv.map(func(u): return u.duplicate(true)))
	b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0)})
	b.simulate()
	return [b.result, b.player_turns]
