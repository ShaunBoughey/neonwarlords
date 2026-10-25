# Neon Warlords - procedural low-poly character + arena generator.
# Run:  blender -b --factory-startup --python make_models.py -- <out_dir>
# Exports one rigged, animated GLB per class and an arena GLB.
import bpy, bmesh, sys, math, os
from mathutils import Vector

OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(os.path.dirname(__file__), "out")
os.makedirs(OUT, exist_ok=True)
FPS = 30

def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.scene.render.fps = FPS

# ------------------------------------------------------------------ materials
def mat(name, color, emit=0.0, metal=0.2, rough=0.5):
    m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Roughness"].default_value = rough
    if emit > 0:
        bsdf.inputs["Emission Color"].default_value = (*color, 1)
        bsdf.inputs["Emission Strength"].default_value = emit
    return m

# Godot recolours "Accent" and "Neon" per syndicate at runtime.
def materials():
    return {
        "Body": mat("Body", (0.08, 0.08, 0.11), metal=0.4, rough=0.55),
        "Skin": mat("Skin", (0.55, 0.42, 0.36), metal=0.0, rough=0.7),
        "Accent": mat("Accent", (0.9, 0.3, 0.2), metal=0.3, rough=0.45),
        "Metal": mat("Metal", (0.45, 0.47, 0.52), metal=0.9, rough=0.3),
        "Neon": mat("Neon", (0.2, 0.9, 1.0), emit=6.0),
    }

# ------------------------------------------------------------------ armature
BONES = {
    # name: (head, tail, parent)
    "root": ((0, 0, 0), (0, 0.2, 0), None),
    "hips": ((0, 0, 0.95), (0, 0, 1.1), "root"),
    "spine": ((0, 0, 1.1), (0, 0, 1.45), "hips"),
    "head": ((0, 0, 1.47), (0, 0, 1.75), "spine"),
    "upper_arm.L": ((0.25, 0, 1.42), (0.27, 0, 1.13), "spine"),
    "lower_arm.L": ((0.27, 0, 1.13), (0.28, 0, 0.86), "upper_arm.L"),
    "upper_arm.R": ((-0.25, 0, 1.42), (-0.27, 0, 1.13), "spine"),
    "lower_arm.R": ((-0.27, 0, 1.13), (-0.28, 0, 0.86), "upper_arm.R"),
    "thigh.L": ((0.11, 0, 0.95), (0.11, 0, 0.52), "hips"),
    "shin.L": ((0.11, 0, 0.52), (0.11, 0, 0.08), "thigh.L"),
    "thigh.R": ((-0.11, 0, 0.95), (-0.11, 0, 0.52), "hips"),
    "shin.R": ((-0.11, 0, 0.52), (-0.11, 0, 0.08), "thigh.R"),
}

def make_armature():
    arm_data = bpy.data.armatures.new("Rig")
    rig = bpy.data.objects.new("Rig", arm_data)
    bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for name, (h, t, p) in BONES.items():
        b = arm_data.edit_bones.new(name)
        b.head = Vector(h)
        b.tail = Vector(t)
        b.roll = 0
        if p:
            b.parent = arm_data.edit_bones[p]
            b.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
    return rig

# ------------------------------------------------------------------ mesh parts
PARTS = []

def part(kind, bone, loc, size, material, rot=(0, 0, 0), segs=10):
    if kind == "box":
        bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
        o = bpy.context.active_object
        o.scale = size
    elif kind == "cyl":
        bpy.ops.mesh.primitive_cylinder_add(vertices=segs, radius=1, depth=1, location=loc, rotation=rot)
        o = bpy.context.active_object
        o.scale = size
    elif kind == "sphere":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=max(4, segs // 2), radius=1, location=loc, rotation=rot)
        o = bpy.context.active_object
        o.scale = size
    elif kind == "cone":
        bpy.ops.mesh.primitive_cone_add(vertices=segs, radius1=1, radius2=0.0, depth=1, location=loc, rotation=rot)
        o = bpy.context.active_object
        o.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    o.data.materials.append(material)
    vg = o.vertex_groups.new(name=bone)
    vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    PARTS.append(o)
    return o

def body(M, cls):
    bulk = {"armour": 1.25, "firepower": 1.0, "modder": 0.95, "hacker": 0.9}[cls]
    # legs
    for s, x in (("L", 0.11), ("R", -0.11)):
        part("cyl", "thigh." + s, (x, 0, 0.73), (0.075 * bulk, 0.075 * bulk, 0.44), M["Body"])
        part("cyl", "shin." + s, (x, 0, 0.3), (0.065 * bulk, 0.065 * bulk, 0.44), M["Body"])
        part("box", "shin." + s, (x, -0.04, 0.05), (0.13 * bulk, 0.24, 0.1), M["Metal"])
        part("box", "shin." + s, (x, -0.075, 0.33), (0.07, 0.03, 0.18), M["Neon"])
    # pelvis + torso
    part("box", "hips", (0, 0, 1.0), (0.36 * bulk, 0.22, 0.2), M["Body"])
    part("box", "spine", (0, 0, 1.28), (0.46 * bulk, 0.26 * bulk, 0.38), M["Accent"])
    part("box", "spine", (0, -0.14 * bulk, 1.3), (0.06, 0.02, 0.3), M["Neon"])
    part("box", "hips", (0, -0.12, 1.07), (0.38 * bulk, 0.02, 0.04), M["Neon"])
    # arms
    for s, x in (("L", 1), ("R", -1)):
        part("cyl", "upper_arm." + s, (0.26 * x, 0, 1.28), (0.06 * bulk, 0.06 * bulk, 0.3), M["Body"])
        part("cyl", "lower_arm." + s, (0.275 * x, 0, 1.0), (0.055 * bulk, 0.055 * bulk, 0.28), M["Metal"])
        part("sphere", "lower_arm." + s, (0.28 * x, 0, 0.83), (0.065, 0.065, 0.065), M["Skin"], segs=8)
        part("sphere", "upper_arm." + s, (0.26 * x, 0, 1.42), (0.1 * bulk, 0.1 * bulk, 0.09), M["Accent"], segs=8)
    # head
    part("sphere", "head", (0, 0, 1.6), (0.13, 0.14, 0.15), M["Skin"], segs=12)
    part("box", "head", (0, -0.11, 1.62), (0.2, 0.06, 0.05), M["Neon"])  # visor
    part("cyl", "spine", (0, 0, 1.49), (0.06, 0.06, 0.06), M["Body"])
    return bulk

def gear(M, cls, bulk):
    if cls == "armour":
        for x in (1, -1):
            part("box", "spine", (0.3 * x * bulk, 0, 1.47), (0.24, 0.3, 0.12), M["Metal"], rot=(0, 0.25 * x, 0))
        part("box", "spine", (0, -0.15 * bulk, 1.28), (0.4 * bulk, 0.04, 0.32), M["Metal"])
        part("box", "lower_arm.L", (0.36, -0.04, 1.0), (0.05, 0.42, 0.55), M["Accent"])          # shield
        part("box", "lower_arm.L", (0.39, -0.04, 1.0), (0.02, 0.3, 0.06), M["Neon"])
        part("cyl", "lower_arm.R", (-0.28, -0.25, 0.83), (0.025, 0.025, 0.55), M["Metal"], rot=(math.pi / 2, 0, 0))
        part("box", "lower_arm.R", (-0.28, -0.55, 0.83), (0.16, 0.14, 0.2), M["Metal"])           # hammer head
        part("box", "lower_arm.R", (-0.28, -0.55, 0.83), (0.17, 0.15, 0.04), M["Neon"])
        part("cyl", "head", (0, 0, 1.66), (0.16, 0.16, 0.14), M["Metal"])                         # helmet
    elif cls == "firepower":
        part("box", "lower_arm.R", (-0.28, -0.3, 0.86), (0.06, 0.6, 0.1), M["Metal"])             # rifle body
        part("cyl", "lower_arm.R", (-0.28, -0.68, 0.88), (0.025, 0.025, 0.3), M["Body"], rot=(math.pi / 2, 0, 0))
        part("box", "lower_arm.R", (-0.28, -0.3, 0.92), (0.03, 0.4, 0.02), M["Neon"])
        part("box", "spine", (0, 0, 1.3), (0.5 * bulk, 0.3, 0.06), M["Metal"], rot=(0, 0.6, 0))  # bandolier
        part("box", "head", (0, 0.02, 1.76), (0.26, 0.04, 0.04), M["Accent"])                     # mohawk-ish crest
        part("box", "head", (0, 0.02, 1.76), (0.04, 0.26, 0.08), M["Accent"])
    elif cls == "modder":
        part("box", "spine", (0, 0.2, 1.3), (0.34, 0.16, 0.4), M["Metal"])                       # backpack
        part("sphere", "spine", (0, 0.22, 1.56), (0.09, 0.09, 0.09), M["Neon"], segs=10)        # orb
        part("cyl", "spine", (0.12, 0.24, 1.62), (0.01, 0.01, 0.36), M["Metal"])                 # antenna
        part("cyl", "lower_arm.R", (-0.28, -0.02, 0.85), (0.02, 0.02, 1.2), M["Metal"])          # staff
        part("sphere", "lower_arm.R", (-0.28, -0.02, 1.47), (0.07, 0.07, 0.07), M["Neon"], segs=8)
        part("cone", "hips", (0, 0, 0.8), (0.32, 0.26, 0.45), M["Accent"])                       # robe skirt
    elif cls == "hacker":
        part("cone", "hips", (0, 0.02, 0.72), (0.3, 0.26, 0.55), M["Body"])                      # long coat
        part("box", "head", (0, 0.03, 1.66), (0.3, 0.3, 0.2), M["Accent"])                       # hood
        part("box", "head", (0, -0.13, 1.6), (0.24, 0.04, 0.08), M["Neon"])                      # big visor
        part("box", "lower_arm.L", (0.28, -0.06, 0.95), (0.1, 0.14, 0.04), M["Neon"])            # wrist deck
        part("box", "lower_arm.R", (-0.28, -0.12, 0.84), (0.04, 0.2, 0.08), M["Metal"])          # pistol
        for i, x in enumerate((0.35, -0.35)):
            part("box", "spine", (x, -0.1, 1.72), (0.07, 0.07, 0.07), M["Neon"], rot=(0.6, 0.6, 0))  # holo cubes

def build_character(cls):
    reset()
    PARTS.clear()
    M = materials()
    rig = make_armature()
    bulk = body(M, cls)
    gear(M, cls, bulk)
    bpy.ops.object.select_all(action="DESELECT")
    for o in PARTS:
        o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    mesh = bpy.context.active_object
    mesh.name = "Warlord"
    bpy.ops.object.shade_flat()
    mod = mesh.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    mesh.parent = rig
    animate(rig, cls)
    return rig

# ------------------------------------------------------------------ animation
def key(rig, frame, poses, root_loc=None, root_rot=None):
    for bone, rot in poses.items():
        pb = rig.pose.bones[bone]
        pb.rotation_euler = rot
        pb.keyframe_insert("rotation_euler", frame=frame)
    if root_loc is not None:
        rig.pose.bones["root"].location = root_loc
        rig.pose.bones["root"].keyframe_insert("location", frame=frame)
    if root_rot is not None:
        rig.pose.bones["root"].rotation_euler = root_rot
        rig.pose.bones["root"].keyframe_insert("rotation_euler", frame=frame)

ALL = [b for b in BONES if b != "root"]

def neutral():
    return {b: (0, 0, 0) for b in ALL}

def pose(**kw):
    p = neutral()
    for k, v in kw.items():
        p[k.replace("_L", ".L").replace("_R", ".R")] = v
    return p

def new_action(rig, name):
    act = bpy.data.actions.new(name)
    act.use_fake_user = True
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = act
    for pb in rig.pose.bones:
        pb.rotation_euler = (0, 0, 0)
        pb.location = (0, 0, 0)
    return act

def push(rig, act):
    track = rig.animation_data.nla_tracks.new()
    track.name = act.name
    track.strips.new(act.name, int(act.frame_range[0]), act)
    track.mute = True
    rig.animation_data.action = None

def animate(rig, cls):
    weapon_ranged = cls in ("firepower", "hacker")
    # idle
    a = new_action(rig, "idle")
    key(rig, 1, pose(upper_arm_L=(0.05, 0, 0.12), upper_arm_R=(0.05, 0, -0.12), lower_arm_R=(-0.4, 0, 0)), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 20, pose(spine=(0.06, 0, 0), upper_arm_L=(0.1, 0, 0.14), upper_arm_R=(0.1, 0, -0.14), lower_arm_R=(-0.5, 0, 0), head=(-0.05, 0, 0)), root_loc=(0, 0, -0.025))
    key(rig, 40, pose(upper_arm_L=(0.05, 0, 0.12), upper_arm_R=(0.05, 0, -0.12), lower_arm_R=(-0.4, 0, 0)), root_loc=(0, 0, 0))
    push(rig, a)
    # run
    a = new_action(rig, "run")
    for f, s in ((1, 1), (10, -1), (20, 1)):
        key(rig, f, pose(spine=(-0.25, 0, 0), thigh_L=(-0.8 * s, 0, 0), shin_L=(0.6 if s < 0 else 0.2, 0, 0), thigh_R=(0.8 * s, 0, 0), shin_R=(0.6 if s > 0 else 0.2, 0, 0),
                         upper_arm_L=(0.7 * s, 0, 0.1), upper_arm_R=(-0.7 * s, 0, -0.1), lower_arm_L=(-0.6, 0, 0), lower_arm_R=(-0.6, 0, 0)), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 5, {}, root_loc=(0, 0, 0.06))
    key(rig, 15, {}, root_loc=(0, 0, 0.06))
    push(rig, a)
    # melee attack
    a = new_action(rig, "attack")
    key(rig, 1, neutral(), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 8, pose(spine=(0.15, 0, 0.5), upper_arm_R=(-2.6, 0, -0.3), lower_arm_R=(-0.8, 0, 0), thigh_L=(-0.4, 0, 0), thigh_R=(0.3, 0, 0)))
    key(rig, 13, pose(spine=(-0.35, 0, -0.5), upper_arm_R=(-0.5, 0, 0.2), lower_arm_R=(-0.1, 0, 0), thigh_L=(-0.6, 0, 0), shin_L=(0.3, 0, 0), thigh_R=(0.4, 0, 0)), root_loc=(0, -0.15, -0.05))
    key(rig, 24, neutral(), root_loc=(0, 0, 0))
    push(rig, a)
    # shoot / ranged
    a = new_action(rig, "shoot")
    aim = pose(upper_arm_R=(-1.5, 0, 0), lower_arm_R=(-0.05, 0, 0), upper_arm_L=(-1.3, 0, -0.5), lower_arm_L=(-0.6, 0, 0), spine=(0, 0, 0.25), head=(0, 0, -0.2))
    key(rig, 1, neutral(), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 7, aim)
    recoil = dict(aim)
    recoil["upper_arm.R"] = (-1.85, 0, 0)
    recoil["spine"] = (0.12, 0, 0.25)
    key(rig, 10, recoil, root_loc=(0, 0.06, 0))
    key(rig, 16, aim, root_loc=(0, 0, 0))
    key(rig, 26, neutral())
    push(rig, a)
    # cast (buff / heal / debuff)
    a = new_action(rig, "cast")
    key(rig, 1, neutral(), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    up = pose(upper_arm_L=(-2.7, 0, 0.4), upper_arm_R=(-2.7, 0, -0.4), lower_arm_L=(-0.3, 0, 0), lower_arm_R=(-0.3, 0, 0), spine=(0.2, 0, 0), head=(0.3, 0, 0))
    key(rig, 12, up, root_loc=(0, 0, 0.12))
    key(rig, 18, up, root_loc=(0, 0, 0.12))
    key(rig, 30, neutral(), root_loc=(0, 0, 0))
    push(rig, a)
    # hit
    a = new_action(rig, "hit")
    key(rig, 1, neutral(), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 4, pose(spine=(0.45, 0, 0.1), head=(0.4, 0, 0), upper_arm_L=(0.5, 0, 0.4), upper_arm_R=(0.5, 0, -0.4)), root_loc=(0, 0.18, 0))
    key(rig, 14, neutral(), root_loc=(0, 0, 0))
    push(rig, a)
    # death
    a = new_action(rig, "death")
    key(rig, 1, neutral(), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 10, pose(spine=(0.4, 0, 0), head=(0.5, 0, 0), thigh_L=(-0.4, 0, 0), shin_L=(0.9, 0, 0)), root_loc=(0, 0.2, -0.25))
    key(rig, 24, pose(spine=(0.2, 0, 0), upper_arm_L=(-0.4, 0, 0.9), upper_arm_R=(-0.4, 0, -0.9)), root_loc=(0, 0.75, 0.12), root_rot=(1.5, 0, 0))
    key(rig, 36, pose(spine=(0.1, 0, 0), upper_arm_L=(-0.3, 0, 1.0), upper_arm_R=(-0.3, 0, -1.0)), root_loc=(0, 0.8, 0.12), root_rot=(1.57, 0, 0))
    push(rig, a)
    # victory
    a = new_action(rig, "victory")
    key(rig, 1, neutral(), root_loc=(0, 0, 0), root_rot=(0, 0, 0))
    key(rig, 12, pose(upper_arm_R=(-2.9, 0, -0.2), lower_arm_R=(-0.2, 0, 0), upper_arm_L=(0.2, 0, 0.5), spine=(-0.15, 0, 0)), root_loc=(0, 0, 0.1))
    key(rig, 30, pose(upper_arm_R=(-2.9, 0, -0.2), lower_arm_R=(-0.2, 0, 0), upper_arm_L=(0.2, 0, 0.5), spine=(-0.15, 0, 0)), root_loc=(0, 0, 0))
    push(rig, a)

def export(path):
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", export_animations=True, export_animation_mode="NLA_TRACKS",
                              export_apply=False, export_yup=True, export_skins=True, export_materials="EXPORT")

# ------------------------------------------------------------------ arena
def box(loc, size, material, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    o.data.materials.append(material)
    return o

def build_arena():
    reset()
    import random
    random.seed(7)
    asphalt = mat("Asphalt", (0.05, 0.05, 0.07), metal=0.1, rough=0.35)
    wall = mat("Wall", (0.07, 0.07, 0.1), metal=0.2, rough=0.6)
    trim = mat("Trim", (0.15, 0.15, 0.2), metal=0.7, rough=0.3)
    cyan = mat("NeonCyan", (0.1, 0.85, 1.0), emit=8)
    pink = mat("NeonPink", (1.0, 0.15, 0.55), emit=8)
    purple = mat("NeonPurple", (0.6, 0.3, 1.0), emit=7)
    yellow = mat("NeonYellow", (1.0, 0.8, 0.2), emit=6)
    window = mat("Window", (0.9, 0.7, 0.4), emit=2.5)
    # street floor with lane lines
    box((0, 0, -0.05), (40, 26, 0.1), asphalt)
    for x in range(-18, 19, 3):
        box((x, 0, 0.005), (1.4, 0.08, 0.01), yellow)
    for y in (-5.5, 5.5):
        box((0, y, 0.005), (40, 0.06, 0.01), cyan)
    # grid tiles under the fighters
    for x in range(-8, 9, 2):
        box((x, 0, 0.006), (0.03, 9, 0.01), purple)
    # buildings around
    neons = [cyan, pink, purple, yellow]
    for side in (-1, 1):
        x = -20.0
        while x < 20:
            w = random.uniform(2.5, 5.0)
            h = random.uniform(5, 16)
            y = side * random.uniform(11, 13)
            box((x + w / 2, y, h / 2), (w, 3, h), wall)
            box((x + w / 2, y - side * 1.52, h + 0.05), (w, 0.08, 0.1), random.choice(neons))
            for row in range(1, int(h / 1.4)):
                for col in range(int(w / 0.9)):
                    if random.random() < 0.45:
                        box((x + 0.45 + col * 0.9, y - side * 1.51, row * 1.4), (0.45, 0.02, 0.6), window if random.random() < 0.7 else random.choice(neons))
            if random.random() < 0.5:
                sign_h = random.uniform(2.5, h - 1)
                box((x + w / 2, y - side * 1.7, sign_h), (min(w * 0.7, 2.6), 0.08, 0.7), random.choice(neons))
            x += w + random.uniform(0.2, 1.2)
    # back wall far behind enemies and behind camera side
    box((-24, 0, 7), (2, 30, 14), wall)
    box((24, 0, 7), (2, 30, 14), wall)
    # props: crates, barrels, lamps
    for _ in range(14):
        cx = random.uniform(-16, 16)
        cy = random.choice((-1, 1)) * random.uniform(6.5, 9.5)
        s = random.uniform(0.5, 1.0)
        box((cx, cy, s / 2), (s, s, s), trim, rot=(0, 0, random.uniform(0, 1)))
    for x in (-12, -4, 4, 12):
        for y in (-7, 7):
            box((x, y, 2.2), (0.12, 0.12, 4.4), trim)
            box((x, y - math.copysign(0.4, y), 4.4), (0.15, 0.9, 0.1), trim)
            box((x, y - math.copysign(0.8, y), 4.33), (0.3, 0.3, 0.04), cyan if x < 0 else pink)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, "arena.glb"), export_format="GLB", export_materials="EXPORT")

for cls in ("armour", "firepower", "modder", "hacker"):
    build_character(cls)
    export(os.path.join(OUT, "warlord_%s.glb" % cls))
    print("EXPORTED", cls)
build_arena()
print("EXPORTED arena")
