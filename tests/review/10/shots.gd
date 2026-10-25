extends Node
## Section 10 visual QA (windowed): Pit screens, Black Market, a Pit battle.

const OUT := "user://shots_10/"
var main

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	main.current._new()
	await _frames(5)
	main.close_modal()
	Game.S.tutorial_done = true
	Game.S.player.level = 12
	Game.take_new_unlocks()
	Game.S.items.contract.rare = 12
	for i in 12:
		Game.open_contract("rare")
	Game.S.cur.pitCoin = 12000
	Game.S.pit.brawl.points = 1260
	Game.S.pit.brawl.wins = 37
	Game.S.pit.brawl.losses = 9
	Game.S.cur.brawl = 6
	var best: Array = Game.S.roster.duplicate()
	best.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	Game.S.squads.pit_royal = best.slice(0, 7).map(func(w): return w.uid)
	Game.S.pit.last_def = U.now() - 3600.0 * 16.0
	Game._simulate_pit_defense()
	main.home()
	await _frames(5)
	for mode in ["brawl", "royal"]:
		for view in ["fight", "defence", "leaderboard", "brackets"]:
			main.go("arena", {"mode": mode, "view": view})
			await _frames(5)
			await _shot("arena_%s_%s" % [mode, view])
	main.go("arena", {"mode": "brawl", "view": "leaderboard", "lb": "Gang"})
	await _frames(5)
	await _shot("arena_brawl_leaderboard_gang")
	_dump_buttons("arena_fight", "arena", {"mode": "brawl", "view": "fight"})
	main.go("black_market")
	await _frames(5)
	await _shot("bm_01")
	_dump_buttons("black_market", "black_market", {})
	main.show_rewards("Black Market", Game.bm_buy(8), main.current.rebuild)
	await _frames(5)
	await _shot("bm_02_reward_modal")
	main.close_modal()
	main.go("black_market")
	await _frames(5)
	await _shot("bm_03_after_buy")
	Game.add_item(["cache", "Substantial Cache"], 1)
	main.go("inventory")
	await _frames(5)
	await _shot("inventory_caches")
	main.show_rewards("Substantial Cache", Game.open_cache("Substantial Cache"), Callable())
	await _frames(5)
	await _shot("cache_open_modal")
	main.close_modal()
	var opps := Content.pit_opponents("royal")
	main.start_encounter(Content.build_pit("royal", opps[0]))
	await _frames(6)
	await _shot("squad_royal")
	main.go("squad", {"enc": {"mode": "defence", "pit_mode": "brawl", "title": "Pit Brawl Defence", "royal": false}})
	await _frames(6)
	await _shot("squad_defence")
	var bopps := Content.pit_opponents("brawl")
	main.start_encounter(Content.build_pit("brawl", bopps[0]))
	await _frames(6)
	await _shot("squad_brawl")
	Game.S.settings.auto = true
	Game.S.settings.speed = 3
	main.current._start()
	await get_tree().create_timer(2.5).timeout
	await _shot("battle_brawl_start")
	await get_tree().create_timer(5.0).timeout
	await _shot("battle_brawl_mid")
	var t := 0.0
	while not main.current.finished and t < 100.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	await _frames(12)
	await _shot("battle_brawl_result")
	print("pit after battle: ", Game.S.pit.brawl.points, " invites ", Game.cur("brawl"), " log ", Game.S.pit.brawl.log[0].txt)
	main.home()
	await _frames(4)
	var ropps := Content.pit_opponents("royal")
	main.start_encounter(Content.build_pit("royal", ropps[ropps.size() - 1]))
	await _frames(6)
	main.current._start()
	await get_tree().create_timer(9.0).timeout
	await _shot("battle_royal_mid")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _dump_buttons(tag: String, screen: String, params: Dictionary) -> void:
	main.go(screen, params)
	var out: Array = []
	for b in main.current.find_children("*", "BaseButton", true, false):
		var conns: int = b.pressed.get_connections().size() + b.button_down.get_connections().size() + b.gui_input.get_connections().size() + b.toggled.get_connections().size()
		out.append("%s[%s]%s" % [b.get("text") if b.get("text") != null else b.name, conns, "(disabled)" if b.disabled else ""])
	print("BUTTONS ", tag, ": ", out)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
