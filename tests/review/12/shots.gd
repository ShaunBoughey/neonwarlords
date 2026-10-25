extends Node
## Section 12 screenshots. NW_SAVE=12 godot --path . res://tests/review/12/Shots.tscn -- --nwtest

const OUT := "user://shots_12/"
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
	Game.S.player.level = 3
	Game.S.player.xp = 200
	Game.take_new_unlocks()
	main.home()
	await _frames(6)
	await _shot("01_city_topbar_lv3")
	# level-up 3 -> 4 by spending energy (unlocks plaza + black market together)
	Game.spend("energy", 60)
	await _frames(3)
	await _shot("02_levelup_toast")
	main._refresh_hud()
	await _frames(6)
	await _shot("03_unlock_modal_lv4")
	main.close_modal()
	await _frames(3)
	main._refresh_hud()
	await _frames(6)
	await _shot("04_after_close_lv4")
	# straight to 10 (arena + safehouse)
	Game.S.player.level = 9
	Game.S.player.xp = 0
	Game.add_pxp(600)
	main._refresh_hud()
	await _frames(6)
	await _shot("05_unlock_modal_lv10")
	main.close_modal()
	main._refresh_hud()
	await _frames(6)
	await _shot("06_after_close_lv10")
	Game.S.player.level = 12
	Game.take_new_unlocks()
	main.close_modal()
	# recruit
	Game.S.items.contract.uncommon = 12
	Game.S.items.contract.rare = 11
	Game.S.items.contract.epic = 1
	Game.S.items.scrap.rare = 7
	main.go("recruit")
	await _frames(6)
	await _shot("10_recruit_rare")
	main.current.params.sel = "legendary"
	main.current.rebuild()
	await _frames(6)
	await _shot("11_recruit_legendary_none")
	main.current.params.sel = "rare"
	main.current.rebuild()
	await _frames(4)
	main.current._open(1)
	await get_tree().create_timer(2.6).timeout
	await _shot("12_recruit_open1_reveal")
	main.current.rebuild()
	await _frames(4)
	main.current._open(10)
	await get_tree().create_timer(2.6).timeout
	await _shot("13_recruit_open10_reveal")
	main.close_modal()
	# arena top bar with pit coin
	Game.add_cur("pitCoin", 1234)
	main.go("arena")
	await _frames(6)
	await _shot("20_arena_topbar")
	main.go("account")
	await _frames(6)
	await _shot("21_account")
	# level cap
	Game.S.player.level = 100
	Game.S.player.xp = 0
	Game.add_pxp(30500)
	main.home()
	await _frames(6)
	await _shot("30_city_lv_after_100")
	main.go("inbox")
	await _frames(6)
	await _shot("31_inbox_levelmails")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT + name + ".png")
