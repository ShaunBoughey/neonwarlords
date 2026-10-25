# Section 16 review: Overview, Level Design, User Interface, Finance

Reviewer: section-16 session. Read-only review; nothing under `scripts/`, `scenes/`, `assets/`, `data/` or `project.godot` was changed.

**Probe files** (all under `tests/review/16/`):
- `Tour16.tscn` / `tour16.gd`: visits every screen and takes a screenshot of each. On each screen it also audits every visible control for:
  - buttons smaller than 44 px
  - buttons with no handler
  - font size under 14
  - text that goes off-screen
  - emoji codepoints
- `Ftue16.tscn` / `ftue16.gd`: a copy of `tests/ftue.gd` that saves to `shots_16/ftue/`.

**Runs** (all with `NW_SAVE=16`, windowed):
- `std`: 1280x720, 16:9
- `phone`: `--resolution 1560x720`, 19.5:9
- `tablet`: `--resolution 1024x768`, 4:3, which the engine runs as a 1280x960 viewport

**Screenshots** are in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_16\`, under `std/`, `phone/`, `tablet/` and `ftue/`. I looked at every std and FTUE shot, plus the key phone and tablet shots.

**FTUE result:** `FTUE TEST DONE, failures: 0`. All 13 coach steps completed and the unlock card appeared.

**Totals:** OK 22 · MISSING 5 · WRONG 1 · DEVIATION 3 · N/A 5 (36 items)

---

## 1. GDD items

| # | GDD item | Status | Evidence / note |
|---|---|---|---|
| 1 | Mobile turn-based looter set in a neon dystopian world | OK | The battle is turn-based, loot drops everywhere, and the neon city sets the tone. |
| 2 | Players level characters and work their stats for PvE (Campaign, Hideouts) and PvP (Arena) | OK | Armoury stats, gear, Neuronet. The Campaign, Hideouts and Pit screens all exist. |
| 3 | "Same vein as RAID, SWGOH, Overhit" | OK | Uses the RAID hub pattern: City hub with the squad centre stage, hex BATTLE button, bottom nav and currency pills. |
| 4 | 3D design with a clean GUI | OK | Battle, city squad, campaign district map and Armoury are 3D. The models are placeholders, which `GDD_COVERAGE.md` already notes. |
| 5 | "Harnessing the power of Unreal Engine" | DEVIATION (undocumented) | The project is built in Godot 4.3, and `GDD_COVERAGE.md` never says so. **Add a line** under "Design choices". |
| 6 | Mission: a ragtag group fights its way through the gangs of the city | OK | The Campaign dens are gang territories. The inbox welcome says "Your ragtag crew needs gear". |
| 7 | Levelling characters, collecting gear, finding companions | OK | Levels and ranks, gear drops, Recruitment contracts. |
| 8 | PvE: campaign and boss fights in hideouts | OK | `campaign.gd`, `hideouts.gd` |
| 9 | PvP against other players' teams | MISSING (backend) | The Pit opponents are generated offline (`Content.pit_*`). This is expected for a prototype, but real PvP needs the backend (#15/#16). |
| 10 | "This will be an Android game" / Platforms: Android planned | MISSING | `export_presets.cfg` has only a "Windows Desktop" preset. Prep is in place: the `mobile` renderer and ETC2/ASTC import are already on in `project.godot`. |
| 11 | iOS later | N/A | Future work |
| 12 | Web or Play launcher possible | N/A | |
| 13 | Genre: mobile looter, collection, PvE, PvP | OK | |
| 14 | Technology: Unreal Engine 4 | DEVIATION | Same as #5 (Godot). The Unreal assets "Soul: City" and "Firebase Blueprints" don't apply. The mood they were for is delivered by the city background art and `battle_view_3d.gd`. |
| 15 | Firebase Authentication | MISSING | `login.gd` is a local name prompt with no account or sign-in. |
| 16 | Firebase Database (cloud save, economy) | MISSING | The save is local JSON only (`user://save*.json`). |
| 17 | Firebase monitoring/analytics, release pipelines | MISSING | No analytics hooks. |
| 18 | Target: grindy looter with lots of character progression | OK | |
| 19 | Short regular sessions | OK | Auto battle, x3 speed, REPLAY on results, daily and weekly jobs, login calendar. |
| 20 | "Possibly with a side of being able to idle the game" | OK (light) | Trinium Stocks builds up passively ("0 / 75 stored"). There is no auto-repeat or multi-battle, which is the RAID-style answer here. That is an open lever, not a bug (see P3-9). |
| 21 | Audience dislikes energy limits | OK per GDD | Energy exists because the GDD's own Currencies section defines it, and the cap of 160 and refills are generous. Not flagged. |
| 22 | Audience dislikes gear duplication from missions | N/A | No testable rule |
| 23 | Bragging rights / top percentile | OK | Pit brackets, leaderboard tab, weekly ranking. |
| 24 | Level Design: "Slums Levels" (template text plus 3 rainy-alley mood images) | WRONG (visual) | Slums is Den 1, and the city background matches the wet neon alley mood. But the battle "wet floor" relies on SSR, which the mobile renderer ignores: the log shows `Screen-space reflections (SSR) can only be enabled when using the Forward+ rendering backend`. The battle street therefore renders dry and matte, not like the GDD's puddle images (`battle_view_3d.gd:_wet_floor`, around line 137). See P2-1. |
| 25 | UI flow: Player Start → Login → City Centre | OK | `Main._ready` → `go("login")` → `home()` |
| 26 | UI flow: Tutorial (optional, from Login) | OK | Coach FTUE starts after START. It has SKIP GUIDE, and Settings has "Replay tutorial". FTUE probe: 0 failures. |
| 27 | City ↔ Shop, Settings, Inbox/Friends, Account | OK | The audit found 0 dead buttons on all screens. |
| 28 | City ↔ Clans (Gang), Events, Login Rewards, Missions | OK | The Events cards each route to their mode (`events.gd:10-16`). |
| 29 | City ↔ Inventory, Recruitment Office, Black Market, Safe house | OK | |
| 30 | Tavern | DEVIATION | Already documented: it has no GDD text. |
| 31 | Fight → Campaign map → area/stage select → Squad → Fight → Result | OK | Results has STAGE MAP / REPLAY / NEXT STAGE. |
| 32 | Fight → Hideout map → level select 1-20 → Squad → Fight → Result | OK | Stage grid 1-10 and 11-20 |
| 33 | Fight → Syndicate Wars → Syndicate select → Stage select 1-20 → Squad → Fight → Result | OK | |
| 34 | Fight → Arena → Opponent select → Squad → Fight → Result | OK | |
| 35 | Finance: conversion, ARPPU/ARPDAU, Firebase cost tables, revenue tables | N/A | Business planning with no game rules. Shop prices (£4.99 to £49.99, battle pass £15/£25) sit within the GDD's ARPPU assumption. Section 15 owns the price list. |
| 36 | Finance: "Unreal 5%" royalty line | N/A | Godot has no royalty, so this cost line drops out. Worth noting in the business plan. |

Status count from the table: OK 22, MISSING 5 (#9, 10, 15, 16, 17), WRONG 1 (#24), DEVIATION 3 (#5, 14, 30), N/A 5 (#11, 12, 22, 35, 36).

---

## 2. Whole-game checks (vision, mood, mobile)

### 2a. Aspect ratio
- `project.godot`: base 1280x720, `canvas_items` stretch, `expand` aspect. It is landscape-only, like RAID. **Good choice.**
- **Phone, 19.5:9** (`phone/*.png`): every hub widens cleanly. Side rails stay anchored, the Battle cards centre, and the campaign map stretches. Nothing breaks.
  - Arena's last opponent row and squad roster tiles run under the bottom edge. That is expected for scroll lists.
- **Tablet, 4:3** (`tablet/*.png`): the viewport grows to 1280x960.
  - **Bug:** the City squad 3D view crops the two outer warlords with hard vertical edges (`tablet/03_city.png`). See P2-2.
  - The Armoury letterboxes with empty space top and bottom. The Armoury is kept as-is by user decision, so this is not flagged.
- **No safe-area handling.** Nothing calls `DisplayServer.get_display_safe_area()`. On notched phones in landscape, the camera cutout will sit over:
  - the top-left back button and profile hex at x 20-64
  - the left rail icons
  
  See P2-4.

### 2b. Touch targets
The audit measured every visible `BaseButton` and `LineEdit` against the design canvas rule "All buttons ≥ 44px tall; CTAs 56px". All primary CTAs pass: BATTLE hex, gold CTAs at 56, bottom nav at 76, back button at 44. These fail:

| Control | Size | Where | Screens |
|---|---|---|---|
| Top-bar "+" on Energy and Trinium | **32×32** | `Main.gd:_pill` line 281 | every screen with the HUD (25 of 29) |
| Campaign map location pins | 38×34 | `district_map.gd:197` | campaign |
| Shared segmented tabs: Brawl/Royal, Fight/Defence, sort, slot filters, Inbox/Friends, roster class filter | 40 tall | `screen.gd:tabs` line 53 | arena, armory, inventory, inbox, squad |
| Hideout stage grid | 60×40 | `hideouts.gd:115` | hideouts |
| Campaign difficulty segmented | 42 tall | campaign header | campaign |
| Armory rarity filter chips | 43 tall | | armory |
| FTUE "SKIP GUIDE" | 114×36 | `coach.gd:47` | FTUE (GO button is 40 at `coach.gd:51`) |
| Armoury bottom bar buttons, AUTO EQUIP, a 19 px TextureButton | 34 tall | | warlord (kept as-is, listed for info only) |

**Physical size note.** On a 6.1" phone, 720 canvas px is about 67 mm, so 44 canvas px is about 4 mm. Apple's 44 pt and Android's 48 dp are about 7-9 mm. The 44 px floor is therefore already a compromise on phones. Raising the shared minimum to 48, and the HUD "+" to at least 44, is the cheap win (P2-3). This is an open lever: the GDD doesn't specify it.

### 2c. Text size
The design canvas sets a body minimum of 14 px, with 12 px allowed for caps labels (`UI.cap`). Below 12 px:
- **11 px** text appears in several places:
  - fight card mode tags ("PVE • STORY")
  - login-rewards day tags
  - mission "PROGRESS"
  - inbox timestamp
  - squad slot labels and names
  - result "LEVEL UP / MVP / DEFEATED"
  - shop "BEST VALUE / LIMIT"
  - `UI.reward_tile` label (`ui.gd:345`, size 11)
- **9 px** "★" on squad cards.

See P3-1.

### 2d. Login, tutorial, FTUE
- **Login** (`std/01_login.png`): a functional name prompt.
  - It is the weakest screen against the "rainy neon" vision. Flat gradient, no key art, no rain, title in plain `lbl` instead of the display style.
  - It shows debug text: **"Prototype build • Godot 4"** at 12 px (`login.gd:56`).
- **FTUE** (`ftue/70_*.png`): passes. The coach spotlights each target, and the bubble text is clear. Two issues:
  - `ftue/70_ftue_09_recruit.png`: the previous step's toast "Equipped 8 items" sits **on top of the highlighted OPEN ×1 target**. Toasts are centred at bottom −140 (`Main.gd:67`), which is the same band as most screens' CTA rows. See P2-5.
  - The battle step's bubble covers the upper enemy rows. Acceptable.
- **Unlock announcement** (`ftue/79_unlock_card.png`): clean, with one gold GO. OK.

### 2e. Shell: top bar and bottom nav
- Matches the canvas spec exactly:
  - top bar 64 px with gradient fade
  - bottom nav 76 px, 7 tabs, active cyan bar and glow, lock icons for gated tabs, red count badges
  - back button plus title with accent dashes on flow screens
  - profile hex plus XP bar on City
- The Pit Coin pill appears only on Arena, Black Market and Safehouse. Good.
- Hub vs flow is respected: the nav is hidden on flow screens.
- City (`std/03_city.png`) is a close match to canvas board "01 City Centre": left rail, centre squad and power, right district signs, next-goal strip, hex BATTLE.
  - One gap: the canvas says the 3D squad is "tap to open Armoury", but city's `ModelPreview` has no `model_clicked` handler. See P3-6.

### 2f. Visual consistency with the approved canvas
Screens that match the v2 system (notched panels, Orbitron display, cyan/gold roles, rails):
- City, Battle hub, Campaign, Hideouts, Warlords, Inventory, Missions, Login Rewards, Shop, Results, Pit

Screens still in the older look:
- **Battle Pass** (`std/10_battle_pass.png`):
  - title-case "Claim" buttons
  - two gold buttons in the header
  - plain-text track
  - "BATTLE PASS - SEASON 5" uses a hyphen where the rest of the UI uses "•"
- **Gang** (`std/10_gang.png`):
  - dense paragraphs with "[ACTIVE]" bracket text
  - title-case "Rename"
  - tiny chat box
- **Account** (`std/10_account.png`): long text list
- **Events** (`std/10_events.png`): cards with no icon or art and no visible affordance, although they are tappable
- **Settings** (`std/10_settings.png`): player-facing dev rows ("Free IAP (dev mode)", "Developer: grant test items", raw save path)

**"Gold = max one per screen" is broken on:**
- Shop: 4 gold price buttons plus the featured one
- Battle Pass: 2 header buttons
- Inbox: Claim All plus each Claim
- Plaza: every buy button
- Settings: "Grant"

Shop and Plaza are catalogues, so this is defensible there, but Settings and Battle Pass should follow the rule. See P3-3.

**Emoji are rendering as colour emoji** via the Windows fallback font. This breaks the "no emoji, stroke icons" rule:

| Screenshot | What shows | Source |
|---|---|---|
| `std/10_plaza.png` | ⚔ crossed swords and ⚗ alembic as full-colour emoji tile icons | `plaza.gd:20` uses `U.reward_icon` |
| `std/10_missions.png` | ✉ envelope on "10x Brawl Invite"; ⚡ on "Energy Battery" | `UI.reward_chips` → `UI.chip(U.reward_icon(r)...)`, `ui.gd:380` |
| `std/10_inbox.png` | ⚔ on "Set of Rank 2 Health Equipment" | same path |

Source of the glyphs: `U.REWARD_ICON` (`U.gd:316-320`), `Game.gd:1802` (`"%d ⚡"`) and the `ui.gd:340` fallback glyph in `reward_tile`. See **P1-1**.

**Other text and labels:**
- `Content.build_campaign` titles fights "Slums 1:1" (`Content.gd:85`). Campaign, city goal and stage panel all say "1-1", and squad and battle headers show "SLUMS 1:1". See P3-4.
- Clipped text: `std/10_hideouts.png` rail row "TeraTek Cyberneti" is cut off with no ellipsis.
- `std/10_inventory.png`: the slot tab strip is cut at "C…" (CHEST, GLOVES, LEGS, BOOTS hidden) because the Sell button takes the rest of the row. See P2-6.
- Campaign map labels overlap their pins: "CHOP A[pin]EY", "RAIL BR[pin]GE" (`std/10_campaign.png`). See P3-5.
- Placeholder art, already known, listed for completeness:
  - Battle hub mode cards, Hideout boss and Shop featured pack use generic silhouettes
  - Recruit cases and Shop "Small Rare Contract" use grey boxes
  - The canvas itself says these need Blender portrait renders
- Inbox copy: "1 messages, 1 unclaimed". See P3-7.

---

## 3. Visual issues (screenshot index)

| Issue | Screenshot |
|---|---|
| Colour emoji ⚔ ⚗ as Plaza tile icons | `shots_16/std/10_plaza.png` |
| Colour emoji ✉ (and ⚡) in mission reward chips | `shots_16/std/10_missions.png` |
| Emoji ⚔ in inbox reward chip | `shots_16/std/10_inbox.png` |
| City squad cropped at 4:3 | `shots_16/tablet/03_city.png` |
| Battle street dry/matte (no SSR on mobile renderer) vs GDD rain-puddle mood | `shots_16/std/31_battle.png` vs GDD images 10/1/2 |
| Toast covering FTUE target | `shots_16/ftue/70_ftue_09_recruit.png` |
| Inventory slot tabs cut at "C…" | `shots_16/std/10_inventory.png` |
| "TeraTek Cyberneti" clipped | `shots_16/std/10_hideouts.png`, `12_hideout_vikings.png` |
| Map labels under pins | `shots_16/std/10_campaign.png` |
| Debug text "Prototype build • Godot 4" | `shots_16/std/01_login.png` |
| Dev subtitle "FREE IAP DEV MODE • NO PAYMENT TAKEN" in shop header | `shots_16/std/10_shop.png` |
| Dev rows and save path in Settings | `shots_16/std/10_settings.png` |
| Old-style screens (two gold buttons, title-case buttons, text walls) | `std/10_battle_pass.png`, `10_gang.png`, `10_account.png`, `10_events.png` |
| "Slums 1:1" vs "1-1" | `std/30_squad.png`, `31_battle.png` vs `10_campaign.png` |

---

## 4. Prioritised fix list

### P1: breaks a rule
1. **Replace text glyphs with stroke icons or art for every reward.** These render as colour emoji. Changes:
   - **`scripts/ui/ui.gd` `reward_chips()`**: stop calling `chip(U.reward_icon(r), …)`. Build the chip with `""` as the icon, then insert `reward_node(r, size + 8)` as the first child of the chip's HBox. `reward_node` already maps every reward key to art or an `Icon.make` stroke icon.
   - **`ui.gd` `reward_tile()`** (around line 340): replace the `lbl(r.get("icon", "•") …)` fallback with `reward_node(r, int(sz * 0.6))`.
   - **`scripts/ui/screens/plaza.gd:20`**: replace `UI.lbl(U.reward_icon(r), 44, col, …)` with `UI.reward_node(r, 48)`.
   - **`scripts/core/Game.gd:1802`**: change `"%d ⚡"` to `"%d Energy"`, or have the caller render `Icon.make("bolt", …)`.
   - Optionally delete `U.REWARD_ICON` so the glyph path can't come back.

### P2: wrong or ugly
1. **Wet street on the mobile renderer.** In `scripts/combat/battle_view_3d.gd` `_wet_floor()`, SSR is a no-op under `renderer/rendering_method="mobile"`. Add a `ReflectionProbe`, which the mobile renderer supports:
   - `update_mode = UPDATE_ONCE`, `box_projection = true`
   - extents covering the arena, placed at street height
   - keep the puddle material at low roughness and high metallic
   
   Stop calling `environment_set_ssr` / SSAO to clear the warnings. This restores the GDD's rainy-puddle Slums look.
2. **City squad crop at narrow aspects.** In `scripts/ui/model_preview.gd`, handle `resized` (or check in `_place_camera()`):
   - when `size.x / size.y < 1.23` (the 16:9 city ratio), set `cam.keep_aspect = Camera3D.KEEP_WIDTH` and `cam.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(17.0)) * 1.23))` (about 41°)
   - otherwise keep `KEEP_HEIGHT` with fov 34
   
   This keeps all 4 warlords in frame on 4:3 tablets.
3. **Touch-target floor.** Changes:
   - `scripts/ui/Main.gd:_pill()` line 281: `Vector2(32, 32)` → `Vector2(44, 44)`, and re-centre the plus icon (`pi.position = Vector2(15, 15)`).
   - `scripts/ui/screen.gd:tabs()` line 53: `custom_minimum_size.y = 40` → `48`.
   - `scripts/ui/screens/hideouts.gd:115`: stage buttons `40` → `48`.
   - `scripts/ui/district_map.gd:197`: small pins `Vector2(38, 34)` → `Vector2(44, 44)`. The visual can stay small if you widen only the hit rect.
   - `scripts/ui/coach.gd:47` and `:51`: SKIP GUIDE and GO to `44`.
4. **Safe area.** In `scripts/ui/Main.gd` `_ready()` (and on `get_viewport().size_changed`), read `DisplayServer.get_display_safe_area()`, convert it to canvas units, and apply it as left/right offsets on `hud`, `nav` and `content`. On desktop it returns the full window, so this is safe to ship now.
5. **Toasts over CTAs.** In `scripts/ui/Main.gd:_ready()` lines 64-67, anchor `toast_box` to `PRESET_CENTER_TOP` at `position = Vector2(-220, 72)`, just under the HUD. That keeps toasts clear of the CTA band and of the coach spotlight.
6. **Inventory tab strip clipped.** In `scripts/ui/screens/inventory.gd`, put the slot `tabs()` row and the "Sell unequipped…" button on separate rows, or wrap the tabs in `UI.scroll(tabs, true)`. Per the canvas "Catalogue" pattern, slots could also become a second level in the left rail.
7. **Document the engine.** In `GDD_COVERAGE.md` → "Design choices", add: "Engine: Godot 4.3 (mobile renderer) instead of Unreal Engine 4. Firebase auth, cloud save and analytics not yet integrated (local JSON save). No Android export preset yet." Add an Android export preset when device testing starts. That item is MISSING #10, and it is the stated platform.

### P3: polish
1. **Sub-12 px text** → 12 px minimum:
   - `ui.gd:345` `reward_tile` label 11 → 12
   - fight card mode tags (`fight.gd`)
   - result tags (`battle.gd` results)
   - squad slot labels and the 9 px "★" (`squad.gd`)
   - shop "BEST VALUE"/"LIMIT" (`shop.gd`)
   - mission "PROGRESS" (`missions.gd`)
2. **Hide dev text from players**, gated behind `OS.is_debug_build()` or a dev flag:
   - `login.gd:56` "Prototype build • Godot 4"
   - `shop.gd:11` subtitle "Free IAP dev mode • no payment taken"
   - `settings.gd`: "Free IAP (dev mode)", "Developer: grant test items" and the save path row
3. **One gold per screen** (canvas rule): in `battle_pass.gd`, make "Premium +25 Lv" the cyan-outline style; in `settings.gd`, make "Grant" ghost. Bring Battle Pass, Gang, Account and Events up to the v2 look:
   - uppercase display buttons
   - Events cards get an `Icon.make` glyph and a chevron "›" affordance like the City district signs
   - Gang ability text drops the "[ACTIVE]" brackets in favour of `UI.tag`
4. **Stage naming.** `scripts/core/Content.gd:85`: `"%s %d:%d"` → `"%s %d-%d"`, to match "Stage 1-1" everywhere else.
5. **Map label overlap.** In `scripts/ui/district_map.gd`, offset the location name labels below the pin's footprint ring (`+18 px y`), or draw the labels behind the pins.
6. **City squad tap → Armoury** (canvas board 01): in `city.gd` after `mp.set_models(models)`, add `mp.model_clicked.connect(func(i): main.go("warlord", {"uid": squad[i]}))`.
7. **Inbox copy.** In `inbox.gd`, pluralise: "1 message".
8. **Hideouts rail.** In `hideouts.gd`, enable `text_overrun_behavior = OVERRUN_TRIM_ELLIPSIS` on the rail name label, or use the short name "TeraTek".
9. **Open lever, "idle the game"** (GDD Target Audience): a RAID-style multi-battle / auto-repeat toggle on the Results screen. Repeat the stage N times while energy lasts. The GDD doesn't specify it, so treat it as a suggestion.

---

## Wave 1 applied (owner C)

**Changed (owned files only):**
- **Reward icons (16:P1, 13:#2, 15:P3-6, 10:P3-5).** `UI.reward_node(r, size)` is now the only icon path.
  - `ui.gd` `reward_chips` builds each chip around `reward_node`.
  - `reward_tile` (which feeds `Main.show_rewards`) uses `reward_node` too. It reads `r.reward` or `r.k` when present; otherwise it maps the `Game.grant` glyph back to its kind (`UI._glyph_kind`).
  - `reward_node` gains stroke icons for stimm, firmware, raidTicket and merits.
  - `U.REWARD_ICON` no longer has any emoji-presentation glyphs. ⚡ ✉ ⚗ ⚔ ⚙ ⛁ became ϟ ▭ ⬡ ◈ ◎ ◉, kept only as a plain-text fallback.
  - The modal close "✕" became a 44×44 stroke icon.
- **Touch targets (16:P2-3).**
  - HUD "+" buttons are 44×44, and pills are 44 tall (`Main._pill`).
  - `Screen.tabs` buttons are 48 tall.
  - Coach SKIP GUIDE and GO are 44 tall.
  - Re-audit: 0 controls under 44 px on all my screens.
- **16:P2-4 safe area.** New `Main._apply_safe_area()` insets `hud`, `nav` and `content` by the display's safe area when the window fills the screen. It re-runs on resize and on every screen change.
- **16:P2-5 / 12:#6 toasts.** Moved to the top centre, just under the HUD (y 72).
- **12:#2 unlocks.** When several features unlock at once, one card shows a row per feature, each with its own GO. A single unlock uses the old card.
- **12:#3** City and Battle hub rebuild when features unlock.
- **12:#5 level-up card.** Listens to `Game.player_leveled`. The card shows "PLAYER LEVEL N", "Energy refilled" and the reward chips. CLAIM claims that level's mail. Cards queue ahead of unlock cards and use the same guards (battle, login, squad, coach).
- **11:#8** The HUD title and subtitle trim with an ellipsis. The title box expands, so long titles can't push the currency pills off-screen.
- **16:P2-2 model_preview.** On narrow containers it keeps the 16:9 horizontal FOV, so the outer models no longer get cropped. Verified in `shots_16/tablet/03_city.png`.
- **City:**
  - 16:P3-6: tapping a squad model opens that warlord's page.
  - 14:P3-11: added a Plaza sign.
  - 11:#2: the Stocks modal names the unlocking ambition, read from `Data.STOCK_LEVEL_AMBITION`, and includes `cap_bonus`.
  - 11:#15: Collect is disabled when nothing is stored.
- **15:P3-5** HUD energy "+" opens Shop › Trinium Market; trinium "+" opens Trinium Vault.
- **16:P3-2.** Behind `OS.is_debug_build()` now:
  - login "Prototype build"
  - Settings dev rows: Free IAP, Grant (now ghost style, 16:P3-3) and the save path
- **16:P3-3 events.** Cards now use the v2 style: notched panel, stroke icon, display-type title, chevron.
- **16:P3-7** Inbox says "1 message" for a single mail.
- **16:P3-1 (ui.gd)** `reward_tile` label 11 → 12 px; `item_card` set name 10 → 12 px.
- **08:#1 (U.gd)** Both credit regexes now accept `\s*Credits`.
- **Extra:** added `U.secs_to_next_month()` for F's 13:#8 (Jobs monthly reset text).

**Verification:**
- Compile check is clean.
- `TestRunner`: failures 0.
- `UiSmoke`: completes. Its SCRIPT ERRORs (`DistrictMap.stage_name` / `declutter`) come from H's in-progress `district_map.gd`, not my files.
- `Ftue16`: failures 0.
- Re-ran the std and tablet tours and checked the screenshots: level-up card, city, missions, events, plaza, tablet city, FTUE.

**Skipped:**
- `Game.gd:1802` belongs to E.
- `plaza.gd:20` belongs to F, and it is already redrawn with art.
- The quicknav dead code in `Main.gd` was left alone. Quick Navigation was removed on purpose and nothing calls it.

**Requests:**
- **E:** optionally add `"reward": r` to each `Game.grant` display entry (`Game.gd:1088`, and the neon entry around 1081). `reward_tile` then gets exact art without the glyph lookup.
- **E:** `Data.SLOT_ICON` still holds emoji-capable glyphs (✋ ⛑ ⚙ ♥ ☠ ⚔), used by `item_view.gd:9` (A's file).
- **A:** `item_view.gd:9` should use `Art.SLOT_BUTTON` art instead of `Data.SLOT_ICON`.
- **Coordinator:** add the engine line from P2-7 to `GDD_COVERAGE.md`.
