extends Screen
## Fighting scene: drives Battle.gd and plays its event log as RAID-style 3D combat.
## Layout follows the battle reference: floating vertical HP/turn bars per unit, red target
## reticles, big damage numbers, hex skill buttons bottom-right, AUTO / speed bottom-left.

signal chosen(ab_id: String, target_uid: String)

var enc: Dictionary
var team: Array
var b: Battle
var view: BattleView3D
var cards := {}            # unit uid -> {u, hud: UnitHud, hit: Button}
var hud_layer: Control
var fx_layer: Control
var skill_bar: HBoxContainer
var info_label: Label
var top_label: Label
var round_label: Label
var round_panel: Control
var boss_bar: ProgressBar
var boss_name: Label
var boss_info: Label
var paused := false        # set while the gear menu is open
## AUTO x10 multi-battle run, carried from battle to battle in params.run:
## {total, n, wins, items, pxp, wxp, auto (the player's AUTO setting before the run), stopped}
var run: Dictionary = {}
var run_stop_btn: Button
var _summary: Dictionary = {}   # Content.finish result (rewards granted once)
var _result_ov: Control
var auto_btn: HexButton
var speed_btn: HexButton
var actor = null
var pending_ab := ""
var waiting := false
var finished := false
var fled := false
var _returning := ""
var _side_count := [0, 0]

func _init() -> void:
	show_hud = false
	full_bleed = true

func rebuild() -> void:
	UI.clear(self)
	build()

func build() -> void:
	enc = params.enc
	team = params.team
	_setup_run()
	view = BattleView3D.new()
	view.loc_theme = BattleView3D.theme_for(enc)
	view.speed = 1.0 / _speed_mult()
	add_child(view)
	hud_layer = Control.new()
	hud_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_layer)
	fx_layer = Control.new()
	fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx_layer)
	# ---------------- top: encounter title (left) and settings gear (right)
	top_label = UI.lbl("", 17, UI.TEXT)
	top_label.add_theme_color_override("font_outline_color", Color.BLACK)
	top_label.add_theme_constant_override("outline_size", 5)
	top_label.position = Vector2(16, 10)
	add_child(top_label)
	var rp := UI.panel(UI.CYAN, Color(0.02, 0.06, 0.14, 0.85), 6, 8)
	rp.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	rp.offset_left = -270
	rp.offset_right = -92
	rp.offset_top = 22
	rp.offset_bottom = 56
	round_label = UI.lbl("", 15, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	var rf := Art.font(true)
	if rf:
		round_label.add_theme_font_override("font", rf)
	rp.add_child(round_label)
	add_child(rp)
	rp.visible = enc.waves.size() > 1   # "ROUND 1 OF 1" says nothing
	round_panel = rp
	if enc.get("turn_limit", 0) > 0:
		_build_boss_panel()
	var gear := HexButton.new()
	gear.icon_name = "settings"
	gear.fill = Color("#2a1840")
	gear.fill2 = Color("#4a2a70")
	gear.border = Color("#d8b8ff")
	gear.glyph_size = 30
	gear.custom_minimum_size = Vector2(64, 64)
	gear.size = Vector2(64, 64)
	gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gear.position = Vector2(-80, 8)
	gear.offset_left = -80
	gear.offset_right = -16
	gear.offset_top = 8
	gear.offset_bottom = 72
	gear.pressed.connect(_menu)
	add_child(gear)
	# ---------------- bottom-left: AUTO and speed hexes
	auto_btn = _hex_btn("AUTO", Vector2(16, -100), func(): _toggle_auto())
	auto_btn.glyph_size = 16   # "AUTO" at 20 spilled past the hex border
	speed_btn = _hex_btn("»", Vector2(108, -100), func(): _toggle_speed())
	# ---------------- bottom-right: skill hexes + description
	skill_bar = UI.hb(10)
	skill_bar.alignment = BoxContainer.ALIGNMENT_END
	skill_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skill_bar.offset_left = -560
	skill_bar.offset_right = -30
	skill_bar.offset_top = -142
	skill_bar.offset_bottom = -22
	skill_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(skill_bar)
	info_label = UI.lbl("", 14, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.add_theme_constant_override("outline_size", 4)
	info_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	info_label.offset_left = -330
	info_label.offset_right = 200
	info_label.offset_top = -64
	info_label.offset_bottom = -14
	add_child(info_label)
	_build_run_hud()
	_update_toggles()
	_setup_battle()
	_run.call_deferred()

## Turn-limited fights (Bastion): big boss HP bar, turns and running damage, top centre.
func _build_boss_panel() -> void:
	var p := UI.panel(Color("#ff2e55"), Color(0.06, 0.02, 0.06, 0.88), 6, 10)
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	p.offset_left = -280
	p.offset_right = 280
	p.offset_top = 10
	p.offset_bottom = 84
	var v := UI.vb(4)
	boss_name = UI.lbl("", 16, UI.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	boss_name.clip_text = true
	v.add_child(boss_name)
	boss_bar = UI.bar(1, 1, Color("#ff2e55"), 12)
	v.add_child(boss_bar)
	boss_info = UI.lbl("", 15, UI.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(boss_info)
	p.add_child(v)
	add_child(p)

# ================================================================ AUTO x10 multi-battle
func _setup_run() -> void:
	run = params.get("run", {})
	if run.is_empty() and int(enc.get("repeat", 0)) <= 1:
		return
	if run.is_empty():
		run = {"total": int(enc.repeat), "n": 0, "wins": 0, "items": [], "pxp": 0, "wxp": 0, "auto": Game.S.settings.auto, "stopped": false}
	run.n = int(run.n) + 1
	Game.S.settings.auto = true   # the run is always on auto; the player's setting comes back at the end

## "AUTO n/10" tag and a STOP button under the title.
func _build_run_hud() -> void:
	if run.is_empty():
		return
	var row := UI.hb(10)
	row.position = Vector2(16, 40)
	row.add_child(UI.tag("AUTO %d/%d" % [run.n, run.total], UI.GOLD))
	run_stop_btn = UI.btn("STOP", func(): _stop_run(), "danger", 110, 14)
	run_stop_btn.custom_minimum_size.y = 44
	row.add_child(run_stop_btn)
	add_child(row)

func _stop_run() -> void:
	run.stopped = true
	enc.repeat = 0
	if run_stop_btn != null and is_instance_valid(run_stop_btn):
		run_stop_btn.disabled = true
		run_stop_btn.text = "STOPPED"

## Group repeated drops (e.g. credits from every win) into one tile with a "x N" count.
func _merge_loot(items: Array) -> Array:
	var out: Array = []
	var by_label := {}
	for r in items:
		if r.has("equip") or r.has("warlord"):
			out.append(r)
			continue
		var key := String(r.label)
		if by_label.has(key):
			by_label[key].count += 1
		else:
			var c: Dictionary = r.duplicate()
			c.count = 1
			by_label[key] = c
			out.append(c)
	for c in out:
		if int(c.get("count", 1)) > 1:
			c.label = "%s ×%d" % [c.label, c.count]
	return out

func _hex_btn(glyph: String, pos: Vector2, cb: Callable) -> HexButton:
	var h := HexButton.new()
	h.glyph = glyph
	h.fill = Color("#341a5a")
	h.fill2 = Color("#5a2a8a")
	h.border = Color("#b06cff")
	h.custom_minimum_size = Vector2(84, 84)
	h.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	h.offset_left = pos.x
	h.offset_right = pos.x + 84
	h.offset_top = pos.y
	h.offset_bottom = pos.y + 84
	h.pressed.connect(cb)
	add_child(h)
	return h

func _setup_battle() -> void:
	b = Battle.new()
	var reinf: Array = Content.player_units(params.get("reinf", []))
	var waves: Array = []
	for wv in enc.waves:
		var arr: Array = []
		for u in wv:
			arr.append(u.duplicate(true))
		waves.append(arr)
	b.setup(Content.player_units(team), waves, {"turn_limit": enc.get("turn_limit", 0), "reinforcements": reinf, "enemy_reinforcements": enc.get("enemy_reinf", []).map(func(u): return u.duplicate(true)), "no_revive": enc.get("royal", false)})
	var per_side := [0, 0]
	for u in b.units:
		per_side[u.side] += 1
	for u in b.units:
		_add_card(u, -1, per_side[u.side])

func _process(_d: float) -> void:
	if view == null:
		return
	for uid in cards:
		var c: Dictionary = cards[uid]
		var head := view.screen_pos(uid, 2.05)
		var foot := view.screen_pos(uid, 0.1)
		var hud: UnitHud = c.hud
		hud.position = Vector2(foot.x - 62, foot.y - hud.size.y + 6)
		hud.reticle_pos = head - hud.position + Vector2(0, -22)
		var hgt: float = max(70.0, foot.y - head.y)
		c.hit.position = Vector2(foot.x - 40, head.y - 10)
		c.hit.size = Vector2(80, hgt + 16)

# ================================================================ per-unit HUD
func _add_card(u: Dictionary, idx := -1, count := 5) -> void:
	if idx < 0:
		idx = _side_count[u.side]
	_side_count[u.side] += 1
	view.add_unit(u, idx, count)
	var hud := UnitHud.new()
	hud.side = u.side
	hud.level = int(u.level)
	hud_layer.add_child(hud)
	var hit := Button.new()
	hit.flat = true
	hit.focus_mode = Control.FOCUS_NONE
	for st in ["normal", "hover", "pressed", "focus"]:
		hit.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var uid: String = u.uid
	hit.pressed.connect(func(): _card_clicked(uid))
	hit.mouse_entered.connect(func(): _hover(uid))
	hud_layer.add_child(hit)
	cards[u.uid] = {"u": u, "hud": hud, "hit": hit}
	_refresh_card(u.uid)

func _remove_card(uid: String) -> void:
	if cards.has(uid):
		cards[uid].hud.queue_free()
		cards[uid].hit.queue_free()
		cards.erase(uid)
	view.remove_unit(uid)

func _refresh_card(uid: String) -> void:
	if not cards.has(uid):
		return
	var c: Dictionary = cards[uid]
	var u: Dictionary = c.u
	var hud: UnitHud = c.hud
	hud.hp_ratio = u.hp / u.max_hp
	hud.shield_ratio = b.total_shield(u) / u.max_hp
	hud.tm_ratio = min(1.0, u.tm / 1000.0)
	hud.alive = u.alive
	var icons: Array = []
	var seen := {}
	for d in u.debuffs:
		if seen.has(d.id):
			continue
		seen[d.id] = true
		var cnt := b.debuff_count(u, d.id)
		icons.append({"id": d.id, "turns": cnt if cnt > 1 else int(d.turns), "debuff": true})
	for bf in u.buffs:
		if seen.has(bf.id):
			continue
		seen[bf.id] = true
		icons.append({"id": bf.id, "turns": int(bf.turns), "debuff": false})
	hud.icons = icons
	c.hit.visible = u.alive

func _refresh_all() -> void:
	for uid in cards:
		_refresh_card(uid)
	_update_top()

func _update_top() -> void:
	round_label.text = "ROUND %d OF %d" % [b.wave_no, b.wave_total]
	if enc.get("turn_limit", 0) > 0:
		top_label.text = enc.get("title", "")
		var foes: Array = b.side_units(1, false)
		if not foes.is_empty() and boss_bar != null:
			var boss: Dictionary = foes[0]
			for f in foes:
				if f.boss:
					boss = f
					break
			boss_name.text = String(boss.name).to_upper()
			boss_bar.max_value = max(1.0, float(boss.max_hp))
			boss_bar.value = float(boss.hp)
			boss_info.text = "TURNS %d/%d   •   DAMAGE %s" % [b.player_turns, enc.turn_limit, U.fmt(b.damage_to_side(1))]
	else:
		top_label.text = "%s  •  %s" % [enc.get("title", ""), enc.get("subtitle", "")]

func _set_targets(valid: Array) -> void:
	for uid in cards:
		cards[uid].hud.targetable = valid.has(uid)

func _hover(uid: String) -> void:
	var u = b.unit(uid)
	if u == null or waiting and pending_ab != "":
		return
	var parts: Array = []
	for bf in u.buffs:
		parts.append("%s (%dt)" % [Data.BUFFS[bf.id].name, bf.turns])
	for d in u.debuffs:
		parts.append("%s (%dt)" % [Data.DEBUFFS[d.id].name, d.turns])
	info_label.text = "%s  Lv%d  •  HP %s/%s  •  SPD %d  ARM %d  FP %d%s" % [u.name, u.level, U.fmt(u.hp), U.fmt(u.max_hp), b.eff(u, "spd"), b.eff(u, "arm"), b.eff(u, "fp"), ("  •  " + ", ".join(parts)) if not parts.is_empty() else ""]

# ================================================================ main loop
func _run() -> void:
	b.start()
	await _play(b.take_events())
	while b.result == "" and not fled and is_inside_tree():
		while paused and not fled and is_inside_tree():
			await get_tree().process_frame
		var t = b.next_turn()
		await _play(b.take_events())
		if t == null:
			break
		actor = t.actor
		info_label.text = ""
		_refresh_all()
		_highlight_actor()
		var ab_id := ""
		var target := ""
		if t.has("forced_ab"):
			ab_id = t.forced_ab
			target = t.forced_target
			if actor.side == 0:
				info_label.text = "%s is forced to use %s" % [actor.name, b.get_ability(actor, ab_id).name]
			await _wait(0.4)
		elif actor.side == 1 or Game.S.settings.auto:
			var c := b.ai_choose(actor)
			ab_id = c.ab
			target = c.target
			await _wait(0.15)
		else:
			_show_abilities()
			waiting = true
			var res: Array = await chosen
			waiting = false
			if fled:
				break
			ab_id = res[0]
			target = res[1]
		_clear_abilities()
		if b.result != "" or fled:
			break
		b.act(actor, ab_id, target)
		await _play(b.take_events())
		actor = null
		_refresh_all()
	if not is_inside_tree():
		return
	_refresh_all()
	await _wait(0.8)
	_finish()

func _speed_mult() -> float:
	return [1.0, 0.5, 0.25][clampi(int(Game.S.settings.speed) - 1, 0, 2)]

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec * _speed_mult()).timeout

func _highlight_actor() -> void:
	for uid in cards:
		cards[uid].hud.active = actor != null and uid == actor.uid
	view.set_selected(actor.uid if actor != null else "", "active")

# ================================================================ player input (hex skills)
const SKILL_COLORS := {
	"damage": [Color("#b8320f"), Color("#ffb347"), Color("#ff2e88")],
	"aoe": [Color("#7a1030"), Color("#ff6a2a"), Color("#ff2e88")],
	"buff": [Color("#123a7a"), Color("#3fc8ff"), Color("#29e3ff")],
	"heal": [Color("#0f5a2a"), Color("#59ff8a"), Color("#38e07b")],
	"debuff": [Color("#4a1070"), Color("#c04cff"), Color("#b45cff")],
}

func _skill_kind(a: Dictionary) -> String:
	if float(a.get("mult", 0)) > 0.0:
		return "aoe" if a.get("tgt", "") == "all_enemies" else "damage"
	for f in a.get("fx", []):
		if f.t == "heal" or f.t == "revive":
			return "heal"
		if f.t == "debuff" or f.t == "strip":
			return "debuff"
	return "buff"

## Stroke icon (Icon.paint) for a skill hex, by skill kind.
func _skill_glyph(a: Dictionary) -> String:
	match _skill_kind(a):
		"damage": return "swords"
		"aoe": return "star"
		"heal": return "plus"
		"debuff": return "skull"
	return "up"

func _show_abilities() -> void:
	UI.clear(skill_bar)
	pending_ab = ""
	info_label.text = "%s's turn" % actor.name
	for a in b.actives(actor):
		if a.get("auto", false):
			continue
		var cd := int(actor.cds.get(a.id, 0))
		var ab: Dictionary = a
		var h := HexButton.new()
		var kc: Array = SKILL_COLORS[_skill_kind(a)]
		h.fill = kc[0]
		h.fill2 = kc[1]
		h.border = kc[2]
		h.icon_name = _skill_glyph(a)
		h.glyph_size = 40
		h.caption = String(a.name).to_upper()
		h.cooldown = cd
		h.disabled = cd > 0
		h.custom_minimum_size = Vector2(118, 118)
		h.set_meta("ab", a.id)
		h.tooltip_text = "%s  (Lv %d)\n%s%s" % [a.name, int(actor.ab_lv.get(a.id, 1)), a.desc, ("\nCooldown: %d turns" % a.cd) if a.cd > 0 else ""]
		h.pressed.connect(func(): _pick_ability(ab))
		skill_bar.add_child(h)
	var first: Array = b.actives(actor).filter(func(a): return b.ability_ready(actor, a))
	if not first.is_empty():
		_pick_ability(first[0])

func _pick_ability(a: Dictionary) -> void:
	if pending_ab == a.id and a.tgt in ["all_enemies", "all_allies", "self"]:
		chosen.emit(a.id, actor.uid if a.tgt != "all_enemies" else _first_enemy())
		return
	pending_ab = a.id
	for c in skill_bar.get_children():
		if c is HexButton:
			c.selected = c.get_meta("ab", "") == a.id
			c.queue_redraw()
	var hint := ""
	match a.tgt:
		"enemy": hint = "Tap an enemy."
		"ally": hint = "Tap an ally."
		"all_enemies": hint = "Hits all enemies - tap an enemy or the skill again."
		_: hint = "Tap any ally or the skill again."
	info_label.text = "%s: %s  %s" % [String(a.name).to_upper(), a.desc, hint]
	var valid: Array = []
	for uid in cards:
		if _valid_target(a, cards[uid].u):
			valid.append(uid)
	_set_targets(valid if a.tgt in ["enemy", "all_enemies"] else [])
	view.set_selected(actor.uid, "active")
	view.mark_targets(valid)

func _valid_target(a: Dictionary, u: Dictionary) -> bool:
	if not u.alive:
		return false
	match a.tgt:
		"enemy", "all_enemies": return u.side != actor.side
		_: return u.side == actor.side

## Guide hook: the first living enemy's tap area while the player is choosing a target.
func coach_node(id: String) -> Control:
	if id != "enemy" or not waiting or actor == null:
		return null
	for f in b.foes(actor):
		if cards.has(f.uid):
			return cards[f.uid].hit
	return null

func _first_enemy() -> String:
	var f := b.foes(actor)
	return f[0].uid if not f.is_empty() else ""

func _card_clicked(uid: String) -> void:
	if not waiting or pending_ab == "":
		_hover(uid)
		return
	var a = b.get_ability(actor, pending_ab)
	var u = b.unit(uid)
	if a == null or u == null or not _valid_target(a, u):
		_hover(uid)
		return
	chosen.emit(pending_ab, uid)

func _clear_abilities() -> void:
	UI.clear(skill_bar)
	pending_ab = ""
	_set_targets([])
	_highlight_actor()

func _toggle_auto() -> void:
	Game.S.settings.auto = not Game.S.settings.auto
	Game.mark()
	_update_toggles()
	if Game.S.settings.auto and waiting and actor != null:
		var c := b.ai_choose(actor)
		chosen.emit(c.ab, c.target)

func _toggle_speed() -> void:
	Game.S.settings.speed = (int(Game.S.settings.speed) % 3) + 1
	Game.mark()
	view.speed = 1.0 / _speed_mult()
	_update_toggles()

func _update_toggles() -> void:
	auto_btn.selected = Game.S.settings.auto
	auto_btn.fill = Color("#5a1a8a") if Game.S.settings.auto else Color("#2a1a44")
	auto_btn.queue_redraw()
	speed_btn.glyph = ["»", "»»", "»»»"][clampi(int(Game.S.settings.speed) - 1, 0, 2)]
	speed_btn.selected = int(Game.S.settings.speed) > 1
	speed_btn.queue_redraw()

func _menu() -> void:
	paused = true
	var v := UI.vb(10)
	v.add_child(UI.lbl("Battle paused", 15, UI.DIM))
	v.add_child(UI.btn("Resume", func():
		paused = false
		main.close_modal(), "primary", 240))
	v.add_child(UI.btn("Flee (counts as defeat)", func():
		paused = false
		main.close_modal()
		_flee(), "danger", 240))
	main.modal("Menu", v)
	# closing the modal any other way (X, backdrop) also resumes
	v.tree_exited.connect(func(): paused = false)

func _flee() -> void:
	fled = true
	b.result = "loss"
	if waiting:
		chosen.emit("", "")

# ================================================================ event playback
func _play(events: Array) -> void:
	view.speed = 1.0 / _speed_mult()
	for e in events:
		if not is_inside_tree():
			return
		match e.e:
			"ability":
				await _finish_return()
				await _choreograph(b.unit(e.u), e)
			"dmg":
				var crit: bool = e.crit
				Sfx.play("crit" if crit else "hit")
				_float(e.u, U.fmt(e.v), Color("#ff2e3c"), 34 if crit else 26, crit)
				view.hit(e.u, crit)
				_refresh_card(e.u)
				await _wait(0.1)
			"heal":
				Sfx.play("heal")
				_float(e.u, "+" + U.fmt(e.v), UI.GREEN, 22)
				_refresh_card(e.u)
				await _wait(0.06)
			"buff":
				Sfx.play("buff")
				_float(e.u, Data.BUFFS[e.id].name, UI.CYAN, 15)
				_refresh_card(e.u)
				await _wait(0.05)
			"debuff":
				Sfx.play("debuff")
				_float(e.u, Data.DEBUFFS[e.id].name, Color("#ff4fb0"), 15)
				_refresh_card(e.u)
				await _wait(0.05)
			"resist":
				_float(e.u, "RESISTED", UI.DIM, 16)
				await _wait(0.05)
			"block":
				_float(e.u, "BLOCKED", UI.DIM, 16)
				await _wait(0.05)
			"text":
				_float(e.u, String(e.t).to_upper(), UI.YELLOW, 16)
				await _wait(0.06)
			"skip":
				_float(e.u, String(e.why).to_upper(), UI.PURPLE, 22)
				await _wait(0.35)
			"overtime":
				Sfx.play("debuff")
				_banner("OVERTIME" if int(e.lvl) == 1 else "OVERTIME x%d" % int(e.lvl))
				var otl := UI.cap("Overtime %d  •  healing -%d%%  •  damage +%d%%" % [int(e.lvl), mini(100, 50 + 25 * (int(e.lvl) - 1)), 20 * int(e.lvl)], UI.RED, 13)
				otl.name = "OvertimeTag"
				var old_tag := hud_layer.get_node_or_null("OvertimeTag")
				if old_tag:
					old_tag.queue_free()
				otl.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
				otl.offset_left = -200
				otl.offset_right = 200
				otl.offset_top = 60
				otl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				hud_layer.add_child(otl)
			"death":
				Sfx.play("death")
				view.die(e.u)
				_refresh_card(e.u)
				if _returning == e.u:
					_returning = ""
				await _wait(0.25)
			"revive":
				_float(e.u, "REVIVED", UI.GREEN, 22)
				view.revive(e.u)
				_refresh_card(e.u)
				await _wait(0.25)
			"wave":
				await _finish_return()
				for uid in cards.keys():
					var cu: Dictionary = cards[uid].u
					if cu.side == 1 and not cu.alive:
						_remove_card(uid)
				_side_count[1] = 0
				for uid in e.units:
					_add_card(b.unit(uid), -1, e.units.size())
				_banner("WAVE %d" % e.n)
				await _wait(0.9)
			"spawn":
				_remove_card(e.replaces)
				_add_card(b.unit(e.u))
				_float(e.u, "REINFORCEMENT", UI.CYAN, 18)
				await _wait(0.3)
			"tm", "expire", "turn":
				_refresh_card(e.u)
			"end":
				await _finish_return()
				view.victory(0 if e.result == "win" else 1)
	await _finish_return()
	_refresh_all()

## RAID-style action for an ability: melee rush, ranged bolts or a cast.
func _choreograph(u: Dictionary, e: Dictionary) -> void:
	var a = b.get_ability(u, e.id)
	var targets: Array = e.targets
	var damaging: bool = a != null and float(a.get("mult", 0.0)) > 0.0
	var big: bool = a != null and int(a.get("cd", 0)) > 0 and not e.get("assist", false)
	if big:
		view.punch(e.u)
		Sfx.play("skill")
		_skill_banner(u, a.name)
		await _wait(0.25)
	var syn_col: Color = Data.SYNDICATES[u.syn].color.lightened(0.2)
	if big:
		var kind := BattleView3D.vfx_kind(a, u.cls)
		if damaging:
			var sfoes: Array = targets.filter(func(t): return b.unit(t) != null and b.unit(t).side != u.side)
			if sfoes.is_empty():
				sfoes = targets
			await view.signature_attack(kind, e.u, sfoes, syn_col)
			if kind == "slash":
				_returning = e.u
		else:
			await view.signature_support(kind, e.u, targets, SKILL_COLORS[_skill_kind(a)][2])
		return
	if damaging:
		var foes: Array = targets.filter(func(t): return b.unit(t) != null and b.unit(t).side != u.side)
		if foes.is_empty():
			foes = targets
		if foes.is_empty():
			return
		if u.cls == "armour":
			await view.melee(e.u, foes[0])
			_returning = e.u
		elif u.cls == "modder":
			await view.ranged(e.u, foes, syn_col, "cast")
		else:
			await view.ranged(e.u, foes, syn_col, "shoot")
	else:
		var kind := _skill_kind(a) if a != null else "buff"
		var fx_col: Color = SKILL_COLORS[kind][2]
		await view.cast(e.u, targets, fx_col)

func _finish_return() -> void:
	if _returning != "":
		var r := _returning
		_returning = ""
		await view.return_home(r)

func _skill_banner(u: Dictionary, name: String) -> void:
	var l := UI.lbl(String(name).to_upper(), 32, UI.CYAN if u.side == 0 else Color("#ff2e3c"), HORIZONTAL_ALIGNMENT_CENTER)
	var f := Art.font(true)
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.custom_minimum_size = Vector2(700, 50)
	l.position = Vector2(size.x / 2 - 350, size.y * 0.16)
	fx_layer.add_child(l)
	var tw := create_tween()
	tw.tween_interval(0.7 * _speed_mult())
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)

func _float(uid: String, text: String, color: Color, fsize: int, crit := false) -> void:
	var l := UI.lbl(text, fsize, color, HORIZONTAL_ALIGNMENT_CENTER)
	var f := Art.font(true)
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0, 0.05) if color == Color("#ff2e3c") else Color.BLACK)
	l.add_theme_constant_override("outline_size", 7)
	l.custom_minimum_size.x = 260
	fx_layer.add_child(l)
	var base := view.screen_pos(uid, 2.3) if view.actors.has(uid) else size / 2
	l.position = base + Vector2(-130 + randf_range(-26, 26), randf_range(-10, 10))
	if crit:
		l.scale = Vector2(1.5, 1.5)
		l.pivot_offset = Vector2(130, 20)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.2)
	tw.tween_property(l, "position:y", l.position.y - 54, 1.0 * max(0.4, _speed_mult()))
	tw.tween_property(l, "modulate:a", 0.0, 0.5 * max(0.4, _speed_mult())).set_delay(0.55 * max(0.4, _speed_mult()))
	tw.chain().tween_callback(l.queue_free)

func _banner(text: String) -> void:
	var l := UI.lbl(text, 64, UI.MAGENTA, HORIZONTAL_ALIGNMENT_CENTER)
	var f := Art.font(true)
	if f:
		l.add_theme_font_override("font", f)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 10)
	l.position = size / 2 - Vector2(300, 50)
	l.custom_minimum_size = Vector2(600, 100)
	fx_layer.add_child(l)
	var tw := create_tween()
	tw.tween_interval(0.6 * _speed_mult())
	tw.tween_property(l, "modulate:a", 0.0, 0.4)
	tw.tween_callback(l.queue_free)

# ================================================================ result screen
func _finish() -> void:
	if finished:
		return
	finished = true
	# rewards are granted once; a redraw (STOP on the result screen) reuses them
	var first := _summary.is_empty()
	if first:
		_summary = Content.finish(enc, b, team)
	var summary: Dictionary = _summary
	var won: bool = summary.won
	# AUTO x10: tally this battle once, then decide whether the run goes on
	var run_next := false
	var run_end := ""
	if not run.is_empty():
		if first:
			run.wins = int(run.wins) + (1 if won else 0)
			run.items.append_array(summary.items)
			run.pxp = int(run.pxp) + int(summary.pxp)
			run.wxp = int(run.wxp) + int(summary.xp_each)
		var more: bool = int(enc.get("repeat", 0)) > 1 and not run.stopped
		var can: bool = Game.can_pay(Content.enc_cost(Content.rebuild(enc))) == ""
		run_next = won and more and can
		if not run_next:
			run_end = "Out of energy" if run.get("out", false) else ("Stopped" if run.stopped else ("Defeated" if not won else ("Out of energy" if more else "Done")))
			Game.S.settings.auto = run.auto
			Game.mark()
	var bastion: bool = enc.mode == "bastion"
	var col := UI.YELLOW if won else UI.RED
	if first:
		Sfx.music("", 0.6)
		Sfx.play("victory" if won else "defeat")
		if won and not summary.levels.is_empty():
			get_tree().create_timer(0.9).timeout.connect(func(): Sfx.play("levelup"))
	for c in get_children():
		if c != view:
			c.visible = false
	if _result_ov != null and is_instance_valid(_result_ov):
		_result_ov.queue_free()
	var ov := ColorRect.new()
	_result_ov = ov
	ov.color = Color(0.01, 0.0, 0.04, 0.0)
	ov.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(ov)
	create_tween().tween_property(ov, "color:a", 0.82, 0.35)
	var v := UI.vb(8)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 20
	v.offset_bottom = -34
	v.offset_left = 40
	v.offset_right = -40
	ov.add_child(v)
	var head := UI.lbl("BASTION COMPLETE" if bastion else ("VICTORY" if won else "DEFEAT"), 60 if not run.is_empty() else 76, col, HORIZONTAL_ALIGNMENT_CENTER)
	var hf := Art.font(true)
	if hf:
		head.add_theme_font_override("font", hf)
	head.add_theme_color_override("font_shadow_color", Color(col.r, col.g, col.b, 0.6))
	head.add_theme_constant_override("shadow_outline_size", 22)
	head.add_theme_color_override("font_outline_color", Color.BLACK)
	head.add_theme_constant_override("outline_size", 6)
	head.pivot_offset = Vector2(600, 40)
	head.scale = Vector2(1.6, 1.6)
	v.add_child(head)
	create_tween().tween_property(head, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sub := "%s  •  %s  •  %d turn%s" % [enc.get("title", ""), enc.get("subtitle", ""), b.player_turns, "" if b.player_turns == 1 else "s"]
	v.add_child(UI.lbl(sub, 16, UI.DIM, HORIZONTAL_ALIGNMENT_CENTER))
	if not run.is_empty():
		# AUTO x10 status sits under the subtitle (no extra row, so the buttons keep their margin)
		var rl := ""
		if run_next:
			rl = "AUTO %d/%d  •  next battle starting…" % [run.n, run.total]
		else:
			rl = "AUTO RUN %s  •  %d battle%s, %d won  •  Warlord XP +%s each" % [run_end.to_upper(), run.n, "" if int(run.n) == 1 else "s", run.wins, U.fmt(run.wxp)]
		v.get_child(v.get_child_count() - 1).text = sub + "
" + rl
		v.get_child(v.get_child_count() - 1).add_theme_color_override("font_color", UI.GOLD)
	if enc.mode in ["campaign", "sw"] and won:
		var chr := UI.hb(14)
		chr.alignment = BoxContainer.ALIGNMENT_CENTER
		var l1 := ColorRect.new()
		l1.color = Color(UI.GOLD, 0.6)
		l1.custom_minimum_size = Vector2(120, 2)
		l1.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		chr.add_child(l1)
		chr.add_child(UI.chevrons(summary.stars, 34))
		var l2 := l1.duplicate()
		chr.add_child(l2)
		v.add_child(chr)
	if bastion:
		v.add_child(UI.lbl("DAMAGE DEALT  %s   (rewards arrive in your inbox at the daily reset)" % U.fmt(summary.damage), 18, UI.YELLOW, HORIZONTAL_ALIGNMENT_CENTER))
	if enc.mode == "pit":
		var p: Dictionary = Game.S.pit[enc.pit_mode]
		v.add_child(UI.lbl("%s  •  %d points (%s)" % [p.log[0].txt if not p.log.is_empty() else "", int(p.points), Game.pit_tier_row(int(p.points))[1]], 17, UI.YELLOW, HORIZONTAL_ALIGNMENT_CENTER))
	# warlord cards: MVP, level-ups, defeated
	var mvp := ""
	var best_dmg := -1
	for c in summary.contrib:
		if int(c.dealt) > best_dmg:
			best_dmg = int(c.dealt)
			mvp = c.uid
	var cards_row := UI.hb(16)
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	for c in summary.contrib:
		cards_row.add_child(_result_card(c, summary, c.uid == mvp and won))
	v.add_child(cards_row)
	# loot tray
	var tray := PanelContainer.new()
	tray.add_theme_stylebox_override("panel", UI._sb(Color(UI.DEEP, 0.94), UI.LINE, 1, UI.NOTCH, 16))
	tray.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tray.custom_minimum_size.x = 760
	var tv := UI.vb(8)
	var th := UI.hb()
	th.add_child(UI.cap("Loot"))
	th.add_child(UI.spacer())
	var loot: Array = summary.items
	var pxp := int(summary.pxp)
	if run_end != "" and int(run.n) > 1:
		# combined summary for the whole run
		loot = _merge_loot(run.items)
		pxp = int(run.pxp)
		th.get_child(0).text = "LOOT  •  ALL %d BATTLES" % run.n
	th.add_child(UI.cap("Player XP +%d%s" % [pxp, "  •  XP boost active" if Game.xp_mult() > 1.0 else ""], Color("#C9A6FF")))
	tv.add_child(th)
	var f := UI.flow(10)
	var i := 0
	for r in loot:
		var tile := UI.reward_tile(r, 66)
		tile.modulate.a = 0.0
		f.add_child(tile)
		var tw := create_tween()
		tw.tween_interval(0.25 + 0.08 * i)
		tw.tween_property(tile, "modulate:a", 1.0, 0.2)
		i += 1
	if bastion:
		f.add_child(UI.lbl(_bastion_tier_text(), 15, UI.YELLOW))
	elif loot.is_empty():
		f.add_child(UI.lbl("No item drops this time.", 15, UI.DIM))
	tv.add_child(f)
	tray.add_child(tv)
	v.add_child(tray)
	v.add_child(UI.spacer(false, 0, 4))
	var h := UI.hb(14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	var back_lbl := "STAGE MAP" if enc.mode == "campaign" else "BACK"
	h.add_child(UI.btn(back_lbl, func(): main.back(), "ghost", 180, 15))
	if enc.mode != "pit":
		# REPLAY with a cost badge and icon, like the squad START / hideout BATTLE buttons
		var cost := Content.enc_cost(Content.rebuild(enc))
		var cost_n := ""
		var cost_icon := "bolt"
		for k in cost:
			cost_n = str(int(cost[k]))
			cost_icon = "bolt" if k == "energy" else "ticket"
			break
		var rb := UI.cta("REPLAY", func(): _replay(), cost_n, cost_icon, 220)
		h.add_child(rb)
		# UI.cta places its cost badge on `resized`, before the badge has a size: place it again once laid out
		for ch in rb.get_children():
			if ch is PanelContainer:
				var badge: PanelContainer = ch
				badge.resized.connect(func(): badge.position = Vector2(rb.size.x - badge.size.x - 14, (rb.size.y - badge.size.y) / 2))
	var nxt := Content.next_enc(enc)
	if not nxt.is_empty() and won:
		h.add_child(UI.btn("NEXT STAGE  ›", func(): main.replace("squad", {"enc": nxt}), "gold", 240, 18))
	if run_next:
		# the run goes on: only STOP and leaving are offered
		for c in h.get_children():
			c.queue_free()
		h.add_child(UI.btn(back_lbl, func():
			_end_run_here(false)
			main.back(), "ghost", 180, 15))
		h.add_child(UI.btn("STOP AUTO", func(): _end_run_here(true), "danger", 220, 15))
	for btn_node in h.get_children():
		btn_node.custom_minimum_size.y = 56
	v.add_child(h)
	if run_next:
		get_tree().create_timer(1.5).timeout.connect(_next_run_battle)

## Bastion result: the reward tier reached today (rewards arrive by mail at the reset).
func _bastion_tier_text() -> String:
	var tiers: Array = Content.bastion_tiers(int(enc.get("stage", 1)))
	var dmg := int(Game.S.gang.bastion.get("my_dmg", 0))
	var reached := 0
	for tr in tiers:
		if dmg >= int(tr[0]):
			reached += 1
	return "Tier %d of %d reached today  •  rewards by mail at the daily reset" % [reached, tiers.size()]

func _result_card(c: Dictionary, summary: Dictionary, is_mvp: bool) -> Control:
	var w = Game.wl(c.uid)
	var t: Dictionary = Warlords.get_t(c.tpl)
	var gained: int = int(summary.levels.get(c.uid, 0))
	var card := Panel.new()
	card.custom_minimum_size = Vector2(190, 254)
	var sb := UI._sb(Color("#121A2C"), UI.GOLD if is_mvp else (UI.LINE if c.alive else Color("#5A2234")), 2 if is_mvp else 1, UI.NOTCH, 0)
	if is_mvp:
		sb.shadow_color = Color(UI.GOLD, 0.35)
		sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	if not c.alive:
		card.modulate.a = 0.6
	var por := UI.portrait(c.tpl, 104)
	por.position = Vector2(43, 34)
	card.add_child(por)
	if is_mvp:
		var mt := UI.tag("MVP", UI.GOLD)
		mt.add_theme_font_size_override("font_size", 12)
		mt.position = Vector2(12, 10)
		card.add_child(mt)
	var flag := ""
	var fcol := UI.GREEN
	if not c.alive:
		flag = "Defeated"
		fcol = Color("#FF8AA0")
	elif gained > 0:
		flag = "Level up"
	if flag != "":
		var fl := UI.cap(flag, fcol, 12)
		fl.position = Vector2(98 if flag == "Level up" else 90, 13)
		card.add_child(fl)
	var v := UI.vb(5)
	v.position = Vector2(12, 144)
	v.custom_minimum_size.x = 166
	var nh := UI.hb()
	var nm := UI.lbl(t.name, 14, UI.TEXT)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.expand(nm)
	nh.add_child(nm)
	if w != null:
		nh.add_child(UI.disp("LV %d" % w.level, 14, UI.GOLD if gained > 0 else UI.DIM))
	v.add_child(nh)
	if w != null:
		var need := Data.xp_to_next(w.level, w.rank)
		var maxed: bool = w.level >= Game.max_level(w)
		var bar := UI.bar(0, 1.0, UI.PURPLE, 6)
		v.add_child(bar)
		create_tween().tween_property(bar, "value", 1.0 if maxed else float(w.xp) / float(need), 0.8).set_delay(0.3)
	var sh := UI.hb()
	sh.add_child(UI.lbl("+%s XP" % U.fmt(summary.xp_each), 14, Color("#C9A6FF")))
	sh.add_child(UI.spacer())
	sh.add_child(UI.lbl("DMG " + U.fmt(c.dealt), 14, UI.DIM))
	v.add_child(sh)
	# GDD: contributions are damage dealt, taken and healed
	var sh2 := UI.hb()
	sh2.add_child(UI.lbl("TAKEN " + U.fmt(c.taken), 12, UI.DIM))
	sh2.add_child(UI.spacer())
	sh2.add_child(UI.lbl("HEALED " + U.fmt(c.healed), 12, UI.DIM))
	v.add_child(sh2)
	card.add_child(v)
	card.tooltip_text = "Damage %s  •  Taken %s  •  Healed %s" % [U.fmt(c.dealt), U.fmt(c.taken), U.fmt(c.healed)]
	return card

## AUTO x10: pay and start the next battle of the run (unless STOP was pressed or we left).
func _next_run_battle() -> void:
	if not is_inside_tree() or run.stopped or main.current != self:
		return
	var e2 := Content.rebuild(enc)
	e2.repeat = int(enc.get("repeat", 0)) - 1   # Content.rebuild drops it
	if Game.pay(Content.enc_cost(e2)) != "":
		run.out = true
		_end_run_here()
		return
	main.replace("battle", {"enc": e2, "team": team, "reinf": params.get("reinf", []), "run": run})

## End the run on the result screen (STOP, leaving, or no energy for the next battle);
## optionally redraw this result as the combined run summary.
func _end_run_here(redraw := true) -> void:
	run.stopped = true
	enc.repeat = 0
	Game.S.settings.auto = run.auto
	Game.mark()
	if redraw and is_inside_tree():
		finished = false
		_finish()

func _replay() -> void:
	var e2 := Content.rebuild(enc)
	var err_text := Game.pay(Content.enc_cost(e2))
	if err_text != "":
		err(err_text)
		return
	main.replace("battle", {"enc": e2, "team": team, "reinf": params.get("reinf", [])})
