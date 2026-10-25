extends Node
## Visual QA: saves screenshots of key screens. Run windowed:
##   godot --path . res://tests/Shots.tscn -- --nwtest

const OUT := "user://shots/"
var main

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	await _shot("01_login")
	main.current._new()
	await _frames(5)
	await _shot("02_tutorial")
	main.close_modal()
	Game.S.tutorial_done = true
	Game.S.player.level = 12
	Game.take_new_unlocks()
	Game.S.items.contract.rare = 12
	for i in 12:
		Game.open_contract("rare")
	Game.grant([{"k": "gearSet", "rank": 4, "set": "Speed", "r": "epic"}, {"k": "implantSet", "rank": 4}, {"k": "neon", "rank": 4, "n": 6}])
	main.home()
	await _frames(5)
	await _shot("03_city")
	for s in ["fight", "campaign", "hideouts", "sw", "arena", "armory", "recruit", "black_market", "safehouse", "missions", "battle_pass", "shop", "login_rewards", "gang"]:
		main.go(s)
		await _frames(4)
		await _shot("10_" + s)
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(4)
	await _shot("11_campaign_stages")
	main.go("hideout", {"id": "vikings"})
	await _frames(4)
	await _shot("12_hideout_vikings")
	var w: Dictionary = Game.S.roster[0]
	for slot in Data.GEAR_SLOTS:
		for it in Game.S.equip:
			if it.slot == slot and it.owner == "":
				Game.equip_on(w, it)
				break
	Game.grant([{"k": "neon", "rank": 4, "n": 10}, {"k": "firmware", "lv": 1, "n": 3}, {"k": "stimm", "r": "rare", "n": 3}, {"k": "metabolic", "align": "renegade", "tier": "minor", "n": 5},
		{"k": "deeds", "align": "renegade", "tier": "minor", "n": 7}, {"k": "deeds", "align": "generic", "tier": "minor", "n": 2}, {"k": "mf", "tier": 1, "n": 300}])
	main.go("warlord", {"uid": w.uid})
	await _frames(4)
	for pg in main.current.PAGES:
		main.current._go_page(pg)
		await _frames(4)
		await _shot("20_armoury_" + pg)
	main.current._go_page("gear")
	main.current._select_slot("boots")
	await _frames(4)
	await _shot("21_armoury_gear_modal_drawer")
	main.current._go_page("neuronet")
	main.current.st.nn = "precision"
	main.current.rebuild()
	await _frames(4)
	await _shot("22_armoury_nn_modal")
	main.current._go_page("abilities")
	await _frames(4)
	main.current._toggle_drawer("switch")
	await _frames(4)
	await _shot("23_armoury_switch_drawer")
	main.home()
	await _frames(4)
	main._toggle_quicknav()
	await _frames(4)
	await _shot("24_quicknav")
	main._toggle_quicknav()
	main.go("armory")
	await _frames(4)
	await _shot("25_armory_roster")
	main.go("squad", {"enc": Content.build_campaign(0, 0, 0)})
	await _frames(4)
	await _shot("30_squad")
	Game.S.settings.auto = false
	main.current._start()
	await get_tree().create_timer(2.5).timeout
	await _shot("31_battle_start")
	Game.S.settings.auto = true
	main.current._toggle_auto()
	main.current._toggle_auto()
	await get_tree().create_timer(4.0).timeout
	await _shot("32_battle_mid")
	var t := 0.0
	while not main.current.finished and t < 90.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	await _frames(10)
	await _shot("33_result")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
