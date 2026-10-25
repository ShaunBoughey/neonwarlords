class_name Portrait
extends Control
## Procedural warlord portrait: rim-lit bust in the syndicate colour. Headgear comes from the
## syndicate (mitre, crest, antenna, horns, kabuto, ram horns, tricorn), shoulders from the class
## and the visor varies per warlord, so every card reads as a distinct character.

var tpl_id := ""
var dim := false
var flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if size.x < 8 or size.y < 8:
		return
	if tpl_id == "":
		return
	var t: Dictionary = Warlords.get_t(tpl_id)
	var sc: Color = Data.SYNDICATES[t.syn].color
	var rc: Color = Data.RARITY_COLOR[t.rarity]
	var h := hash(tpl_id)
	var W := size.x
	var H := size.y
	# backdrop: syndicate glow fading to void, fine hatching
	var steps := 14
	for i in steps:
		var f := float(i) / steps
		draw_rect(Rect2(0, H * f, W, H / steps + 1), sc.darkened(0.45).lerp(Color("#06080F"), clampf(f * 1.25, 0, 1)))
	var x := -H
	while x < W:
		draw_line(Vector2(x, H), Vector2(x + H * 0.5, 0), Color(sc, 0.06), 1.0)
		x += max(5.0, W * 0.08)
	var cx := W * 0.5
	var hy := H * 0.42
	var hr := H * 0.17
	var body := Color("#151B2A")
	var rim := sc.lightened(0.35)
	var lw: float = max(1.5, W * 0.022)
	# shoulders by class
	var sh := _shoulders(String(t.cls), cx, W, H)
	draw_colored_polygon(sh, body)
	draw_polyline(_left_edge(sh), Color(rim, 0.9), lw, true)
	if t.cls == "armour":
		for sx in [-1.0, 1.0]:
			var pc := Vector2(cx + sx * W * 0.3, H * 0.74)
			draw_circle(pc, W * 0.13, Color("#1C2436"))
			draw_arc(pc, W * 0.13, PI * (1.05 if sx < 0 else 1.55), PI * (1.6 if sx < 0 else 2.0), 12, Color(rim, 0.8), lw, true)
	elif t.cls == "firepower":
		draw_line(Vector2(cx - W * 0.22, H * 0.7), Vector2(cx + W * 0.18, H), Color(sc, 0.7), lw * 1.4)
	elif t.cls == "modder":
		for k in 3:
			draw_circle(Vector2(cx + W * 0.24 + k * W * 0.05, H * 0.78 + k * H * 0.04), W * 0.018, Color(sc, 0.9))
	elif t.cls == "hacker":
		draw_colored_polygon(PackedVector2Array([Vector2(cx - hr * 1.5, hy + hr * 0.4), Vector2(cx, hy - hr * 1.55),
			Vector2(cx + hr * 1.5, hy + hr * 0.4), Vector2(cx + hr * 1.1, H * 0.72), Vector2(cx - hr * 1.1, H * 0.72)]), Color("#10151F"))
	# neck + head
	draw_rect(Rect2(cx - hr * 0.45, hy + hr * 0.6, hr * 0.9, H * 0.12), body)
	draw_circle(Vector2(cx, hy), hr, Color("#1A2133"))
	draw_arc(Vector2(cx, hy), hr, PI * 0.75, PI * 1.45, 16, Color(rim, 0.95), lw, true)
	_headgear(String(t.syn), cx, hy, hr, body, rim, lw)
	_visor(h, cx, hy, hr, sc)
	# class + syndicate marks, boss crown
	var isz := H * 0.2
	var ct := Art.tex(Art.CLASS_SYMBOL[t.cls])
	if ct:
		draw_texture_rect(ct, Rect2(3, H - isz - 3, isz, isz), false, Color(1, 1, 1, 0.85))
	var st := Art.tex(Art.SYN_SYMBOL[t.syn])
	if st:
		draw_texture_rect(st, Rect2(W - isz - 3, 3, isz, isz), false, Color(1, 1, 1, 0.85))
	if t.get("boss", false):
		Icon.paint(self, "crown", Vector2(3, 3), isz / 24.0, UI.GOLD, max(1.5, lw))
	draw_rect(Rect2(Vector2.ZERO, size), rc, false, max(2.0, W * 0.035))
	if dim:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, flash * 0.6))

func _shoulders(cls: String, cx: float, W: float, H: float) -> PackedVector2Array:
	var top := H * 0.66
	var wide: float = {"armour": 0.46, "firepower": 0.4, "modder": 0.38, "hacker": 0.34}.get(cls, 0.4)
	var p := PackedVector2Array([Vector2(cx - W * wide, H), Vector2(cx - W * (wide - 0.06), top + H * 0.06),
		Vector2(cx - W * 0.12, top), Vector2(cx + W * 0.12, top), Vector2(cx + W * (wide - 0.06), top + H * 0.06), Vector2(cx + W * wide, H)])
	if cls == "modder":
		p[4] = Vector2(cx + W * (wide + 0.02), top + H * 0.02)
	return p

func _left_edge(p: PackedVector2Array) -> PackedVector2Array:
	return PackedVector2Array([p[0], p[1], p[2]])

func _headgear(syn: String, cx: float, hy: float, hr: float, body: Color, rim: Color, lw: float) -> void:
	match syn:
		"trolls":   # mitre with cross
			var m := PackedVector2Array([Vector2(cx - hr * 0.8, hy - hr * 0.55), Vector2(cx - hr * 0.55, hy - hr * 2.1),
				Vector2(cx, hy - hr * 2.5), Vector2(cx + hr * 0.55, hy - hr * 2.1), Vector2(cx + hr * 0.8, hy - hr * 0.55)])
			draw_colored_polygon(m, Color("#7A1A22"))
			draw_polyline(PackedVector2Array([m[0], m[1], m[2]]), Color(rim, 0.9), lw, true)
			draw_line(Vector2(cx, hy - hr * 2.0), Vector2(cx, hy - hr * 1.0), Color("#FFD36A"), lw * 1.2)
			draw_line(Vector2(cx - hr * 0.3, hy - hr * 1.65), Vector2(cx + hr * 0.3, hy - hr * 1.65), Color("#FFD36A"), lw * 1.2)
		"vultures":   # swept-back crest spikes
			for k in 3:
				var bx := cx - hr * 0.4 + k * hr * 0.4
				draw_colored_polygon(PackedVector2Array([Vector2(bx - hr * 0.18, hy - hr * 0.8), Vector2(bx + hr * 0.5, hy - hr * (1.9 - k * 0.25)), Vector2(bx + hr * 0.2, hy - hr * 0.7)]), body)
			draw_line(Vector2(cx - hr * 0.5, hy - hr * 0.85), Vector2(cx + hr * 0.6, hy - hr * 1.9), Color(rim, 0.8), lw)
		"teratek":   # corporate helmet with antenna
			draw_arc(Vector2(cx, hy), hr * 1.1, PI * 1.05, PI * 1.95, 16, Color("#2A3448"), hr * 0.35, true)
			draw_line(Vector2(cx + hr * 0.6, hy - hr * 0.9), Vector2(cx + hr * 0.9, hy - hr * 1.9), Color(rim, 0.9), lw)
			draw_circle(Vector2(cx + hr * 0.9, hy - hr * 1.95), lw * 1.4, rim)
		"vikings":   # horns
			for sx in [-1.0, 1.0]:
				var horn := PackedVector2Array()
				for q in [[0.6, -0.55], [1.2, -0.85], [1.65, -1.3], [1.75, -1.95], [1.35, -1.35], [0.95, -1.05], [0.65, -0.85]]:
					horn.append(Vector2(cx + sx * hr * q[0], hy + hr * q[1]))
				draw_colored_polygon(horn, Color("#C9B98A"))
			draw_arc(Vector2(cx, hy), hr * 1.02, PI * 1.1, PI * 1.9, 16, Color("#3A4050"), hr * 0.3, true)
		"shogunate":   # kabuto with crescent crest
			draw_arc(Vector2(cx, hy), hr * 1.05, PI * 1.0, PI * 2.0, 16, Color("#2A1424"), hr * 0.4, true)
			draw_arc(Vector2(cx, hy - hr * 1.3), hr * 0.8, PI * 0.15, PI * 0.85, 16, Color(rim, 0.95), lw * 1.6, true)
		"spliced":   # curled ram horns
			for sx in [-1.0, 1.0]:
				draw_arc(Vector2(cx + sx * hr * 1.0, hy - hr * 0.3), hr * 0.55, 0, TAU * 0.8, 20, Color("#8A7A5A"), hr * 0.28, true)
		"traders":   # tricorn hat
			draw_colored_polygon(PackedVector2Array([Vector2(cx - hr * 1.6, hy - hr * 0.6), Vector2(cx, hy - hr * 1.9), Vector2(cx + hr * 1.6, hy - hr * 0.6), Vector2(cx, hy - hr * 0.9)]), Color("#1E1A14"))
			draw_line(Vector2(cx - hr * 1.6, hy - hr * 0.6), Vector2(cx, hy - hr * 1.9), Color(rim, 0.85), lw)

func _visor(h: int, cx: float, hy: float, hr: float, sc: Color) -> void:
	var glow := sc.lightened(0.45)
	match abs(h) % 4:
		0:   # slit visor
			draw_rect(Rect2(cx - hr * 0.75, hy - hr * 0.12, hr * 1.5, hr * 0.28), Color(glow, 0.35))
			draw_rect(Rect2(cx - hr * 0.7, hy - hr * 0.06, hr * 1.4, hr * 0.14), glow)
		1:   # goggles
			for sx in [-1.0, 1.0]:
				draw_circle(Vector2(cx + sx * hr * 0.38, hy), hr * 0.26, Color(glow, 0.3))
				draw_circle(Vector2(cx + sx * hr * 0.38, hy), hr * 0.16, glow)
		2:   # cyclops eye
			draw_circle(Vector2(cx, hy), hr * 0.32, Color(glow, 0.3))
			draw_circle(Vector2(cx, hy), hr * 0.18, glow)
		3:   # mask with eye slits
			draw_rect(Rect2(cx - hr * 0.6, hy + hr * 0.15, hr * 1.2, hr * 0.55), Color("#0C1018"))
			for sx in [-1.0, 1.0]:
				draw_line(Vector2(cx + sx * hr * 0.15, hy - hr * 0.05), Vector2(cx + sx * hr * 0.6, hy - hr * 0.15), glow, max(2.0, hr * 0.14))
