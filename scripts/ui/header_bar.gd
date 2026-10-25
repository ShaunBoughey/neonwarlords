class_name HeaderBar
extends Control
## Slanted neon underline with tick marks under screen titles (cyberpunk HUD flourish).

var col := Color("#29e3ff")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var h := size.y
	var w := size.x
	# main slanted bar
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(w * 0.55, 0), Vector2(w * 0.55 - h, h), Vector2(0, h)])
	draw_colored_polygon(pts, Color(col.r, col.g, col.b, 0.9))
	# trailing chevron segments
	for i in 4:
		var x := w * 0.58 + i * 16.0
		var seg := PackedVector2Array([Vector2(x, 0), Vector2(x + 9, 0), Vector2(x + 9 - h, h), Vector2(x - h, h)])
		draw_colored_polygon(seg, Color(col.r, col.g, col.b, 0.55 - i * 0.12))
	# thin data line + ticks
	draw_line(Vector2(w * 0.58 + 70, h * 0.5), Vector2(w, h * 0.5), Color(col.r, col.g, col.b, 0.35), 1.0)
	for i in 6:
		var tx := w * 0.58 + 80 + i * 14.0
		draw_line(Vector2(tx, 0), Vector2(tx, h), Color(col.r, col.g, col.b, 0.4), 1.0)
