# Audit 01 - Warlord progression (Rank, Reputation, Level, Leveling, Abilities, Class, Syndicate, Statistics)

GDD lines covered: 23-125, 174-184, 277-365 of `review/gdd/00_full_gdd.txt`.
Probe: `tests/audit/01/probe.gd` (`probe.tscn`), run headless with `NW_SAVE=audit01`. All rule checks pass; the one "FAIL" in the first run was a typo in the probe's own expected value (row 49 R5 is 71021, which the code returns).

Probe results:
- XP totals per rank: 6790 / 28138 / 89922 / 267164 / 773915 / 2220907. The GDD gives 6790 / 28137 / 89922 / 267163 / 773916 / 2220905. The difference is at most 2 and comes from the GDD rounding each row as it goes. Every row checked matches (e.g. L9 R1 1072, L59 R6 202633).
- All 36 recruitable templates: alignment is valid. Base HP/ARM/FP are inside the GDD class/rarity range. SPD is 90-110, CC 10, CD 50, FW 30, HACK 0. Ability caps are respected (active <= 3, leader <= 1, reinforce <= 2).
- Rank-up: blocked below max level. Common goes R1 L10 to R2 L10 after 6790 XP plus 1 R1 fodder. Rep 2/2, then "capped at rank".
- Metabolic: renegade minor on a renegade gives 2250 XP; paragon minor on a renegade gives 1500.
- Alignment distribution (recruitable): Paragon 8, Neutral 14, Renegade 14.

## 1. Item table

| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| **Warlord Rank** |||||||
| 1 | Consuming warlords ranks up the chosen warlord | Y | Y | Y | OK | `Game.rank_up` Game.gd:528; Armoury > Rank warlord.gd:729 |
| 2 | Required rank and count = current rank of the chosen warlord | Y | Y | Y | OK | Game.gd:531,537 (`f.rank != w.rank`); drawer lists only same rank warlord.gd:1120; status "CONSUME N x RANK N" warlord.gd:773 |
| 3 | Chosen warlord must be max level for its current rank | Y | Y | Y | OK | `can_rank_up` Game.gd:523; "REACH LV x TO RANK UP" warlord.gd:771 |
| 4 | Starting rank by rarity (Common 1 ... Legendary 5) | Y | Y | Y | OK | `Data.RANK_START` Data.gd:61; `add_warlord` Game.gd:487; stars on card ui.gd:446 |
| 5 | Rank 6 = max | Y | Y | Y | OK | `Data.MAX_RANK` 6; "MAXIMUM RANK" warlord.gd:769 |
| 6 | "Required 1 Ranks to ascend" column (2/6/18/90/540) | - | Y | - | OK | Follows from the rule; informational only |
| 7 | Firmware Mk N stands in for a rank-N warlord | Y | Y | Y | DEVIATION | Documented; the code matches (Game.gd:533, warlord.gd:779-791) |
| 8 | Rank (stars) shown wherever a warlord is shown | Y | - | Partial | PARTIAL | Shown on card, detail chevrons, rank fodder. Battle HUD and hover info show level only (unit_hud.gd, battle.gd:336). Armory roster has no Rank sort (it is folded into "Level") |
| **Warlord Reputation** |||||||
| 9 | Rep max = current star rating | Y | Y | Y | OK | Game.gd:639; "REP x/rank" warlord.gd:802; "RANK UP TO RAISE REPUTATION FURTHER" :827 |
| 10 | Rep raised with alignment deeds + generic deeds | Y | Y | Y | OK | `can_rep_up` / `rep_up` Game.gd:638-666 |
| 11 | Paragon warlord needs Paragon + Generic deeds (and the same pattern for Neutral / Renegade) | Y | Y | Partial | PARTIAL | Rules are right. The Rep page shows a header for the warlord's alignment and a GENERIC header, plus two requirement bars (warlord.gd:810-844). Nowhere does it say "this warlord is PARAGON, so it needs Paragon + Generic". There is no preview of later rep levels and no hint of which hideout drops the deeds |
| 12 | Deeds come in Minor / Major / Grand per alignment (+ Generic) | Y | Y | Y | OK | `_align_tiers` Game.gd:173; Rep page tiers warlord.gd:816 |
| 13 | Deeds come from their respective hideouts | Y | Y | Y | OK | Content.gd:185-191 (deeds_paragon/neutral/renegade/generic) |
| 14 | Deed table Common/Uncommon/Rare (6 rows) | Y | Y | Y | OK | `REP_LOW` Data.gd:63 equals the GDD |
| 15 | Deed table Epic (6 rows) | Y | Y | Y | OK | `REP_EPIC` Data.gd:64 equals the GDD |
| 16 | Deed table Legendary (6 rows) | Y | Y | Y | OK | `REP_LEG` Data.gd:65 equals the GDD |
| 17 | Rep scaling 1-3% per increase | Y | Y | Y | OK | compute_stats Game.gd:739; "NEXT REP: +x% STATS" warlord.gd:829 |
| 18 | Rep level visible on cards / roster | Y | - | N | MISSING (UI) | `UI.warlord_card` shows LV and stars only (ui.gd:443-449). The Armory roster cannot sort by Rep (armory.gd:44). Only the Armoury drawer sorts by Rep |
| **Warlord Level** |||||||
| 19 | XP from all combat, amount depends on content and outcome | Y | Y | Y | OK | Content.gd:145/283/361/540/547 |
| 20 | Losses give only 20% XP | Y | Y | Y | OK | `int(xp*0.2)` Content.gd:146,284,362; Pit 500 = 20% of 2500 :540; Bastion always counts as a win |
| 21 | +10% per level, and the same for the starting level of each rank | Y | Y | - | OK | `Data.xp_to_next` Data.gd:55 = 500 x 1.1^(L+R-2) |
| 22 | XP table, 60 rows x 6 ranks + totals | Y | Y | Y | OK | Probe: every row matches; totals within GDD rounding (+/-2). XP bar on detail warlord.gd:301 |
| 23 | Max level 10 per rank | Y | Y | Y | OK | `Data.max_level` = rank x 10 |
| 24 | XP split across the squad | Y | Y | Y | OK | Content.gd:549-556; result screen "xp_each" |
| 25 | Level shown everywhere | Y | - | Y | OK | Card "LV n", detail ring, battle HUD level, result cards |
| **Leveling methods** |||||||
| 26 | Method 1: battle XP (costs energy and time) | Y | Y | Y | OK | as #19 |
| 27 | Method 2: Dojo + Metabolics of varying levels | Y | Y | Partial | PARTIAL | Built as Armoury > Level (warlord.gd:596). The word "Dojo" never appears to the player (only as an internal tab alias, warlord.gd:94). Tiers 1500/8000/40000 XP (Data.gd:254) are an open lever. Metabolics drop only from the hourly Plaza roll and the starter kit. The Plaza pool has no Renegade Minor, Paragon Grand or Neutral Grand (Data.gd:397-402) |
| 28 | Higher XP when the metabolic matches the warlord's alignment ("reputation") | Y | Y | Partial | PARTIAL | +50% (open lever) Game.gd:675. "(+50%)" appears only after the matching metabolic is picked (warlord.gd:619). The three metabolic buttons do not mark which one matches (warlord.gd:660-671) |
| 29 | Generic metabolics | Y | n/a | N | WRONG | 3 Generic Minor metabolics come in every starter kit (Game.gd:113) and the test kit (Game.gd:153-155). The Level page offers only paragon/renegade/neutral (warlord.gd:660), so they can never be used. GDD metabolics align with the warlord, so Generic metabolics should not exist |
| 30 | "Two methods" only | Y | Y | Y | WRONG (undocumented deviation) | A third method, feeding warlords for XP (`Game.feed_xp` Game.gd:554-573, 6 feed slots on the Level page), is not in the GDD and not in the GDD_COVERAGE deviations table (listed as "Verified" in the coverage table) |
| **Warlord Abilities** |||||||
| 31 | Duplicate = +3 ability levels | Y | Y | Y | OK | `feed_duplicate` Game.gd:591; "DUPLICATE: +3 LEVELS" warlord.gd:1013 |
| 32 | Stimm = +1 level, equal-or-higher rarity | Y | Y | Partial | PARTIAL | `use_stimm` Game.gd:617. The UI offers only Rare/Epic/Legendary stimms (warlord.gd:1015), but `items.stimm.uncommon` exists (Game.gd:49) and is valid for Common/Uncommon warlords. No reward source grants it today |
| 33 | Ability count varies per warlord | Y | Y | Y | OK | 2 to 6 per template (Warlords.gd) |
| 34 | Mixture of active / gang (leader) / passive | Y | Y | Y | OK | Type label ATK/PASV/LEAD/REIN warlord.gd:969 |
| 35 | Each ability has its own damage multiplier | Y | Y | N | MISSING (UI) | `mult` on every active (Warlords.gd). The ability modal shows desc, level and cooldown but no multiplier (warlord.gd:984-994) |
| 36 | Damage scales off the multiplier and the class stat | Y | Y | Partial | DEVIATION | `Data.CLASS_SCALING` (documented). The UI never says "damage based on Armour/FP/HP/Hacking" except the class info modal |
| 37 | Active max 3 | Y | Y | Y | OK | probe |
| 38 | Passive always on | Y | Y | Y | OK | Battle hooks, compute_stats passives Game.gd:778 |
| 39 | Leader max 1, only when leading, passive bonus | Y | Y | Y | OK | Battle.gd:145-166 (team[0]); squad "LEADER" slot + leader skill text squad.gd:52,84-90 |
| 40 | Reinforce max 2, fires on a Pit Royal reinforcement or at the start of a combat round | Y | Y | Y | OK | Battle.gd:195 (rounds after the first), 743-757 (Royal) |
| 41 | Ability max levels | Y | Y | Y | DEVIATION | Documented ("Ability levels"); the code matches Data.gd:256-281 |
| 42 | Table of all warlords and abilities | - | - | - | OK (n/a) | GDD placeholder link |
| **Warlord Class** |||||||
| 43 | 4 classes with roles | Y | Y | Partial | PARTIAL | `Data.CLASS_INFO`. Shown as a portrait icon (portrait.gd:74), detail icon + info modal (warlord.gd:284-286) and card tooltip. The Armory roster has no class filter (armory.gd only has rarity + syndicate). Battle hover has no class |
| 44 | Base stats control balance; higher base armour gets more from gear | Y | Y | - | OK | % gear multiplies base (Game.gd:807-809) |
| 45 | Armour/ARM, Firepower/FP, Modder/HP, Hacker/Hacking damage scaling | Y | Y | Y | DEVIATION | `CLASS_SCALING` documented (hacker 0.72 FP + 1.2 HACK, base hack 0 is a user decision) |
| **Warlord Syndicate** |||||||
| 46 | Every warlord has a syndicate tag | Y | Y | Y | OK | All templates incl. enemies (Warlords.gd) |
| 47 | 7 syndicates: names + descriptions | Y | - | Y | OK | Data.gd:23-31; Vikings desc leaves out "Vikings and muscles theme" (P3) |
| 48 | Gang sign per syndicate | Y | - | Y | OK | `sign` text + `Art.SYN_SYMBOL`; portrait corner (portrait.gd:77), detail icon + "Gang sign:" modal (warlord.gd:283-322) |
| 49 | Syndicate-calling abilities; no extra attacks if no matching allies | Y | Y | Partial | PARTIAL | Battle.gd:1040 (`syn` filter); Herd Call, Call the Crew. The squad picker has no syndicate filter or match count to help build for leader / call skills (squad.gd:122) |
| 50 | Filter by syndicate | Y | - | Partial | OK | Armory rail (armory.gd:11-17), Armoury drawer (warlord.gd:233); squad picker has none (see #49) |
| **Warlord Statistics** |||||||
| 51 | HP / Armour / Firepower scale | Y | Y | Y | OK | compute_stats Game.gd:740-745 |
| 52 | Speed 90-110 | Y | Y | Y | OK | Warlords.gd:45 (probe) |
| 53 | Crit Chance base 10%, cap 100% | Y | Y | Y | OK | Data.BASE_CC; min(cc,100) |
| 54 | Crit Damage base 50% | Y | Y | Y | OK | Data.BASE_CD |
| 55 | Hacking 0 | Y | Y | Y | OK | user decision |
| 56 | Firewall base 30 | Y | Y | Y | OK | Data.BASE_FW |
| 57 | Base stat starting ranges (20 rows) | Y | Y | Y | OK | `BASE_RANGES` Data.gd:75-80 equals the GDD; probe: all 36 in range |
| 58 | Level / rank / rep scaling table (20 rows) | Y | Y | Y | OK | `SCALING` Data.gd:82-87 equals the GDD. Level total spread over L1-60, rank total over R1-6, so a Legendary starts with 4/5 of its rank bonus. Stat breakdown modal warlord.gd:1256 |
| **Alignment (Paragon / Neutral / Renegade)** |||||||
| 59 | Every warlord has an alignment | Y | Y | - | OK | `_w(..., align, ...)` Warlords.gd:82; probe 36/36 valid |
| 60 | Distribution sensible | Y | - | - | PARTIAL | P 8 / N 14 / R 14. Paragon is 1 each at Common/Uncommon/Rare/Legendary and 4 at Epic. Shogunate 4/5 Paragon; Vultures and Traders 0 Paragon. Content lever, ask the user |
| 61 | Alignment on warlord cards (roster, squad, recruit, fodder) | Y | - | N | MISSING (UI) | `UI.warlord_card` ui.gd:414-463 (no glyph/colour); Armoury drawer card warlord.gd:1137-1166 |
| 62 | Alignment in card tooltips | Y | - | N | MISSING (UI) | ui.gd:462, warlord.gd:1165 (rarity/class/syndicate only) |
| 63 | Filter/sort by alignment in the roster | Y | - | N | MISSING (UI) | armory.gd (rarity + syndicate only); Armoury drawer filters warlord.gd:212 (no Alignment) |
| 64 | Alignment on warlord detail | Y | - | Partial | PARTIAL | Bottom strip text "RARITY • ALIGNMENT" drawn in the *rarity* colour, no icon, no info modal (warlord.gd:299) |
| 65 | Alignment in squad picker | Y | - | N | MISSING (UI) | squad.gd uses warlord_card only |
| 66 | Alignment in recruit reveal | Y | - | N | MISSING (UI) | recruit.gd:214-237 shows card + rarity + name only |
| 67 | Alignment in battle HUD | Y | - | N | MISSING (UI) | Low value in combat (P3) |
| 68 | Consistent alignment icon/colour | Y | - | Partial | PARTIAL | `Data.ALIGN_COLOR` exists and is used on the Rep / Level / Safehouse pages. `UI.align_tag` / `syn_tag` / `class_tag` (ui.gd:537-546) are never called |
| **Three-layer check for the other attributes** |||||||
| 69 | Rarity | Y | Y | Y | OK | Border colour everywhere, roster filter + sort, recruit headline; battle hover none (P3) |
| 70 | Class | Y | Y | Partial | PARTIAL | see #43 |
| 71 | Syndicate | Y | Y | Y | OK | see #48-50 |
| 72 | Rank | Y | Y | Partial | PARTIAL | see #8 |
| 73 | Reputation | Y | Y | Partial | PARTIAL | see #18 |
| 74 | Level | Y | Y | Y | OK | see #25 |

Counts: OK 47, PARTIAL 13, MISSING 8, WRONG 2, DEVIATION 4 (74 rows).

## 2. Fix list

### P1
None. Every progression rule (rank, rep, XP table, loss XP, metabolic bonus, stats, ability caps) matches the GDD.

### P2
1. **Show alignment on every warlord card and tooltip.** In `scripts/ui/ui.gd` `warlord_card`, add a small alignment pip/glyph in `Data.ALIGN_COLOR[t.align]` (for example a "◈" label top-right above the stars, or a coloured left edge on the name strip). Add `U.cap(t.align)` to `tooltip_text`. Do the same in `warlord.gd` `_warlord_card` (the drawer card) and its `_hit` tooltip. This carries alignment into the roster, squad picker, recruit reveal, rank / level fodder and result screens at once.
2. **Alignment (and class) filter in the roster.** In `scripts/ui/screens/armory.gd` `build`, add a Paragon / Neutral / Renegade toggle row (ALIGN_COLOR) and a class row next to the rarity buttons, and filter `list` by `t.align` / `t.cls`. In `warlord.gd` `_left_bar` / `_filter` / `_warlord_list`, add an "Alignment" cycle filter (reuse the "Rarity" slot art or add a text button) and filter on `tx.align`.
3. **Show reputation on cards and allow sorting by it.** In `ui.gd` `warlord_card`, show rep, for example "R{rank} • REP {rep}" or rep-filled stars (filled = rep, gold outline = rank). Add "Rank" and "Rep" to the Armory sort tabs (`armory.gd:44`).
4. **Explain alignment and its deed costs.** In `warlord.gd` `_bottom_strip`, colour the alignment with `Data.ALIGN_COLOR` and add an `_hit` that opens `_info_modal`. The modal says: "<Alignment>: Reputation needs <Alignment> + Generic Deeds (from the <Alignment> / Generic Deeds hideouts); <Alignment> Metabolics give +50% XP; Safehouse <Alignment> nodes boost this warlord". In `_page_rep`, add a line under the portrait: "<NAME> IS <ALIGN>: NEEDS <ALIGN> + GENERIC DEEDS". Add a compact six-row cost preview built from `Data.rep_table(t.rarity)`, with the current row highlighted.
5. **Recruit reveal shows the warlord's identity.** In `recruit.gd` (after the name label, around line 237), add a row with `UI.class_tag(t.cls)`, `UI.syn_tag(t.syn)` and `UI.align_tag(t.align)`. These helpers already exist and are unused.
6. **Mark the matching metabolic.** In `warlord.gd` `_page_level`, on the 3 metabolic buttons (line 660 loop), highlight the one where `al == t.align` (glow or a "+50%" label) and add "matches <alignment>: +50% XP" to its tooltip.

### P3
7. **Generic metabolics cannot be used.** In `Game.gd` `grant_starter_kit` (line 111) and `grant_test_kit` (line 149), grant metabolics only for paragon/neutral/renegade (keep generic for deeds). Keep `_align_tiers` for old saves; optionally convert any owned generic metabolics to neutral in `load_game`.
8. **Uncommon Stimm slot.** In `warlord.gd` `_page_abilities` line 1015, include "uncommon" in `rs` (needs a stimm art fallback), or remove `stimm.uncommon` from the save if it will never drop.
9. **Ability modal shows multiplier and scaling stat.** In `_page_abilities` (around line 990), add "x{mult} {CLASS stat}" (from `Data.CLASS_SCALING[t.cls]`) for actives with `mult > 0`.
10. **Battle hover info.** In `battle.gd` `_hover` line 336, add rank stars, class name and syndicate (alignment optional).
11. **Squad picker syndicate help.** In `squad.gd`, add a syndicate filter next to the class tabs. Under LEADER SKILL, show "affects N/4" when the aura has `syn`.
12. **"Dojo" naming.** In the `_page_level` header, label the metabolics area "DOJO" so the GDD term reaches the player.
13. **Warlord feeding for XP** (`Game.feed_xp`): the GDD names only two methods. Ask the user whether to keep it. If kept, add it to the GDD_COVERAGE deviations table.
14. **Alignment distribution** (P 8 / N 14 / R 14; no Paragon in Vultures or Traders): content lever, ask the user before retagging.
15. **Metabolic sources.** `Data.PLAZA_POOL` has no Renegade Minor, Paragon Grand or Neutral Grand. Add the missing combos so all alignments can reach every tier (the costs are an open lever).
16. **Vikings description.** In `Data.SYNDICATES.vikings.desc`, append "Vikings and muscles theme." to match the GDD.


**Applied (owner C):** P3 15 - `Data.PLAZA_POOL` gains Renegade Minor (3x, 15k), Paragon Grand and Neutral Grand (1x, 120k), matching the existing row costs.

## Applied (fix owner B)
- P3 9: ability modal shows "DAMAGE: xM MULTIPLIER • SCALES WITH <stat> (<class> CLASS)" for actives with mult > 0 (from `Data.CLASS_SCALING`).
- P3 8 skipped: the GDD names no Uncommon Stimm source and there is no Uncommon Stimm art; Uncommon warlords already accept Rare+ Stimms. Removing `stimm.uncommon` from the save is owner C's call (Game.gd); Inventory > Items still lists the count.

**Applied (owner C, alignment retag 12/12/12):** Madame Marrow R->P, Enforcer Kellen N->P, Oni Matsuda P->R, Mama Hogg N->P, Navigator Pix N->P, Bosun Krug R->N, Ragnar Volt R->P. Every syndicate has all three. Alignment lives on the template, so old saves pick it up.
