# Review 06 - City Centre and Campaign

GDD text: `review/gdd/06_city-campaign.txt` (City Centre paragraph, Campaign rules, Reward Table, Additional Drops, Progression Rewards, Enemy Levels).
Code checked: `data/gdd.json` (`campaign`, `campaignProgress`), `Data.CAMPAIGN_*` (`scripts/core/Data.gd:383-397`), `Content.build_campaign / campaign_set / campaign_rewards / chevrons / finish` (`scripts/core/Content.gd:49-127, 395-480`), `Game.campaign_*` / `claim_campaign_progress` / `corpo_tower_set` (`scripts/core/Game.gd:1335-1378`), `U.parse_rewards`, `scripts/ui/screens/campaign.gd`, `city.gd`, `district_diorama.gd`, `battle_view_3d.gd:43`.

Probes (all under `tests/review/06/`):
- `compare_gdd.py`: parses every cell of the GDD text and diffs it against `data/gdd.json`. 10 locations x 7 stages x 3 difficulties: names, set, slot, XP, credits, and enemy level/rank/rep. **0 mismatches.** The 14 progression rows x 3 difficulties match word for word.
- `Probe.tscn` (headless, `NW_SAVE=06`): builds all 210 encounters and checks the lead enemy's level, plus every enemy's rank and rep, against the GDD (0 mismatches). Also checks energy, sets, unlocks and claims, parses every progression reward, and runs a 20,000-roll Monte Carlo of the drops for each difficulty.
- `Shots06.tscn` and `Shots06b.tscn` (windowed): screenshots in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_06\`.

## GDD items

| # | GDD item | Status | Notes |
|---|---|---|---|
| C1 | City Centre is the hub that every location and menu sprouts from | OK | `city.gd`: Daily login, Missions, Battle pass, Inbox, Events, Black Market, Safehouse, Trinium Stocks, Inventory, Settings, Next Goal GO, BATTLE, plus bottom nav. Every `main.go` target exists in `Main.gd` SCREENS. The GDD flow chart is an image and is not in the extracted text, so the node-by-node flow was not compared. |
| C2 | 10 locations x 7 stages | OK | Slums, Sewers, Shipyard, Industrial, Chemical Plant, Mall, Sky Street, Megablock, Downtown, Corpo Tower (`gdd.json`). |
| C3 | Reward table: XP and credits per stage per difficulty (210 cells x 2) | OK | 0 mismatches. `campaign_rewards` pays `rew[d]` (`Content.gd:96-101`). The stage sheet shows the same values. |
| C4 | Equipment set per location (Health, Armour, Firepower, Speed, Stitcher, Hacking, Firewall, Crit Chance, Crit Damage) | OK | `campaign_set` maps "Crit Chance" and "Crit Damage" to the `Data.SETS` names. Probe confirms all 9. |
| C5 | Location 10 set rotates daily | OK | `Game.corpo_tower_set()` = `Data.SETS.keys()[day_id % 20]`, cycling all 20 sets. Note: the save field `campaign_rot` (`Game.gd:75`) is written but never read (dead field). |
| C6 | Stages 1-6 drop a fixed slot (Weapon, Helmet, Chest, Gloves, Legs, Boots); stage 7 "Random Piece" | OK | `campaign_rewards` uses `stg.slot`, or a random slot when the name is not a gear slot (`Content.gd:116-117`). |
| C7 | Energy 4 / 6 / 8 per battle | OK | `Data.CAMPAIGN_ENERGY`. The probe shows `enc.energy` 4/6/8, and the sheet CTA and squad START show the cost (screenshots 02, 08, 10). |
| C8 | Additional drops, Street Punk: Common WL 15%, Uncommon WL 5%, Equipment 75%, Uncommon Contract 5% | OK | Monte Carlo (n=20,000): equipment 74.6%, contract 4.7%, warlords 20.1% in total. |
| C9 | Additional drops, Mob Boss: Uncommon WL 17.5%, Rare WL 2.5%, Equipment 75%, 2x Uncommon Contract 5% | OK | equipment 75.2%, "2x Uncommon Contract" 5.1%, warlords 20.2% in total. |
| C10 | Additional drops, Warlord: Uncommon WL 15%, Rare WL 5%, Equipment 75%, 3x Uncommon Contract 5% | OK | equipment 74.9%, "3x" 5.0%, warlords 20.3% in total. |
| C11 | Warlord drop rarity "common-rare" | OK | Only common, uncommon and rare are ever granted. |
| C12 | 3 chevrons per stage, from stage requirements | OK (open lever) | Win / no Warlord lost / win within `12 + stage` turns (`Content.gd:86, 397-406`). The GDD doesn't name the requirements. |
| C13 | Progression rewards at 15...210 chevrons per difficulty (14 rows x 3) | OK | Text matches. Every cell parses to a known reward: "2x Rank 3 Firmware" gives n=2 Mk3, "Gear Set: Rank 4 Crit Chance" gives Critical Chance, and so on. A claim needs the star total; a second claim returns `[]`; claims are tracked per difficulty (probe). 210 = 70 stages x 3, so it's reachable. |
| C14 | A new difficulty opens after the previous campaign is cleared; 3 difficulties | OK | `campaign_unlocked`: d>0 needs stage 10-7 of d-1. Probe: Mob Boss opens only after Street Punk 10-7; Warlord stays locked. The tab shows "Clear X first". |
| C15 | XP divided equally among the **5** Warlords used | WRONG (needs user decision) | `Content.finish` divides by `team.size()`, which is correct, but the campaign squad has **4** slots (`squad.gd:7,12`, `team_size := 4`). The GDD (here and in section 10, "5 Warlords as a Defensive Gang") assumes 5. Not listed in `GDD_COVERAGE.md`. RAID's own campaign uses 4 slots, so either add a 5th slot or document it as a deviation. Ask the user; don't change it silently. |
| C16 | Enemy level / rank / rep table (210 rows x 3 difficulties) | OK | `gdd.json` matches the GDD cell for cell. All 630 built encounters field the lead enemy at the exact GDD level, with every unit at the GDD rank and rep. GDD_COVERAGE line 63 says "unchanged". |
| C17 | Den boss stages (x:7): the GDD gives one level per stage | DEVIATION (undocumented) | On x:7 only the boss gets the GDD level. The 3 escorts are built at `max(1, lv - 2)` (`Content.gd:80`), e.g. Corpo 10-7 Mob Boss: boss L60, escorts L58. That's reasonable, but it isn't in `GDD_COVERAGE.md`. |
| C18 | Enemy difficulty should scale "considerably", needing "Campaign Farmers" | OK | Follows the table. The power read-out on the sheet goes Favoured / Fair / Hard / Deadly. |

**Counts:** OK 16 (2 of them open levers), WRONG 1 (C15, squad size 5 vs 4, needs a user decision), DEVIATION 1 undocumented (C17), MISSING 0.

**GDD table oddities** (they are the spec and implemented as written; listed only so the user can confirm they're intended):
- The Sky Street header says "XP / **Silver**" in the Street Punk column. The code treats it as Credits.
- Mob Boss 1:7 is level 30, below 1:1-1:6 (all 50).
- Street Punk 4:7 = 22 < 4:6 = 24. 5:6 = 24 < 5:5 = 29. 7:7 = 25 < 7:6 = 37. Den 8 (20-25) is below den 7 (32-37). Warlord 1:3 = 50 < 1:2 = 60.
- Warlord rank 6 / rep 5 on 1:1-1:2, and rep 6 from 1:3 on.

## Visual and button check

Design canvas artboard: `Campaign.dc.html` (district map left, notched stage sheet right, den progress with reward diamonds bottom-left, den prev/next, difficulty segmented control top-centre, AUTO x10 + BATTLE CTA). City: `Main.dc.html`.

Buttons exercised: difficulty tabs (locked tab shows a toast), stage pins (select a stage), den prev/next (`_den(3)` leads to "Industrial"; next is disabled when the den is locked), REWARDS (modal, CLAIM works, CLAIMED state), BATTLE (opens the squad screen with the right title, "Slums 1:3", and energy 4), squad START (opens the 3D battle). City: every sign and icon button routes to an existing screen, Next Goal GO opens the campaign at the right stage, and BATTLE opens the Fight menu. Every button leads somewhere.

Overall: the City hub and the campaign screen are close to the canvas (top bar, segmented difficulty switch, notched sheet with power bar, enemies, drops, chevron goals, gold BATTLE CTA with energy chip). The 3D diorama is a real upgrade over the canvas's flat map. No emoji or debug text was found. Issues:

| # | Issue | Screenshot | Sev |
|---|---|---|---|
| V1 | Map labels collide with pins and with each other: "CHOP A[pin 3]EY", "RAIL BRI[pin 5]GE", "NOOD[pin 2]ROW", "SCRAPY[pin 4]D", "BLACK CLIN[pin]" running into "DOCTOR MANDRILL". This happens on every den because the pin layout is the same everywhere. | `03_campaign_chem_partial.png`, `04_campaign_industrial_boss_sheet.png`, `02_campaign_slums_fresh.png` | P2 |
| V2 | The REWARDS button slides under the stage sheet when the next-den label is long ("DEN 5 - CHEMICAL PLANT"). The button is half hidden at x 860. | `04_campaign_industrial_boss_sheet.png` | P2 |
| V3 | All 10 dens use the same diorama layout and the same landmark names ("Noodle Row", "Chop Alley", "Scrapyard", "Rail Bridge", "Black Clinic", "Rooftops"), so Corpo Tower has a "Noodle Row". Only the tint and the building seed change. | `02`, `04`, `07`, `09` | P2 |
| V4 | Campaign battles use the same "alley" arena in every location; only the neon accent colours change (`battle_view_3d.gd:44-48`). Slums, Chemical Plant, Sky Street and Corpo Tower are geometrically identical. | `20_battle_d0_1-3.png`, `20_battle_d0_5-7.png`, `20_battle_d0_7-2.png`, `20_battle_d1_10-7.png` | P2 |
| V5 | Den bosses also appear as their own escort: Mall boss Sister Cackle plus a Sister Cackle minion, Megablock Nails + Nails, Downtown Ronin Haze + Ronin Haze, Chem Plant Dr Mandrill + Dr Mandrill, Warlord Corpo Lysa Vohn + Lysa Vohn (probe output). `gang()` draws named warlords from the same syndicate pool that includes the boss. | (probe) `20_battle_d0_5-7.png` | P2 |
| V6 | The "BOSS" tag on the boss enemy tile is drawn under the portrait's stacked-card frame and is partly hidden. | `04_...`, `07_campaign_corpo_boss_d0.png` | P3 |
| V7 | A long syndicate caption ("TERATEK CYBERNETICS - STREET PUNK") widens the stage sheet past its 400 px frame. The right edge sits at 1272 instead of 1260, and the drops grid reflows. | `07_campaign_corpo_boss_d0.png` | P3 |
| V8 | Contract drop tile shows "5%" with tooltip "Contract" only. Mob Boss and Warlord give 2x / 3x but the tile doesn't say so. The equipment tile shows the set name only in a tooltip (the canvas shows set art). | `08_campaign_slums_mobboss.png` | P3 |
| V9 | Chevron goal markers are text glyphs (`▲` / `△`, `campaign.gd:269`). The canvas uses the SVG chevron, and the glyph renders small and thin next to the rest of the stroke-icon UI. | `02_...` | P3 |
| V10 | Den progress bar has no reward diamonds. The canvas puts milestone diamonds on the den chevron bar; the build only has the REWARDS modal. The modal rows have no icons, and the text column jumps with the width of the threshold number ("15" vs "105"). | `32_rewards_modal.png` | P3 |
| V11 | No AUTO x10 / multi-battle button on the stage sheet (the canvas has one). Farming the campaign is the main use of this screen in RAID. | `02_...` | P3 |
| V12 | Fight menu: the Campaign card subtitle "Gear sets & Warlords" touches or clips the card's right edge. All five cards use the same mannequin silhouette art. | `31_fight_menu.png` | P3 |
| V13 | Battle HUD title "Slums 1:3 - Street Punk" is plain small text with no plate, top-left (owned by section 05; noted only). | `20_battle_*.png` | P3 |
| V14 | City: the coach "GUIDE" box sits on top of the Settings sign while the guide is active. Fine once it's skipped. | `01_city.png` vs `30_city_progressed.png` | P3 |

## Prioritised fix list

**P1:** none. All campaign data and rules match the GDD.

**P2**
1. **Squad size, needs a user decision (C15).** Ask the user: 4 slots (RAID campaign) or 5 (GDD text)? If 4, add a row to `GDD_COVERAGE.md` "Deviations": "Campaign/Pit squad = 4 Warlords (GDD says 5) - matches RAID campaign; XP split per Warlord used". If 5: in `scripts/ui/screens/squad.gd:7,12` set `team_size := 5`, widen the slot row, and check `Game.S.squads.last` defaults and the battle formation in `battle_view_3d.gd`.
2. **Bosses duplicated as escorts (V5).** In `Content.gd` `gang()`, add a parameter `exclude: Array = []` and filter `pool_named` with `not exclude.has(id)`. In `build_campaign`, call `gang(syn, 3, max(1, lv - 2), rk, rp, quality, [boss_id])`. The line-up stays seeded, so stages remain deterministic.
3. **Map label collisions (V1).** In `scripts/ui/district_diorama.gd`, in the label placement after line 371, offset each label away from neighbouring pins. For example, put labels for odd stages above the pin (`-pin.size.y - 18`) and even stages below it. Or run a simple pass that nudges a label's y by its height while its rect intersects an earlier label or pin rect. Give labels the same backing plate as the canvas.
4. **REWARDS button under the sheet (V2).** In `campaign.gd` `build()`, shorten the next-den button to `"DEN %d  ›"` (put the den name in `tooltip_text`), or give `nav_row` `offset_right = -440` and `clip_contents = true`. Better: move REWARDS into the den-progress panel (`dp`) like the canvas's milestone diamonds.
5. **Same district per den (V3).** In `scripts/ui/district_map.gd:15`, turn `NAMES` into a per-den table (10 x 6 names that fit each location: Sewers "Outflow Gate", Shipyard "Dry Dock", Corpo Tower "Lobby", "Server Floor", and so on). Index it in `district_diorama.gd:371` as `NAMES[den][i]`. Optionally vary the pin path per den by seeding pin positions with `den` in `setup()`.
6. **Same battle arena everywhere (V4).** In `battle_view_3d.gd` `theme_for()` (line 44), map each campaign location to a prop set: Sewers and Chemical Plant to pipes/tanks, Shipyard to containers, Industrial to `corp`/factory, Mall and Sky Street to storefront, Corpo Tower to `corp`. Use the existing `_props()` kinds ("alley", "arena", "corp", plus the hideout props) before adding new ones.

**P3**
7. `campaign.gd` `_enemy_tile`: put the "Boss" caption on a BG plate at (4,4) and call `move_to_front()` after the portrait is added, or put it in the bottom-right corner opposite "LV" (V6).
8. `campaign.gd` `_sheet`: in the header caption `hv`, set `clip_text = true` or `text_overrun_behavior = OVERRUN_TRIM_ELLIPSIS` (V7).
9. `campaign.gd` drops: give the contract tile the count from `d[1]` ("2x 5%"), and add a caption under the equipment tile with the short set name (V8).
10. `campaign.gd:269`: swap the `▲/△` labels for the stroke chevron icon (`Icon.make("chevron"...)`, or the same SVG path as the canvas) (V9).
11. `campaign.gd` `_rewards()`: give the threshold label a fixed `custom_minimum_size.x = 48`, and add reward icons via `U.reward_label` / `Data` icons. Optionally add milestone diamonds on the den bar (V10).
12. Add a multi-battle / "AUTO x10" button next to BATTLE that repeats `start_encounter` with auto on until energy runs out or 10 runs are done (V11; the canvas shows it).
13. `Content.gd:80`: add a row to `GDD_COVERAGE.md` for den-boss escorts at boss level -2 (C17), or build the escorts at `lv`.
14. `Game.gd:75`: remove the unused `campaign_rot` save field, or use it to pin the Corpo Tower set (C5).
15. `fight.gd` Campaign card: trim the subtitle or reduce its font size, and give each mode card distinct key art (V12).

## Wave 1 applied (owner H)

Files edited: `scripts/ui/screens/campaign.gd`, `scripts/ui/district_map.gd`, `scripts/ui/district_diorama.gd`, `scripts/ui/screens/fight.gd`.

| Item | Change |
|---|---|
| 06:#3 / 16:P3-5 map labels | New `DistrictMap.declutter(labels, pins)` scores 30 candidate offsets per label by overlap area against pins, chevrons and labels already placed, then picks the cleanest. Called every layout pass by both `DistrictMap._layout` and `DistrictDiorama._layout_pins`. Screenshots 03/04/07: no label overlaps a pin any more. |
| 16:P2-3 pins | Map pins raised from 38x34 / 50x44 to 48x44 / 54x48 in both maps. `district_map.gd` now flags big pins with a `"big"` meta instead of testing the width. |
| 06:#5 same district per den | `DistrictMap.DEN_NAMES` (10 dens x 6 landmark names) + `DistrictMap.stage_name(den, i)`, used by both maps (e.g. Corpo Tower: Lobby, Security Gate, Server Floor, R&D Wing, Executive Lift, Boardroom). The pin layout still comes from the 3 `ROUTES`; not changed. |
| 06:#4 REWARDS under sheet | Next-den button is now "DEN n ›" with the den name in the tooltip. The REWARDS button stays clear of the sheet on every den. |
| 06:#7 boss tag | "BOSS" tag on a BG plate at the tile's top-left, moved to the front (screenshots 04/07). |
| 06:#8 sheet widening | Header caption clips with an ellipsis. The new gear line wraps. The sheet keeps its 400 px frame on Corpo Tower. |
| 06:#9 drop tiles | Contract tile shows "2x 5%" / "3x 5%" on Mob Boss and Warlord, with the full name in the tooltip. A new line under the drops shows the set and slot: "Gear: Stitcher set • Gloves" or "Gear: Strike Back (today) • any slot". |
| 06:#10 chevrons | Goal markers are now a drawn triangle (`_chevron_icon`, filled or outlined) instead of the ▲/△ glyphs. Sheet spacing went from 14 to 10 so all three goals fit. |
| 06:#11 rewards modal | Fixed 48 px threshold column, plus a reward icon per row via `UI.reward_node(U.parse_rewards(text)[0], 36)` (screenshot 32). Den-bar milestone diamonds were optional and are skipped. |
| 06:#12 AUTO x10 | "AUTO ×10" button next to BATTLE (enabled once the stage has at least 1 chevron). It opens the squad screen with `enc.repeat = 10`. **The loop itself needs battle.gd (Request 1).** Until then the button runs a single battle. |
| 06:#15 fight card | Campaign subtitle shortened to "Gear & Warlords" (screenshot 31). Distinct key art: Request 2. |

Verification: compile clean (`--import`, no SCRIPT ERROR). `TestRunner` failures: 0. `UiSmoke` reaches "UI SMOKE DONE" with no script errors. Screenshots re-taken and checked (`shots_06/02-10, 30-33`).

### Requests
1. **Owner B (`battle.gd`): AUTO x10.** If `enc.get("repeat", 0) > 1`:
   - Force `Game.S.settings.auto` on for the run.
   - On the result screen after a win, when `Game.pay(Content.enc_cost(e2))` succeeds: wait about 1.5 s, then call `main.replace("battle", {"enc": e2, "team": team, "reinf": ...})` with `e2.repeat = enc.repeat - 1`.
   - Show an "AUTO n/10" tag and a STOP button that sets `repeat` to 0.
   - `Content.rebuild()` drops the key, so copy it across in `_replay`.
2. **Key art (`key_art_card.gd`, unowned):** all five Fight cards use the same mannequin silhouette. Give each mode its own art once Blender renders exist.
3. **Owner C (header / `screen.gd`):** in the new header, the energy pill now overlaps the right edge of the campaign difficulty tabs ("WARLORD" is cut, screenshots 03/04/07). Either shift the pills or let `campaign.gd` place the tabs. If you tell me which, I'll change the tab offsets (`campaign.gd` build, `tb.offset_left/right`).
4. **Coordinator, GDD_COVERAGE.md:** add "Den-boss escorts are built at boss level -2 (Content.build_campaign)" (06 C17), and "Campaign/Pit squad = 4 Warlords (GDD says 5); agreed with the user" (06:#1).

## Wave 2 applied (owner H)

- **Fix wave 2, item 2: difficulty tabs vs HUD pills.** In `campaign.gd` `build()`, the difficulty tabs are now anchored `PRESET_TOP_RIGHT` with `GROW_DIRECTION_BEGIN`, at offsets -840 to -480. They used to be centred, at -170 to 190.
  - They track the right-anchored HUD pills, and share the safe-area insets that `Main._apply_safe_area` applies to both `hud` and `content`.
  - Checked at 1920×1080 and 1440×1080 (4:3): "WARLORD" is fully visible, with about 40 px clear of the energy pill, and no overlap with the den title ("CHEMICAL PLANT").
  - Screenshots: `shots_06/w2_1920x1080/` and `shots_06/w2_1440x1080/`.
- Compile check: my files are clean. TestRunner: 0 failures. UiSmoke: stopped at the battle step because `battle.gd` (owner B, AUTO ×10 work in progress) had parse errors at :1015-1019 (`_last_items`, `_last_pxp`, `_last_wxp`, `_finish_view_only` undeclared). Not mine; re-run once B lands it.
