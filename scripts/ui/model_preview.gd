class_name ModelPreview
extends View3D
## Transparent 3D viewer for warlord models (Armoury centrepiece, team select, boss intel).
## Drag to rotate; on release models ease back to face the camera. set_models([{tpl, boss?}]) lines models up left to right.

signal model_clicked(index: int)

var world: Node3D
var cam: Camera3D
var pivot: Node3D
var nodes: Array = []
var spin := 0.0
var auto_spin := 0.0       # warlords face the camera by default; > 0 turns the model continuously
var spacing := 1.6
var cam_dist := 4.2
var cam_height := 1.4
var look_height := 1.0
var _dragging := false

func _ready() -> void:
	resized.connect(_fit_fov)
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#5a5080")
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 1.1
	key.light_color = Color("#ffe8dd")
	world.add_child(key)
	_omni(Vector3(-2.5, 2.2, -1.5), UI.CYAN, 4.0)
	_omni(Vector3(2.5, 2.0, -1.2), UI.MAGENTA, 4.0)
	_omni(Vector3(0, 1.5, 3.0), Color("#8a7aff"), 1.5)
	pivot = Node3D.new()
	world.add_child(pivot)
	cam = Camera3D.new()
	cam.fov = 34
	world.add_child(cam)
	_place_camera()

func _omni(p: Vector3, c: Color, e: float) -> void:
	var l := OmniLight3D.new()
	l.position = p
	l.light_color = c
	l.light_energy = e
	l.omni_range = 7.0
	world.add_child(l)

func _place_camera() -> void:
	var n: int = max(1, nodes.size())
	var dist: float = cam_dist + (n - 1) * 0.9
	cam.position = Vector3(0, cam_height + (n - 1) * 0.15, dist)
	cam.look_at(Vector3(0, look_height, 0))
	_fit_fov()

## Keep the horizontal view at least as wide as at REF_ASPECT, so narrow (4:3, portrait-ish)
## containers don't crop the outer models of a line-up.
const REF_ASPECT := 1.23
var ref_aspect := REF_ASPECT   # set to the container's 16:9 aspect where it is wider (city line-up)
func _fit_fov() -> void:
	if cam == null or size.y <= 0.0:
		return
	if nodes.size() > 1 and size.x / size.y < ref_aspect:
		cam.keep_aspect = Camera3D.KEEP_WIDTH
		cam.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(17.0)) * ref_aspect))
	else:
		cam.keep_aspect = Camera3D.KEEP_HEIGHT
		cam.fov = 34

func set_models(list: Array) -> void:
	for n in nodes:
		n.queue_free()
	nodes.clear()
	var count := list.size()
	if count == 1 and auto_spin == 0.0:
		spin = -1.4          # spin-in: a single warlord turns in and settles facing the camera
	for i in count:
		var m: Dictionary = list[i]
		if m.is_empty():
			continue
		var t: Dictionary = Warlords.get_t(m.tpl)
		var node := Node3D.new()
		pivot.add_child(node)
		var model: Node3D = (load(BattleView3D.model_path(m.tpl, t.cls)) as PackedScene).instantiate()
		node.add_child(model)
		var boss: bool = m.get("boss", false)
		node.scale = Vector3.ONE * (1.3 if boss else 1.0)
		node.position = Vector3((i - (count - 1) / 2.0) * spacing, 0, -abs(i - (count - 1) / 2.0) * 0.35)
		node.rotation.y = 0.0
		_recolour(model, Data.SYNDICATES[t.syn].color, boss)
		var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
		if ap and ap.has_animation("idle"):
			ap.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			ap.play("idle")
			ap.seek(randf())
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.45
		tm.outer_radius = 0.55
		ring.mesh = tm
		ring.scale = Vector3(1, 0.04, 1)
		ring.position.y = 0.02
		var rm := StandardMaterial3D.new()
		var rc: Color = Data.RARITY_COLOR[t.rarity]
		rm.albedo_color = rc
		rm.emission_enabled = true
		rm.emission = rc
		rm.emission_energy_multiplier = 3.0
		rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ring.material_override = rm
		node.add_child(ring)
		nodes.append(node)
	_place_camera()

func play(index: int, anim: String) -> void:
	if index < 0 or index >= nodes.size():
		return
	var ap: AnimationPlayer = nodes[index].find_child("AnimationPlayer", true, false)
	if ap and ap.has_animation(anim):
		ap.play(anim, 0.1)
		ap.queue("idle")

func _recolour(model: Node, syn: Color, boss: bool) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var base: Material = mesh.surface_get_material(i)
			var nm := base.resource_name if base else ""
			if not nm in ["Accent", "Neon", "Body"]:
				continue
			var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
			match nm:
				"Accent":
					m.albedo_color = syn.darkened(0.15)
				"Neon":
					var nc := Color("#ffd42a") if boss else syn.lightened(0.25)
					m.albedo_color = nc
					m.emission_enabled = true
					m.emission = nc
					m.emission_energy_multiplier = 3.0
				"Body":
					m.albedo_color = Color("#16161f")
			mi.set_surface_override_material(i, m)

func _process(delta: float) -> void:
	if pivot == null:
		return
	if not _dragging and nodes.size() == 1:
		spin += auto_spin * delta
	if not _dragging and auto_spin == 0.0:
		spin = lerp_angle(spin, 0.0, 1.0 - exp(-3.0 * delta))   # ease back to facing the camera
	pivot.rotation.y = spin

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		_dragging = e.pressed
		if e.pressed and e.double_click:
			play(0, "victory")
	elif e is InputEventMouseMotion and _dragging:
		spin += e.relative.x * 0.01
