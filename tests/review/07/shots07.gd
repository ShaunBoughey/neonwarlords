extends Node
## Section 07 screenshots (windowed):
##   NW_SAVE=07 godot --path . res://tests/review/07/Shots07.tscn -- --nwtest

const OUT := "user://shots_07/"
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
	Game.S.player.level = 12
	Game.take_new_unlocks()
	var uids: Array = []
	var n := 0
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and n < 4:
			var w := Game.add_warlord(id, true)
			w.rank = 5; w.level = Data.max_level(5); w.rep = 5
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, 5, "epic")
				it.level = 12
				Game.S.equip.append(it)
				Game.equip_on(w, it)
			uids.append(w.uid); n += 1
	Game.S.squads.last = uids
	Game.hideout_state("trolls").max = 14
	Game.hideout_state("trolls").wins = {"1": 2, "5": 1, "14": 1}
	main.home()
	await _frames(4)
	main.go("hideouts")
	await _frames(5)
	await _shot("01_hideouts_default")
	for hid in ["trolls", "vultures", "teratek", "vikings"]:
		main.go("hideout", {"id": hid})
		await _frames(5)
		await _shot("02_hideout_" + hid)
	main.go("hideout", {"id": "trolls", "stage": 15, "page": 1})
	await _frames(5)
	await _shot("03_trolls_stage15_page2")
	main.current._intel(Content.build_hideout("trolls", 15))
	await _frames(5)
	await _shot("04_trolls_intel")
	main.close_modal()
	main.go("hideout", {"id": "vikings"})
	await _frames(4)
	main.current._intel(Content.build_hideout("vikings", 1))
	await _frames(5)
	await _shot("05_vikings_intel")
	main.close_modal()
	for hid in ["synapse", "chopshop", "deeds_paragon"]:
		Game.hideout_state(hid).max = 3
		main.go("hideout", {"id": hid, "stage": 4})
		await _frames(5)
		await _shot("07_drops_" + hid)
	Game.S.cur.heist = 0
	main.go("hideout", {"id": "heist"})
	await _frames(5)
	await _shot("08_heist_zero_plans")
	Game.S.cur.heist = 5
	main.start_encounter(Content.build_hideout("trolls", 1))
	await _frames(5)
	await _shot("06_squad_trolls")
	# boss wave battles (wave 1 removed so the boss is on screen quickly)
	Game.S.settings.auto = false
	Game.S.settings.speed = 1
	for hid in ["trolls", "vikings"]:
		var enc := Content.build_hideout(hid, 3)
		main.go("battle", {"enc": enc, "team": uids, "reinf": []})
		await get_tree().create_timer(2.5).timeout
		await _shot("10_battle_%s_wave1" % hid)
		var enc2 := Content.build_hideout(hid, 3)
		enc2.waves = [enc2.waves[1]]
		main.go("battle", {"enc": enc2, "team": uids, "reinf": []})
		await get_tree().create_timer(2.5).timeout
		await _shot("11_battle_%s_boss" % hid)
		Game.S.settings.auto = true
		main.current._update_toggles()
		if main.current.waiting and main.current.actor != null:
			var c = main.current.b.ai_choose(main.current.actor)
			main.current.chosen.emit(c.ab, c.target)
		for i in 3:
			await get_tree().create_timer(1.5).timeout
			await _shot("12_battle_%s_boss_auto_%d" % [hid, i])
		Game.S.settings.auto = false
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
