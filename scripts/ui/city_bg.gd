class_name CityBackground
extends Control
## Animated procedural neon skyline used behind every screen.

var buildings: Array = []
var signs: Array = []
var rain: Array = []
var t := 0.0
var seed_val := 7
var intensity := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gen()
	resized.connect(_gen)

func _gen() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_val
	buildings.clear()
	signs.clear()
	var w: float = max(size.x, 1280.0)
	var h: float = max(size.y, 720.0)
	for layer in 3:
		var x := -20.0
		while x < w + 40:
			var bw := r.randf_range(40, 120) * (1.0 + layer * 0.3)
			var bh := r.randf_range(0.25, 0.7) * h * (1.0 - layer * 0.18)
			buildings.append({"x": x, "w": bw, "h": bh, "layer": layer, "seed": r.randi()})
			if r.randf() < 0.18 and layer > 0:
				var cols := [UI.CYAN, UI.MAGENTA, UI.PURPLE, UI.YELLOW]
				signs.append({"x": x + bw * 0.2, "y": h - bh + r.randf_range(10, 60), "w": bw * 0.6, "c": cols[r.randi_range(0, 3)], "ph": r.randf() * 6.0})
			x += bw + r.randf_range(2, 14)
	rain.clear()
	for i in 90:
		rain.append(Vector2(r.randf() * w, r.randf() * h))

func _process(delta: float) -> void:
	t += delta
	for i in rain.size():
		rain[i].y += delta * 520.0
		rain[i].x -= delta * 60.0
		if rain[i].y > size.y:
			rain[i] = Vector2(randf() * size.x + 60, -10)
	queue_redraw()

var photo: Texture2D
var mode := "photo"
var tint := Color("#0E2238")
var _glow: GradientTexture2D

## "photo" = city art; "dark" = void with a soft tinted glow (screens that carry their own subject).
func set_mode(m: String, c: Color) -> void:
	mode = m
	tint = c
	var g := Gradient.new()
	g.set_color(0, Color(c, 1.0))
	g.set_color(1, Color(c, 0.0))
	_glow = GradientTexture2D.new()
	_glow.gradient = g
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_glow.width = 256
	_glow.height = 256
	queue_redraw()

func _draw() -> void:
	if mode == "none":
		return
	if mode == "dark":
		_draw_dark()
		return
	if photo == null:
		photo = Art.tex(Art.BACKGROUND)
	if photo != null:
		_draw_photo()
		return
	var h := size.y
	# sky gradient
	var steps := 16
	for i in steps:
		var f := float(i) / steps
		var c := Color("#07081a").lerp(Color("#2a0d3d"), f * 0.9)
		draw_rect(Rect2(0, h * f, size.x, h / steps + 1), c)
	# moon haze
	draw_circle(Vector2(size.x * 0.78, h * 0.18), 70, Color(1.0, 0.18, 0.53, 0.08))
	draw_circle(Vector2(size.x * 0.78, h * 0.18), 40, Color(1.0, 0.4, 0.7, 0.12))
	for b in buildings:
		var layer: int = b.layer
		var base := Color("#0b0c22").lerp(Color("#03030a"), layer / 2.0)
		var rect := Rect2(b.x, h - b.h, b.w, b.h)
		draw_rect(rect, base)
		draw_line(Vector2(b.x, h - b.h), Vector2(b.x + b.w, h - b.h), UI.CYAN.darkened(0.6 + layer * 0.1), 1.0)
		var r := RandomNumberGenerator.new()
		r.seed = b.seed
		var wy: float = h - b.h + 8
		while wy < h - 6:
			var wx: float = b.x + 5
			while wx < b.x + b.w - 6:
				if r.randf() < 0.35 * intensity:
					var flick := 0.6 + 0.4 * sin(t * 2.0 + r.randf() * 10.0)
					var wc := (UI.YELLOW if r.randf() < 0.5 else UI.CYAN).darkened(0.55 + layer * 0.1)
					wc.a = 0.5 * flick
					draw_rect(Rect2(wx, wy, 4, 3), wc)
				wx += 9
			wy += 10
	for s in signs:
		var a := 0.55 + 0.45 * sin(t * 3.0 + s.ph)
		var c: Color = s.c
		c.a = a
		draw_rect(Rect2(s.x, s.y, s.w, 6), c)
		var glow := c
		glow.a = a * 0.25
		draw_rect(Rect2(s.x - 4, s.y - 4, s.w + 8, 14), glow)
	for p in rain:
		draw_line(p, p + Vector2(-3, 12), Color(0.5, 0.8, 1.0, 0.18), 1.0)
	# floor glow
	draw_rect(Rect2(0, h - 3, size.x, 3), Color(1.0, 0.18, 0.53, 0.5))

func _draw_dark() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UI.BG)
	if _glow != null:
		draw_texture_rect(_glow, Rect2(Vector2(-size.x * 0.1, -size.y * 0.35), Vector2(size.x * 1.2, size.y * 1.5)), false)
	# fine diagonal hatching + scanlines
	var x := -size.y
	while x < size.x:
		draw_line(Vector2(x, size.y), Vector2(x + size.y * 0.47, 0), Color(UI.CYAN, 0.025), 2.0)
		x += 22.0
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.14), 1.0)
		y += 3.0

## Cover-fit the supplied background art, then animated rain and a shade for readability.
func _draw_photo() -> void:
	var ts := photo.get_size()
	var sc: float = max(size.x / ts.x, size.y / ts.y)
	var dsz := ts * sc
	draw_texture_rect(photo, Rect2((size - dsz) / 2.0, dsz), false)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.06, 0.42))
	for p in rain:
		draw_line(p, p + Vector2(-3, 12), Color(0.6, 0.85, 1.0, 0.16), 1.0)
	# CRT scanlines + subtle grid + vignette for the cyberpunk screen feel
	var y := 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0, 0, 0, 0.16), 1.0)
		y += 3.0
	var gx := fmod(t * 6.0, 64.0)
	var x := -64.0 + gx
	while x < size.x:
		draw_line(Vector2(x, size.y * 0.72), Vector2(x - 120, size.y), Color(0.16, 0.89, 1.0, 0.05), 1.0)
		x += 64.0
	for i in 10:
		var a := 0.05 * (10 - i) / 10.0
		draw_rect(Rect2(Vector2(i * 6, i * 6), size - Vector2(i * 12, i * 12)), Color(0, 0, 0, a), false, 6.0)
