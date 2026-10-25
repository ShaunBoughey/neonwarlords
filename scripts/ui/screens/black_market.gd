extends Screen
## Black Market: Pit Coin store with daily / weekly limits.

func build() -> void:
	bg_tint = Color("#3A0E2E")
	header("Black Market")
	subtitle = "Daily %s  •  Weekly %s" % [U.dur(U.secs_to_next_day()), U.dur(U.secs_to_next_week())]
	var g := UI.grid(4, 10)
	var rows: Array = Data.GDD.blackMarket
	for i in rows.size():
		var row: Array = rows[i]
		var p := UI.panel(UI.LINE, Color(UI.DEEP, 0.92), UI.NOTCH, 14)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vb(6)
		p.add_child(v)
		var top := UI.hb()
		var reset := String(row[2])
		top.add_child(UI.cap("No limit" if reset == "N/A" else reset, UI.MAGENTA if reset.to_lower() == "weekly" else (UI.DIM if reset == "N/A" else UI.CYAN)))
		v.add_child(top)
		var rew := U.parse_rewards(row[0])
		var holder := CenterContainer.new()
		holder.custom_minimum_size.y = 70
		if not rew.is_empty():
			holder.add_child(UI.reward_node(rew[0], 60))
		v.add_child(holder)
		var nm := UI.lbl(U.reward_label(rew[0]) if not rew.is_empty() else String(row[0]), 15, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		nm.clip_text = true
		v.add_child(nm)
		var can := Game.bm_can_buy(i)
		var idx := i
		var b := UI.btn("", func(): main.show_rewards("Black Market", Game.bm_buy(idx), rebuild), "primary", 0, 14)
		b.disabled = can != ""
		b.tooltip_text = can
		if can == "Sold out until reset.":
			b.text = "Sold out"
		else:
			# price with the pit-coin stroke icon (same as the HUD pill)
			b.custom_minimum_size.y = 44
			var price := UI.hb(6)
			price.alignment = BoxContainer.ALIGNMENT_CENTER
			price.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var pcol := UI.HINT if b.disabled else UI.TEXT
			for c in [Icon.make("pitcoin", UI.HINT if b.disabled else UI.MAGENTA, 18), UI.lbl(U.fmt(row[1]), 16, pcol)]:
				c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				price.add_child(c)
			UI._ignore_mouse(price)
			b.add_child(price)
		v.add_child(b)
		g.add_child(p)
	root.add_child(UI.scroll(g))
