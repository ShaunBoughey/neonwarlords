# Build a separate, cloth-simulated cape for a Meshy warlord (run inside Blender 5.x).
# Consolidated from the steps used for Deacon Chainz; see docs/WARLORD_MODELS.md.
#
#   import cape_build as cb
#   mask = cb.cape_mask(template_body, template_arm)           # template = the WITH-cape Meshy generation
#   cape = cb.grid_from_template(template_body, mask)          # open 25x21 grid + back slit
#   cb.bake_texture(cape, template_body)                       # copy the Meshy cape look onto it
#   cb.fit_to_body(cape, body)                                 # push out of the no-cape body
#   cb.rig(cape, arm)                                          # 10 chains x 4 bones, weights
#   cb.setup_sim(cape, arm)                                    # hidden cloth copy + colliders
#   then cape_bake.bake_action(name) for each of the 8 clips, then export.
#
# Conventions: world space, character faces -Y, feet at z=0, Meshy rig (bones Hips/Spine02/Spine01/Spine,
# Left/RightUpLeg, Left/RightLeg, Left/RightFoot, Left/RightToeBase), armature scale 0.01.
import bpy, bmesh, numpy as np
from mathutils import Vector, Matrix
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

NR, NC = 21, 25                       # cape grid rows x columns (cape_bake.py uses the same)
CH = [0, 3, 6, 9, 11, 13, 15, 18, 21, 24]
RJ = [0, 5, 10, 15, 20]
CY = -0.03                            # body axis y


def _world_rest(obj, arm):
    arm.data.pose_position = "REST"; bpy.context.view_layer.update()
    me = obj.data; n = len(me.vertices)
    co = np.empty(n * 3, np.float32); me.vertices.foreach_get("co", co)
    M = np.array(obj.matrix_world)
    return co.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]


def _seg_dist(P, a, b):
    ab = b - a; t = np.clip(((P - a) @ ab) / (ab @ ab), 0, 1)
    return np.linalg.norm(P - (a + t[:, None] * ab), axis=1)


def cape_mask(body, arm, z_top=1.30):
    """Soft 0..1 cape mask on a WITH-cape Meshy body: skinned to hips/legs, outside the body core,
    grown over cloth-coloured (red/gold) texture, feathered, faded out toward the shoulders."""
    me = body.data; nv = len(me.vertices); P = _world_rest(body, arm)
    H = lambda n: np.array(arm.matrix_world @ arm.data.bones[n].head_local)
    kd = KDTree(nv)
    for i, p in enumerate(P): kd.insert(p, i)
    kd.balance()
    canon = np.arange(nv)
    for i, p in enumerate(P):
        if canon[i] == i:
            for (_, j, _) in kd.find_range(p, 1e-4):
                if j > i: canon[j] = i
    ev = np.empty(len(me.edges) * 2, np.int32); me.edges.foreach_get("vertices", ev)
    ev = canon[ev.reshape(-1, 2)]; ev = ev[ev[:, 0] != ev[:, 1]]
    nbr = [[] for _ in range(nv)]
    for a, b in ev: nbr[a].append(b); nbr[b].append(a)
    img = [n for n in me.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0].image
    T = img.size[0]; B = np.array(img.pixels[:], np.float32).reshape(img.size[1], T, 4)
    lv = np.empty(len(me.loops), np.int32); me.loops.foreach_get("vertex_index", lv)
    uv = np.empty(len(me.loops) * 2, np.float32); me.uv_layers.active.uv.foreach_get("vector", uv)
    vuv = np.zeros((nv, 2), np.float32); vuv[lv] = uv.reshape(-1, 2)
    rgb = B[np.clip((vuv[:, 1] * B.shape[0]).astype(int), 0, B.shape[0] - 1), np.clip((vuv[:, 0] * T).astype(int), 0, T - 1), :3]
    sat = (rgb.max(1) - rgb.min(1)) / (rgb.max(1) + 1e-6)
    cloth = (sat > 0.35) & (rgb.max(1) > 0.12) & (rgb[:, 0] >= rgb[:, 2])
    d_core = np.full(nv, 9.0)
    for a, b, r in (("LeftUpLeg", "LeftLeg", .11), ("LeftLeg", "LeftFoot", .10), ("RightUpLeg", "RightLeg", .11),
                    ("RightLeg", "RightFoot", .10), ("LeftFoot", "LeftToeBase", .09), ("RightFoot", "RightToeBase", .09)):
        d_core = np.minimum(d_core, _seg_dist(P, H(a), H(b)) - r)
    tz = (P[:, 2] > 0.85) & (P[:, 2] < 1.5)
    ell = (np.sqrt((P[:, 0] / 0.2) ** 2 + ((P[:, 1] - CY) / 0.15) ** 2) - 1.0) * 0.15
    d_core = np.where(tz, np.minimum(d_core, ell), d_core)
    low_leg = np.minimum(_seg_dist(P, H("LeftLeg"), H("LeftFoot")), _seg_dist(P, H("RightLeg"), H("RightFoot")))
    feet = (np.minimum(_seg_dist(P, H("LeftFoot"), H("LeftToeBase")), _seg_dist(P, H("RightFoot"), H("RightToeBase"))) < 0.13) & ~cloth
    feet |= (P[:, 2] < 0.32) & (low_leg < 0.135) & ~cloth
    chest = (P[:, 1] < CY - 0.02) & (np.abs(P[:, 0]) < 0.17) & (P[:, 2] > 0.8)
    vg = {g.index: g.name for g in body.vertex_groups}
    allowed = {"Hips", "Spine02", "Spine01", "LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot"}
    dom = np.array([bool(v.groups) and vg[max(v.groups, key=lambda g: g.weight).group] in allowed for v in me.vertices])
    ok = dom & ~feet & ~chest & (P[:, 2] < z_top + 0.04)
    seed = ok & (d_core > 0.035) & (P[:, 2] < z_top)
    grow = ok & ((d_core > -0.01) | cloth)
    grow_c = np.ones(nv, bool); np.logical_and.at(grow_c, canon, grow)
    sel = np.zeros(nv, bool); stack = list(set(int(c) for c in canon[np.nonzero(seed)[0]]))
    for c in stack: sel[c] = True
    while stack:
        x = stack.pop()
        for y in nbr[x]:
            if not sel[y] and grow_c[y]:
                sel[y] = True; stack.append(y)
    fc = sel.astype(np.float32)
    for _ in range(4):
        acc = fc.copy(); cnt = np.ones(nv, np.float32)
        np.add.at(acc, ev[:, 0], fc[ev[:, 1]]); np.add.at(cnt, ev[:, 0], 1)
        np.add.at(acc, ev[:, 1], fc[ev[:, 0]]); np.add.at(cnt, ev[:, 1], 1)
        fc = acc / cnt
    f = fc[canon] * np.clip((z_top - P[:, 2]) / 0.12, 0, 1)
    f[feet | chest | (P[:, 2] < 0.1)] = 0.0
    return f


def grid_from_template(body, mask, arm=None, z_top=1.36, span=127.0, slit=0.4, name="warlord_cape"):
    """Open NR x NC grid following the template cape's outer surface; back slit over the lower `slit` fraction."""
    arm = arm or body.parent
    P = _world_rest(body, arm)
    phi = np.degrees(np.arctan2(P[:, 0], P[:, 1] - CY)); rad = np.hypot(P[:, 0], P[:, 1] - CY)
    cape = mask > 0.5
    PH = np.linspace(-span, span, NC)
    angd = lambda a, b: np.abs(((a - b + 180) % 360) - 180)
    hem = np.array([np.percentile(P[cape & (angd(phi, p) < 6), 2], 1.5) if (cape & (angd(phi, p) < 6)).sum() > 20 else np.nan for p in PH])
    ok = ~np.isnan(hem); hem = np.interp(np.arange(NC), np.nonzero(ok)[0], hem[ok])
    hem = np.convolve(np.pad(hem, 1, mode="edge"), [0.25, 0.5, 0.25], "valid")
    R = np.full((NR, NC), np.nan); Z = np.zeros((NR, NC))
    for i, p in enumerate(PH):
        for j in range(NR):
            z = z_top + j / (NR - 1) * (hem[i] - z_top); Z[j, i] = z
            if z > 1.24: continue
            m = cape & (angd(phi, p) < 7) & (np.abs(P[:, 2] - z) < 0.045)
            if m.sum() >= 6: R[j, i] = np.percentile(rad[m], 95)
    for i in range(NC):
        col = R[:, i]; ok = ~np.isnan(col)
        R[:, i] = np.interp(np.arange(NR), np.nonzero(ok)[0], col[ok]) if ok.sum() >= 2 else (col[ok][0] if ok.any() else 0.25)
        first = next(j for j in range(NR) if Z[j, i] <= 1.24)
        for j in range(first):
            R[j, i] = R[first, i] * (1 - 0.18 * (Z[j, i] - 1.24) / (z_top - 1.24))
    for i in range(NC):                                   # back-slit gap in the samples: don't dip inward
        if abs(PH[i]) < 25:
            for j in range(NR):
                R[j, i] = max(R[j, i], 0.5 * (R[j, max(i - 3, 0)] + R[j, min(i + 3, NC - 1)]))
    for _ in range(4):
        Rp = np.pad(R, 1, mode="edge"); R = (Rp[1:-1, 1:-1] * 4 + Rp[:-2, 1:-1] + Rp[2:, 1:-1] + Rp[1:-1, :-2] + Rp[1:-1, 2:]) / 8
    X = R * np.sin(np.radians(PH))[None]; Y = CY + R * np.cos(np.radians(PH))[None]
    verts = [(float(X[j, i]), float(Y[j, i]), float(Z[j, i])) for j in range(NR) for i in range(NC)]
    faces = [(j * NC + i, j * NC + i + 1, (j + 1) * NC + i + 1, (j + 1) * NC + i) for j in range(NR - 1) for i in range(NC - 1)]
    cm = bpy.data.meshes.new(name + "_mesh"); cm.from_pydata(verts, [], faces)
    uvl = cm.uv_layers.new(name="UVMap")
    lv = np.empty(len(cm.loops), np.int32); cm.loops.foreach_get("vertex_index", lv)
    uvl.uv.foreach_set("vector", np.stack([(lv % NC) / (NC - 1), 1 - (lv // NC) / (NR - 1)], 1).astype(np.float32).ravel())
    cm.polygons.foreach_set("use_smooth", [True] * len(cm.polygons)); cm.update()
    c = cm.polygons[(NR // 2) * (NC - 1) + NC // 2]
    if c.normal.x * c.center.x + c.normal.y * (c.center.y - CY) < 0: cm.flip_normals()
    if slit > 0:
        bm = bmesh.new(); bm.from_mesh(cm); bm.verts.ensure_lookup_table(); mid = NC // 2
        es = [bm.edges.get((bm.verts[j * NC + mid], bm.verts[(j + 1) * NC + mid])) for j in range(int(round(NR * (1 - slit))), NR - 1)]
        bmesh.ops.split_edges(bm, edges=[e for e in es if e]); bm.to_mesh(cm); bm.free()
    ob = bpy.data.objects.new(name, cm); bpy.context.scene.collection.objects.link(ob)
    return ob


def bake_texture(cape, source, size=2048, tuck_band=0.125):
    """Copy the source (template) colour onto the cape via selected-to-active; repaint the band under the mantle."""
    img = bpy.data.images.new(cape.name + "_baseColor", size, size, alpha=False)
    mat = bpy.data.materials.new(cape.name + "_mat"); mat.use_nodes = True; mat.use_backface_culling = False
    nt = mat.node_tree; bsdf = [n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"][0]
    bsdf.inputs["Roughness"].default_value = 0.75; bsdf.inputs["Metallic"].default_value = 0.0
    tex = nt.nodes.new("ShaderNodeTexImage"); tex.image = img; nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    nt.nodes.active = tex
    cape.data.materials.clear(); cape.data.materials.append(mat)
    sc = bpy.context.scene; sc.render.engine = "CYCLES"; sc.cycles.samples = 8
    for o in bpy.context.view_layer.objects: o.select_set(False)
    source.select_set(True); cape.select_set(True); bpy.context.view_layer.objects.active = cape
    bpy.ops.object.bake(type="DIFFUSE", pass_filter={"COLOR"}, use_selected_to_active=True, cage_extrusion=0.05, max_ray_distance=0.15, margin=16)
    W, H = img.size; px = np.array(img.pixels[:], np.float32).reshape(H, W, 4)
    b0 = int(H * (1 - tuck_band)); ref = px[b0 - 50:b0 - 30].mean(0)
    px[b0:] = ref
    for k, r in enumerate(range(b0 - 8, b0)): w = (k + 1) / 9; px[r] = px[r] * (1 - w) + ref * w
    img.pixels[:] = px.ravel(); img.pack()
    return img


def fit_to_body(cape, body, margin=0.015, iters=3):
    dg = bpy.context.evaluated_depsgraph_get(); eb = body.evaluated_get(dg); bme = eb.to_mesh()
    bm = bmesh.new(); bm.from_mesh(bme); bm.transform(body.matrix_world); eb.to_mesh_clear()
    bvh = BVHTree.FromBMesh(bm); bm.free()
    cm = cape.data; Mi = cape.matrix_world.inverted(); Mw = cape.matrix_world
    for _ in range(iters):
        for v in cm.vertices:
            p = Mw @ v.co; hit, nrm, _, _ = bvh.find_nearest(p)
            if hit is not None and (p - hit).dot(nrm) < margin:
                v.co = Mi @ (hit + nrm * margin)
    cm.update()


def attach_top(cape, body, arm, rows=8, tuck=0.012, snug=0.006, step=0.003):
    """Make the cape read as attached: top rows go INSIDE the cloth mantle where one covers them (the cape
    emerges from under it), elsewhere they sit snug on the body, the gap growing gently down the cape.
    Run after fit_to_body (which keeps the lower cape clear) and before rig()."""
    arm.data.pose_position = "REST"; bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get(); eb = body.evaluated_get(dg); bme = eb.to_mesh()
    bm = bmesh.new(); bm.from_mesh(bme); bm.transform(body.matrix_world)
    uvl = bm.loops.layers.uv.active; bm.faces.ensure_lookup_table()
    face_uv = [f.loops[0][uvl].uv.copy() for f in bm.faces]
    bvh = BVHTree.FromBMesh(bm); bm.free(); eb.to_mesh_clear()
    img = [n for n in body.data.materials[0].node_tree.nodes if n.type == "TEX_IMAGE"][0].image
    tw, th = img.size; tex = np.array(img.pixels[:], np.float32).reshape(th, tw, 4)
    def is_cloth(fi):
        u, v = face_uv[fi]; c = tex[int(np.clip(v * th, 0, th - 1)), int(np.clip(u * tw, 0, tw - 1)), :3]
        return (c.max() - c.min()) / (c.max() + 1e-6) > 0.35 and c[0] >= c[2]
    cm = cape.data; Mw = cape.matrix_world; Mi = Mw.inverted(); n0 = NR * NC; moved = 0
    for v in cm.vertices:
        if v.index >= n0 or v.index // NC >= rows: continue
        j = v.index // NC
        p = Mw @ v.co
        hit, nrm, fi, d = bvh.find_nearest(p, 0.15)       # nearest surface: never the far-out T-pose arms
        if hit is None: continue
        if is_cloth(fi) and j < rows - 2:
            target = hit - nrm * tuck                        # hidden under the mantle
        else:
            target = hit + nrm * (snug + step * j)           # snug on armour, gap grows downward
        target.z = p.z                                       # move sideways only: keeps the texture (and decals) unstretched
        w = 1.0 if j < rows - 3 else (rows - j) / 3.0        # blend into the fitted lower cape
        v.co = Mi @ (p.lerp(target, w)); moved += 1
    cm.update()
    return moved


def _grid_index(cape):
    cm = cape.data; n0 = NR * NC
    co = np.array([v.co[:] for v in cm.vertices]); gi = np.zeros(len(co), int); gj = np.zeros(len(co), int)
    lookup = {tuple(np.round(co[k], 6)): k for k in range(n0)}
    for v in cm.vertices:
        k = v.index if v.index < n0 else lookup[tuple(np.round(co[v.index], 6))]
        gj[v.index], gi[v.index] = divmod(k, NC)
    side = np.zeros(len(co))
    for v in cm.vertices:
        if gi[v.index] == NC // 2:
            side[v.index] = -1 if np.mean([p.center.x for p in cm.polygons if v.index in p.vertices]) < 0 else 1
    return co, gi, gj, side


def rig(cape, arm, parent_bone="Spine", slit_from_row=13):
    """Add Cape_c_k bones (len(CH) chains x len(RJ)-1 bones) and bilinear weights (max 4 influences)."""
    co, gi, gj, side = _grid_index(cape)
    W = np.array(cape.matrix_world)
    cow = co @ W[:3, :3].T + W[:3, 3]
    J = np.array([[cow[j * NC + i] for j in RJ] for i in CH])
    arm.data.pose_position = "REST"; bpy.context.view_layer.update()
    inv = arm.matrix_world.inverted()
    import contextlib
    wins = bpy.context.window_manager.windows
    areas = [a for a in wins[0].screen.areas if a.type == "VIEW_3D"] if wins else []
    ctx = (bpy.context.temp_override(window=wins[0], area=areas[0], active_object=arm, object=arm, selected_objects=[arm])
           if areas else contextlib.nullcontext())             # headless (blender -b) needs no override
    with ctx:
        for o in bpy.context.view_layer.objects: o.select_set(False)
        arm.select_set(True); bpy.context.view_layer.objects.active = arm
        bpy.ops.object.mode_set(mode="EDIT"); ebn = arm.data.edit_bones
        for b in [b for b in ebn if b.name.startswith("Cape_")]: ebn.remove(b)
        for c in range(len(CH)):
            prev = None
            for k in range(len(RJ) - 1):
                b = ebn.new("Cape_%d_%d" % (c, k)); b.head = inv @ Vector(J[c, k]); b.tail = inv @ Vector(J[c, k + 1]); b.roll = 0
                b.parent = prev or ebn[parent_bone]; b.use_connect = prev is not None; prev = b
        bpy.ops.object.mode_set(mode="OBJECT")
    for pb in arm.pose.bones: pb.rotation_mode = "QUATERNION"
    for g in list(cape.vertex_groups): cape.vertex_groups.remove(g)
    groups = {}
    def add(vi, n, w):
        if w > 1e-4:
            g = groups.get(n) or cape.vertex_groups.new(name=n); groups[n] = g; g.add([int(vi)], float(w), "ADD")
    for v in cape.data.vertices:
        vi = v.index; i, j = gi[vi], gj[vi]
        if side[vi] != 0 and j >= slit_from_row:
            pairs = [(CH.index(CH[len(CH) // 2 - 1]) if side[vi] < 0 else CH.index(CH[len(CH) // 2]), 1.0)]
        else:
            c1 = max(c for c in range(len(CH)) if CH[c] <= i); c2 = min(c1 + 1, len(CH) - 1)
            t = 0 if c1 == c2 else (i - CH[c1]) / (CH[c2] - CH[c1]); pairs = [(c1, 1 - t), (c2, t)]
        k = min(max(k for k in range(len(RJ)) if RJ[k] <= j), len(RJ) - 2); s = (j - RJ[k]) / (RJ[k + 1] - RJ[k])
        segs = [(k, 1.0)] if (s >= 0.5 or k == 0) else [(k - 1, 0.5 - s), (k, 0.5 + s)]
        top = 1.0 if j == 0 else (0.4 if j == 1 else 0.0)
        if top: add(vi, parent_bone, top)
        for c, wc in pairs:
            for kk, ws in segs: add(vi, "Cape_%d_%d" % (c, kk), (1 - top) * wc * ws)
    for m in list(cape.modifiers): cape.modifiers.remove(m)
    mw = cape.matrix_world.copy(); cape.parent = arm; cape.matrix_world = mw
    cape.modifiers.new("Armature", "ARMATURE").object = arm
    arm.data.pose_position = "POSE"


LIMB_CAP = {"thigh": 0.12, "shin": 0.10, "uparm": 0.09, "forearm": 0.09}   # hip plates skin to the thighs; the hip collider covers them


def measure_colliders(body, arm, margin=0.012, pct=75, cap=True):
    """Capsule colliders sized from the actual body: legs/arms by radial spread of their skinned verts,
    hips/chest as ellipses from the torso band. Returns (name, bone0, bone1, rx, ry) tuples."""
    P = _world_rest(body, arm); me = body.data
    H = lambda n: np.array(arm.matrix_world @ arm.data.bones[n].head_local)
    vg = {g.index: g.name for g in body.vertex_groups}
    dom = np.array([vg[max(v.groups, key=lambda g: g.weight).group] if v.groups else "" for v in me.vertices])
    out = []
    for nm, b0, b1, owners in (("col_thigh_L", "LeftUpLeg", "LeftLeg", ["LeftUpLeg"]), ("col_shin_L", "LeftLeg", "LeftFoot", ["LeftLeg"]),
                               ("col_thigh_R", "RightUpLeg", "RightLeg", ["RightUpLeg"]), ("col_shin_R", "RightLeg", "RightFoot", ["RightLeg"]),
                               ("col_uparm_L", "LeftArm", "LeftForeArm", ["LeftArm"]), ("col_forearm_L", "LeftForeArm", "LeftHand", ["LeftForeArm", "LeftHand"]),
                               ("col_uparm_R", "RightArm", "RightForeArm", ["RightArm"]), ("col_forearm_R", "RightForeArm", "RightHand", ["RightForeArm", "RightHand"])):
        m = np.isin(dom, owners)
        r = float(np.percentile(_seg_dist(P[m], H(b0), H(b1)), pct)) + margin if m.sum() > 20 else 0.09
        if cap: r = min(r, LIMB_CAP[nm.split("_")[1]])
        out.append((nm, b0, b1, r, r))
    for nm, b0, b1, z0, z1 in (("col_hips", "Hips", "Spine02", 0.8, 1.15), ("col_chest", "Spine02", "Spine", 1.1, 1.36)):
        band = (P[:, 2] > z0) & (P[:, 2] < z1) & (np.abs(P[:, 0]) < 0.28) & ~np.isin(dom, ["LeftArm", "RightArm", "LeftForeArm", "RightForeArm", "LeftHand", "RightHand"])
        rx = float(np.percentile(np.abs(P[band, 0]), 95)) + margin if band.any() else 0.2
        ry = float(np.percentile(np.abs(P[band, 1] - CY), 95)) + margin if band.any() else 0.15
        out.append((nm, b0, b1, rx, ry))
    return out


def tie_top_to_shoulders(cape, arm, rows=3, share=0.6, width=0.18):
    """Move part of the top rows' Spine weight onto Left/RightShoulder so the cape follows the mantle."""
    W = np.array(cape.matrix_world); n0 = NR * NC
    sp = cape.vertex_groups.get("Spine")
    if sp is None: return
    for side in ("LeftShoulder", "RightShoulder"):
        if side not in cape.vertex_groups: cape.vertex_groups.new(name=side)
    for v in cape.data.vertices:
        k = v.index if v.index < n0 else None
        if k is None or k // NC >= rows: continue
        w = next((g.weight for g in v.groups if g.group == sp.index), 0.0)
        if w <= 0: continue
        x = (W[:3, :3] @ np.array(v.co[:]) + W[:3, 3])[0]
        s = share * min(abs(x) / width, 1.0)
        if s <= 0: continue
        sp.add([v.index], w * (1 - s), "REPLACE")
        cape.vertex_groups["LeftShoulder" if x > 0 else "RightShoulder"].add([v.index], w * s, "ADD")


def tuck_top(cape, rows=4, factor=0.9, center=CY):
    """Pull the top rows toward the body axis so they stay under the shoulder mantle."""
    cm = cape.data; n0 = NR * NC
    for v in cm.vertices:
        if v.index < n0 and v.index // NC < rows:
            t = 1 - (v.index // NC) / rows; f = 1 - (1 - factor) * t
            v.co.x *= f; v.co.y = center + (v.co.y - center) * f
    cm.update()


def poke_through(body, cape, arm, action, step=2, covered=None, max_out=0.04):
    """Count body verts that end up OUTSIDE the cape (poke-through) per sampled frame of `action`.
    Only counts verts just outside the cloth (4 mm .. max_out): a cape that swings away is not a poke-through.
    Returns (max, mean, covered_mask). covered = body verts under the cape at rest (computed if None)."""
    sc = bpy.context.scene; ad = arm.animation_data
    def bvh_of(o):
        dg = bpy.context.evaluated_depsgraph_get(); e = o.evaluated_get(dg); m = e.to_mesh()
        bm = bmesh.new(); bm.from_mesh(m); bm.transform(o.matrix_world); e.to_mesh_clear()
        t = BVHTree.FromBMesh(bm); bm.free(); return t
    def body_pts():
        dg = bpy.context.evaluated_depsgraph_get(); e = body.evaluated_get(dg); m = e.to_mesh()
        c = np.empty(len(m.vertices) * 3, np.float32); m.vertices.foreach_get("co", c); e.to_mesh_clear()
        M = np.array(body.matrix_world); return c.reshape(-1, 3) @ M[:3, :3].T + M[:3, 3]
    if covered is None:
        prev = ad.action; ad.action = None
        arm.data.pose_position = "REST"; bpy.context.view_layer.update()
        t = bvh_of(cape); Pb = body_pts(); covered = np.zeros(len(Pb), bool)
        for i, p in enumerate(Pb):
            hit, nrm, _, d = t.find_nearest(Vector(p), 0.12)
            if hit is not None and (Vector(p) - hit).dot(nrm) < 0 and p[2] < 1.2: covered[i] = True
        arm.data.pose_position = "POSE"; ad.action = prev
    act = bpy.data.actions[action]; ad.action = act
    try: ad.action_slot = act.slots[0]
    except Exception: pass
    a, b = [int(x) for x in act.frame_range]; counts = []
    idx = np.nonzero(covered)[0]
    for f in range(a, b + 1, step):
        sc.frame_set(f); t = bvh_of(cape); Pb = body_pts(); n = 0
        for i in idx:
            hit, nrm, _, d = t.find_nearest(Vector(Pb[i]), 0.12)
            if hit is not None and 0.004 < (Vector(Pb[i]) - hit).dot(nrm) < max_out: n += 1
        counts.append(n)
    return max(counts), float(np.mean(counts)), covered


def setup_sim(cape, arm, parent_bone="Spine", colliders=None):
    """Hidden cloth copy named 'cape_sim' (what cape_bake.py reads) + capsule colliders, in collection 'cape_sim'.
    Pass colliders=measure_colliders(body, arm) to size them from the body (cape_bake.bake_all does this per clip)."""
    arm.data.pose_position = "REST"; bpy.context.view_layer.update()
    coll = bpy.data.collections.get("cape_sim") or bpy.data.collections.new("cape_sim")
    if coll.name not in bpy.context.scene.collection.children: bpy.context.scene.collection.children.link(coll)
    for o in list(coll.objects): bpy.data.objects.remove(o)
    def bone_parent(o, bone):
        mw = o.matrix_world.copy(); o.parent = arm; o.parent_type = "BONE"; o.parent_bone = bone
        bpy.context.view_layer.update(); o.matrix_world = mw
    sm = cape.data.copy(); sim = bpy.data.objects.new("cape_sim", sm); coll.objects.link(sim)
    sim.matrix_world = cape.matrix_world.copy()
    for g in list(sim.vertex_groups): sim.vertex_groups.remove(g)
    for m in list(sim.modifiers): sim.modifiers.remove(m)
    pin = sim.vertex_groups.new(name="pin")
    for v in sm.vertices:
        if v.index < NR * NC:
            w = {0: 1.0, 1: 0.6, 2: 0.2}.get(v.index // NC, 0.0)
            if w: pin.add([v.index], w, "REPLACE")
    bone_parent(sim, parent_bone)
    s = sim.modifiers.new("Cloth", "CLOTH").settings
    s.quality = 8; s.mass = 0.4; s.air_damping = 1.5
    s.tension_stiffness = 15; s.compression_stiffness = 15; s.shear_stiffness = 5; s.bending_stiffness = 0.5
    s.tension_damping = 5; s.compression_damping = 5; s.bending_damping = 0.5
    s.vertex_group_mass = "pin"; s.pin_stiffness = 1.0
    c = sim.modifiers["Cloth"].collision_settings; c.distance_min = 0.015; c.collision_quality = 4
    H = lambda n: Vector(arm.matrix_world @ arm.data.bones[n].head_local)
    colliders = colliders or (("col_thigh_L", "LeftUpLeg", "LeftLeg", .095, .095), ("col_shin_L", "LeftLeg", "LeftFoot", .08, .08),
                              ("col_thigh_R", "RightUpLeg", "RightLeg", .095, .095), ("col_shin_R", "RightLeg", "RightFoot", .08, .08),
                              ("col_hips", "Hips", "Spine02", .2, .15), ("col_chest", "Spine02", "Spine", .2, .15))
    for nm, b0, b1, rx, ry in colliders:
        a, b = H(b0), H(b1); L = (b - a).length
        bm = bmesh.new(); bmesh.ops.create_uvsphere(bm, u_segments=16, v_segments=10, radius=1.0)
        me = bpy.data.meshes.new(nm); bm.to_mesh(me); bm.free()
        o = bpy.data.objects.new(nm, me); coll.objects.link(o)
        z = (b - a).normalized(); x = Vector((1, 0, 0)); y = z.cross(x).normalized(); x = y.cross(z)
        o.matrix_world = Matrix.Translation((a + b) / 2) @ Matrix((x, y, z)).transposed().to_4x4() @ Matrix.Diagonal((rx, ry, L * 0.62, 1))
        bone_parent(o, b0)
        o.modifiers.new("Collision", "COLLISION"); o.collision.thickness_outer = 0.01; o.display_type = "WIRE"
    for o in coll.objects:
        o.hide_render = True; o.hide_set(True)
    arm.data.pose_position = "POSE"
    return sim


def lift_texture(img, gain=1.3, sat=1.15, gamma=0.9):
    """Brighten Meshy's painted albedo for the neon battle lighting (apply once per image)."""
    if img.get("lifted"): return
    w, h = img.size; px = np.array(img.pixels[:], np.float32).reshape(h, w, 4)
    rgb = np.power(np.clip(px[..., :3], 0, 1), gamma) * gain
    lum = (rgb * [0.299, 0.587, 0.114]).sum(-1, keepdims=True)
    px[..., :3] = np.clip(lum + (rgb - lum) * sat, 0, 1)
    img.pixels[:] = px.ravel(); img.pack(); img["lifted"] = True
