extends Node
## Review 09: Syndicate Wars screenshots. Windowed run, NW_SAVE=09.

const OUT := "user://shots_09/"
var main

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	Game.reset_save()
	Game.new_game("Review09")
	Game.S.tutorial_done = true
	Game.S.player.level = 12
	Game.take_new_unlocks()
	Game.S.items.contract.rare = 16
	for i in 16:
		Game.open_contract("rare")
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _frames(5)
	main.close_modal()
	main.home()
	await _frames(5)
	main.go("sw")
	await _frames(6)
	await _shot("01_sw_select")
	# pick the syndicate with most owned warlords
	var best := ""
	var bn := -1
	for s in Data.SYNDICATES:
		var n: int = Game.S.roster.filter(func(w): return Game.tpl(w).syn == s).size()
		if n > bn:
			bn = n
			best = s
	print("best syn ", best, " owned ", bn)
	for st in range(1, 7):
		Game.sw_record(best, st, 3 if st < 5 else 2)
	main.go("sw", {"syn": best})
	await _frames(6)
	await _shot("02_sw_stages")
	# claim progress reward
	main.show_rewards("Syndicate Wars", Game.claim_sw_progress(15), Callable())
	await get_tree().create_timer(1.2).timeout
	await _shot("03_sw_claim")
	main.close_modal()
	main.go("sw", {"syn": best})
	await _frames(6)
	await _shot("04_sw_stages_after_claim")
	for sc in main.current.find_children("*", "ScrollContainer", true, false):
		sc.scroll_vertical = 10000
	await _frames(6)
	await _shot("04b_sw_stages_scrolled")
	print("QUIT_EARLY")
	get_tree().quit()
	return
	# empty syndicate
	var worst := ""
	for s in Data.SYNDICATES:
		if Game.S.roster.filter(func(w): return Game.tpl(w).syn == s).size() == 0:
			worst = s
	if worst != "":
		main.go("squad", {"enc": Content.build_sw(worst, 1)})
		await _frames(6)
		await _shot("05_squad_empty_syndicate")
	main.go("squad", {"enc": Content.build_sw(best, 7)})
	await _frames(6)
	await _shot("06_squad_sw")
	Game.S.settings.auto = false
	main.current._start()
	await get_tree().create_timer(2.5).timeout
	await _shot("07_battle_start")
	Game.S.settings.auto = true
	main.current._toggle_auto()
	main.current._toggle_auto()
	await get_tree().create_timer(4.0).timeout
	await _shot("08_battle_mid")
	var t := 0.0
	while not main.current.finished and t < 90.0:
		await get_tree().create_timer(0.5).timeout
		t += 0.5
	await _frames(10)
	await _shot("09_result")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
