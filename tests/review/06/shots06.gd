extends Node
## Review 06 visual QA (City + Campaign). Windowed:
##   NW_SAVE=06 godot --path . res://tests/review/06/Shots06.tscn -- --nwtest

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
	Game.S.items.contract.rare = 8
	for i in 8:
		Game.open_contract("rare")
	main.home()
	await _frames(8)
	await _shot("01_city")
	# fresh campaign: den 1, only 1:1 open
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(10)
	await _shot("02_campaign_slums_fresh")
	# progress: d0 dens 1-4 cleared with mixed stars, den 5 partway
	for loc in 4:
		for st in 7:
			Game.campaign_record(0, loc, st, 3 if (st + loc) % 3 else 2)
	for st in 3:
		Game.campaign_record(0, 4, st, 3)
	main.go("campaign", {"d": 0, "loc": 4})
	await _frames(10)
	await _shot("03_campaign_chem_partial")
	main.go("campaign", {"d": 0, "loc": 3, "st": 6})
	await _frames(10)
	await _shot("04_campaign_industrial_boss_sheet")
	main.go("campaign", {"d": 0, "loc": 1, "st": 2})
	await _frames(10)
	await _shot("05_campaign_sewers_stage_done")
	# difficulty lock toast
	main.current.params.d = 1
	main.go("campaign", {"d": 0, "loc": 0})
	await _frames(6)
	main.current._rewards()
	await _frames(6)
	await _shot("06_progress_rewards_modal")
	main.close_modal()
	# clear everything on d0 to open Mob Boss and show Corpo Tower
	for loc in 10:
		for st in 7:
			Game.campaign_record(0, loc, st, 3)
	main.go("campaign", {"d": 0, "loc": 9, "st": 6})
	await _frames(10)
	await _shot("07_campaign_corpo_boss_d0")
	main.go("campaign", {"d": 1, "loc": 0})
	await _frames(10)
	await _shot("08_campaign_slums_mobboss")
	main.go("campaign", {"d": 0, "loc": 6, "st": 3})
	await _frames(10)
	await _shot("09_campaign_skystreet")
	# squad screen from the sheet CTA
	main.start_encounter(Content.build_campaign(0, 0, 2))
	await _frames(10)
	await _shot("10_squad_campaign")
	# battles in several locations
	Game.S.settings.auto = false
	Game.S.settings.speed = 1
	for spec in [[0, 0, 2], [0, 4, 6], [0, 6, 1], [1, 9, 6]]:
		main.go("battle", {"enc": Content.build_campaign(spec[0], spec[1], spec[2]), "team": Game.S.squads.last, "reinf": []})
		await get_tree().create_timer(2.5).timeout
		await _shot("20_battle_d%d_%d-%d" % [spec[0], spec[1] + 1, spec[2] + 1])
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
