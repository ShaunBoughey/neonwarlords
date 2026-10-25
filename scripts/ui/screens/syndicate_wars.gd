extends Screen
## Syndicate Wars: single-syndicate squads, 20 stages per syndicate, Neon rewards.
## Hideouts pattern: syndicate rail on the left, the syndicate centre stage, stage picker and BATTLE on the right.

const MAX_CHEVRONS := 360

func build() -> void:
	var syn: String = params.get("syn", "")
	if not Data.SYNDICATES.has(syn):
		syn = _default_syn()
	bg_tint = Color("#2A0E3A")
	screen_title = "SYNDICATE WARS"
	_progress()
	var body := UI.hb(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_rail(syn))
	body.add_child(_centre(syn))
	body.add_child(_stage_panel(syn))

## The syndicate you own the most warlords in (chevrons break ties).
func _default_syn() -> String:
	var best: String = Data.SYNDICATES.keys()[0]
	var score := -1
	for s in Data.SYNDICATES:
		var sc := _owned(s).size() * 100 + _syn_stars(s)
		if sc > score:
			score = sc
			best = s
	return best

func _owned(syn: String) -> Array:
	var ws: Array = Game.S.roster.filter(func(w): return Game.tpl(w).syn == syn)
	ws.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	return ws

func _syn_stars(syn: String) -> int:
	var n := 0
	for st in range(1, 21):
		n += Game.sw_stars(syn, st)
	return n

func _bounty_pill() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color(UI.PANEL, 0.9), Color(0, 0, 0, 0), 0, UI.NOTCH, 10))
	var h := UI.hb(8)
	var ic := Icon.make("ticket", UI.GOLD, 18)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(ic)
	h.add_child(UI.lbl("%d / %d" % [Game.cur("bounty"), Data.BOUNTY_DAILY], 18, UI.TEXT))
	p.add_child(h)
	p.tooltip_text = "Bounty Tokens (refresh daily)"
	return p

## Three chevron stroke icons, lit for each chevron earned.
func _chevrons(n: int, px := 16) -> HBoxContainer:
	var h := UI.hb(0)
	for i in 3:
		h.add_child(Icon.make("up", UI.YELLOW if i < n else Color(UI.DIM, 0.45), px))
	return h

func _progress() -> void:
	var total := Game.sw_total_stars()
	var p := UI.panel(UI.LINE, Color(UI.DEEP, 0.9), UI.NOTCH, 10)
	var v := UI.vb(6)
	var top := UI.hb(12)
	top.add_child(UI.cap("Chevron milestones", UI.PURPLE, 14))
	top.add_child(UI.spacer())
	var shown := "%d / %d" % [mini(total, MAX_CHEVRONS), MAX_CHEVRONS]
	if total > MAX_CHEVRONS:
		shown += " (+%d)" % (total - MAX_CHEVRONS)
	top.add_child(UI.lbl(shown, 16, UI.YELLOW))
	top.add_child(_bounty_pill())
	v.add_child(top)
	v.add_child(UI.bar(mini(total, MAX_CHEVRONS), MAX_CHEVRONS, UI.PURPLE, 8))
	var strip := UI.hb(6)
	for r in Data.GDD.swProgress:
		strip.add_child(_milestone(r, total))
	var sc := UI.scroll(strip, true)
	sc.custom_minimum_size.y = 96
	v.add_child(sc)
	p.add_child(v)
	root.add_child(p)

## A milestone tile: its first reward's icon and label over the threshold. Claimable tiles are gold and pulse.
func _milestone(r: Array, total: int) -> Button:
	var thr := int(r[0])
	var claimed: bool = Game.S.sw.claimed.has(thr) or Game.S.sw.claimed.has(float(thr))
	var can := total >= thr and not claimed
	var rew := U.parse_rewards(String(r[1]))
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(112, 92)
	var border := UI.GOLD if can else (UI.LINE if not claimed else Color(UI.LINE, 0.5))
	var bg := Color(UI.GOLD, 0.18) if can else Color(UI.PANEL, 0.6)
	b.add_theme_stylebox_override("normal", UI._sb(bg, border, 2 if can else 1, UI.NOTCH, 4))
	b.add_theme_stylebox_override("hover", UI._sb(Color(bg, bg.a + 0.1), border, 2, UI.NOTCH, 4))
	b.add_theme_stylebox_override("disabled", UI._sb(bg, border, 1, UI.NOTCH, 4))
	b.tooltip_text = "%d chevrons: %s" % [thr, r[1]]
	var v := UI.vb(2)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	if not rew.is_empty():
		var ic := UI.reward_node(rew[0], 34)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var nm := UI.lbl(U.reward_label(rew[0]), 14, UI.SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(nm)
	var th := UI.hb(3)
	th.alignment = BoxContainer.ALIGNMENT_CENTER
	if claimed:
		th.add_child(Icon.make("check", UI.GREEN, 14))
	th.add_child(UI.lbl(str(thr), 14, UI.GOLD if can else (UI.DIM if claimed else UI.TEXT)))
	v.add_child(th)
	UI._ignore_mouse(v)
	b.add_child(v)
	if claimed:
		b.modulate = Color(1, 1, 1, 0.55)
	elif not can:
		b.modulate = Color(1, 1, 1, 0.8)
	b.disabled = not can
	if can:
		b.pressed.connect(func(): main.show_rewards("Syndicate Wars", Game.claim_sw_progress(thr), rebuild))
		b.tree_entered.connect(func():
			var tw := b.create_tween().set_loops()
			tw.tween_property(b, "self_modulate", Color(1.25, 1.15, 0.85), 0.6)
			tw.tween_property(b, "self_modulate", Color.WHITE, 0.6), CONNECT_ONE_SHOT)
	return b

## Left rail: the 7 syndicates with chevrons earned (x/60) and the owned count.
func _rail(syn: String) -> PanelContainer:
	var items: Array = []
	for s in Data.SYNDICATES:
		var info: Dictionary = Data.SYNDICATES[s]
		var owned := _owned(s).size()
		items.append({"id": s, "name": info.name, "right": "%d/60" % _syn_stars(s), "right_col": UI.YELLOW if owned > 0 else UI.HINT,
			"col": info.color})
	var rl := rail([{"label": "Syndicates", "items": items}], syn, func(s):
		params.syn = s
		params.erase("stage")
		params.erase("page")
		rebuild(), 280)
	return rl

## Centre: the syndicate's symbol, name, lore and how many of its warlords you own.
func _centre(syn: String) -> VBoxContainer:
	var info: Dictionary = Data.SYNDICATES[syn]
	var owned := _owned(syn).size()
	var v := UI.vb(10)
	UI.expand(v)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var cap := UI.cap("Syndicate Wars  •  single-syndicate squads", Color(info.color, 1.0).lightened(0.2), 14)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(cap)
	if Art.SYN_SYMBOL.has(syn):
		var sym := Art.icon(Art.SYN_SYMBOL[syn], Vector2(150, 150))
		sym.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(sym)
	var nm := UI.disp(info.name, 34)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_color_override("font_shadow_color", Color(info.color, 0.5))
	nm.add_theme_constant_override("shadow_outline_size", 14)
	v.add_child(nm)
	v.add_child(UI.lbl(info.desc, 15, UI.SOFT, HORIZONTAL_ALIGNMENT_CENTER, true))
	var oc := UI.GREEN if owned >= 4 else (UI.GOLD if owned > 0 else UI.RED)
	v.add_child(UI.lbl("%d Warlord%s owned" % [owned, "" if owned == 1 else "s"], 16, oc, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.lbl("Your whole squad must be from this syndicate. Neons are only found here.", 14, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER, true))
	return v

## Right panel: 20-stage picker (two pages of 10), enemy, power check, Neon odds and BATTLE.
func _stage_panel(syn: String) -> PanelContainer:
	var info: Dictionary = Data.SYNDICATES[syn]
	var unlocked_max := 1
	for st in range(1, 20):
		if Game.sw_stars(syn, st) > 0:
			unlocked_max = st + 1
	var stage := clampi(int(params.get("stage", unlocked_max)), 1, unlocked_max)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.94), UI.LINE, 1, UI.NOTCH, 16))
	p.custom_minimum_size.x = 380
	p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var outer := UI.vb(10)
	p.add_child(outer)
	var v := UI.vb(8)
	var sc := UI.scroll(v)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sc)
	var page := int(params.get("page", (stage - 1) / 10))
	# caption and page switch share one row to keep BATTLE details above the fold
	var pg := UI.hb(6)
	pg.add_child(UI.cap("Select stage", UI.DIM, 14))
	pg.add_child(UI.spacer())
	for pi in 2:
		var pb := UI.btn("%d-%d" % [pi * 10 + 1, pi * 10 + 10], func():
			params.page = pi
			rebuild(), "ghost", 0, 14)
		pb.disabled = page == pi
		pg.add_child(pb)
	v.add_child(pg)
	var g := UI.grid(5, 6)
	for s in range(page * 10 + 1, page * 10 + 11):
		var on := s == stage
		var stars := Game.sw_stars(syn, s)
		var b := UI.btn(str(s), func():
			params.stage = s
			rebuild(), "normal", 0, 15)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		b.add_theme_stylebox_override("normal", UI._sb(info.color if on else Color(1, 1, 1, 0.06), Color(0, 0, 0, 0), 0, 8, 4))
		b.add_theme_color_override("font_color", UI.BG if on else (UI.YELLOW if stars > 0 else UI.SOFT))
		b.disabled = s > unlocked_max
		b.tooltip_text = "Stage %d  •  %d / 3 chevrons" % [s, stars]
		g.add_child(b)
	v.add_child(g)
	var enc := Content.build_sw(syn, stage)
	var row: Dictionary = Data.GDD.syndicateWars[stage - 1]
	var sh := UI.hb()
	sh.add_child(UI.disp("Stage %d" % stage, 22))
	sh.add_child(UI.spacer())
	sh.add_child(_chevrons(Game.sw_stars(syn, stage), 18))
	v.add_child(sh)
	v.add_child(UI.lbl(String(enc.subtitle), 15, Color("#FF8AA0")))
	# power check against the squad auto-fill would pick (your best 4 of this syndicate)
	var mine := Game.team_power(_owned(syn).slice(0, 4).map(func(w): return w.uid))
	var theirs := Content.enc_power(enc)
	var ratio: float = float(mine) / max(1.0, float(theirs))
	var rh := UI.hb()
	rh.add_child(UI.lbl("You " + U.fmt(mine), 14, UI.CYAN))
	rh.add_child(UI.spacer())
	rh.add_child(UI.lbl("Recommended " + U.fmt(theirs), 14, UI.GOLD))
	v.add_child(rh)
	var split := UI.hb(0)
	for part in [[UI.CYAN, mine], [UI.RED, theirs]]:
		var r := ColorRect.new()
		r.color = part[0]
		r.custom_minimum_size.y = 8
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.size_flags_stretch_ratio = max(0.05, float(part[1]))
		split.add_child(r)
	v.add_child(split)
	var verdict: Array = ["Favoured", UI.GREEN] if ratio > 1.15 else (["Fair fight", UI.GOLD] if ratio > 0.9 else (["Hard", Color("#FF8A3A")] if ratio > 0.7 else ["Deadly", UI.RED]))
	if mine == 0:
		verdict = ["No %s warlords" % info.name, UI.RED]
	v.add_child(UI.lbl(verdict[0], 15, verdict[1]))
	v.add_child(UI.cap("Neon drop (win)", UI.DIM, 14))
	v.add_child(UI.lbl(_odds_text(row.ranks), 15, UI.MAGENTA, HORIZONTAL_ALIGNMENT_LEFT, true))
	v.add_child(UI.lbl("Warlord XP: %s (split across the squad)" % U.fmt(2000 + 1000 * stage), 14, UI.SOFT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var go := UI.cta("BATTLE", func(): main.start_encounter(Content.build_sw(syn, stage)), str(int(row.tokens)), "ticket")
	go.disabled = mine == 0
	outer.add_child(go)
	return p

## Neon rank odds, e.g. "R1 35%  •  R2 40%  •  R3 25%".
func _odds_text(ranks: Dictionary) -> String:
	var total := 0.0
	for k in ranks:
		total += float(ranks[k])
	var parts: Array = []
	for k in ranks:
		if float(ranks[k]) > 0:
			parts.append("R%s %d%%" % [k, int(round(float(ranks[k]) / max(0.001, total) * 100.0))])
	return "  •  ".join(parts)
