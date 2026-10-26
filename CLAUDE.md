# Neon Warlords

A Godot 4.3 gacha RPG in the style of RAID: Shadow Legends. The portable Godot is at `../tools/Godot_v4.3-stable_win64.exe` (with a `_console` variant).

## 3D warlord models
Follow **`docs/WARLORD_MODELS.md`** for every new or replaced warlord model (Meshy → Blender → `assets/models/warlord_<id>.glb`). Its hard rules in short:
- Generate the body **without** long cloth, then add the cape or coat as a separate cloth-simulated piece (`tools/blender/cape_build.py` + `cape_bake.py`).
- Use Meshy's standard model, not Smart Topology.
- `.blend` files live only under `assets/source/`, which has a `.gdignore`. Otherwise Godot's headless import and export hang.
- Commit the `warlord_<id>_*.jpg` textures that Godot extracts next to each GLB.
