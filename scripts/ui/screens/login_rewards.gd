extends Screen
## Monthly login calendar. Progress only advances on days you log in (no reset).

func build() -> void:
	header("Login Rewards")
	subtitle = "Next day in " + U.dur(U.secs_to_next_day())
	var g := UI.grid(7, 8)
	for d in ["Mon", "Tues", "Weds", "Thurs", "Fri", "Sat", "Sun"]:
		var dl := UI.cap(d, UI.HINT)
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		g.add_child(dl)
	var claimed_today: bool = Game.S.login.claimed
	var total: int = Data.GDD.login.size()
	# today's day stays on its card (ticked) after claiming, so day 31 doesn't wrap to day 1
	var cur_i := (int(Game.S.login.progress) - (1 if claimed_today else 0)) % total
	for i in total:
		var text: String = Data.GDD.login[i]
		var done := i < cur_i or (i == cur_i and claimed_today)
		var today := i == cur_i and not claimed_today
		var col := UI.GOLD if today else (UI.GREEN if done else UI.LINE)
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UI._sb_selected(UI.GOLD, 8, 6) if today else UI._sb(Color(UI.DEEP, 0.92), col, 1, 8, 6))
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p.custom_minimum_size.y = 92
		if done:
			p.modulate.a = 0.55
		var v := UI.vb(2)
		p.add_child(v)
		var dh := UI.hb()
		dh.add_child(UI.cap("Day %d" % (i + 1), UI.GOLD if today else UI.DIM, 13))
		dh.add_child(UI.spacer())
		if done:
			dh.add_child(Icon.make("check", UI.GREEN, 14))
		v.add_child(dh)
		var rew := U.parse_rewards(text)
		var holder := CenterContainer.new()
		holder.custom_minimum_size.y = 40
		if not rew.is_empty():
			holder.add_child(UI.reward_node(rew[0], 38))
		v.add_child(holder)
		v.add_child(UI.lbl(U.rewards_text(rew) if not rew.is_empty() else text, 14, UI.SOFT, HORIZONTAL_ALIGNMENT_CENTER, true))
		g.add_child(p)
	root.add_child(UI.scroll(g))
	var b := UI.btn("CLAIMED TODAY" if claimed_today else "CLAIM DAY %d" % (cur_i + 1), func(): main.show_rewards("Login Reward", Game.claim_login(), rebuild), "gold", 280, 20)
	b.custom_minimum_size.y = 56
	b.disabled = claimed_today
	var bh := UI.hb()
	bh.alignment = BoxContainer.ALIGNMENT_CENTER
	bh.add_child(b)
	root.add_child(bh)
