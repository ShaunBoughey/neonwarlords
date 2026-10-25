class_name HexButton
extends Button
## Hexagonal button (battle skill / AUTO / speed buttons from the battle reference).

var fill := Color("#c8401a")
var fill2 := Color("#ffb347")
var border := UI.MAGENTA
var glyph := ""
var icon_name := ""   # stroke icon (Icon.paint); drawn instead of `glyph` when set
var caption := ""
var cooldown := 0
var selected := false
var glyph_size := 34

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	text = ""
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, StyleBoxEmpty.new())
	pressed.connect(func(): Sfx.play("click"))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _hex(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 6:
		var a := PI / 6 + i * PI / 3 + PI / 2
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts

func _draw() -> void:
	var c := size / 2
	var r: float = min(size.x, size.y) / 2 - 3
	var grey := disabled or cooldown > 0
	var bcol := Color("#555566") if grey else border
	if selected and not grey:
		var glow := _hex(c, r + 5)
		draw_colored_polygon(glow, Color(bcol.r, bcol.g, bcol.b, 0.35))
	var outer := _hex(c, r)
	draw_colored_polygon(outer, bcol)
	var inner := _hex(c, r - 5)
	var cols := PackedColorArray()
	for i in inner.size():
		var t := float(i) / inner.size()
		var f1 := Color("#2a2a33") if grey else fill
		var f2 := Color("#4a4a55") if grey else fill2
		cols.append(f1.lerp(f2, 0.5 + 0.5 * sin(t * TAU)))
	draw_polygon(inner, cols)
	if is_hovered() and not grey:
		draw_colored_polygon(inner, Color(1, 1, 1, 0.12))
	var font: Font = Art.font(true) if Art.font(true) else get_theme_default_font()
	if cooldown > 0:
		draw_string(font, Vector2(0, c.y + glyph_size * 0.38), str(cooldown), HORIZONTAL_ALIGNMENT_CENTER, size.x, int(glyph_size * 1.3), Color(1, 1, 1, 0.8))
	elif icon_name != "":
		var s := glyph_size / 24.0
		Icon.paint(self, icon_name, c - Vector2(12, 12) * s, s, Color.WHITE, max(2.0, 2.2 * s))
	else:
		draw_string(font, Vector2(0, c.y + glyph_size * 0.36), glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, glyph_size, Color.WHITE)
	if caption != "":
		var cw := size.x + 24.0
		draw_multiline_string(font, Vector2(-12, size.y + 4), caption, HORIZONTAL_ALIGNMENT_CENTER, cw, 12, 2, Color(1, 1, 1, 0.92))
