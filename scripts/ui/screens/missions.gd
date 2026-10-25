extends Screen
## Jobs (daily / weekly / monthly) and Ambitions (lifetime missions).

var _gold_used := false

func build() -> void:
	_gold_used = false
	var tab: String = params.get("tab", "Daily")
	screen_title = "Missions"
	var job_tabs := ["Daily", "Weekly", "Monthly"]
	var amb_tabs: Array = Data.GDD.ambitions.keys()
	var jobs: Array = []
	for t in job_tabs:
		var n := 0
		for j in Game.jobs_list(t.to_lower()):
			if not j.claimed and j.cur >= j.target:
				n += 1
		jobs.append({"id": t, "name": t, "right": ("%d ready" % n) if n > 0 else "", "right_col": UI.GOLD, "col": UI.GREEN})
	var ambs: Array = []
	for c in amb_tabs:
		var n := 0
		for a2 in Game.ambitions_list(c):
			if not a2.claimed and a2.cur >= a2.target:
				n += 1
		ambs.append({"id": c, "name": c, "right": ("%d ready" % n) if n > 0 else "", "right_col": UI.GOLD, "col": UI.GREEN})
	var rl := rail([{"label": "Jobs", "items": jobs}, {"label": "Ambitions", "items": ambs}], tab, func(id):
		params.tab = id
		rebuild(), 240)
	rl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	rl.offset_left = 20
	rl.offset_right = 260
	rl.offset_top = 10
	rl.offset_bottom = -16
	add_child(rl)
	root.offset_left = 280
	if tab in job_tabs:
		_jobs(tab.to_lower())
	else:
		_ambitions(tab)

func _jobs(period: String) -> void:
	var reset := U.secs_to_next_day() if period == "daily" else (U.secs_to_next_week() if period == "weekly" else U.secs_to_next_month())
	root.add_child(UI.lbl("Jobs reset in %s." % U.dur(reset), 14, UI.DIM))
	var list := UI.vb(6)
	for j in Game.jobs_list(period):
		list.add_child(_row(j.text, j.rewards, j.cur, j.target, j.claimed, func(): main.show_rewards("Job Complete", Game.claim_job(period, j.i), rebuild)))
	root.add_child(UI.scroll(list))

func _ambitions(cat: String) -> void:
	root.add_child(UI.lbl("Ambitions are lifetime goals. Complete a tier to reveal the next.", 14, UI.DIM))
	var list := UI.vb(6)
	var last_tier := 0
	for a in Game.ambitions_list(cat):
		if a.tier != last_tier:
			last_tier = a.tier
			list.add_child(UI.lbl("Tier %d" % a.tier, 16, UI.YELLOW))
		var amb: Dictionary = a
		list.add_child(_row(a.text, a.rewards, a.cur, a.target, a.claimed, func(): main.show_rewards("Ambition Complete", Game.claim_ambition(cat, amb), rebuild)))
	root.add_child(UI.scroll(list))

func _row(text: String, rewards: Array, cur_v: int, target: int, claimed: bool, cb: Callable) -> PanelContainer:
	var done := cur_v >= target
	var acc := UI.DIM if claimed else (UI.GREEN if done else UI.CYAN)
	var p := PanelContainer.new()
	var sb := UI._sb(Color(0.04, 0.05, 0.12, 0.92) if not (done and not claimed) else Color(0.03, 0.12, 0.08, 0.92), acc.darkened(0.35), 1, 10, 12)
	sb.border_width_left = 6
	sb.border_color = acc.darkened(0.2)
	if done and not claimed:
		sb.shadow_color = Color(UI.GREEN.r, UI.GREEN.g, UI.GREEN.b, 0.3)
		sb.shadow_size = 8
	p.add_theme_stylebox_override("panel", sb)
	if claimed:
		p.modulate = Color(1, 1, 1, 0.55)
	var h := UI.hb(14)
	p.add_child(h)
	var v := UI.vb(4)
	UI.expand(v)
	var tl := UI.lbl(text.to_upper(), 14, UI.TEXT)
	var bf := Art.font(true)
	if bf:
		tl.add_theme_font_override("font", bf)
	v.add_child(tl)
	v.add_child(UI.reward_chips(rewards, 14))
	h.add_child(v)
	var pv := UI.vb(3)
	pv.custom_minimum_size.x = 190
	pv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ph := UI.hb()
	ph.add_child(UI.cap("Progress", UI.DIM, 13))
	ph.add_child(UI.spacer())
	ph.add_child(UI.lbl("%s / %s" % [U.fmt(mini(cur_v, target)), U.fmt(target)], 13, acc))
	pv.add_child(ph)
	pv.add_child(UI.bar(mini(cur_v, target), target, acc, 10))
	h.add_child(pv)
	# one gold CTA per screen: the first claimable row; the others are cyan
	var kind := "ghost"
	if done and not claimed:
		kind = "primary" if _gold_used else "gold"
		_gold_used = true
	var b := UI.btn("CLAIMED" if claimed else ("CLAIM" if done else "IN PROGRESS"), cb, kind, 150, 14)
	b.disabled = claimed or not done
	if done and not claimed:
		b.set_meta("coach", "claim")
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(b)
	return p
