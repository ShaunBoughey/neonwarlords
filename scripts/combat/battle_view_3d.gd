class_name BattleView3D
extends View3D
## RAID-style 3D presentation of a Battle: cyberpunk street arena, animated warlord models,
## approach/strike/projectile/cast choreography, hit reactions and camera punches.
## Pure presentation: the Battle engine decides everything, this only animates it.

const MODELS := {
	"armour": "res://assets/models/warlord_armour.glb",
	"firepower": "res://assets/models/warlord_firepower.glb",
	"modder": "res://assets/models/warlord_modder.glb",
	"hacker": "res://assets/models/warlord_hacker.glb",
}
const ARENA := "res://assets/models/arena.glb"
## Bespoke models per warlord template (fall back to the class model).
const TPL_MODELS := {"deacon_chainz": "res://assets/models/warlord_deacon.glb"}

static func model_path(tpl_id: String, cls: String) -> String:
	var p: String = TPL_MODELS.get(tpl_id, "")
	if p != "" and ResourceLoader.exists(p):
		return p
	return MODELS[cls]
const LOOPING := ["idle", "run"]
const CAM_POS := Vector3(-4.2, 5.2, 8.8)
const CAM_LOOK := Vector3(1.0, 0.6, -1.6)

var world: Node3D
var cam: Camera3D
var actors := {}           # uid -> {node, model, ap, home, facing, side, scale, mats, dead}
var speed := 1.0
var _shake := 0.0
## Location look: set before adding to the tree (see theme_for).
var loc_theme := {}

const HIDEOUT_THEME := {
	"trolls": ["chapel", "#FF3D5E", "#FFC53D"], "vultures": ["scrap", "#FF8A3A", "#B44DFF"], "teratek": ["corp", "#34E0FF", "#EAF6FF"],
	"vikings": ["hall", "#FFC53D", "#3DA5FF"], "synapse": ["server", "#34E0FF", "#3DFF9A"], "heist": ["vault", "#FFC53D", "#FF8A3A"],
	"chopshop": ["clinic", "#3DFF9A", "#EAF6FF"], "deeds_paragon": ["temple", "#FFC53D", "#EAF6FF"], "deeds_neutral": ["temple", "#34E0FF", "#B44DFF"],
	"deeds_renegade": ["temple", "#FF3D5E", "#FF8A3A"], "deeds_generic": ["temple", "#B44DFF", "#34E0FF"],
}

## Prop set per campaign location: Slums, Sewers, Shipyard, Industrial, Chemical Plant,
## Mall, Sky Street, Megablock, Downtown, Corpo Tower.
const CAMPAIGN_PROPS := ["alley", "scrap", "scrap", "corp", "clinic", "vault", "server", "alley", "server", "corp"]

## Pick the battle backdrop from where the encounter happens.
static func theme_for(enc: Dictionary) -> Dictionary:
	match String(enc.get("mode", "")):
		"campaign":
			var loc := int(enc.get("loc", 0))
			var c: Color = Data.SYNDICATES[Data.CAMPAIGN_SYNDICATE[loc]].color
			return {"prop": CAMPAIGN_PROPS[clampi(loc, 0, CAMPAIGN_PROPS.size() - 1)], "accent": c, "accent2": UI.CYAN if c.h > 0.7 or c.h < 0.2 else UI.MAGENTA, "seed": loc}
		"sw":
			var c2: Color = Data.SYNDICATES[String(enc.get("syn", "trolls"))].color
			return {"prop": "alley", "accent": c2, "accent2": UI.PURPLE, "seed": hash(enc.get("syn", "")) % 97}
		"hideout":
			var h: Array = HIDEOUT_THEME.get(String(enc.get("id", "")), ["alley", "#FF3DB4", "#34E0FF"])
			return {"prop": h[0], "accent": Color(h[1]), "accent2": Color(h[2]), "seed": 40}
		"pit":
			return {"prop": "arena", "accent": UI.MAGENTA, "accent2": UI.GOLD, "seed": 7}
		"bastion":
			return {"prop": "corp", "accent": UI.CYAN, "accent2": UI.RED, "seed": 13}
	return {"prop": "alley", "accent": UI.MAGENTA, "accent2": UI.CYAN, "seed": 1}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.handle_input_locally = false
	add_child(vp)
	world = Node3D.new()
	vp.add_child(world)
	_build_world()

func _process(delta: float) -> void:
	if cam == null:
		return
	if _shake > 0.0:
		_shake = max(0.0, _shake - delta * 2.5)
		cam.h_offset = randf_range(-1, 1) * 0.08 * _shake
		cam.v_offset = randf_range(-1, 1) * 0.08 * _shake
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0

# ================================================================ world
func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#05040d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#3a3560")
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 0.9
	env.fog_enabled = true
	var acc: Color = loc_theme.get("accent", UI.MAGENTA)
	var acc2: Color = loc_theme.get("accent2", UI.CYAN)
	env.fog_light_color = Color("#140a24").lerp(acc, 0.12)
	env.fog_density = 0.018
	# SSR/SSAO are Forward+ only (warnings on the mobile renderer); _wet_floor uses a ReflectionProbe
	env.volumetric_fog_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("#8fa6ff")
	sun.light_energy = 0.55
	sun.shadow_enabled = true
	world.add_child(sun)
	if ResourceLoader.exists(ARENA):
		world.add_child((load(ARENA) as PackedScene).instantiate())
	# neon street lamps (match the arena lamp posts) + rim lights on the fighting lanes
	for x in [-12.0, -4.0, 4.0, 12.0]:
		for z in [-7.0, 7.0]:
			_omni(Vector3(x, 4.0, z * 0.9), acc2 if x < 0 else acc, 3.0, 10.0)
	_omni(Vector3(-5, 3.0, 2.5), acc2.lerp(Color("#5aa0ff"), 0.4), 2.5, 9.0)
	_omni(Vector3(5, 3.0, 2.5), acc.lerp(Color("#ff4f7b"), 0.3), 2.5, 9.0)
	_omni(Vector3(0, 6.0, -4), acc.lerp(Color("#9b5cff"), 0.5), 2.0, 14.0)
	_wet_floor()
	_skyline(acc, acc2, int(loc_theme.get("seed", 1)))
	_set_dressing()
	_props(String(loc_theme.get("prop", "alley")), acc, acc2)
	_rain()
	cam = Camera3D.new()
	cam.fov = 42
	world.add_child(cam)
	cam.position = CAM_POS
	cam.look_at(CAM_LOOK)

## Glossy puddle layer over the street so neon reflects. A box-projected ReflectionProbe gives
## the reflections (it works on the mobile renderer, unlike SSR).
func _wet_floor() -> void:
	var probe := ReflectionProbe.new()
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.box_projection = true
	probe.size = Vector3(32, 12, 20)
	probe.origin_offset = Vector3(0, -5.0, 0)
	probe.position = Vector3(0, 6.0, -0.5)
	probe.intensity = 1.0
	world.add_child(probe)
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(30, 18)
	m.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.03, 0.03, 0.05, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.85
	mat.roughness = 0.05
	m.material_override = mat
	m.position = Vector3(0, 0.012, -0.5)
	world.add_child(m)

func _box(pos: Vector3, size: Vector3, col: Color, emit := 0.0, rot := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.5
	mat.metallic = 0.3
	if emit > 0.0:
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = emit
	m.material_override = mat
	m.position = pos
	m.rotation.y = rot
	world.add_child(m)
	return m

## Close set dressing behind the fight: storefront wall, neon signs, crates, barrels, vending machine.
func _set_dressing() -> void:
	_box(Vector3(1, 3.2, -6.5), Vector3(18, 6.4, 0.6), Color("#14121f"))
	_box(Vector3(1, 0.2, -6.1), Vector3(18, 0.4, 0.4), Color("#2a2838"))
	var acc: Color = loc_theme.get("accent", UI.MAGENTA)
	var acc2: Color = loc_theme.get("accent2", UI.CYAN)
	var signs := [[Vector3(-3.5, 3.4, -6.15), Vector3(3.2, 0.7, 0.08), acc], [Vector3(2.5, 4.2, -6.15), Vector3(2.4, 0.5, 0.08), acc2],
		[Vector3(6.2, 2.8, -6.15), Vector3(0.6, 2.2, 0.08), UI.GOLD], [Vector3(-7.5, 2.6, -6.15), Vector3(1.6, 1.0, 0.08), acc.lerp(UI.PURPLE, 0.5)]]
	if String(loc_theme.get("prop", "alley")) != "alley":
		signs = signs.slice(1, 3)
	for sg in signs:
		_box(sg[0], sg[1], sg[2], 5.0)
		_omni(sg[0] + Vector3(0, 0, 1.2), sg[2], 1.6, 6.0)
	for i in 6:
		_box(Vector3(-6.5 + i * 2.6, 1.2, -6.15), Vector3(1.6, 1.8, 0.05), Color("#3a2a10"), 1.2)  # lit shop windows
	_box(Vector3(-6.0, 0.4, -4.8), Vector3(0.8, 0.8, 0.8), Color("#3a3326"), 0.0, 0.3)
	_box(Vector3(-5.2, 0.3, -5.2), Vector3(0.6, 0.6, 0.6), Color("#3a3326"), 0.0, -0.2)
	_box(Vector3(6.8, 0.9, -5.4), Vector3(0.9, 1.8, 0.7), Color("#1a2a44"))
	_box(Vector3(6.8, 1.2, -5.04), Vector3(0.7, 1.0, 0.02), Color("#29e3ff"), 2.5)              # vending machine screen
	for x in [-8.0, 8.5]:
		var bar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.32
		cyl.bottom_radius = 0.32
		cyl.height = 0.9
		bar.mesh = cyl
		var bm := StandardMaterial3D.new()
		bm.albedo_color = Color("#3a1a1a")
		bm.metallic = 0.6
		bar.material_override = bm
		bar.position = Vector3(x, 0.45, -3.6)
		world.add_child(bar)
	# traffic cones like the reference street
	for p in [Vector3(-7.2, 0, 1.5), Vector3(7.4, 0, 2.2), Vector3(-5.6, 0, -3.8)]:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.18
		cm.height = 0.5
		cone.mesh = cm
		var com := StandardMaterial3D.new()
		com.albedo_color = Color("#ff6a1a")
		cone.material_override = com
		cone.position = p + Vector3(0, 0.25, 0)
		world.add_child(cone)

## Distant towers with lit windows rising behind the street wall (shared window shader).
func _skyline(acc: Color, acc2: Color, seed: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1000 + seed
	var sh := Shader.new()
	sh.code = DistrictDiorama.WINDOW_SHADER
	var x := -20.0
	while x < 22.0:
		var w := r.randf_range(2.5, 4.5)
		var h := r.randf_range(8.0, 18.0)
		var z := r.randf_range(-16.0, -10.0)
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("neon", [acc, acc2, UI.GOLD][r.randi_range(0, 2)])
		mat.set_shader_parameter("seed", r.randf() * 50.0)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(w, h, 3.0)
		m.mesh = bm
		m.material_override = mat
		m.position = Vector3(x, h / 2.0, z)
		world.add_child(m)
		if r.randf() < 0.4:
			_box(Vector3(x, h + 0.05, z + 1.5), Vector3(w, 0.08, 0.08), acc if r.randf() < 0.5 else acc2, 5.0)
		x += w + r.randf_range(0.3, 1.5)

## Location-specific set dressing in front of the street wall.
func _props(kind: String, acc: Color, acc2: Color) -> void:
	match kind:
		"chapel":
			for i in 3:
				_box(Vector3(-4.5 + i * 4.5, 3.6, -6.12), Vector3(1.1, 3.2, 0.05), [acc, UI.GOLD, acc2][i].darkened(0.2), 3.0)
			_box(Vector3(0, 5.2, -6.1), Vector3(0.25, 2.0, 0.08), UI.GOLD, 6.0)
			_box(Vector3(0, 5.6, -6.1), Vector3(1.1, 0.25, 0.08), UI.GOLD, 6.0)
			for i in 9:
				_box(Vector3(-7.0 + i * 1.75, 0.35, -5.7), Vector3(0.1, 0.5, 0.1), Color("#FFE7A8"), 4.0)
			_omni(Vector3(0, 4.5, -4.8), UI.GOLD, 2.5, 8.0)
		"scrap":
			var r := RandomNumberGenerator.new()
			r.seed = 5
			for i in 14:
				var p := Vector3(r.randf_range(-9, 9), 0, r.randf_range(-6, -4.2))
				var sz := Vector3(r.randf_range(0.6, 1.6), r.randf_range(0.4, 1.4), r.randf_range(0.6, 1.2))
				_box(p + Vector3(0, sz.y / 2, 0), sz, [Color("#3A2A1A"), Color("#2A2E36"), Color("#4A2212")][r.randi_range(0, 2)], 0.0, r.randf() * PI)
			_box(Vector3(5.5, 0.7, -4.6), Vector3(3.2, 1.2, 1.6), Color("#2A1A14"), 0.0, 0.25)
			_omni(Vector3(4, 2.5, -4), acc, 3.0, 8.0)
		"corp":
			for y in [1.2, 2.6, 4.0, 5.4]:
				_box(Vector3(1, y, -6.12), Vector3(17.5, 0.06, 0.05), acc2.lerp(acc, 0.3), 3.0)
			for x in [-6.0, -2.0, 2.0, 6.0]:
				_box(Vector3(x, 3.2, -5.6), Vector3(0.5, 6.4, 0.5), Color(0.6, 0.85, 1.0, 1.0).darkened(0.7), 0.4)
			_box(Vector3(0, 4.6, -6.08), Vector3(1.6, 1.6, 0.06), acc, 4.0)
		"hall":
			_box(Vector3(1, 5.4, -6.1), Vector3(17.5, 0.15, 0.08), acc, 4.0)
			for i in 6:
				var sh := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 0.6
				cm.bottom_radius = 0.6
				cm.height = 0.12
				sh.mesh = cm
				var mm := StandardMaterial3D.new()
				mm.albedo_color = [acc2, acc][i % 2].darkened(0.6)
				mm.emission_enabled = true
				mm.emission = [acc2, acc][i % 2]
				mm.emission_energy_multiplier = 0.35
				sh.material_override = mm
				sh.rotation.x = PI / 2
				sh.position = Vector3(-7.0 + i * 2.8, 3.4, -6.05)
				world.add_child(sh)
			for x in [-8.0, 8.5]:
				_box(Vector3(x, 0.9, -4.8), Vector3(0.6, 0.2, 0.6), Color("#FF8A3A"), 6.0)
				_omni(Vector3(x, 1.6, -4.6), Color("#FF8A3A"), 2.5, 6.0)
		"server":
			for i in 8:
				var x := -8.0 + i * 2.3
				_box(Vector3(x, 1.6, -5.6), Vector3(1.2, 3.2, 0.9), Color("#0E141E"))
				for k in 6:
					_box(Vector3(x, 0.5 + k * 0.45, -5.14), Vector3(0.9, 0.04, 0.02), acc if (i + k) % 3 else acc2, 4.0)
		"vault":
			var door := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 2.4
			cm.bottom_radius = 2.4
			cm.height = 0.4
			door.mesh = cm
			var dm := StandardMaterial3D.new()
			dm.albedo_color = Color("#5A4A2A")
			dm.metallic = 0.9
			dm.roughness = 0.3
			door.material_override = dm
			door.rotation.x = PI / 2
			door.position = Vector3(0.5, 3.0, -6.0)
			world.add_child(door)
			_box(Vector3(0.5, 3.0, -5.75), Vector3(0.2, 3.6, 0.1), UI.GOLD, 1.2)
			for i in 5:
				_box(Vector3(-6.5 + (i % 3) * 0.7, 0.15 + int(i / 3) * 0.3, -4.8), Vector3(0.6, 0.28, 0.3), UI.GOLD, 2.5)
			_omni(Vector3(0.5, 3.0, -3.5), UI.GOLD, 1.0, 6.0)
		"clinic":
			_box(Vector3(-4, 4.2, -6.08), Vector3(0.5, 1.6, 0.06), acc, 6.0)
			_box(Vector3(-4, 4.2, -6.08), Vector3(1.6, 0.5, 0.06), acc, 6.0)
			_box(Vector3(3.5, 0.6, -4.8), Vector3(2.2, 0.2, 0.9), Color("#B8C2CC"))
			_box(Vector3(3.5, 4.8, -4.8), Vector3(1.2, 0.08, 1.2), Color("#EAF6FF"), 5.0)
			_omni(Vector3(3.5, 4.2, -4.6), Color("#EAF6FF"), 2.5, 7.0)
		"temple":
			for x in [-5.5, 5.5]:
				_box(Vector3(x, 2.6, -5.2), Vector3(0.4, 5.2, 0.4), acc.darkened(0.3), 1.0)
			_box(Vector3(0, 5.4, -5.2), Vector3(12.5, 0.35, 0.5), acc.darkened(0.2), 1.5)
			for i in 7:
				_box(Vector3(-6.0 + i * 2.0, 4.4, -5.0), Vector3(0.35, 0.5, 0.35), [acc, acc2][i % 2], 4.0)
		"arena":
			for x in [-6.0, 0.0, 6.0]:
				var sp := SpotLight3D.new()
				sp.light_color = acc if x != 0.0 else acc2
				sp.light_energy = 6.0
				sp.spot_range = 16.0
				sp.spot_angle = 26.0
				sp.position = Vector3(x, 9.0, 2.0)
				sp.rotation_degrees = Vector3(-80, 0, 0)
				world.add_child(sp)
			for z in [-4.6, 5.6]:
				_box(Vector3(0, 0.9, z), Vector3(20, 0.08, 0.08), acc, 4.0)
				_box(Vector3(0, 0.45, z), Vector3(20, 0.06, 0.06), acc2, 3.0)

func _rain() -> void:
	var p := GPUParticles3D.new()
	p.amount = 900
	p.lifetime = 1.2
	p.visibility_aabb = AABB(Vector3(-14, -2, -10), Vector3(28, 14, 20))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(12, 0.5, 8)
	pm.direction = Vector3(-0.15, -1, 0)
	pm.spread = 3.0
	pm.initial_velocity_min = 14.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3(0, -9.8, 0)
	p.process_material = pm
	var drop := QuadMesh.new()
	drop.size = Vector2(0.015, 0.35)
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = Color(0.7, 0.85, 1.0, 0.35)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	drop.material = dm
	p.draw_pass_1 = drop
	p.position = Vector3(0, 9, -1)
	world.add_child(p)

func _omni(pos: Vector3, col: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	world.add_child(l)

## Formation slot: player side on the left (-X), enemies on the right (+X), staggered like RAID.
const ALLY_X := -1.6
const FOE_X := 2.0

## RAID staging (reference): each team stands in a line running away from the camera
## (near front-right to far back-left); the two lines face each other across the gap.
func formation(side: int, idx: int, count: int) -> Vector3:
	var zs := [2.6, 0.7, -1.2, -3.1, -5.0, 4.4, -6.8]
	var jitter := [0.0, -0.35, 0.15, -0.25, 0.1, 0.2, -0.1]
	if count == 1 and side == 1:
		return Vector3(FOE_X + 0.4, 0, -0.8)
	var i := idx % zs.size()
	if side == 0:
		return Vector3(ALLY_X + jitter[i], 0, zs[i])
	return Vector3(FOE_X - jitter[i], 0, zs[i] - 0.9)

# ================================================================ units
func add_unit(u: Dictionary, idx: int, count: int) -> void:
	var t: Dictionary = Warlords.get_t(u.tpl)
	var node := Node3D.new()
	world.add_child(node)
	var model: Node3D = (load(model_path(u.tpl, t.cls)) as PackedScene).instantiate()
	node.add_child(model)
	var sc := 1.0
	if u.get("boss", false):
		sc = 1.55
	node.scale = Vector3.ONE * sc
	var home := formation(u.side, idx, count)
	node.position = home
	var facing := PI / 2 if u.side == 0 else -PI / 2   # face straight across the gap
	node.rotation.y = facing
	var syn_col: Color = Data.SYNDICATES[t.syn].color
	var mats := _recolour(model, syn_col, Data.RARITY_COLOR[t.rarity], u.get("boss", false))
	var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if ap:
		for a in LOOPING:
			if ap.has_animation(a):
				ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		ap.play("idle")
		ap.seek(randf() * 1.2)
	# ground ring marker in the side colour
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.42
	tm.outer_radius = 0.5
	ring.mesh = tm
	ring.scale = Vector3(1, 0.05, 1)
	ring.position.y = 0.02
	ring.material_override = _emissive(UI.CYAN if u.side == 0 else UI.RED, 2.0)
	node.add_child(ring)
	actors[u.uid] = {"node": node, "model": model, "ap": ap, "home": home, "facing": facing, "side": u.side, "scale": sc, "mats": mats, "dead": false, "ring": ring}

func remove_unit(uid: String) -> void:
	if actors.has(uid):
		actors[uid].node.queue_free()
		actors.erase(uid)

func _emissive(col: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

## Syndicate colour on armour accents, glowing neon trims, boss gold.
func _recolour(model: Node, syn: Color, rar: Color, boss: bool) -> Array:
	var out: Array = []
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var base: Material = mesh.surface_get_material(i)
			var name := base.resource_name if base else ""
			var m: StandardMaterial3D = (base.duplicate() if base is StandardMaterial3D else StandardMaterial3D.new())
			match name:
				"Accent":
					m.albedo_color = syn.darkened(0.15)
					m.metallic = 0.35
					m.roughness = 0.4
				"Neon":
					var nc := Color("#ffd42a") if boss else syn.lightened(0.25)
					m.albedo_color = nc
					m.emission_enabled = true
					m.emission = nc
					m.emission_energy_multiplier = 3.5
				"Body":
					m.albedo_color = Color("#15151f").lerp(rar, 0.08)
			mi.set_surface_override_material(i, m)
			out.append(m)
	return out

func pos_of(uid: String) -> Vector3:
	return actors[uid].node.global_position if actors.has(uid) else Vector3.ZERO

## Screen position (container pixels) of a point above the unit.
func screen_pos(uid: String, height := 2.15) -> Vector2:
	if not actors.has(uid) or cam == null:
		return Vector2(-1000, -1000)
	var a: Dictionary = actors[uid]
	var p: Vector3 = a.node.global_position + Vector3(0, height * a.scale, 0)
	if cam.is_position_behind(p):
		return Vector2(-1000, -1000)
	var sp := cam.unproject_position(p)
	var ratio := size / Vector2(vp.size) if vp.size.x > 0 else Vector2.ONE
	return sp * ratio

func unit_screen_height(uid: String) -> float:
	return screen_pos(uid, 0.0).y - screen_pos(uid, 2.0).y

func play(uid: String, anim: String, blend := 0.12) -> void:
	if not actors.has(uid):
		return
	var ap: AnimationPlayer = actors[uid].ap
	if ap == null or not ap.has_animation(anim):
		return
	ap.speed_scale = speed
	ap.play(anim, blend)
	if not anim in LOOPING and anim != "death":
		if not ap.animation_finished.is_connected(_on_anim_done.bind(uid)):
			ap.animation_finished.connect(_on_anim_done.bind(uid))

func _on_anim_done(anim: String, uid: String) -> void:
	if actors.has(uid) and not actors[uid].dead and anim != "death" and anim != "victory":
		var ap: AnimationPlayer = actors[uid].ap
		if ap.current_animation == "" or ap.current_animation == anim:
			ap.play("idle", 0.2)

func _wait(sec: float) -> void:
	await get_tree().create_timer(max(0.01, sec / speed)).timeout

func _tween() -> Tween:
	var tw := create_tween()
	tw.set_speed_scale(speed)
	return tw

# ================================================================ choreography
## Melee: run to the target, strike. Returns at the moment of impact (call return_home after).
func melee(uid: String, target_uid: String) -> void:
	if not actors.has(uid) or not actors.has(target_uid):
		return
	var a: Dictionary = actors[uid]
	var tp := pos_of(target_uid)
	var dir: Vector3 = (tp - a.node.global_position)
	dir.y = 0
	var dist := dir.length()
	var stop: Vector3 = tp - dir.normalized() * (1.1 * max(a.scale, actors[target_uid].scale))
	a.node.look_at(Vector3(tp.x, a.node.global_position.y, tp.z), Vector3.UP, true)
	play(uid, "run")
	var tw := _tween()
	tw.tween_property(a.node, "global_position", stop, clamp(dist * 0.07, 0.2, 0.55))
	await tw.finished
	play(uid, "attack", 0.05)
	await _wait(0.36)

func return_home(uid: String) -> void:
	if not actors.has(uid) or actors[uid].dead:
		return
	var a: Dictionary = actors[uid]
	if a.node.global_position.distance_to(a.home) < 0.05:
		_face_front(uid)
		return
	await _wait(0.12)
	a.node.look_at(Vector3(a.home.x, a.node.global_position.y, a.home.z), Vector3.UP, true)
	play(uid, "run")
	var tw := _tween()
	tw.tween_property(a.node, "global_position", a.home, 0.35)
	await tw.finished
	_face_front(uid)
	play(uid, "idle", 0.15)

func _face_front(uid: String) -> void:
	var a: Dictionary = actors[uid]
	a.node.rotation = Vector3(0, a.facing, 0)

func face(uid: String, target_uid: String) -> void:
	if not actors.has(uid) or not actors.has(target_uid) or uid == target_uid:
		return
	var a: Dictionary = actors[uid]
	var tp := pos_of(target_uid)
	a.node.look_at(Vector3(tp.x, a.node.global_position.y, tp.z), Vector3.UP, true)

## Ranged: aim, fire glowing bolts at every target. Returns on impact.
func ranged(uid: String, targets: Array, col: Color, anim := "shoot") -> void:
	if not actors.has(uid):
		return
	if not targets.is_empty():
		face(uid, targets[0])
	play(uid, anim, 0.08)
	await _wait(0.28)
	var from: Vector3 = pos_of(uid) + Vector3(0, 1.25 * actors[uid].scale, 0)
	var last: Tween = null
	for t in targets:
		if not actors.has(t):
			continue
		last = _bolt(from, pos_of(t) + Vector3(0, 1.1 * actors[t].scale, 0), col)
	if last:
		await last.finished

func _bolt(from: Vector3, to: Vector3, col: Color) -> Tween:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.12
	s.height = 0.24
	m.mesh = s
	m.material_override = _emissive(col, 6.0)
	world.add_child(m)
	m.global_position = from
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = 2.0
	light.omni_range = 3.0
	m.add_child(light)
	var tw := _tween()
	tw.tween_property(m, "global_position", to, clamp(from.distance_to(to) * 0.035, 0.15, 0.4))
	tw.tween_callback(func():
		_burst(to, col, 0.9)
		m.queue_free())
	return tw

## Expanding glow ring + flash at a point.
func _burst(at: Vector3, col: Color, size := 1.0) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.3 * size
	s.height = 0.6 * size
	m.mesh = s
	var mat := _emissive(col, 5.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	world.add_child(m)
	m.global_position = at
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * 2.2, 0.3)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(m.queue_free)

## Buff / heal / debuff cast with rings on the affected units.
func cast(uid: String, targets: Array, col: Color) -> void:
	if not actors.has(uid):
		return
	play(uid, "cast", 0.08)
	_ring(pos_of(uid), col, 1.6 * actors[uid].scale)
	await _wait(0.35)
	for t in targets:
		if actors.has(t):
			_ring(pos_of(t), col, 1.1 * actors[t].scale)
			_burst(pos_of(t) + Vector3(0, 1.0, 0), col, 0.6)
	await _wait(0.2)

func _ring(at: Vector3, col: Color, radius: float) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.85
	tm.outer_radius = 1.0
	m.mesh = tm
	var mat := _emissive(col, 4.0)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.material_override = mat
	world.add_child(m)
	m.global_position = at + Vector3(0, 0.05, 0)
	m.scale = Vector3(0.2, 0.2, 0.2) * radius
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(1, 0.3, 1) * radius, 0.45)
	tw.tween_property(m, "position:y", at.y + 1.2, 0.45)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(m.queue_free)

func hit(uid: String, crit: bool) -> void:
	if not actors.has(uid) or actors[uid].dead:
		return
	var a: Dictionary = actors[uid]
	play(uid, "hit", 0.03)
	_flash(uid)
	if crit:
		_shake = 1.0
	_burst(pos_of(uid) + Vector3(0, 1.1 * a.scale, 0), Color("#ffd42a") if crit else Color("#ff5a36"), 0.7 if crit else 0.45)

func _flash(uid: String) -> void:
	var a: Dictionary = actors[uid]
	for m in a.mats:
		var sm: StandardMaterial3D = m
		# remember the true resting glow once, so overlapping flashes never "restore" to white
		if not sm.has_meta("rest"):
			sm.set_meta("rest", [sm.emission_enabled, sm.emission, sm.emission_energy_multiplier])
		sm.set_meta("flash_n", int(sm.get_meta("flash_n", 0)) + 1)
		sm.emission_enabled = true
		sm.emission = Color(1, 1, 1)
		sm.emission_energy_multiplier = 1.5
		get_tree().create_timer(0.09).timeout.connect(func():
			var n: int = int(sm.get_meta("flash_n", 1)) - 1
			sm.set_meta("flash_n", n)
			if n <= 0:
				var rest: Array = sm.get_meta("rest")
				sm.emission_enabled = rest[0]
				sm.emission = rest[1]
				sm.emission_energy_multiplier = rest[2])

func die(uid: String) -> void:
	if not actors.has(uid):
		return
	var a: Dictionary = actors[uid]
	a.dead = true
	play(uid, "death", 0.05)
	a.ring.visible = false
	var tw := _tween()
	tw.tween_interval(1.4)
	tw.tween_property(a.node, "position:y", -0.6, 0.8)

func revive(uid: String) -> void:
	if not actors.has(uid):
		return
	var a: Dictionary = actors[uid]
	a.dead = false
	a.node.position = a.home
	a.ring.visible = true
	_face_front(uid)
	play(uid, "idle", 0.1)
	_ring(a.home, UI.GREEN, 1.6)

func victory(side: int) -> void:
	for uid in actors:
		var a: Dictionary = actors[uid]
		if a.side == side and not a.dead:
			_face_front(uid)
			play(uid, "victory")

## Camera push toward the acting unit for big skills (cooldown abilities).
func punch(uid: String) -> void:
	if not actors.has(uid):
		return
	var p := pos_of(uid)
	# small push and turn only, so the near-left set wall never swings in front of the allies
	var target_pos := CAM_POS.lerp(p + Vector3(0, 2.5, 5.5), 0.12)
	var tw := _tween()
	tw.tween_method(func(v: float):
		cam.position = CAM_POS.lerp(target_pos, v)
		cam.look_at(CAM_LOOK.lerp(p + Vector3(0, 1.2, 0), v * 0.3)), 0.0, 1.0, 0.25)
	tw.tween_interval(0.35)
	tw.tween_method(func(v: float):
		cam.position = CAM_POS.lerp(target_pos, v)
		cam.look_at(CAM_LOOK.lerp(p + Vector3(0, 1.2, 0), v * 0.3)), 1.0, 0.0, 0.35)

func set_selected(uid: String, kind: String) -> void:
	for k in actors:
		var a: Dictionary = actors[k]
		var col := UI.CYAN if a.side == 0 else UI.RED
		var e := 2.0
		if k == uid and kind == "active":
			col = UI.GREEN
			e = 5.0
		a.ring.material_override = _emissive(col, e)
		a.ring.scale = Vector3(1.25, 0.05, 1.25) if k == uid else Vector3(1, 0.05, 1)

func mark_targets(uids: Array) -> void:
	for k in actors:
		if uids.has(k):
			actors[k].ring.material_override = _emissive(UI.MAGENTA, 5.0)


# ================================================================ signature skill effects
## Pick a signature effect for a cooldown ability. An ability may name its own with "vfx".
static func vfx_kind(a: Dictionary, cls: String) -> String:
	if a.has("vfx"):
		return String(a.vfx)
	var debuffs: Array = []
	var heals := false
	var shields := false
	var buffs := false
	for f in a.get("fx", []):
		match String(f.get("t", "")):
			"debuff": debuffs.append(String(f.get("id", "")))
			"heal", "revive": heals = true
			"shield": shields = true
			"buff": buffs = true
	if float(a.get("mult", 0.0)) > 0.0:
		if a.get("tgt", "") == "all_enemies":
			return "orbital" if int(a.get("cd", 0)) >= 4 else "shockwave"
		if int(a.get("hits", 1)) > 1:
			return "flurry"
		for d in debuffs:
			if d in ["stun", "shock", "stupefy"]:
				return "lightning"
			if d in ["poison"]:
				return "toxic"
		return {"armour": "slash", "firepower": "beam", "modder": "beam", "hacker": "lightning"}.get(cls, "beam")
	if heals:
		return "heal"
	if shields:
		return "shield"
	if not debuffs.is_empty() and not buffs:
		return "hex"
	return "empower"

func _fx_mat(col: Color, e := 5.0) -> StandardMaterial3D:
	var m := _emissive(col, e)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _chest(uid: String) -> Vector3:
	return pos_of(uid) + Vector3(0, 1.1 * actors[uid].scale, 0)

func _flash_light(at: Vector3, col: Color, energy := 4.0, dur := 0.35) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = 5.0
	world.add_child(l)
	l.global_position = at
	var tw := _tween()
	tw.tween_property(l, "light_energy", 0.0, dur)
	tw.tween_callback(l.queue_free)

## Cylinder stretched between two points that swells then thins out.
func _beam(from: Vector3, to: Vector3, col: Color, width := 0.18, dur := 0.45) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	m.mesh = cm
	var mat := _fx_mat(col, 7.0)
	m.material_override = mat
	world.add_child(m)
	var mid := (from + to) / 2.0
	var length := from.distance_to(to)
	m.global_position = mid
	var dir := (to - from).normalized()
	var up := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	m.global_transform.basis = Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, PI / 2)
	m.scale = Vector3(width * 0.2, length, width * 0.2)
	var tw := _tween()
	tw.tween_property(m, "scale", Vector3(width, length, width), dur * 0.25)
	tw.tween_property(m, "scale", Vector3(width * 0.1, length, width * 0.1), dur * 0.75)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, dur * 0.75)
	tw.tween_callback(m.queue_free)

## Jagged lightning arc built from thin glowing segments; re-strikes a few times.
func _lightning(from: Vector3, to: Vector3, col: Color, strikes := 3) -> void:
	for k in strikes:
		var prev := from
		var segs := 7
		for i in range(1, segs + 1):
			var t := float(i) / segs
			var p := from.lerp(to, t)
			if i < segs:
				p += Vector3(randf_range(-0.35, 0.35), randf_range(-0.3, 0.3), randf_range(-0.35, 0.35))
			_beam(prev, p, col.lightened(0.35), 0.045, 0.16)
			prev = p
		await _wait(0.09)

## Flat glowing ring that sweeps outward across the ground.
func _shockwave(center: Vector3, col: Color, radius := 6.0, dur := 0.55) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.9
	tm.outer_radius = 1.0
	m.mesh = tm
	var mat := _fx_mat(col, 6.0)
	m.material_override = mat
	world.add_child(m)
	m.global_position = center + Vector3(0, 0.1, 0)
	m.scale = Vector3(0.3, 0.15, 0.3)
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(m, "scale", Vector3(radius, 0.15, radius), dur).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(m.queue_free)

## Squashed torus that spins across the target like a blade arc.
func _slash(at: Vector3, col: Color, tilt := 0.6) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.92
	tm.outer_radius = 1.0
	m.mesh = tm
	var mat := _fx_mat(col, 8.0)
	m.material_override = mat
	world.add_child(m)
	m.global_position = at
	m.scale = Vector3(1.1, 0.05, 1.1)
	m.rotation = Vector3(tilt, 0, 0.4)
	var tw := _tween()
	tw.set_parallel(true)
	tw.tween_property(m, "rotation:y", PI * 1.2, 0.22)
	tw.tween_property(m, "scale", Vector3(1.6, 0.05, 1.6), 0.22)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.chain().tween_callback(m.queue_free)

## One-shot particle spray (rising motes, toxic cloud, falling hex sparks).
func _spray(at: Vector3, col: Color, mode: String, amount := 40) -> void:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = 0.9
	p.explosiveness = 0.85
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.6
	match mode:
		"rise":
			pm.direction = Vector3.UP
			pm.initial_velocity_min = 1.5
			pm.initial_velocity_max = 3.0
			pm.gravity = Vector3(0, 0.5, 0)
		"cloud":
			pm.direction = Vector3.UP
			pm.spread = 180.0
			pm.initial_velocity_min = 0.3
			pm.initial_velocity_max = 1.0
			pm.gravity = Vector3.ZERO
			pm.scale_min = 2.0
			pm.scale_max = 4.0
		"fall":
			pm.direction = Vector3.DOWN
			pm.initial_velocity_min = 1.0
			pm.initial_velocity_max = 2.5
			pm.gravity = Vector3(0, -2.0, 0)
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var qm := _fx_mat(col, 6.0)
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = qm
	p.draw_pass_1 = q
	world.add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)

## Translucent bubble that pops up around a unit.
func _bubble(uid: String, col: Color) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.9 * actors[uid].scale
	sm.height = 1.8 * actors[uid].scale
	m.mesh = sm
	var mat := _fx_mat(col, 2.0)
	mat.albedo_color.a = 0.35
	m.material_override = mat
	world.add_child(m)
	m.global_position = _chest(uid)
	m.scale = Vector3.ONE * 0.2
	var tw := _tween()
	tw.tween_property(m, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(m.queue_free)

## Three rings spiralling up (empower) or down (hex) around a unit.
func _spiral(uid: String, col: Color, up := true) -> void:
	var base := pos_of(uid)
	for i in 3:
		var m := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.75
		tm.outer_radius = 0.82
		m.mesh = tm
		var mat := _fx_mat(col, 5.0)
		m.material_override = mat
		world.add_child(m)
		var y0 := 0.1 if up else 2.4
		var y1 := 2.4 if up else 0.1
		m.global_position = base + Vector3(0, y0, 0)
		m.scale = Vector3.ONE * actors[uid].scale * (0.8 + 0.15 * i)
		var tw := _tween()
		tw.tween_interval(0.09 * i)
		tw.tween_property(m, "global_position:y", base.y + y1, 0.5)
		tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5)
		tw.tween_callback(m.queue_free)

## Signature attack choreography. Returns when the impacts land.
func signature_attack(kind: String, uid: String, foes: Array, col: Color) -> void:
	if not actors.has(uid):
		return
	var live: Array = foes.filter(func(t): return actors.has(t))
	if live.is_empty():
		return
	match kind:
		"orbital", "holy":
			var c: Color = UI.GOLD if kind == "holy" else col
			play(uid, "cast", 0.08)
			_spiral(uid, c, true)
			await _wait(0.35)
			for t in live:
				var at := pos_of(t)
				_beam(at + Vector3(0, 12, 0), at, c, 0.45, 0.6)
				_flash_light(at + Vector3(0, 1, 0), c, 6.0)
				_shockwave(at, c, 1.6, 0.4)
				await _wait(0.06)
			_shake = 0.8
			await _wait(0.25)
		"shockwave":
			play(uid, "cast", 0.08)
			await _wait(0.25)
			var centre := Vector3.ZERO
			for t in live:
				centre += pos_of(t)
			centre /= live.size()
			_shockwave(pos_of(uid), col, centre.distance_to(pos_of(uid)) * 2.2, 0.5)
			await _wait(0.35)
			for t in live:
				_burst(_chest(t), col, 0.8)
		"chain":
			play(uid, "attack", 0.08)
			await _wait(0.2)
			var from := _chest(uid)
			for t in live:
				var to := _chest(t)
				for k in 7:
					var link := MeshInstance3D.new()
					var tm := TorusMesh.new()
					tm.inner_radius = 0.07
					tm.outer_radius = 0.11
					link.mesh = tm
					link.material_override = _fx_mat(Color("#C9C9D6"), 3.0)
					world.add_child(link)
					link.global_position = from
					link.rotation = Vector3(PI / 2 * (k % 2), 0, 0)
					var lt := _tween()
					lt.tween_property(link, "global_position", from.lerp(to, (k + 1) / 7.0) + Vector3(0, sin(k / 7.0 * PI) * 0.6, 0), 0.18)
					lt.tween_interval(0.12)
					lt.tween_callback(link.queue_free)
				await _wait(0.12)
				_burst(to, UI.RED, 0.7)
			_shake = 0.5
			await _wait(0.2)
		"flurry":
			var t0: String = live[0]
			face(uid, t0)
			play(uid, "attack", 0.06)
			for k in 5:
				var at := _chest(t0) + Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.4), randf_range(-0.2, 0.2))
				_burst(at, col if k % 2 == 0 else col.lightened(0.4), 0.7)
				_slash(at, col, randf_range(-0.8, 0.8))
				_flash_light(at, col, 3.0, 0.15)
				await _wait(0.1)
		"lightning":
			play(uid, "cast", 0.08)
			await _wait(0.2)
			for t in live:
				_lightning(_chest(uid) + Vector3(0, 0.3, 0), _chest(t), col)
				_flash_light(_chest(t), col, 5.0)
			await _wait(0.25)
			for t in live:
				_burst(_chest(t), col, 0.7)
		"toxic":
			await ranged(uid, live, col, "shoot")
			for t in live:
				_spray(_chest(t), Color("#7CFF5A"), "cloud", 30)
		"slash":
			await melee(uid, live[0])
			_slash(_chest(live[0]), col.lightened(0.3))
			_flash_light(_chest(live[0]), col, 4.0)
			_shake = 0.6
		_:  # beam
			face(uid, live[0])
			play(uid, "shoot", 0.08)
			var charge := _chest(uid) + Vector3(0, 0.15, 0)
			_burst(charge, col, 0.5)
			await _wait(0.3)
			for t in live:
				_beam(charge, _chest(t), col, 0.24, 0.8)
				_flash_light(_chest(t), col, 4.0)
			await _wait(0.2)
			for t in live:
				_burst(_chest(t), col, 0.8)

## Signature support effects (heal, shield, empower, hex).
func signature_support(kind: String, uid: String, targets: Array, col: Color) -> void:
	if not actors.has(uid):
		return
	play(uid, "cast", 0.08)
	_ring(pos_of(uid), col, 1.8 * actors[uid].scale)
	await _wait(0.3)
	for t in targets:
		if not actors.has(t):
			continue
		match kind:
			"heal":
				_spray(pos_of(t) + Vector3(0, 0.4, 0), UI.GREEN, "rise", 36)
				_ring(pos_of(t), UI.GREEN, 1.2)
			"shield":
				_bubble(t, Color("#7FD8FF"))
			"hex":
				_spiral(t, Color("#B44DFF"), false)
				_spray(_chest(t) + Vector3(0, 0.8, 0), Color("#B44DFF"), "fall", 24)
			_:
				_spiral(t, UI.GOLD, true)
	await _wait(0.35)
