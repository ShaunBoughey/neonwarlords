extends Node
func _ready() -> void:
	var m = load("res://scenes/Main.tscn").instantiate()
	get_tree().root.add_child.call_deferred(m)
	for i in 10:
		await get_tree().process_frame
	Game.S.player.level = 30
	for r in [["city", {}], ["campaign", {}], ["arena", {}], ["arena", {"mode": "royal", "view": "brackets"}], ["sw", {}], ["hideout", {"id": "trolls"}], ["campaign", {"d": 0}], ["shop", {"sec": "Trinium Market"}], ["shop", {}], ["battle_pass", {}], ["gang", {}], ["missions", {}], ["account", {}], ["hideouts", {}]]:
		m.go(r[0], r[1])
		for i in 3:
			await get_tree().process_frame
		print("built ", r[0])
	CacheInfo.show(m, "Exalted")
	print(CacheInfo.text("Meager Cache"))
	m.call("_close", m.overlay.get_child(m.overlay.get_child_count() - 1))
	var camp = m.get("cur") if m.get("cur") else null
	print("PROBE DONE")
	get_tree().quit()
