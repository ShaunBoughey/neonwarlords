class_name PawnShop
extends Control
## Back-alley pawn shop backdrop for Recruitment: shelves of junk, a broker behind a barred
## service window, a flickering PAWN sign and the counter the contract cases slide across.

var _t := 0.0
var counter_y := 330.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var w := size.x
	var cx := w / 2.0
	draw_rect(Rect2(0, 0, w, size.y), Color("#07060C"))
	_vgrad(Rect2(0, 0, w, counter_y + 20), Color("#120E1C"), Color("#0B0812"))
	# back room seen through the window
	var win := Rect2(cx - 320, 10, 640, counter_y - 40)
	draw_rect(win, Color("#0E0B16"))
	for sy in [win.position.y + 90, win.position.y + 190]:
		draw_rect(Rect2(win.position.x + 20, sy, win.size.x - 40, 6), Color("#2A2236"))
	var junk := [[42, 44, 40, 46, "#1A2A3A", UI.CYAN], [100, 58, 70, 32, "#2A1A30", Color(0, 0, 0, 0)], [190, 36, 26, 54, "#3A2A12", UI.GOLD],
		[460, 50, 90, 40, "#16202A", Color(0, 0, 0, 0)], [60, 146, 60, 44, "#221828", Color(0, 0, 0, 0)], [370, 136, 44, 54, "#102030", UI.PURPLE], [530, 154, 50, 36, "#2A1414", Color(0, 0, 0, 0)]]
	for j in junk:
		var r := Rect2(win.position.x + j[0], win.position.y + j[1], j[2], j[3])
		if j[5].a > 0:
			draw_rect(r.grow(6), Color(j[5], 0.12))
		draw_rect(r, Color(j[4]))
	draw_rect(Rect2(win.position.x + 490, win.position.y + 60, 30, 8), UI.GREEN)
	# broker silhouette
	var bx := cx
	var by := win.position.y + 120
	draw_circle(Vector2(bx, by), 40, Color("#1E1630"))
	draw_colored_polygon(PackedVector2Array([Vector2(bx - 110, counter_y - 30), Vector2(bx - 70, by + 70), Vector2(bx + 70, by + 70), Vector2(bx + 110, counter_y - 30)]), Color("#16111F"))
	draw_rect(Rect2(bx - 26, by - 6, 52, 10), Color(UI.MAGENTA, 0.85 + 0.15 * sin(_t * 5.0)))
	# window frame and bars
	draw_rect(win.grow(10), Color("#1C1824"), false, 10.0)
	var x := win.position.x + 46
	while x < win.end.x:
		draw_rect(Rect2(x, win.position.y, 6, win.size.y), Color("#1C1824"))
		x += 52.0
	draw_rect(Rect2(win.position.x, win.end.y - 30, win.size.x, 30), Color("#05040A"))
	# counter
	var top := counter_y
	var poly := PackedVector2Array([Vector2(w * 0.06, top), Vector2(w * 0.94, top), Vector2(w + 40, size.y), Vector2(-40, size.y)])
	var cols := PackedColorArray([Color("#2B2531"), Color("#2B2531"), Color("#0C0A10"), Color("#0C0A10")])
	draw_polygon(poly, cols)
	draw_line(Vector2(w * 0.06, top), Vector2(w * 0.94, top), Color("#4A4256"), 3.0)
	var sx := -size.y
	while sx < w:
		draw_line(Vector2(sx, size.y), Vector2(sx + (size.y - top) * 0.2, top), Color(1, 1, 1, 0.015), 3.0)
		sx += 9.0

func _vgrad(r: Rect2, c0: Color, c1: Color) -> void:
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([c0, c0, c1, c1]))
