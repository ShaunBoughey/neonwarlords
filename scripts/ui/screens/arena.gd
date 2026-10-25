extends Screen
## The Pit: Brawls (4v4) and Royals (4 + 3 reinforcements). Brackets, opponents, defence and leaderboard.

func build() -> void:
	var mode: String = params.get("mode", "brawl")
	var view: String = params.get("view", "fight")
	bg_tint = Color("#3A2A06")
	var h := header("The Pit")
	subtitle = "Weekly reset " + U.dur(U.secs_to_next_week())
	h.add_child(tabs(["Brawl", "Royal"], U.cap(mode), func(n):
		params.mode = n.to_lower()
		rebuild()))
	h.add_child(tabs(["Fight", "Defence", "Leaderboard", "Brackets"], U.cap(view), func(n):
		params.view = n.to_lower()
		rebuild()))
	var p: Dictionary = Game.S.pit[mode]
	var row := Game.pit_tier_row(int(p.points))
	var info := PanelContainer.new()
	info.add_theme_stylebox_override("panel", UI._sb(Color("#2A1E06"), Color("#6E5414"), 1, UI.NOTCH, 18))
	var ih := UI.hb(28)
	info.add_child(ih)
	var emblem := HexButton.new()
	emblem.custom_minimum_size = Vector2(76, 68)
	emblem.fill = Color("#3A2A06")
	emblem.fill2 = Color("#6E4A0F")
	emblem.border = UI.GOLD
	emblem.glyph = str(row[0])
	emblem.glyph_size = 28
	emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ih.add_child(emblem)
	var bv := UI.vb(4)
	bv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bv.add_child(UI.cap("Bracket %d" % row[0], UI.GOLD))
	bv.add_child(UI.disp(String(row[1]), 26))
	bv.add_child(UI.lbl("%d points  •  W %d / L %d" % [int(p.points), int(p.wins), int(p.losses)], 15, UI.SOFT))
	ih.add_child(bv)
	ih.add_child(UI.spacer())
	var iv := UI.vb(6)
	iv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	iv.custom_minimum_size.x = 360
	var ihh := UI.hb()
	ihh.add_child(UI.cap("%s invites" % mode, UI.CYAN))
	ihh.add_child(UI.spacer())
	ihh.add_child(UI.lbl("%d / %d" % [Game.cur(mode), Data.PIT_CAP], 15, UI.TEXT))
	iv.add_child(ihh)
	iv.add_child(UI.segments(Game.cur(mode), Data.PIT_CAP, UI.CYAN))
	iv.add_child(UI.lbl("Weekly cache: " + String(row[3]), 14, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	ih.add_child(iv)
	root.add_child(info)
	match view:
		"fight": _fight(mode)
		"defence": _defence(mode)
		"leaderboard": _board(mode)
		"brackets": _brackets()

func _fight(mode: String) -> void:
	var opps := Content.pit_opponents(mode)
	# compare with the attack squad's first 4, the same scale as opponent power
	var att: Array = Game.S.squads.get("royal", Game.S.squads.pit_royal) if mode == "royal" else Game.S.squads.last
	var mine := Game.team_power(att.slice(0, 4))
	var list := UI.vb(6)
	for o in opps:
		var p := UI.panel()
		var h := UI.hb(10)
		p.add_child(h)
		var nv := UI.vb(0)
		nv.custom_minimum_size.x = 200
		nv.add_child(UI.lbl(o.name, 16))
		nv.add_child(UI.lbl("%d pts • Lv %d • Rank %d" % [o.points, o.level, o.rank], 14, UI.DIM))
		h.add_child(nv)
		for m in o.team.slice(0, 4):
			h.add_child(UI.portrait(m.tpl, 44))
		if mode == "royal":
			h.add_child(UI.lbl("+%d" % (o.team.size() - 4), 14, UI.DIM))
		h.add_child(UI.spacer())
		var col := UI.GREEN if o.power < mine * 0.9 else (UI.RED if o.power > mine * 1.1 else UI.YELLOW)
		h.add_child(UI.lbl("Power %s" % U.fmt(o.power), 15, col))
		var opp: Dictionary = o
		h.add_child(UI.btn("FIGHT", func(): main.start_encounter(Content.build_pit(mode, opp)), "primary", 100))
		list.add_child(p)
	var bottom := UI.hb()
	var note := UI.lbl("Opponents refresh hourly. Wins: +10 points, Credits & Pit Coin. A lost attack costs only the invite; points are lost when your defence is beaten.", 14, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true)
	UI.expand(note)
	bottom.add_child(note)
	bottom.add_child(UI.btn("Refresh (10 ◆)", func():
		if Game.spend("trinium", 10):
			Game.S.pit[mode].opps = []
			rebuild()
		else:
			err("Not enough Trinium"), "ghost"))
	root.add_child(UI.scroll(list))
	root.add_child(bottom)

func _defence(mode: String) -> void:
	var size := 7 if mode == "royal" else 4
	var sq: Array = Game.S.squads["pit_" + mode]
	var p := UI.panel()
	var v := UI.vb(8)
	p.add_child(v)
	v.add_child(UI.lbl("Defensive gang (%d Warlords%s). Other players attack this team while you are away." % [size, ", last 3 are reinforcements" if mode == "royal" else ""], 14, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var h := UI.hb(8)
	for i in sq.size():
		var w = Game.wl(sq[i])
		if w == null:
			continue
		if i == 4:
			var rc := UI.cap("Reinforcements", UI.PURPLE, 14)
			rc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(UI.spacer(false, 12))
			h.add_child(rc)
		h.add_child(UI.warlord_card(w, Callable(), false, true))
	v.add_child(h)
	# opponents are rated on their first 4, so the defence is too
	v.add_child(UI.lbl("Defence power: " + U.fmt(Game.team_power(sq.slice(0, 4))), 15, UI.YELLOW))
	v.add_child(UI.btn("Set Defence Gang", func(): main.go("squad", {"enc": {"mode": "defence", "pit_mode": mode, "title": "Pit %s Defence" % U.cap(mode), "royal": mode == "royal"}}), "primary", 240))
	root.add_child(p)
	var lp := UI.panel()
	var lv := UI.vb(2)
	lv.add_child(UI.lbl("Battle log", 15, UI.CYAN))
	for e in Game.S.pit[mode].log:
		lv.add_child(UI.lbl(e.txt, 14, UI.GREEN if e.win else UI.RED))
	lp.add_child(lv)
	root.add_child(UI.scroll(lp))

func _board(mode: String) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = U.week_id() * 31 + (1 if mode == "royal" else 0)
	var pool: Array = Warlords.RECRUITABLE
	var seeded_team := func() -> Array:
		var t: Array = []
		for j in 4:
			t.append(pool[r.randi_range(0, pool.size() - 1)])
		return t
	var rows: Array = []
	for i in 30:
		rows.append({"name": "%s%s%d" % [Content.NAME_A[r.randi_range(0, 19)], Content.NAME_B[r.randi_range(0, 19)], r.randi_range(1, 99)], "pts": int(3400 * pow(0.9, i)) + r.randi_range(0, 40), "gang": ["Neon Jackals", "Chrome Saints", "Null Set", "Volt Kings", "Rust Monks"][r.randi_range(0, 4)], "team": seeded_team.call()})
	for m in Game.S.gang.members:
		rows.append({"name": m.name, "pts": 100 + int(m.power / 60) % 2400, "gang": Game.S.gang.name, "friend": true, "team": seeded_team.call()})
	var my_team: Array = []
	for u in Game.S.squads["pit_" + mode].slice(0, 4):
		var w = Game.wl(u)
		if w:
			my_team.append(w.tpl)
	rows.append({"name": Game.S.name + " (you)", "pts": int(Game.S.pit[mode].points), "gang": Game.S.gang.name, "me": true, "team": my_team})
	rows.sort_custom(func(a, b): return a.pts > b.pts)
	for i in rows.size():
		rows[i].rank = i + 1
	var filt: String = params.get("lb", "All")
	var q: String = params.get("q", "")
	var fh := UI.hb(6)
	fh.add_child(tabs(["All", "Gang", "Friends"], filt, func(n):
		params.lb = n
		rebuild()))
	var se := LineEdit.new()
	se.placeholder_text = "Search players"
	se.text = q
	se.custom_minimum_size.x = 220
	se.text_submitted.connect(func(t):
		params.q = t
		rebuild())
	fh.add_child(se)
	fh.add_child(UI.btn("Search", func():
		params.q = se.text
		rebuild(), "ghost"))
	root.add_child(fh)
	rows = rows.filter(func(e):
		if filt == "Gang" and e.gang != Game.S.gang.name: return false
		if filt == "Friends" and not (e.get("friend", false) or e.get("me", false)): return false
		if q != "" and not String(e.name).to_lower().contains(q.to_lower()): return false
		return true)
	# your own row is pinned above the list
	for e in rows:
		if e.get("me", false):
			root.add_child(_board_row(e))
	var list := UI.vb(4)
	for e in rows:
		list.add_child(_board_row(e))
	root.add_child(UI.scroll(list))

## One leaderboard row: rank, defence team, name, gang, bracket, points.
func _board_row(e: Dictionary) -> PanelContainer:
	var me: bool = e.get("me", false)
	var p := UI.panel(UI.MAGENTA if me else UI.LINE, Color(UI.MAGENTA, 0.12) if me else Color(UI.DEEP, 0.85), UI.NOTCH, 8)
	var h := UI.hb(10)
	p.add_child(h)
	var rk := UI.lbl("#%d" % e.rank, 16, UI.YELLOW)
	rk.custom_minimum_size.x = 48
	h.add_child(rk)
	var team := UI.hb(4)
	team.custom_minimum_size.x = 4 * 36
	for tpl in e.get("team", []):
		team.add_child(UI.portrait(tpl, 32))
	h.add_child(team)
	var n := UI.lbl(e.name, 16, UI.MAGENTA if me else UI.TEXT)
	UI.expand(n)
	n.clip_text = true
	h.add_child(n)
	h.add_child(UI.lbl(e.gang, 14, UI.DIM))
	var br := UI.lbl(Game.pit_tier_row(e.pts)[1], 14, UI.CYAN, HORIZONTAL_ALIGNMENT_RIGHT)
	br.custom_minimum_size.x = 120
	h.add_child(br)
	var pts := UI.lbl("%d pts" % e.pts, 16, UI.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
	pts.custom_minimum_size.x = 96
	h.add_child(pts)
	return p

func _brackets() -> void:
	var cur_tier := Game.pit_tier(int(Game.S.pit[params.get("mode", "brawl")].points))
	var widths := [56, 200, 110, 240, 0]
	var hh := UI.hb(10)
	var heads := ["Tier", "Bracket", "Points", "Weekly reward", "Per win"]
	for i in heads.size():
		var c := UI.cap(heads[i], UI.CYAN, 14)
		c.custom_minimum_size.x = widths[i]
		if widths[i] == 0:
			UI.expand(c)
		hh.add_child(c)
	var hp := UI.pad(hh, 0)
	hp.add_theme_constant_override("margin_left", 8)
	hp.add_theme_constant_override("margin_right", 8)
	root.add_child(hp)
	var list := UI.vb(4)
	for row in Data.GDD.pitTiers:
		var on := int(row[0]) == cur_tier
		var p := UI.panel(UI.GOLD if on else UI.LINE, Color(UI.GOLD, 0.14) if on else Color(UI.DEEP, 0.85), UI.NOTCH, 8)
		var h := UI.hb(10)
		p.add_child(h)
		var m := RegEx.create_from_string("(\\d+)k Credits, (\\d+) Pit Coin").search(String(row[4]))
		var per_win := "+10 pts  •  %sK Credits  •  %s Pit Coin" % [m.get_string(1), m.get_string(2)] if m else String(row[4])
		var cells := [[str(row[0]), UI.TEXT], [String(row[1]), UI.GOLD], [U.fmt(int(row[2])) + "+", UI.TEXT], [String(row[3]), UI.TEXT], [per_win, UI.SOFT]]
		for i in cells.size():
			var l := UI.lbl(cells[i][0], 15, cells[i][1])
			l.custom_minimum_size.x = widths[i]
			if widths[i] == 0:
				UI.expand(l)
			h.add_child(l)
		list.add_child(p)
	root.add_child(UI.scroll(list))
