extends Node
func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	for k in [[2,3,6],[2,8,6],[1,9,6],[2,4,6],[2,9,6]]:
		var enc := Content.build_campaign(k[0], k[1], k[2])
		var s := "%s:" % enc.title
		for wv in enc.waves:
			s += "  |" + ", ".join(wv.map(func(u): return "%s L%d %s" % [u.tpl, u.level, Game.tpl(u).cls if Game.tpl(u) else ""]))
		print(s)
	get_tree().quit()
