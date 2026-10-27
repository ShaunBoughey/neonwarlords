extends Node
func _ready() -> void:
	await get_tree().process_frame
	for st in [1, 5, 10, 15, 20]:
		print("hideout s%d %s" % [st, Content.hideout_level(st)])
	for d in 3:
		for loc in [0, 4, 9]:
			var stg := Content.campaign_stage(d, loc, 6)
			print("campaign d%d den%d boss enemy %s" % [d, loc + 1, stg.enemy[d]])
	get_tree().quit()
