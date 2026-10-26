extends Node
## Armoury check for a Meshy warlord model: front (idle, facing camera) and back (cape).
## godot --path . res://tests/review/meshy/ShotsArmoury.tscn -- --nwtest   (set NW_SAVE=<tag>)
const OUT := "user://shots_meshy/"
const TPL := "deacon_chainz"
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
	var w := Game.add_warlord(TPL, true)
	main.go("warlord", {"uid": w.uid})
	await get_tree().create_timer(1.0).timeout
	await _shot("01_front_idle_a")
	await get_tree().create_timer(3.0).timeout
	await _shot("02_front_idle_b")
	var mp: ModelPreview = main.find_children("*", "ModelPreview", true, false)[0]
	mp._dragging = true          # hold the turn so it doesn't ease back to the front
	mp.spin = PI
	await get_tree().create_timer(0.5).timeout
	await _shot("03_back")
	mp.spin = PI * 0.75
	await get_tree().create_timer(0.5).timeout
	await _shot("04_back_three_quarter")
	mp._dragging = false
	await get_tree().create_timer(2.5).timeout
	await _shot("05_released_eases_front")
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
