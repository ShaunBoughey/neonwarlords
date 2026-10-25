# Review 01: Warlord Rank, Warlord Reputation, Warlord Level and Leveling Methods

GDD text: `review/gdd/01_warlord-rank-rep-level.txt`.
Probe + screenshots: `tests/review/01/Probe01.tscn` (windowed, `NW_SAVE=01`). It runs logic checks first (34 asserts), then captures the Level, Rank and Rep pages. Shots are in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_01\`.
I also cross-checked all 360 cells of the GDD XP table against `Data.xp_to_next` offline (Python), with 0 mismatches.

**Totals: 22 OK, 0 MISSING, 0 WRONG, 2 DEVIATION.** All of this section's game rules match the GDD. Every finding below is a UI or presentation issue.

## GDD items

| # | GDD item | Status | Evidence |
|---|---|---|---|
| 1 | Consuming warlords raises the chosen warlord's rank | OK | `Game.rank_up` (`Game.gd:462`); probe: R3 → R4, 3 fodder removed |
| 2 | Number of fodder = current rank (1×R1, 2×R2 … 5×R5) | OK | `Game.gd:465` `fodder.size() + firmware != w.rank`; probe: 2 of 3 rejected |
| 3 | Fodder rank = current rank (not lower, not higher) | OK | `Game.gd:470` `f.rank != w.rank`; probe: an R2 fodder for R3 and an R2 fodder for R1 are both rejected. Locked fodder, Pit-defence fodder and self are also rejected |
| 4 | Chosen warlord must be max level for its rank | OK | `Game.can_rank_up` (`Game.gd:457`); probe: blocked at LV20/30 |
| 5 | Starting rank by rarity (C1, U2, R3, E4, L5) | OK | `Data.RANK_START` (`Data.gd:61`), used in `Game.add_warlord` |
| 6 | Rank 6 is max (N/A) | OK | `Data.MAX_RANK = 6`; `can_rank_up` false at R6 |
| 7 | "Required 1 Ranks to Ascend From" column (2/6/18/90/540) | OK (informational) | Not a rule in code. GDD note: by the table's own rule, R3→R4 is 3×6 + 6 = 24, not 18 (the 90 and 540 also follow from 18). No code change; it only matters if this column is ever shown in game |
| 8 | Firmware Mk N stands in for one rank-N warlord | DEVIATION | Documented in `GDD_COVERAGE.md` ("Design choices"). Probe: R1 → R2 with 1×Mk1 |
| 9 | Reputation max = current rank ("star rating") | OK | `Game.can_rep_up` (`Game.gd:573`); probe: capped at 3 for R3, and reaches 6 once R6 |
| 10 | Rep cost = alignment deeds + generic deeds | OK | `Game.rep_up` takes `deeds/<align>/<tier>` + `deeds/generic/<tier>`. The GDD wording names only Paragon; the code applies the rule to all three alignments, which matches the "respective alignments" sentence and the per-alignment Deed hideouts |
| 11 | Deed tiers Minor / Major / Grand per alignment, from Hideouts | OK | `Content.gd:139-148` (four Deed hideouts: paragon/neutral/renegade/generic) |
| 12 | Rep table: Common/Uncommon/Rare (6 rows × 2) | OK | `Data.REP_LOW` matches all 12 cells; probe: rep 1 costs exactly 2 minor alignment + 3 minor generic, rep 6 costs 3 major |
| 13 | Rep table: Epic (6 × 2) | OK | `Data.REP_EPIC` matches all 12 cells |
| 14 | Rep table: Legendary (6 × 2) | OK | `Data.REP_LEG` matches all 12 cells |
| 15 | XP from all combat, by content and outcome | OK | `Content.finish` (`Content.gd:444`): campaign/hideout/SW/pit/bastion each have their own XP |
| 16 | Losses give 20% XP | OK | `Content.gd:100, 218, 293` `xp * 0.2`; Pit 500 vs 2500; probe: campaign 400 vs 2000 |
| 17 | XP per level: 500 base, +10% cumulative per level | OK | `Data.xp_to_next` = `round(500 × 1.1^(L+R-2))` (`Data.gd:54`) |
| 18 | Same +10% rule for each rank's starting level | OK | Same formula; all 360 GDD cells match (R1 L1 500 … R6 L59 202633) |
| 19 | Max level per rank 10/20/30/40/50/60 | OK | `Data.max_level = rank × 10`; probe for ranks 1-6 |
| 20 | "Total XP" row (6790 / 28137 / 89922 / 267163 / 773916 / 2220905) | OK (informational) | The code's sums are 6790 / 28138 / 89922 / 267164 / 773915 / 2220907, which equal the sums of the GDD's own cells. The GDD total row is off by 1-2 from rounding. Totals are not shown in game |
| 21 | Leveling method 1: battle XP (costs energy and time) | OK | `Content.finish` splits XP across the squad; `enc_cost` charges energy |
| 22 | Leveling method 2: Dojo metabolics give XP | OK | `Game.use_metabolic` (`Game.gd:602`); the City "Dojo" tab opens the Level page (`warlord.gd:94`). Metabolic XP (1500/8000/40000) is an open lever; the GDD gives no values |
| 23 | Metabolic bonus when it matches the warlord | OK | `+50%` when the metabolic's alignment = the warlord's alignment (probe: 1500 vs 2250). The GDD says it should match the warlord's "reputation"; alignment is the only sensible reading. The 50% size is an open lever (`Data.METABOLIC_ALIGN_BONUS`) |
| 24 | Only two leveling methods | DEVIATION | The Level page also lets you feed warlords for XP (`Game.feed_xp`, `400 × (1+rarity)² × level`). It is listed in the `GDD_COVERAGE.md` table row ("metabolics + warlord feeding"), not in the deviations list. Recommend adding one line to the deviations list (P3) |

## Visual issues

Screens: warlord detail, Level, Rank, Rep. Buttons I exercised: page rail (Gear/Level/Rank/Rep), every INSTALL button (by emitting `pressed`), the fodder drawers (feed, rank, switch) and picking/unpicking, the firmware chip state, and the metabolic selection. All of them lead to the right place and work.

- **V1 (P2) Double "INSTALL" text.** The Level, Rank and Rep install button textures already contain the word INSTALL (`assets/ui/LevelScreenG/MetabolicsInstallButton--normal.png`, `RankScreenG/FirmwareInstallButton--normal.png`, `RepScreenG/ReputationInstallButton--normal.png`). The code draws a second "INSTALL" label on top, slightly offset, which gives a ghosted, doubled word. Shots: `10_level_empty.png`, `21_rank_ready_empty.png`, `31_rep_ready.png`. (The same thing happens on the Neuronet page at `warlord.gd:859`; that belongs to section 02.)
- **V2 (P2) The Level page header overlaps the top feed slot.** "+19.6K XP SELECTED" / "MAX LEVEL FOR RANK 3" is drawn at y=168, while slot 2 (`FEED_POS[1]`) starts at y=158, so the text sits on the slot frame and on the portrait. Shots: `15_level_feed_6_picked.png`, `12_level_meta_aligned_x3.png`, `16_level_max_for_rank.png`. The Rank page (slots +30 px) only just clears it.
- **V3 (P2) The Rank page at R6 still looks actionable.** At maximum rank all 6 fodder slots are lit ("RANK 6") and INSTALL is live. Only the header says "MAXIMUM RANK". Shot: `25_rank_max_rank6.png`.
- **V4 (P2) The "CLEAR CHIPS" button covers the Mk 5 firmware count.** Shot: `23_rank_2picks_1firmware.png`. The button is at (1620, 960); the Mk5 count label is at (1572, 977).
- **V5 (P2) In the bottom strip, "LV 12/30" runs under the LOCK button.** The stats line "POWER 288   REP 0/3   LV 12/30" (20 px, x=540) is wider than the 365 px before LOCK at x=905. Shots: every one, e.g. `01_detail_gear.png`, `16_level_max_for_rank.png`.
- **V6 (P2) The warlord name is truncated at 12 characters.** "ABBOT MAYHEM" (12 chars) gets size 52 and is clipped to "ABBOT MAYH…", while longer names such as "SIGRUN THUNDERWIFE" fit at 32. Shots: `01_detail_gear.png` vs `36_rep_epic_rep3_major.png`. (Section 04's report covers the roster cards, not this title.)
- **V7 (P2) Warlords are consumed with no confirmation.** INSTALL on the Rank page permanently removes up to 5 warlords (5×R5 for R5→R6). Level INSTALL can feed an R3+ or Legendary warlord. Neither shows a confirm prompt. RAID confirms before it consumes champions.
- **V8 (P3) Misleading error at max level.** On the Level page at max level with a metabolic selected, INSTALL says "Select Warlords or Metabolics to install". The real reason, "max level for rank", is swallowed (`_install_level` breaks on the error without showing it). Shot: `16_level_max_for_rank.png` shows the state.
- **V9 (P3) No level preview or overflow warning.** The Level page shows "+6,750 XP SELECTED" but not the level that XP reaches, or how much XP is lost past the cap (`add_wxp` zeroes overflow at the cap). RAID shows the resulting level.
- **V10 (P3) The metabolic tier is hidden.** You change the tier by clicking the metabolic slot (no hint), and the slot art is the same for Minor, Major and Grand. Only a small "MINOR/MAJOR" caption changes. The owned counts under the three orbs show the total across all tiers until one is selected. Shots: `10_level_empty.png`, `13_level_meta_offalign_major.png`.
- **V11 (P3) The Rep page doesn't say what the next level gives.** It doesn't mention the stat % per rep or the implant slot unlocks at Rep 2/4/6. Shots: `31_rep_ready.png`, `36_rep_epic_rep3_major.png`.
- **V12 (P3) Drawer card names are clipped at both ends** ("colyte Bishop Bric", "Enforcer Kellen") because `clip_text` is combined with centre alignment. Shots: `14_level_feed_drawer.png`, `22_rank_fodder_drawer.png`. Section 04 reports the same on roster cards.
- **V13 (P3) The "+50%" label is hardcoded.** The label and the gain preview use the literals `"(+50%)"` and `1.5` instead of `Data.METABOLIC_ALIGN_BONUS` (`warlord.gd:605, 629`). If the lever is tuned, the UI will be wrong.
- Note: the bottom strip and drawer use text glyphs ("◀ BACK", "⌂", "◀", "▶", "✕"), not stroke icons. They are not emoji; this is left to the UI-wide review (section 16), as section 04 also noted.
- No placeholder or debug text, and no emoji, on these screens.

## Prioritised fix list

P1: none. All of this section's rules and tables match the GDD.

1. **P2, V1:** `scripts/ui/screens/warlord.gd`. Delete the three overlaid labels: line 596 in `_page_level` (`_lbl("INSTALL", Vector2(1460, 628) …)`), line 709 in `_page_rank` (`_lbl("INSTALL", Vector2(1462, 698) …)`) and line 753 in `_page_rep` (`_lbl("INSTALL", Vector2(1288, 431) …)`). The button art already carries the word.
2. **P2, V7:** `warlord.gd` `_page_rank`. Wrap the INSTALL callback in `main.confirm("Consume %d Warlord(s) to raise %s to Rank %d?" % [st.picks.size(), t.name, w.rank + 1], func(): …existing rank_up body…)`, skipping the prompt when only firmware is used. In `_install_level`, if any pick has `rank >= 3` or rarity `epic`/`legendary`, ask `main.confirm(...)` before `Game.feed_xp`.
3. **P2, V2:** `warlord.gd` `_page_level`, last line. Move the header label from `Vector2(1282, 168)` to `Vector2(1282, 126)`, which sits between the chevrons (end ~y116) and slot 2 (y158).
4. **P2, V3:** `warlord.gd` `_page_rank`. Make the slot test `if i >= need or w.rank >= Data.MAX_RANK:` (dim and disable), and when `w.rank >= Data.MAX_RANK` skip creating the FirmwareInstallButton.
5. **P2, V4:** `warlord.gd` `_page_rank`, the "CLEAR CHIPS" `_ui_btn`. Move it to the free space left of the Mk4 chip: `Vector2(1292, 930)`, width 112, text "CLEAR", font 16.
6. **P2, V5:** `warlord.gd` `_bottom_strip`. Change the stats label to font 17 and the format `"POWER %s · REP %d/%d · LV %d/%d"`, or give it `width 355` with `wrap=false` (ellipsis), so it ends before LOCK at x=905.
7. **P2, V6:** `warlord.gd` `_title_zone`. Size the font to the measured width rather than the character count: start at 52 and step down while `Art.font(true).get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > 490`.
8. **P3, V8:** `warlord.gd` `_install_level`. Keep the `use_metabolic` error (`var e := Game.use_metabolic(...)`), and if `e != ""` and `not did`, show `err(e)` and return.
9. **P3, V9:** `warlord.gd` `_page_level`. Work out the resulting level with a plain loop over `Data.xp_to_next(lv, w.rank)` starting from `w.level`/`w.xp`. Don't call `Game.add_wxp`, which changes the save. Show "→ LV %d" plus "(%s XP over cap)" in the header.
10. **P3, V10:** `warlord.gd` `_page_level`. Add a small "TAP TO CHANGE TIER" caption under the metabolic slot. Tint or scale the slot icon per tier (for example a modulate of 1.0/1.15/1.3 brightness plus a tier pip row).
11. **P3, V11:** `warlord.gd` `_page_rep`. Under "UPGRADE REPUTATION" add one line: `"+%d%% STATS%s" % [Data.SCALING[cls][rarity][6], ", UNLOCKS IMPLANT SLOT" if (w.rep + 1) in [2, 4, 6] else ""]`.
12. **P3, V12:** `warlord.gd` `_warlord_card`. Set `nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS` (keep `clip_text`), so long names keep their start.
13. **P3, V13:** `warlord.gd:605` and `:629`. Use `"(+%d%%)" % int(Data.METABOLIC_ALIGN_BONUS * 100)` and `1.0 + Data.METABOLIC_ALIGN_BONUS`.
14. **P3, item 24:** `GDD_COVERAGE.md` "Design choices". Add: "Level page also accepts warlords as XP fodder (`Game.feed_xp_value` = 400 × (1+rarity)² × level), a third leveling method beyond the GDD's battle + metabolics."

## Probe output (summary)

```
PASS ×33, FAIL ×1 (probe artefact: the starter kit already holds 10 Neutral deeds, so the Epic test warlord could afford rep 1; the code path, tpl.align deeds, is correct by reading)
XP totals per rank: [6790, 28138, 89922, 267164, 773915, 2220907]
rep tables printed = GDD (all 36 rows)
metabolic minor: off-align 1500 XP, on-align 2250 XP
campaign loss xp 400 = 20% of 2000
after rank-up (2 R3 fodder + 1 Mk3): rank 4, level 30/40, Mk3 2 -> 1
```

## Wave 1 applied

Owner A. Files edited: `scripts/ui/screens/warlord.gd`, `scripts/ui/item_view.gd`, `scripts/ui/screens/inventory.gd`. Verified: `--import` compiles with no SCRIPT ERROR, TestRunner `failures: 0`, UiSmoke passes every Armoury page and "armoury interactions ok", and `tests/review/01/Probe01.tscn` re-shot (34 asserts as before; the one FAIL is the known probe artefact). Shots are in `shots_01/`, including new ones 24a, 40-47.

**01 (this report)**
- #1: removed the doubled "INSTALL" labels on the Level, Rank, Rep and Neuronet buttons.
- #2: confirm before consuming warlords: Rank INSTALL (`main.confirm`, skipped when only firmware is used) and Level feed when a pick is R3+ or Epic/Legendary (`_install_level(confirmed)`).
- #3: Level header moved to y132, clear of slot 2.
- #4: at R6 every rank slot is dimmed and the INSTALL button isn't created.
- #5: firmware "CLEAR" button moved to (1292, 930).
- #6: bottom strip stats are now 17px `POWER · REP · LV`, clipped at 355px.
- #7: title font is fitted to the measured width (so "ABBOT MAYHEM" is no longer truncated).
- #8: the metabolic error is shown at max level.
- #9: header shows `-> LV n (x OVER CAP)` via `_preview_level` (no save writes).
- #10: tier pips plus a "TAP SLOT: TIER" hint.
- #11: Rep page shows "NEXT REP: +N% STATS" and the implant unlock.
- #12: drawer names trim with an ellipsis.
- #13: the +50% text and maths read `Data.METABOLIC_ALIGN_BONUS`.

**02**
- F1: pips, tooltip and modal use `sk.max`.
- F2: `Data.ability_max_level` is used on slots, the modal and the learn checks.
- F3:
  - the stimm is applied first
  - a spill confirm appears when duplicate levels would go to other abilities
  - "Ability improved" shows only on success, and the stimm clears after use
  - duplicate picks are capped at ceil(levels_left / 3)
- F4: badge shows "n/m", offset past the baked "LVL"; names don't wrap; the slot 4 badge is clamped.
- F5: locked layers are dimmed with "LOCKED: 2 POINTS IN LAYER N"; partner-taken or full-layer hexes are dimmed.
- F7: "LAYER N" (30px so it fits the row).
- F8: Neuronet modal shows "NOW / NEXT"; the ability modal shows "+5% EFFECT PER LEVEL" or "THIS ABILITY DOES NOT LEVEL".
- F12: RESET uses the stroke diamond (Trinium) icon.
- F13: the selection is a slot-button modulate, replacing the pink rect.
- F14: help text raised to 14px (16px collided with the duplicate slots and the panel edge).
- Extra: removed the doubled "LEARN" label; the button art already says LEARN.

**03 / 04 / 16**
- 03:#2 = 04:#2: neon title uses the short stat name, 16px, no wrap.
- 03:#3 = 16:P2-6: inventory slot tabs get their own full row (all 7 reachable); the count and bulk-sell go on the row below.
- 03:#4: item popup uses the slot art in a rarity border.
- 03:#6: neon bar = grafted / subs, hidden with 0 subs.
- 03:#7: "IF EQUIPPED" is 13px, one line, at y205 inside the modal art (substat rows tightened to 19px).
- 03:#9: implant hint reads "IMPLANTS UNLOCK AT REP 2 / 4 / 6".
- 03:#10: neon markers in the gear modal and item popup are the stroke diamond icon; owner dots are check/users icons.
- 04:#6: `st.item` is cleared when leaving for a non-Upgrade page.
- 04:#7: the class and syndicate symbols open an info modal (desc, role, gang sign).
- Extra: gear-modal PRIMARY line clipped at 248px; it overlapped the SET BONUS column on long primaries.

**Skipped:** none.

**Requests**
- `tests/ui_smoke.gd` (coordinator): line 69 `scr._install_level()` now stops at the new confirm when the fodder is R3+. Call `scr._install_level(true)` so the smoke test still exercises the install.
- Owner C (`Main.gd` toasts): the new top-centre toast position covers the Armoury gear/ability modal (top-left) and the title zone, e.g. `shots_01/43_upgrade_neon.png`. Consider `Vector2(-220, 150)` or showing toasts over the centre column only.
- Owner C (text glyphs): the bottom strip in `warlord.gd` still uses "◀ BACK / ⌂ / ◀ / ▶" and the drawer uses "✕". I left these for the UI-wide pass so all screens change together. If C provides an icon-button helper in `ui.gd`, I'll switch them.
- Coordinator (`GDD_COVERAGE.md`): add the warlord-feeding line from fix #14.
- Seen during the run (not mine): UiSmoke printed `Nonexistent function 'stage_name'` / `'declutter'` once each in the battle part, and the first `--import` showed a transient parse error in `district_map.gd:60` (owner H) that had cleared on the re-run.
