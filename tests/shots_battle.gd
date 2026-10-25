extends Node
## Visual QA of the 3D battle: godot --path . res://tests/ShotsBattle.tscn -- --nwtest

const OUT := "user://shots/"
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
	# put Deacon Chainz in the squad as leader
	var d := Game.add_warlord("deacon_chainz", true)
	d.level = 10
	Game.S.squads.last = [d.uid] + Game.S.squads.last.slice(0, 3)
	Game.S.settings.auto = false
	Game.S.settings.speed = 1
	main.go("battle", {"enc": Content.build_campaign(0, 0, 6), "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(2.0).timeout
	await _shot("40_battle3d_start")
	Game.S.settings.auto = true
	main.current._update_toggles()
	if main.current.waiting and main.current.actor != null:
		var c = main.current.b.ai_choose(main.current.actor)
		main.current.chosen.emit(c.ab, c.target)
	for i in 6:
		await get_tree().create_timer(0.7).timeout
		await _shot("41_battle3d_action_%d" % i)
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
