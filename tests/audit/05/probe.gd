extends Node
## Audit 05: hideout reward distributions + boss mechanic spot checks.
const N := 4000

func _ready() -> void:
	await get_tree().process_frame
	Game.reset_save()
	Game.new_game("Audit05")
	for st in [1, 6, 7, 13, 20]:
		_gear("trolls", st)
		_gear("chopshop", st)
	for st in [1, 14, 20]:
		_diff("synapse", st)
		_diff("heist", st)
		_diff("deeds_paragon", st)
	_mech()
	print("AUDIT05 DONE")
	get_tree().quit()

func _gear(id: String, st: int) -> void:
	var ranks := {}; var rar := {}; var slots := {}; var sets := {}
	var c0 := Game.cur("credits")
	for i in N:
		var r := Content.hideout_rewards({"id": id, "stage": st}, true)
		var uid = r.items[r.items.size() - 1].equip
		var it: Dictionary = {}
		for e in Game.S.equip:
			if e.uid == uid: it = e
		ranks[it.rank] = ranks.get(it.rank, 0) + 1
		rar[it.rarity] = rar.get(it.rarity, 0) + 1
		slots[it.slot] = slots.get(it.slot, 0) + 1
		sets[str(it.get("set", ""))] = sets.get(str(it.get("set", "")), 0) + 1
		Game.S.equip.clear()
	print("%s s%d credits/win=%d cost=%s ranks=%s rar=%s slots=%s sets=%s" % [id, st, (Game.cur("credits") - c0) / N, Content.hideout_cost(id, st), _pc(ranks), _pc(rar), _pc(slots), _pc(sets)])

func _diff(id: String, st: int) -> void:
	var tally := {}
	for i in N:
		var before: Dictionary = Game.S.items.duplicate(true)
		var c0 := Game.cur("credits")
		Content.hideout_rewards({"id": id, "stage": st}, true)
		var dc := Game.cur("credits") - c0
		var keyparts: Array = []
		if dc > 0: keyparts.append("cr" + str(dc))
		_walk(before, Game.S.items, "", keyparts)
		keyparts.sort()
		var k := " ".join(keyparts)
		tally[k] = tally.get(k, 0) + 1
	var keys := tally.keys()
	if keys.size() > 40:
		# summarise per-component
		var comp := {}
		for k in keys:
			for p in String(k).split(" "):
				var base := p.split("=")[0]
				comp[base] = comp.get(base, 0) + tally[k]
		print("%s s%d cost=%s components=%s" % [id, st, Content.hideout_cost(id, st), _pc(comp)])
	else:
		print("%s s%d cost=%s outcomes=%s" % [id, st, Content.hideout_cost(id, st), _pc(tally)])

func _walk(a, b, path: String, out: Array) -> void:
	for k in b:
		if b[k] is Dictionary:
			_walk(a.get(k, {}) if a is Dictionary else {}, b[k], path + "/" + str(k), out)
		else:
			var d := int(b[k]) - int(a.get(k, 0) if a is Dictionary else 0)
			if d != 0:
				out.append("%s/%s=%d" % [path, k, d])

func _pc(d: Dictionary) -> String:
	var tot := 0
	for k in d: tot += d[k]
	var parts: Array = []
	var ks := d.keys(); ks.sort()
	for k in ks:
		parts.append("%s:%.1f" % [str(k), 100.0 * d[k] / tot])
	return "{" + ", ".join(parts) + "}"

func _mech() -> void:
	# boss immunities
	for id in ["trolls", "vultures", "teratek", "vikings"]:
		var enc := Content.build_hideout(id, 5)
		print("immune %s boss=%s %s boss_flag=%s n_wave2=%d" % [id, enc.waves[1][0].tpl, enc.waves[1][0].immune, enc.waves[1][0].get("boss", false), enc.waves[1].size()])
	# TM immunity in battle, open wounds, devour, ragnarok
	var uids: Array = []
	for id in Warlords.RECRUITABLE:
		if Warlords.get_t(id).rarity == "epic" and uids.size() < 4:
			uids.append(Game.add_warlord(id, true).uid)
	var b := Battle.new()
	var enc := Content.build_hideout("vultures", 1)
	b.setup(Content.player_units(uids), [enc.waves[1].map(func(u): return u.duplicate(true))], {})
	var cormac: Dictionary = b.side_units(1)[0]
	var p: Dictionary = b.side_units(0)[0]
	cormac.tm = 500.0
	b._tm(p, cormac, -50.0, false)
	print("cormac tm after -50 (immune expected 500): ", cormac.tm)
	for i in 3:
		p.debuffs.append({"id": "bleed", "v": 5.0, "turns": 2, "src": cormac.uid, "hit": 100.0})
	b._special_after(cormac, Warlords.get_t("cormac").abilities[0], p, {})
	print("open wounds 3 stacks -> ", b.debuff_count(p, "bleed"))
	var nx = b._next_actor() if b.has_method("_next_actor") else null
	print("next actor method present: ", b.has_method("_next_actor"))
	# Deacon not TM-immune
	var b2 := Battle.new()
	var enc2 := Content.build_hideout("trolls", 1)
	b2.setup(Content.player_units(uids), [enc2.waves[1].map(func(u): return u.duplicate(true))], {})
	var dc: Dictionary = b2.side_units(1)[0]
	var p2: Dictionary = b2.side_units(0)[0]
	for st in [1, 10, 20]:
		var e3 := Content.build_hideout("trolls", st)
		print("trolls s%d wave2 hack: %s" % [st, e3.waves[1].map(func(u): return [u.tpl, u.base.hack, u.base.fw])])
	print("player fw: ", b2.side_units(0).map(func(u): return u.base.fw))
	dc.tm = 500.0
	b2._tm(p2, dc, -50.0, false)
	print("deacon tm after -50 (not immune; may be resisted by hack check): ", dc.tm, " hack=", b2.eff(p2, "hack"), " fw=", b2.eff(dc, "fw"))
	b2._place_debuff(p2, dc, {"id": "stun", "turns": 1}, {})
	print("deacon stun placed? ", b2.has_debuff(dc, "stun"))
	# Divine retribution reflect stacks (force hack so placement lands)
	dc.base.hack = 9999.0
	p2.base.hack = 9999.0
	b2._place_debuff(p2, dc, {"id": "stun", "turns": 1}, {})
	b2._place_debuff(p2, dc, {"id": "armDown", "turns": 1}, {})
	print("deacon stun w/ hack? ", b2.has_debuff(dc, "stun"), " armDown? ", b2.has_debuff(dc, "armDown"))
	dc.tm = 500.0
	b2._tm(p2, dc, -50.0, false)
	print("deacon tm after -50 w/ hack (expect 250): ", dc.tm)
	b2._place_debuff(dc, p2, {"id": "enraged", "turns": 1}, {})
	b2._place_debuff(dc, b2.side_units(0)[1], {"id": "enraged", "turns": 1}, {})
	print("deacon reflect sum after 2 enrages: ", b2._buff_sum(dc, "reflect"))
