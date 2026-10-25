# Review 08: Resource hideouts and Deeds (Synapse Centre, Heist, Chopshop, Paragon / Neutral / Renegade / Generic Deeds)

**Totals:** 25 OK, 1 MISSING, 2 WRONG, 2 DEVIATION (plus 3 typos in the GDD itself, listed below).

**How this was checked**
- `tests/review/08/compare_tables.py` parses all four GDD tables from `review/gdd/08_resource-hideouts-deeds.txt` (20 stages each) and compares every cell with `data/gdd.json`.
- `tests/review/08/Probe08.tscn` (headless, NW_SAVE=08) does three things:
  - runs every Heist and Deeds reward string through `U.parse_rewards`
  - prints the entry cost of every hideout at 8 stages
  - checks the Heist Plan cap and daily reset, then runs `Content.hideout_rewards` 2,000 to 4,000 times per stage and compares the drop odds and ranges with the GDD.
- `tests/review/08/Shots08.tscn` (windowed) saves 29 screenshots to `user://shots_08/` (`C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_08\`).
- The compile check passed: no `SCRIPT ERROR`.

## GDD items

| # | GDD item | Status | Evidence |
|---|---|---|---|
| 1 | Synapse Centre is the only source of Memory Fragments, farmable with energy | OK | `Content.hideout_rewards` "mf" branch. Fragments come only from here and from fixed rewards (starter pack, shop). |
| 2 | Synapse: each win gives a random set of fragments, varying in tier and quantity | OK | Probe: T1/T2/T3 rolled independently in the GDD ranges (s1 T1 15-35, T2/T3 0; s20 55-75 / 25-45 / 15-35). |
| 3 | Synapse table: 20 stages x 3 tiers, amounts | OK | compare_tables: all 60 cells match (`08-28` at s12 is read as 8-28). |
| 4 | Synapse energy (8 for s1-5, 10 for s6-10, 12 for s11-15, 14 for s16-20) | OK | Probe COST line. |
| 5 | Synapse boss "Bring It On" (immune to STUN, SHOCK, STUPEFY, TM manipulation, Cooldown Increase, ENRAGE) | OK | `Warlords.gd:362` MNEMOSYNE uses `IMMUNE_BOSS_TM`. |
| 6 | Synapse boss, minion abilities and strategies (blank in the GDD) | DEVIATION | Designed to fit (GDD_COVERAGE "Bosses ... were blank"). MNEMOSYNE plus 2 Synapse Drones, with tips. |
| 7 | Heist is a Credits hideout; rare Contracts and occasional huge payouts | OK | "credits" branch: one weighted pick per win. |
| 8 | Heist costs 1 Heist Plan at every stage | OK | `Content.hideout_cost` returns `{"heist": 1}` for all 20 stages. |
| 9 | Heist Plans: 5 a day | OK | `Game.tick` daily reset sets `c.heist = Data.HEIST_DAILY` (5). Probe: 1 rises to 5 after the day changes. |
| 10 | Heist Plans capped at 5; unused ones are lost | OK | `Game.CUR_CAP` / `add_cur`. Probe: 5+3 gives 5, a grant of 10 gives 5. The reset overwrites to 5, so unused plans do not carry over. |
| 11 | No Heist Plan, no entry | OK | Probe: after 5 entries `can_pay` returns "Not enough: 1 Heist Plan". On screen the squad START button shows the red toast (shot 16). |
| 12 | Heist table: 20 stages x 7 rewards, amounts and % chances | OK | compare_tables: all 140 rows match; each stage sums to 100%. |
| 13 | Heist odds in play | OK | Probe s1 (4,000 runs): 50K 30.2 / 75K 40.6 / 100K 23.9 / 500K 2.1 / 1M 0.5 / UC 2.4 / R 0.3 (GDD 30/40/25/2/0.5/2/0.5). s20: 2xR, 5xUC and 5M all parse and drop. |
| 14 | Heist boss and minions (blank in the GDD) | DEVIATION | WARDEN-9 Vault Mech plus 2 Netrunners, designed to fit. |
| 15 | Chopshop is the main Implant source | OK | "implant" branch; every win gives exactly 1 implant. |
| 16 | Chopshop table: credits, energy, rank %, rarity %, slot % (Limbs 35 / Organs 35 / Skeleton 30), 20 stages | OK | compare_tables: every value matches. |
| 17 | Chopshop odds in play | OK | Probe s1: R1 14 / R2 49 / R3 36; Uncommon 61 / Rare 39; Limbs 36 / Organs 33 / Skeleton 32. s20: R5 65 / R6 35; Rare 35 / Epic 35 / Legendary 30. Credits are exact (3,000 to 8,000). |
| 18 | Chopshop energy (10 / 12 / 14 / 16) | OK | Probe COST line. |
| 19 | Chopshop: needs a team built for its mechanics | OK | Doc Sawbones: Heal Block, buffs his crew, Patchers. Tips are shown. |
| 20 | Deeds hideouts x4 (Paragon, Neutral, Renegade, Generic), each with its own boss | OK | `Content.HIDEOUTS.deeds_*`; bosses Saint Lumen, Grey Broker, Red Mara, Archivist. All four have "Bring It On" with TM immunity. |
| 21 | Deeds table: 20 stages x 5 rows, ranges, chances | OK | compare_tables: all 100 rows match the GDD text. |
| 22 | Deeds energy (10 / 12 / 14 / 16) | OK | Probe COST line. |
| 23 | Deeds credits (100%) at every stage | **WRONG** | `data/gdd.json:4643` stage 4 is `"8600Credits"` (no space, copied from a GDD typo). `U.parse_one` needs `\s+Credits`, so it fails to parse. **GDD says 8,600 Credits (100%); code gives 0.** Probe: s4 credits 0%, other stages 100%. Shot 12 shows "8600Credits (100%)". |
| 24 | Deeds Minor / Major / Grand: one of three per win | **WRONG** | `Content.gd:250-264` rolls each row independently. The GDD's three chances sum to exactly 100% at all 20 stages (s1: 70 / 30 / 0), which means one tier is picked. Result: 21% of stage-1 wins give no deeds at all, and some give both Minor and Major. The averages are unchanged; the spread and the "no deeds" wins are not. |
| 25 | Deeds Rare Contract chance (0.5% s1-5, 1% s6-10, 1.5% s11-15, 2% s16-20) | OK | Probe: 0.45 to 0.60% at s1/s4, 1.05 to 1.20% at s6/s10, 1.9 to 2.4% at s20. |
| 26 | Deeds tiers feed Reputation (alignment and generic) | OK | Grant adds to `items.deeds[align][tier]`, which `Game.rep_up` uses (section 01's area). |
| 27 | "Possible Victory Strategies" for each hideout | OK | `HIDEOUTS[*].tips` shown as "Counter with" chips. |
| 28 | Boss / minion ATK and PASV blocks shown to the player | OK | INTEL modal lists every ability (shot 13). |
| 29 | Chopshop drop panel shows the full GDD row | **MISSING** | `hideouts.gd:_reward_lines` shows rank and rarity, but not the Limbs / Organs / Skeleton slot odds the GDD lists. |
| 30 | Heist plan count visible to the player | OK | Hideouts rail "5 plans", Battle hub "Heist plans 5 / 5" (shot 00), Inventory. |

### Typos in the GDD itself (the code copies them as written; for the user to confirm, not code bugs)
- Chopshop s6 rarity: Uncommon 35 + Rare 55 + Epic 5 = **95%**. `U.weighted` normalises this, so play shows Epic 6% / Uncommon 36% (probe), and the UI shows "Epic 5%"-style rounded percentages.
- Synapse s14 Tier 1 is "42-52" (10 wide; every other range is 20 wide, so 42-62 was likely meant). Synapse T2 s4-7 and T3 s11-12 are also narrower, but those follow a "0-N" ramp and look deliberate.
- Deeds s4 "8600Credits" is missing a space (this causes the WRONG in item 23).

## Visual issues

| Screen | Issue | Screenshot |
|---|---|---|
| Hideouts, Heist (any stage) | The Drops list (7 rows plus Warlord XP) is taller than the panel. The XP line is hidden, a small scrollbar tick shows under "1xR Contract", and nothing hints that it scrolls. | `shots_08/10_heist_s1.png`, `11_heist_s14.png` |
| Hideouts, Heist | Raw GDD shorthand "1xUC Contract" / "1xR Contract" in the drop list; elsewhere the UI says "Uncommon Contract". | `10_heist_s1.png` |
| Hideouts, Deeds | Drop lines are raw GDD text: "N/A Grand (0%)", "8600Credits", "2-6 Minor" with no alignment named (Minor what?). | `12_deeds_paragon_s4.png` |
| Hideouts, Synapse s12 | Shows "08-28" (raw zero-padded GDD text). | (seen in data; s14 shot shows the format) |
| Hideouts, all | Drops are text lines. The approved canvas (`Hideouts.dc.html`) shows drop **tiles** (item art plus a rank badge, and a credits tile). Gear hideouts belong to section 07; for this section, credits, fragment, implant and deeds tiles would match the canvas. | all `10_*`, `11_*` |
| Hideouts, page 2 (s11-20) | With a 5-digit "Recommended 4,804" the right panel's content is wider than the panel. Stage cell 15/20 and the "11-20 ›" button touch or cross the right notch (about 6 px). | `11_synapse_s14.png`, `11_heist_s14.png` |
| Hideouts rail | "TeraTek Cyberneti" is cut off (section 07's row, but it is the same rail). The canvas shows the full name. | any `10_*` |
| Hideouts, Heist with 0 plans | BATTLE stays gold and active, showing "▤1". You only find out on the squad screen (toast). The rail's "0 plans" stays gold instead of red. | `14_heist_zero_plans.png`, `16_heist_squad_refused.png` |
| Battle results | "REPLAY • 1" / "REPLAY • 10" has no currency icon, so you can't tell plans from energy. | `22_heist_victory.png`, `22_chopshop_victory.png` |
| Battle results | "Brother Gri" name is cut off by "LV 10" (results card; shared screen). | `22_deeds_renegade_victory.png` |
| Battle HUD | The second skill label "GUT RIP" is cut off by the right edge (shared battle HUD). | `21_heist_battle_wave1.png` |

Checked and fine:
- The intel modal is clean once its fade-in ends (`13_heist_intel.png`).
- Victory loot tiles for credits, fragments, implants and deeds read correctly.
- The 3D battle loads its own arena per hideout (vault for Heist).
- No emoji, debug or placeholder text on these screens. The boss silhouette matches the canvas.

Buttons checked:
- Rail rows switch hideout.
- Stage cells 1-20 work, and locked ones are disabled.
- `‹ 1-10` / `11-20 ›` paging works.
- INTEL opens the modal, and its × closes it.
- BATTLE opens the squad screen.
- START pays the cost (plans 5 → 4 after one Heist) or shows a toast when you can't pay.
- BACK, REPLAY and NEXT STAGE appear on the results screen.

The dead file `scripts/ui/screens/hideout_detail.gd` is not routed (`Main.gd:9-10` sends both `hideouts` and `hideout` to `hideouts.gd`).

## Prioritised fixes

**P1**
1. **Deeds stage 4 gives no credits.** In `data/gdd.json` line 4643, change `"8600Credits"` to `"8600 Credits"`. To guard against similar typos, also loosen `U.gd` `parse_one`: in both credit regexes, change `\\s+Credits` to `\\s*Credits` (the `([\\d.,]+\\s*[km]?)\\s+Credits` pattern near `U.gd:185`, and the range pattern at `:178`).

**P2**

2. **Deeds tiers should be one of three, not independent rolls.** In `Content.gd` `hideout_rewards`, `"deeds"` branch (lines 250-264):
   - Split the rows into the tier rows (regex `(Minor|Major|Grand)$`) and the rest.
   - For the tier rows, do a single `U.weighted(tier_rows.map(func(r): return [r, float(String(r[1]).replace("%", ""))]))`, then roll the count for the picked row with `U.ri(lo, hi)`. Skip the row if it is "N/A".
   - Keep the independent `U.chance` roll only for the Credits (100%) and Rare Contract rows.
   - This matches the GDD columns, which sum to 100% (same pattern as the Heist branch).
3. **Heist drop list overflow.** In `hideouts.gd` `_panel`, either reduce the Drops label font from 14 to 13 and gap `v` from 14 to 10 for kinds `credits` / `deeds`, or (better, matching the canvas) render drops as a tile row (`UI` reward tile like `main.show_rewards` uses), so 7 Heist rows fit. Make sure the "Warlord XP" line is visible without scrolling.
4. **Readable drop text.** In `hideouts.gd` `_reward_lines`:
   - `"credits"`: pass `r[0]` through `U.parse_rewards` and print it with the existing reward-label helper (`U.gd:293`-style), giving "1x Uncommon Contract".
   - `"deeds"`: map `"2-6 Minor"` to `"2-6 %s Minor Deeds" % U.cap(align)`, skip rows whose chance is `0%` or that start with `N/A`, and format credits with `U.fmt`.
   - `"mf"`: strip leading zeros from the range (`"%d-%d"`).
5. **Chopshop slot odds missing.** In `hideouts.gd` `_reward_lines`, `"gear", "implant"` branch: when `kind == "implant"`, add `out.append("Slot: " + _pct_text(row.slots))`.

**P3**

6. **Heist with no plans.** In `hideouts.gd` `_panel`:
   - when `not Game.can_pay(enc.cost).is_empty()`, set `go.disabled = true` (or tint the cost chip red);
   - in `build()`, set `rcol = UI.RED` when `Game.cur("heist") == 0`.
7. **REPLAY cost icon.** In `battle.gd:745-753`, build REPLAY with `UI.cta("REPLAY", ..., str(n), "bolt" if k == "energy" else "ticket")`, the same as the hideouts BATTLE button, instead of a plain `"REPLAY • n"` string.
8. **Right panel overflow on stages 11-20.** In `hideouts.gd` `_panel`, set `sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED` and let the "Recommended" label shrink or clip (`clip_text = true`), so the grid stays inside the 360 px notch.
9. **Rail name clipping** (shared with section 07). In `hideouts.gd` `build()`, rail width 262: shorten the TeraTek label to "TeraTek" for the rail, or reduce the rail font so "TeraTek Cybernetics" fits like the canvas.
10. **Consistency.** `Warlords.gd:373`: Doc Sawbones uses `IMMUNE_BOSS` (no Turn Meter immunity). Every other hideout boss uses `IMMUNE_BOSS_TM`, and the GDD's standard "Bring It On" text includes Turn Meter Manipulation. Switch him to `IMMUNE_BOSS_TM` and update the description, unless TM control is meant as his counter (then add it to his tips).
11. **Clean-up.**
    - Delete the unused `scripts/ui/screens/hideout_detail.gd`.
    - `Game.gd:120` `add_cur("heist", 5)` in the starter pack is a no-op under the cap; remove it or leave it.

**Open lever / note for the user (not a bug):** Heist Plans granted by other rewards (29 places in `gdd.json`: logins, jobs, packs) are lost if the player already holds 5, because of the GDD's hard cap. Consider whether reward plans should be allowed above the cap (RAID-style overflow), or whether the reward popup should warn "plans full".
