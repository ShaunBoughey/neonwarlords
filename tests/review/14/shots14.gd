extends Node
## Review 14: Gang + Plaza screenshots and button probe.
const OUT := "user://shots_14/"
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
	# locked state first (level 1)
	main.home()
	await _frames(4)
	main.go("gang")
	await _frames(4)
	await _shot("00_gang_locked_lv1")
	print("LOCKED gang -> current=", main.current.get_script().resource_path if main.current else "null")
	main.close_modal()
	Game.S.player.level = 12
	Game.take_new_unlocks()
	main.home()
	await _frames(4)
	main.close_modal()
	main.go("gang")
	await _frames(4)
	await _shot("01_gang")
	_buttons("gang")
	main.current._rename()
	await _frames(4)
	await _shot("02_gang_rename_modal")
	main.close_modal()
	main.go("plaza")
	await _frames(4)
	await _shot("03_plaza_start_credits")
	_buttons("plaza")
	print("credits=", Game.cur("credits"), " items=", JSON.stringify(Game.S.plaza.items))
	Game.add_cur("credits", 5000000)
	main.current.rebuild()
	await _frames(4)
	await _shot("04_plaza_rich")
	var before := Game.cur("credits")
	main.show_rewards("The Plaza", Game.plaza_buy(0), main.current.rebuild)
	await _frames(4)
	await _shot("05_plaza_bought_modal")
	print("spent=", before - Game.cur("credits"), " bought=", Game.S.plaza.bought, " job plazaBuy=", Game.S.jobs.c.daily)
	main.close_modal()
	main.current.rebuild()
	await _frames(4)
	await _shot("06_plaza_sold")
	print("rebuy returns=", Game.plaza_buy(0))
	# hour rollover
	Game.S.plaza.hour = -5
	var it2 := Game.plaza_items()
	print("after reroll bought=", Game.S.plaza.bought, " n=", it2.size())
	# events card and nav
	main.go("events")
	await _frames(4)
	await _shot("07_events")
	main.go("gang")
	await _frames(4)
	var atk = _find_btn(main.current, "ATTACK")
	if atk:
		atk.pressed.emit()
		await _frames(4)
		await _shot("08_gang_attack_pressed")
		print("ATTACK -> ", main.current.get_script().resource_path)
	get_tree().quit()

func _find_btn(n: Node, prefix: String) -> Button:
	for c in n.get_children():
		if c is Button and String(c.text).begins_with(prefix):
			return c
		var r = _find_btn(c, prefix)
		if r: return r
	return null

func _buttons(tag: String) -> void:
	var out: Array = []
	_collect(main, out)
	print("BUTTONS[", tag, "] ", out)

func _collect(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is Button and c.is_visible_in_tree():
			out.append("%s%s" % [c.text if c.text != "" else ("<" + c.name + ">"), " (disabled)" if c.disabled else ""])
		_collect(c, out)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + name + ".png")
