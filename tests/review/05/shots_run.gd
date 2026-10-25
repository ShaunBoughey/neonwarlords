extends Node
## Wave 2 AUTO x10 check: NW_SAVE=05 godot --path . res://tests/review/05/ShotsRun.tscn -- --nwtest

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
	d.level = 30
	Game.S.squads.last = [d.uid] + Game.S.squads.last.slice(0, 3)
	Game.S.settings.auto = false
	Game.S.settings.speed = 3
	var energy0 := Game.cur("energy")
	var e := Content.build_campaign(0, 0, 0)
	e.repeat = 3
	Game.pay(Content.enc_cost(e))
	main.go("battle", {"enc": e, "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(2.0).timeout
	await _shot("20_run_battle1")
	var seen := {}
	var t := 0.0
	while t < 120.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
		var bs = main.current
		if bs.get("run") == null or bs.run.is_empty():
			continue
		var n := int(bs.run.n)
		if not seen.has("b%d" % n) and not bs.finished:
			seen["b%d" % n] = true
			if n == 2:
				await _shot("21_run_battle2")
		if bs.finished and not seen.has("r%d" % n):
			seen["r%d" % n] = true
			await get_tree().create_timer(0.6).timeout
			await _shot("22_run_result_%d" % n)
			if bs.run.stopped or n >= int(bs.run.total) or bs.b.result != "win":
				break
	var bs2 = main.current
	print("RUN n=%d wins=%d stopped=%s auto_after=%s energy %d -> %d items=%d" % [bs2.run.n, bs2.run.wins, bs2.run.stopped, Game.S.settings.auto, energy0, Game.cur("energy"), bs2.run.items.size()])
	# STOP during a run
	var e2 := Content.build_campaign(0, 0, 0)
	e2.repeat = 10
	Game.pay(Content.enc_cost(e2))
	main.go("battle", {"enc": e2, "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(1.5).timeout
	main.current._stop_run()
	t = 0.0
	while not main.current.finished and t < 60.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	await get_tree().create_timer(2.5).timeout
	await _shot("23_run_stopped")
	print("STOP n=%d stopped=%s current_is_same=%s auto_after=%s" % [main.current.run.n, main.current.run.stopped, main.current.finished, Game.S.settings.auto])
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
