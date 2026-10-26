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
