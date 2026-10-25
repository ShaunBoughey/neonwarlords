extends Node
## Walks the first-session guide like a new player, screenshotting each step, then checks the
## unlock announcement:  godot --path . res://tests/Ftue.tscn -- --nwtest

const OUT := "user://shots_16/ftue/"
var main
var fails := 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(3)
	main.current._new()
	await _wait(0.6)
	var coach: Coach = main.coach
	var guard := 0
	while coach.active() and guard < 40:
		guard += 1
		await _wait(0.5)
		var st: int = coach.step()
		var s: Dictionary = Coach.STEPS[st]
		await _shot("70_ftue_%02d_%s" % [st, main._cur_name])
		if s.get("go", "") != "" and s.target == "":
			if s.get("when", "") == "finished" and not main.current.get("finished"):
				await _finish_battle()
				continue
			coach._do_go()
			continue
		var target: Control = null
		if main.current.has_method("coach_node"):
			target = main.current.coach_node(s.target)
		if target == null:
			target = coach._find(main.current, s.target)
		if target == null:
			if main._cur_name == "battle":
				await _wait(0.5)   # waiting for the player's turn
				continue
			print("FTUE: no target for step %d (%s) on %s" % [st, s.target, main._cur_name])
			fails += 1
			coach.advance()
			continue
		print("FTUE step %d: tap %s on %s" % [st, s.target, main._cur_name])
		target.pressed.emit()
		await _wait(0.4)
		if s.target == "enemy":
			await _finish_battle()
	print("FTUE done: active=%s step=%d" % [coach.active(), coach.step()])
	if coach.active():
		fails += 1
	# unlock announcement
	main.home()
	await _wait(0.4)
	Game.S.player.level = 5
	main._refresh_hud()
	await _wait(0.5)
	var announced: bool = main.overlay.get_child_count() > 0
	await _shot("79_unlock_card")
	print("unlock card shown: %s" % announced)
	if not announced:
		fails += 1
	main.close_modal()
	print("FTUE TEST DONE, failures: %d" % fails)
	get_tree().quit()

func _finish_battle() -> void:
	Game.S.settings.auto = true
	Game.S.settings.speed = 3
	var scr = main.current
	if scr.has_method("_update_toggles"):
		scr._update_toggles()
	if scr.get("waiting") and scr.get("actor") != null:
		var c = scr.b.ai_choose(scr.actor)
		scr.chosen.emit(c.ab, c.target)
	var t := 0
	while not scr.get("finished") and t < 240:
		t += 1
		await _wait(0.25)
	Game.S.settings.auto = false
	Game.S.settings.speed = 1

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
