class_name DistrictDiorama
extends Control
## 3D campaign den: a neon district diorama (procedural blocks with lit windows, roof trims, a wet
## street lit up to the player's progress, the den boss tower with a beacon, rain and fog).
## Same interface as DistrictMap: setup(...) and the stage_pressed signal. Drag to swing the camera.

signal stage_pressed(index: int)

const N := 13
const NAMES := DistrictMap.NAMES
const WINDOW_SHADER := """
shader_type spatial;
uniform vec3 neon : source_color = vec3(0.2, 0.9, 1.0);
uniform float seed = 0.0;
uniform float boss = 0.0;
varying vec3 wpos;
varying vec3 wnorm;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 body = mix(vec3(0.06, 0.08, 0.13), vec3(0.16, 0.04, 0.07), boss);
	ALBEDO = body;
	ROUGHNESS = 0.55;
	METALLIC = 0.25;
	if (wnorm.y > 0.5) {
		ALBEDO = body * 1.6;
	} else {
		float u = abs(wnorm.x) > 0.5 ? wpos.z : wpos.x;
		vec2 cell = vec2(floor(u * 6.0), floor(wpos.y * 4.0));
		vec2 f = vec2(fract(u * 6.0), fract(wpos.y * 4.0));
		float win = step(0.22, f.x) * step(f.x, 0.78) * step(0.3, f.y) * step(f.y, 0.68);
		float lit = step(0.6, h(cell + seed));
		vec3 wc = mix(vec3(1.0, 0.88, 0.6), neon, step(0.55, h(cell * 1.7 + seed)));
		EMISSION = wc * win * lit * 2.4 * step(0.2, wpos.y);
	}
}
"""
const GROUND_SHADER := """
shader_type spatial;
void fragment() {
	vec2 g = abs(fract(UV * 13.0) - 0.5);
	float line = 1.0 - smoothstep(0.47, 0.5, max(g.x, g.y));
	ALBEDO = vec3(0.025, 0.035, 0.06);
	ROUGHNESS = 0.12;
	METALLIC = 0.6;
	EMISSION = vec3(0.05, 0.12, 0.22) * (1.0 - line) * 0.8;
}
"""

var den := 0
var accent := Color("#FF3DB4")
var boss_name := "Boss Lair"
var states: Array = []
var stars: Array = []
var vpc: View3D
var vp: SubViewport
var world: Node3D
var cam: Camera3D
var overlay: Control
var route: Array = []
var _pins: Array = []       # [node, kind, index]
var _beacon: OmniLight3D
var _beacon_mesh: MeshInstance3D
var _yaw := 0.0
var _yaw_target := 0.0
var _drag := false
var _t := 0.0
var _win_shader: Shader
var _center := Vector3(6.6, 0, 5.8)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	vpc = View3D.new()
	vpc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vpc)
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_2X
	vpc.add_child(vp)
	vpc.vp = vp
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

func setup(p_den: int, p_states: Array, p_stars: Array, p_accent: Color, p_boss: String) -> void:
	den = p_den
	states = p_states
	stars = p_stars
	accent = p_accent
	boss_name = p_boss
	route = DistrictMap.ROUTES[den % DistrictMap.ROUTES.size()]
	if world != null:
		world.queue_free()
	world = Node3D.new()
	vp.add_child(world)
	_build()
	_make_pins()

# ---------------------------------------------------------------- world
func _build() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#05040d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#2a2f55")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.1
	env.glow_bloom = 0.2
	env.glow_hdr_threshold = 0.85
	env.fog_enabled = true
	env.fog_light_color = Color("#05040d").lerp(accent, 0.08)
	env.fog_density = 0.028
	# SSR exists only on the Forward+ renderer (the project ships on Mobile, where it just warns)
	env.ssr_enabled = ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus"
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var moon := DirectionalLight3D.new()
	moon.rotation_degrees = Vector3(-50, -40, 0)
	moon.light_color = Color("#8fa6ff")
	moon.light_energy = 0.25
	moon.shadow_enabled = true
	world.add_child(moon)
	_win_shader = Shader.new()
	_win_shader.code = WINDOW_SHADER
	# ground
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(N, N)
	g.mesh = pm
	var gs := Shader.new()
	gs.code = GROUND_SHADER
	var gm := ShaderMaterial.new()
	gm.shader = gs
	g.material_override = gm
	g.position = Vector3(N / 2.0, 0, N / 2.0)
	world.add_child(g)
	_street()
	_blocks()
	_rain()
	cam = Camera3D.new()
	cam.fov = 37
	world.add_child(cam)
	_place_camera()

func _emissive(col: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = e
	return m

func _box(pos: Vector3, size: Vector3, mat: Material, rot := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	m.rotation.y = rot
	world.add_child(m)
	return m

func _cleared() -> int:
	var n := 0
	for i in states.size():
		if states[i] == "done":
			n = i + 1
	return n

func _street() -> void:
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color("#0B0F18")
	asphalt.roughness = 0.08
	asphalt.metallic = 0.5
	var lit := clampi(_cleared() + 1, 1, 7)
	for i in route.size() - 1:
		var a := Vector3(route[i].x, 0, route[i].y)
		var b := Vector3(route[i + 1].x, 0, route[i + 1].y)
		var mid := (a + b) / 2.0
		var length := a.distance_to(b)
		var ang := atan2(b.x - a.x, b.z - a.z)
		_box(mid + Vector3(0, 0.01, 0), Vector3(0.9, 0.02, length + 0.9), asphalt, ang)
		var on := i < lit - 1
		var c: Color = UI.CYAN if on else Color("#FFB45A")
		if on:
			_box(mid + Vector3(0, 0.03, 0), Vector3(0.07, 0.02, length), _emissive(UI.CYAN, 4.0), ang)
		for k in range(1, 4):
			var p := a.lerp(b, k / 4.0)
			var side := Vector3(cos(ang), 0, -sin(ang)) * 0.55
			_box(p + side + Vector3(0, 0.25, 0), Vector3(0.04, 0.5, 0.04), _emissive(Color("#1A2030"), 0.0))
			var bulb := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.06
			sm.height = 0.12
			bulb.mesh = sm
			bulb.material_override = _emissive(c, 6.0)
			bulb.position = p + side + Vector3(0, 0.52, 0)
			world.add_child(bulb)
		if i % 2 == 0:
			var l := OmniLight3D.new()
			l.light_color = c
			l.light_energy = 1.4
			l.omni_range = 3.0
			l.position = mid + Vector3(0, 0.8, 0)
			world.add_child(l)

func _blocks() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7 + den * 131
	var neon := [UI.CYAN, accent, UI.GOLD, UI.PURPLE]
	var tower := Vector2(route[6].x + 0.25, route[6].y - 1.75)
	for gx in N:
		for gy in N:
			if r.randf() < 0.45:
				continue
			var c := Vector2(gx + 0.5, gy + 0.5)
			var dist := 99.0
			var near: Vector2 = route[0]
			for i in route.size() - 1:
				dist = min(dist, _seg_dist(c, route[i], route[i + 1]))
			for q in route:
				if c.distance_to(q) < c.distance_to(near):
					near = q
			if dist < 1.5 or c.distance_to(tower) < 1.6:
				continue
			var h: float = [1.4, 2.1, 2.8, 3.8, 4.8, 5.8][r.randi_range(0, 5)]
			if c.x + c.y > near.x + near.y:
				h = [0.5, 0.65, 0.85][r.randi_range(0, 2)] if dist < 4 else [0.7, 1.0][r.randi_range(0, 1)]
			var col: Color = neon[r.randi_range(0, 3)]
			_building(Vector3(c.x, 0, c.y), Vector2(0.8, 0.8), h, col, r.randf() * 50.0, false, r.randf() < 0.4)
	_building(Vector3(tower.x, 0, tower.y), Vector2(1.3, 1.3), 7.2, UI.RED, 3.0, true, true)
	var top := Vector3(tower.x, 7.2, tower.y)
	_box(top + Vector3(0, 0.7, 0), Vector3(0.06, 1.4, 0.06), _emissive(UI.RED, 3.0))
	_beacon_mesh = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	_beacon_mesh.mesh = sm
	_beacon_mesh.material_override = _emissive(UI.RED, 8.0)
	_beacon_mesh.position = top + Vector3(0, 1.5, 0)
	world.add_child(_beacon_mesh)
	_beacon = OmniLight3D.new()
	_beacon.light_color = UI.RED
	_beacon.light_energy = 3.0
	_beacon.omni_range = 6.0
	_beacon.position = top + Vector3(0, 1.2, 0)
	world.add_child(_beacon)

func _building(base: Vector3, fp: Vector2, h: float, col: Color, seed: float, boss: bool, trim: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = _win_shader
	mat.set_shader_parameter("neon", col)
	mat.set_shader_parameter("seed", seed)
	mat.set_shader_parameter("boss", 1.0 if boss else 0.0)
	_box(base + Vector3(0, h / 2.0, 0), Vector3(fp.x, h, fp.y), mat)
	if trim:
		var em := _emissive(col, 5.0)
		_box(base + Vector3(0, h, fp.y / 2.0), Vector3(fp.x, 0.05, 0.05), em)
		_box(base + Vector3(fp.x / 2.0, h, 0), Vector3(0.05, 0.05, fp.y), em)
	if h > 3.0 and seed > 30.0:
		# rooftop neon sign
		_box(base + Vector3(0, h + 0.35, fp.y * 0.3), Vector3(fp.x * 0.7, 0.3, 0.04), _emissive(col, 4.0))

func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var d := b - a
	var t: float = clampf((p - a).dot(d) / d.length_squared(), 0.0, 1.0)
	return p.distance_to(a + d * t)

func _rain() -> void:
	var p := GPUParticles3D.new()
	p.amount = 700
	p.lifetime = 1.0
	p.visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 14, 16))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(8, 0.5, 8)
	pm.direction = Vector3(-0.1, -1, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 12.0
	pm.initial_velocity_max = 16.0
	p.process_material = pm
	var drop := QuadMesh.new()
	drop.size = Vector2(0.015, 0.3)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.7, 0.85, 1.0, 0.3)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	drop.material = dm
	p.draw_pass_1 = drop
	p.position = _center + Vector3(0, 9, 0)
	world.add_child(p)

func _place_camera() -> void:
	if cam == null:
		return
	var dir := Vector3(1, 0, 1).normalized().rotated(Vector3.UP, _yaw)
	cam.position = _center + dir * 19.0 + Vector3(0, 17.5, 0)
	cam.look_at(_center + Vector3(0.4, 1.2, -0.4))

# ---------------------------------------------------------------- pins (2D overlay)
func _state_col(st: String, i: int) -> Color:
	if i == 6 and st != "lock":
		return UI.RED
	match st:
		"done", "open": return UI.CYAN
		"sel": return UI.GOLD
	return Color("#4A5A70")

func _make_pins() -> void:
	for p in _pins:
		p[0].queue_free()
	_pins.clear()
	for i in 7:
		var st: String = states[i] if i < states.size() else "lock"
		var c := _state_col(st, i)
		var big := st == "sel" or i == 6
		var g := Vector3(route[i].x, 0, route[i].y)
		# ground ring + beam in 3D
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.36 if big else 0.3
		tm.outer_radius = 0.42 if big else 0.35
		ring.mesh = tm
		ring.material_override = _emissive(c, 3.0)
		ring.position = g + Vector3(0, 0.04, 0)
		world.add_child(ring)
		var beam := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.02
		cm.height = 1.2 if big else 0.9
		beam.mesh = cm
		beam.material_override = _emissive(c, 2.5)
		beam.position = g + Vector3(0, cm.height / 2.0, 0)
		world.add_child(beam)
		if st == "sel":
			var l := OmniLight3D.new()
			l.light_color = UI.GOLD
			l.light_energy = 2.0
			l.omni_range = 2.5
			l.position = g + Vector3(0, 0.6, 0)
			world.add_child(l)
		var pin := HexButton.new()
		pin.custom_minimum_size = Vector2(54, 48) if big else Vector2(48, 44)
		pin.size = pin.custom_minimum_size
		pin.fill = UI.BG
		pin.fill2 = UI.BG
		pin.border = c
		pin.selected = st == "sel"
		pin.glyph_size = 20 if big else 15
		pin.glyph = "" if st == "lock" else ("B" if i == 6 else str(i + 1))
		pin.disabled = st == "lock"
		var idx := i
		pin.pressed.connect(func(): stage_pressed.emit(idx))
		overlay.add_child(pin)
		if st == "lock":
			var lk := Icon.make("lock", Color("#7F93AA"), 14)
			lk.position = pin.size / 2 - Vector2(7, 7)
			pin.add_child(lk)
		_pins.append([pin, "pin", i, g + Vector3(0, cm.height + 0.05, 0)])
		var lab := UI.cap(boss_name if i == 6 else DistrictMap.stage_name(den, i), UI.TEXT if st != "lock" else Color("#8FA3B8"))
		if i == 6 and st != "lock":
			lab.add_theme_color_override("font_color", Color("#FF8AA0"))
		lab.add_theme_stylebox_override("normal", UI._sb(Color(UI.BG, 0.78), Color(0, 0, 0, 0), 0, 0, 5))
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(lab)
		_pins.append([lab, "label", i, g])
		if st == "done" or (st == "sel" and i < stars.size() and int(stars[i]) > 0):
			var ch := UI.chevrons(int(stars[i]) if i < stars.size() else 0, 13)
			ch.mouse_filter = Control.MOUSE_FILTER_IGNORE
			overlay.add_child(ch)
			_pins.append([ch, "chev", i, g + Vector3(0, cm.height + 0.05, 0)])

func _layout_pins() -> void:
	if cam == null or vp.size.x == 0:
		return
	var sc := size / Vector2(vp.size)
	for p in _pins:
		var n: Control = p[0]
		if not is_instance_valid(n):
			continue
		var sp: Vector2 = cam.unproject_position(p[3]) * sc
		match p[1]:
			"pin":
				n.position = sp - n.size / 2 - Vector2(0, n.size.y * 0.35)
			"label":
				n.reset_size()
				n.position = sp + Vector2(-n.size.x / 2, 14)
			"chev":
				n.reset_size()
				n.position = sp - Vector2(n.size.x / 2, 44)
	var labs: Array = []
	var blockers: Array = []
	for p in _pins:
		if is_instance_valid(p[0]):
			if p[1] == "label":
				labs.append(p[0])
			else:
				blockers.append(p[0])
	DistrictMap.declutter(labs, blockers)

# ---------------------------------------------------------------- motion + input
func _process(delta: float) -> void:
	_t += delta
	if not _drag:
		_yaw_target = sin(_t * 0.15) * 0.06
	_yaw = lerp(_yaw, _yaw_target, clampf(delta * 3.0, 0, 1))
	_place_camera()
	if _beacon:
		var pulse := 0.5 + 0.5 * sin(_t * 3.0)
		_beacon.light_energy = 2.0 + 2.5 * pulse
		_beacon_mesh.scale = Vector3.ONE * (0.9 + 0.3 * pulse)
	_layout_pins()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_drag = e.pressed
	elif e is InputEventMouseMotion and _drag:
		_yaw_target = clampf(_yaw_target - e.relative.x * 0.004, -0.45, 0.45)
	elif e is InputEventScreenDrag:
		_yaw_target = clampf(_yaw_target - e.relative.x * 0.004, -0.45, 0.45)
