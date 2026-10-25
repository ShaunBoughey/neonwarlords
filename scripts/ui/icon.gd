class_name Icon
extends Control
## Stroke line icons drawn on a 24x24 grid (replaces emoji glyphs across the UI).

var icon := "home"
var col := Color("#34E0FF")
var width := 2.0

static func make(name: String, color: Color, px := 24) -> Icon:
	var i := Icon.new()
	i.icon = name
	i.col = color
	i.custom_minimum_size = Vector2(px, px)
	i.size = Vector2(px, px)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var s: float = min(size.x, size.y) / 24.0
	var o := (size - Vector2(24, 24) * s) / 2.0
	Icon.paint(self, icon, o, s, col, width * max(1.0, s * 0.9))

static func paint(ci: CanvasItem, name: String, o: Vector2, s: float, c: Color, w: float) -> void:
	var P := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var line := func(pts: Array) -> void:
		var arr := PackedVector2Array()
		for p in pts:
			arr.append(P.call(p[0], p[1]))
		ci.draw_polyline(arr, c, w, true)
	var circ := func(x: float, y: float, r: float) -> void:
		ci.draw_arc(P.call(x, y), r * s, 0, TAU, 32, c, w, true)
	var arc := func(x: float, y: float, r: float, a0: float, a1: float) -> void:
		ci.draw_arc(P.call(x, y), r * s, a0, a1, 24, c, w, true)
	match name:
		"home": line.call([[3, 11], [12, 3], [21, 11], [21, 21], [15, 21], [15, 15], [9, 15], [9, 21], [3, 21], [3, 11]])
		"users":
			circ.call(9, 8, 4)
			arc.call(9, 21, 7, PI, TAU)
			arc.call(16, 8, 4, -PI / 2, PI / 2)
			arc.call(17, 21, 5, PI * 1.35, TAU)
		"swords":
			line.call([[3, 3], [17, 17]])
			line.call([[21, 3], [7, 17]])
			line.call([[13, 19], [19, 13]])
			line.call([[5, 13], [11, 19]])
			line.call([[17, 17], [21, 21]])
			line.call([[7, 17], [3, 21]])
		"case":
			line.call([[3, 8], [21, 8], [21, 20], [3, 20], [3, 8]])
			line.call([[9, 8], [9, 5], [15, 5], [15, 8]])
			line.call([[3, 13], [21, 13]])
		"tag":
			line.call([[3, 12], [3, 4], [11, 4], [21, 14], [13, 22], [3, 12]])
			circ.call(7.5, 7.5, 1.5)
		"cart":
			line.call([[3, 4], [5, 4], [7.5, 15], [18.5, 15], [21, 7], [6.5, 7]])
			circ.call(9, 19, 1.2)
			circ.call(18, 19, 1.2)
		"shield": line.call([[12, 3], [20, 6], [20, 12], [17, 18], [12, 21], [7, 18], [4, 12], [4, 6], [12, 3]])
		"bolt": line.call([[13, 2], [4, 14], [11, 14], [10, 22], [19, 10], [12, 10], [13, 2]])
		"coin":
			circ.call(12, 12, 9)
			arc.call(12, 12, 4.5, PI * 0.25, PI * 1.75)
		"diamond":
			line.call([[6, 3], [18, 3], [22, 9], [12, 21], [2, 9], [6, 3]])
			line.call([[2, 9], [22, 9]])
		"pitcoin":
			circ.call(12, 12, 9)
			line.call([[8, 16], [8, 8], [13, 8], [15, 10], [13, 12], [8, 12]])
		"plus":
			line.call([[12, 5], [12, 19]])
			line.call([[5, 12], [19, 12]])
		"left": line.call([[15, 6], [9, 12], [15, 18]])
		"right": line.call([[9, 6], [15, 12], [9, 18]])
		"up": line.call([[6, 14], [12, 8], [18, 14]])
		"lock":
			line.call([[5, 11], [19, 11], [19, 21], [5, 21], [5, 11]])
			line.call([[8, 11], [8, 7]])
			line.call([[16, 11], [16, 7]])
			arc.call(12, 7, 4, PI, TAU)
		"gift":
			line.call([[3, 9], [21, 9], [21, 21], [3, 21], [3, 9]])
			line.call([[3, 13], [21, 13]])
			line.call([[12, 9], [12, 21]])
			arc.call(9, 7, 3, PI * 0.2, PI * 1.6)
			arc.call(15, 7, 3, PI * 1.4, PI * 2.8)
		"list":
			for y in [6, 12, 18]:
				line.call([[4, y], [6, y]])
				line.call([[9, y], [20, y]])
		"ticket":
			line.call([[3, 6], [21, 6], [21, 18], [3, 18], [3, 6]])
			for y in [8, 11, 14, 17]:
				line.call([[15, y], [15, y + 1.2]])
		"mail":
			line.call([[3, 5], [21, 5], [21, 19], [3, 19], [3, 5]])
			line.call([[3, 6], [12, 13], [21, 6]])
		"clock":
			circ.call(12, 12, 9)
			line.call([[12, 7], [12, 12], [15, 14]])
		"star": line.call([[12, 3], [14.8, 8.7], [21, 9.6], [16.5, 14], [17.5, 20.2], [12, 17.3], [6.5, 20.2], [7.5, 14], [3, 9.6], [9.2, 8.7], [12, 3]])
		"check": line.call([[5, 12], [10, 17], [19, 7]])
		"gear":
			circ.call(12, 12, 3.5)
			for k in 8:
				var a := k * PI / 4
				line.call([[12 + cos(a) * 6.5, 12 + sin(a) * 6.5], [12 + cos(a) * 9.5, 12 + sin(a) * 9.5]])
			circ.call(12, 12, 6.5)
		"skull":
			arc.call(12, 10, 7, PI, TAU)
			line.call([[5, 10], [5, 15], [8, 17], [8, 20], [16, 20], [16, 17], [19, 15], [19, 10]])
			circ.call(9, 12, 1.5)
			circ.call(15, 12, 1.5)
		"crown": line.call([[3, 18], [3, 7], [8, 12], [12, 5], [16, 12], [21, 7], [21, 18], [3, 18]])
		"settings":
			for y in [6, 12, 18]:
				line.call([[4, y], [20, y]])
			circ.call(9, 6, 2)
			circ.call(15, 12, 2)
			circ.call(8, 18, 2)
		"bag":
			line.call([[5, 8], [19, 8], [20, 21], [4, 21], [5, 8]])
			arc.call(12, 8, 4, PI, TAU)
		"house":
			line.call([[4, 21], [4, 10], [12, 4], [20, 10], [20, 21], [4, 21]])
			line.call([[10, 21], [10, 15], [14, 15], [14, 21]])
		"chart": line.call([[4, 20], [4, 4], [4, 20], [20, 20], [8, 14], [12, 16], [19, 8]])
		_: circ.call(12, 12, 8)
