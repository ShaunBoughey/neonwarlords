# Deacon Chainz - bespoke model from the concept turnaround (same rig + animations as make_models.py).
# Run:  blender -b --factory-startup --python make_deacon.py -- <out_dir>
import bpy, sys, os, math, importlib.util
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.path.join(HERE, "out")
sys.argv = [sys.argv[0], "--", OUT, "noop"]  # keep make_models from building everything on import
spec = importlib.util.spec_from_file_location("mm", os.path.join(HERE, "make_models.py"))
mm = importlib.util.module_from_spec(spec)
mm.__dict__["__deacon_import__"] = True
src = open(os.path.join(HERE, "make_models.py"), encoding="utf-8").read()
src = src[: src.index('for cls in ("armour", "firepower", "modder", "hacker"):')]
exec(compile(src, "make_models.py", "exec"), mm.__dict__)

part, mat, PARTS = mm.part, mm.mat, mm.PARTS

def bind(o, bone):
    vg = o.vertex_groups.new(name=bone)
    vg.add(list(range(len(o.data.vertices))), 1.0, "REPLACE")
    PARTS.append(o)
    return o

def text_part(text, bone, loc, size, material):
    bpy.ops.object.text_add(location=loc, rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object
    o.data.body = text
    o.data.align_x = "CENTER"
    o.data.align_y = "CENTER"
    o.data.size = size
    o.data.extrude = 0.004
    bpy.ops.object.convert(target="MESH")
    o = bpy.context.active_object
    o.data.materials.clear()
    o.data.materials.append(material)
    return bind(o, bone)

def taper_top(o, fx, fy):
    zmax = max(v.co.z for v in o.data.vertices)
    for v in o.data.vertices:
        if abs(v.co.z - zmax) < 1e-4:
            v.co.x *= fx
            v.co.y *= fy

def chain(bone, start, end, links, material, r=0.022):
    for i in range(links):
        t = i / max(1, links - 1)
        p = Vector(start).lerp(Vector(end), t)
        rot = (math.pi / 2, 0, 0) if i % 2 == 0 else (math.pi / 2, math.pi / 2, 0)
        bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=r * 0.28, major_segments=8, minor_segments=4, location=p, rotation=rot)
        o = bpy.context.active_object
        o.data.materials.append(material)
        bind(o, bone)

def padlock(bone, loc, M):
    part("box", bone, loc, (0.05, 0.025, 0.06), M["Gold"])
    bpy.ops.mesh.primitive_torus_add(major_radius=0.02, minor_radius=0.006, major_segments=10, minor_segments=4,
                                     location=(loc[0], loc[1], loc[2] + 0.04), rotation=(math.pi / 2, 0, 0))
    o = bpy.context.active_object
    o.data.materials.append(M["Plate"])
    bind(o, bone)

def build():
    mm.reset()
    PARTS.clear()
    M = mm.materials()
    M["Cloth"] = mat("Cloth", (0.42, 0.04, 0.05), metal=0.0, rough=0.75)
    M["Gold"] = mat("Gold", (0.95, 0.68, 0.18), metal=1.0, rough=0.25)
    M["Plate"] = mat("Plate", (0.62, 0.64, 0.68), metal=1.0, rough=0.28)
    M["Leather"] = mat("Leather", (0.28, 0.17, 0.09), metal=0.0, rough=0.8)
    M["Ink"] = mat("Ink", (0.05, 0.04, 0.04), metal=0.0, rough=0.9)
    M["Neon"] = mat("Neon", (1.0, 0.75, 0.25), emit=6.0)
    rig = mm.make_armature()
    # legs: dark trousers, plate cuisses, knee cops, greaves and sabatons with leather straps
    for s, x in (("L", 0.11), ("R", -0.11)):
        part("cyl", "thigh." + s, (x, 0, 0.73), (0.085, 0.085, 0.44), M["Body"])
        part("box", "thigh." + s, (x, -0.06, 0.72), (0.14, 0.05, 0.34), M["Plate"])
        part("sphere", "shin." + s, (x, -0.05, 0.52), (0.08, 0.06, 0.07), M["Plate"], segs=8)
        part("cyl", "shin." + s, (x, 0, 0.3), (0.08, 0.08, 0.42), M["Plate"])
        part("box", "shin." + s, (x, -0.05, 0.05), (0.14, 0.27, 0.1), M["Plate"])
        part("box", "shin." + s, (x, -0.03, 0.11), (0.15, 0.06, 0.03), M["Leather"])
    # torso plate engraved TRUTH / FAITH / LOYALTY
    part("box", "hips", (0, 0, 1.0), (0.38, 0.24, 0.2), M["Body"])
    part("box", "spine", (0, 0, 1.28), (0.44, 0.27, 0.4), M["Plate"])
    part("box", "spine", (0, -0.12, 1.28), (0.34, 0.06, 0.3), M["Plate"])
    text_part("TRUTH", "spine", (0, -0.155, 1.355), 0.055, M["Ink"])
    text_part("FAITH", "spine", (0, -0.155, 1.285), 0.055, M["Ink"])
    text_part("LOYALTY", "spine", (0, -0.155, 1.215), 0.05, M["Ink"])
    # belt, buckle, pouch, hanging chain and padlock
    part("box", "hips", (0, 0, 1.08), (0.4, 0.27, 0.05), M["Leather"])
    part("box", "hips", (0, -0.14, 1.08), (0.06, 0.02, 0.05), M["Gold"])
    part("box", "hips", (0.15, -0.13, 1.0), (0.07, 0.04, 0.1), M["Leather"])
    chain("hips", (-0.08, -0.14, 1.05), (-0.1, -0.14, 0.82), 6, M["Plate"])
    padlock("hips", (-0.1, -0.14, 0.78), M)
    chain("spine", (0.15, -0.17, 1.42), (-0.15, -0.17, 1.42), 8, M["Gold"], r=0.016)
    # red cope: open front panels with gold trim, back panel with orphrey, capelet and hood
    for x in (1, -1):
        part("box", "spine", (0.215 * x, -0.04, 0.86), (0.12, 0.06, 1.22), M["Cloth"])
        part("box", "spine", (0.155 * x, -0.075, 0.86), (0.03, 0.07, 1.22), M["Gold"])
        part("box", "spine", (0.215 * x, -0.05, 0.27), (0.13, 0.07, 0.035), M["Gold"])
    part("box", "spine", (0, 0.12, 0.86), (0.52, 0.06, 1.24), M["Cloth"])
    part("box", "spine", (0, 0.155, 1.2), (0.26, 0.02, 0.3), M["Gold"])
    part("box", "spine", (0, 0.12, 0.25), (0.53, 0.07, 0.035), M["Gold"])
    cap = part("cyl", "spine", (0, 0.02, 1.47), (0.34, 0.24, 0.08), M["Cloth"], segs=14)
    taper_top(cap, 0.6, 0.65)
    part("cyl", "spine", (0, 0.02, 1.43), (0.345, 0.245, 0.015), M["Gold"], segs=14)
    part("sphere", "head", (0, 0.06, 1.6), (0.17, 0.15, 0.17), M["Cloth"], segs=10)
    # arms: plate, couters, gauntlets, wrist chains with padlocks
    for s, x in (("L", 1), ("R", -1)):
        part("cyl", "upper_arm." + s, (0.26 * x, 0, 1.28), (0.07, 0.07, 0.3), M["Plate"])
        part("sphere", "upper_arm." + s, (0.27 * x, 0, 1.13), (0.075, 0.075, 0.06), M["Plate"], segs=8)
        part("cyl", "lower_arm." + s, (0.275 * x, 0, 1.0), (0.065, 0.065, 0.28), M["Plate"])
        part("box", "lower_arm." + s, (0.28 * x, 0, 0.82), (0.09, 0.08, 0.11), M["Plate"])
        chain("lower_arm." + s, (0.28 * x - 0.06, -0.06, 0.9), (0.28 * x + 0.06, -0.06, 0.9), 4, M["Plate"], r=0.02)
        padlock("lower_arm." + s, (0.28 * x, -0.07, 0.86), M)
        part("sphere", "upper_arm." + s, (0.27 * x, 0, 1.43), (0.12, 0.13, 0.08), M["Cloth"], segs=8)
    # golden mask with curls, beard and a glowing eye slit
    part("sphere", "head", (0, -0.02, 1.6), (0.12, 0.12, 0.14), M["Gold"], segs=12)
    part("cone", "head", (0, -0.07, 1.47), (0.09, 0.06, 0.13), M["Gold"], rot=(math.pi, 0, 0), segs=8)
    for x in (1, -1):
        part("sphere", "head", (0.11 * x, 0.0, 1.6), (0.045, 0.05, 0.07), M["Gold"], segs=6)
    part("box", "head", (0, -0.115, 1.62), (0.13, 0.015, 0.018), M["Neon"])
    # mitre: tall, tapered, gold band, glowing cross
    m1 = part("box", "head", (0, 0, 1.92), (0.24, 0.2, 0.4), M["Cloth"])
    taper_top(m1, 0.35, 0.55)
    part("box", "head", (0, 0, 1.73), (0.25, 0.21, 0.04), M["Gold"])
    part("box", "head", (0, -0.105, 1.9), (0.02, 0.01, 0.26), M["Gold"])
    part("box", "head", (0, -0.112, 1.93), (0.03, 0.012, 0.18), M["Neon"])
    part("box", "head", (0, -0.112, 1.97), (0.11, 0.012, 0.03), M["Neon"])
    # weapon: chain flail with a spiked censer
    chain("lower_arm.R", (-0.28, -0.05, 0.8), (-0.3, -0.25, 0.45), 8, M["Plate"], r=0.024)
    part("sphere", "lower_arm.R", (-0.3, -0.28, 0.38), (0.09, 0.09, 0.09), M["Gold"], segs=10)
    for d, rot in (((1, 0, 0), (0, math.pi / 2, 0)), ((-1, 0, 0), (0, -math.pi / 2, 0)), ((0, 1, 0), (-math.pi / 2, 0, 0)),
                   ((0, -1, 0), (math.pi / 2, 0, 0)), ((0, 0, -1), (math.pi, 0, 0))):
        part("cone", "lower_arm.R", (-0.3 + d[0] * 0.1, -0.28 + d[1] * 0.1, 0.38 + d[2] * 0.1), (0.025, 0.025, 0.06), M["Plate"], rot=rot, segs=6)
    bpy.ops.object.select_all(action="DESELECT")
    for o in PARTS:
        o.select_set(True)
    bpy.context.view_layer.objects.active = PARTS[0]
    bpy.ops.object.join()
    mesh = bpy.context.active_object
    mesh.name = "DeaconChainz"
    bpy.ops.object.shade_flat()
    mod = mesh.modifiers.new("Armature", "ARMATURE")
    mod.object = rig
    mesh.parent = rig
    mm.animate(rig, "armour")
    return rig

rig = build()
mm.export(os.path.join(OUT, "warlord_deacon.glb"))
rig.animation_data.action = None
for tr in rig.animation_data.nla_tracks:
    tr.mute = True
for pb in rig.pose.bones:
    pb.location = (0, 0, 0)
    pb.rotation_euler = (0, 0, 0)
bpy.context.scene.frame_set(1)
# preview render for review
cam_data = bpy.data.cameras.new("Cam")
cam = bpy.data.objects.new("Cam", cam_data)
bpy.context.collection.objects.link(cam)
cam.location = (1.6, -3.4, 1.5)
cam.rotation_euler = (math.radians(84), 0, math.radians(25))
bpy.context.scene.camera = cam
for loc, e in (((2, -3, 3), 900), ((-2, -2, 2), 400), ((0, 3, 3), 600)):
    ld = bpy.data.lights.new("L", "POINT")
    ld.energy = e
    lo = bpy.data.objects.new("L", ld)
    lo.location = loc
    bpy.context.collection.objects.link(lo)
sc = bpy.context.scene
sc.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_EEVEE_NEXT"
sc.render.resolution_x = 640
sc.render.resolution_y = 800
sc.world = bpy.data.worlds.new("W")
sc.world.color = (0.35, 0.33, 0.4)
sc.render.filepath = os.path.join(OUT, "..", "..", "tools", "blender", "deacon_preview.png")
bpy.ops.render.render(write_still=True)
print("EXPORTED deacon")
