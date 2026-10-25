# Neon Warlords

Cyberpunk turn-based looter in the style of RAID: Shadow Legends, built in Godot 4.3 from the
Neon Warlords GDD. All game systems in the GDD are implemented; see `GDD_COVERAGE.md` for the
section-by-section map and how each was verified.

## Run

Open the folder in Godot 4.3 (a portable copy lives at `../tools/Godot_v4.3-stable_win64.exe`)
and press Play, or from a shell:

```bash
../tools/Godot_v4.3-stable_win64.exe --path .
```

A new save starts with a starter kit (gear, implants, neons, contracts). For a fully stocked
account use **Settings › Developer: grant test items**. Real-money packs are free while
**Free IAP (dev mode)** is on.

## PC build

```bash
bash tools/build_pc.sh
```

Writes `../build/NeonWarlords.exe` (the Godot runtime) and `NeonWarlords.pck` (the game; tests,
tools and source art excluded via `export_presets.cfg`). The runtime auto-loads the pack with the
same name, so no export templates are needed.

## Layout

| Path | What lives there |
|---|---|
| `scripts/core/` | Autoloads: `U` (helpers, clock), `Data` (GDD tables and constants), `Warlords` (templates and abilities), `Game` (save and every progression system), `Content` (encounter builders), `Sfx` (sound) |
| `scripts/combat/` | `Battle.gd` turn-meter combat engine; `battle_view_3d.gd` 3D presentation |
| `scripts/ui/` | Code-built UI. `ui.gd` is the design system (tokens, notched frames, buttons, cards), `Main.gd` the router with top bar, bottom nav and modals, `screen.gd` the screen base (hub/flow, rail, tabs) |
| `scripts/ui/screens/` | One script per screen |
| `data/gdd.json` | Tables extracted from the GDD |
| `assets/ui/` | The UI art kit; `assets/models/` glTF warlords and arena; `assets/audio/` sound effects |
| `tools/blender/` | Blender scripts for the placeholder models; `tools/audio/make_sfx.py` regenerates the sounds |

## UI design system

The look follows the **Neon Warlords UI Redesign** canvas: void ground, teal glass panels with a
45° notch on the top-left and bottom-right corners, cyan for anything tappable, gold for the single
forward action on a screen, rarity colours only for rarity. Hub screens (City, Warlords, Battle,
Recruit, Plaza, Shop, Gang) show the bottom nav; flow screens show a back button and pin their gold
call-to-action at the bottom of a detail panel. Catalogue screens use a category rail on the left.

## Tests

Run any test scene headless (the `--nwtest` flag uses a separate save):

```bash
../tools/Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/TestRunner.tscn -- --nwtest
```

| Scene | Checks |
|---|---|
| `tests/TestRunner.tscn` | Logic and balance: formulas, gear, progression, rewards |
| `tests/UiSmoke.tscn` | Opens every screen, drives the Armoury, plays 4 battle modes |
| `tests/Playthrough.tscn` | GDD equipment checks plus an N-day bot (`NW_DAYS=20`) |
| `tests/Shots.tscn` | Windowed screenshots of every screen to `user://shots` |

## Placeholders

- Character art: warlord portraits are procedural busts and mode cards use silhouettes until real
  portrait renders exist. 3D models are script-built placeholders; real ones (image-to-3D, Mixamo
  rig, animations named idle/run/attack/shoot/cast/hit/death/victory) drop into `assets/models/`.
- Sound effects are synthesised; there is no music yet.
