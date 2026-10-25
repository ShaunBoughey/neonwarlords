extends Node
func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("dbg")
	var team: Array = Game.S.roster.map(func(w): return w.uid)
	for u in team:
		Game.wl(u).level = 8
	for u in Content.player_units(team):
		print("P ", u.name, " r", u.rank, " ", u.base)
	var enc := Content.build_campaign(0, 1, 0)
	for u in enc.waves[0]:
		print("E ", u.name, " r", u.rank, " lv", u.level, " ", u.base)
	var b := Battle.new()
	b.setup(Content.player_units(team), enc.waves, {"seed": 3})
	b.simulate()
	print("result ", b.result, " turns ", b.turn_count, " dmg to enemies ", b.damage_to_side(1), " dmg to players ", b.damage_to_side(0))
	get_tree().quit()
