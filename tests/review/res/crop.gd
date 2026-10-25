extends SceneTree
## Review helper: crops PNG regions at 1:1 for sharpness checks.
##   godot --headless -s res://tests/review/res/crop.gd -- <out.png> <in.png> x y w h [<in2.png> x y w h ...]
## Several inputs are placed side by side (each scaled to the first crop's height).
func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var parts := []
	var i := 1
	while i + 4 < a.size():
		var img := Image.load_from_file(a[i])
		var r := Rect2i(int(a[i + 1]), int(a[i + 2]), int(a[i + 3]), int(a[i + 4]))
		parts.append(img.get_region(r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))))
		i += 5
	var h: int = parts[0].get_height()
	var wsum := 0
	for p in parts:
		if p.get_height() != h:
			p.resize(int(p.get_width() * float(h) / p.get_height()), h, Image.INTERPOLATE_NEAREST)
		wsum += p.get_width() + 8
	var out := Image.create(wsum, h, false, Image.FORMAT_RGBA8)
	out.fill(Color.WHITE)
	var x := 0
	for p in parts:
		p.convert(Image.FORMAT_RGBA8)
		out.blit_rect(p, Rect2i(Vector2i.ZERO, p.get_size()), Vector2i(x, 0))
		x += p.get_width() + 8
	out.save_png(a[0])
	quit()
