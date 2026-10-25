extends Node
## Wave 2: squad.gd must pass enc.repeat to the battle untouched.

func _ready() -> void:
	Game.reset_save()
	var main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	for i in 5: await get_tree().process_frame
	main.current._new()
	for i in 5: await get_tree().process_frame
	main.close_modal()
	Game.S.tutorial_done = true
	var e: Dictionary = Content.build_campaign(0, 0, 0)
	e.repeat = 10
	main.start_encounter(e)
	for i in 3: await get_tree().process_frame
	print("REPEAT squad screen: ", main.current.enc.get("repeat", "missing"))
	main.current._start()
	for i in 3: await get_tree().process_frame
	print("REPEAT battle screen: ", main._cur_name, " ", main.current.params.enc.get("repeat", "missing"))
	get_tree().quit()
