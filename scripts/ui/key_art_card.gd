class_name KeyArtCard
extends Button
## Tall RAID-style mode card: scene-coloured key art, mode tag, title, status line and meter.

var scene_col := Color("#0F4C6E")
var rim := Color("#5FEBFF")
var tag_text := ""
var tag_col := UI.CYAN
var heading := ""
var sub := ""
var status_l := ""
var status_r := ""
var status_col := UI.CYAN
var meter_cur := -1
var meter_total := 0
var meter_ratio := -1.0
var dot := false
var lock_text := ""
var _hover := 0.0
var _poly: PackedVector2Array

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	for s in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(s, StyleBoxEmpty.new())
	pressed.connect(func(): Sfx.play("confirm"))
	mouse_entered.connect(func(): create_tween().tween_property(self, "_hover", 1.0, 0.12))
	mouse_exited.connect(func(): create_tween().tween_property(self, "_hover", 0.0, 0.2))
	var sil := Silhouette.new()
	sil.rim = rim
	sil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sil.offset_top = 40
	sil.offset_bottom = -96
	add_child(sil)
	var scrim := TextureRect.new()
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.45, 0.78, 1.0])
	g.colors = PackedColorArray([Color(UI.BG, 0), Color(UI.BG, 0), Color(UI.BG, 0.96), Color(UI.BG, 0.98)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 128
	scrim.texture = gt
	scrim.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	scrim.stretch_mode = TextureRect.STRETCH_SCALE
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	var t := UI.tag(tag_text, tag_col)
	t.position = Vector2(16, 16)
	add_child(t)
	var v := UI.vb(4)
	v.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	v.offset_left = 16
	v.offset_right = -16
	v.offset_bottom = -18
	v.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(v)
	var h := UI.disp(heading, 20)
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(h)
	v.add_child(UI.lbl(sub, 15, UI.DIM, HORIZONTAL_ALIGNMENT_LEFT, true))
	v.add_child(UI.spacer(false, 0, 6))
	var row := UI.hb()
	row.add_child(UI.lbl(status_l, 14, UI.TEXT))
	row.add_child(UI.spacer())
	row.add_child(UI.lbl(status_r, 14, status_col))
	v.add_child(row)
	if meter_total > 0:
		v.add_child(UI.segments(meter_cur, meter_total, status_col))
	elif meter_ratio >= 0.0:
		v.add_child(UI.bar(meter_ratio, 1.0, status_col, 6))
	if lock_text != "":
		var dimr := ColorRect.new()
		dimr.color = Color(UI.BG, 0.7)
		dimr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dimr)
		var lk := Icon.make("lock", UI.DIM, 40)
		lk.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lk.offset_left = -20
		lk.offset_top = -60
		add_child(lk)
		var lt := UI.cap(lock_text, UI.SOFT, 14)
		lt.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lt.offset_left = -105
		lt.offset_right = 105
		lt.offset_top = -10
		lt.offset_bottom = 40
		lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(lt)
	var fr := Control.new()
	fr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fr.draw.connect(func(): _frame_draw(fr))
	add_child(fr)
	_frame = fr
	for c in get_children():
		UI._ignore_mouse(c)

var _frame: Control

func _process(_d: float) -> void:
	queue_redraw()
	if _frame:
		_frame.queue_redraw()

func _chamfer(r: Rect2, c: float) -> PackedVector2Array:
	return PackedVector2Array([r.position + Vector2(c, 0), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y - c),
		Vector2(r.end.x - c, r.end.y), Vector2(r.position.x, r.end.y), r.position + Vector2(0, c)])

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var r := Rect2(Vector2.ZERO, size)
	var poly := _chamfer(r, 22)
	var cols := PackedColorArray()
	for p in poly:
		var k: float = clampf(p.y / size.y, 0, 1)
		cols.append(scene_col.lightened(0.08 * _hover).lerp(UI.BG, clampf(k * 1.3, 0, 1)))
	draw_polygon(poly, cols)
	var x := -size.y
	while x < size.x:
		draw_line(Vector2(x, size.y * 0.6), Vector2(x + size.y * 0.6 * 0.47, 0), Color(rim, 0.04), 2.0)
		x += 16.0
	if dot:
		draw_circle(Vector2(size.x - 22, 22), 9, Color(UI.RED, 0.3))
		draw_circle(Vector2(size.x - 22, 22), 6, UI.RED)

## Frame drawn above the children so the scrim never covers it.
func _frame_draw(fr: Control) -> void:
	var o := _chamfer(Rect2(Vector2(1, 1), size - Vector2(2, 2)), 22)
	o.append(o[0])
	if _hover > 0.01:
		fr.draw_polyline(o, Color(UI.CYAN, 0.3 * _hover), 8.0)
	fr.draw_polyline(o, UI.LINE.lerp(UI.CYAN, _hover), 1.5 + _hover)
