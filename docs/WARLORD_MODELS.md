# Warlord 3D models: the standard process

This is **the** way we make warlord models. It was proven on Deacon Chainz on 2026-10-26, after several dead ends (listed at the bottom so nobody repeats them). Setup details for Meshy, and the full Deacon history, are in `review/reports/meshy_setup.md`.

## What the game needs
- A card portrait per warlord: `assets/portraits/<tpl_id>.png` (step 10).
- One file per warlord: `assets/models/warlord_<id>.glb`, mapped in `TPL_MODELS` in `scripts/combat/battle_view_3d.gd`. Unmapped warlords fall back to the class model.
- About 2.0 m tall, feet at 0, facing +Z in glTF. Meshy and our Blender export both produce this.
- One `AnimationPlayer` with exactly these clips: **idle, run, attack, shoot, cast, hit, death, victory** (idle and run loop).
- Textures embedded. Godot extracts them as `warlord_<id>_*.jpg` next to the GLB on import. **Commit those too.**

## Inputs
A **colour T-pose front** concept of the warlord, on a plain background. Save the concepts to `assets/source/concepts/<id>/`.

## Steps
Meshy steps use the `meshy_*` MCP tools, or `tools/meshy/meshy_api.py` (reads `MESHY_API_KEY`).

| # | Step | How | Credits |
|---|---|---|---|
| 0 | **Remove long cloth** (capes, coats, robes, skirts) from the concept | `image_to_image`, model `nano-banana-2`, with the T-pose as reference. Prompt template: `tools/meshy/deacon_nocape_prompt.txt` ("remove ONLY the long cape… keep everything else identical"). Keep short shoulder pieces. Skip this step if the warlord has no long cloth. | 6 |
| 1 | Body mesh | `image_to_3d` on the no-cloth image: **standard model** `ai_model: "latest"`, `pose_mode: "t-pose"`, `should_remesh: true`, `target_polycount: 40000`, `enable_pbr: true`, `multi_view_thumbnails: true`. Check the thumbnails. | 30 |
| 2 | Rig | `rig` with `input_task_id` = step 1, `height_meters: 2.0` | 5 |
| 3 | Clips | `animate` with `action_ids` (up to 10, one GLB with all clips). The library is free to list. Deacon uses: **idle 243 "Idle 3"**, run 14, attack 198, shoot 126, cast 125, hit 178, death 8, victory 59. **The idle must face straight ahead with the feet together.** Combat stances (for example 89 "Combat Idle") stand turned about 45° and look mid-stride in the Armoury. Check the library's preview GIFs, which are free, before spending credits. | 3 each |
| 4 | Cloth piece | Only if step 0 removed cloth. Optionally also generate the WITH-cloth version (30) as a shape and texture template. Then in Blender, use `tools/blender/cape_build.py`: `cape_mask` → `grid_from_template` → `bake_texture` → `tuck_top(rows=4, factor=0.88)` → `fit_to_body(margin=0.03)` → **`attach_top`** (top rows go under the cloth mantle and sit snug on armour, so the cape reads as attached) → `rig` → `tie_top_to_shoulders`. `cape_bake.bake_all` builds the sim (`setup_sim`) itself. | 0–30 |
| 5 | Bake cloth into clips | `tools/blender/cape_bake.py`: `bake_all(body, cape, arm)` bakes all 8 clips, each with its cloth style and collider set (`CLIP_STYLE`, `CLIP_COLLIDERS`): calm, damped cloth and snug colliders for idle and victory; lively cloth for the rest; full measured colliders for clips with sharp body motion. Every clip is then smoothed over time to remove sim jitter. Verify with `cape_build.poke_through(body, cape, arm, clip)`. Deacon's mean poke-through is 19–30 for idle and hit and about 200 for run and attack (it started above 1,000). | 0 |
| 6 | Back and side details | The front image projects almost 1:1, but backs are invented. Project and bake decals for anything the design needs (for example, Deacon's keys pennant). | 0 |
| 7 | Brighten | `cape_build.lift_texture(img)` on every albedo. Meshy's painted textures look muddy under the neon battle lighting without it. | 0 |
| 8 | Export | Rename the clips to the 8 names; set pose bones to **QUATERNION**, reset the pose, clear the active action. glTF export of **armature + body + cloth only** (`use_selection`, `export_animation_mode="ACTIONS"`, `export_influence_nb=4`, JPEG 92). Cloth material has backface culling off, which makes it double-sided. Save the `.blend` to `assets/source/models/`. | 0 |
| 9 | Check | Map `<id>` in `TPL_MODELS`. Run `godot --headless --path . --import` (about 6 s). Then, with `NW_SAVE=<tag>` and the user's OK because they open windows: `res://tests/review/meshy/ShotsArmoury.tscn` (front idle and back; set `TPL`) and `res://tests/ShotsBattle.tscn`. Check: facing the camera, calm idle, no cape poke-through, lit, clips playing. | 0 |
| 10 | Card portrait | `blender -b assets/source/models/<id>.blend --python tools/blender/render_portrait.py -- assets/portraits/<tpl_id>.png <syndicate hex>` (syndicate colours are in `Data.SYNDICATES`; Cardinal Trolls is `ff5a36`). This renders a 512×640 head-and-shoulders, three-quarter idle shot, rim-lit in the syndicate colour on the card backdrop. `Portrait` (`scripts/ui/portrait.gd`) uses `assets/portraits/<tpl_id>.png` automatically, cover-fitted with the head-gear kept in frame; without one it falls back to the procedural bust. Check with `res://tests/review/meshy/ShotsPortrait.tscn` (roster, squad, hideout, every card size). | 0 |

**About 65 credits per warlord** (6 + 30 + 5 + 24), or about 35 if there's no long cloth. Monthly allowance: 3,100.

## Hard rules (each one cost us time on Deacon)
1. **Never generate long cloth as part of the body.** Meshy fuses it to the legs and builds nothing behind it. Re-weighting gives a stiff robe; cutting it free leaves holes.
2. **Don't use Smart Topology** (`meshy-t2.5`). It loses small details such as chains and padlocks. Use the standard model.
3. **Never let Godot see `.blend` files.** Godot 4.3 auto-imports them via Blender, and headless `--import`/`--export-pack` then **hang forever**. `assets/source/.gdignore` prevents this. Keep it, and keep all `.blend` files under `assets/source/`.
4. **Don't run two Godot processes on the project at once** (imports and exports block each other).
5. Meshy bones animate **quaternions**. Never switch them to Euler, or the clips silently stop playing.
6. Cloth sims jitter. **Always smooth the baked cape motion** (`bake_all` does this). Raw bakes looked like constant flickering in the Armoury.
7. Don't let the clearance fit push the cape's top edge outside the shoulder mantle (it then floats off his back): run `attach_top`, which only moves points sideways so decals stay unstretched.
8. Fit the cape with the arms DOWN in mind: the T-pose rest shape puts the side panels where idle arms hang. The arm colliders plus the calm idle sim handle this.
9. Previews face the camera: `ModelPreview.auto_spin` defaults to 0. A single warlord spins in on open and settles facing the camera, and also eases back after a drag.
10. In Blender the cloth sim helper (`cape_sim` collection) stays hidden. If you see a torn-looking second cape in the viewport, that's the helper, not the model.

## Files
- `tools/meshy/meshy_api.py`: Meshy REST client (balance, image-to-3D, image-to-image, rig, animate, download)
- `tools/meshy/deacon_nocape_prompt.txt`: prompt template for step 0
- `tools/blender/cape_build.py`: cloth piece build, rig and sim setup (steps 4 and 7)
- `tools/blender/cape_bake.py`: per-clip cloth bake (step 5)
- `tools/blender/render_portrait.py`: card portrait render (step 10)
- `assets/source/models/deacon_meshy.blend`: the reference example of a finished warlord
