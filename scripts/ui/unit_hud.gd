class_name UnitHud
extends Control
## Floating per-unit battle HUD (matches the battle reference): a column of status icons,
## a tall vertical HP bar (shield shown as a yellow cap), a thin turn-meter bar, the level
## underneath and a target reticle over targetable units.

signal status_pressed(text: String)   # tap/click on a status icon (mobile has no hover tooltips)

var side := 0
var level := 1
var hp_ratio := 1.0
var shield_ratio := 0.0
var tm_ratio := 0.0
var icons: Array = []        # [{id, turns, debuff, tip}]
var targetable := false
var active := false
var alive := true
var reticle_pos := Vector2.ZERO   # local position of the reticle (over the unit's head)
var _pulse := 0.0

const BAR_W := 9.0
const BAR_H := 118.0
const TM_W := 3.0
const ICON := 26.0
const MAX_ICONS := 5
const BUFF_COL := Color("#3DFF9A")
const DEBUFF_COL := Color("#ff4fb0")

const TEX_DIR := "res://assets/ui/BattleHUD/"
static var _tex := {}

static func _t(name: String) -> Texture2D:
	if not _tex.has(name):
		var p := TEX_DIR + name + ".png"
		_tex[name] = load(p) if ResourceLoader.exists(p) else null
	return _tex[name]

func _ready() -> void:
	# only the status icon column takes the mouse (see _has_point), for per-icon tooltips
	mouse_filter = Control.MOUSE_FILTER_PASS
	tooltip_text = " "
	custom_minimum_size = Vector2(46, BAR_H + 18)
	size = custom_minimum_size

func _shown_count() -> int:
	return icons.size() if icons.size() <= MAX_ICONS else MAX_ICONS - 1

## Index into icons under a local point, -2 for the "+N" overflow box, -1 for none.
func _icon_at(p: Vector2) -> int:
	if not alive or p.x < 0.0 or p.x > ICON:
		return -1
	for i in _shown_count():
		var y: float = BAR_H - (i + 1) * (ICON + 3.0)
		if p.y >= y and p.y <= y + ICON:
			return i
	if icons.size() > MAX_ICONS:
		var y2: float = BAR_H - MAX_ICONS * (ICON + 3.0)
		if p.y >= y2 and p.y <= y2 + ICON:
			return -2
	return -1

func _has_point(p: Vector2) -> bool:
	return _icon_at(p) != -1

func _icon_text(i: int) -> String:
	if i == -2:
		var rest: Array = []
		for j in range(_shown_count(), icons.size()):
			rest.append(String(icons[j].get("tip", icons[j].id)))
		return "\n".join(rest)
	if i < 0 or i >= icons.size():
		return ""
	return String(icons[i].get("tip", icons[i].id))

func _get_tooltip(at_position: Vector2) -> String:
	return _icon_text(_icon_at(at_position))

func _gui_input(ev: InputEvent) -> void:
	if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) or (ev is InputEventScreenTouch and ev.pressed):
		var t := _icon_text(_icon_at(ev.position))
		if t != "":
			status_pressed.emit(t.replace("\n", "  •  "))
			accept_event()

func _process(delta: float) -> void:
	_pulse += delta * 4.0
	queue_redraw()

func _draw() -> void:
	if not alive:
		return
	var col := UI.CYAN if side == 0 else Color("#ff2e55")
	var bx := ICON + 6.0
	var top := 0.0
	# HP bar frame + fill (fills from the bottom)
	draw_rect(Rect2(bx - 1, top - 1, BAR_W + 2, BAR_H + 2), Color(0, 0, 0, 0.75))
	draw_rect(Rect2(bx, top, BAR_W, BAR_H), col.darkened(0.75))
	var fh: float = BAR_H * clamp(hp_ratio, 0.0, 1.0)
	var hp_tex := _t("hp_ally" if side == 0 else "hp_enemy")
	if hp_tex:
		draw_texture_rect_region(hp_tex, Rect2(bx, top + BAR_H - fh, BAR_W, fh), Rect2(0, hp_tex.get_height() * (1.0 - fh / BAR_H), hp_tex.get_width(), hp_tex.get_height() * fh / BAR_H))
	else:
		draw_rect(Rect2(bx, top + BAR_H - fh, BAR_W, fh), col)
		draw_rect(Rect2(bx, top + BAR_H - fh, 2, fh), col.lightened(0.5))
	if shield_ratio > 0.0:
		var sh: float = BAR_H * clamp(shield_ratio, 0.0, 1.0 - clamp(hp_ratio, 0.0, 1.0) + 0.25)
		sh = min(sh, BAR_H)
		var sy: float = max(top, top + BAR_H - fh - sh * 0.5)
		var sh_tex := _t("shield")
		var srect := Rect2(bx, sy, BAR_W, min(sh, BAR_H - (sy - top)))
		if sh_tex:
			draw_texture_rect(sh_tex, srect, false)
		else:
			draw_rect(srect, Color("#ffe14a"))
	# turn meter (thin white bar to the left of the HP bar)
	var tx := bx - TM_W - 2.0
	draw_rect(Rect2(tx, top, TM_W, BAR_H), Color(1, 1, 1, 0.12))
	var th: float = BAR_H * clamp(tm_ratio, 0.0, 1.0)
	var tm_tex := _t("tm_bar")
	if tm_tex:
		draw_texture_rect(tm_tex, Rect2(tx, top + BAR_H - th, TM_W, th), false)
	else:
		draw_rect(Rect2(tx, top + BAR_H - th, TM_W, th), Color(1, 1, 1, 0.95))
	# status icons: column bottom-up beside the bars. Colour says buff (green) or debuff (pink)
	# on both sides; stroke pictograms, not font glyphs.
	var font := get_theme_default_font()
	var shown: int = _shown_count()
	for i in shown:
		var ic: Dictionary = icons[i]
		var y: float = top + BAR_H - (i + 1) * (ICON + 3.0)
		var r := Rect2(0, y, ICON, ICON)
		var c: Color = DEBUFF_COL if ic.debuff else BUFF_COL
		draw_rect(r, Color(0.05, 0.02, 0.1, 0.9))
		draw_rect(r, c, false, 1.5)
		_paint_status(font, String(ic.get("id", "")), r, c.lightened(0.35))
		if int(ic.turns) > 0:
			var br := Rect2(r.end.x - 11, r.end.y - 11, 12, 12)
			draw_rect(br, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(br.position.x, br.end.y - 2), str(int(ic.turns)), HORIZONTAL_ALIGNMENT_CENTER, 12, 12, Color.WHITE)
	if icons.size() > MAX_ICONS:
		var y2: float = top + BAR_H - MAX_ICONS * (ICON + 3.0)
		var r2 := Rect2(0, y2, ICON, ICON)
		draw_rect(r2, Color(0.05, 0.02, 0.1, 0.9))
		draw_rect(r2, UI.DIM, false, 1.5)
		draw_string(font, Vector2(0, y2 + ICON - 8), "+%d" % (icons.size() - shown), HORIZONTAL_ALIGNMENT_CENTER, ICON, 13, Color.WHITE)
	# level number under the bar
	draw_string(font, Vector2(bx - 14, top + BAR_H + 13), str(level), HORIZONTAL_ALIGNMENT_RIGHT, 30, 13, Color.WHITE)
	var tick := _t("level_tick")
	if tick:
		draw_texture_rect(tick, Rect2(bx - 14, top + BAR_H + 13, 26, 8), false, Color.WHITE if side == 1 else Color(0.5, 1.4, 1.6))
	else:
		draw_line(Vector2(bx - 12, top + BAR_H + 15), Vector2(bx + BAR_W + 2, top + BAR_H + 15), col, 1.5)
	if active:
		draw_rect(Rect2(bx - 3, top - 3, BAR_W + 6, BAR_H + 6), Color("#38e07b"), false, 2.0)
	if targetable:
		_draw_reticle(reticle_pos, 15.0 + sin(_pulse) * 1.5)

## Status pictograms: stat effects are the stat's stroke icon plus an up/down arrow; every
## other buff/debuff has its own stroke glyph (no shared shapes, no letter codes).
const STATUS_ICON := {
	"spd": "bolt", "arm": "shield", "fp": "swords", "hack": "chart", "fw": "lock", "cc": "star", "cd": "diamond",
	"contHeal": "plus", "poison": "skull", "cdIncrease": "clock",
}

func _paint_status(_font: Font, id: String, r: Rect2, c: Color) -> void:
	var stat := ""
	var up := true
	for suf in ["Up", "Down"]:
		if id.ends_with(suf) and STATUS_ICON.has(id.trim_suffix(suf)):
			stat = id.trim_suffix(suf)
			up = suf == "Up"
	var name: String = STATUS_ICON.get(stat if stat != "" else id, "")
	var s := (r.size.x - 6.0) / 24.0
	var o := r.position + Vector2(2, 3)
	if name != "":
		Icon.paint(self, name, o, s, c, 1.6)
		if stat != "":
			var tx := r.end.x - 7.0
			var ty := r.position.y + 3.0
			var pts := PackedVector2Array([Vector2(tx - 4, ty + 5), Vector2(tx, ty), Vector2(tx + 4, ty + 5)]) if up else PackedVector2Array([Vector2(tx - 4, ty), Vector2(tx, ty + 5), Vector2(tx + 4, ty)])
			draw_polyline(pts, Color.WHITE, 2.0, true)
		return
	_glyph(id, o, s, c, 1.6)

## Local 24x24 stroke glyphs for statuses the shared Icon set has no fitting shape for.
func _glyph(id: String, o: Vector2, s: float, c: Color, w: float) -> void:
	var L := func(pts: Array) -> void:
		var pv := PackedVector2Array()
		for q in pts:
			pv.append(o + Vector2(q[0], q[1]) * s)
		draw_polyline(pv, c, w, true)
	var C := func(x, y, rad, a0, a1) -> void:
		draw_arc(o + Vector2(x, y) * s, float(rad) * s, float(a0), float(a1), 24, c, w, true)
	const SHIELD := [[12, 3], [20, 6], [20, 12], [17, 18], [12, 21], [7, 18], [4, 12], [4, 6], [12, 3]]
	match id:
		"blockDebuffs":  # shield with a tick: debuffs bounce off
			L.call(SHIELD); L.call([[8, 12], [11, 15], [16, 9]])
		"overshield":  # double shield
			L.call(SHIELD); L.call([[12, 7], [16, 9], [16, 12], [14, 16], [12, 17], [10, 16], [8, 12], [8, 9], [12, 7]])
		"bolster":  # brick wall
			L.call([[3, 6], [21, 6], [21, 20], [3, 20], [3, 6]]); L.call([[3, 11], [21, 11]]); L.call([[3, 15.5], [21, 15.5]])
			L.call([[12, 6], [12, 11]]); L.call([[8, 11], [8, 15.5]]); L.call([[16, 11], [16, 15.5]]); L.call([[12, 15.5], [12, 20]])
		"reflect":  # mirror with a bounced arrow
			L.call([[19, 3], [19, 21]]); L.call([[3, 6], [17, 12], [3, 18]]); L.call([[3, 14], [3, 18], [7, 19]])
		"vampire":  # fangs
			L.call([[3, 7], [21, 7]]); L.call([[6, 7], [8, 17], [10, 7]]); L.call([[14, 7], [16, 17], [18, 7]])
		"counter":  # return arrow
			C.call(12, 13, 7, PI * 0.9, PI * 2.4); L.call([[1, 9], [5, 13], [9, 9]])
		"unkillable":  # heart
			L.call([[12, 20], [4, 12], [3, 8], [5, 4.5], [8.5, 4], [12, 7.5], [15.5, 4], [19, 4.5], [21, 8], [20, 12], [12, 20]])
		"bleed":  # blood drop
			L.call([[12, 3], [17, 11], [18, 15], [16, 19], [12, 21], [8, 19], [6, 15], [7, 11], [12, 3]])
		"break":  # cracked plate
			L.call([[4, 4], [20, 4], [20, 20], [4, 20], [4, 4]]); L.call([[11, 4], [14, 9], [9, 13], [13, 16], [11, 20]])
		"mark":  # crosshair
			C.call(12, 12, 7, 0.0, TAU); L.call([[12, 2], [12, 7]]); L.call([[12, 17], [12, 22]]); L.call([[2, 12], [7, 12]]); L.call([[17, 12], [22, 12]])
		"enraged":  # flame
			L.call([[12, 21], [6, 17], [5, 12], [8, 7], [9, 11], [12, 3], [16, 9], [17, 6], [19, 12], [18, 17], [12, 21]])
		"stun":  # dizzy ring with sparks over the head
			draw_arc(o + Vector2(12, 14) * s, 8.0 * s, 0, TAU, 24, c, w, true)
			L.call([[6, 3], [6, 8]]); L.call([[3.5, 5.5], [8.5, 5.5]]); L.call([[18, 3], [18, 8]]); L.call([[15.5, 5.5], [20.5, 5.5]])
		"shock":  # electric arc between two terminals
			L.call([[3, 8], [3, 16]]); L.call([[21, 8], [21, 16]]); L.call([[3, 12], [7, 7], [10, 16], [14, 7], [17, 16], [21, 12]])
		"blockBuffs":  # up arrow inside a ban sign
			C.call(12, 12, 9, 0.0, TAU); L.call([[5.5, 18.5], [18.5, 5.5]]); L.call([[9, 12], [12, 8], [15, 12]])
		"healBlock":  # struck-through cross
			L.call([[12, 5], [12, 19]]); L.call([[5, 12], [19, 12]]); L.call([[4, 20], [20, 4]])
		"stupefy":  # question mark
			L.call([[7, 8], [8, 5], [12, 3], [16, 5], [17, 8], [15, 11], [12, 13], [12, 16]]); C.call(12, 20, 1, 0.0, TAU)
		"blockRevive":  # struck-through tombstone
			L.call([[6, 21], [6, 9], [8, 5], [12, 3], [16, 5], [18, 9], [18, 21], [6, 21]]); L.call([[3, 20], [21, 4]])
		_:
			C.call(12, 12, 8, 0.0, TAU)

func _draw_reticle(c: Vector2, r: float) -> void:
	var rt := _t("reticle")
	if rt:
		draw_texture_rect(rt, Rect2(c - Vector2(r, r) * 1.6, Vector2(r, r) * 3.2), false)
		return
	var red := Color("#ff2e3c")
	draw_arc(c, r, 0, TAU, 32, red, 3.0)
	draw_arc(c, r * 0.35, 0, TAU, 16, red, 2.5)
	for a in [0.0, PI / 2, PI, PI * 1.5]:
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (r - 4), c + d * (r + 6), red, 3.0)
