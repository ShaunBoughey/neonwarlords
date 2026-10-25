class_name CtaHex
extends Button
## The big gold hexagonal BATTLE call-to-action (city hub only).

var label := "BATTLE"
var icon_name := "swords"
var _hover := 0.0

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, StyleBoxEmpty.new())
	pressed.connect(func(): Sfx.play("confirm"))
	mouse_entered.connect(func(): create_tween().tween_property(self, "_hover", 1.0, 0.12))
	mouse_exited.connect(func(): create_tween().tween_property(self, "_hover", 0.0, 0.2))

func _set_hover(v: float) -> void:
	_hover = v
	queue_redraw()

func _process(_d: float) -> void:
	queue_redraw()

func _hex(r: Rect2) -> PackedVector2Array:
	var w := r.size.x
	var h := r.size.y
	return PackedVector2Array([r.position + Vector2(w * 0.25, 0), r.position + Vector2(w * 0.75, 0), r.position + Vector2(w, h * 0.5),
		r.position + Vector2(w * 0.75, h), r.position + Vector2(w * 0.25, h), r.position + Vector2(0, h * 0.5)])

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var r := Rect2(Vector2.ZERO, size)
	for i in 4:
		var g := r.grow(4 + i * 4)
		draw_colored_polygon(_hex(g), Color(UI.GOLD, 0.08 + 0.05 * _hover))
	draw_colored_polygon(_hex(r), Color("#B97500"))
	var inner := _hex(r.grow(-4))
	var cols := PackedColorArray()
	var top := Color("#FFE08A").lerp(Color("#FFF0B8"), _hover)
	for p in inner:
		cols.append(top.lerp(Color("#E89A0C"), clampf(p.y / size.y, 0, 1)))
	draw_polygon(inner, cols)
	var f: Font = Art.font(true) if Art.font(true) else get_theme_default_font()
	var fs := int(size.y * 0.26)
	var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var isz := size.y * 0.32
	var total := isz + 10 + tw
	var x0 := (size.x - total) / 2.0
	Icon.paint(self, icon_name, Vector2(x0, (size.y - isz) / 2.0), isz / 24.0, UI.INK, 3.0)
	draw_string(f, Vector2(x0 + isz + 10, size.y / 2.0 + fs * 0.36), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UI.INK)
