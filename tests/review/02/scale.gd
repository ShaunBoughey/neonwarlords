extends Node
## Lists abilities whose level has no effect in Battle.gd / compute_stats.
func _ready() -> void:
	var n := 0
	for id in Warlords.T:
		var t: Dictionary = Warlords.T[id]
		if t.get("enemy_only", false): continue
		for a in t.abilities:
			var s := false
			match a.type:
				"leader": s = true
				"passive": s = a.has("stats")
				_:
					if float(a.get("mult", 0)) > 0.0: s = true
					for f in a.get("fx", []):
						if f.t in ["heal", "shield"]: s = true
						if f.t == "tm" and float(f.v) > 0: s = true
						if f.t == "debuff" and float(f.get("chance", 100)) < 100: s = true
			if not s:
				n += 1
				print("NOSCALE %s.%s (%s): %s" % [id, a.id, a.type, a.desc])
	print("NOSCALE total %d" % n)
	get_tree().quit()
