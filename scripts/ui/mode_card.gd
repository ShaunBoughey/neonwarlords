class_name ModeCard
extends Button
## RAID-style game-mode tile, cyberpunk skin: chamfered neon frame, diagonal hatching,
## hex-framed character portrait, mode tag, progress line and a slanted ENTER strip.

var col := Color("#29e3ff")
var tag := "PVE"
var heading := ""
var desc := ""
var progress := ""          # e.g. "42 / 210 chevrons"
var progress_ratio := -1.0  # 0..1 draws a bar, <0 hides it
var tpl := ""               # portrait template; empty -> big glyph
var glyph := ""
var locked_text := ""
var _hover := 0.0
var _t := 0.0

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	clip_contents = true
	mouse_entered.connect(func(): create_tween().tween_property(self, "_hover", 1.0, 0.15))
	mouse_exited.connect(func(): create_tween().tween_property(self, "_hover", 0.0, 0.2))
	var bf := Art.font(true)
	# text lives in real labels so it wraps and uses the theme fonts
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 22
	v.offset_top = 16
	v.offset_right = -170 if (tpl != "" or glyph != "") else -20
	v.offset_bottom = -60
	v.add_theme_constant_override("separation", 6)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	var tg := UI.lbl(" %s " % tag, 11, Color(0.02, 0.02, 0.06))
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = col
	tsb.skew = Vector2(0.25, 0)
	tsb.content_margin_left = 6
	tsb.content_margin_right = 6
	tg.add_theme_stylebox_override("normal", tsb)
	tg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	v.add_child(tg)
	var h := UI.lbl(heading.to_upper(), 22, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT, true)
	if bf:
		h.add_theme_font_override("font", bf)
	h.add_theme_color_override("font_shadow_color", Color(col.r, col.g, col.b, 0.5))
	h.add_theme_constant_override("shadow_outline_size", 8)
	v.add_child(h)
	var d := UI.lbl(desc, 12, Color(0.72, 0.76, 0.92), HORIZONTAL_ALIGNMENT_LEFT, true)
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(d)
	if progress != "":
		v.add_child(UI.lbl(progress, 13, col.lightened(0.35)))
	if tpl != "":
		var p := UI.portrait(tpl, 132)
		p.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		p.position = Vector2(0, 0)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.name = "Face"
		add_child(p)
	for c in get_children():
		if c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_place)
	_place()

func _place() -> void:
	var f := get_node_or_null("Face")
	if f:
		f.position = Vector2(size.x - 152, (size.y - 46) * 0.5 - 66)

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _chamfer(r: Rect2, c: float) -> PackedVector2Array:
	return PackedVector2Array([
		r.position + Vector2(c, 0), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y),
		Vector2(r.position.x, r.end.y), r.position + Vector2(0, c)])

func _draw() -> void:
	var r := Rect2(Vector2(3, 3), size - Vector2(6, 6))
	var poly := _chamfer(r, 22)
	# body gradient (dark navy -> tinted)
	var cols := PackedColorArray()
	for p in poly:
		var k: float = clampf(p.x / max(1.0, size.x), 0.0, 1.0)
		cols.append(Color(0.03, 0.035, 0.1, 0.94).lerp(Color(col.r * 0.22, col.g * 0.22, col.b * 0.3, 0.94), k * (0.7 + 0.3 * _hover)))
	draw_polygon(poly, cols)
	# diagonal hatching on the right half
	var hc := Color(col.r, col.g, col.b, 0.06 + 0.04 * _hover)
	var x := size.x * 0.45
	while x < size.x + size.y:
		draw_line(Vector2(x, r.position.y), Vector2(x - size.y, r.end.y), hc, 2.0)
		x += 14.0
	# hex frame behind the portrait / glyph
	if tpl != "":
		# slanted neon backing plate behind the portrait card
		var cy := (size.y - 46) * 0.5
		var px := size.x - 160
		var plate := PackedVector2Array([Vector2(px + 10, cy - 84), Vector2(px + 160, cy - 84), Vector2(px + 140, cy + 84), Vector2(px - 10, cy + 84)])
		draw_colored_polygon(plate, Color(col.r, col.g, col.b, 0.16 + 0.1 * _hover))
		plate.append(plate[0])
		draw_polyline(plate, Color(col.r, col.g, col.b, 0.8), 2.0, true)
		for i in 3:
			var ly := cy - 84 + 6 + i * 5
			draw_line(Vector2(px + 120, ly), Vector2(px + 152 - i * 2, ly), col, 2.0)
	elif glyph != "":
		var cpos := Vector2(size.x - 86, (size.y - 46) * 0.5)
		var rad := 78.0 + 3.0 * sin(_t * 2.0)
		var hex := PackedVector2Array()
		for i in 6:
			var a := PI / 6.0 + i * PI / 3.0
			hex.append(cpos + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(hex, Color(col.r, col.g, col.b, 0.12))
		hex.append(hex[0])
		draw_polyline(hex, Color(col.r, col.g, col.b, 0.75), 2.0, true)
		if glyph != "":
			var bf := Art.font(true)
			if bf:
				var gs := 54
				var tw := bf.get_string_size(glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gs).x
				draw_string(bf, cpos + Vector2(-tw * 0.5, gs * 0.36), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, gs, col)
	# progress bar
	if progress_ratio >= 0.0:
		var by := size.y - 52
		draw_rect(Rect2(22, by, size.x * 0.5, 4), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(22, by, size.x * 0.5 * clampf(progress_ratio, 0.0, 1.0), 4), col)
	# ENTER strip
	var sy := size.y - 40
	var strip := PackedVector2Array([Vector2(r.position.x, sy), Vector2(r.end.x, sy), Vector2(r.end.x, r.end.y - 22), Vector2(r.end.x - 22, r.end.y), Vector2(r.position.x, r.end.y)])
	draw_colored_polygon(strip, Color(col.r, col.g, col.b, 0.14 + 0.22 * _hover))
	draw_line(Vector2(r.position.x, sy), Vector2(r.end.x, sy), Color(col.r, col.g, col.b, 0.5), 1.0)
	var bf2 := Art.font(true)
	if bf2:
		var txt := locked_text if locked_text != "" else "ENTER"
		draw_string(bf2, Vector2(22, sy + 25), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE if locked_text == "" else Color(0.6, 0.6, 0.7))
		# animated chevrons
		for i in 3:
			var cx := size.x - 70 + i * 14 + fmod(_t * 18.0, 14.0) * _hover
			var a := 0.35 + 0.2 * i
			draw_polyline(PackedVector2Array([Vector2(cx, sy + 12), Vector2(cx + 7, sy + 20), Vector2(cx, sy + 28)]), Color(col.r, col.g, col.b, a), 2.0)
	# neon frame + glow + corner accents
	var outline := poly.duplicate()
	outline.append(poly[0])
	draw_polyline(outline, Color(col.r, col.g, col.b, 0.18 + 0.2 * _hover), 6.0)
	draw_polyline(outline, Color(col.r, col.g, col.b, 0.55 + 0.45 * _hover), 1.5)
	draw_line(r.position + Vector2(0, 22), r.position + Vector2(22, 0), col, 3.0)
	draw_line(Vector2(r.position.x, r.position.y + 40), Vector2(r.position.x, r.position.y + 90), col, 3.0)
