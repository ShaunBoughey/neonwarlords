extends Node
func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("FixCfw")
	var sim = load("res://tests/fix/C/hack_sim.gd").new()
	for g in [[2, "uncommon", 4], [3, "rare", 8], [4, "rare", 8], [5, "epic", 12], [6, "epic", 16], [6, "legendary", 16]]:
		var fws: Array = []
		for k in 10:
			for uid in sim._squad(g[0], g[1], g[2]):
				fws.append(int(Battle.make_unit(Game.wl(uid), 0).base.fw))
		fws.sort()
		var n := fws.size()
		print("FW R%d %s +%d: p25 %d p50 %d p70 %d p80 %d" % [g[0], g[1], g[2], fws[n/4], fws[n/2], fws[int(n*0.7)], fws[int(n*0.8)]])
	get_tree().quit()
