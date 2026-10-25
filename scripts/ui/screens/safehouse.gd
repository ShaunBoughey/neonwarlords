extends Screen
## Safehouse: Pit Coin stat nodes split by morality (alignment).

func build() -> void:
	bg_tint = Color("#14223A")
	header("Safehouse")
	subtitle = "Boosts per alignment"
	var row := UI.hb(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for al in Data.ALIGNMENTS:
		var col: Color = Data.ALIGN_COLOR[al]
		var p := UI.panel(col.darkened(0.2), Color(UI.DEEP, 0.92), UI.NOTCH, 16)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vb(10)
		p.add_child(v)
		var count: int = Game.S.roster.filter(func(w): return Game.tpl(w).align == al).size()
		var hb2 := UI.hb(10)
		var bar2 := ColorRect.new()
		bar2.color = col
		bar2.custom_minimum_size = Vector2(4, 40)
		hb2.add_child(bar2)
		var hv := UI.vb(0)
		hv.add_child(UI.disp(al, 22, col))
		hv.add_child(UI.lbl("%d %s benefit%s" % [count, "Warlord" if count == 1 else "Warlords", "s" if count == 1 else ""], 14, UI.DIM))
		hb2.add_child(hv)
		v.add_child(hb2)
		var totals: Array = []
		for node in Data.SAFEHOUSE_NODES:
			var lv := Game.safehouse_level(al, node)
			var flat: bool = node in ["hack", "fw"]
			var cur_v: int = (Data.SAFEHOUSE_FLAT[lv] if flat else Data.SAFEHOUSE_PCT[lv])
			var nh := UI.hb(6)
			var nl := UI.vb(0)
			UI.expand(nl)
			nl.add_child(UI.lbl("%s  •  Lv %d/10" % [Data.SAFEHOUSE_NODES[node], lv], 15))
			var unit := "" if flat else "%"
			var bonus := "+%d%s" % [cur_v, unit]
			if lv < 10:
				var nxt: int = Data.SAFEHOUSE_FLAT[lv + 1] if flat else Data.SAFEHOUSE_PCT[lv + 1]
				bonus += "   Next +%d%s" % [nxt, unit]
			nl.add_child(UI.lbl(bonus, 14, UI.GREEN if lv > 0 else UI.DIM))
			nl.add_child(UI.segments(lv, 10, col, 6))
			if lv > 0:
				totals.append("+%d%s %s" % [cur_v, unit, Data.SAFEHOUSE_NODES[node]])
			nh.add_child(nl)
			var a2: String = al
			var n2: String = node
			if lv < 10:
				var b := UI.btn("%d PC" % Data.SAFEHOUSE_COST[lv + 1], func():
					err(Game.safehouse_upgrade(a2, n2))
					rebuild(), "primary", 96, 13)
				b.disabled = Game.cur("pitCoin") < Data.SAFEHOUSE_COST[lv + 1]
				nh.add_child(b)
			else:
				nh.add_child(UI.lbl("MAX", 13, UI.YELLOW))
			v.add_child(nh)
		v.add_child(UI.spacer(false, 0, 6))
		v.add_child(UI.cap("Total", UI.DIM, 13))
		v.add_child(UI.lbl(", ".join(totals) if not totals.is_empty() else "No upgrades yet", 14, UI.TEXT if not totals.is_empty() else UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
		row.add_child(p)
	root.add_child(row)
