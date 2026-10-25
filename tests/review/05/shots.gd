extends Node
## GDD 05 visual QA: NW_SAVE=05 godot --path . res://tests/review/05/Shots.tscn -- --nwtest

const OUT := "user://shots_05/"
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
	var d := Game.add_warlord("deacon_chainz", true)
	d.level = 10
	Game.S.squads.last = [d.uid] + Game.S.squads.last.slice(0, 3)
	Game.S.settings.auto = false
	Game.S.settings.speed = 1
	main.go("battle", {"enc": Content.build_campaign(0, 0, 6), "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(2.5).timeout
	await _shot("01_start_manual")
	var bs = main.current
	# pick the second skill if there is one, to show targeting
	var hexes: Array = bs.skill_bar.get_children()
	if hexes.size() > 1 and not hexes[1].disabled:
		hexes[1].pressed.emit()
		await _frames(4)
		await _shot("02_skill_selected")
	Game.S.settings.auto = true
	bs._update_toggles()
	if bs.waiting and bs.actor != null:
		var c = bs.b.ai_choose(bs.actor)
		bs.chosen.emit(c.ab, c.target)
	for i in 8:
		await get_tree().create_timer(0.9).timeout
		await _shot("03_action_%d" % i)
	# wait for status effects to accumulate
	await get_tree().create_timer(6.0).timeout
	await _shot("04_midfight")
	# force a victory screen
	if not bs.finished:
		for u in bs.b.side_units(1):
			u.alive = false
		bs.b.result = "win"
		bs._finish()
	await get_tree().create_timer(2.0).timeout
	await _shot("05_victory")
	# defeat screen via the menu's Flee
	Game.S.settings.auto = false
	main.go("battle", {"enc": Content.build_campaign(0, 0, 3), "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(2.5).timeout
	main.current._menu()
	await _frames(4)
	await _shot("06_menu")
	main.close_modal()
	main.current._flee()
	await get_tree().create_timer(2.5).timeout
	await _shot("07_defeat")
	# Bastion: boss panel, then its result
	Game.S.settings.auto = true
	main.go("battle", {"enc": Content.build_bastion(1), "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(5.0).timeout
	await _shot("08_bastion")
	var bb = main.current
	if not bb.finished:
		bb.b.result = "timeout"
		bb._finish()
	await get_tree().create_timer(2.0).timeout
	await _shot("09_bastion_result")
	# a later campaign location (prop set per location)
	main.go("battle", {"enc": Content.build_campaign(0, 3, 0), "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(2.5).timeout
	await _shot("10_industrial")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
