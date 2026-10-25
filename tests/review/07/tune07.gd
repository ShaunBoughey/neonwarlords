extends Node
## Hideout curve tuning probe: win% at stages 10/15/20 per band, for every hideout.
##   NW_SAVE=07 godot --headless --path . res://tests/review/07/Tune07.tscn -- --nwtest
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Tune07")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var bands := [[4, "rare", 12], [5, "epic", 16], [6, "epic", 16], [6, "legendary", 20]]
	var teams: Array = []
	for bd in bands:
		var uids: Array = []
		for id in tpls:
			var w := Game.add_warlord(id, true)
			w.rank = bd[0]; w.level = Data.max_level(bd[0]); w.rep = bd[0]
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, bd[0], bd[1])
				it.level = bd[2]
				Game.S.equip.append(it)
				Game.equip_on(w, it)
			uids.append(w.uid)
		teams.append(uids)
	print("bands R4rare / R5epic / R6epic / R6max")
	var stages := [10, 15, 20]
	var tot := {}
	for hid in Content.HIDEOUT_ORDER:
		var row := "%-15s" % hid
		for st in stages:
			var cells: Array = []
			for bi in teams.size():
				var w := 0
				for i in 12:
					var b := Battle.new()
					var enc := Content.build_hideout(hid, st)
					b.setup(Content.player_units(teams[bi]), enc.waves.map(func(wv): return wv.map(func(u): return u.duplicate(true))), {})
					b.simulate()
					w += 1 if b.result == "win" else 0
				cells.append(str(int(w * 100.0 / 12)))
				var k := "%d/%d" % [st, bi]
				tot[k] = tot.get(k, 0) + w
			row += "  s%d %s" % [st, "/".join(cells)]
		print(row)
	var avg := "AVERAGE        "
	for st in stages:
		var cells: Array = []
		for bi in teams.size():
			cells.append(str(int(tot["%d/%d" % [st, bi]] * 100.0 / (12 * Content.HIDEOUT_ORDER.size()))))
		avg += "  s%d %s" % [st, "/".join(cells)]
	print(avg)
	get_tree().quit()
