extends Node
func _ready() -> void:
	Game.reset_save()
	Game.new_game("D07")
	var tpls: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and tpls.size() < 4:
			tpls.append(id)
	var uids: Array = []
	for id in tpls:
		var w := Game.add_warlord(id, true)
		w.rank = 6; w.level = Data.max_level(6); w.rep = 6
		for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
			var it := Game.make_equipment(slot, 6, "legendary"); it.level = 20
			Game.S.equip.append(it); Game.equip_on(w, it)
		uids.append(w.uid)
	for loc in [4, 7, 8, 9]:
		var enc := Content.build_campaign(2, loc, 6)
		print("WL %d-7 %s" % [loc + 1, enc.waves[0].map(func(u): return "%s hp%d fp%d spd%d" % [u.tpl, int(u.base.hp), int(u.base.fp), int(u.base.spd)])])
		for i in 3:
			var b := Battle.new()
			b.setup(Content.player_units(uids), enc.waves.map(func(wv): return wv.map(func(u): return u.duplicate(true))), {})
			b.simulate()
			var alive_e := b.side_units(1).map(func(u): return "%s %d%%" % [u.tpl, int(u.hp * 100 / u.max_hp)])
			var alive_p := b.side_units(0).size()
			print("   %s turns %d  allies alive %d  enemies left %s" % [b.result, b.player_turns, alive_p, alive_e])
	print("team: ", tpls)
	get_tree().quit()
