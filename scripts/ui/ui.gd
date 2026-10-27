class_name UI
extends RefCounted
## Code-built UI helpers and the neon theme.

# Design system v2 (see the "Neon Warlords UI Redesign" canvas): void ground, teal glass panels,
# cyan = interactive, gold = the one forward action per screen, rarity colours mean rarity only.
const BG := Color("#05070F")
const DEEP := Color("#0A1626")
const PANEL := Color(0.047, 0.173, 0.267, 0.92)
const PANEL2 := Color("#0A1626")
const LINE := Color("#1F6F94")
const CYAN := Color("#34E0FF")
const GOLD := Color("#FFC53D")
const MAGENTA := Color("#FF3DB4")
const PURPLE := Color("#B44DFF")
const YELLOW := GOLD
const GREEN := Color("#3DFF9A")
const RED := Color("#FF3D5E")
const DIM := Color("#9FB8CC")
const HINT := Color("#8AA6BD")
const TEXT := Color("#EAF6FF")
const SOFT := Color("#C9DAE8")
const INK := Color("#1A1000")
const NOTCH := 12

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 16
	var f := Art.font(false)
	if f:
		t.default_font = f
	var bfont := Art.font(true)
	if bfont:
		t.set_font("font", "Button", bfont)
	t.set_font_size("font_size", "Button", 15)
	t.set_stylebox("normal", "Button", _sb(Color(DEEP, 0.92), LINE, 1, NOTCH, 14))
	t.set_stylebox("hover", "Button", _sb(Color(0.08, 0.16, 0.26, 0.95), CYAN, 1, NOTCH, 14))
	t.set_stylebox("pressed", "Button", _sb(Color(CYAN, 0.18), CYAN, 2, NOTCH, 14))
	t.set_stylebox("disabled", "Button", _sb(Color(1, 1, 1, 0.05), Color(0, 0, 0, 0), 0, NOTCH, 14))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", SOFT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", HINT)
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("panel", "PanelContainer", _sb(PANEL, LINE, 1, NOTCH, 12))
	t.set_stylebox("panel", "Panel", _sb(PANEL, LINE, 1, NOTCH))
	t.set_stylebox("normal", "LineEdit", _sb(DEEP, LINE, 1, 8))
	t.set_stylebox("focus", "LineEdit", _sb(DEEP, CYAN, 2, 8))
	t.set_stylebox("background", "ProgressBar", _sb(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", _sb(CYAN, CYAN, 0, 0, 0))
	t.set_stylebox("panel", "TooltipPanel", _sb(DEEP, CYAN, 1, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	var grabber := _sb(LINE, LINE, 0, 0, 0)
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", _sb(CYAN, CYAN, 0, 0, 0))
	t.set_stylebox("scroll", "VScrollBar", _sb(Color(1, 1, 1, 0.04), Color(0, 0, 0, 0), 0, 0, 0))
	t.set_stylebox("grabber", "HScrollBar", grabber)
	t.set_stylebox("scroll", "HScrollBar", _sb(Color(1, 1, 1, 0.04), Color(0, 0, 0, 0), 0, 0, 0))
	return t

## Notched frame: 45-degree cuts on the top-left and bottom-right corners (the Armoury tile shape).
## radius >= 30 keeps a fully round box for genuinely round elements.
static func _sb(bg: Color, border: Color, bw: int, radius: int, margin := 8) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	if radius >= 30:
		s.set_corner_radius_all(radius)
	elif radius > 0:
		var c: int = NOTCH if radius >= 8 else 8
		s.corner_radius_top_left = c
		s.corner_radius_bottom_right = c
		s.corner_detail = 1
	s.anti_aliasing = true
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = margin * 0.6
	s.content_margin_bottom = margin * 0.6
	return s

## Selected / focused frame: 2px accent plus a soft outer glow (glow is reserved for selection).
static func _sb_selected(col: Color, radius := NOTCH, margin := 8) -> StyleBoxFlat:
	var s := _sb(Color(col, 0.14), col, 2, radius, margin)
	s.shadow_color = Color(col, 0.35)
	s.shadow_size = 10
	return s

## Kept for older call sites.
static func _sb_panel(bg: Color, border: Color, radius: int, margin: int) -> StyleBoxFlat:
	return _sb(bg, border, 1, radius, margin)

static func _sb_btn(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	return _sb(bg, border, bw, NOTCH, 14)

## Small uppercase tracked label (section labels, tags).
static func cap(text: String, color := DIM, size := 12) -> Label:
	var l := lbl(text.to_upper(), size, color)
	var bf := Art.font(true)
	if bf:
		var fv := FontVariation.new()
		fv.base_font = bf
		fv.spacing_glyph = 2
		l.add_theme_font_override("font", fv)
	return l

## Bold display text (Vipnagorgialla Bd).
static func disp(text: String, size := 22, color := TEXT) -> Label:
	var l := lbl(text.to_upper(), size, color)
	var bf := Art.font(true)
	if bf:
		l.add_theme_font_override("font", bf)
	return l

## Coloured tag (e.g. "PVE - STORY") on a solid chip.
static func tag(text: String, col: Color) -> Label:
	var l := cap(text, Color("#05070F"), 11)
	var sb := _sb(col, col, 0, 0, 6)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	l.add_theme_stylebox_override("normal", sb)
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return l

## Segmented meter for counts (keys, entries, tokens).
static func segments(cur: int, total: int, col: Color, h := 6) -> HBoxContainer:
	var row := hb(3)
	for i in total:
		var r := ColorRect.new()
		r.color = col if i < cur else Color(1, 1, 1, 0.1)
		r.custom_minimum_size = Vector2(0, h)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(r)
	return row

## Big gold call-to-action with an optional cost badge (e.g. energy).
static func cta(text: String, cb: Callable, cost := "", cost_icon := "bolt", min_w := 0) -> Button:
	var b := btn(text, cb, "gold", min_w, 20)
	b.custom_minimum_size.y = 56
	if cost != "":
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.text = text + "      "
		var bp := PanelContainer.new()
		bp.add_theme_stylebox_override("panel", _sb(Color(INK, 0.18), Color(0, 0, 0, 0), 0, 0, 6))
		bp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge := hb(2)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_child(Icon.make(cost_icon, INK, 14))
		badge.add_child(lbl(cost, 16, INK))
		bp.add_child(badge)
		b.add_child(bp)
		b.resized.connect(func(): bp.position = Vector2(b.size.x - bp.size.x - 14, (b.size.y - bp.size.y) / 2))
	return b

# ---------------------------------------------------------------- basic nodes
static func lbl(text: String, size := 16, color := TEXT, align := HORIZONTAL_ALIGNMENT_LEFT, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 60
	return l

static func title(text: String, color := TEXT) -> Label:
	return disp(text, 24, color)

## Button kinds: gold (primary forward action), primary (cyan outline, secondary), ghost (quiet),
## danger / green (outlined semantic). "magenta" maps to gold for older call sites.
static func btn(text: String, cb: Callable, kind := "normal", min_w := 0, size := 15) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(min_w, 44)
	match kind:
		"gold", "magenta":
			b.add_theme_stylebox_override("normal", _sb(Color("#F4B53A"), Color("#FFE08A"), 0, NOTCH, 18))
			b.add_theme_stylebox_override("hover", _sb(Color("#FFCB5C"), Color("#FFE08A"), 0, NOTCH, 18))
			b.add_theme_stylebox_override("pressed", _sb(Color("#D9961A"), Color("#FFE08A"), 0, NOTCH, 18))
			for k in ["font_color", "font_hover_color", "font_pressed_color"]:
				b.add_theme_color_override(k, INK)
		"primary", "danger", "green":
			var col: Color = {"primary": CYAN, "danger": RED, "green": GREEN}[kind]
			b.add_theme_stylebox_override("normal", _sb(Color(col, 0.12), col, 2, NOTCH, 16))
			b.add_theme_stylebox_override("hover", _sb(Color(col, 0.22), col.lightened(0.2), 2, NOTCH, 16))
			b.add_theme_stylebox_override("pressed", _sb(Color(col, 0.32), col.lightened(0.3), 2, NOTCH, 16))
			b.add_theme_color_override("font_color", TEXT)
		"ghost":
			b.add_theme_stylebox_override("normal", _sb(Color(DEEP, 0.85), LINE, 1, NOTCH, 14))
	b.pressed.connect(func(): Sfx.play("confirm" if kind in ["gold", "magenta"] else "click"))
	if cb.is_valid():
		b.pressed.connect(cb)
	return b

static func hb(sep := 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func vb(sep := 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func flow(sep := 6) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", sep)
	f.add_theme_constant_override("v_separation", sep)
	return f

static func grid(cols: int, sep := 8) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	return g

static func panel(border := Color(0, 0, 0, 0), bg := PANEL, radius := NOTCH, margin := 12) -> PanelContainer:
	var p := PanelContainer.new()
	var bc := border if border.a > 0 else LINE
	p.add_theme_stylebox_override("panel", _sb(bg, bc, 1, radius, margin))
	return p

static func pad(node: Control, m := 12) -> MarginContainer:
	var mc := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + side, m)
	mc.add_child(node)
	return mc

static func scroll(child: Control, horizontal := false) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if horizontal:
		s.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	else:
		s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.add_child(child)
	return s

static func bar(val: float, maxv: float, color := CYAN, h := 8, w := 0) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max(1.0, maxv)
	p.value = val
	p.show_percentage = false
	p.custom_minimum_size = Vector2(w, h)
	p.add_theme_stylebox_override("fill", _sb(color, color, 0, 0, 0))
	p.add_theme_stylebox_override("background", _sb(Color(1, 1, 1, 0.1), Color(0, 0, 0, 0), 0, 0, 0))
	return p

static func spacer(expand := true, w := 0, h := 0) -> Control:
	var c := Control.new()
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(w, h)
	return c

static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

static func expand(c: Control, h := true, v := false) -> Control:
	if h: c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if v: c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return c

static func stars(n: int, maxn := 6, color := YELLOW, size := 14) -> Label:
	var s := ""
	for i in maxn:
		s += "★" if i < n else "☆"
	return lbl(s, size, color)

static func chevrons(n: int, size := 16) -> Label:
	var s := ""
	for i in 3:
		s += "▲" if i < n else "△"
	return lbl(s, size, YELLOW if n > 0 else DIM)

static func chip(icon: String, text: String, color := TEXT, size := 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _sb(Color(DEEP, 0.92), LINE, 1, 8, 8))
	var h := hb(6)
	if icon != "":
		h.add_child(lbl(icon, size + 1, color))
	h.add_child(lbl(text, size, TEXT))
	p.add_child(h)
	return p

static func reward_art(r: Dictionary) -> String:
	match r.get("k", ""):
		"deeds": return Art.deed(r.align, r.tier)
		"mf": return Art.mf_icon(int(r.tier))
		"neon": return Art.neon_small(r.get("stat", "hp"))
		"stimm": return Art.stimm(r.r) if r.r in ["rare", "epic", "legendary"] else ""
		"firmware": return Art.firmware(clampi(int(r.lv), 1, 5))
		"metabolic": return Art.metabolic(r.align)
	return ""

## Loot tile for a granted reward display entry {label, icon, color, equip?, warlord?}.
static func reward_tile(r: Dictionary, sz := 96) -> Control:
	var col: Color = r.get("color", Color.WHITE)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.custom_minimum_size = Vector2(sz + 20, 0)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(sz, sz * 1.15)
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var it = Game.eq(r.get("equip", "")) if r.has("equip") else null
	if it != null:
		var ic := Art.icon(Art.SLOT_BUTTON[it.slot], Vector2(sz, sz * 1.15))
		holder.add_child(ic)
		holder.add_child(Art.rect(Art.equip_border(it.rarity), Vector2.ZERO, 1.0, Vector2(sz, sz * 1.15)))
		var rk := lbl("R%d" % it.rank, 13, Color.WHITE)
		rk.position = Vector2(8, 4)
		holder.add_child(rk)
		holder.tooltip_text = item_tooltip(it)
	elif r.has("warlord") and Game.wl(r.warlord) != null:
		var w = Game.wl(r.warlord)
		var pr := portrait(w.tpl, int(sz * 0.8))
		pr.position = Vector2(sz * 0.1, sz * 0.12)
		holder.add_child(pr)
		holder.add_child(Art.rect(Art.warlord_border(Game.tpl(w).rarity), Vector2.ZERO, 1.0, Vector2(sz, sz * 1.15)))
	else:
		var bg := Panel.new()
		bg.size = Vector2(sz, sz * 1.15)
		var sb := _sb(Color("#141638"), col.darkened(0.1), 2, 10, 0)
		sb.shadow_color = Color(col.r, col.g, col.b, 0.35)
		sb.shadow_size = 6
		bg.add_theme_stylebox_override("panel", sb)
		holder.add_child(bg)
		var raw: Dictionary = r.get("reward", {"k": r.get("k", _glyph_kind(String(r.get("icon", ""))))})
		var g := reward_node(raw, int(sz * 0.6))
		g.position = (Vector2(sz, sz * 1.15) - g.custom_minimum_size) / 2.0
		holder.add_child(g)
	box.add_child(holder)
	var l := lbl(String(r.label), 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER, true)
	l.custom_minimum_size.x = sz + 20
	box.add_child(l)
	_ignore_mouse(box)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	return box

## Reward kind for a display entry that only carries U.REWARD_ICON's glyph (Game.grant output).
static func _glyph_kind(glyph: String) -> String:
	for k in U.REWARD_ICON:
		if U.REWARD_ICON[k] == glyph:
			return k
	return ""

## Art for a parsed reward {k, ...}: the user's item art where it exists, otherwise a stroke icon
## (gear and implants use their slot art with a rarity border).
static func reward_node(r: Dictionary, sz := 56) -> Control:
	var k: String = r.get("k", "")
	var rar: String = r.get("r", "")
	var art := reward_art(r)
	if art != "" and Art.has(art):
		return Art.icon(art, Vector2(sz, sz))
	if k in ["gear", "implant", "gearSet", "implantSet"]:
		var c := Control.new()
		var sz2 := Vector2(sz * 0.82, sz)
		c.custom_minimum_size = sz2
		var slot := "chest" if k.begins_with("gear") else "organs"
		c.add_child(Art.icon(Art.SLOT_BUTTON[slot], sz2))
		c.add_child(Art.rect(Art.equip_border(rar if Data.RARITY_COLOR.has(rar) else "rare"), Vector2.ZERO, 1.0, sz2))
		return c
	var ic: Array = {"credits": ["coin", TEXT], "trinium": ["diamond", CYAN], "energy": ["bolt", GOLD], "battery": ["bolt", GOLD],
		"pxp": ["up", PURPLE], "xpBoost": ["up", GREEN], "xpBoostMinor": ["up", GREEN], "pitCoin": ["pitcoin", MAGENTA],
		"heist": ["ticket", GOLD], "brawl": ["mail", CYAN], "royal": ["mail", PURPLE], "contract": ["case", Data.RARITY_COLOR.get(rar, CYAN)],
		"warlord": ["users", Data.RARITY_COLOR.get(rar, CYAN)], "cache": ["gift", GOLD], "neon": ["diamond", GREEN],
		"stimm": ["plus", GREEN], "firmware": ["settings", CYAN], "raidTicket": ["ticket", RED], "merits": ["star", GOLD]}.get(k, ["bag", GOLD])
	var icon := Icon.make(ic[0], ic[1], int(sz * 0.8))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon

static func reward_chips(list: Array, size := 13) -> HFlowContainer:
	var f := flow(4)
	for r in list:
		var col := Color.WHITE
		if r.has("r") and Data.RARITY_COLOR.has(r.get("r", "")):
			col = Data.RARITY_COLOR[r.r]
		var c := chip("", U.reward_label(r), col, size)
		var row: HBoxContainer = c.get_child(0)
		var ic := reward_node(r, size + 10)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_ignore_mouse(ic)
		row.add_child(ic)
		row.move_child(ic, 0)
		f.add_child(c)
	return f

static func badge(n: int) -> Label:
	var l := lbl(str(n), 13, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_stylebox_override("normal", _sb(RED, RED, 0, 0, 3))
	l.custom_minimum_size = Vector2(20, 18)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# ---------------------------------------------------------------- game widgets
static func portrait(tpl_id: String, size := 64) -> Control:
	var p := Portrait.new()
	p.tpl_id = tpl_id
	p.custom_minimum_size = Vector2(size, size)
	return p

static func warlord_card(w: Dictionary, cb: Callable, selected := false, compact := false) -> Button:
	var t := Game.tpl(w)
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	var sz := Vector2(118, 150) if not compact else Vector2(96, 122)
	b.custom_minimum_size = sz
	var col: Color = Data.RARITY_COLOR[t.rarity]
	b.add_theme_stylebox_override("normal", _sb_selected(col, NOTCH, 0) if selected else _sb(Color("#121A2C"), col.darkened(0.15), 2, NOTCH, 0))
	b.add_theme_stylebox_override("hover", _sb(Color("#18233A"), col.lightened(0.2), 2, NOTCH, 0))
	b.add_theme_stylebox_override("pressed", _sb(Color("#1E2A44"), col.lightened(0.3), 2, NOTCH, 0))
	var pr := portrait(w.tpl, int(sz.x - 8))
	pr.custom_minimum_size = Vector2(sz.x - 8, sz.y - 44)
	pr.size = pr.custom_minimum_size
	pr.position = Vector2(4, 4)
	b.add_child(pr)
	var strip := ColorRect.new()
	strip.color = Color(BG, 0.88)
	strip.position = Vector2(4, sz.y - 42)
	strip.size = Vector2(sz.x - 8, 38)
	b.add_child(strip)
	# long names step down a size so duplicates stay distinguishable instead of truncating
	var nlen: int = String(t.name).length()
	var nfs: int = (13 if nlen <= 13 else (11 if nlen <= 17 else 10)) if not compact else (11 if nlen <= 12 else 9)
	var nm := lbl(t.name, nfs, TEXT)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.position = Vector2(8, sz.y - 42)
	nm.size = Vector2(sz.x - 16, 18)
	b.add_child(nm)
	var lv := lbl("LV %d" % w.level, 12, DIM)
	lv.position = Vector2(8, sz.y - 23)
	b.add_child(lv)
	var st := rank_stars(w, 11 if not compact else 9)
	st.position = Vector2(8, sz.y - 24)
	st.size = Vector2(sz.x - 16, 16)
	b.add_child(st)
	var ab := align_badge(t.align, 20 if not compact else 16)
	ab.position = Vector2(sz.x - ab.custom_minimum_size.x - 6, 6)
	b.add_child(ab)
	if w.get("locked", false):
		var lk := Icon.make("lock", GOLD, 14)
		lk.position = Vector2(sz.x - 22, sz.y - 60)
		b.add_child(lk)
	if w.get("new", false):
		var nw := tag("New", MAGENTA)
		nw.position = Vector2(6, 6)
		b.add_child(nw)
	for c in b.get_children():
		_ignore_mouse(c)
	if cb.is_valid():
		b.pressed.connect(cb)
	b.tooltip_text = warlord_tooltip(w)
	return b

static func warlord_tooltip(w: Dictionary) -> String:
	var t := Game.tpl(w)
	return "%s\n%s %s  •  %s  •  %s\nLevel %d  •  Rank %d  •  Reputation %d/%d" % [t.name, U.cap(t.rarity), Data.CLASS_INFO[t.cls].name,
		Data.SYNDICATES[t.syn].name, U.cap(t.align), w.level, w.rank, w.rep, w.rank]

## Rank stars: gold per rank; stars already raised by reputation glow magenta (rep is capped at rank).
static func rank_stars(w: Dictionary, size := 11) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_OFF
	r.add_theme_font_size_override("normal_font_size", size)
	var rep: int = int(w.get("rep", 0))
	r.text = "[right][color=#%s]%s[/color][color=#%s]%s[/color][/right]" % [MAGENTA.to_html(false), "★".repeat(rep),
		GOLD.to_html(false), "★".repeat(max(0, int(w.rank) - rep))]
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

## Round alignment mark (Paragon / Neutral / Renegade / Generic) in its alignment colour.
static func align_badge(al: String, px := 20) -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(px, px)
	p.size = p.custom_minimum_size
	var col: Color = Data.ALIGN_COLOR[al]
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(BG, 0.85)
	sb.border_color = col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(px)
	p.add_theme_stylebox_override("panel", sb)
	var ic := Icon.make(al, col, int(px * 0.8))
	ic.width = 1.6
	ic.position = Vector2(px * 0.1, px * 0.1)
	p.add_child(ic)
	p.tooltip_text = ALIGN_INFO.get(al, U.cap(al))
	return p

const ALIGN_INFO := {
	"paragon": "Paragon: reputation needs Paragon + Generic Deeds. Paragon Metabolics give +50% XP. Boosted by the Safehouse Paragon nodes.",
	"neutral": "Neutral: reputation needs Neutral + Generic Deeds. Neutral Metabolics give +50% XP. Boosted by the Safehouse Neutral nodes.",
	"renegade": "Renegade: reputation needs Renegade + Generic Deeds. Renegade Metabolics give +50% XP. Boosted by the Safehouse Renegade nodes.",
	"generic": "Generic Deeds are needed by every warlord's reputation, alongside their alignment's deeds.",
}

static func _ignore_mouse(n: Node) -> void:
	if n is Control:
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in n.get_children():
		_ignore_mouse(c)

static func item_card(it: Dictionary, cb: Callable, selected := false) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(92, 92)
	var col: Color = Data.RARITY_COLOR[it.rarity]
	var bg := Color("#1d1446") if selected else PANEL2
	b.add_theme_stylebox_override("normal", _sb(bg, col.darkened(0.2) if not selected else col, 2 if selected else 1, 8, 4))
	b.add_theme_stylebox_override("hover", _sb(bg.lightened(0.07), col, 2, 8, 4))
	b.add_theme_stylebox_override("pressed", _sb(bg.lightened(0.12), col, 2, 8, 4))
	var v := vb(0)
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var ic := Art.icon(Art.SLOT_BUTTON[it.slot], Vector2(44, 46))
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	v.add_child(lbl("R%d  +%d" % [it.rank, it.level], 12, TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	var setname: String = it.set if it.set != "" else "Implant"
	var sl := lbl(setname, 12, DIM, HORIZONTAL_ALIGNMENT_CENTER)
	sl.clip_text = true
	v.add_child(sl)
	_ignore_mouse(v)
	b.add_child(v)
	var eb := Art.rect(Art.equip_border(it.rarity), Vector2.ZERO, 1.0, b.custom_minimum_size)
	eb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(eb)
	if it.owner != "":
		var o := lbl("●", 12, GREEN)
		o.position = Vector2(6, 2)
		o.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(o)
	if it.get("locked", false):
		var lk := Icon.make("lock", YELLOW, 14)
		lk.position = Vector2(70, 2)
		lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lk)
	if cb.is_valid():
		b.pressed.connect(cb)
	b.tooltip_text = item_tooltip(it)
	return b

static func stat_text(stat: String, v: float) -> String:
	var info: Dictionary = Data.STATS.get(stat, {"name": stat, "pct": false})
	if info.pct:
		return "%s +%s%%" % [info.name.replace(" %", ""), str(snappedf(v, 0.1))]
	return "%s +%d" % [info.name, int(v)]

static func item_tooltip(it: Dictionary) -> String:
	var s := "%s\n%s  Rank %d  +%d\n" % [Game.equip_name(it), U.cap(it.rarity), it.rank, it.level]
	s += "Primary: " + stat_text(it.pri.stat, Data.primary_value(it.pri.stat, it.rank, it.level)) + "\n"
	for sub in it.subs:
		s += "  " + stat_text(sub.stat, float(sub.val) + float(sub.get("neon", 0))) + ("  ✦" if float(sub.get("neon", 0)) > 0 else "") + "\n"
	if it.set != "":
		s += "Set: %s (%d pc) - %s" % [it.set, Data.SETS[it.set].pieces, Data.SETS[it.set].desc]
		var src := set_sources(it.set)
		if src != "":
			s += "
Drops: " + src
	if it.get("kind", "") == "implant":
		s += "%s slot unlocks at Reputation %d" % [U.cap(it.slot), int(Data.IMPLANT_UNLOCK.get(it.slot, 0))]
	return s

## Where a set drops: campaign locations (GDD campaign table) and syndicate hideouts (Data.HIDEOUT_SETS).
static func set_sources(set_name: String) -> String:
	var out: Array = []
	var camp: Array = Data.GDD.campaign
	for i in camp.size():
		if String(camp[i].get("set", "")) == set_name:
			out.append("Campaign %d %s" % [i + 1, camp[i].name])
	for syn in Data.HIDEOUT_SETS:
		if set_name in Data.HIDEOUT_SETS[syn]:
			out.append("%s Hideout" % Content.HIDEOUTS[syn].name if Content.HIDEOUTS.has(syn) else syn)
	return ", ".join(out)

static func _art_chip(art: String, text: String, color: Color) -> PanelContainer:
	var c := chip("", text, color, 12)
	var row: HBoxContainer = c.get_child(0)
	var first := row.get_child(0)
	row.remove_child(first)
	first.queue_free()
	var ic := Art.icon(art, Vector2(22, 22))
	row.add_child(ic)
	row.move_child(ic, 0)
	return c

static func class_tag(cls: String) -> PanelContainer:
	var info: Dictionary = Data.CLASS_INFO[cls]
	return _art_chip(Art.CLASS_SYMBOL[cls], info.name + " • " + info.role, CYAN)

static func syn_tag(syn: String) -> PanelContainer:
	var info: Dictionary = Data.SYNDICATES[syn]
	return _art_chip(Art.SYN_SYMBOL[syn], info.name, info.color)

static func align_tag(al: String) -> PanelContainer:
	var c := chip("", U.cap(al), Data.ALIGN_COLOR[al], 12)
	var row: HBoxContainer = c.get_child(0)
	var first := row.get_child(0)
	row.remove_child(first)
	first.queue_free()
	var ic := Icon.make(al, Data.ALIGN_COLOR[al], 18)
	row.add_child(ic)
	row.move_child(ic, 0)
	c.tooltip_text = ALIGN_INFO.get(al, "")
	return c
