# Review 04: Warlord Class, Warlord Syndicate and Warlord Statistics

GDD text: `review/gdd/04_class-syndicate-stats.txt`.
Probe: `tests/review/04/Probe.tscn` (headless). It checks all 78 templates (recruitable and enemy-only) against `Data.BASE_RANGES`, speed 90-110, crit chance/crit damage/firewall/hacking bases, and the level/rank/rep scaling at L60 R6 Rep 6 against `Data.SCALING`.
Screenshots: `tests/review/04/Shots.tscn` (windowed, NW_SAVE=04) → `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_04\`.

**Totals: 21 OK, 0 MISSING, 2 WRONG, 1 DEVIATION.**

## GDD items

| # | GDD item | Status | Evidence |
|---|---|---|---|
| 1 | Four classes: Armour/Tank, Firepower/DPS, Modder/Buffer, Hacker/Debuffer | OK | `Data.gd:14-20` `CLASSES`, `CLASS_INFO` |
| 2 | Armour: damage scales with Armour | OK | `Data.CLASS_SCALING.armour = {arm: 0.78}` (`Data.gd:316`), used by `Battle._scaling` (`Battle.gd:258`) |
| 3 | Firepower: damage scales with Firepower | OK | `CLASS_SCALING.firepower = {fp: 1.08}` |
| 4 | Modder: damage scales with Health | OK | `CLASS_SCALING.modder = {hp: 0.037}` (uses `max_hp`) |
| 5 | Hacker: damage scales with Hacking | DEVIATION | `CLASS_SCALING.hacker = {fp: 0.72, hack: 1.2}`. This is documented in `GDD_COVERAGE.md:60` (CLASS_SCALING is a tuning lever) |
| 6 | Higher base stats get more from equipment (1000 vs 900 armour) | OK | `Game.compute_stats` applies gear/set `%` to the scaled base (`Game.gd:744-746`) |
| 7 | Every warlord has a Syndicate tag | OK | All 78 templates have a valid `syn` (probe) |
| 8 | Syndicate "call" abilities call only same-syndicate allies; no ally means no extra attack | OK | `Battle.gd:1009-1019` filters `x.syn == u.syn` when `syn: true`; the slice is empty when there are none (Herd Call, Call the Crew) |
| 9 | 7 syndicates: names and gang signs | OK | `Data.SYNDICATES` (`Data.gd:23-31`), sign art `Art.SYN_SYMBOL` |
| 10 | Syndicate descriptions | WRONG (minor) | `Data.gd:25-26`: Vultures leaves out "Dark and gruesome themes." Teratek is reworded ("Suits and cyborgs" instead of "Suits and cyborgs theme"). Low impact, but the text should match the GDD |
| 11 | Health: max HP pool; raises Modder damage; scales | OK | `compute_stats` hp × level/rank/rep |
| 12 | Armour: reduces damage %; raises Armour damage; scales | OK | `Battle.gd:585` `mit = arm/(arm+ARMOUR_K)` capped |
| 13 | Firepower: raises Firepower damage; scales | OK | |
| 14 | Speed 90-110, drives the turn meter | OK | All 78 bases are 90-110 (`Warlords._base_stats`, probe); TM fills by `eff(spd)` (`Battle.gd:290`) |
| 15 | Crit chance: base 10%, capped at 100% | OK | `Data.BASE_CC`; `compute_stats` `min(100, ...)`; `Battle.eff` clamps to 0-100 |
| 16 | Crit damage: base 50% | OK | `Data.BASE_CD`; crit multiplier `1 + cd/100` (`Battle.gd:563`) |
| 17 | Hacking: base **0**, raises the chance to land debuffs | WRONG | `Warlords.gd:49-50` gives every Hacker a base Hacking of 20-40 (`Data.HACKER_BASE_HACK`, `Data.gd:91`), and `Game.gd:679-680` scales Hacking +60% by level and +40% by rank. The GDD says Hacking starts at 0, and its "Scales?" column lists only HP/ARM/FP. This is not in `GDD_COVERAGE.md`. The land-chance rule itself is OK (`Battle._hack_check`, `Battle.gd:834`) |
| 18 | Firewall: base 30, resists debuffs | OK | `Data.BASE_FW`; `_hack_check` |
| 19 | Base stat ranges: Armour × 5 rarities (HP/ARM/FP) | OK | `Data.BASE_RANGES.armour` matches all 15 cells |
| 20 | Base stat ranges: Firepower × 5 | OK | matches all 15 cells |
| 21 | Base stat ranges: Modder × 5 | OK | matches all 15 cells |
| 22 | Base stat ranges: Hacker × 5 | OK | matches all 15 cells |
| 23 | Every warlord's base HP/ARM/FP falls inside its class/rarity range | OK | 78/78 templates (probe output below) |
| 24 | Level scaling totals (70-80%) per class/rarity | OK | `Data.SCALING[0..2]` matches all 60 cells; spread over levels 1→60 (`Game.gd:671`) |
| 25 | Rank scaling totals (45-55%) per class/rarity | OK | `Data.SCALING[3..5]` matches all 60 cells; spread over ranks 1→6 (`Game.gd:672`) |
| 26 | Reputation 1-3% per increase | OK | `Data.SCALING[6]`; `rep_f = 1 + rep × %` (`Game.gd:673`) |

The probe confirmed L1R1Rep0 → L60R6Rep6 growth ratios for every template to within 1%. The only gap is Abbot Mayhem's armour, 3.111 against 3.125, which comes from rounding his +15% Armour passive at a low base. It is not a bug.

Probe base values (recruitable): e.g. Deacon Chainz (legendary armour) hp 1135 / arm 72 / fp 68 / spd 107; Raiden X (legendary firepower) 843 / 63 / 76 / 92; Issac Vaun (legendary hacker) 1298 / 63 / 70 / 105, hack 27. The full list is printed by `tests/review/04/Probe.tscn`.

## Visual review

The design canvas has no artboard for the roster or the warlord stats panel, so I checked these screens against its DesignSystem board: colours, notched frames, rarity colours, cyan/gold buttons and the category rail.

- **Roster** (`shots_04/01_roster_all.png`, `02_roster_teratek.png`, `03_roster_legendary.png`, `04_roster_empty.png`): matches the Catalogue pattern (left rail, rarity chips, sort segmented control, gold RECRUIT CTA). Every filter, sort, rail row, card, INVENTORY and RECRUIT button was exercised and works, and the empty state reads correctly.
  - V1 (P3): the rail label "Teratek Cybernetic**s**" is clipped against its count (`01_roster_all.png`).
  - V2 (P3): card names are truncated with an ellipsis: "Deacon Ch…", "Shogun Raid…", "Oni Matsud…", "Abbot May…", "Pontiff Ruck…", "Navigator …". "Sigrun Thunde…" is truncated even after the step-down font.
- **Warlord stats panel** (`10_warlord_gear_stats.png`, `11_warlord_implants_stats.png`, `12_warlord_upgrade_stats.png`, `14_warlord_hacker_noGear.png`, `16_warlord_raiden.png`): all 8 stats are shown with their gear increase, and crit chance and crit damage show %. Syndicate and class symbols and the level ring render. The expand button opens the Stat Breakdown (`13_stat_breakdown.png`, `15_hacker_breakdown.png`), and its numbers agree with the panel. The left filter bar and the right page bar are wired (`warlord.gd:201-230`, `257-270`).
  - V3 (P2): on the Upgrade page, the neon box's title "R2 ARMOUR % NEON" wraps to two lines and overprints "CURRENT ARM% ON GEAR: 3", making it unreadable (`12_warlord_upgrade_stats.png`).
  - V4 (P3): the selected-item card (top left) stays open after leaving Upgrade for Gear, and it shows up behind the Stat Breakdown modal (`13_stat_breakdown.png`).
  - V5 (P3): the class and syndicate symbols in the title zone are tooltip-only hit areas (`func(): pass`, `warlord.gd:280-281`). Clicking them does nothing. Acceptable, but a click could open a small info pop-up with the class role/description (`Data.CLASS_INFO.desc`) or the syndicate description and gang sign, which is the only place this section's text could appear in game.
  - Note: the bottom strip uses text glyphs "◀ BACK", "⌂", "◀", "▶" (`warlord.gd:290-293`), not stroke icons. These are not emoji, so this is left to the UI-wide review (section 16).

No placeholder or debug text was found on these screens.

## Prioritised fixes

**P1:** none.

**P2**
1. **Hacker base Hacking (item 17).** `Warlords._base_stats` (`Warlords.gd:49-50`) and `Game.compute_stats` (`Game.gd:679-680`). The GDD sets Hacking to 0 at base and does not list it as scaling, yet Hacker damage is meant to scale with Hacking. Applying the GDD literally would leave the Hacking term at 0 at the start. Either way, record it in `GDD_COVERAGE.md` → "Balance tuning". The open levers are `Data.HACKER_BASE_HACK` and the 60%/40% hack level/rank growth. Ask the user which to keep:
   - (a) Keep as is and add a DEVIATION row: "Hacker base Hacking 20-40, +60% by level, +40% by rank: needed because Hacker damage scales with Hacking (GDD gives Hacking base 0)."
   - (b) Follow the GDD literally: set `HACKER_BASE_HACK := [0, 0]`, remove the `if t.cls == "hacker": base.hack *= ...` block, and retune Hacker damage via `CLASS_SCALING.hacker`. Then re-run `tests/ClassProbe.tscn`.
2. **Neon label overlap (V3).** `warlord.gd` `_page_upgrade`, line 525. Change `_lbl("R%d %s NEON" ...` to use `Data.STATS[ne.stat].short` (gives "R2 ARM% NEON") and font 16, so the label fits on one line at width 220. Alternatively, keep the label and move the CURRENT/VALUE labels down by about 22 px (lines 530-531).

**P3**
3. **Syndicate descriptions (item 10).** `Data.gd:25-26`. Set Vultures `desc` to "Lower slum syndicate who preys on the augmented to steal the augments by force. Dark and gruesome themes." Set Teratek to "A corporation focused on the manufacturing and selling of augments. Suits and cyborgs theme."
4. **Roster rail clip (V1).** `armory.gd` `build()`, the `rail(..., 240)` call. Widen it to 260 (and shift `offset_right`/`body.offset_left` by 20), or show a shorter rail name (e.g. "Teratek") with the full name in the tooltip.
5. **Card name truncation (V2).** `ui.gd` `warlord_card` (around line 427). Allow a two-line name, or step the font size down one more level for names longer than 12 characters.
6. **Item card lingering (V4).** `warlord.gd` `_go_page`. Add `st.item = ""` when moving to a page other than `upgrade`.
7. **Class/syndicate info (V5).** `warlord.gd` `_title_zone`, lines 280-281. Replace `func(): pass` with a `main.modal(...)` that shows `CLASS_INFO[cls].role` and `.desc`, or `SYNDICATES[syn].desc` and `.sign`.
