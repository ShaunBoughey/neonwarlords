class_name Silhouette
extends Control
## Rim-lit character silhouette used as key-art placeholder until real portrait renders exist.

var rim := Color("#34E0FF")
var flip := false

const BODY := [Vector2(58, 98), Vector2(100, 89), Vector2(142, 98), Vector2(164, 114), Vector2(174, 131), Vector2(186, 213),
	Vector2(177, 225), Vector2(169, 226), Vector2(158, 218), Vector2(148, 152), Vector2(142, 156), Vector2(142, 242),
	Vector2(154, 392), Vector2(144, 402), Vector2(124, 402), Vector2(114, 393), Vector2(104, 265), Vector2(96, 265),
	Vector2(86, 393), Vector2(76, 402), Vector2(56, 402), Vector2(46, 392), Vector2(58, 242), Vector2(58, 156),
	Vector2(52, 152), Vector2(42, 218), Vector2(31, 226), Vector2(23, 225), Vector2(14, 213), Vector2(26, 131), Vector2(36, 114)]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var sc: float = min(size.x / 200.0, size.y / 420.0)
	var off := Vector2((size.x - 200 * sc) / 2.0, size.y - 410 * sc)
	var fy := off.y + 402 * sc
	draw_set_transform(Vector2(size.x / 2.0, fy), 0, Vector2(1, 0.3))
	for i in 6:
		draw_circle(Vector2.ZERO, (90 - i * 12) * sc, Color(rim.r, rim.g, rim.b, 0.05 + 0.03 * i))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var dark := Color("#0A0D18")
	var mid := Color("#1A2033")
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for p in BODY:
		var q: Vector2 = Vector2(200 - p.x, p.y) if flip else p
		pts.append(off + q * sc)
		var t: float = clampf((q.x / 200.0) * 0.6 + (q.y / 420.0) * 0.8, 0.0, 1.0)
		cols.append(rim.lerp(mid, clampf(t * 2.2, 0, 1)).lerp(dark, clampf(t * 1.4 - 0.4, 0, 1)))
	draw_polygon(pts, cols)
	var head := off + Vector2(100, 53) * sc
	draw_circle(head, 34 * sc, mid)
	var a0 := -PI * 0.25 if flip else -PI * 0.75
	draw_arc(head, 33 * sc, a0 - PI * 0.35, a0 + PI * 0.35, 24, Color(rim.r, rim.g, rim.b, 0.85), 3.0 * sc, true)
