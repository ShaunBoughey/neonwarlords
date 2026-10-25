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
		actions.add_child(UI.btn("Level x5", func():
			for i in 5:
				if Game.equip_level_up(it) != "":
					break
			refresh.call(), "primary"))
	var fitting: Array = Game.S.neons.filter(func(ne): return Game.neon_can(it, ne) == "")
	if not fitting.is_empty():
		actions.add_child(UI.btn("Apply Neon (%d fit)" % fitting.size(), func():
			main.close_modal()
			_neon_picker(main, it, fitting, on_change), "magenta"))
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
		main.confirm("Sell %s?" % Game.equip_name(it), func():
			var e := Game.sell_equipment(it)
			if e != "":
				Game.say(e, UI.RED)
			main.close_modal()
			on_change.call()), "danger"))
	v.add_child(actions)
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
