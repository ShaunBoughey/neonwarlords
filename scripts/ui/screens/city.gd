extends Screen
## City Centre hub (RAID-style home): your squad in 3D centre stage, district hotspots as neon signs,
## quest/event icons with badges on the left, big BATTLE hex bottom-right.

const TUTORIAL := [
	["Welcome to the City", "You lead a ragtag gang fighting through the syndicates of a neon city. Level up Warlords, collect gear and climb the Pit."],
	["Battle", "BATTLE opens the Campaign (10 dens x 7 stages, 3 difficulties), Hideouts (boss fights for gear, implants, credits, fragments and deeds), Syndicate Wars (Neons), the Pit (PvP) and Bastions."],
	["Combat", "Turn meters fill by Speed. On your turn pick a skill, then a target. The first Warlord in your squad is the Leader and grants their Leader ability."],
	["Armoury", "Tap a Warlord to open the Armoury: equip 6 gear pieces and 3 implants (AUTO EQUIP picks the best), upgrade gear with Credits, graft Neons, spend Memory Fragments in the Neuronet, raise Reputation with Deeds and Rank up."],
	["Recruit", "Open Contracts to recruit Warlords. Break down unwanted Warlords into scrap - 10 scrap makes a contract."],
	["Daily loop", "Collect Login Rewards, complete Missions, claim Trinium Stocks, spend Pit Coin at the Black Market and Safehouse, and hit the Bastion with your Gang."],
]

func build() -> void:
	show_nav = true
	bg_mode = "photo"
	screen_title = "City Centre"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var squad: Array = Game.S.squads.last.filter(func(u): return Game.wl(u) != null)
	# --- centre: the active squad (3D)
	var mp := ModelPreview.new()
	mp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mp.offset_left = 250
	mp.offset_right = -340
	mp.offset_top = 60
	mp.offset_bottom = -96
	mp.spacing = 1.5
	mp.cam_dist = 4.0
	mp.auto_spin = 0.0
	mp.ref_aspect = 1.6   # 16:9 line-up width; 4:3 keeps it instead of cropping the outer models
	add_child(mp)
	move_child(mp, 0)
	var models: Array = []
	for u in squad:
		models.append({"tpl": Game.wl(u).tpl})
	mp.set_models(models)
	var head := UI.vb(2)
	head.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	head.offset_left = -200
	head.offset_right = 140
	head.offset_top = 18
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hc := UI.cap("Active squad", UI.CYAN)
	hc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_child(hc)
	var pw := UI.disp("Power " + U.fmt(Game.team_power(squad)), 28)
	pw.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pw.add_theme_color_override("font_shadow_color", Color(UI.CYAN, 0.45))
	pw.add_theme_constant_override("shadow_outline_size", 12)
	head.add_child(pw)
	add_child(head)
	var tap := UI.btn("", func(): pass, "normal")
	tap.flat = true
	for st in ["normal", "hover", "pressed"]:
		tap.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap.offset_left = 300
	tap.offset_right = -380
	tap.offset_top = 90
	tap.offset_bottom = -110
	tap.tooltip_text = "Open the Armoury"
	# tap a warlord to open their Armoury page (models are laid out evenly left to right)
	tap.pressed.connect(func():
		if squad.is_empty():
			main.go("armory")
			return
		var i := clampi(int(tap.get_local_mouse_position().x / max(1.0, tap.size.x) * squad.size()), 0, squad.size() - 1)
		main.go("warlord", {"uid": squad[i]}))
	add_child(tap)
	# --- left: quick rail
	var left := UI.vb(14)
	left.position = Vector2(20, 24)
	add_child(left)
	_icon_btn(left, "gift", "Daily login", func(): main.go("login_rewards"), 0 if Game.S.login.claimed else 1)
	_icon_btn(left, "list", "Missions", func(): main.go("missions"), Game.jobs_claimable() + Game.ambitions_claimable())
	_icon_btn(left, "ticket", "Battle pass", func(): main.go("battle_pass"), _bp_badge(), "battle_pass")
	_icon_btn(left, "mail", "Inbox", func(): main.go("inbox"), Game.unclaimed_mail())
	_icon_btn(left, "clock", "Events", func(): main.go("events"), 0, "events")
	# --- right: district signboards
	var right := UI.vb(10)
	right.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	right.offset_left = -320
	right.offset_right = -20
	right.offset_top = 20
	add_child(right)
	_sign(right, "The Plaza", "Hourly credit market", UI.YELLOW, func(): main.go("plaza"), false, "plaza")
	_sign(right, "Black Market", "Pit Coin store", UI.CYAN, func(): main.go("black_market"), false, "black_market")
	_sign(right, "Safehouse", "Permanent stat nodes", UI.CYAN, func(): main.go("safehouse"), false, "safehouse")
	var stocks_ready: bool = Game.stocks_level() > 0 and Game.S.stocks.stored >= 1.0
	_sign(right, "Trinium Stocks", ("Ready to collect  •  %d" % int(Game.S.stocks.stored)) if stocks_ready else _stocks_text(), UI.GOLD if stocks_ready else UI.CYAN, func(): _stocks(), stocks_ready)
	_sign(right, "Inventory", "%d items  •  %d neons" % [Game.S.equip.size(), Game.S.neons.size()], UI.CYAN, func(): main.go("inventory"))
	_sign(right, "Settings", "Account, audio, developer" if OS.is_debug_build() else "Account and audio", UI.HINT, func(): main.go("settings"))
	# --- bottom: next goal + battle
	var goal := PanelContainer.new()
	goal.add_theme_stylebox_override("panel", UI._sb(UI.PANEL, Color(0, 0, 0, 0), 0, UI.NOTCH, 14))
	goal.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	goal.offset_left = 20
	goal.offset_top = -84
	goal.offset_right = 460
	goal.offset_bottom = -18
	var gh := UI.hb(12)
	var gv := UI.vb(2)
	UI.expand(gv)
	gv.add_child(UI.cap("Next goal", UI.CYAN))
	var ng := _next_goal()
	var gl := UI.lbl(ng.text, 17, UI.TEXT)
	gl.clip_text = true
	gv.add_child(gl)
	gh.add_child(gv)
	var gob := UI.btn("GO", func(): main.go("campaign", ng.params), "primary", 64, 14)
	gob.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	gh.add_child(gob)
	goal.add_child(gh)
	add_child(goal)
	var battle := CtaHex.new()
	battle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	battle.offset_left = -234
	battle.offset_top = -112
	battle.offset_right = -24
	battle.offset_bottom = -20
	battle.set_meta("coach", "battle")
	battle.pressed.connect(func(): main.go("fight"))
	add_child(battle)
	var reset := UI.lbl("Daily reset %s  •  Weekly %s" % [U.dur(U.secs_to_next_day()), U.dur(U.secs_to_next_week())], 13, UI.HINT)
	reset.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	reset.offset_left = -560
	reset.offset_right = -250
	reset.offset_top = -40
	reset.offset_bottom = -22
	reset.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(reset)

func _icon_btn(parent: Control, icon: String, label: String, cb: Callable, badge: int, feature := "") -> void:
	var locked := feature != "" and not Game.feature_ok(feature)
	if locked:
		icon = "lock"
		label = "%s  •  Lv %d" % [label, Game.feature_level(feature)]
		badge = 0
	var row := Button.new()
	row.focus_mode = Control.FOCUS_NONE
	row.flat = true
	for st in ["normal", "hover", "pressed"]:
		row.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	row.custom_minimum_size = Vector2(190, 52)
	var h := HexButton.new()
	h.fill = Color(UI.PANEL, 1.0)
	h.fill2 = Color(UI.PANEL, 1.0)
	h.border = UI.CYAN
	h.size = Vector2(58, 52)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(h)
	var ic := Icon.make(icon, UI.CYAN, 24)
	ic.position = Vector2(17, 14)
	row.add_child(ic)
	var l := UI.cap(label, UI.TEXT)
	l.position = Vector2(70, 17)
	row.add_child(l)
	if badge > 0:
		var b := UI.badge(badge)
		b.position = Vector2(42, -4)
		row.add_child(b)
	row.mouse_entered.connect(func():
		h.border = UI.CYAN.lightened(0.3)
		h.queue_redraw())
	row.mouse_exited.connect(func():
		h.border = UI.CYAN
		h.queue_redraw())
	row.pressed.connect(cb)
	parent.add_child(row)

func _sign(parent: Control, title: String, sub: String, col: Color, cb: Callable, hot := false, feature := "") -> void:
	if feature != "" and not Game.feature_ok(feature):
		sub = "Unlocks at Player Level %d" % Game.feature_level(feature)
		col = UI.HINT
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(300, 62)
	b.add_theme_stylebox_override("normal", UI._sb(UI.PANEL, Color(0, 0, 0, 0), 0, UI.NOTCH, 0))
	b.add_theme_stylebox_override("hover", UI._sb(Color(0.07, 0.24, 0.36, 0.96), UI.CYAN, 1, UI.NOTCH, 0))
	b.add_theme_stylebox_override("pressed", UI._sb(Color(UI.CYAN, 0.2), UI.CYAN, 1, UI.NOTCH, 0))
	var h := UI.hb(14)
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 16
	h.offset_right = -14
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(4, 34)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(bar)
	var v := UI.vb(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.expand(v)
	v.add_child(UI.disp(title, 15))
	v.add_child(UI.lbl(sub, 14, UI.GOLD if hot else UI.DIM))
	h.add_child(v)
	var chev := Icon.make("right", UI.CYAN, 18)
	chev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(chev)
	UI._ignore_mouse(h)
	b.add_child(h)
	b.pressed.connect(cb)
	parent.add_child(b)

func _bp_badge() -> int:
	if Game.S.bp.season < 0:
		return 0
	var n := 0
	for weekly in [false, true]:
		for c in Game.bp_challenges(weekly):
			if not c.claimed and c.cur >= c.target:
				n += 1
	return n

func _stocks_text() -> String:
	var lv := Game.stocks_level()
	if lv == 0:
		return "Locked"
	return "%d / %d stored  •  Lv %d" % [int(Game.S.stocks.stored), _stocks_cap(lv), lv]

func _stocks_cap(lv: int) -> int:
	return int(Data.STOCKS[lv].cap) + int(Game.S.stocks.get("cap_bonus", 0))

func _stocks_unlock_text(i: int) -> String:
	var req = Data.STOCK_LEVEL_AMBITION[i] if i < Data.STOCK_LEVEL_AMBITION.size() else null
	if req == null:
		return "unlocked from the start"
	return "unlocked by claiming Complete All Tier %d %s Ambitions" % [int(req[1]), req[0]]

func _stocks() -> void:
	var lv := Game.stocks_level()
	var v := UI.vb(10)
	v.add_child(UI.lbl("The Trinium Stocks pay out premium currency every day. Level %d of 3." % lv, 15, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	for i in range(1, 4):
		var row := "Level %d: %d Trinium / day, holds %d  (%s)" % [i, Data.STOCKS[i].daily, _stocks_cap(i), _stocks_unlock_text(i)]
		v.add_child(UI.lbl(row, 14, UI.GREEN if i <= lv else UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	if lv > 0:
		v.add_child(UI.bar(Game.S.stocks.stored, _stocks_cap(lv), UI.CYAN, 14))
		v.add_child(UI.lbl("%.1f Trinium stored" % Game.S.stocks.stored, 16, UI.CYAN))
	var cb := UI.btn("Collect", func():
		Game.collect_stocks()
		main.close_modal()
		rebuild(), "primary", 200)
	cb.disabled = lv == 0 or Game.S.stocks.stored < 1.0
	v.add_child(cb)
	main.modal("Trinium Stocks", v)

func _next_goal() -> Dictionary:
	for d in 3:
		for loc in 10:
			for st in 7:
				if Game.campaign_stars(d, loc, st) == 0:
					return {"text": "Clear %s %d-%d on %s" % [Data.GDD.campaign[loc].name, loc + 1, st + 1, Data.DIFFS[d]], "params": {"d": d, "loc": loc, "st": st}}
	return {"text": "Campaign complete - push the Hideouts", "params": {}}

func _tutorial(i: int) -> void:
	if i >= TUTORIAL.size():
		Game.S.tutorial_done = true
		Game.mark()
		return
	var v := UI.vb(12)
	v.add_child(UI.lbl(TUTORIAL[i][1], 16, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	var h := UI.hb()
	h.add_child(UI.lbl("%d / %d" % [i + 1, TUTORIAL.size()], 13, UI.DIM))
	h.add_child(UI.spacer())
	h.add_child(UI.btn("Skip", func():
		main.close_modal()
		_tutorial(TUTORIAL.size()), "ghost", 100))
	h.add_child(UI.btn("Next", func():
		main.close_modal()
		_tutorial(i + 1), "primary", 120))
	v.add_child(h)
	main.modal(TUTORIAL[i][0], v, false, false)
