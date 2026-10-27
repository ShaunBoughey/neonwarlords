extends Screen
## Battle Pass: 10 week seasons, 100 levels, free and premium tracks, daily/weekly merit challenges.

func build() -> void:
	var info := Game.bp_season_info()
	var h := header("BATTLE PASS", UI.YELLOW)
	h.add_child(UI.tag("Season %d" % info.season, UI.YELLOW))
	if not info.active:
		root.add_child(UI.lbl("The season has ended. The next season starts in %d days." % info.days_left, 18, UI.DIM))
		return
	h.add_child(UI.lbl("%d days left" % info.days_left, 15, UI.DIM))
	var lvl := Game.bp_level()
	var top := UI.panel(UI.YELLOW.darkened(0.3))
	var th := UI.hb(16)
	top.add_child(th)
	th.add_child(UI.lbl("Level %d / 100" % lvl, 24, UI.YELLOW))
	var mv := UI.vb(2)
	UI.expand(mv)
	var into := int(Game.S.bp.merits) % Data.BP_MERITS_PER_LEVEL
	if lvl >= 100:
		mv.add_child(UI.lbl("Merits: %d  (MAX LEVEL)" % int(Game.S.bp.merits), 14))
		mv.add_child(UI.bar(1, 1, UI.YELLOW, 8))
	else:
		mv.add_child(UI.lbl("Merits: %d  (%d / %d to next level)" % [int(Game.S.bp.merits), into, Data.BP_MERITS_PER_LEVEL], 14))
		mv.add_child(UI.bar(into, Data.BP_MERITS_PER_LEVEL, UI.YELLOW, 8))
	th.add_child(mv)
	if _claimable(lvl) > 0:
		th.add_child(UI.btn("CLAIM ALL (%d)" % _claimable(lvl), func(): _claim_all(lvl), "primary", 0, 14))
	var iap: bool = Game.S.settings.free_iap
	if Game.S.bp.premium:
		th.add_child(UI.lbl("PREMIUM ACTIVE", 18, UI.MAGENTA))
		if lvl < 25:
			th.add_child(UI.btn("+25 LV  £10", func():
				err(Game.bp_buy_premium(true))
				rebuild(), "primary" if iap else "ghost", 0, 14))
	else:
		th.add_child(UI.btn("PREMIUM  £15", func():
			err(Game.bp_buy_premium(false))
			rebuild(), "gold" if iap else "ghost", 0, 14))
		# "straight to level 25": nothing extra once you are already there
		if lvl < 25:
			th.add_child(UI.btn("PREMIUM +25 LV  £25", func():
				err(Game.bp_buy_premium(true))
				rebuild(), "primary" if iap else "ghost", 0, 14))
	root.add_child(top)
	# challenges
	var ch := UI.hb(12)
	for weekly in [false, true]:
		var p := UI.panel()
		UI.expand(p)
		var v := UI.vb(2)
		p.add_child(v)
		v.add_child(UI.lbl(("Weekly challenges (%d merits each, +%d bonus)" % [Data.BP_WEEKLY_MERITS, Data.BP_WEEKLY_BONUS]) if weekly else ("Daily challenges (%d merits each, +%d bonus)" % [Data.BP_DAILY_MERITS, Data.BP_DAILY_BONUS]), 14, UI.CYAN))
		for c in Game.bp_challenges(weekly):
			var rh := UI.hb(6)
			var l := UI.lbl("%s  %s/%s" % [c.text, U.fmt(c.cur), U.fmt(c.target)], 13, UI.DIM if c.claimed else UI.TEXT)
			UI.expand(l)
			rh.add_child(l)
			var wk: bool = weekly
			var cid: String = c.id
			var b := UI.btn("CLAIMED" if c.claimed else "CLAIM", func():
				Game.bp_claim_challenge(wk, cid)
				rebuild(), "primary" if c.cur >= c.target and not c.claimed else "ghost", 80, 13)
			b.disabled = c.claimed or c.cur < c.target
			b.custom_minimum_size.y = 34
			rh.add_child(b)
			# GDD: one weekly challenge may be reset each week
			if weekly and not c.claimed and Game.has_method("bp_reroll_weekly"):
				var used: bool = int(Game.S.bp.get("wreroll", -1)) == U.week_id()
				var rb := UI.btn("RESET", func():
					err(String(Game.call("bp_reroll_weekly", cid)))
					rebuild(), "ghost", 70, 13)
				rb.disabled = used
				rb.custom_minimum_size.y = 34
				rb.tooltip_text = "Reset used this week." if used else "Swap this challenge for another (once a week)."
				rh.add_child(rb)
			v.add_child(rh)
		ch.add_child(p)
	root.add_child(ch)
	# reward track
	var track := UI.hb(6)
	for row in Data.GDD.battlePass:
		var level := int(row[0])
		var col := UI.YELLOW if level <= lvl else UI.DIM
		var p := UI.panel(col.darkened(0.3) if level <= lvl else Color("#2a2c48"))
		p.custom_minimum_size = Vector2(150, 0)
		var v := UI.vb(4)
		p.add_child(v)
		v.add_child(UI.lbl("Lv %d" % level, 14, col, HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(_reward_cell(level, String(row[1]), false, lvl))
		v.add_child(_reward_cell(level, String(row[2]), true, lvl))
		track.add_child(p)
	var sc := UI.scroll(track, true)
	sc.custom_minimum_size.y = 222
	root.add_child(sc)
	root.add_child(UI.spacer(false, 0, 12))
	_scroll_to_level.call_deferred(sc, lvl)

func _scroll_to_level(sc: ScrollContainer, lvl: int) -> void:
	sc.scroll_horizontal = max(0, (lvl - 3) * 156)

func _reward_cell(level: int, text: String, paid: bool, lvl: int) -> Control:
	var p := UI.panel(UI.MAGENTA.darkened(0.4) if paid else UI.CYAN.darkened(0.5), Color("#0d0e24"))
	p.custom_minimum_size.y = 76
	var v := UI.vb(2)
	p.add_child(v)
	v.add_child(UI.lbl("PREMIUM" if paid else "FREE", 10, UI.MAGENTA if paid else UI.CYAN))
	if text == "":
		p.modulate.a = 0.45
		return p
	var rs := U.parse_rewards(text)
	var row := UI.hb(6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	if not rs.is_empty():
		row.add_child(UI.reward_node(rs[0], 30))
	var full := U.rewards_text(rs) if not rs.is_empty() else text
	var nm := UI.lbl(full, 12, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	nm.custom_minimum_size.x = 92
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	p.tooltip_text = full
	row.add_child(nm)
	v.add_child(row)
	var arr: Array = Game.S.bp.claimed_paid if paid else Game.S.bp.claimed_free
	var claimed := arr.has(level) or arr.has(float(level))
	var can: bool = level <= lvl and not claimed and (not paid or Game.S.bp.premium)
	var b := UI.btn("CLAIMED" if claimed else ("CLAIM" if can else "LOCKED"), func(): main.show_rewards("Battle Pass Lv %d" % level, Game.bp_claim(level, paid), rebuild), "primary" if can else "ghost", 0, 12)
	b.custom_minimum_size.y = 32
	b.disabled = not can
	v.add_child(b)
	return p

## Track rewards the player can claim right now.
func _claimable(lvl: int) -> int:
	var n := 0
	for row in Data.GDD.battlePass:
		var level := int(row[0])
		if level > lvl:
			break
		for paid in [false, true]:
			if String(row[2 if paid else 1]) == "" or (paid and not Game.S.bp.premium):
				continue
			var arr: Array = Game.S.bp.claimed_paid if paid else Game.S.bp.claimed_free
			if not (arr.has(level) or arr.has(float(level))):
				n += 1
	return n

func _claim_all(lvl: int) -> void:
	var got: Array = []
	for level in range(1, lvl + 1):
		for paid in [false, true]:
			got += Game.bp_claim(level, paid)
	main.show_rewards("Battle Pass rewards", got, rebuild)
