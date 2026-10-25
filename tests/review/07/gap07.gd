extends Node
## Trolls vs Vikings difficulty gap probe.
##   NW_SAVE=07 godot --headless --path . res://tests/review/07/Gap07.tscn -- --nwtest

var teams: Array = []

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Gap07")
	var epics: Array = Warlords.RECRUITABLE.filter(func(id): return Warlords.get_t(id).rarity == "epic")
	print("epics: ", epics)
	for c in [[0, 1, 2, 3], [4, 5, 6, 7], [1, 3, 5, 7]]:
		var uids: Array = []
		for i in c:
			var w := Game.add_warlord(epics[i % epics.size()], true)
			w.rank = 5; w.level = 50; w.rep = 5
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, 5, "epic")
				it.level = 16
				Game.S.equip.append(it)
				Game.equip_on(w, it)
			uids.append(w.uid)
		teams.append(uids)
		print("team %s power %s" % [c.map(func(i): return epics[i % epics.size()]), U.fmt(Game.team_power(uids))])
	for hid in ["trolls", "vikings", "vultures", "teratek"]:
		for st in [8, 12, 16, 20]:
			var line := "%-8s st%-2d" % [hid, st]
			for variant in ["base", "fixed"] + (["noReflect", "fixed+noReflect"] if hid == "trolls" else []):
				var wins := 0; var n := 0; var refl := 0.0; var total := 0.0; var turns := 0
				for team in teams:
					for i in 6:
						var r := _sim(team, hid, st, variant)
						wins += 1 if r[0] == "win" else 0
						refl += r[1]; total += r[2]; turns += r[3]; n += 1
				line += "  %s %3d%% (refl %2d%% of dmg taken, %dt)" % [variant, wins * 100 / n, int(refl * 100.0 / max(1.0, total)), turns / n]
			print(line)
	# enemy stat comparison at stage 12
	for hid in ["trolls", "vikings"]:
		var enc := Content.build_hideout(hid, 12)
		var tot_hp := 0.0
		for wv in enc.waves:
			for u in wv:
				tot_hp += u.base.hp
		print("%s st12 enc_power %s total enemy HP %d boss: %s" % [hid, U.fmt(Content.enc_power(enc)), int(tot_hp), enc.waves[1].map(func(u): return "%s hp%d arm%d fp%d spd%d" % [u.tpl, int(u.base.hp), int(u.base.arm), int(u.base.fp), int(u.base.spd)])])
	get_tree().quit()

func _sim(team: Array, hid: String, st: int, variant: String) -> Array:
	var enc := Content.build_hideout(hid, st)
	var waves: Array = []
	for wv in enc.waves:
		waves.append(wv.map(func(u): return u.duplicate(true)))
	if variant.begins_with("fixed"):
		if hid == "vikings":
			var extra = Content.enemy_unit("raider", Content.hideout_level(st)[0], Content.hideout_level(st)[1], Content.hideout_level(st)[2])
			waves[1].append(extra)
		for u in waves[1]:
			if u.boss:
				u.immune.append_array(Warlords.IMMUNE_BOSS_TM if hid in ["vultures", "vikings"] else Warlords.IMMUNE_BOSS)
	if variant.ends_with("noReflect"):
		for u in waves[1]:
			u.specials.erase("divine_retribution")
	var b := Battle.new()
	var w1: Array = waves[0]
	b.setup(Content.player_units(team), waves, {})
	if variant.begins_with("fixed"):
		for u in w1:
			u.debuffs.append({"id": "blockRevive", "v": 0, "turns": 9999, "src": ""})   # emulate Ragnarok reviving raiders only
	b.simulate()
	var refl := 0.0; var total := 0.0; var pending := {}
	for e in b.events:
		if e.e == "text" and e.t == "reflect":
			pending[e.u] = true
		elif e.e == "dmg":
			var u = b.unit(e.u)
			if u != null and u.side == 0:
				total += e.v
				if pending.get(e.u, false):
					refl += e.v
			pending.erase(e.u)
	return [b.result, refl, total, b.player_turns]
