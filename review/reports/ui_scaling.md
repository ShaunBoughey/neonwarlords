# UI scaling: phone to 4K

Goal: the same UI, crisp and fully visible from 1280x720 up to 3840x2160 and at 20:9, 4:3 and 21:9, with no redesign.

## Method

- **Matrix test:** `tests/review/res/ShotsRes.tscn` (`shots_res.gd`, modelled on `tests/shots.gd`).
  ```
  NW_SAVE=res timeout 600 G:/tst/tools/Godot_v4.3-stable_win64_console.exe --path . res://tests/review/res/ShotsRes.tscn -- --nwtest [--only=3840x2160]
  ```
  - Sizes: 1280x720, 1920x1080, 2560x1440, 3840x2160, 2400x1080, 2048x1536, 3440x1440.
  - Screens (14 per size): city, the Battle hub, campaign map, campaign 3D diorama, the hideouts list, a hideout boss, shop, recruit, Pit, Warlords roster, Armoury Gear and NeuroNet, squad select, and a live 3D battle.
  - Output: `user://shots_res/<WxH>/` (`C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_res\`). The pre-fix set is kept in `shots_res_before/`. Its 3840x2160 battle shot was overwritten during the first fix check.
- **Sizes bigger than the monitor:** the monitor here is 3440x1440. The script makes the window borderless at (0,0), then sets `get_window().size`. Windows accepts a borderless window larger than the desktop. The probe confirmed `window.size`, `DisplayServer.window_get_size()` and the viewport image all equal the target, with the expected stretch factor (3.0 at 4K, 1.6 at 4:3). So every PNG is a real full-resolution frame. No SubViewport emulation was needed, which keeps font oversampling realistic.
- **Automatic audit after every shot:**
  - Flags visible Buttons and Labels sticking out of the window (ignoring anything inside a ScrollContainer or clip parent).
  - Flags any 3D SubViewport rendering below its on-screen pixel size.
  - Records each texture's screen-pixels-per-texel. Prints `TEX` lines for art that is upscaled more than 1.3x or downscaled below 0.55x.
- **Review:** I looked at every screen at 16:9, 20:9, 4:3 and 21:9 using contact sheets, then at full-size shots and 1:1 crops for sharpness. `tests/review/res/crop.gd` is a headless crop and side-by-side helper.

## Findings per size (before fixes)

| Size | Stretch | Canvas | Findings |
|---|---|---|---|
| 1280x720 | 1.0 | 1280x720 | Baseline. Gear-slot icons drawn at 0.34x without mipmaps had jagged edges. The AUTO hex text spilled past its border. At the hideout boss, long "Counter with" tips overlapped the model's ring. |
| 1920x1080 | 1.5 | 1280x720 | 3D (battle, diorama, model previews) rendered at 1280x720 and was upscaled: soft. |
| 2560x1440 | 2.0 | 1280x720 | 3D at half resolution: visibly blurry. Armoury art upscaled 1.33x. |
| 3840x2160 | 3.0 | 1280x720 | 3D at one third resolution: very blurry. Armoury art kit upscaled 2.0x: soft but clean. Fonts are crisp (rasterised at the real size). |
| 2400x1080 (20:9) | 1.5 | 1600x720 | Layout fine. The Armoury canvas is centred (pillarboxed). 3D soft as at 1080p. |
| 2048x1536 (4:3) | 1.6 | 1280x960 | **City squad line-up zoomed in and cropped the 4th warlord's ring.** The Armoury is centred and letterboxed. The extra height is spare space on the shop, Pit and Battle hub, but nothing is clipped. |
| 3440x1440 (21:9) | 2.0 | 1720x720 | Layout fine and everything centred. 3D at half resolution. |

The off-screen audit found 0 controls outside the window at any size, before and after the fixes.

## What I changed

1. **3D renders at real pixels.**
   - New `scripts/ui/view_3d.gd` (`class_name View3D extends Control`). SubViewportContainer's `stretch` sizes the viewport in canvas units, and Godot 4.3 refuses a manual `vp.size` while stretch is on. So View3D owns the SubViewport and draws its texture itself with `draw_texture_rect` over its own rect.
   - Every frame it sets `vp.size = size × render_scale()` and redraws when that changes. `render_scale()` is `get_viewport().get_final_transform()` (window stretch) × `get_global_transform_with_canvas()` (parent scales, e.g. the Armoury's 1920 canvas). This covers window resizes, the Armoury canvas rescale and any scale tweens.
   - On mobile (`OS.has_feature("mobile")`) the scale is capped at `View3D.MOBILE_MAX_SCALE = 1.25`.
   - `battle_view_3d.gd` and `model_preview.gd` now `extends View3D`. I dropped their own `vp` declaration and `stretch = true`. `district_diorama.gd` hosts its viewport in a `View3D` instead of a SubViewportContainer.
   - None of them took input through the container: battle and diorama ignore the mouse, and ModelPreview uses its own `_gui_input`. `screen_pos()` and `_layout_pins()` already scale by `size / vp.size`, so reticles, HUD bars and diorama pins still line up.
   - Verified: vp is 3840x2160 at 4K, 2400x1080 at 20:9 and 3440x1440 at 21:9. The 1:1 crop of a battle unit is clearly sharper than before.
2. **Mipmaps for heavily shrunk art.**
   - Set `mipmaps/generate=true` on 131 `assets/ui` textures drawn below about 0.55x. These are the NN/MF icons (0.24x), equipment selection borders (0.21x), gear/implant/ability slot buttons (0.26–0.34x), rank chevrons (0.53x), deed icons and neons. I deleted their `.godot/imported/*.md5` files to force a reimport.
   - Set `rendering/textures/canvas_textures/default_texture_filter=3` (linear with mipmaps) in `project.godot`.
   - Textures without mipmaps look exactly as before. Magnified art is unchanged. Gear-slot icon edges are visibly smoother at 720p.
3. **City line-up at 4:3.**
   - `ModelPreview` now has `var ref_aspect` (default `REF_ASPECT` 1.23) in place of the constant in `_fit_fov`. `city.gd` sets `mp.ref_aspect = 1.6`, the panel's 16:9 aspect.
   - Narrower (4:3) panels now keep the 16:9 horizontal framing instead of zooming in, so all four warlords and rings are visible. 16:9 and wider are unchanged.
4. **Hideout boss spacing** (`hideouts.gd` `build`): the 3D boss's top and bottom now follow the header and the "Counter with" block (`hv.resized` / `tv.resized`). Five tip rows no longer overlap the ring. The old 200 / -150 offsets remain the minimum, so short bosses look the same.
5. **AUTO hex** (`battle.gd`): `auto_btn.glyph_size` changed from 20 to 16. The word sat on and past the hex border at every size.

The Armoury layout, the absence of a turn-order bar and Quick Navigation are untouched, as decided. I did not touch `Content.gd` or `playthrough.gd`.

## Re-shoot and regression runs

- Full matrix re-shot after the fixes: 98 PNGs, 0 audit issues, every 3D view at full pixel size.
- I re-reviewed the contact sheets, and the 4:3 city, hideout and Armoury at full size.
- `--import` compile check: 0 `SCRIPT ERROR`.
- `TestRunner.tscn` headless: `TESTS DONE, failures: 0`.
- `UiSmoke.tscn` headless: `UI SMOKE DONE`. Every Armoury page is OK, and the battle, Pit, hideout and bastion flows all finish.
  - It prints about 1,600 `mesh_get_surface_count: Parameter "m" is null` errors. These come from the headless dummy renderer reading primitive meshes. I didn't add any mesh code and believe they predate this change, but I didn't run a baseline to confirm.

## Left over

- **Art for 2x versions** (the kit is authored for 1920x1080; the Armoury canvas draws it at 1.33x on 1440p and 2.0x on 4K, so it is soft though not broken):
  - Everything in `ArmouryBarG`, `FilterBarsG` (EQ and WL filter buttons and bar backgrounds), `GearScreenG` (slot buttons), `StatsG` (StatsPanelBGI, StatsTitleI, Stat*IncIconI, SetSlotsI, StatExpandButton) and `WarlordTitleZoneG` (RankChevron*I, WarlordLVLI, RarityRingI, ClassSymbol*, SyndicateSymbol*).
  - In `NeuroNetScreenG`: tab buttons, TierBG, skill buttons, OwnedMFBackground, Tier*MFIcon, CostSlot, InstallButton, PointUnspent.
  - `GearSetSymbol*`.
  - **Not needed:** the NN/MF icons (359x410), deed icons (212x312) and selection borders (190x230). They are already drawn at or below 1x even at 4K.
  - With 2x art, load it at 4K-class scales (e.g. `Art` picks `@2x` when `View3D`-style render scale > 1.4) and keep the same layout coordinates.
- **Mobile cap:** `MOBILE_MAX_SCALE = 1.25` is a guess (a 2400x1080 phone renders 3D at 2000x900). Profile on a device and tune it. Nothing here could be tested on a phone.
- **4:3 spare height:** the shop, Pit list and Battle hub cards stay at their 720-high layout and leave empty space at the bottom on tablets. Nothing is clipped, but a tablet pass could let those rows fill the height. That would be a design change, so I didn't make it.
- **Armoury 3D turntable:** the ring is cut by the bottom edge of its preview rect at every size. That is part of the kept Armoury layout, so I left it.

## Layout pass (follow-up)

Goal: screens should look like the design canvas at every window shape, not just fit. The canvas artboards are all 1280x720, so 16:9 is the reference.

**Shots.** Before: `user://shots_layout_before/<WxH>/`. After: `user://shots_layout_after/<WxH>/`. Both sets are at 2048x1536, 1920x1080, 3440x1440, 5120x1440, 2400x1080 and 1080x1920 (all under `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\`). `shots_res.gd` now takes a size list (`--size=WxH,WxH`) and `--out=<dir>`, and also shoots Gang, Missions and Settings. The 7-size matrix in `shots_res/` was re-shot as well.

### Changes

1. **Ultra-wide menu safe area** (`Main._apply_safe_area`, `MENU_MAX_W = 1720`, which is 21:9 / 3440x1440 at the 720-high canvas). Past 21:9, the screen body (`content`), the HUD row and the nav buttons are centred inside 1720 canvas units. The HUD and nav bar backgrounds and the city art stay full width.
   - `Screen.full_bleed` opts a screen out. Battle uses it, so the 3D fight stays full width.
   - `Screen.bleed` lists full-rect art nodes that stretch back out to the window edges. The Recruit pawn-shop room uses it, so the counter and floor span the window while its shelf, odds tag and buttons stay in the safe area.
   - `Screen.rebuild` re-applies the safe area. Up to 21:9 nothing changes (the extra width is 0), so 16:9, 20:9 and the user's 3440x1440 monitor look the same as before.
2. **Taller than 16:9.** `Screen.tall_extra()` returns the canvas height beyond 720 (240 at 4:3). A screen that uses it rebuilds when the window's shape changes.
   - The Shop Featured page gives 40% of that height to the banner and 60% to the four offer cards.
   - The Battle hub key-art cards grow by 70% of it and stay vertically centred.
   - The Pit already fills 4:3 because its opponent list is a scroll that shows more rows, so I left it unchanged.
3. **Contract card art** (`shop.gd` `_cases`): the grey rectangles are replaced by two stacked Recruit `ContractCase` cases at 0.42 scale, in the pack's rarity colour (LED strip and latches).
4. **Dev text in release builds:**
   - Hidden: the Shop's "not connected in this prototype / Free IAP (dev)" line, and the city Settings sign's "developer" wording.
   - Already gated: "FREE IAP DEV MODE", "Prototype build" and the Settings developer rows.

### Judged against the canvas

| Size | Before | After |
|---|---|---|
| 1920x1080 | Matches the canvas apart from the grey contract placeholders | Contract cases drawn; otherwise unchanged |
| 3440x1440 | Right | Unchanged (safe area equals the canvas width) |
| 2400x1080 | Right | Unchanged |
| 2048x1536 | Shop and Battle hub left the bottom third empty | Shop banner and cards and the Battle hub cards fill the height (`10_shop.png`, `10_fight.png`); Pit fills with more rows |
| 5120x1440 | Shop cards were thin strips; City HUD and side panels sat at the far edges; nav spread over 32:9 | Shop, City (HUD, side panels, Next Goal, Battle button), nav, Pit, Hideouts and Campaign sit in a centred 21:9 area. Recruit room and battle stay full width (`01_city.png`, `10_shop.png`, `10_recruit.png`) |
| 1080x1920 | Letterboxed 16:9 (coordinator's `_fit_aspect`) | Same; layout is the 16:9 one |

### Verification

- Size audit at all 13 sizes (the 7-size matrix plus the 6 above): 0 off-screen controls, and every 3D view at full pixel size.
- `--import` compile check: 0 `SCRIPT ERROR`.
- TestRunner: `failures: 0`.
- UiSmoke: `UI SMOKE DONE`.

### Left over

- **Armoury at 32:9:** still a centred 1280x720-proportioned box. The canvas is height-bound and the Armoury layout is kept as is by decision, so it fills the same share of the screen as at 21:9.
- **Campaign diorama at 32:9:** framed inside the safe area, so it reads as a map panel beside the stage sheet rather than full-bleed 3D. It could join `Screen.bleed` if full width is preferred, but then the map would slide under the right panel.
- **Release builds give real-money packs away free:** `Game.gd` defaults `settings.free_iap` to `true`, so a release export grants those packs for nothing. Only the text is gated today. Suggested fix: default it to `OS.is_debug_build()`. I didn't change it, because it is an economy rule in `Game.gd`.
