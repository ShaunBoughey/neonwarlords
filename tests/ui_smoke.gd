extends Node
## UI smoke test: godot --headless --path . res://tests/UiSmoke.tscn -- --nwtest

var main

func _ready() -> void:
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	main.current._new()
	await _frames(3)
	main.close_modal()
	Game.S.tutorial_done = true
	# level gate: locked districts must not open at Player Level 1
	main.go("arena")
	await _frames(2)
	if main._cur_name == "arena":
		push_error("SMOKE FAIL: arena opened at Player Level 1")
	else:
		print("gate ok: arena locked at level 1")
	Game.S.player.level = 12
	for name in main.SCREENS:
		if name in ["battle", "squad", "warlord", "hideout"]:
			continue
		main.go(name)
		await _frames(2)
		if main._cur_name != name:
			push_error("SMOKE FAIL: could not open " + name)
		print("screen ok: ", name)
	main.go("hideout", {"id": "trolls"})
	await _frames(2)
	Game.grant([{"k": "gearSet", "rank": 3, "set": "Speed"}, {"k": "implantSet", "rank": 3}, {"k": "neon", "rank": 3, "n": 10}, {"k": "firmware", "lv": 1, "n": 3},
		{"k": "stimm", "r": "rare", "n": 3}, {"k": "metabolic", "align": "renegade", "tier": "minor", "n": 5}, {"k": "deeds", "align": "renegade", "tier": "minor", "n": 20},
		{"k": "deeds", "align": "generic", "tier": "minor", "n": 20}, {"k": "mf", "tier": 1, "n": 500}])
	var w: Dictionary = Game.S.roster[0]
	main.go("warlord", {"uid": w.uid})
	await _frames(2)
	var scr = main.current
	for pg in scr.PAGES:
		scr._go_page(pg)
		await _frames(1)
		print("armoury page ok: ", pg)
	scr._go_page("gear")
	scr._select_slot("boots")
	await _frames(1)
	var boots: Array = Game.S.equip.filter(func(e): return e.slot == "boots")
	scr.st.item = boots[0].uid
	scr.rebuild()
	await _frames(1)
	Game.equip_on(w, boots[0])
	scr._go_page("upgrade")
	scr.st.item = boots[0].uid
	scr._upgrade(boots[0], 3)
	scr._upgrade_to(boots[0], 5)
	await _frames(1)
	print("boots level: ", boots[0].level)
	scr._filter("Rarity")
	scr._filter("Set")
	scr._filter("Reset")
	scr._go_page("level")
	scr._open_fodder("feed")
	await _frames(1)
	var fod: Array = Game.S.roster.filter(func(x): return x.uid != w.uid and not Game.in_any_squad(x.uid))
	if not fod.is_empty():
		scr._pick_warlord(fod[0].uid, "feed")
	scr.st.meta = "renegade"
	scr.st.meta_n = 2
	scr._install_level()
	await _frames(1)
	print("after level install lv ", w.level)
	w.level = Game.max_level(w)
	scr._go_page("rank")
	scr.st.fw = w.rank
	await _frames(1)
	print("rank before ", w.rank, " -> ", Game.rank_up(w, [], w.rank), " now ", w.rank)
	scr._go_page("rep")
	await _frames(1)
	print("rep up: '", Game.rep_up(w), "' rep ", w.rep)
	scr._go_page("neuronet")
	scr.st.nn = "precision"
	scr.rebuild()
	await _frames(1)
	print("nn add: '", Game.nn_add(w, "precision"), "'")
	scr._go_page("abilities")
	scr.st.stimm = "rare"
	scr._learn()
	await _frames(1)
	scr._toggle_drawer("switch")
	await _frames(1)
	main._toggle_quicknav()
	await _frames(1)
	main._toggle_quicknav()
	print("armoury interactions ok")
	# campaign tabs
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(2)
	# a full auto battle
	Game.S.settings.auto = true
	Game.S.settings.speed = 3
	main.start_encounter(Content.build_campaign(0, 0, 0))
	await _frames(2)
	main.current._start()
	await _frames(2)
	print("in battle: ", main.current.get_meta("screen_name"))
	var t := 0.0
	while not main.current.finished and t < 120.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	print("battle finished: ", main.current.finished, " result: ", main.current.b.result, " after ", t, "s")
	# pit battle + hideout battle quick
	for enc in [Content.build_pit("brawl", Content.pit_opponents("brawl")[0]), Content.build_hideout("vikings", 1), Content.build_bastion(1)]:
		main.close_modal()
		main.replace("battle", {"enc": enc, "team": Game.S.squads.last, "reinf": []})
		t = 0.0
		while not main.current.finished and t < 200.0:
			await get_tree().create_timer(0.5).timeout
			t += 0.5
		print(enc.mode, " finished: ", main.current.finished, " result: ", main.current.b.result)
	print("UI SMOKE DONE")
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
