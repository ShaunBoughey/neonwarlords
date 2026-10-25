extends Screen
## The Armoury: art-driven warlord screen (Gear, Implants, Upgrade, Level, Rank, Rep, NeuroNet, Abilities).
## Laid out on a 1920x1080 canvas (the art's native size) scaled to the window.

const CW := 1920.0
const CH := 1080.0
const PAGES := ["gear", "implants", "upgrade", "level", "rank", "rep", "neuronet", "abilities"]
const PAGE_BTN := {
	"gear": "ArmouryBarG/ArmouryGearButton", "implants": "ArmouryBarG/ArmouryImplantsButton", "upgrade": "ArmouryBarG/ArmouryUpgradeButton",
	"level": "ArmouryBarG/ArmouryLevelButton", "rank": "ArmouryBarG/ArmouryRankButton", "rep": "ArmouryBarG/ArmouryRepButton",
	"neuronet": "ArmouryBarG/ArmouryNeuronetButton", "abilities": "ArmouryBarG/ArmouryAbilitiesButton",
}
const SLOT_POS := [Vector2(1282, 220), Vector2(1458, 220), Vector2(1634, 220), Vector2(1282, 412), Vector2(1458, 412), Vector2(1634, 412)]
const GEAR_ORDER := ["helmet", "chest", "legs", "weapon", "gloves", "boots"]
const FEED_POS := [Vector2(1278, 245), Vector2(1455, 158), Vector2(1630, 245), Vector2(1278, 485), Vector2(1455, 395), Vector2(1630, 485)]
const ABIL_POS := [Vector2(1318, 248), Vector2(1543, 248), Vector2(1393, 368), Vector2(1618, 368), Vector2(1318, 488), Vector2(1543, 488)]
const CAREER_TINT := {"assault": Color(1.0, 0.55, 0.55), "protection": Color(0.6, 0.7, 1.0), "control": Color(0.6, 1.0, 0.65)}

var canvas: Control
var w: Dictionary
var t: Dictionary
var page := "gear"
var st: Dictionary   # per-screen UI state stored in params so it survives rebuilds

func _init() -> void:
	show_hud = false

func rebuild() -> void:
	UI.clear(self)
	canvas = Control.new()
	canvas.size = Vector2(CW, CH)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	if not resized.is_connected(_layout):
		resized.connect(_layout)
	_layout()
	build()

func _layout() -> void:
	if canvas == null:
		return
	var s: float = min(size.x / CW, size.y / CH)
	if s <= 0.0:
		s = 1280.0 / CW
	canvas.scale = Vector2(s, s)
	canvas.position = (size - Vector2(CW, CH) * s) / 2.0

func build() -> void:
	var found = Game.wl(params.get("uid", ""))
	if found == null:
		if Game.S.roster.is_empty():
			return
		found = Game.S.roster[0]
		params.uid = found.uid
	w = found
	t = Game.tpl(w)
	if w.get("new", false):
		w.new = false
		Game.mark()
	page = params.get("page", _page_from_tab())
	if not params.has("st"):
		params.st = {"drawer": "", "slot": "", "item": "", "picks": [], "fw": 0, "ability": "", "career": "assault", "nn": "", "meta": "", "meta_tier": "minor", "meta_n": 1, "neon": 0, "target": 5, "dups": [], "stimm": "", "filter": {}}
	st = params.st
	_left_bar()
	_right_bar()
	_title_zone()
	if st.drawer == "":
		# RAID-style centrepiece: the warlord in 3D on a turntable (drag to rotate, double-click to taunt)
		var mp := ModelPreview.new()
		mp.position = Vector2(300, 250)
		mp.size = Vector2(780, 690)
		mp.cam_dist = 3.6
		canvas.add_child(mp)
		mp.set_models([{"tpl": w.tpl, "boss": false}])
		_lbl("DRAG TO ROTATE", Vector2(300, 915), 14, UI.DIM, 780, HORIZONTAL_ALIGNMENT_CENTER)
	match page:
		"gear": _page_slots(Data.GEAR_SLOTS)
		"implants": _page_slots(Data.IMPLANT_SLOTS)
		"upgrade": _page_upgrade()
		"level": _page_level()
		"rank": _page_rank()
		"rep": _page_rep()
		"neuronet": _page_neuronet()
		"abilities": _page_abilities()
	_bottom_strip()
	if st.drawer != "":
		_drawer()

func _page_from_tab() -> String:
	match String(params.get("tab", "")):
		"Equipment": return "gear"
		"Abilities": return "abilities"
		"Neuronet": return "neuronet"
		"Dojo": return "level"
	return "gear"

func _go_page(p: String) -> void:
	params.page = p
	if p != "upgrade":
		st.item = ""
	st.drawer = ""
	st.picks = []
	st.fw = 0
	st.dups = []
	rebuild()

# ================================================================ canvas helpers
func _img(rel: String, pos: Vector2, scale := 1.0, sz := Vector2.ZERO, parent: Control = null) -> TextureRect:
	var r := Art.rect(rel, pos, scale, sz)
	(parent if parent else canvas).add_child(r)
	return r

func _icon(rel: String, pos: Vector2, sz: Vector2, parent: Control = null) -> TextureRect:
	var r := Art.icon(rel, sz)
	r.position = pos
	(parent if parent else canvas).add_child(r)
	return r

func _tbtn(base: String, pos: Vector2, cb: Callable, scale := 1.0, active := false, parent: Control = null) -> TextureButton:
	var b := Art.button(base, cb, pos, scale, active)
	(parent if parent else canvas).add_child(b)
	return b

func _lbl(text: String, pos: Vector2, fs: int, color := Color.WHITE, width := 0.0, align := HORIZONTAL_ALIGNMENT_LEFT, bold := false, parent: Control = null, wrap := true) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_y", 2)
	var f := Art.font(bold)
	if f:
		l.add_theme_font_override("font", f)
	l.horizontal_alignment = align
	if width > 0:
		if wrap:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.custom_minimum_size.x = width
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else canvas).add_child(l)
	if width > 0:
		l.size = Vector2(width, l.get_combined_minimum_size().y)
	return l

## Invisible click area.
func _hit(pos: Vector2, sz: Vector2, cb: Callable, tip := "", parent: Control = null) -> Button:
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = pos
	b.size = sz
	for s in ["normal", "hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	b.tooltip_text = tip
	b.pressed.connect(cb)
	(parent if parent else canvas).add_child(b)
	return b

func _portrait(tpl_id: String, pos: Vector2, sz: float, parent: Control = null) -> Portrait:
	var p := UI.portrait(tpl_id, int(sz)) as Portrait
	p.position = pos
	p.size = Vector2(sz, sz)
	(parent if parent else canvas).add_child(p)
	return p

func _bar(rel_bg: String, rel_fill: String, pos: Vector2, ratio: float, fill_off := Vector2(2, 2)) -> void:
	var bg := _img(rel_bg, pos)
	var fill_tex := Art.tex(rel_fill)
	if fill_tex == null:
		return
	var fsz := fill_tex.get_size()
	var fill := Art.rect(rel_fill, pos + fill_off, 1.0, Vector2(fsz.x * clamp(ratio, 0.0, 1.0), fsz.y))
	fill.stretch_mode = TextureRect.STRETCH_TILE
	canvas.add_child(fill)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ui_btn(text: String, pos: Vector2, cb: Callable, kind := "primary", width := 180, fs := 22) -> Button:
	var b := UI.btn(text, cb, kind, width, fs)
	var f := Art.font(true)
	if f:
		b.add_theme_font_override("font", f)
	b.position = pos
	b.custom_minimum_size.y = 52
	canvas.add_child(b)
	return b

func _panel(pos: Vector2, sz: Vector2, alpha := 0.85) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	p.add_theme_stylebox_override("panel", UI._sb(Color(0.03, 0.05, 0.12, alpha), UI.CYAN.darkened(0.3), 2, 10))
	canvas.add_child(p)
	return p

# ================================================================ bars & title
func _gear_page() -> bool:
	return page in ["gear", "implants", "upgrade"]

func _left_bar() -> void:
	var base := "FilterBarsG/EquipmentFilterBar/" if _gear_page() else "FilterBarsG/WarlordFilterBarG/"
	_img(base + "FilterBarBGI.png", Vector2(12, 228))
	var sw := _tbtn(base + ("EQFilterSwitchButton" if _gear_page() else "WLFilterSwitchButton"), Vector2(22, 240), func(): _toggle_drawer("equipment" if _gear_page() else "switch"))
	sw.tooltip_text = "Browse equipment" if _gear_page() else "Switch Warlord"
	if not _gear_page():
		_portrait(w.tpl, Vector2(31, 248), 76)
	else:
		_lbl("⚙", Vector2(22, 255), 44, UI.MAGENTA, 94, HORIZONTAL_ALIGNMENT_CENTER)
	var names: Array = ["Set", "Stats", "Rank", "Slot", "Level", "Rarity", "Reset"] if _gear_page() else ["Syndicate", "Class", "Rank", "Rep", "Level", "Rarity", "Reset"]
	for i in names.size():
		var n: String = names[i]
		var btn_base: String = base + ("EQFilter%sButton" % n if _gear_page() else "WLFilter%sButton" % n)
		var active: bool = st.filter.has(n.to_lower())
		var b := _tbtn(btn_base, Vector2(22, 345 + i * 103), func(): _filter(n), 1.0, active)
		b.tooltip_text = _filter_tip(n)

func _filter_tip(n: String) -> String:
	var f: Dictionary = st.filter
	var key := n.to_lower()
	if not f.has(key):
		return n + " filter / sort"
	return "%s: %s" % [n, str(f[key])]

func _filter(n: String) -> void:
	var f: Dictionary = st.filter
	var key := n.to_lower()
	match key:
		"reset":
			st.filter = {}
		"syndicate":
			var opts: Array = Data.SYNDICATES.keys()
			f[key] = opts[(opts.find(f.get(key, "")) + 1) % opts.size()] if f.get(key, "") != opts[opts.size() - 1] else null
		"class":
			var opts2: Array = Data.CLASSES
			f[key] = opts2[(opts2.find(f.get(key, "")) + 1) % opts2.size()] if f.get(key, "") != opts2[opts2.size() - 1] else null
		"set":
			var opts3: Array = Data.SETS.keys()
			f[key] = opts3[(opts3.find(f.get(key, "")) + 1) % opts3.size()] if f.get(key, "") != opts3[opts3.size() - 1] else null
		"slot":
			var opts4: Array = Data.ALL_SLOTS
			f[key] = opts4[(opts4.find(f.get(key, "")) + 1) % opts4.size()] if f.get(key, "") != opts4[opts4.size() - 1] else null
		"stats":
			var opts5: Array = Data.STATS.keys()
			f[key] = opts5[(opts5.find(f.get(key, "")) + 1) % opts5.size()] if f.get(key, "") != opts5[opts5.size() - 1] else null
		_:
			# sort toggles: desc -> asc -> off
			var cur_v = f.get(key, null)
			f[key] = "high" if cur_v == null else ("low" if cur_v == "high" else null)
	for k in f.keys():
		if f[k] == null:
			f.erase(k)
	if st.drawer == "":
		st.drawer = "equipment" if _gear_page() else "switch"
	rebuild()

func _right_bar() -> void:
	_img("ArmouryBarG/ArmouryBarBGI.png", Vector2(1795, 228))
	for i in PAGES.size():
		var p: String = PAGES[i]
		var b := _tbtn(PAGE_BTN[p], Vector2(1805, 240 + i * 103), func(): _go_page(p), 1.0, p == page)
		b.tooltip_text = p.capitalize()
		if p == page:
			var glow := ColorRect.new()
			glow.color = Color(1.0, 0.18, 0.53, 0.25)
			glow.position = Vector2(1805, 240 + i * 103)
			glow.size = Vector2(97, 95)
			glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(glow)

func _title_zone() -> void:
	var nfs := 52
	var tf := Art.font(true)
	if tf:
		while nfs > 24 and tf.get_string_size(String(t.name).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, nfs).x > 490:
			nfs -= 2
	_lbl(String(t.name).to_upper(), Vector2(1285, 6 + (52 - nfs) / 2), nfs, Color.WHITE, 500, HORIZONTAL_ALIGNMENT_LEFT, true, null, false)
	for i in 6:
		var c := _img("WarlordTitleZoneG/RankChevron%dI.png" % (i + 1), Vector2(1290 + i * 45, 66), 0.8)
		c.modulate = Color(1, 1, 1, 1.0 if i < w.rank else 0.18)
	_icon(Art.SYN_SYMBOL[t.syn], Vector2(1592, 62), Vector2(70, 70)).tooltip_text = Data.SYNDICATES[t.syn].name
	_icon(Art.CLASS_SYMBOL[t.cls], Vector2(1688, 62), Vector2(70, 70))
	_hit(Vector2(1592, 62), Vector2(70, 70), func(): _info_modal(Data.SYNDICATES[t.syn].name, String(Data.SYNDICATES[t.syn].get("desc", ""))), Data.SYNDICATES[t.syn].name)
	_hit(Vector2(1688, 62), Vector2(70, 70), func(): _info_modal("%s • %s" % [Data.CLASS_INFO[t.cls].name, Data.CLASS_INFO[t.cls].role], String(Data.CLASS_INFO[t.cls].desc)), "%s • %s" % [Data.CLASS_INFO[t.cls].name, Data.CLASS_INFO[t.cls].role])
	var ring := _img("WarlordTitleZoneG/RarityRingI.png", Vector2(1788, 52))
	ring.modulate = Data.RARITY_COLOR[t.rarity].lightened(0.3)
	_img("WarlordTitleZoneG/WarlordLVLI.png", Vector2(1801, 72), 0.9)
	_lbl(str(w.level), Vector2(1788, 92), 46, Color.WHITE, 118, HORIZONTAL_ALIGNMENT_CENTER, true)

func _bottom_strip() -> void:
	var p := _panel(Vector2(140, 955), Vector2(1120, 110), 0.72)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_btn("◀ BACK", Vector2(155, 985), func(): main.back(), "ghost", 150)
	_ui_btn("⌂", Vector2(315, 985), func(): main.home(), "ghost", 60)
	_ui_btn("◀", Vector2(385, 985), func(): _cycle(-1), "ghost", 60)
	_ui_btn("▶", Vector2(455, 985), func(): _cycle(1), "ghost", 60)
	_lbl("%s  •  %s" % [U.cap(t.rarity).to_upper(), U.cap(t.align).to_upper()], Vector2(540, 968), 20, Data.RARITY_COLOR[t.rarity], 0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_lbl("POWER %s · REP %d/%d · LV %d/%d" % [U.fmt(Game.power(w)), w.rep, w.rank, w.level, Game.max_level(w)], Vector2(540, 998), 17, UI.YELLOW, 355, HORIZONTAL_ALIGNMENT_LEFT, false, null, false)
	if w.level < Game.max_level(w):
		var need := Data.xp_to_next(w.level, w.rank)
		var xb := UI.bar(w.xp, need, UI.PURPLE, 10, 330)
		xb.position = Vector2(540, 1035)
		xb.size = Vector2(330, 10)
		canvas.add_child(xb)
	_ui_btn("UNLOCK" if w.locked else "LOCK", Vector2(905, 985), func():
		w.locked = not w.locked
		Game.mark()
		rebuild(), "gold" if w.locked else "ghost", 140)
	_ui_btn("SCRAP", Vector2(1060, 985), func(): main.confirm("Break down %s for 1-2 %s contract scrap? Their gear returns to the inventory." % [t.name, U.cap(Data.SCRAP_FOR[t.rarity])], func():
		var e := Game.break_down(w)
		if e != "":
			err(e)
		else:
			main.back()), "danger", 180)

func _info_modal(title: String, desc: String) -> void:
	var v := UI.vb(10)
	v.add_child(UI.lbl(desc, 17, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	if Data.SYNDICATES[t.syn].name == title:
		v.add_child(UI.lbl("Gang sign: " + String(Data.SYNDICATES[t.syn].sign), 15, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	main.modal(title, v)

func _cycle(d: int) -> void:
	var idx: int = Game.S.roster.find(w)
	var n: int = Game.S.roster.size()
	params.uid = Game.S.roster[(idx + d + n) % n].uid
	st.picks = []
	st.dups = []
	st.fw = 0
	st.item = ""
	rebuild()

# ================================================================ stats panel (Gear / Implants / Upgrade)
func _stats_panel() -> void:
	_img("StatsG/StatsPanelBGI.png", Vector2(1280, 605))
	_img("StatsG/StatsTitleI.png", Vector2(1452, 616))
	var ex := _tbtn("StatsG/StatExpandButton", Vector2(1620, 615), func(): _stat_breakdown())
	ex.tooltip_text = "Full stat breakdown"
	var s := Game.compute_stats(w)
	var bare: Dictionary = w.duplicate(true)
	bare.gear = {}
	var b := Game.compute_stats(bare)
	var rows := [["hp", "HEALTH", "StatHealthIncIconI"], ["arm", "ARMOUR", "StatArmourIncIconI"], ["fp", "FIREPOWER", "StatFirepowerIncIconI"], ["spd", "SPEED", "StatSpeedIncIconI"],
		["cc", "CRIT CHANCE", "StatCritChanceIncIconI"], ["cd", "CRIT DAMAGE", "StatCritDamageIncIconI"], ["hack", "HACKING", "StatHackingIncIconI"], ["fw", "FIREWALL", "StatFirewallIncIconI"]]
	for i in rows.size():
		var r: Array = rows[i]
		var col := 0 if i < 4 else 1
		var row := i % 4
		var x := 1322 + col * 250
		var y := 645 + row * 97
		var pct: bool = r[0] in ["cc", "cd"]
		_lbl(r[1], Vector2(x, y), 22, Color.WHITE, 0, HORIZONTAL_ALIGNMENT_LEFT, true)
		_lbl((str(snappedf(s[r[0]], 0.1)) + "%") if pct else U.fmt(s[r[0]]), Vector2(x, y + 25), 24, Color.WHITE)
		var inc: float = float(s[r[0]]) - float(b[r[0]])
		_img("StatsG/%s.png" % r[2], Vector2(x + 2, y + 62))
		_lbl(("+%s%%" % str(snappedf(inc, 0.1))) if pct else "+" + U.fmt(inc), Vector2(x + 16, y + 56), 18, UI.GREEN)
	# set slots
	_img("StatsG/SetSlotsG/SetSlotsI.png", Vector2(1216, 670))
	var k := 0
	for sname in s.sets:
		var sd: Dictionary = Data.SETS[sname]
		var times := int(s.sets[sname] / sd.pieces)
		if times <= 0 or k >= 3:
			continue
		var sym := _img("StatsG/SetSlotsG/GearSetSymbol%d.png" % (k + 1), Vector2(1225, 700 + k * 80))
		sym.tooltip_text = "%s x%d: %s" % [sname, times, sd.desc]
		_hit(Vector2(1216, 685 + k * 80), Vector2(56, 60), func(): pass, "%s (%d/%d) x%d: %s" % [sname, s.sets[sname], sd.pieces, times, sd.desc])
		_lbl(sname.to_upper(), Vector2(1000, 700 + k * 80), 16, UI.GREEN, 210, HORIZONTAL_ALIGNMENT_RIGHT)
		k += 1

# ================================================================ GEAR / IMPLANTS
func _page_slots(slots: Array) -> void:
	var order: Array = GEAR_ORDER if slots.size() == 6 else slots
	for i in order.size():
		var slot: String = order[i]
		var pos: Vector2 = SLOT_POS[i]
		var locked: bool = slot in Data.IMPLANT_SLOTS and w.rep < Data.IMPLANT_UNLOCK[slot]
		var b := _tbtn(Art.SLOT_BUTTON[slot], pos, func(): _select_slot(slot))
		var it = Game.eq(w.gear.get(slot, ""))
		if locked:
			b.modulate = Color(0.4, 0.4, 0.4)
			_lbl("REP %d" % Data.IMPLANT_UNLOCK[slot], pos + Vector2(0, 140), 22, UI.YELLOW, 152, HORIZONTAL_ALIGNMENT_CENTER, true)
			b.tooltip_text = "%s slot unlocks at Reputation %d" % [U.cap(slot), Data.IMPLANT_UNLOCK[slot]]
		elif it != null:
			_img(Art.equip_border(it.rarity), pos, 1.0, Vector2(152, 186))
			_lbl("R%d +%d" % [it.rank, it.level], pos + Vector2(0, 150), 22, Color.WHITE, 152, HORIZONTAL_ALIGNMENT_CENTER, true)
			b.tooltip_text = UI.item_tooltip(it)
		else:
			b.modulate = Color(1, 1, 1, 0.55)
			b.tooltip_text = "Empty %s slot - click to equip" % slot
		if st.slot == slot:
			var sel := ColorRect.new()
			sel.color = Color(1, 0.84, 0.16, 0.18)
			sel.position = pos
			sel.size = Vector2(152, 186)
			sel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			canvas.add_child(sel)
	var ae := _ui_btn("AUTO EQUIP", Vector2(1080, 236), func():
		var n := Game.auto_equip(w)
		Game.say("Equipped %d item%s" % [n, "" if n == 1 else "s"] if n > 0 else "Already wearing the best gear", UI.GREEN)
		rebuild(), "green", 190, 18)
	ae.set_meta("coach", "auto_equip")
	_ui_btn("UNEQUIP ALL", Vector2(1080, 296), func():
		Game.unequip_all(w)
		rebuild(), "ghost", 190, 18)
	if slots.size() == 3:
		_lbl("IMPLANTS UNLOCK AT REP 2 / 4 / 6", Vector2(1282, 420), 18, UI.DIM, 504, HORIZONTAL_ALIGNMENT_CENTER)
	_stats_panel()
	if st.item != "":
		_gear_modal()

func _select_slot(slot: String) -> void:
	if slot in Data.IMPLANT_SLOTS and w.rep < Data.IMPLANT_UNLOCK[slot]:
		err("%s slot unlocks at Reputation %d" % [U.cap(slot), Data.IMPLANT_UNLOCK[slot]])
		return
	st.slot = slot
	st.filter.erase("slot")
	var it = Game.eq(w.gear.get(slot, ""))
	st.item = it.uid if it != null else ""
	st.drawer = "equipment"
	rebuild()

## Top-left equipment detail (GearModal art).
func _gear_modal() -> void:
	var it = Game.eq(st.item)
	if it == null:
		st.item = ""
		return
	_img("GearModalG/ModalBGI.png", Vector2(42, 45))
	_img("GearModalG/ModalImageSlot.png", Vector2(8, 40))
	_icon(Art.SLOT_BUTTON[it.slot], Vector2(14, 46), Vector2(136, 170))
	_img(Art.equip_border(it.rarity), Vector2(8, 40), 1.0, Vector2(148, 183))
	var col: Color = Data.RARITY_COLOR[it.rarity]
	_lbl("%s / %s" % [it.rarity.to_upper(), it.slot.to_upper()], Vector2(165, 52), 20, col, 0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_lbl(("%s SET  •  R%d  +%d" % [it.set.to_upper(), it.rank, it.level]) if it.set != "" else "IMPLANT  •  R%d  +%d" % [it.rank, it.level], Vector2(165, 76), 16, Color.WHITE)
	_lbl("PRIMARY: " + UI.stat_text(it.pri.stat, Data.primary_value(it.pri.stat, it.rank, it.level)).to_upper(), Vector2(165, 108), 16, UI.YELLOW, 248, HORIZONTAL_ALIGNMENT_LEFT, false, null, false)
	for i in 4:
		var text := "-"
		var c := Color.WHITE
		if i < it.subs.size():
			var sb: Dictionary = it.subs[i]
			text = UI.stat_text(sb.stat, float(sb.val) + float(sb.get("neon", 0))).to_upper()
			if float(sb.get("neon", 0)) > 0:
				c = UI.MAGENTA
				var nic := Icon.make("diamond", UI.MAGENTA, 13)
				nic.position = Vector2(165, 134 + i * 19)
				canvas.add_child(nic)
		_lbl(text, Vector2(165 + (17 if c == UI.MAGENTA else 0), 132 + i * 19), 15, c)
	if it.set != "":
		var sd: Dictionary = Data.SETS[it.set]
		_lbl("SET BONUS (%d):" % sd.pieces, Vector2(420, 104), 14, UI.CYAN, 180, HORIZONTAL_ALIGNMENT_LEFT, true)
		_lbl(String(sd.desc).to_upper(), Vector2(420, 124), 13, Color.WHITE, 180)
	var owner = Game.wl(it.owner)
	if owner != null and owner.uid != w.uid:
		_lbl("ON " + Game.tpl(owner).name.to_upper(), Vector2(165, 52), 13, UI.YELLOW, 245, HORIZONTAL_ALIGNMENT_RIGHT, false, null, false)
	var equipped: bool = it.owner == w.uid
	if not equipped:
		var delta := Game.equip_delta(w, it)
		var parts: Array = []
		for k in ["hp", "arm", "fp", "spd", "cc", "cd", "hack", "fw"]:
			if delta.has(k):
				var dv: float = delta[k]
				parts.append(("%s%s %s" % ["+" if dv > 0 else "", (str(snappedf(dv, 0.1)) + "%") if k in ["cc", "cd"] else U.fmt(dv), Data.STATS[k].short]))
		var good: bool = Game.stat_score(w, Game.stats_with(w, it)) >= Game.stat_score(w, Game.compute_stats(w))
		_lbl("IF EQUIPPED: " + ("  ".join(parts) if not parts.is_empty() else "NO CHANGE"), Vector2(165, 205), 13, UI.GREEN if good else UI.RED, 540, HORIZONTAL_ALIGNMENT_LEFT, true, null, false)
	var eb := _tbtn("GearModalG/ModalEquipButton", Vector2(617, 58), func():
		if equipped:
			Game.unequip(it)
		else:
			err(Game.equip_on(w, it))
		rebuild())
	eb.tooltip_text = "Unequip" if equipped else "Equip"
	if equipped:
		eb.modulate = Color(1.0, 0.6, 0.6)
	var ub := _tbtn("GearModalG/ModalUpgradeButton", Vector2(617, 140), func():
		params.page = "upgrade"
		st.drawer = ""
		rebuild())
	ub.tooltip_text = "Upgrade"
	_tbtn("GearModalG/ModalCloseButton", Vector2(700, 42), func():
		st.item = ""
		rebuild())

# ================================================================ UPGRADE
func _page_upgrade() -> void:
	var it = Game.eq(st.item)
	if it == null and st.slot != "":
		it = Game.eq(w.gear.get(st.slot, ""))
	if it == null:
		for sl in GEAR_ORDER + Data.IMPLANT_SLOTS:
			it = Game.eq(w.gear.get(sl, ""))
			if it != null:
				break
	if it != null:
		st.item = it.uid
	_img("UpgradeScreenG/UpgradeTopPanelG/UpgradeItemBGPanelI.png", Vector2(1282, 163))
	var slot_b := _tbtn("UpgradeScreenG/UpgradeTopPanelG/UpgradeItemSlotButton", Vector2(1300, 180), func(): _toggle_drawer("equipment"))
	slot_b.tooltip_text = "Choose equipment to upgrade"
	if it != null:
		_icon(Art.SLOT_BUTTON[it.slot], Vector2(1306, 186), Vector2(141, 175))
		_img(Art.equip_border(it.rarity), Vector2(1300, 180), 1.0, Vector2(153, 187))
		_lbl("+%d" % it.level, Vector2(1300, 330), 22, Color.WHITE, 153, HORIZONTAL_ALIGNMENT_CENTER, true)
	else:
		_lbl("SELECT\nGEAR", Vector2(1300, 240), 22, UI.DIM, 153, HORIZONTAL_ALIGNMENT_CENTER, true)
	var target: int = int(st.target)
	_tbtn("UpgradeScreenG/UpgradeTopPanelG/UpgradeOnce", Vector2(1460, 178), func(): _upgrade(it, 1))
	_tbtn("UpgradeScreenG/UpgradeTopPanelG/UpgradeToButton", Vector2(1460, 278), func(): _upgrade_to(it, target))
	var tos := [5, 10, 15, 20]
	for i in 4:
		var lv: int = tos[i]
		_tbtn("UpgradeScreenG/UpgradeTopPanelG/To%dButton" % lv, Vector2(1590 + (i % 2) * 90, 178 + (i / 2) * 70), func():
			st.target = lv
			rebuild(), 1.0, lv == target)
	_img("UpgradeScreenG/UpgradeTopPanelG/CurrentCostI.png", Vector2(1592, 322))
	var cost_text := "-"
	if it != null and it.level < Data.MAX_EQUIP_LEVEL:
		cost_text = U.fmt(Data.equip_level_cost(it.rank, it.level))
	elif it != null:
		cost_text = "MAX"
	_lbl(cost_text, Vector2(1585, 336), 32, Color.WHITE, 190, HORIZONTAL_ALIGNMENT_CENTER, true)
	_bar("UpgradeScreenG/UpgradeTopPanelG/UpgradeProgressBarBackground.png", "UpgradeScreenG/UpgradeTopPanelG/UpgradeProgressBarFill.png", Vector2(1298, 374), float(it.level) / 20.0 if it != null else 0.0)
	_lbl("LEVEL %d / 20%s" % [it.level if it != null else 0, ("  •  TO +%d: %s ¢" % [target, U.fmt(_cost_to(it, target))]) if it != null and it.level < target else ""], Vector2(1298, 372), 15, Color.WHITE, 475, HORIZONTAL_ALIGNMENT_CENTER, true)
	if it != null and it.subs.size() < 4:
		_lbl("NEXT SUBSTAT AT +%d" % [((it.level / 5) + 1) * 5], Vector2(1380, 397), 15, UI.YELLOW, 306, HORIZONTAL_ALIGNMENT_CENTER)
	# neon graft
	_img("UpgradeScreenG/NeonGlyphsG/UpgradeNeonPanelBGI.png", Vector2(1282, 428))
	var fitting: Array = []
	if it != null:
		fitting = Game.S.neons.filter(func(ne): return Game.neon_can(it, ne) == "")
	var ni: int = int(st.neon) % max(1, fitting.size())
	_tbtn("UpgradeScreenG/NeonGlyphsG/UpgradeNeonSlotButton", Vector2(1300, 445), func():
		st.neon = ni + 1
		rebuild())
	if not fitting.is_empty():
		var ne: Dictionary = fitting[ni]
		_icon(Art.neon_big(ne.stat), Vector2(1308, 453), Vector2(102, 102))
		_lbl("R%d %s NEON" % [ne.rank, Data.STATS[ne.stat].short.to_upper()], Vector2(1425, 442), 16, Color.WHITE, 220, HORIZONTAL_ALIGNMENT_LEFT, true, null, false)
		var cur_val := 0.0
		for sb in it.subs:
			if sb.stat == ne.stat:
				cur_val = float(sb.val)
		_lbl("CURRENT %s ON GEAR: %s" % [Data.STATS[ne.stat].short, str(cur_val)], Vector2(1425, 470), 15, Color.WHITE, 220)
		_lbl("VALUE GEAR WILL INCREASE BY +%s" % str(Data.SUBSTAT[ne.stat][ne.rank]), Vector2(1425, 512), 15, UI.GREEN, 220)
		_lbl("%d / %d FITTING" % [ni + 1, fitting.size()], Vector2(1645, 538), 14, UI.DIM, 118, HORIZONTAL_ALIGNMENT_CENTER)
		_tbtn("UpgradeScreenG/NeonGlyphsG/GraftNeonButton", Vector2(1645, 440), func():
			err(Game.apply_neon(it, ne))
			st.neon = 0
			rebuild())
	else:
		_lbl("NO FITTING NEON", Vector2(1425, 450), 18, UI.DIM, 220, HORIZONTAL_ALIGNMENT_LEFT, true)
		_lbl("NEONS FIT GEAR OF EQUAL OR HIGHER RANK WITH A MATCHING SUBSTAT. WIN THEM IN SYNDICATE WARS.", Vector2(1425, 478), 13, UI.DIM, 345)
	var grafted := 0
	if it != null:
		for sb in it.subs:
			if float(sb.get("neon", 0)) > 0:
				grafted += 1
	if it != null and it.subs.size() > 0:
		_bar("UpgradeScreenG/NeonGlyphsG/NeonProgressBarBackground.png", "UpgradeScreenG/NeonGlyphsG/NeonProgressBarFill.png", Vector2(1298, 565), grafted / float(it.subs.size()), Vector2(0, 0))
		_lbl("NEONS GRAFTED %d / %d" % [grafted, it.subs.size()], Vector2(1298, 563), 15, Color.WHITE, 475, HORIZONTAL_ALIGNMENT_CENTER, true)
	_stats_panel()
	if it != null:
		st.item = it.uid
		_gear_modal()

func _cost_to(it, target: int) -> int:
	if it == null:
		return 0
	var c := 0
	for l in range(it.level, min(target, Data.MAX_EQUIP_LEVEL)):
		c += Data.equip_level_cost(it.rank, l)
	return c

func _upgrade(it, n: int) -> void:
	if it == null:
		err("Select a piece of equipment first")
		return
	for i in n:
		var e := Game.equip_level_up(it)
		if e != "":
			err(e)
			break
	rebuild()

func _upgrade_to(it, target: int) -> void:
	if it == null:
		err("Select a piece of equipment first")
		return
	if it.level >= target:
		err("Already +%d or higher" % target)
		return
	_upgrade(it, target - it.level)

# ================================================================ LEVEL
func _page_level() -> void:
	_img("LevelScreenG/WarlordLevelSlotsG/LevelScreenBGI.png", Vector2(1325, 205))
	var picks: Array = st.picks
	var gain := 0
	for i in 6:
		var pos: Vector2 = FEED_POS[i]
		_tbtn("LevelScreenG/WarlordLevelSlotsG/WarlordLevelSlot%d" % (i + 1), pos, func(): _open_fodder("feed"))
		if i < picks.size():
			var f = Game.wl(picks[i])
			if f != null:
				_portrait(f.tpl, pos + Vector2(12, 14), 130)
				_img(Art.warlord_border(Game.tpl(f).rarity), pos, 1.0, Vector2(155, 190))
				_lbl("LV %d" % f.level, pos + Vector2(0, 150), 18, Color.WHITE, 155, HORIZONTAL_ALIGNMENT_CENTER, true)
				gain += Game.feed_xp_value(f)
	_tbtn("LevelScreenG/MetabolicsInstallButton", Vector2(1460, 612), func(): _install_level())
	# metabolics
	_img("LevelScreenG/MetabolicsInstallNG.png", Vector2(1282, 683))
	var meta: String = st.meta
	var tier: String = st.meta_tier
	_tbtn("LevelScreenG/MetabolicsSlotButton", Vector2(1455, 692), func(): _cycle_meta_tier())
	if meta != "":
		_icon(Art.metabolic(meta), Vector2(1470, 694), Vector2(124, 122))
		_lbl(tier.to_upper(), Vector2(1300, 700), 18, Data.ALIGN_COLOR[meta], 150, HORIZONTAL_ALIGNMENT_LEFT, true)
		_lbl("%s XP EACH%s" % [U.fmt(Data.METABOLIC_XP[tier]), (" (+%d%%)" % int(round(Data.METABOLIC_ALIGN_BONUS * 100))) if meta == t.align else ""], Vector2(1300, 728), 14, Color.WHITE, 150)
	else:
		_lbl("PICK A METABOLIC BELOW", Vector2(1300, 700), 14, UI.DIM, 150)
	# tier pips + hint (the slot cycles Minor / Major / Grand)
	var ti: int = ["minor", "major", "grand"].find(tier)
	for k in 3:
		var pip := ColorRect.new()
		pip.color = UI.YELLOW if k <= ti else Color(1, 1, 1, 0.15)
		pip.position = Vector2(1300 + k * 26, 772)
		pip.size = Vector2(20, 8)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.add_child(pip)
	_lbl("TAP SLOT: TIER", Vector2(1300, 786), 14, UI.DIM, 150)
	var owned := Game.item_count(["metabolic", meta, tier]) if meta != "" else 0
	var n: int = clampi(int(st.meta_n), 0, max(0, owned))
	st.meta_n = n
	_bar("LevelScreenG/MetabolicsProgressBarBackground.png", "LevelScreenG/MetabolicsProgressBarFill.png", Vector2(1298, 832), float(n) / max(1, owned))
	var sl := HSlider.new()
	sl.position = Vector2(1298, 826)
	sl.size = Vector2(475, 30)
	sl.min_value = 0
	sl.max_value = max(1, owned)
	sl.step = 1
	sl.value = n
	sl.editable = owned > 0
	sl.add_theme_stylebox_override("slider", StyleBoxEmpty.new())
	sl.add_theme_stylebox_override("grabber_area", StyleBoxEmpty.new())
	sl.add_theme_stylebox_override("grabber_area_highlight", StyleBoxEmpty.new())
	sl.add_theme_icon_override("grabber", Art.tex("LevelScreenG/SliderToggle.png"))
	sl.add_theme_icon_override("grabber_highlight", Art.tex("LevelScreenG/SliderToggle.png"))
	canvas.add_child(sl)
	var qty := _lbl("X%d" % n, Vector2(1282, 852), 24, Color.WHITE, 504, HORIZONTAL_ALIGNMENT_CENTER, true)
	sl.drag_ended.connect(func(_c): rebuild())
	sl.value_changed.connect(func(v):
		st.meta_n = int(v)
		qty.text = "X%d" % int(v))
	if meta != "":
		var xpv: float = Data.METABOLIC_XP[tier] * ((1.0 + Data.METABOLIC_ALIGN_BONUS) if meta == t.align else 1.0)
		gain += int(xpv * n)
	_img("LevelScreenG/OwnedMetabolicsBG.png", Vector2(1282, 893))
	_lbl("METABOLICS", Vector2(1282, 898), 20, Color.WHITE, 504, HORIZONTAL_ALIGNMENT_CENTER, true)
	var aligns := ["paragon", "renegade", "neutral"]
	for i in 3:
		var al: String = aligns[i]
		var b := _tbtn(Art.metabolic(al), Vector2(1335 + i * 145, 922), func():
			st.meta = al
			st.meta_n = 1
			rebuild(), 0.85, meta == al)
		b.tooltip_text = "%s metabolics: %d minor / %d major / %d grand" % [U.cap(al), Game.item_count(["metabolic", al, "minor"]), Game.item_count(["metabolic", al, "major"]), Game.item_count(["metabolic", al, "grand"])]
		var tot := 0
		for tr in ["minor", "major", "grand"]:
			tot += Game.item_count(["metabolic", al, tr])
		_lbl("X%d" % (Game.item_count(["metabolic", al, tier]) if meta == al else tot), Vector2(1335 + i * 145, 1030), 22, Color.WHITE, 105, HORIZONTAL_ALIGNMENT_CENTER, true)
	var cap_text := "MAX LEVEL FOR RANK %d" % w.rank
	if w.level < Game.max_level(w):
		cap_text = "+%s XP SELECTED" % U.fmt(gain)
		if gain > 0:
			var pv := _preview_level(gain)
			cap_text += "  ->  LV %d" % pv[0]
			if pv[1] > 0:
				cap_text += " (%s OVER CAP)" % U.fmt(pv[1])
	_lbl(cap_text, Vector2(1282, 132), 20, UI.YELLOW, 504, HORIZONTAL_ALIGNMENT_CENTER, true, null, false)

## [level reached, XP wasted past the rank cap] if `gain` XP were added now (no save changes).
func _preview_level(gain: int) -> Array:
	var lv: int = w.level
	var xp: int = int(w.xp) + gain
	var cap := Game.max_level(w)
	while lv < cap and xp >= Data.xp_to_next(lv, w.rank):
		xp -= Data.xp_to_next(lv, w.rank)
		lv += 1
	return [lv, xp if lv >= cap else 0]

func _cycle_meta_tier() -> void:
	var tiers := ["minor", "major", "grand"]
	st.meta_tier = tiers[(tiers.find(st.meta_tier) + 1) % 3]
	st.meta_n = 1
	rebuild()

func _install_level(confirmed := false) -> void:
	if not confirmed:
		for u in st.picks:
			var f = Game.wl(u)
			if f != null and (int(f.rank) >= 3 or Game.tpl(f).rarity in ["epic", "legendary"]):
				main.confirm("Feed %d Warlord(s) to %s? This includes Rank 3+ or Epic/Legendary Warlords and cannot be undone." % [st.picks.size(), t.name], func(): _install_level(true), "Feed")
				return
	var did := false
	if not (st.picks as Array).is_empty():
		var e := Game.feed_xp(w, st.picks)
		if e != "":
			err(e)
			return
		st.picks = []
		did = true
	var meta: String = st.meta
	if meta != "":
		for i in int(st.meta_n):
			var me := Game.use_metabolic(w, meta, st.meta_tier)
			if me != "":
				if not did:
					err(me)
					rebuild()
					return
				break
			did = true
	if not did:
		err("Select Warlords or Metabolics to install")
	rebuild()

# ================================================================ RANK
func _page_rank() -> void:
	_img("RankScreenG/WarlordRankSlotsG/RankScreenBGI.png", Vector2(1325, 255))
	var picks: Array = st.picks
	var fw: int = int(st.fw)
	var need: int = w.rank
	for i in 6:
		var pos: Vector2 = FEED_POS[i] + Vector2(0, 30)
		var b := _tbtn("RankScreenG/WarlordRankSlotsG/WarlordRankSlot%d" % (i + 1), pos, func(): _open_fodder("rank"))
		if i >= need or w.rank >= Data.MAX_RANK:
			b.modulate = Color(0.35, 0.35, 0.35, 0.6)
			b.disabled = true
			continue
		if i < picks.size():
			var f = Game.wl(picks[i])
			if f != null:
				_portrait(f.tpl, pos + Vector2(12, 14), 130)
				_img(Art.warlord_border(Game.tpl(f).rarity), pos, 1.0, Vector2(155, 190))
				_lbl("R%d LV %d" % [f.rank, f.level], pos + Vector2(0, 150), 18, Color.WHITE, 155, HORIZONTAL_ALIGNMENT_CENTER, true)
		elif i < picks.size() + fw:
			_icon(Art.firmware(w.rank), pos + Vector2(14, 50), Vector2(127, 80))
			_lbl("MK %d" % w.rank, pos + Vector2(0, 150), 18, UI.YELLOW, 155, HORIZONTAL_ALIGNMENT_CENTER, true)
		else:
			_lbl("RANK %d" % w.rank, pos + Vector2(0, 80), 18, UI.DIM, 155, HORIZONTAL_ALIGNMENT_CENTER, true)
	if w.rank < Data.MAX_RANK:
		_tbtn("RankScreenG/FirmwareInstallButton", Vector2(1462, 682), func():
			var go := func():
				var e := Game.rank_up(w, st.picks, int(st.fw))
				if e != "":
					err(e)
				else:
					Game.say("%s reached Rank %d!" % [t.name, w.rank], UI.YELLOW)
					st.picks = []
					st.fw = 0
				rebuild()
			if not (st.picks as Array).is_empty() and Game.can_rank_up(w) and (st.picks as Array).size() + int(st.fw) == w.rank:
				main.confirm("Consume %d Warlord(s) to raise %s to Rank %d? This cannot be undone." % [(st.picks as Array).size(), t.name, w.rank + 1], go, "Rank Up")
			else:
				go.call())
	var status := ""
	if w.rank >= Data.MAX_RANK:
		status = "MAXIMUM RANK"
	elif w.level < Game.max_level(w):
		status = "REACH LV %d TO RANK UP" % Game.max_level(w)
	else:
		status = "CONSUME %d x RANK %d (%d/%d SELECTED)" % [need, need, picks.size() + fw, need]
	_lbl(status, Vector2(1282, 168), 20, UI.YELLOW, 504, HORIZONTAL_ALIGNMENT_CENTER, true)
	# firmware
	_img("RankScreenG/FirmwareBGI.png", Vector2(1280, 758))
	_img("RankScreenG/FirmwareTitleI.png", Vector2(1446, 776))
	var fpos := [Vector2(1342, 805), Vector2(1482, 805), Vector2(1622, 805), Vector2(1412, 905), Vector2(1552, 905)]
	for lv in range(1, 6):
		var pos: Vector2 = fpos[lv - 1]
		var cnt := Game.item_count(["firmware", lv])
		var usable: bool = lv == w.rank and Game.can_rank_up(w) and picks.size() + fw < need and fw < cnt
		var b := _tbtn(Art.firmware(lv), pos, func():
			if usable:
				st.fw = int(st.fw) + 1
				rebuild()
			else:
				err("Mk %d Firmware stands in for a Rank %d Warlord." % [lv, lv]))
		b.modulate = Color(1, 1, 1, 1.0 if lv == w.rank else 0.45)
		b.tooltip_text = "Mk %d Firmware: counts as one Rank %d Warlord when ranking up." % [lv, lv]
		_lbl(str(cnt - (fw if lv == w.rank else 0)), pos + Vector2(20, 72), 20, Color.WHITE, 83, HORIZONTAL_ALIGNMENT_CENTER, true)
	if fw > 0:
		_ui_btn("CLEAR", Vector2(1292, 930), func():
			st.fw = 0
			rebuild(), "ghost", 112, 16)

# ================================================================ REP
func _page_rep() -> void:
	_tbtn("RepScreenG/WarlordReputationSlotButton", Vector2(1285, 218), func(): _toggle_drawer("switch"))
	_portrait(w.tpl, Vector2(1297, 232), 130)
	_img(Art.warlord_border(t.rarity), Vector2(1285, 218), 1.0, Vector2(155, 190))
	_lbl("REP %d/%d" % [w.rep, mini(6, w.rank)], Vector2(1285, 380), 20, Color.WHITE, 155, HORIZONTAL_ALIGNMENT_CENTER, true)
	_tbtn("RepScreenG/ReputationInstallButton", Vector2(1288, 415), func():
		var e := Game.rep_up(w)
		if e != "":
			err(e)
		else:
			Game.say("Reputation raised to %d" % w.rep, UI.YELLOW)
		rebuild())
	var groups := [[t.align, 218], ["generic", 538]]
	for g in groups:
		var al: String = g[0]
		var y0: int = g[1]
		_img("RepScreenG/New Assets/Deed Title 256x36.png", Vector2(1528, y0))
		_lbl(al.to_upper(), Vector2(1528, y0 + 2), 24, Data.ALIGN_COLOR[al], 254, HORIZONTAL_ALIGNMENT_CENTER, true)
		var tiers := ["minor", "major", "grand"]
		for i in 3:
			var y := y0 + 40 + i * 92
			_img("RepScreenG/New Assets/Deed Background 343x102.png", Vector2(1442, y), 0.88)
			_icon(Art.deed(al, tiers[i]), Vector2(1450, y + 4), Vector2(62, 84))
			_lbl(String(tiers[i]).to_upper(), Vector2(1540, y + 8), 22, Color.WHITE, 240, HORIZONTAL_ALIGNMENT_CENTER, true)
			_lbl(str(Game.item_count(["deeds", al, tiers[i]])), Vector2(1540, y + 42), 26, Color.WHITE, 240, HORIZONTAL_ALIGNMENT_CENTER, true)
	# requirement bars
	_img("RepScreenG/New Assets/Upgrade Panel 506x213.png", Vector2(1282, 858))
	_lbl("UPGRADE REPUTATION", Vector2(1282, 866), 22, Color.WHITE, 506, HORIZONTAL_ALIGNMENT_CENTER, true)
	if w.rep >= 6 or w.rep >= w.rank:
		_lbl("MAX REPUTATION" if w.rep >= 6 else "RANK UP TO RAISE REPUTATION FURTHER", Vector2(1282, 950), 20, UI.YELLOW, 506, HORIZONTAL_ALIGNMENT_CENTER, true)
		return
	var gain_txt := "NEXT REP:\n+%d%% STATS" % int(Data.SCALING[t.cls][t.rarity][6])
	for sl in Data.IMPLANT_UNLOCK:
		if Data.IMPLANT_UNLOCK[sl] == w.rep + 1:
			gain_txt += "\nUNLOCKS %s IMPLANT" % String(sl).to_upper()
	_lbl(gain_txt, Vector2(1285, 485), 16, UI.GREEN, 155, HORIZONTAL_ALIGNMENT_CENTER, true)
	var cost := Game.rep_cost(w)
	var rows := [[t.align, cost[0]], ["generic", cost[1]]]
	for i in 2:
		var al2: String = rows[i][0]
		var req: Dictionary = rows[i][1]
		var tier2: String = req.keys()[0]
		var need: int = req[tier2]
		var have := Game.item_count(["deeds", al2, tier2])
		var y2 := 892 + i * 82
		_bar("RepScreenG/New Assets/Upgrade Bar BG 480x73.png", "RepScreenG/New Assets/Upgrade Bar Fill 474x35.png", Vector2(1295, y2), float(have) / max(1, need), Vector2(3, 33))
		_lbl("%s: %d %s  (%d/%d)" % [al2.to_upper(), need, tier2.to_upper(), mini(have, need), need], Vector2(1340, y2 + 4), 17, Color.WHITE, 420, HORIZONTAL_ALIGNMENT_LEFT, true)

# ================================================================ NEURONET
func _page_neuronet() -> void:
	var tabs_def := [["assault", "NeuroNetScreenG/AssualtTabButton", 1282], ["protection", "NeuroNetScreenG/ProtectTabButton", 1450], ["control", "NeuroNetScreenG/ControlTabButton", 1619]]
	for td in tabs_def:
		var car: String = td[0]
		var b := _tbtn(td[1], Vector2(td[2], 225), func():
			st.career = car
			st.nn = ""
			rebuild())
		if st.career != car:
			b.modulate = Color(0.55, 0.55, 0.55)
	var career: String = st.career
	var sc := ScrollContainer.new()
	sc.position = Vector2(1280, 292)
	sc.size = Vector2(512, 520)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(sc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	sc.add_child(col)
	for li in 7:
		var row := Control.new()
		row.custom_minimum_size = Vector2(504, 201)
		col.add_child(row)
		var bg := _img("NeuroNetScreenG/NeuroNetScrollG/TierBG.png", Vector2.ZERO, 1.0, Vector2.ZERO, row)
		bg.modulate = CAREER_TINT[career].darkened(0.1)
		bg.modulate.a = 0.85
		var tl := _lbl("LAYER %d" % (li + 1), Vector2(10, 186), 30, Color.WHITE, 0, HORIZONTAL_ALIGNMENT_LEFT, true, row)
		tl.rotation = -PI / 2
		var cost: Array = Data.NN_COST[li + 1]
		_lbl("%d/4" % Game.nn_layer_points(w, li + 1), Vector2(440, 8), 18, Color.WHITE, 60, HORIZONTAL_ALIGNMENT_RIGHT, true, row)
		_lbl("%d T%d" % [cost[1], cost[0]], Vector2(430, 170), 15, Color.WHITE, 70, HORIZONTAL_ALIGNMENT_RIGHT, false, row)
		var skills: Array = Data.NEURONET[career][li]
		var layer_locked: bool = li > 0 and Game.nn_layer_points(w, li) < 2
		var layer_full: bool = Game.nn_layer_points(w, li + 1) >= Data.NN_POINTS_PER_LAYER
		for si in 2:
			var sk: Dictionary = skills[si]
			var pts := int(w.nn.get(sk.id, 0))
			var x := 90 + si * 175
			var base: String = "NeuroNetScreenG/NeuroNetScrollG/%sSkillIconButton" % ("Aquired" if pts > 0 else "UnAquired")
			var sid: String = sk.id
			var b := Art.button(base, func():
				st.nn = sid
				rebuild(), Vector2(x, 11), 1.0)
			b.size = Vector2(155, 179)
			row.add_child(b)
			var ic := _icon(Art.nn_icon(sid), Vector2(x + 14, 22), Vector2(127, 145), row)
			var partner_taken: bool = int(w.nn.get(skills[1 - si].id, 0)) > 0
			if pts == 0:
				ic.modulate = Color(0.45, 0.45, 0.45)
				if partner_taken or layer_full or layer_locked:
					ic.modulate = Color(0.25, 0.25, 0.25)
					b.modulate = Color(0.55, 0.55, 0.55)
			if st.nn == sid:
				_img("NeuroNetScreenG/NeuroNetScrollG/SkillIconOutline.png", Vector2(x - 11, 1), 1.0, Vector2.ZERO, row)
			var smax := int(sk.get("max", 2))
			for p in smax:
				var pip := "NeuroNetScreenG/NeuroNetScrollG/PointSpent1.png" if p < pts else "NeuroNetScreenG/NeuroNetScrollG/PointUnspent2.png"
				_img(pip, Vector2(x + 4 + p * 14, 6), 0.9, Vector2.ZERO, row)
			b.tooltip_text = "%s %d/%d\n%s" % [sk.name, pts, smax, sk.desc]
		if layer_locked:
			row.modulate = Color(0.55, 0.55, 0.55)
			_lbl("LOCKED: 2 POINTS IN LAYER %d" % li, Vector2(60, 86), 20, UI.YELLOW, 400, HORIZONTAL_ALIGNMENT_CENTER, true, row)
	# owned fragments
	_img("NeuroNetScreenG/OwnedMFBackground.png", Vector2(1280, 828))
	for tier in [1, 2, 3]:
		_img(Art.mf_icon(tier), Vector2(1300 + (tier - 1) * 108, 842))
		_lbl(U.fmt(Game.item_count(["mf", tier])), Vector2(1290 + (tier - 1) * 108, 944), 22, Color.WHITE, 95, HORIZONTAL_ALIGNMENT_CENTER, true)
	_img("NeuroNetScreenG/CostSlot.png", Vector2(1625, 815))
	var selid: String = st.nn
	if selid != "":
		var sk2: Dictionary = Data.NN_BY_ID[selid]
		var c2: Array = Data.NN_COST[sk2.layer]
		_img(Art.mf_icon(c2[0]), Vector2(1682, 838))
		_lbl(str(c2[1]), Vector2(1625, 948), 24, Color.WHITE, 190, HORIZONTAL_ALIGNMENT_CENTER, true)
		_nn_modal(sk2)
	else:
		_lbl("SELECT\nA SKILL", Vector2(1625, 880), 20, UI.DIM, 190, HORIZONTAL_ALIGNMENT_CENTER, true)
	_tbtn("NeuroNetScreenG/NeuronetInstallButton", Vector2(1645, 988), func():
		if st.nn == "":
			err("Select a skill first")
			return
		err(Game.nn_add(w, st.nn))
		rebuild())
	var rb := _ui_btn("RESET  %d   " % Game.NN_RESET_COST, Vector2(1280, 1000), func(): main.confirm("Refund all fragments for %d Trinium?" % Game.NN_RESET_COST, func():
		err(Game.nn_reset(w))
		rebuild()), "ghost", 200, 16)
	var tri := Icon.make("diamond", UI.CYAN, 18)
	tri.position = Vector2(160, 17)
	rb.add_child(tri)

func _nn_modal(sk: Dictionary) -> void:
	_img("NeuroNetScreenG/Modal Description/ModalSkillBackground.png", Vector2(60, 45))
	_img("NeuroNetScreenG/Modal Description/ModalSkillIcon.png", Vector2(8, 40))
	_icon(Art.nn_icon(sk.id), Vector2(18, 52), Vector2(134, 154))
	var pts := int(w.nn.get(sk.id, 0))
	var smax := int(sk.get("max", 2))
	_lbl("%s  %d/%d" % [String(sk.name).to_upper(), pts, smax], Vector2(175, 60), 26, UI.MAGENTA, 0, HORIZONTAL_ALIGNMENT_LEFT, true)
	_lbl(String(sk.desc).to_upper(), Vector2(175, 98), 18, Color.WHITE, 470)
	var vals: Array = sk.get("v", [])
	if not vals.is_empty():
		var now_t: String = (str(vals[pts - 1]) + "%") if pts > 0 else "-"
		var next_t: String = (str(vals[pts]) + "%") if pts < vals.size() else "MAX"
		_lbl("NOW: %s   NEXT: %s" % [now_t, next_t], Vector2(175, 156), 16, UI.CYAN, 470)
	var why := Game.nn_can(w, sk.id)
	_lbl(why.to_upper() if why != "" else "READY TO INSTALL", Vector2(175, 180), 15, UI.YELLOW if why != "" else UI.GREEN, 470)

# ================================================================ ABILITIES
func _page_abilities() -> void:
	_img("AbilityScreenG/SelectedWarlordAbilitiesG/WarlordAbilitiesBG.png", Vector2(1298, 228))
	var abil: Array = t.abilities
	if st.ability == "" and not abil.is_empty():
		st.ability = abil[0].id
	for i in 6:
		var pos: Vector2 = ABIL_POS[i]
		var b := _tbtn("AbilityScreenG/SelectedWarlordAbilitiesG/WarlordAbilitySlotButton%d" % (i + 1), pos, func():
			if i < abil.size():
				st.ability = abil[i].id
				rebuild())
		if i >= abil.size():
			b.modulate = Color(0.4, 0.4, 0.4, 0.5)
			continue
		var a: Dictionary = abil[i]
		var short: String = {"active": "ATK", "passive": "PASV", "leader": "LEAD", "reinforce": "REIN"}[a.type]
		_lbl(short, pos + Vector2(4, 74), 26, UI.CYAN if a.type == "active" else UI.PURPLE, 126, HORIZONTAL_ALIGNMENT_CENTER, true)
		_lbl(String(a.name).to_upper(), pos + Vector2(14, 106), 13, Color.WHITE, 106, HORIZONTAL_ALIGNMENT_CENTER, true, null, false)
		var badge := Vector2(minf(pos.x + 68, 1298 + 476 - 125), pos.y + 44)
		_img("AbilityScreenG/SelectedWarlordAbilitiesG/AbilitySlot%dLevelBG.png" % (i + 1), badge)
		_lbl("%d/%d" % [int(w.ab.get(a.id, 1)), Data.ability_max_level(a)], badge + Vector2(42, 3), 15, Color.WHITE, 78, HORIZONTAL_ALIGNMENT_CENTER, true)
		b.tooltip_text = a.desc
		b.modulate = Color(1.3, 1.25, 1.3) if st.ability == a.id else Color(0.75, 0.75, 0.8)
	var sel = null
	for a in abil:
		if a.id == st.ability:
			sel = a
	if sel != null:
		_img("AbilityScreenG/ModalAbilityG/ModalAbilityBG.png", Vector2(5, 42))
		_img("AbilityScreenG/ModalAbilityG/ModalSelectedAbilitySlot.png", Vector2(18, 52))
		_lbl({"active": "ATK", "passive": "PASV", "leader": "LEAD", "reinforce": "REIN"}[sel.type], Vector2(18, 110), 30, UI.CYAN, 148, HORIZONTAL_ALIGNMENT_CENTER, true)
		var lv := int(w.ab.get(sel.id, 1))
		var info := "  LV %d/%d" % [lv, Data.ability_max_level(sel)]
		if sel.type == "active":
			info += "  •  " + ("BASIC" if int(sel.cd) == 0 else "CD %d" % sel.cd)
		_lbl(String(sel.name).to_upper() + info, Vector2(172, 56), 20, Color.WHITE, 480, HORIZONTAL_ALIGNMENT_LEFT, true, null, false)
		_lbl(String(sel.desc).to_upper(), Vector2(172, 92), 16, Color.WHITE, 470)
		if Data.ability_max_level(sel) > 1:
			_lbl("+%d%% EFFECT PER LEVEL" % int(round(Data.ABILITY_LEVEL_BONUS * 100)), Vector2(172, 196), 15, UI.CYAN, 470)
		else:
			_lbl("THIS ABILITY DOES NOT LEVEL", Vector2(172, 196), 15, UI.DIM, 470)
	# use warlord (duplicate) or stimm
	_img("AbilityScreenG/AbilityUpgradeG/WarlordOrStimmBG.png", Vector2(1298, 675))
	_lbl("USE WARLORD OR STIMM", Vector2(1298, 686), 22, Color.WHITE, 476, HORIZONTAL_ALIGNMENT_CENTER, true)
	var dups: Array = st.dups
	for i in 2:
		var pos2 := Vector2(1315 + i * 163, 718)
		_tbtn("AbilityScreenG/AbilityUpgradeG/WarlordSelectButton", pos2, func(): _open_fodder("dup"), 0.92)
		if i < dups.size():
			var d = Game.wl(dups[i])
			if d != null:
				_portrait(d.tpl, pos2 + Vector2(14, 14), 132)
	var stimm_r: String = st.stimm
	_tbtn("AbilityScreenG/AbilityUpgradeG/StimmSlot", Vector2(1645, 720), func():
		st.stimm = ""
		rebuild())
	if stimm_r != "":
		_icon(Art.stimm(stimm_r), Vector2(1650, 730), Vector2(105, 70))
	_tbtn("AbilityScreenG/AbilityUpgradeG/AbilityLearnButton", Vector2(1650, 832), func(): _learn())
	_lbl("DUPLICATE: +3 LEVELS\nSTIMM: +1 LEVEL (EQUAL OR HIGHER RARITY)", Vector2(1310, 890), 14, UI.DIM, 460)
	_img("AbilityScreenG/OwnedStimmsG/OwnedStimmsBG.png", Vector2(1298, 935))
	var rs := ["rare", "epic", "legendary"]
	for i in 3:
		var r: String = rs[i]
		var ok: bool = Data.rarity_idx(r) >= Data.rarity_idx(t.rarity)
		var b2 := _tbtn(Art.stimm(r), Vector2(1310 + i * 152, 948), func():
			if not ok:
				err("Requires a %s or higher Stimm" % U.cap(t.rarity))
				return
			st.stimm = r
			rebuild())
		b2.modulate = Color(1, 1, 1, 1.0 if ok else 0.35)
		b2.tooltip_text = "%s Stimm" % U.cap(r)
		_lbl(str(Game.item_count(["stimm", r])), Vector2(1310 + i * 152, 1028), 24, Color.WHITE, 144, HORIZONTAL_ALIGNMENT_CENTER, true)

## Levels the given ability can still gain.
func _levels_left(ability_id: String) -> int:
	for a in t.abilities:
		if a.id == ability_id:
			return maxi(0, Data.ability_max_level(a) - int(w.ab.get(a.id, 1)))
	return 0

func _learn(confirmed := false) -> void:
	var dups: Array = st.dups
	if dups.is_empty() and st.stimm == "":
		err("Select a duplicate Warlord or a Stimm")
		return
	var left := _levels_left(st.ability) - (1 if st.stimm != "" else 0)
	var spill: int = dups.size() * 3 - maxi(0, left)
	if not confirmed and not dups.is_empty() and spill > 0:
		main.confirm("%d level(s) will go to other abilities. Continue?" % spill, func(): _learn(true), "Learn")
		return
	var did := false
	if st.stimm != "":
		var e2 := Game.use_stimm(w, st.ability, st.stimm)
		if e2 != "":
			err(e2)
		else:
			did = true
			st.stimm = ""
	for d in dups:
		var e := Game.feed_duplicate(w, d, st.ability)
		if e != "":
			err(e)
		else:
			did = true
	st.dups = []
	if did:
		Game.say("Ability improved", UI.GREEN)
	rebuild()

# ================================================================ drawer (roster / equipment browser)
func _toggle_drawer(mode: String) -> void:
	st.drawer = "" if st.drawer == mode else mode
	rebuild()

func _open_fodder(mode: String) -> void:
	st.drawer = mode
	rebuild()

func _drawer() -> void:
	var mode: String = st.drawer
	var p := _panel(Vector2(140, 235), Vector2(1120, 710), 0.9)
	var title := ""
	match mode:
		"switch": title = "SELECT WARLORD"
		"feed": title = "FEED WARLORDS FOR XP (UP TO 6)"
		"rank": title = "CONSUME RANK %d WARLORDS (%d NEEDED)" % [w.rank, w.rank]
		"dup": title = "DUPLICATE %s (UP TO 2)" % String(t.name).to_upper()
		"equipment": title = ("%s EQUIPMENT" % String(st.slot).to_upper()) if st.slot != "" and page != "upgrade" else "EQUIPMENT"
	_lbl(title, Vector2(160, 245), 24, UI.CYAN, 700, HORIZONTAL_ALIGNMENT_LEFT, true)
	var ftxt: Array = []
	for k in st.filter:
		ftxt.append("%s: %s" % [k, str(st.filter[k])])
	_lbl(", ".join(ftxt).to_upper(), Vector2(160, 276), 14, UI.YELLOW, 900)
	_ui_btn("✕", Vector2(1195, 243), func():
		st.drawer = ""
		rebuild(), "ghost", 50, 18)
	var sc := ScrollContainer.new()
	sc.position = Vector2(155, 300)
	sc.size = Vector2(1090, 630)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	canvas.add_child(sc)
	var flow := HFlowContainer.new()
	flow.custom_minimum_size.x = 1070
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	sc.add_child(flow)
	if mode == "equipment":
		for it in _equip_list():
			flow.add_child(_equip_card(it))
	else:
		for f in _warlord_list(mode):
			flow.add_child(_warlord_card(f, mode))
	if flow.get_child_count() == 0:
		var l := UI.lbl("Nothing matches. Adjust the filters (left bar) or reset them.", 20, UI.DIM)
		flow.add_child(l)

func _warlord_list(mode: String) -> Array:
	var f: Dictionary = st.filter
	var list: Array = Game.S.roster.filter(func(x):
		var tx: Dictionary = Game.tpl(x)
		if f.has("syndicate") and tx.syn != f.syndicate: return false
		if f.has("class") and tx.cls != f["class"]: return false
		match mode:
			"feed": return x.uid != w.uid and not x.locked and not Game.in_any_squad(x.uid)
			"rank": return x.uid != w.uid and x.rank == w.rank and not x.locked and not Game.in_any_squad(x.uid)
			"dup": return x.uid != w.uid and x.tpl == w.tpl and not x.locked and not Game.in_any_squad(x.uid)
		return true)
	var key := ""
	for k in ["level", "rank", "rep", "rarity"]:
		if f.has(k):
			key = k
	if key != "":
		var desc: bool = f[key] == "high"
		list.sort_custom(func(a, b):
			var va: int = Data.rarity_idx(Game.tpl(a).rarity) if key == "rarity" else int(a[key])
			var vb: int = Data.rarity_idx(Game.tpl(b).rarity) if key == "rarity" else int(b[key])
			return va > vb if desc else va < vb)
	else:
		list.sort_custom(func(a, b): return Game.power(a) > Game.power(b))
	return list

func _warlord_card(f: Dictionary, mode: String) -> Control:
	var tf: Dictionary = Game.tpl(f)
	var c := Control.new()
	c.custom_minimum_size = Vector2(150, 198)
	var picked: bool = (st.picks as Array).has(f.uid) or (st.dups as Array).has(f.uid) or (mode == "switch" and f.uid == w.uid)
	var pr := UI.portrait(f.tpl, 124) as Portrait
	pr.position = Vector2(13, 14)
	pr.size = Vector2(124, 124)
	c.add_child(pr)
	var br := Art.rect(Art.warlord_border(tf.rarity), Vector2.ZERO, 1.0, Vector2(150, 198))
	c.add_child(br)
	var nm := UI.lbl(tf.name, 14, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	nm.position = Vector2(4, 142)
	nm.size = Vector2(142, 20)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	c.add_child(nm)
	var info := UI.lbl("LV %d  R%d" % [f.level, f.rank] + ("  +%s XP" % U.fmt(Game.feed_xp_value(f)) if mode == "feed" else ""), 13, UI.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	info.position = Vector2(4, 162)
	info.size = Vector2(142, 20)
	c.add_child(info)
	if picked:
		var g := ColorRect.new()
		g.color = Color(1, 0.84, 0.16, 0.25)
		g.size = Vector2(150, 198)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(g)
	var uid: String = f.uid
	_hit(Vector2.ZERO, Vector2(150, 198), func(): _pick_warlord(uid, mode), "%s • %s %s • %s" % [tf.name, U.cap(tf.rarity), Data.CLASS_INFO[tf.cls].name, Data.SYNDICATES[tf.syn].name], c)
	return c

func _pick_warlord(uid: String, mode: String) -> void:
	match mode:
		"switch":
			params.uid = uid
			st.drawer = ""
			st.picks = []
			st.dups = []
			st.fw = 0
			st.item = ""
		"feed", "rank":
			var picks: Array = st.picks
			var cap: int = 6 if mode == "feed" else maxi(0, w.rank - int(st.fw))
			if picks.has(uid):
				picks.erase(uid)
			elif picks.size() < cap:
				picks.append(uid)
			else:
				err("All slots are filled")
		"dup":
			var dups: Array = st.dups
			if dups.has(uid):
				dups.erase(uid)
			elif dups.size() < clampi(ceili(_levels_left(st.ability) / 3.0), 1, 2):
				dups.append(uid)
			else:
				err("Enough duplicates selected for this ability")
	rebuild()

func _equip_list() -> Array:
	var f: Dictionary = st.filter
	var slot: String = f.get("slot", st.slot if page != "upgrade" else "")
	var list: Array = Game.S.equip.filter(func(e):
		if page == "gear" and e.kind != "gear": return false
		if page == "implants" and e.kind != "implant": return false
		if slot != "" and e.slot != slot: return false
		if f.has("set") and e.set != f.set: return false
		if f.has("stats"):
			var has_stat: bool = e.pri.stat == f.stats or e.subs.any(func(sb): return sb.stat == f.stats)
			if not has_stat: return false
		return true)
	var key := ""
	for k in ["level", "rank", "rarity"]:
		if f.has(k):
			key = k
	if key != "":
		var desc: bool = f[key] == "high"
		list.sort_custom(func(a, b):
			var va: int = Data.rarity_idx(a.rarity) if key == "rarity" else int(a[key])
			var vb: int = Data.rarity_idx(b.rarity) if key == "rarity" else int(b[key])
			return va > vb if desc else va < vb)
	else:
		list.sort_custom(func(a, b): return (a.owner == w.uid and b.owner != w.uid) or ((a.owner == w.uid) == (b.owner == w.uid) and a.rank * 100 + a.level > b.rank * 100 + b.level))
	return list

func _equip_card(it: Dictionary) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(152, 184)
	c.add_child(Art.icon(Art.SLOT_BUTTON[it.slot], Vector2(152, 184)))
	c.add_child(Art.rect(Art.equip_border(it.rarity), Vector2.ZERO, 1.0, Vector2(152, 184)))
	var l := UI.lbl("R%d +%d" % [it.rank, it.level], 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	l.position = Vector2(0, 140)
	l.size = Vector2(152, 22)
	c.add_child(l)
	var l2 := UI.lbl(it.set if it.set != "" else "Implant", 12, UI.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	l2.position = Vector2(0, 160)
	l2.size = Vector2(152, 18)
	l2.clip_text = true
	c.add_child(l2)
	if it.owner != "":
		# check = worn by this warlord, users = worn by someone else
		var o := Icon.make("check" if it.owner == w.uid else "users", UI.GREEN if it.owner == w.uid else UI.YELLOW, 20)
		o.position = Vector2(10, 8)
		c.add_child(o)
	if st.item == it.uid:
		var g := ColorRect.new()
		g.color = Color(1, 0.84, 0.16, 0.22)
		g.size = Vector2(152, 184)
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(g)
	var uid: String = it.uid
	_hit(Vector2.ZERO, Vector2(152, 184), func():
		st.item = uid
		if page != "upgrade":
			st.slot = it.slot
		rebuild(), UI.item_tooltip(it), c)
	return c

## Every stat split by source: base (level / rank / reputation / passives / safehouse), neuronet, gear + sets.
func _stat_breakdown() -> void:
	var full := Game.compute_stats(w)
	var ng: Dictionary = w.duplicate(true)
	ng.gear = {}
	var no_gear := Game.compute_stats(ng)
	var nn_off: Dictionary = ng.duplicate(true)
	nn_off.nn = {}
	var base := Game.compute_stats(nn_off)
	var g := UI.grid(5, 14)
	for h in ["STAT", "BASE", "NEURONET", "GEAR + SETS", "TOTAL"]:
		g.add_child(UI.lbl(h, 14, UI.CYAN))
	for k in ["hp", "arm", "fp", "spd", "cc", "cd", "hack", "fw"]:
		var pct: bool = k in ["cc", "cd"]
		var f := func(v: float) -> String: return (str(snappedf(v, 0.1)) + "%") if pct else U.fmt(v)
		g.add_child(UI.lbl(Data.STATS[k].name, 14))
		g.add_child(UI.lbl(f.call(base[k]), 14))
		g.add_child(UI.lbl("+" + f.call(float(no_gear[k]) - float(base[k])), 14, UI.PURPLE))
		g.add_child(UI.lbl("+" + f.call(float(full[k]) - float(no_gear[k])), 14, UI.GREEN))
		g.add_child(UI.lbl(f.call(full[k]), 15, UI.YELLOW))
	var v := UI.vb(10)
	v.add_child(UI.lbl("%s  •  Lv %d  Rank %d  Rep %d  •  Power %s" % [t.name, w.level, w.rank, w.rep, U.fmt(Game.power(w))], 15))
	v.add_child(g)
	var sets_txt: Array = []
	for sn in full.sets:
		var sd: Dictionary = Data.SETS[sn]
		var times := int(full.sets[sn] / sd.pieces)
		sets_txt.append("%s %d/%d%s" % [sn, full.sets[sn], sd.pieces, (" ACTIVE x%d: %s" % [times, sd.desc]) if times > 0 else " (inactive)"])
	v.add_child(UI.lbl("Sets: " + ("; ".join(sets_txt) if not sets_txt.is_empty() else "none"), 13, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	var gear_lines: Array = []
	for slot in Data.ALL_SLOTS:
		var it = Game.eq(w.gear.get(slot, ""))
		if it != null:
			var subs: Array = []
			for sb in it.subs:
				subs.append(UI.stat_text(sb.stat, float(sb.val) + float(sb.get("neon", 0))) + (" (neon)" if float(sb.get("neon", 0)) > 0 else ""))
			gear_lines.append("%s: R%d %s +%d  -  %s | %s" % [U.cap(slot), it.rank, U.cap(it.rarity), it.level, UI.stat_text(it.pri.stat, Data.primary_value(it.pri.stat, it.rank, it.level)), ", ".join(subs)])
	v.add_child(UI.lbl("\n".join(gear_lines) if not gear_lines.is_empty() else "No equipment", 12, UI.TEXT, HORIZONTAL_ALIGNMENT_LEFT, true))
	main.modal("Stat Breakdown", v, true)
