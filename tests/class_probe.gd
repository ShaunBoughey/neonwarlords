extends Node
## Class balance probe: per class, an R6 L60 warlord in class-optimal legendary +20 gear.
## Prints HP, mitigation, effective HP, damage scaling, then mono-class teams vs Warlord stages
## (win rate and average player turns).  godot --headless --path . res://tests/ClassProbe.tscn -- --nwtest

const CLASSES := ["armour", "firepower", "modder", "hacker"]

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	seed(4242)
	var teams := {}
	print("class      rarity      hp      arm   mit   eHP      scale  (dmg per 1.0 mult vs 600 armour)")
	for cls in CLASSES:
		var uids: Array = []
		var ids: Array = Warlords.RECRUITABLE.filter(func(id): return Warlords.get_t(id).cls == cls and Data.rarity_idx(Warlords.get_t(id).rarity) >= 2)
		ids.sort_custom(func(x, y): return Data.rarity_idx(Warlords.get_t(x).rarity) > Data.rarity_idx(Warlords.get_t(y).rarity))
		var rar := ""
		if true:
			for id in ids.slice(0, 4):
				rar = Warlords.get_t(id).rarity
				var w := _build(id)
				uids.append(w.uid)
				var u := Battle.make_unit(w, 0)
				var b := Battle.new()
				b.setup([u], [[Battle.make_unit(Content.enemy("thug_trolls", 60, 6, 0), 1)]], {})
				var unit: Dictionary = b.units[0]
				var arm: float = b.eff(unit, "arm")
				var mit: float = min(b.MAX_MITIGATION, arm / (arm + b.ARMOUR_K))
				var sc: float = b._scaling(unit)
				var vs600: float = sc * (1.0 - 600.0 / (600.0 + b.ARMOUR_K))
				print("%-10s %-10s %6d %6d  %3d%%  %7d  %6d  %6d  %s" % [cls, rar, int(unit.max_hp), int(arm), int(mit * 100), int(unit.max_hp / (1.0 - mit)), int(sc), int(vs600), id])
		teams[cls] = uids.slice(0, 4)
	print("== mono-class teams (4) vs Warlord stages: win%% / avg player turns, power")
	for cls in CLASSES:
		var row := "%-10s n%d power %s " % [cls, teams[cls].size(), U.fmt(Game.team_power(teams[cls]))]
		for st in [[2, 4, 6], [2, 9, 0], [2, 9, 6]]:
			var wins := 0
			var turns := 0
			for i in 6:
				var r := _sim(teams[cls], Content.build_campaign(st[0], st[1], st[2]))
				wins += 1 if r[0] == "win" else 0
				turns += r[1]
			row += "  W%d-%d: %d%% %dt" % [st[1] + 1, st[2] + 1, int(wins * 100.0 / 6), turns / 6]
		print(row)
	get_tree().quit()

func _build(id: String) -> Dictionary:
	var w := Game.add_warlord(id, true)
	w.rank = 6
	w.level = 60
	w.rep = 6
	for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
		for k in 3:
			var it := Game.make_equipment(slot, 6, "legendary")
			for lv in 20:
				Game.equip_level_up(it, true)
			Game.S.equip.append(it)
	Game.auto_equip(w)
	return w

func _sim(team: Array, enc: Dictionary) -> Array:
	var b := Battle.new()
	var waves: Array = []
	for wv in enc.waves:
		waves.append(wv.map(func(u): return u.duplicate(true)))
	b.setup(Content.player_units(team), waves, {"turn_limit": 0})
	b.simulate()
	return [b.result, b.player_turns]
