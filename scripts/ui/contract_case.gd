class_name ContractCase
extends Control
## Hard-shell contract case: rarity LED strip, latches, and a lid that swings open.

var col := Color("#3DA5FF")
var label := "RARE CONTRACT"
var lid_open := 0.0       # 0 closed .. 1 open
var latch_flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(280, 150)
	size = custom_minimum_size
	pivot_offset = size / 2

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var w := size.x
	# shadow
	draw_rect(Rect2(10, 150, w - 20, 14), Color(0, 0, 0, 0.5))
	# body
	draw_polygon(PackedVector2Array([Vector2(0, 54), Vector2(w, 54), Vector2(w, 150), Vector2(0, 150)]),
		PackedColorArray([Color("#3A3444"), Color("#3A3444"), Color("#1E1A26"), Color("#1E1A26")]))
	draw_rect(Rect2(0, 54, w, 96), Color("#0A080E"), false, 2.0)
	draw_rect(Rect2(14, 96, w - 28, 6), col)
	draw_rect(Rect2(10, 92, w - 20, 14), Color(col, 0.25))
	for lx in [50.0, w - 76.0]:
		draw_rect(Rect2(lx, 66, 26, 16), Color("#0A080E"))
		draw_rect(Rect2(lx, 66, 26, 16), Color("#5A5266"), false, 2.0)
		var on: float = 0.4 + 0.6 * latch_flash
		draw_rect(Rect2(lx + 8, 71, 10, 6), Color(col, on))
	# inner glow when open
	if lid_open > 0.05:
		draw_rect(Rect2(8, 50, w - 16, 10), Color(col, 0.9 * lid_open))
	# lid: hinged at y=54, flips up as it opens
	var lh := 56.0 * (1.0 - 1.7 * lid_open)
	var y0 := 54.0
	var y1 := y0 - lh
	var a := Color("#4A4456").lerp(Color("#2A2532"), lid_open)
	var b := Color("#2A2532")
	if abs(y0 - y1) >= 1.0:
		draw_polygon(PackedVector2Array([Vector2(0, min(y0, y1)), Vector2(w, min(y0, y1)), Vector2(w, max(y0, y1)), Vector2(0, max(y0, y1))]),
			PackedColorArray([a, a, b, b]))
	if lid_open < 0.5:
		var f: Font = Art.font(true)
		if f:
			var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			draw_string(f, Vector2((w - tw) / 2.0, y0 - 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		draw_rect(Rect2(w * 0.4, y1 + 14, w * 0.2, 10), Color("#0A080E"))
