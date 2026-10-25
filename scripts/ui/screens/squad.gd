extends Screen
## Squad selection (RAID team setup): chosen warlords in 3D centre stage, leader crown, power vs enemy,
## roster strip along the bottom. Slot 1 is the Leader. Pit Royal adds 3 reinforcement slots.

var enc: Dictionary
var sel: Array = []
var team_size := 4
var filter_cls := ""

func build() -> void:
	enc = params.enc
	team_size = 7 if enc.get("royal", false) else 4
	if not params.has("sel"):
		var start: Array
		if enc.mode == "defence":
			start = Game.S.squads["pit_" + enc.pit_mode].duplicate()
		else:
			# a first Royal starts from the Royal defence gang so the reserve slots are filled
			var fallback: Array = Game.S.squads.get("pit_royal", []) if team_size == 7 else Game.S.squads.last
			start = Game.S.squads.get("royal" if team_size == 7 else "last", fallback).duplicate()
			if start.is_empty():
				start = Game.S.squads.last.duplicate()
		params.sel = start.filter(func(u): return Game.wl(u) != null and _allowed(Game.wl(u))).slice(0, team_size)
	sel = params.sel
	filter_cls = params.get("cls", "")
	root.add_theme_constant_override("separation", 6)
	# ---------------- header: encounter + enemy intel
	var h := header(String(enc.get("title", "Squad")).to_upper())
	h.add_child(UI.lbl(String(enc.get("subtitle", "")), 15, UI.DIM))
	var top := UI.hb(12)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(top)
	# ---------------- centre: 3D squad on stage + slot cards
	var stage := UI.vb(4)
	UI.expand(stage)
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var mp := ModelPreview.new()
	mp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mp.custom_minimum_size = Vector2(0, 220)
	mp.spacing = 1.45
	mp.cam_dist = 3.6
	mp.auto_spin = 0.0
	stage.add_child(mp)
	var models: Array = []
	for u in sel.slice(0, 4):
		models.append({"tpl": Game.wl(u).tpl})
	mp.set_models.call_deferred(models)
	var slots := UI.hb(8)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in team_size:
		var box := UI.vb(2)
		var cap := "LEADER" if i == 0 else ("RESERVE %d" % (i - 3) if i >= 4 else "SLOT %d" % (i + 1))
		box.add_child(UI.lbl(cap, 12, UI.YELLOW if i == 0 else UI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
		if i < sel.size():
			var w = Game.wl(sel[i])
			var uid: String = sel[i]
			box.add_child(UI.warlord_card(w, func(): _toggle(uid), true, true))
		else:
			var empty := UI.panel(UI.CYAN.darkened(0.6), Color(0.02, 0.03, 0.08, 0.75))
			empty.custom_minimum_size = Vector2(96, 120)
			empty.add_child(UI.lbl("+", 34, UI.CYAN.darkened(0.3), HORIZONTAL_ALIGNMENT_CENTER))
			box.add_child(empty)
		slots.add_child(box)
	stage.add_child(slots)
	top.add_child(stage)
	# ---------------- right: power comparison, leader skill, cost, start
	var side := UI.panel(UI.LINE, Color(0.04, 0.12, 0.19, 0.95), UI.NOTCH, 16)
	side.custom_minimum_size.x = 320
	var sv := UI.vb(10)
	side.add_child(sv)
	var mine := Game.team_power(sel.slice(0, 4))
	sv.add_child(UI.lbl("YOUR POWER", 12, UI.DIM))
	sv.add_child(_big(U.fmt(mine), UI.CYAN))
	if enc.has("waves"):
		var theirs := Content.enc_power(enc)
		sv.add_child(UI.lbl("ENEMY POWER", 12, UI.DIM))
		sv.add_child(_big(U.fmt(theirs), UI.RED))
		var ratio: float = float(mine) / max(1.0, float(theirs))
		var verdict := "EASY" if ratio > 1.3 else ("FAIR FIGHT" if ratio > 0.95 else ("HARD" if ratio > 0.75 else "VERY HARD"))
		var vcol := UI.GREEN if ratio > 1.3 else (UI.YELLOW if ratio > 0.95 else (Color("#ff8a3a") if ratio > 0.75 else UI.RED))
		sv.add_child(UI.lbl("DIFFICULTY: " + verdict, 15, vcol))
		sv.add_child(UI.bar(min(ratio, 2.0), 2.0, vcol, 8))
	if not sel.is_empty():
		var leader = Game.wl(sel[0])
		var lead_text := "No leader ability"
		for a in Game.tpl(leader).abilities:
			if a.type == "leader":
				lead_text = "%s - %s" % [a.name, a.desc]
		sv.add_child(UI.lbl("LEADER SKILL", 12, UI.DIM))
		sv.add_child(UI.lbl(lead_text, 13, UI.YELLOW, HORIZONTAL_ALIGNMENT_LEFT, true))
	if enc.has("lock_syn"):
		sv.add_child(UI.lbl("Syndicate Wars: %s only" % Data.SYNDICATES[enc.lock_syn].name, 13, Data.SYNDICATES[enc.lock_syn].color))
	sv.add_child(UI.spacer(false, 0, 4))
	var btns := UI.hb(6)
	btns.add_child(UI.btn("Auto-fill", func(): _auto(), "ghost"))
	btns.add_child(UI.btn("Clear", func():
		params.sel = []
		rebuild(), "ghost"))
	sv.add_child(btns)
	var foot := UI.hb(10)
	var cost_n := ""
	var cost_icon := "bolt"
	if enc.mode != "defence":
		var cost := Content.enc_cost(enc)
		for k in cost:
			cost_n = str(int(cost[k]))
			cost_icon = "bolt" if k == "energy" else ("mail" if k in ["brawl", "royal"] else "ticket")
			if k == "bastion":
				cost_n = "1 Entry" if int(Game.S.gang.bastion.get("entries", 0)) > 0 else "1 Raid Ticket"
		if Game.can_pay(cost) != "":
			foot.add_child(UI.lbl(Game.cost_text(cost), 15, UI.RED))
	var go := UI.cta("SAVE" if enc.mode == "defence" else "START", _start, cost_n, cost_icon)
	go.disabled = sel.is_empty()
	go.set_meta("coach", "start")
	UI.expand(go)
	foot.add_child(go)
	sv.add_child(foot)
	top.add_child(side)
	# ---------------- bottom: roster strip
	var ctrl := UI.hb(6)
	ctrl.add_child(UI.lbl("ROSTER", 14, UI.CYAN))
	ctrl.add_child(tabs(["All", "Armour", "Firepower", "Modder", "Hacker"], "All" if filter_cls == "" else U.cap(filter_cls), func(n):
		params.cls = "" if n == "All" else n.to_lower()
		rebuild()))
	root.add_child(ctrl)
	var roster: Array = Game.S.roster.filter(func(w): return _allowed(w) and (filter_cls == "" or Game.tpl(w).cls == filter_cls))
	roster.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	var strip := UI.hb(8)
	for w in roster:
		var uid: String = w.uid
		strip.add_child(UI.warlord_card(w, func(): _toggle(uid), sel.has(uid), true))
	var sc := UI.scroll(strip, true)
	sc.custom_minimum_size.y = 136
	sc.size_flags_vertical = Control.SIZE_SHRINK_END
	root.add_child(sc)

func _big(text: String, col: Color) -> Label:
	var l := UI.lbl(text, 30, col)
	var bf := Art.font(true)
	if bf:
		l.add_theme_font_override("font", bf)
	return l

func _allowed(w: Dictionary) -> bool:
	if enc.has("lock_syn"):
		return Game.tpl(w).syn == enc.lock_syn
	return true

func _toggle(uid: String) -> void:
	if sel.has(uid):
		sel.erase(uid)
	elif sel.size() < team_size:
		sel.append(uid)
	else:
		err("Squad is full")
		return
	rebuild()

func _auto() -> void:
	var roster: Array = Game.S.roster.filter(func(w): return _allowed(w))
	roster.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	params.sel = roster.slice(0, team_size).map(func(w): return w.uid)
	rebuild()

func _start() -> void:
	if enc.mode == "defence":
		Game.S.squads["pit_" + enc.pit_mode] = sel.duplicate()
		Game.mark()
		Game.say("Defence gang saved")
		main.back()
		return
	var e := Game.pay(Content.enc_cost(enc))
	if e != "":
		err(e)
		return
	if team_size == 7:
		Game.S.squads["royal"] = sel.duplicate()
	else:
		Game.S.squads.last = sel.duplicate()
	Game.mark()
	main.replace("battle", {"enc": enc, "team": sel.slice(0, 4), "reinf": sel.slice(4, 7)})
