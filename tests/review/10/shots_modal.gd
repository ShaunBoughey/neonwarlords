extends Node
## Section 10: reward modals after their fade-in.

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
	Game.S.cur.pitCoin = 12000
	main.go("black_market")
	await _frames(5)
	main.show_rewards("Black Market", Game.bm_buy(11), main.current.rebuild)
	await get_tree().create_timer(2.0).timeout
	await _shot("bm_02_reward_modal_settled")
	main.close_modal()
	Game.add_item(["cache", "Sublime Cache"], 1)
	main.go("inventory")
	await _frames(5)
	main.show_rewards("Sublime Cache", Game.open_cache("Sublime Cache"), Callable())
	await get_tree().create_timer(2.5).timeout
	await _shot("cache_open_modal_settled")
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
