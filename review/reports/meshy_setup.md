# Meshy setup (MCP for Claude + Godot plugin)

Date: 2026-10-26. Goal: RAID-quality rigged and animated warlord models, made with Meshy (Premium account, 3,100 monthly credits).

## 1. Meshy MCP server (lets Claude drive Meshy)

**What was installed**
- Official server `@meshy-ai/meshy-mcp-server` **v0.6.5** (MIT, by Meshy; source https://github.com/meshy-dev/meshy-mcp-server; docs https://docs.meshy.ai/en/api/ai).
- Added at **user scope** to `C:\Users\sboug\.claude.json` → `mcpServers.meshy`, so every Claude Code session in every project gets it:
  ```json
  "meshy": { "type": "stdio", "command": "cmd.exe",
             "args": ["/d", "/c", "npx", "-y", "@meshy-ai/meshy-mcp-server@0.6.5"], "env": {} }
  ```
  The version is pinned, so updating means changing `@0.6.5`. A backup of the previous file was taken before the edit.
- Smoke test (no key): the server starts and registers **28 tools**: `meshy_text_to_3d`, `meshy_image_to_3d`, `meshy_multi_image_to_3d`, `meshy_text_to_3d_refine`, `meshy_remesh`, `meshy_retexture`, `meshy_rig`, `meshy_animate`, `meshy_list_animations`, `meshy_text_to_motion`, `meshy_get_task_status`, `meshy_download_model`, `meshy_convert`, `meshy_check_balance`, plus 3D-print and image tools.

**Where the API key goes**
No key is stored in the config. The server reads `MESHY_API_KEY` from your Windows user environment.
1. On meshy.ai, open **Developers → API Keys** (https://www.meshy.ai/developers/keys) and create a key (it starts `msy_`).
2. Set it yourself in PowerShell. Paste your key in place of the placeholder, and don't paste it into chat:
   ```powershell
   [Environment]::SetEnvironmentVariable("MESHY_API_KEY", "msy_PASTE_YOUR_KEY_HERE", "User")
   ```
   (Or go to Start → "Edit environment variables for your account" → New → `MESHY_API_KEY`.)
3. **Fully quit and restart the Claude desktop app.** Running sessions don't see new environment variables, and MCP tools only load at session start.

**How to test**
- In a new session, ask Claude to "check my Meshy balance". It should call `meshy_check_balance` and report your credits. In a terminal `claude` session, `/mcp` should list `meshy` as connected.
- If it says the key is missing, the app was started before the variable was set, so restart it again.
- Note: one directory listing says API access needs Pro or higher. Your account shows Premium, which should be fine, but the balance check confirms it. API calls spend the same credits as the web app.

## 2. Meshy Godot plugin (Meshy web app → Godot editor)

**What was installed**
- Official `meshy-godot-plugin` **v0.1.6** (zip from https://github.com/meshy-dev/meshy-godot-plugin/releases/tag/v0.1.6, 17 KB) → `addons/meshy-godot-plugin/`.
- Enabled in `project.godot` → `[editor_plugins] enabled=PackedStringArray("res://addons/meshy-godot-plugin/plugin.cfg")`.
- Godot 4.3 compatibility: Meshy lists it for 4.4. On our 4.3 the headless `--import` compiles clean (0 `SCRIPT ERROR`, and the plugin panel initialises). The first-ever import shows a one-time icon preload error until the icon is imported, and that's already done. One harmless warning remains: `invalid UID ... using text path instead`, because 4.4 `.uid` files are ignored by 4.3.
- Meshy's newer "DCC Core" Godot connector (meshy-dcc-adapters) needs Godot **4.4+**, so it wasn't used.

**There is no API key in the Godot plugin.** It's a local bridge. Clicking **Run Meshy Bridge** opens a listener on `localhost:5325`. The meshy.ai web app, while you're logged in, sends the model to it ("Send to Godot" / DCC Bridge, a Pro-plan feature). Authentication is your browser login to meshy.ai.

**How to use and test**
1. Open the project in the Godot editor. A **Meshy** tab appears at the top beside 2D/3D/Script.
2. Click **Run Meshy Bridge**. The status changes to "Bridge: Running".
3. On meshy.ai, open any model of yours and use the DCC bridge / send to Godot (choose GLB).
4. The model lands in `res://imported_models/<model name>/` and opens in a new scene. A progress toast appears in the bottom right.
5. **Stop the bridge when you're done.** The listener accepts import requests from any page in your browser (CORS `*`) without auth, so only leave it running while you're sending models.

**Build and git hygiene**
- `export_presets.cfg` exclude filter now includes `addons/meshy-godot-plugin/*, imported_models/*`. `tools/build_pc.sh` uses that preset (`--export-pack`), so neither ends up in the PC build. (Editor plugins never run in the game anyway.)
- `addons/` is **not** gitignored, so commit the plugin with the project. `/imported_models/` **is** gitignored on purpose: it's the staging area for raw Meshy downloads (often 20–50 MB with 4K textures). Finished models go to `assets/models/` and get committed there.

## 3. Recommended warlord pipeline

The battle view (`scripts/combat/battle_view_3d.gd`) loads `res://assets/models/warlord_<id>.glb` per template via `TPL_MODELS` (Deacon is already mapped: `deacon_chainz → warlord_deacon.glb`). It falls back to the class model and finds the first `AnimationPlayer`. It plays clips named **idle, run, attack, shoot, cast, hit, death, victory** (idle and run are set to loop). The model's materials keep their textures. `_recolour` only overrides materials named Accent/Neon/Body.

Proven on Deacon Chainz (2026-10-26). **The key rule: never generate long cloth (capes, coats, robes) as part of the body.** Meshy builds one fused, watertight shell, so a cape is welded to the legs and there are no legs behind it. Re-weighting gives only a stiff robe, and cutting it free leaves holes. Generate the body without the cloth, and add the cloth as its own mesh.

| Step | Tool | Notes | Credits |
|---|---|---|---|
| 0. No-cloth concept | `meshy_image_to_image`, model `nano-banana-2`, with the colour **T-pose front** as reference | Prompt: remove only the long cape and keep everything else identical (see `tools/meshy/deacon_nocape_prompt.txt`). Keep short shoulder mantles on the body. | 6 |
| 1. Body mesh | `meshy_image_to_3d`: standard model (`ai_model: "latest"`), `pose_mode: "t-pose"`, `should_remesh: true`, `target_polycount: 40000`, PBR on | Meshy projects the front image almost 1:1, so lettering stays sharp. **Don't use Smart Topology** (`meshy-t2.5`): tried on Deacon, it lost small details such as the wrist chains and padlocks. | 30 |
| 2. Rig | `meshy_rig`, `height_meters: 2.0` (2.0 includes the mitre) | Humanoid, textured, facing +Z. | 5 |
| 3. Clips | `meshy_animate` with `action_ids` (one GLB with all clips) | Deacon: idle 89 Combat Idle, run 14 Run 2, attack 198 Punch Combo, shoot 126 Charged Spell Cast 1, cast 125 Charged Spell Cast, hit 178 Hit Reaction, death 8 Dead, victory 59 Victory Cheer. | 3 each |
| 4. Cloth mesh | Blender | Model the cape as an open grid (Deacon: 25 × 21, with a split for the back slit). Shape it from a with-cape generation, or by hand. Bake that generation's cape texture onto it (Cycles selected-to-active diffuse colour), so it keeps Meshy's look. Paint out the band that tucks under the mantle. | 0 (+30 if you generate a with-cape version for reference) |
| 5. Cloth rig and bake | Blender, `tools/blender/cape_bake.py` | Bone chains along the cape grid (Deacon: 10 chains × 4 bones, parented to `Spine`, bilinear weights, max 4 influences, top row locked to `Spine`). A hidden copy of the cape runs the cloth sim: pinned top rows, parented to the `Spine` bone, capsule colliders on the thighs, shins, hips and chest. `bake_action(name)` steps each clip (looping clips get two loops of run-up and the last 4 frames blended into the first), aims each cape bone at its cloth joint, and keys it into the clip. | 0 |
| 6. Details | Blender | Project and bake decals for details the front image can't show (Deacon's keys pennant on the back). | 0 |
| 7. Export | Blender glTF | Rename the clips to our 8 names; set bones to **quaternion** rotation; export only armature + body + cape (`export_influence_nb=4`, JPEG textures); cape material with backface culling off (exports double-sided). Save the `.blend` to `assets/source/models/`. | 0 |
| 8. Check | Godot | `--import` (extracts the textures next to the GLB; commit them), then `tests/ShotsBattle.tscn` with `NW_SAVE=<tag>`. Meshy textures are painted and fairly dark, so lift them about 30% brighter and a little more saturated before export, or they look muddy under the neon battle lighting. | 0 |

**Never put `.blend` files where Godot can see them.** Godot 4.3 auto-imports `.blend` by launching Blender, and headless `--import`/`--export-pack` then hang forever. That is why `assets/source/.gdignore` exists, and it must stay. Also avoid running two Godot processes on the project at once.

**Per warlord:** about 65 credits (6 + 30 + 5 + 24). The monthly 3,100 covers about 45 warlords, or about 30 with a reference generation and retries.

### Deacon Chainz: what's in the game now
- `assets/models/warlord_deacon.glb` (7.9 MB): the no-cape Meshy body, 2.0 m, all 8 clips, plus a separate cloth cape with the keys pennant on 40 cape bones, cloth-simulated and baked into every clip. Godot 4.3 loads it cleanly (8 clips, 64 bones, both meshes textured, cape double-sided).
- Sources: `assets/source/models/deacon_meshy.blend` (final); `deacon_meshy_v1_robe.blend` (the earlier one-piece version with the re-weighted robe, kept as a fallback). Concept images, including the generated no-cape T-pose, are in `assets/source/concepts/deacon/`.
- **Credits spent on Deacon: 168** (balance 2,932). That breaks down as: v1 with cape 59, a rejected Smart Topology test 44, the no-cape image edit 6, and the final body, rig and clips 59.
- The first editor import will extract `warlord_deacon_Material_0_baseColor.jpg` and `warlord_deacon_cape_baked.jpg` next to the GLB. Commit them with it.

### Tools
- `tools/meshy/meshy_api.py`: a small REST client (balance, image-to-3D, image-to-image, rig, animate, download). It reads `MESHY_API_KEY` from the environment. Once the Meshy MCP is loaded after a restart, prefer the `meshy_*` MCP tools.
- `tools/blender/cape_bake.py`: the per-clip cloth to cape-bone baker (step 5).

### Follow-ups
- Small cape artefacts at extreme poses (death crumple): raise collision distance or cloth stiffness if they show in game.
- Bespoke models for other warlords: add each to `TPL_MODELS`.
- A one-shot script that builds the cape grid and runs the texture bake (steps 4–5 were done interactively for Deacon).
