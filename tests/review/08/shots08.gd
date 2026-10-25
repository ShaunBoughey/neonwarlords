extends Node
## Section 08 visual QA. Windowed:
##   NW_SAVE=08 godot --path . res://tests/review/08/Shots08.tscn -- --nwtest

const OUT := "user://shots_08/"
const IDS := ["synapse", "heist", "chopshop", "deeds_paragon", "deeds_neutral", "deeds_renegade", "deeds_generic"]
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
	Game.S.player.level = 40
	Game.take_new_unlocks()
	Game.S.items.contract.rare = 12
	for i in 12:
		Game.open_contract("rare")
	main.close_modal()
	main.home()
	await _frames(4)
	main.go("fight")
	await _frames(4)
	await _shot("00_fight_heist_plans")
	for id in IDS:
		main.go("hideouts", {"id": id})
		await _frames(4)
		await _shot("10_%s_s1" % id)
	# unlock all stages, show late stages (page 2)
	for id in IDS:
		Game.hideout_state(id).max = 19
	for id in ["synapse", "heist", "chopshop", "deeds_generic"]:
		main.go("hideouts", {"id": id, "stage": 14})
		await _frames(4)
		await _shot("11_%s_s14" % id)
	main.go("hideouts", {"id": "deeds_paragon", "stage": 4})
	await _frames(4)
	await _shot("12_deeds_paragon_s4")
	# intel modal
	main.go("hideouts", {"id": "heist", "stage": 1})
	await _frames(4)
	main.current._intel(Content.build_hideout("heist", 1))
	await get_tree().create_timer(1.0).timeout
	await _shot("13_heist_intel")
	main.close_modal()
	if OS.get_environment("NW08_QUICK") != "":
		get_tree().quit()
		return
	# heist with zero plans -> squad -> start should be refused
	Game.S.cur.heist = 0
	main.go("hideouts", {"id": "heist", "stage": 1})
	await _frames(4)
	await _shot("14_heist_zero_plans")
	main.start_encounter(Content.build_hideout("heist", 1))
	await _frames(4)
	await _shot("15_heist_squad_zero_plans")
	main.current._start()
	await _frames(4)
	await _shot("16_heist_squad_refused")
	print("BUTTON-CHECK heist start with 0 plans -> screen=", main.current.get_script().resource_path)
	Game.S.cur.heist = 5
	# battles: synapse and heist, then forced victory screens
	for id in ["heist", "synapse", "chopshop", "deeds_renegade"]:
		main.start_encounter(Content.build_hideout(id, 3))
		await _frames(4)
		await _shot("20_%s_squad" % id)
		main.current._start()
		await get_tree().create_timer(2.5).timeout
		await _shot("21_%s_battle_wave1" % id)
		var bt = main.current
		if "b" in bt and bt.b != null:
			bt.b.result = "win"
			bt._finish()
			await get_tree().create_timer(1.5).timeout
			await _shot("22_%s_victory" % id)
	print("PLANS after heist battle: ", Game.cur("heist"))
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
