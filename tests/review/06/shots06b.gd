extends Node
## Review 06 visual QA, pass 2: rewards modal (settled), City without guide, Fight menu, den-switch buttons.
const OUT := "user://shots_06/"
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
	Game.S.player.level = 30
	Game.take_new_unlocks()
	for k in Game.S.keys():
		if String(k).begins_with("coach"):
			print("coach key ", k)
	if Game.S.has("coach"):
		Game.S.coach = {"done": true}
	for loc in 10:
		for st in 7:
			Game.campaign_record(0, loc, st, 3 if (st + loc) % 4 else 2)
	main.home()
	await get_tree().create_timer(1.0).timeout
	await _shot("30_city_progressed")
	main.go("fight")
	await get_tree().create_timer(0.8).timeout
	await _shot("31_fight_menu")
	main.go("campaign", {"d": 0, "loc": 2})
	await get_tree().create_timer(0.8).timeout
	main.current._rewards()
	await get_tree().create_timer(1.2).timeout
	await _shot("32_rewards_modal")
	main.close_modal()
	await _frames(4)
	main.current._den(3)
	await get_tree().create_timer(0.8).timeout
	await _shot("33_den_next_pressed")
	print("title after next: ", main.current.screen_title)
	# Warlord tab locked (Mob Boss not cleared)
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(6)
	print("warlord unlocked? ", Game.campaign_unlocked(2, 0, 0))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
