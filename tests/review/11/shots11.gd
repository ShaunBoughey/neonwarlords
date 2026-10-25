extends Node
## Section 11 screenshots: godot --path . res://tests/review/11/Shots11.tscn -- --nwtest  (NW_SAVE=11)

const OUT := "user://shots_11/"
var main

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	main.current._new()
	await _frames(3)
	main.close_modal()
	Game.S.tutorial_done = true
	Game.S.player.level = 45
	Game.take_new_unlocks()
	var tm: Array = []
	for id in ["deacon_chainz", "raiden_x", "issac_vaun", "pontiff_ruckus"]:
		var w := Game.add_warlord(id, true)
		w.level = 50
		w.rank = 5
		tm.append(w.uid)
	Game.S.squads.last = tm
	Game.S.stocks.stored = 52.4
	main.home()
	await _frames(6)
	await _shot("01_city_stocks_sign")
	main.current._stocks()
	await _frames(4)
	await _shot("02_stocks_modal")
	main.close_modal()
	Game.S.player.level = 10
	Game.S.stocks.stored = 0.0
	main.home()
	await _frames(4)
	main.current._stocks()
	await _frames(4)
	await _shot("03_stocks_modal_lv1_empty")
	main.close_modal()
	Game.S.player.level = 45
	for s in ["fight", "gang", "events"]:
		main.go(s)
		await _frames(5)
		await _shot("10_" + s)
	for st in [2, 3]:
		Game.S.gang.bastion.stage = st
		main.go("gang")
		await _frames(5)
		await _shot("11_gang_stage%d" % st)
	Game.S.gang.bastion.stage = 3
	main.start_encounter(Content.build_bastion(3))
	await _frames(5)
	await _shot("20_squad_bastion")
	Game.S.settings.auto = false
	main.go("battle", {"enc": Content.build_bastion(3), "team": tm, "reinf": []})
	await get_tree().create_timer(2.5).timeout
	await _shot("21_bastion_battle_start")
	Game.S.settings.auto = true
	Game.S.settings.speed = 3
	main.current._update_toggles()
	if main.current.waiting and main.current.actor != null:
		var c = main.current.b.ai_choose(main.current.actor)
		main.current.chosen.emit(c.ab, c.target)
	for i in 3:
		await get_tree().create_timer(1.5).timeout
		await _shot("22_bastion_battle_mid_%d" % i)
	var t := 0.0
	while not main.current.finished and t < 150.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	await _frames(20)
	await _shot("23_bastion_result")
	main.go("gang")
	await _frames(5)
	await _shot("24_gang_after")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
