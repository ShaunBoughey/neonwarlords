# Render a warlord card portrait from its finished .blend (run headless):
#   blender -b assets/source/models/<id>.blend --python tools/blender/render_portrait.py -- \
#       assets/portraits/<tpl_id>.png <syndicate hex colour, e.g. ff5a36> [yaw_deg=25] [frame=60]
# Head-and-shoulders, three-quarter view, idle pose, rim-lit in the syndicate colour, composited on the
# same dark syndicate backdrop the procedural portraits use. 512x640 PNG.
import bpy, sys, math, os, numpy as np
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT = os.path.abspath(argv[0]); SYN = argv[1].lstrip("#")
YAW = float(argv[2]) if len(argv) > 2 else 25.0
FRAME = int(argv[3]) if len(argv) > 3 else 60
W, H = 512, 640
sc_col = tuple(int(SYN[i:i + 2], 16) / 255.0 for i in (0, 2, 4))

scene = bpy.context.scene
arm = next(o for o in scene.objects if o.type == "ARMATURE")
meshes = [o for o in scene.objects if o.type == "MESH" and o.parent == arm and o.visible_get()]
for c in bpy.data.collections:                       # cloth helpers etc. stay out of the picture
    if c.name == "cape_sim":
        for o in c.objects: o.hide_render = True
for o in scene.objects:
    if o.type in ("LIGHT",): o.hide_render = True
    if o.type == "MESH" and o not in meshes: o.hide_render = True
ad = arm.animation_data
if ad and "idle" in bpy.data.actions:
    ad.action = bpy.data.actions["idle"]
    try: ad.action_slot = ad.action.slots[0]
    except Exception: pass
scene.frame_set(FRAME)

# framing from the evaluated mesh: top of the head-gear down to mid-chest
dg = bpy.context.evaluated_depsgraph_get()
pts = []
for o in meshes:
    e = o.evaluated_get(dg); m = e.to_mesh()
    mw = o.matrix_world
    pts += [mw @ v.co for v in m.vertices]
    e.to_mesh_clear()
P = np.array([p[:] for p in pts])
head = arm.matrix_world @ arm.pose.bones["Head"].head
top = P[:, 2].max()
bottom = head.z - 0.62
region_h = (top - bottom) * 1.06
zc = bottom + region_h / 2 + 0.01

cam_data = bpy.data.cameras.new("PortraitCam"); cam_data.lens = 85; cam_data.sensor_fit = "VERTICAL"; cam_data.sensor_height = 24
cam = bpy.data.objects.new("PortraitCam", cam_data); scene.collection.objects.link(cam); scene.camera = cam
fov = 2 * math.atan(12 / 85)
dist = region_h / 2 / math.tan(fov / 2)
a = math.radians(YAW)
target = Vector((head.x, head.y, zc))
cam.location = target + Vector((math.sin(a) * dist, -math.cos(a) * dist, 0.05))
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()

def light(name, kind, energy, color, loc, size=1.0):
    ld = bpy.data.lights.new(name, kind); ld.energy = energy; ld.color = color
    if kind == "AREA": ld.size = size
    lo = bpy.data.objects.new(name, ld); scene.collection.objects.link(lo)
    lo.location = target + Vector(loc)
    lo.rotation_euler = (target - lo.location).to_track_quat("-Z", "Y").to_euler()
light("key", "AREA", 170, (1.0, 0.95, 0.9), (-1.2 + math.sin(a) * 1.5, -2.2, 0.9), 1.4)
light("fill", "AREA", 45, (0.75, 0.82, 1.0), (1.8, -1.6, -0.2), 2.0)
light("rimL", "AREA", 700, sc_col, (-1.4, 1.6, 0.6), 0.8)
light("rimR", "AREA", 700, sc_col, (1.4, 1.6, 0.6), 0.8)
light("top", "AREA", 160, sc_col, (0, 0.6, 1.8), 1.0)

scene.render.engine = "BLENDER_EEVEE"
scene.render.resolution_x, scene.render.resolution_y, scene.render.resolution_percentage = W, H, 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"; scene.render.image_settings.color_mode = "RGBA"
try: scene.view_settings.view_transform = "Standard"
except Exception: pass
if scene.world is None: scene.world = bpy.data.worlds.new("w")
scene.world.use_nodes = True
bg = scene.world.node_tree.nodes.get("Background")
if bg: bg.inputs[0].default_value = (0.02, 0.025, 0.04, 1); bg.inputs[1].default_value = 0.6
tmp = OUT + ".raw.png"
scene.render.filepath = tmp
bpy.ops.render.render(write_still=True)

# composite onto the procedural portrait backdrop: syndicate glow at the top fading to void, faint hatching
img = bpy.data.images.load(tmp); px = np.array(img.pixels[:], np.float32).reshape(H, W, 4)[::-1]     # top-down
sc = np.array(sc_col); top_c = sc * 0.55; void = np.array([0x06, 0x08, 0x0F]) / 255.0
yy = np.linspace(0, 1, H)[:, None, None]
bgc = top_c * (1 - np.clip(yy * 1.25, 0, 1)) + void * np.clip(yy * 1.25, 0, 1)
bgc = np.broadcast_to(bgc, (H, W, 3)).copy()
X, Y = np.meshgrid(np.arange(W), np.arange(H))
hatch = (((X + Y * 0.5) % 40) < 1.5)[..., None]
bgc = np.where(hatch, bgc * 0.94 + sc * 0.06, bgc)
glow = np.exp(-(((X - W * 0.5) / (W * 0.45)) ** 2 + ((Y - H * 0.3) / (H * 0.35)) ** 2))[..., None]
bgc = bgc + sc * 0.18 * glow
al = px[..., 3:4]
out = np.concatenate([np.clip(px[..., :3] * al + bgc * (1 - al), 0, 1), np.ones((H, W, 1))], -1)
o = bpy.data.images.new("portrait", W, H, alpha=True); o.pixels[:] = out[::-1].ravel()
o.filepath_raw = OUT; o.file_format = "PNG"; o.save()
os.remove(tmp)
print("PORTRAIT", OUT)
