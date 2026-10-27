extends Screen
## Campaign: one den at a time as an isometric district map (7 landmarks), difficulty switch,
## stage sheet with power check, enemies, drops and chevron goals, BATTLE pinned bottom-right.

var diff := 0
var loc := 0

func build() -> void:
	diff = int(params.get("d", _default_diff()))
	loc = int(params.get("loc", _default_loc()))
	if loc < 0:
		loc = _default_loc()
	var info: Dictionary = Data.GDD.campaign[loc]
	var syn: String = Data.CAMPAIGN_SYNDICATE[loc]
	var scol: Color = Data.SYNDICATES[syn].color
	bg_tint = scol.darkened(0.78)
	screen_title = String(info.name)
	subtitle = "Campaign  •  Den %d of 10" % (loc + 1)
	var sel_st := _selected_stage()
	# ---- difficulty switch (top centre)
	var tb := tabs(Data.DIFFS, Data.DIFFS[diff], func(n):
		var d: int = Data.DIFFS.find(n)
		if not Game.campaign_unlocked(d, 0, 0):
			err("Clear %s first" % Data.DIFFS[d - 1])
			return
		params.d = d
		params.st = -1
		rebuild())
	# right-anchored so it always ends left of the HUD pills (energy / credits / trinium), whatever the aspect
	tb.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	tb.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tb.offset_left = -840
	tb.offset_right = -480
	tb.offset_top = -56
	tb.offset_bottom = -10
	add_child(tb)
	# ---- district map
	var states: Array = []
	var stars: Array = []
	for st in 7:
		var un := Game.campaign_unlocked(diff, loc, st)
		var s := Game.campaign_stars(diff, loc, st)
		stars.append(s)
		states.append("sel" if st == sel_st else ("done" if s > 0 else ("open" if un else "lock")))
	var boss_enc := Content.build_campaign(diff, loc, 6)
	var boss_name := "Den Boss"
	for u in boss_enc.waves[0]:
		if u.get("boss", false):
			boss_name = Warlords.get_t(u.tpl).name
	var map := DistrictDiorama.new()
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.offset_left = 0
	map.offset_right = -430
	map.offset_top = 10
	map.offset_bottom = -84
	add_child(map)
	map.setup(loc, states, stars, scol, boss_name)
	map.stage_pressed.connect(func(i):
		params.st = i
		rebuild())
	add_child(_cap_at("District map  •  tap a location", Vector2(20, 12)))
	# ---- den progress + den switching (bottom-left)
	var den_stars := 0
	for st in 7:
		den_stars += Game.campaign_stars(diff, loc, st)
	var dp := PanelContainer.new()
	dp.add_theme_stylebox_override("panel", UI._sb(UI.PANEL, Color(0, 0, 0, 0), 0, UI.NOTCH, 14))
	dp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	dp.offset_left = 20
	dp.offset_right = 360
	dp.offset_top = -78
	dp.offset_bottom = -18
	var dv := UI.vb(6)
	var dh := UI.hb()
	dh.add_child(UI.cap("Den chevrons"))
	dh.add_child(UI.spacer())
	dh.add_child(UI.lbl("%d / 21" % den_stars, 15, UI.TEXT))
	dv.add_child(dh)
	dv.add_child(UI.bar(den_stars, 21, UI.GOLD, 8))
	dp.add_child(dv)
	add_child(dp)
	var nav_row := UI.hb(10)
	nav_row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	nav_row.offset_left = 376
	nav_row.offset_top = -72
	nav_row.offset_bottom = -24
	var prev := UI.btn("", func(): _den(loc - 1), "normal", 44)
	var pi := Icon.make("left", UI.CYAN, 20)
	pi.position = Vector2(12, 12)
	prev.add_child(pi)
	prev.disabled = loc == 0
	nav_row.add_child(prev)
	var nxt_ok := loc < 9 and Game.campaign_unlocked(diff, loc + 1, 0)
	var nxt := UI.btn("DEN %d  ›" % (loc + 2) if loc < 9 else "FINAL DEN", func(): _den(loc + 1), "normal", 0, 14)
	if loc < 9:
		nxt.tooltip_text = "Den %d: %s" % [loc + 2, Data.GDD.campaign[loc + 1].name]
	nxt.disabled = not nxt_ok
	nav_row.add_child(nxt)
	nav_row.add_child(UI.btn("MAP", func(): _map(), "normal", 0, 14))
	var claimable := _claimable_rewards()
	nav_row.add_child(UI.btn("REWARDS%s" % ("  •  %d" % claimable if claimable > 0 else ""), func(): _rewards(), "gold" if claimable > 0 else "primary", 0, 14))
	add_child(nav_row)
	# ---- stage sheet
	add_child(_sheet(sel_st, syn, scol))

func _cap_at(text: String, pos: Vector2) -> Label:
	var l := UI.cap(text, UI.DIM)
	l.position = pos
	return l

func _default_diff() -> int:
	var d := 0
	for i in range(1, 3):
		if Game.campaign_unlocked(i, 0, 0):
			d = i
	return d

func _default_loc() -> int:
	var l := 0
	for i in 10:
		if Game.campaign_unlocked(diff, i, 0):
			l = i
	return l

func _selected_stage() -> int:
	var sel_st := int(params.get("st", -1))
	if sel_st < 0 or not Game.campaign_unlocked(diff, loc, sel_st):
		sel_st = 0
		for st in 7:
			if Game.campaign_unlocked(diff, loc, st):
				sel_st = st
				if Game.campaign_stars(diff, loc, st) == 0:
					break
		params.st = sel_st
	return sel_st

## Campaign map: all 10 dens of this difficulty with chevrons earned and lock state.
func _map() -> void:
	var g := UI.grid(2, 8)
	var dim_ref := []
	for i in Data.GDD.campaign.size():
		var stars := 0
		for st in 7:
			stars += Game.campaign_stars(diff, i, st)
		var open := Game.campaign_unlocked(diff, i, 0)
		var den: int = i
		var b := UI.btn("%d. %s   %s" % [i + 1, String(Data.GDD.campaign[i].name), ("%d / 21 chevrons" % stars) if open else "Locked"], func():
			main._close(dim_ref[0])
			_den(den), "primary" if i == loc else "normal", 420, 14)
		b.disabled = not open
		b.custom_minimum_size.y = 48
		g.add_child(b)
	dim_ref.append(main.modal("Campaign map - %s" % Data.DIFFS[diff], g, true))

func _den(i: int) -> void:
	params.loc = clampi(i, 0, 9)
	params.st = -1
	rebuild()

func _sheet(sel_st: int, syn: String, scol: Color) -> PanelContainer:
	var info: Dictionary = Data.GDD.campaign[loc]
	var stg: Dictionary = info.stages[sel_st]
	var rew: Array = stg.rew[diff]
	var enc := Content.build_campaign(diff, loc, sel_st)
	var side := PanelContainer.new()
	side.add_theme_stylebox_override("panel", UI._sb(Color(0.04, 0.12, 0.19, 0.95), UI.LINE, 1, UI.NOTCH, 20))
	side.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	side.offset_left = -420
	side.offset_right = -20
	side.offset_top = 10
	side.offset_bottom = -18
	var outer := UI.vb(12)
	side.add_child(outer)
	var sv := UI.vb(10)
	var sc := UI.scroll(sv)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sc)
	var hv := UI.vb(2)
	var hc := UI.cap("%s  •  %s" % [Data.SYNDICATES[syn].name, Data.DIFFS[diff]])
	hc.clip_text = true
	hc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hc.custom_minimum_size.x = 0
	hv.add_child(hc)
	hv.add_child(UI.disp(("Boss stage %d-%d" if sel_st == 6 else "Stage %d-%d") % [loc + 1, sel_st + 1], 28, UI.RED if sel_st == 6 else UI.TEXT))
	sv.add_child(hv)
	# power check
	var mine := Game.team_power(Game.S.squads.last)
	var theirs := Content.enc_power(enc)
	var ratio: float = float(mine) / max(1.0, float(theirs))
	var verdict: Array = ["Favoured", UI.GREEN] if ratio > 1.15 else (["Fair fight", UI.GOLD] if ratio > 0.9 else (["Hard", Color("#FF8A3A")] if ratio > 0.7 else ["Deadly", UI.RED]))
	var pr := UI.hb(12)
	var pv := UI.vb(5)
	UI.expand(pv)
	var pt := UI.hb()
	pt.add_child(UI.lbl("You  " + U.fmt(mine), 15, UI.CYAN))
	pt.add_child(UI.spacer())
	pt.add_child(UI.lbl("Enemy  " + U.fmt(theirs), 15, UI.RED))
	pv.add_child(pt)
	var split := UI.hb(0)
	var a := ColorRect.new()
	a.color = UI.CYAN
	a.custom_minimum_size.y = 8
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	a.size_flags_stretch_ratio = max(0.05, float(mine))
	var b := ColorRect.new()
	b.color = UI.RED
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_stretch_ratio = max(0.05, float(theirs))
	split.add_child(a)
	split.add_child(b)
	pv.add_child(split)
	pr.add_child(pv)
	var vl := UI.cap(verdict[0], verdict[1], 12)
	vl.add_theme_stylebox_override("normal", UI._sb(Color(verdict[1], 0.14), Color(0, 0, 0, 0), 0, 8, 8))
	vl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pr.add_child(vl)
	sv.add_child(pr)
	# enemies
	var ev := UI.vb(8)
	ev.add_child(UI.cap("Enemies"))
	var er := UI.hb(8)
	for u in enc.waves[0]:
		er.add_child(_enemy_tile(u))
	ev.add_child(er)
	sv.add_child(ev)
	# drops
	var dv := UI.vb(8)
	dv.add_child(UI.cap("Possible drops"))
	var dr := UI.flow(8)
	var slot_name: String = String(stg.slot).to_lower()
	var set_name := Content.campaign_set(loc)
	# rarity border = the most likely rarity at this difficulty; tooltip shows the real rank/rarity odds
	var eq: Dictionary = Data.CAMPAIGN_EQUIP[diff]
	var top_r := "common"
	for r in eq.rar:
		if int(eq.rar[r]) > int(eq.rar.get(top_r, 0)):
			top_r = r
	var rk_parts: Array = []
	for k in eq.ranks:
		rk_parts.append("R%s %d%%" % [str(k), int(eq.ranks[k])])
	var rr_parts: Array = []
	for r in eq.rar:
		rr_parts.append("%s %d%%" % [U.cap(r), int(eq.rar[r])])
	dr.add_child(_art_tile(Art.SLOT_BUTTON.get(slot_name, Art.SLOT_BUTTON.weapon), top_r, "75%", "%s set
Rank: %s
Rarity: %s" % [set_name, ", ".join(rk_parts), ", ".join(rr_parts)]))
	for d in Data.CAMPAIGN_DROPS[diff]:
		if d[0] == "warlord":
			dr.add_child(_icon_tile("users", Data.RARITY_COLOR[d[1]], "%s%%" % str(d[2]), "%s Warlord" % U.cap(d[1])))
		elif d[0] == "contract":
			var n := int(d[1])
			dr.add_child(_icon_tile("case", Data.RARITY_COLOR.uncommon, ("%dx  %s%%" % [n, str(d[2])]) if n > 1 else "%s%%" % str(d[2]), "%dx Uncommon Contract" % n))
	dr.add_child(_text_tile(U.fmt(rew[0]), "XP"))
	dr.add_child(_text_tile(U.fmt(rew[1]), "Credits"))
	dv.add_child(dr)
	var daily := String(Data.GDD.campaign[loc].set) == "Rotates Daily"
	var gear_txt := "Gear: %s%s  •  %s" % [set_name, " (today)" if daily else " set", "any slot" if not Data.GEAR_SLOTS.has(slot_name) else String(stg.slot)]
	var gl := UI.lbl(gear_txt, 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true)
	gl.custom_minimum_size.x = 0
	dv.add_child(gl)
	# when the next difficulty opens (GDD: clearing the final stage of a difficulty unlocks the next)
	if diff < Data.DIFFS.size() - 1 and not Game.campaign_unlocked(diff + 1, 0, 0):
		var last := loc == 9 and sel_st == 6
		var ul := UI.lbl(("Winning this stage unlocks %s" if last else "Clear Den 10 stage 7 to unlock %s") % Data.DIFFS[diff + 1], 13, UI.GOLD if last else UI.HINT, HORIZONTAL_ALIGNMENT_LEFT, true)
		dv.add_child(ul)
	sv.add_child(dv)
	# chevron goals
	var gv := UI.vb(6)
	gv.add_child(UI.cap("Chevron goals"))
	var got := Game.campaign_stars(diff, loc, sel_st)
	var goals := ["Win the battle", "No Warlord defeated", "Win within %d turns" % enc.chevron_turns]
	for i in 3:
		var row := UI.hb(8)
		row.add_child(_chevron_icon(i < got, 16))
		row.add_child(UI.lbl(goals[i], 15, UI.TEXT if i < got else UI.DIM))
		gv.add_child(row)
	sv.add_child(gv)
	# CTA
	var go := UI.cta("BATTLE", func(): main.start_encounter(Content.build_campaign(diff, loc, sel_st)), str(Data.CAMPAIGN_ENERGY[diff]))
	go.disabled = not Game.campaign_unlocked(diff, loc, sel_st)
	go.set_meta("coach", "stage_battle")
	UI.expand(go)
	# multi-battle: the battle screen replays while enc.repeat > 1 (see battle.gd)
	var auto := UI.btn("AUTO ×10", func():
		var e := Content.build_campaign(diff, loc, sel_st)
		e.repeat = 10
		main.start_encounter(e), "primary", 0, 13)
	auto.custom_minimum_size.y = 56
	auto.tooltip_text = "Replay this stage on auto up to 10 times while you have energy"
	auto.disabled = go.disabled or Game.campaign_stars(diff, loc, sel_st) == 0
	var cta_row := UI.hb(10)
	cta_row.add_child(auto)
	cta_row.add_child(go)
	outer.add_child(cta_row)
	return side

## Gold chevron (filled = earned), drawn like the design canvas's triangle path.
func _chevron_icon(filled: bool, sz: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(sz, sz)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var s := float(sz)
		var pts := PackedVector2Array([Vector2(1, s * 0.85), Vector2(s / 2, s * 0.2), Vector2(s - 1, s * 0.85)])
		if filled:
			c.draw_colored_polygon(pts, UI.GOLD)
		else:
			pts.append(pts[0])
			c.draw_polyline(pts, UI.GOLD, 1.5, true))
	return c

func _enemy_tile(u: Dictionary) -> Control:
	var t: Dictionary = Warlords.get_t(u.tpl)
	var boss: bool = u.get("boss", false)
	var col: Color = UI.RED if boss else Data.RARITY_COLOR.get(t.rarity, UI.DIM)
	var p := Panel.new()
	p.custom_minimum_size = Vector2(80, 80)
	p.add_theme_stylebox_override("panel", UI._sb(Color("#1A0E14"), col, 2, 8, 0))
	var por := UI.portrait(u.tpl, 70)
	por.position = Vector2(5, 3)
	p.add_child(por)
	var lv := UI.lbl("LV %d" % int(u.get("level", 1)), 12, UI.TEXT)
	lv.add_theme_stylebox_override("normal", UI._sb(UI.BG, UI.BG, 0, 0, 4))
	lv.position = Vector2(4, 58)
	p.add_child(lv)
	if boss:
		var bl := UI.cap("Boss", UI.RED, 10)
		bl.add_theme_stylebox_override("normal", UI._sb(UI.BG, UI.BG, 0, 0, 3))
		bl.position = Vector2(4, 4)
		p.add_child(bl)
		bl.move_to_front()
	p.tooltip_text = t.name
	return p

func _art_tile(art: String, rarity: String, corner: String, tip: String) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(66, 80)
	c.add_child(Art.icon(art, Vector2(66, 80)))
	c.add_child(Art.rect(Art.equip_border(rarity), Vector2.ZERO, 1.0, Vector2(66, 80)))
	var l := UI.lbl(corner, 12, UI.TEXT)
	l.add_theme_stylebox_override("normal", UI._sb(UI.BG, UI.BG, 0, 0, 4))
	l.position = Vector2(26, 60)
	c.add_child(l)
	c.tooltip_text = tip
	return c

func _icon_tile(icon: String, col: Color, corner: String, tip: String) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(66, 80)
	p.add_theme_stylebox_override("panel", UI._sb(Color(col, 0.12), col, 2, 8, 0))
	var ic := Icon.make(icon, col, 26)
	ic.position = Vector2(20, 16)
	p.add_child(ic)
	var l := UI.lbl(corner, 13, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, 50)
	l.size = Vector2(66, 20)
	p.add_child(l)
	p.tooltip_text = tip
	return p

func _text_tile(big: String, small: String) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(66, 80)
	p.add_theme_stylebox_override("panel", UI._sb(Color(1, 1, 1, 0.06), UI.LINE, 1, 8, 0))
	var v := UI.vb(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var b := UI.lbl(big, 16, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	b.clip_text = true
	v.add_child(b)
	var s := UI.cap(small, UI.DIM, 10)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	p.add_child(v)
	return p

func _claimable_rewards() -> int:
	var total := Game.campaign_total_stars(diff)
	var n := 0
	for r in Data.GDD.campaignProgress:
		var thr := int(r[0])
		var claimed: bool = Game.S.campaign.claimed[diff].has(thr) or Game.S.campaign.claimed[diff].has(float(thr))
		if total >= thr and not claimed:
			n += 1
	return n

func _rewards() -> void:
	var total := Game.campaign_total_stars(diff)
	var v := UI.vb(8)
	v.add_child(UI.lbl("%s chevrons: %d / 210" % [Data.DIFFS[diff], total], 16, UI.GOLD))
	v.add_child(UI.bar(total, 210, UI.GOLD, 8))
	for r in Data.GDD.campaignProgress:
		var thr := int(r[0])
		var claimed: bool = Game.S.campaign.claimed[diff].has(thr) or Game.S.campaign.claimed[diff].has(float(thr))
		var can := total >= thr and not claimed
		var row := UI.hb(12)
		var tl := UI.lbl("%d" % thr, 16, UI.GOLD if total >= thr else UI.DIM)
		tl.custom_minimum_size.x = 48
		row.add_child(tl)
		var parsed: Array = U.parse_rewards(String(r[1 + diff]))
		if not parsed.is_empty():
			var ic := UI.reward_node(parsed[0], 36)
			ic.custom_minimum_size = Vector2(36, 36)
			ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(ic)
		var d := UI.lbl(String(r[1 + diff]), 14, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true)
		d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		UI.expand(d)
		row.add_child(d)
		var b := UI.btn("CLAIMED" if claimed else "CLAIM", func():
			main.close_modal()
			main.show_rewards("Campaign Rewards", Game.claim_campaign_progress(diff, thr), rebuild), "gold" if can else "ghost", 120, 13)
		b.disabled = not can
		row.add_child(b)
		v.add_child(row)
	main.modal("Campaign Rewards", v, true)
