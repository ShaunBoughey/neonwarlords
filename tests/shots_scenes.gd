extends Node
## Visual QA of the per-location battle backdrops:
## godot --path . res://tests/ShotsScenes.tscn -- --nwtest

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
	Game.S.settings.auto = false
	var encs := {
		"50_scene_campaign_slums": Content.build_campaign(0, 0, 0),
		"51_scene_campaign_den5": Content.build_campaign(0, 4, 0),
		"52_scene_trolls_chapel": Content.build_hideout("trolls", 1),
		"53_scene_vultures_scrap": Content.build_hideout("vultures", 1),
		"54_scene_teratek_corp": Content.build_hideout("teratek", 1),
		"55_scene_vikings_hall": Content.build_hideout("vikings", 1),
		"56_scene_synapse_server": Content.build_hideout("synapse", 1),
		"57_scene_heist_vault": Content.build_hideout("heist", 1),
		"58_scene_chopshop_clinic": Content.build_hideout("chopshop", 1),
		"59_scene_deeds_temple": Content.build_hideout("deeds_paragon", 1),
		"60_scene_bastion": Content.build_bastion(0),
	}
	for k in encs:
		main.go("battle", {"enc": encs[k], "team": Game.S.squads.last, "reinf": []})
		await get_tree().create_timer(1.6).timeout
		await _shot(k)
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
