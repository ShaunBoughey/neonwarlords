class_name DistrictMap
extends Control
## Isometric neon district for a campaign den: blocks, a street route through 7 landmarks,
## lamps lit up to the player's progress, and the den boss tower. Seeded per den.

signal stage_pressed(index: int)

const DESIGN := Vector2(860, 560)
const N := 13
const ROUTES := [
	[Vector2(2, 11), Vector2(3, 8), Vector2(5.5, 9), Vector2(6.5, 6), Vector2(8.5, 7), Vector2(9.5, 4), Vector2(11.5, 3)],
	[Vector2(1.5, 9), Vector2(4, 10.5), Vector2(5, 7.5), Vector2(7.5, 8.5), Vector2(8, 5.5), Vector2(10.5, 6), Vector2(11, 2.5)],
	[Vector2(2.5, 10), Vector2(2.5, 7), Vector2(5, 6.5), Vector2(6, 9), Vector2(8.5, 8.5), Vector2(9, 5), Vector2(11.5, 3.5)],
]
const NAMES := ["Noodle Row", "Chop Alley", "Scrapyard", "Rail Bridge", "Black Clinic", "Rooftops", "Den Boss"]
## Landmark names per den (stages 1-6; stage 7 shows the den boss).
const DEN_NAMES := [
	["Noodle Row", "Chop Alley", "Scrapyard", "Rail Bridge", "Black Clinic", "Rooftops"],
	["Outflow Gate", "Rat Tunnels", "Pump Station", "Sluice Lock", "Drowned Market", "Cistern"],
	["Dry Dock", "Container Maze", "Crane Yard", "Customs Shed", "Rust Pier", "Smugglers' Berth"],
	["Foundry Gate", "Conveyor Line", "Slag Pits", "Smelter", "Cooling Towers", "Freight Depot"],
	["Loading Bay", "Vat Hall", "Pipe Gallery", "Spill Zone", "Gene Lab", "Reactor Ring"],
	["Food Court", "Neon Arcade", "Atrium", "Parking Deck", "Cinema", "Skybridge"],
	["Mag-Lev Stop", "Hanging Gardens", "Sky Bazaar", "Cable Walk", "Penthouse Row", "Pagoda Deck"],
	["Lobby Block", "Stairwell 9", "Laundry Floor", "Hab Corridor", "Roof Antenna", "Water Tower"],
	["Plaza Fountain", "Holo Avenue", "Bank Vault", "Club Strip", "Data Exchange", "Metro Hub"],
	["Lobby", "Security Gate", "Server Floor", "R&D Wing", "Executive Lift", "Boardroom"],
]

static func stage_name(p_den: int, i: int) -> String:
	if i >= 6:
		return "Den Boss"
	return DEN_NAMES[clampi(p_den, 0, DEN_NAMES.size() - 1)][i]

## Nudge already-placed labels so none overlaps a pin or an earlier label.
## Tries below (as placed), further below, above the pin, then left / right.
static func declutter(labels: Array, pins: Array) -> void:
	var taken: Array = []
	for p in pins:
		if is_instance_valid(p):
			taken.append(Rect2(p.position, p.size).grow(2))
	for l in labels:
		if not is_instance_valid(l):
			continue
		var base: Vector2 = l.position
		var h: float = l.size.y
		var w: float = l.size.x
		var tries: Array = []
		for dy in [0.0, h + 4, 2 * h + 8, -2 * h - 52, 3 * h + 12, -3 * h - 56]:
			for dx in [0.0, -w / 2 - 12, w / 2 + 12, -w * 0.3, w * 0.3]:
				tries.append(Vector2(dx, dy))
		var pick: Vector2 = base
		var best := INF
		for t in tries:
			var r := Rect2(base + t, l.size)
			var overlap := 0.0
			for o in taken:
				overlap += r.intersection(o).get_area()
			# small bias towards staying close to the pin
			var score: float = overlap + t.length() * 0.05
			if score < best:
				best = score
				pick = base + t
		l.position = pick
		taken.append(Rect2(pick, l.size).grow(2))

var den := 0
var accent := Color("#FF3DB4")
var boss_name := "Boss Lair"
var states: Array = []          # per stage: "done" | "open" | "sel" | "lock"
var stars: Array = []
var _polys: Array = []          # [PackedVector2Array, Color]
var _lines: Array = []          # [from, to, Color, width]
var _route: Array = []
var _beacon := Vector2.ZERO
var _t := 0.0
var _pins: Array = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	resized.connect(_layout)

func setup(p_den: int, p_states: Array, p_stars: Array, p_accent: Color, p_boss: String) -> void:
	den = p_den
	states = p_states
	stars = p_stars
	accent = p_accent
	boss_name = p_boss
	_gen()
	_make_pins()
	_layout()

func _P(gx: float, gy: float, z := 0.0) -> Vector2:
	return Vector2(430 + (gx - gy) * 32.0, 120 + (gx + gy) * 16.0 - z)

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	var t: float = clampf((p - a).dot(d) / d.length_squared(), 0.0, 1.0)
	return p.distance_to(a + d * t)

func _gen() -> void:
	_polys.clear()
	_lines.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 7 + den * 131
	_route = ROUTES[den % ROUTES.size()]
	var neon := [UI.CYAN, accent, UI.GOLD, UI.PURPLE]
	_polys.append([PackedVector2Array([_P(0, 0), _P(N, 0), _P(N, N), _P(0, N)]), Color("#0A0F1A")])
	for i in N + 1:
		_lines.append([_P(i, 0), _P(i, N), Color("#16243A"), 1.0])
		_lines.append([_P(0, i), _P(N, i), Color("#16243A"), 1.0])
	var blds: Array = []
	for gx in N:
		for gy in N:
			if r.randf() < 0.45:
				continue
			var c := Vector2(gx + 0.5, gy + 0.5)
			var dist := 99.0
			var near: Vector2 = _route[0]
			for i in _route.size() - 1:
				dist = min(dist, _seg_dist(c, _route[i], _route[i + 1]))
			for q in _route:
				if c.distance_to(q) < c.distance_to(near):
					near = q
			if dist < 1.5 or c.distance_to(Vector2(_route[6].x + 0.25, _route[6].y - 1.75)) < 1.6:
				continue
			var h: float = [40, 60, 80, 110, 140, 170][r.randi_range(0, 5)]
			if c.x + c.y > near.x + near.y:
				h = [14, 18, 24][r.randi_range(0, 2)] if dist < 4 else [20, 30][r.randi_range(0, 1)]
			blds.append([gx + 0.1, gy + 0.1, 0.8, 0.8, h, false])
	var last: Vector2 = _route[6]
	blds.append([last.x - 0.4, last.y - 2.4, 1.3, 1.3, 210.0, true])
	blds.sort_custom(func(a, b): return a[0] + a[1] + a[2] + a[3] < b[0] + b[1] + b[2] + b[3])
	for bd in blds:
		var gx: float = bd[0]
		var gy: float = bd[1]
		var w: float = bd[2]
		var d: float = bd[3]
		var h: float = bd[4]
		var boss: bool = bd[5]
		_polys.append([PackedVector2Array([_P(gx, gy + d), _P(gx + w, gy + d), _P(gx + w, gy + d, h), _P(gx, gy + d, h)]), Color("#2A0E18") if boss else Color("#111827")])
		_polys.append([PackedVector2Array([_P(gx + w, gy), _P(gx + w, gy + d), _P(gx + w, gy + d, h), _P(gx + w, gy, h)]), Color("#1A0810") if boss else Color("#0B1019")])
		_polys.append([PackedVector2Array([_P(gx, gy, h), _P(gx + w, gy, h), _P(gx + w, gy + d, h), _P(gx, gy + d, h)]), Color("#3A1422") if boss else Color("#1C2638")])
		var col: Color = UI.RED if boss else neon[r.randi_range(0, 3)]
		var z := 10.0
		while z < h - 6:
			var t := 0.08
			while t < w - 0.15:
				if r.randf() < 0.35:
					var wc: Color = col if r.randf() < 0.4 else Color("#FFE7A8")
					_lines.append([_P(gx + t, gy + d, z), _P(gx + t + 0.12, gy + d, z), Color(wc, r.randf_range(0.3, 0.85)), 3.0])
				if r.randf() < 0.25:
					_lines.append([_P(gx + w, gy + t, z), _P(gx + w, gy + t + 0.12, z), Color(col, r.randf_range(0.2, 0.6)), 3.0])
				t += 0.2
			z += 12.0
		if boss or r.randf() < 0.35:
			_lines.append([_P(gx, gy + d, h), _P(gx + w, gy + d, h), col, 2.0])
			_lines.append([_P(gx + w, gy + d, h), _P(gx + w, gy, h), col, 2.0])
		if boss:
			_beacon = _P(gx + w / 2, gy + d / 2, h)

func _cleared_upto() -> int:
	var n := 0
	for i in states.size():
		if states[i] == "done":
			n = i + 1
	return n

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _xf() -> Array:
	var sc: float = min(size.x / DESIGN.x, size.y / DESIGN.y)
	var off := (size - DESIGN * sc) / 2.0
	return [off, sc]

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	var xf := _xf()
	draw_set_transform(xf[0], 0, Vector2(xf[1], xf[1]))
	# ground first, then the street, then blocks (painter's order already sorted)
	draw_colored_polygon(_polys[0][0], _polys[0][1])
	for i in 2 * (N + 1):
		var l: Array = _lines[i]
		draw_line(l[0], l[1], l[2], l[3])
	var rp := PackedVector2Array()
	for q in _route:
		rp.append(_P(q.x, q.y))
	draw_polyline(rp, Color("#141B28"), 30.0, true)
	var lit := clampi(_cleared_upto() + 1, 1, 7)
	var cp := PackedVector2Array()
	for i in lit:
		cp.append(rp[i])
	if cp.size() > 1:
		draw_polyline(cp, Color(UI.CYAN, 0.18), 12.0, true)
		draw_polyline(cp, UI.CYAN, 3.0, true)
	for i in rp.size() - 1:
		for k in range(1, 4):
			var p: Vector2 = rp[i].lerp(rp[i + 1], k / 4.0)
			var c: Color = UI.CYAN if i < lit - 1 else Color("#FFB45A")
			draw_circle(p, 9, Color(c, 0.14))
			draw_circle(p, 2, c)
	for i in range(1, _polys.size()):
		draw_colored_polygon(_polys[i][0], _polys[i][1])
	for i in range(2 * (N + 1), _lines.size()):
		var l: Array = _lines[i]
		draw_line(l[0], l[1], l[2], l[3])
	if _beacon != Vector2.ZERO:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		draw_line(_beacon, _beacon - Vector2(0, 40), UI.RED, 3.0)
		draw_circle(_beacon - Vector2(0, 44), 22 + pulse * 6, Color(UI.RED, 0.18))
		draw_circle(_beacon - Vector2(0, 44), 6, UI.RED)
	# ground rings + beams under the pins
	for i in rp.size():
		var st: String = states[i] if i < states.size() else "lock"
		var c := _state_col(st, i)
		var big := st == "sel" or i == 6
		var rad := 30.0 if big else 24.0
		draw_set_transform(xf[0] + rp[i] * xf[1], 0, Vector2(xf[1], xf[1] * 0.5))
		draw_arc(Vector2.ZERO, rad, 0, TAU, 32, c, 2.0, true)
		if st == "sel":
			draw_circle(Vector2.ZERO, rad + 12 + sin(_t * 4.0) * 3.0, Color(c, 0.22))
		draw_set_transform(xf[0], 0, Vector2(xf[1], xf[1]))
		var lift := 64.0 if big else 50.0
		draw_line(rp[i], rp[i] - Vector2(0, lift - (24 if big else 18)), Color(c, 0.8), 2.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _state_col(st: String, i: int) -> Color:
	if i == 6 and st != "lock":
		return UI.RED
	match st:
		"done": return UI.CYAN
		"sel": return UI.GOLD
		"open": return UI.CYAN
	return Color("#4A5A70")

func _make_pins() -> void:
	for p in _pins:
		p.queue_free()
	_pins.clear()
	for i in 7:
		var st: String = states[i] if i < states.size() else "lock"
		var pin := HexButton.new()
		var big := st == "sel" or i == 6
		pin.custom_minimum_size = Vector2(54, 48) if big else Vector2(48, 44)
		pin.size = pin.custom_minimum_size
		pin.set_meta("big", big)
		pin.fill = UI.BG
		pin.fill2 = UI.BG
		pin.border = _state_col(st, i)
		pin.selected = st == "sel"
		pin.glyph_size = 20 if big else 15
		pin.glyph = "" if st == "lock" else ("B" if i == 6 else str(i + 1))
		pin.disabled = st == "lock"
		var idx := i
		pin.pressed.connect(func(): stage_pressed.emit(idx))
		add_child(pin)
		if st == "lock":
			var lk := Icon.make("lock", Color("#7F93AA"), 14)
			lk.position = pin.size / 2 - Vector2(7, 7)
			pin.add_child(lk)
		var lab := UI.cap(boss_name if i == 6 else stage_name(den, i), UI.TEXT if st != "lock" else Color("#8FA3B8"))
		if i == 6:
			lab.add_theme_color_override("font_color", Color("#FF8AA0") if st != "lock" else Color("#8FA3B8"))
		lab.add_theme_stylebox_override("normal", UI._sb(Color(UI.BG, 0.78), Color(0, 0, 0, 0), 0, 0, 5))
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lab)
		var chev: Control = null
		if st == "done" or (st == "sel" and i < stars.size() and int(stars[i]) > 0):
			chev = UI.chevrons(int(stars[i]) if i < stars.size() else 0, 13)
			chev.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(chev)
		_pins.append(pin)
		_pins.append(lab)
		if chev:
			_pins.append(chev)
		pin.set_meta("i", i)
		lab.set_meta("lab", i)
		if chev:
			chev.set_meta("chev", i)

func _layout() -> void:
	if _route.is_empty():
		return
	var xf := _xf()
	for n in _pins:
		if not is_instance_valid(n):
			continue
		if n.has_meta("i"):
			var i: int = n.get_meta("i")
			var big: bool = n.get_meta("big", false)
			var g: Vector2 = xf[0] + _P(_route[i].x, _route[i].y) * xf[1]
			n.position = g - Vector2(0, (64.0 if big else 50.0) * xf[1]) - n.size / 2
		elif n.has_meta("lab"):
			var i: int = n.get_meta("lab")
			var g: Vector2 = xf[0] + _P(_route[i].x, _route[i].y) * xf[1]
			n.reset_size()
			n.position = g + Vector2(-n.size.x / 2, 16 * xf[1])
		elif n.has_meta("chev"):
			var i: int = n.get_meta("chev")
			var g: Vector2 = xf[0] + _P(_route[i].x, _route[i].y) * xf[1]
			n.reset_size()
			n.position = g - Vector2(n.size.x / 2, 50.0 * xf[1] + 36)
	declutter(_pins.filter(func(n): return is_instance_valid(n) and n.has_meta("lab")), _pins.filter(func(n): return is_instance_valid(n) and n.has_meta("i")))
