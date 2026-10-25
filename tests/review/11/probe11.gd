extends Node
## Headless logic probe for GDD section 11 (Bastions, Trinium Stocks).

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Probe11")
	Game.S.tutorial_done = true
	# --- stocks
	for lv in [1, 19, 20, 40]:
		Game.S.player.level = lv
		print("stocks: player lv %d -> stocks lv %d" % [lv, Game.stocks_level()])
	Game.S.player.level = 40
	Game.S.stocks.stored = 0.0
	Game.S.stocks.t = Time.get_unix_time_from_system() - 86400 * 3
	Game.tick()
	print("stocks after 3 days offline (lv3): ", Game.S.stocks.stored)
	# --- bastion
	print("bastion state: ", Game.S.gang.bastion)
	var tm := _team(60, 6, 5)
	for stage in [1, 2, 3]:
		var enc := Content.build_bastion(stage)
		var boss: Dictionary = enc.waves[0][0]
		print("stage %d boss %s hp %d, adds %d" % [stage, boss.name, int(boss.base.hp), enc.waves[0].size() - 1])
		for i in 3:
			var b := Battle.new()
			var waves: Array = [enc.waves[0].map(func(u): return u.duplicate(true))]
			b.setup(Content.player_units(tm), waves, {"turn_limit": enc.turn_limit, "seed": 50 + i})
			var r = b.simulate()
			var bossu = b.side_units(1, false)[0]
			print("  run %d: result %s, player_turns %d, dmg %d, boss alive %s hp %d/%d, debuffs %d" % [i, r, b.player_turns, int(b.damage_to_side(1)), bossu.alive, int(bossu.hp), int(bossu.max_hp), b.debuffs_placed_by_player])
	var weak := _team(20, 3, 2)
	var enc1 := Content.build_bastion(1)
	var b2 := Battle.new()
	b2.setup(Content.player_units(weak), [enc1.waves[0].map(func(u): return u.duplicate(true))], {"turn_limit": enc1.turn_limit, "seed": 7})
	print("weak team stage1: ", b2.simulate(), " turns ", b2.player_turns, " dmg ", int(b2.damage_to_side(1)))
	print("rewards 0: ", Content.bastion_rewards(1, 0).size(), " max: ", Content.bastion_rewards(3, 999999))
	# pay/entries
	for i in 5:
		print("pay #%d: '%s' entries %d tickets %d" % [i, Game.pay({"bastion": 1}), int(Game.S.gang.bastion.entries), Game.cur("raidTicket")])
	print("PROBE DONE")
	get_tree().quit()

func _team(level: int, rank: int, gear_rank: int) -> Array:
	var out: Array = []
	for id in ["deacon_chainz", "raiden_x", "issac_vaun", "pontiff_ruckus", "redd_skullfire"]:
		var w := Game.add_warlord(id, true)
		w.level = level
		w.rank = rank
		w.rep = mini(rank, 6)
		for slot in Data.GEAR_SLOTS:
			var it := Game.add_equipment(Game.make_equipment(slot, gear_rank, "epic", "Speed" if slot in ["weapon", "helmet"] else "Firepower"))
			for i in mini(16, gear_rank * 3):
				Game.equip_level_up(it, true)
			Game.equip_on(w, it)
		out.append(w.uid)
	return out
