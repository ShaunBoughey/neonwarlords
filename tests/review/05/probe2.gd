extends "res://tests/review/05/probe.gd"
## Wave 1 checks: NW_SAVE=05 godot --headless --path . res://tests/review/05/Probe2.tscn -- --nwtest

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe")
	var p := fresh(); var x: Dictionary = p[0]; var e: Dictionary = p[1]
	# D6: firepower buff and passive stacks multiply
	x.fp_stacks = 10.0
	b._place_buff(x, x, {"id": "fpUp", "turns": 2, "l": 0}, true)
	ok("FP buff x passive multiply (1.25 x 1.10)", is_equal_approx(b.eff(x, "fp"), x.base.fp * 1.25 * 1.10))
	# cdIncrease large = full cooldown
	x.base.hack = 9999.0
	for k in e.cds: e.cds[k] = 0
	b._place_debuff(x, e, {"id": "cdIncrease", "turns": 1, "chance": 100, "l": 1}, {})
	var full := true
	for a in b.actives(e):
		if int(e.cds[a.id]) != int(a.get("cd", 0)): full = false
	ok("Cooldown Increase large = full cooldowns", full)
	# cd_reduce reset
	b._apply_fx(e, b.basic(e), [{"t": "cd_reduce", "reset": true, "to": "self"}], [e], {})
	ok("Cooldown reset", e.cds.values().all(func(v): return int(v) == 0))
	# Rapid Rescue re-arms after a heal above 25%
	e.low_fired = true
	e.hp = e.max_hp * 0.1
	b._heal(e, e, e.max_hp * 0.5, false)
	ok("low_fired resets after heal >= 25%", not e.low_fired)
	# Blitz kept through a buff-only skill
	x.first_attack = true
	b._use_ability(x, {"id": "t", "name": "t", "mult": 0.0, "fx": [], "tgt": "self"}, x, false)
	ok("first_attack kept after a non-damage skill", x.first_attack)
	# boss debuff counter
	e.boss = true
	var n0 := b.debuffs_on_boss
	b._place_debuff(x, e, {"id": "armDown", "turns": 2, "chance": 100, "l": 0}, {})
	ok("debuffs_on_boss counts", b.debuffs_on_boss == n0 + 1)
	# Formations: two carriers don't compound
	p = fresh()
	var al: Array = b.side_units(0)
	var a0: float = al[0].base.arm; var a1: float = al[1].base.arm; var a2: float = al[2].base.arm
	al[0].nn["formations"] = 2; al[1].nn["formations"] = 2
	var v := float(Data.NN_BY_ID["formations"].v[1])
	b._apply_formations(0)
	ok("Formations from snapshot", is_equal_approx(al[2].base.arm, a2 + (a0 + a1) * v / 100.0))
	# turn limit never reports limit + 1
	var enc := Content.build_campaign(0, 0, 0)
	var bb := Battle.new()
	var allies: Array = Content.player_units(Game.S.squads.last)
	bb.setup(allies, [enc.waves[0].map(func(u): return u.duplicate(true))], {"turn_limit": 3})
	bb.simulate()
	ok("turn_limit: player_turns <= limit", bb.player_turns <= 3, "%d (%s)" % [bb.player_turns, bb.result])
	print("\nFAILS: %d" % fails)
	get_tree().quit()
