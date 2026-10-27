class_name ItemView
extends RefCounted
## Equipment detail modal shared by the Armory and Inventory.

static func open(main, it: Dictionary, on_change: Callable) -> void:
	var v := UI.vb(8)
	var col: Color = Data.RARITY_COLOR[it.rarity]
	var top := UI.hb(12)
	var frame := Control.new()
	frame.custom_minimum_size = Vector2(66, 80)
	var ic := Art.icon(Art.SLOT_BUTTON[it.slot], Vector2(58, 72))
	ic.position = Vector2(4, 4)
	ic.size = Vector2(58, 72)
	frame.add_child(ic)
	frame.add_child(Art.rect(Art.equip_border(it.rarity), Vector2.ZERO, 1.0, Vector2(66, 80)))
	top.add_child(frame)
	var tv := UI.vb(2)
	tv.add_child(UI.lbl(Game.equip_name(it), 20, col))
	tv.add_child(UI.lbl("%s  •  Rank %d  •  Level +%d / 20" % [U.cap(it.rarity), it.rank, it.level], 14, UI.DIM))
	if it.owner != "":
		var w = Game.wl(it.owner)
		if w:
			tv.add_child(UI.lbl("Equipped on " + Game.tpl(w).name, 13, UI.GREEN))
	top.add_child(tv)
	v.add_child(top)
	var sp := UI.panel()
	var sv := UI.vb(3)
	sp.add_child(sv)
	sv.add_child(UI.lbl("Primary: " + UI.stat_text(it.pri.stat, Data.primary_value(it.pri.stat, it.rank, it.level)), 16, UI.YELLOW))
	for s in it.subs:
		var nv := float(s.get("neon", 0))
		var t := UI.stat_text(s.stat, float(s.val) + nv)
		if int(s.rolls) > 0:
			t += "  (+%d rolls)" % int(s.rolls)
		if nv > 0:
			t += "  (neon)"
			var nh := UI.hb(6)
			nh.add_child(Icon.make("diamond", UI.MAGENTA, 14))
			nh.add_child(UI.lbl(t, 14, UI.MAGENTA))
			sv.add_child(nh)
			continue
		sv.add_child(UI.lbl(t, 14, UI.TEXT))
	if it.subs.size() < 4:
		sv.add_child(UI.lbl("Next substat at +%d" % [((it.level / 5) + 1) * 5], 12, UI.DIM))
	if it.set != "":
		var sd: Dictionary = Data.SETS[it.set]
		sv.add_child(UI.lbl("Set: %s (%d pieces): %s" % [it.set, sd.pieces, sd.desc], 13, UI.CYAN, HORIZONTAL_ALIGNMENT_LEFT, true))
		var ow = Game.wl(it.owner) if it.owner != "" else null
		if ow != null:
			var worn := int(Game.compute_stats(ow).sets.get(it.set, 0))
			var times := int(worn / sd.pieces)
			sv.add_child(UI.lbl("%s worn: %d/%d - %s" % [it.set, worn, sd.pieces, ("ACTIVE x%d" % times) if times > 0 else "inactive"], 13, UI.GREEN if times > 0 else UI.DIM))
		var src := UI.set_sources(it.set)
		if src != "":
			sv.add_child(UI.lbl("Drops: " + src, 12, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	if it.kind == "implant":
		var need := int(Data.IMPLANT_UNLOCK.get(it.slot, 0))
		var ow2 = Game.wl(it.owner) if it.owner != "" else null
		sv.add_child(UI.lbl("%s slot unlocks at Reputation %d" % [U.cap(it.slot), need], 13, UI.YELLOW if ow2 == null or int(ow2.rep) >= need else UI.RED))
	v.add_child(sp)
	var dim_ref := []
	var refresh := func():
		main.close_modal()
		on_change.call()
		open(main, it, on_change)
	var actions := UI.flow(6)
	if it.level < Data.MAX_EQUIP_LEVEL:
		var cost := Data.equip_level_cost(it.rank, it.level)
		actions.add_child(UI.btn("Level Up (%s ¢)" % U.fmt(cost), func():
			var e := Game.equip_level_up(it)
			if e != "":
				Game.say(e, UI.RED)
			refresh.call(), "primary"))
		var cost5 := 0
		for i in range(it.level, mini(it.level + 5, Data.MAX_EQUIP_LEVEL)):
			cost5 += Data.equip_level_cost(it.rank, i)
		actions.add_child(UI.btn("Level x%d (%s ¢)" % [mini(5, Data.MAX_EQUIP_LEVEL - it.level), U.fmt(cost5)], func():
			for i in 5:
				if Game.equip_level_up(it) != "":
					break
			refresh.call(), "primary"))
	var fitting: Array = Game.S.neons.filter(func(ne): return Game.neon_can(it, ne) == "")
	if not fitting.is_empty():
		actions.add_child(UI.btn("Apply Neon (%d fit)" % fitting.size(), func():
			main.close_modal()
			_neon_picker(main, it, fitting, on_change), "magenta"))
	else:
		var nb := UI.btn("Apply Neon", func(): pass, "magenta")
		nb.disabled = true
		actions.add_child(nb)
		nb.tooltip_text = _neon_why(it)
	actions.add_child(UI.btn("Unlock" if it.locked else "Lock", func():
		it.locked = not it.locked
		Game.mark()
		refresh.call(), "ghost"))
	if it.owner != "":
		actions.add_child(UI.btn("Unequip", func():
			Game.unequip(it)
			main.close_modal()
			on_change.call(), "ghost"))
	actions.add_child(UI.btn("Sell (%s ¢)" % U.fmt(Game.equip_sell_value(it)), func():
		var on = Game.wl(it.owner) if it.owner != "" else null
		var q := ("Sell %s? It is equipped on %s." % [Game.equip_name(it), Game.tpl(on).name]) if on != null else "Sell %s?" % Game.equip_name(it)
		main.confirm(q, func():
			var e := Game.sell_equipment(it)
			if e != "":
				Game.say(e, UI.RED)
			main.close_modal()
			on_change.call()), "danger"))
	v.add_child(actions)
	if fitting.is_empty():
		v.add_child(UI.lbl(_neon_why(it), 12, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	dim_ref.append(main.modal("Equipment", v))

static func _neon_picker(main, it: Dictionary, fitting: Array, on_change: Callable) -> void:
	var v := UI.vb(6)
	v.add_child(UI.lbl("Neons boost a matching substat by its rank value. Neons fit equipment of the same or higher rank.", 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	var f := UI.flow(6)
	for ne in fitting:
		var neon: Dictionary = ne
		f.add_child(UI.btn("R%d %s (+%s)" % [ne.rank, Data.STATS[ne.stat].name, str(Data.SUBSTAT[ne.stat][ne.rank])], func():
			var e := Game.apply_neon(it, neon)
			if e != "":
				Game.say(e, UI.RED)
			main.close_modal()
			on_change.call()
			open(main, it, on_change), "magenta"))
	v.add_child(f)
	main.modal("Apply Neon", v)

## Why no owned neon fits this item (shown under a disabled Apply Neon).
static func _neon_why(it: Dictionary) -> String:
	if Game.S.neons.is_empty():
		return "No Neons owned. Win Neons in Syndicate Wars."
	var stats: Array = it.subs.map(func(sb): return sb.stat)
	var free: Array = it.subs.filter(func(sb): return float(sb.get("neon", 0)) <= 0).map(func(sb): return Data.STATS[sb.stat].short)
	if free.is_empty():
		return "Every substat already has a Neon (one Neon per substat)."
	var match_hi := false
	for ne in Game.S.neons:
		if ne.stat in stats and int(ne.rank) > int(it.rank):
			match_hi = true
	var why := "Needs a Rank <= %d Neon matching a free substat (%s)." % [it.rank, ", ".join(free)]
	if match_hi:
		why += " Your matching Neons are higher rank than this item."
	return why
