extends Node
## Section 07 review probe (logic only).
##   NW_SAVE=07 godot --headless --path . res://tests/review/07/Probe07.tscn -- --nwtest

func _ready() -> void:
	Game.reset_save()
	Game.new_game("Probe07")
	# 1) boss immunities / wave make-up
	for hid in ["trolls", "vultures", "teratek", "vikings"]:
		var enc := Content.build_hideout(hid, 10)
		var w2: Array = enc.waves[1]
		print("%s stage10 cost=%s wave1=%d wave2=%s" % [hid, enc.cost, enc.waves[0].size(), w2.map(func(u): return u.tpl)])
		for u in w2:
			if u.boss:
				print("   boss %s immune=%s hp=%d" % [u.tpl, u.immune, int(u.base.hp)])
	for s in [1, 5, 6, 11, 16, 20]:
		print("stage %d cost=%s level=%s" % [s, Content.hideout_cost("trolls", s), Content.hideout_level(s)])
	# 2) Ragnarok revive targets: build a strong team and log revives in Vikings fights
	var uids: Array = []
	var n := 0
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and n < 4:
			var w := Game.add_warlord(id, true)
			w.rank = 6; w.level = Data.max_level(6); w.rep = 6
			for slot in Data.GEAR_SLOTS + Data.IMPLANT_SLOTS:
				var it := Game.make_equipment(slot, 6, "legendary")
				it.level = 16
				Game.S.equip.append(it)
				Game.equip_on(w, it)
			uids.append(w.uid); n += 1
	var rev := {}
	var shocked_skip_boss := 0
	var enrage_on_boss := 0
	for i in 20:
		for hid in ["vikings", "trolls", "vultures", "teratek"]:
			var enc := Content.build_hideout(hid, 8)
			var b := Battle.new()
			var waves: Array = []
			for wv in enc.waves:
				waves.append(wv.map(func(u): return u.duplicate(true)))
			b.setup(Content.player_units(uids), waves, {})
			b.simulate()
			for e in b.events:
				if e.e == "revive":
					var u = b.unit(e.u)
					if u != null and u.side == 1:
						var k: String = hid + ":" + u.tpl
						rev[k] = rev.get(k, 0) + 1
	print("enemy revives by hideout:tpl = ", rev)
	# 3) direct immunity test: place stun/shock/enraged/tm on each boss
	for hid in ["trolls", "vultures", "teratek", "vikings"]:
		var enc := Content.build_hideout(hid, 5)
		var b := Battle.new()
		b.setup(Content.player_units(uids), [enc.waves[1].map(func(u): return u.duplicate(true))], {})
		b.start()
		var boss = b.side_units(1).filter(func(u): return u.boss)[0]
		var src = b.side_units(0)[0]
		src.base.hack = 9999.0
		var got: Array = []
		for d in ["stun", "shock", "stupefy", "enraged"]:
			b._place_debuff(src, boss, {"id": d, "turns": 1, "chance": 100, "l": 1}, {})
			if b.has_debuff(boss, d): got.append(d)
		boss.tm = 500.0
		b._tm(src, boss, -50.0, false)
		if boss.tm < 500.0: got.append("tm")
		print("%s boss %s ACCEPTED debuffs: %s" % [hid, boss.tpl, got])
	# 4) reward distribution at stage 6 and 20
	for st in [6, 20]:
		var ranks := {}; var rars := {}; var slots := {}; var sets := {}
		for i in 3000:
			var r := Content.hideout_rewards({"mode": "hideout", "id": "vikings", "stage": st}, true)
			for it in r.items:
				if it.has("equip"):
					var eq = null
					for x in Game.S.equip:
						if x.uid == it.equip: eq = x
					ranks[eq.rank] = ranks.get(eq.rank, 0) + 1
					rars[eq.rarity] = rars.get(eq.rarity, 0) + 1
					slots[eq.slot] = slots.get(eq.slot, 0) + 1
					sets[eq.set] = sets.get(eq.set, 0) + 1
		print("stage %d ranks=%s rar=%s slots=%s sets=%s" % [st, ranks, rars, slots, sets])
		Game.S.equip = Game.S.equip.filter(func(x): return x.owner != "")
	get_tree().quit()
