extends Node
## Visual QA of every signature skill effect:  godot --path . res://tests/ShotsVfx.tscn -- --nwtest

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
	main.go("battle", {"enc": Content.build_campaign(0, 0, 0), "team": Game.S.squads.last, "reinf": []})
	await get_tree().create_timer(1.8).timeout
	var t := 0
	while not main.current.waiting and t < 80:
		t += 1
		await get_tree().create_timer(0.25).timeout
	var view: BattleView3D = main.current.view
	var allies: Array = []
	var foes: Array = []
	for uid in view.actors:
		(allies if view.actors[uid].side == 0 else foes).append(uid)
	var caster: String = allies[0]
	var i := 0
	for kind in ["orbital", "holy", "shockwave", "chain", "flurry", "lightning", "toxic", "beam", "slash"]:
		var targets: Array = foes if kind in ["orbital", "holy", "shockwave", "chain"] else [foes[0]]
		view.signature_attack(kind, caster, targets, UI.MAGENTA if i % 2 else UI.CYAN)
		await get_tree().create_timer({"slash": 0.62, "toxic": 0.62, "flurry": 0.3, "lightning": 0.32, "beam": 0.45}.get(kind, 0.5)).timeout
		await _shot("80_vfx_%d_%s" % [i, kind])
		await get_tree().create_timer(1.2).timeout
		i += 1
	for kind in ["heal", "shield", "empower", "hex"]:
		var targets: Array = allies if kind != "hex" else foes
		view.signature_support(kind, allies[1], targets, UI.GREEN)
		await get_tree().create_timer(0.55).timeout
		await _shot("80_vfx_%d_%s" % [i, kind])
		await get_tree().create_timer(1.0).timeout
		i += 1
	print("SHOTS IN: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()

func _frames(n: int) -> void:
	for k in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
