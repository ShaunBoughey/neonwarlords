# Bake the cape cloth sim onto the Cape_c_k bones for one action (run inside Blender).
# Steps through the clip, reads the simulated cloth joints and aims each cape bone at its joint.
import bpy, math, numpy as np
from mathutils import Matrix, Quaternion

NR, NC = 21, 25
CH = [0, 3, 6, 9, 11, 13, 15, 18, 21, 24]
RJ = [0, 5, 10, 15, 20]
LOOPING = {"idle", "run"}


def channelbag(act, slot):
    return act.layers[0].strips[0].channelbag(slot)


def bake_action(name, preroll_hold=12):
    sc = bpy.context.scene
    arm = bpy.data.objects["Armature"]; sim = bpy.data.objects["cape_sim"]
    ad = arm.animation_data
    act = bpy.data.actions[name]
    ad.action = act
    if ad.action_slot is None:
        ad.action_slot = act.slots[0]
    cb = channelbag(act, ad.action_slot)
    for fc in [fc for fc in cb.fcurves if 'Cape_' in fc.data_path]:
        cb.fcurves.remove(fc)
    a, b = act.frame_range
    a, b = int(math.floor(a)), int(math.ceil(b))
    loop = name in LOOPING
    mods = []
    if loop:
        for fc in cb.fcurves:
            mods.append((fc, fc.modifiers.new("CYCLES")))
        pre = (b - a) * 2
    else:
        pre = preroll_hold
    cache = sim.modifiers["Cloth"].point_cache
    cache.frame_start = a - pre
    cache.frame_end = b
    sim.modifiers["Cloth"].settings.mass = sim.modifiers["Cloth"].settings.mass   # invalidate cache
    sc.frame_start, sc.frame_end = a - pre, b
    inv_arm = arm.matrix_world.inverted()
    pbs = {(c, k): arm.pose.bones["Cape_%d_%d" % (c, k)] for c in range(len(CH)) for k in range(len(RJ) - 1)}
    rest = {key: pb.bone.matrix_local.copy() for key, pb in pbs.items()}
    spine_rest = arm.data.bones["Spine"].matrix_local.copy()
    keyed = 0
    for f in range(a - pre, b + 1):
        sc.frame_set(f)
        if f < a:
            continue
        dg = bpy.context.evaluated_depsgraph_get()
        es = sim.evaluated_get(dg)
        mw = es.matrix_world
        Ms = arm.pose.bones["Spine"].matrix.copy()
        for c, col in enumerate(CH):
            parent_posed, parent_rest = Ms, spine_rest
            for k in range(len(RJ) - 1):
                pb = pbs[(c, k)]
                vi = RJ[k + 1] * NC + col
                tgt = inv_arm @ (mw @ es.data.vertices[vi].co)
                M0 = parent_posed @ (parent_rest.inverted() @ rest[(c, k)])
                head = M0.translation
                cur = M0.col[1].xyz.normalized()
                want = (tgt - head)
                if want.length < 1e-6:
                    q = Quaternion()
                    posed = M0
                else:
                    r = cur.rotation_difference(want.normalized()).to_matrix().to_4x4()
                    posed = Matrix.Translation(head) @ r @ Matrix.Translation(-head) @ M0
                    q = (M0.inverted() @ posed).to_quaternion()
                pb.rotation_quaternion = q
                pb.keyframe_insert("rotation_quaternion", frame=f)
                keyed += 1
                parent_posed, parent_rest = posed, rest[(c, k)]
    for fc, m in mods:
        fc.modifiers.remove(m)
    # loops: blend the last 4 frames toward the first so the cape doesn't pop at the wrap
    if loop:
        cb = channelbag(act, ad.action_slot)
        for fc in cb.fcurves:
            if 'Cape_' not in fc.data_path:
                continue
            kp = {int(round(p.co[0])): p for p in fc.keyframe_points}
            if a not in kp:
                continue
            v0 = kp[a].co[1]
            for i in range(1, 5):
                fr = b - 4 + i
                if fr in kp:
                    w = i / 4.0
                    kp[fr].co[1] = kp[fr].co[1] * (1 - w) + v0 * w
            fc.update()
    return {"action": name, "range": [a, b], "preroll": pre, "keys": keyed}


# Per-clip cloth style, measured on Deacon (poke-through and jitter): standing clips want heavy,
# damped cloth that drapes around the arms; clips with sharp body motion want livelier cloth that
# moves out of the way. Every clip is then smoothed over time to remove sim jitter.
CLOTH_STYLE = {
    "calm":   dict(quality=12, mass=0.6, air_damping=6.0, tension_damping=25, compression_damping=25,
                   shear_damping=25, bending_damping=3.0, sigma=6.0),
    "lively": dict(quality=8, mass=0.4, air_damping=1.5, tension_damping=5, compression_damping=5,
                   shear_damping=5, bending_damping=0.5, sigma=2.0),
}
CLIP_STYLE = {"idle": "calm", "victory": "calm"}          # everything else: lively
# Collider sizing per clip: "snug" = limb radii capped (cloth flows past swinging legs), "full" = the body's
# measured 90th-percentile radii (cloth kept well clear during sharp body motion). Measured on Deacon.
CLIP_COLLIDERS = {"idle": "snug", "run": "snug", "victory": "snug"}   # everything else: full


def bake_all(body, cape, arm, clips=("idle", "run", "attack", "shoot", "cast", "hit", "death", "victory"), distance=0.02):
    """Bake + smooth every clip with its cloth style and collider set (rebuilds the sim per collider set)."""
    import cape_build as cb
    out = []
    for cset in ("snug", "full"):
        group = [n for n in clips if CLIP_COLLIDERS.get(n, "full") == cset]
        if not group:
            continue
        cols = cb.measure_colliders(body, arm, pct=75, cap=True) if cset == "snug" else cb.measure_colliders(body, arm, pct=90, cap=False)
        sim = cb.setup_sim(cape, arm, colliders=cols)
        sim.modifiers["Cloth"].collision_settings.distance_min = distance
        s = sim.modifiers["Cloth"].settings
        for n in group:
            st = dict(CLOTH_STYLE[CLIP_STYLE.get(n, "lively")]); sigma = st.pop("sigma")
            for k, v in st.items(): setattr(s, k, v)
            r = bake_action(n); smooth_action(n, sigma=sigma)
            r["style"] = CLIP_STYLE.get(n, "lively"); r["colliders"] = cset; out.append(r)
    return out


def _cape_quats(act, slot):
    cb = channelbag(act, slot)
    bones = sorted({fc.data_path.split('"')[1] for fc in cb.fcurves if 'Cape_' in fc.data_path})
    return cb, bones


def smooth_action(name, sigma=2.0):
    """Gaussian-smooth the baked cape rotations over time (cloth sims jitter frame to frame).
    Looping clips wrap around so the loop stays seamless."""
    arm = bpy.data.objects["Armature"]
    act = bpy.data.actions[name]
    cb, bones = _cape_quats(act, act.slots[0])
    a, b = [int(round(x)) for x in act.frame_range]
    loop = name in LOOPING
    r = int(math.ceil(sigma * 2.5)); w = np.exp(-0.5 * (np.arange(-r, r + 1) / sigma) ** 2); w /= w.sum()
    for bn in bones:
        fcs = [cb.fcurves.find('pose.bones["%s"].rotation_quaternion' % bn, index=i) for i in range(4)]
        if any(fc is None for fc in fcs):
            continue
        Q = np.array([[fc.evaluate(f) for fc in fcs] for f in range(a, b + 1)])
        for i in range(1, len(Q)):                      # keep one hemisphere
            if np.dot(Q[i], Q[i - 1]) < 0: Q[i] = -Q[i]
        n = len(Q); out = np.zeros_like(Q)
        for i in range(n):
            idx = np.arange(i - r, i + r + 1)
            idx = idx % n if loop else np.clip(idx, 0, n - 1)
            q = (Q[idx] * w[:, None]).sum(0); out[i] = q / np.linalg.norm(q)
        for c, fc in enumerate(fcs):
            for kp in fc.keyframe_points:
                f = int(round(kp.co[0]))
                if a <= f <= b: kp.co[1] = out[f - a, c]
            fc.update()


def sway_action(name, amp_deg=(1.0, 1.6, 2.2, 2.8), cycles=2):
    """Replace the cape motion of a calm clip (idle) with a gentle, seamless sway from the rest shape:
    no cloth sim, so no jitter. Amplitude grows down each chain; neighbouring chains are phase-shifted."""
    arm = bpy.data.objects["Armature"]; ad = arm.animation_data
    act = bpy.data.actions[name]; ad.action = act
    if ad.action_slot is None: ad.action_slot = act.slots[0]
    cb = channelbag(act, ad.action_slot)
    for fc in [fc for fc in cb.fcurves if 'Cape_' in fc.data_path]: cb.fcurves.remove(fc)
    a, b = [int(round(x)) for x in act.frame_range]; L = b - a
    for c in range(len(CH)):
        for k in range(len(RJ) - 1):
            pb = arm.pose.bones["Cape_%d_%d" % (c, k)]
            for f in range(a, b + 1, 2):
                ph = 2 * math.pi * (cycles * (f - a) / L) - 0.35 * c - 0.5 * k
                ang = math.radians(amp_deg[k]) * math.sin(ph)
                side = math.radians(amp_deg[k] * 0.4) * math.sin(ph * 0.5 + c)
                pb.rotation_quaternion = Quaternion((1, 0, 0), ang) @ Quaternion((0, 0, 1), side)
                pb.keyframe_insert("rotation_quaternion", frame=f)
    return {"action": name, "range": [a, b]}
