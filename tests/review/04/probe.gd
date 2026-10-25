extends Node
## Review 04: base stat ranges and level/rank/rep scaling for every template.

func _ready() -> void:
	var fails := 0
	var n := 0
	var rows := []
	for id in Warlords.T:
		var t: Dictionary = Warlords.T[id]
		var b: Dictionary = t.base
		var rng: Array = Data.BASE_RANGES[t.cls][t.rarity]
		n += 1
		var bad := []
		for i in 3:
			var k: String = ["hp", "arm", "fp"][i]
			if b[k] < rng[i][0] or b[k] > rng[i][1]: bad.append("%s=%s not in %s" % [k, b[k], rng[i]])
		if b.spd < 90 or b.spd > 110: bad.append("spd=%s" % b.spd)
		if b.cc != 10.0 or b.cd != 50.0 or b.fw != 30.0: bad.append("cc/cd/fw=%s/%s/%s" % [b.cc, b.cd, b.fw])
		if t.cls != "hacker" and b.hack != 0: bad.append("hack=%s" % b.hack)
		if t.cls == "hacker" and b.hack != 0: bad.append("hacker base hack=%s (GDD 0)" % b.hack)
		# scaling at max
		var sc: Array = Data.SCALING[t.cls][t.rarity]
		var w := {"tpl": id, "level": 60, "rank": 6, "rep": 6, "gear": {}, "ab": {}, "nn": {}}
		var s := Game.compute_stats(w, 0.0001)  # enemy_bonus>0 skips safehouse; remove its tiny effect below
		var w1 := {"tpl": id, "level": 1, "rank": 1, "rep": 0, "gear": {}, "ab": {}, "nn": {}}
		var s1 := Game.compute_stats(w1, 0.0001)
		var keys := ["hp", "arm", "fp"]
		for i in 3:
			var k: String = keys[i]
			var pas := 0.0
			var expect: float = float(b[k]) * (1 + sc[i] / 100.0) * (1 + sc[i + 3] / 100.0) * (1 + 6 * sc[6] / 100.0)
			var ratio: float = float(s[k]) / float(s1[k])
			var want: float = expect / float(b[k])
			if abs(ratio - want) > 0.01: bad.append("%s scale %.3f want %.3f" % [k, ratio, want])
		if bad.size() > 0 or t.get("enemy_only", false) == false:
			rows.append("%s|%s|%s|%s|hp %d arm %d fp %d spd %d hack %d%s" % [id, t.rarity, t.cls, t.syn, b.hp, b.arm, b.fp, b.spd, b.hack, ("  BAD: " + ", ".join(bad)) if bad.size() else ""])
		if bad.size(): fails += 1
	for r in rows: print(r)
	print("templates: %d  with issues: %d" % [n, fails])
	get_tree().quit()
