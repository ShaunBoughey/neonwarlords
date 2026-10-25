extends Node
func _ready() -> void:
	for d in [1, 2]:
		for loc in 10:
			for st in [0, 6]:
				var enc := Content.build_campaign(d, loc, st)
				var us: Array = enc.waves[0]
				print("%s %d-%d %s" % [Data.DIFFS[d], loc + 1, st + 1, ", ".join(us.map(func(u): return "%s(%s %s) hp%d fp%d" % [u.tpl, Warlords.get_t(u.tpl).cls, Warlords.get_t(u.tpl).rarity, int(u.base.hp), int(u.base.fp)]))])
	get_tree().quit()
