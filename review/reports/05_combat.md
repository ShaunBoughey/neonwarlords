# 05 - Combat - review

GDD text: `review/gdd/05_combat.txt`. I checked the code by reading `scripts/combat/Battle.gd`, `scripts/core/Data.gd` (BUFFS / DEBUFFS), `scripts/ui/screens/battle.gd`, `scripts/ui/unit_hud.gd` and `Content.finish`. I also ran a headless probe, `tests/review/05/Probe.tscn` (NW_SAVE=05). It places every buff and debuff on real units and checks the numbers: **24/24 checks pass**. The screenshots come from a windowed run of `tests/review/05/Shots.tscn` and are saved in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_05\`.

The brief lists these as documented deviations, so I don't flag them: `DAMAGE_SCALE`, the mitigation cap (`MAX_MITIGATION` 0.8), Overtime (including the 400-turn hard stop) and the AI. There is no turn-order bar, on purpose.

**Totals:** 80 items. **OK 64 · MISSING 3 · WRONG 7 · DEVIATION 6.**
Two of the WRONG items are rule-level and need a user decision, because the fix changes balance:
- The mitigation curve doesn't reproduce the GDD's worked example (M2).
- Hacking vs Firewall is a probability roll, where the GDD describes a pass/fail check (H2).

## 1. Flow of combat

| # | GDD item | Status | Evidence |
|---|---|---|---|
| F1 | Start fight; both teams load ready and facing each other | OK | `01_start_manual.png` |
| F2 | All turn meters fill together and stop when the first one is full | OK | `Battle.next_turn` (Battle.gd:286-302) advances every meter by `spd*dt` to the first full one |
| F3 | Pick the ability first | OK | `battle._show_abilities`; hex buttons, `02_skill_selected.png` |
| F4 | Then pick a target; valid targets depend on the ability | OK | `battle._valid_target` / `_pick_ability` (enemy, ally, self, all) |
| F5 | The ability applies all its effects (TM, damage, buffs/debuffs) | OK | `Battle._use_ability` (pre fx, hits, post fx) |
| F6 | Passives trigger; most don't trigger further passives | OK | `_hooks`; `_in_assist` blocks counters during assists; counters can't be countered |
| F7 | Meters resume from where they stopped; next full meter acts | OK | `_end_turn` resets only the actor (Battle.gd:407) |
| F8 | Repeat until one team is dead | DEVIATION | Overtime from turn 140 and a hard loss at `max_turns` 400 (Battle.gd:316) are documented |
| F9 | Win or loss screen, rewards, back to fight select | OK | `battle._finish`; STAGE MAP / BACK returns via `main.back()` |

## 2. Squad composition / speed

| # | GDD item | Status | Evidence |
|---|---|---|---|
| SQ1 | Squad composition (heading only, no text) | DEVIATION | Team size 4 (user decision, `GDD_COVERAGE.md`) |
| S1 | Speed converts to bar fill; first full bar goes first | OK | `TM_FULL` 1000, fill rate `eff(spd)`; ties go to the higher meter |
| S2 | All bars pause during a turn | OK | Turns are discrete; meters only move inside `next_turn` |
| S3 | Bars pause for extra turns | OK | Extra turn sets `tm = TM_FULL` (Battle.gd:407) |

## 3. Total damage equation

GDD: `Base stats × Ability mult × Ability level × Crit dmg × Neuronet × Buffs × Passives`, minus mitigation at the end.

| # | GDD item | Status | Evidence |
|---|---|---|---|
| D1 | Total base stats | DEVIATION | `Battle._scaling` uses `Data.CLASS_SCALING` (documented) |
| D2 | Ability multiplier, applied first | OK | `a.mult` (Battle.gd:529) |
| D3 | Ability level multiplier | OK | `ab_level_mult` = 1 + 5% per level |
| D4 | Crit damage multiplier (50% CD = ×1.5) | OK | `1 + cd/100 (+crit_bonus)` (Battle.gd:563) |
| D5 | Neuronet bonuses | OK | Stat skills in `Game.compute_stats`; damage skills summed into `bonus` (Battle.gd:530-548) |
| D6 | **Buffs × Passives as separate factors** | **WRONG** (Battle.gd:251, 259) | GDD 1.3 × 1.1 = 1.43. The code adds them: `fpUp + fp_stacks` → 1.40. Same for armour: `armUp` + Shield Wall's 0.20 (Battle.gd:245-249) |
| D7 | Global damage multiplier | DEVIATION | `DAMAGE_SCALE` 2.2 (documented) |
| D8 | Mitigation % taken off at the end | OK | Applied after crit, mark and break (Battle.gd:584-586) |

## 4. Damage mitigation equation

| # | GDD item | Status | Evidence |
|---|---|---|---|
| M1 | Total armour = base × Neuronet × buffs × passives | OK | Plating and Galvanized in `compute_stats`; `armUp`/`armDown` in `eff` (same additive note as D6) |
| M2 | **Armour converts to a mitigation %: worked example 1518 armour = 50%** | **WRONG** (Battle.gd:10, 585) | `arm/(arm+ARMOUR_K)` with K=500 gives **75.2%** for 1518 (probe). The GDD's own example needs K = 1518. `ARMOUR_K` isn't listed in `GDD_COVERAGE.md`. For scale: an R6 L60 warlord has about 200 base armour before gear (probe: Deacon Chainz 201, Hammer of Four 204) |
| M3 | Mitigation cap | DEVIATION | `MAX_MITIGATION` 0.8 (deviation per the brief, but it is **not written in `GDD_COVERAGE.md`**, see fix P3-9) |
| M4 | **Armour penetration subtracts %-points from mitigation (50% - 5% = 45%)** | **MISSING** | Nothing in the game grants armour penetration. The comment at Battle.gd:573 claims the rule, but the code only has "ignore X% armour" effects (`ignore_arm`, Ripper, Fracture), which cut the armour value. That fits their own wording but isn't the GDD rule. Example: GDD 2990 damage; code 1399 (K=500) |

## 5. Hacking vs Firewall

| # | GDD item | Status | Evidence |
|---|---|---|---|
| H1 | Check runs on debuffs and enemy turn-meter changes | OK | `_place_debuff` and `_tm` (v<0 on an enemy) both call `_hack_check` |
| H2 | **"Check if attacker's Hacking is higher than target's Firewall" (pass/fail)** | **WRONG** (Battle.gd:834-838, not documented) | If hack ≥ fw the debuff always lands. Otherwise it's a roll: resist chance = fw - hack, capped at 85%. Probe: hack 0 vs fw 50 resisted 99/200. Read literally, the GDD would resist 200/200 |
| H3 | Debuff order: chance → hack check → block debuffs → existing debuff → refresh/stack → place | OK | `_place_debuff`. Block Debuffs is checked *before* the hack roll (GDD: after). The only effect is which Neuronet heal fires (Adaptive vs Syphon Intel), so this is P3 at most |
| H4 | Buff order: chance → block buffs → existing → refresh → place | OK | `_place_buff`. No ability gives a buff a chance (`_place_buff` ignores `chance`), so the first step is n/a |
| H5 | Firewall Down skips the Hack vs Firewall check | OK | `noCheck` (Data.gd); probe passes at fw 9999 |

## 6. Buffs (`Data.BUFFS`, `Battle.eff` and friends)

| Buff | GDD (small / large) | Code | Status |
|---|---|---|---|
| Speed Up | +15 / 30% | [15, 30] %, probe ×1.15 / ×1.30 | OK |
| Armour Up | +25 / 50% | [25, 50] % | OK |
| Firepower Up | +25 / 50% | [25, 50] % | OK |
| Hacking Up | +40 / 70 flat | [40, 70] flat, probe +40 | OK |
| Firewall Up | +40 / 70 flat | [40, 70] flat | OK |
| Crit Chance Up | +15 / 30 | [15, 30], clamped at 100 | OK |
| Crit Damage Up | +25 / 50 | [25, 50] | OK |
| Block Debuffs | blocks all debuff attempts | `_place_debuff` blocks it (probe). It does **not** stop Reduce Turn Meter, see the debuff table | OK |
| Continuous Heal | 10 / 20% at the start of each turn | max HP %, in `_turn_start` (probe 10%) | OK |
| Bolster | 15 / 25% damage mitigation | `dmg *= 1 - bolster` after armour | OK |
| **Reflect** | 15 / 30% of damage back | values OK, but `"stack": true` (Data.gd), and Divine Retribution appends a second copy (Battle.gd:897) | **WRONG**: the GDD says buffs refresh; two Reflects add up to 60% |
| Overshield | x bonus shield (HP) | amount per ability (`shield` fx, % of HP); probe absorbs | OK |
| Vampire | heal 15 / 30% of damage dealt | added to lifesteal (Battle.gd:605) | OK |
| Counter | 50 / 100% chance to counter | `_buff_sum(counter)`; once per turn | OK |
| **Cooldown** | Decrease / **Reset** | `cd_reduce` fx only does -1; no Reset; no ability uses it | **MISSING** (Reset) |
| Increase Turn Meter | +x% turn meter | `tm` fx, scaled by ability level | OK |
| (Unkillable) | not in GDD | extra; probe holds at 1 HP | (extra, not counted) |

## 7. Debuffs (`Data.DEBUFFS`)

| Debuff | GDD (small / large) | Code | Status |
|---|---|---|---|
| Speed Down | -15 / 30% | [15, 30] | OK |
| Armour Down | -25 / 50% | [25, 50], probe ×0.5 | OK |
| Firepower Down | -25 / 50% | [25, 50] | OK |
| Firewall Down | -40 / 70, no hack check | [40, 70], `noCheck` | OK |
| Hacking Down | -40 / 70 | [40, 70] | OK |
| Crit Chance Down | -15 / 30 | [15, 30] | OK |
| Crit Damage Down | -25 / 50 | [25, 50] | OK |
| Poison | 2.5 / 5% HP at turn start | max HP %, stacks to 10; probe 2.5+5 | OK |
| Bleed | 2.5 / 5% of the damage dealt, at turn start | % of the hit that placed it; probe 50 of 1000 | OK |
| Shock | 25 / 50% chance to miss the turn | probe 114/400 at 25% | OK |
| Stun | misses the next turn | probe: skips, then expires | OK |
| Break | +15 / 25% damage taken | [15, 25] | OK |
| Mark Target | next hit ×2 / ×3 | consumed on the next `_attack` | OK |
| Enraged | basic attack on the enrager only | `next_turn` forces `basic` on the source (probe) | OK |
| Block Buffs | stops all buffs landing | blocks buffs and overshields (probe) | OK |
| **Cooldown Increase** | Increase / **Full Cooldown** | always +1 (Battle.gd:871-876); `val [1, 99]` is ignored; no ability uses the large one | **MISSING** (Full Cooldown) |
| **Reduce Turn Meter** | -x% turn meter (a debuff) | hack check OK, but **Block Debuffs doesn't stop it** (probe: tm 37 → 0 through Block Debuffs) | **WRONG** (Battle.gd:813-822) |
| Heal Block | stops all healing | `_heal` returns (probe) | OK |
| Stupefy | 35% to miss the turn, hacking -50 | probe 141/400; hack -50 | OK |

## 8. Winning and losing screens

| # | GDD item | Status | Evidence |
|---|---|---|---|
| W1 | Victory header | OK | `05_victory.png` |
| W2 | Content name, difficulty, stage number | OK | "Slums 1:7 • Street Punk" |
| W3 | Player XP gained | OK | "PLAYER XP +4" (energy spent) |
| W4 | Item rewards / drops | OK | loot tray |
| W5 | Warlords used | OK | 4 cards, MVP, level-up flags |
| W6 | **Contributions: damage dealt, taken and healed** | **WRONG** (battle.gd:810-815) | Only "DMG" shows. Taken and healed are in the card's tooltip only, so you can't see them on touch |
| W7 | Warlord XP gained | OK | "+500 XP" and an XP bar |
| W8 | Back to upper menu | OK | STAGE MAP / BACK |
| W9 | Continue to next stage | OK | NEXT STAGE (campaign and SW, on a win) |
| W10 | Replay | OK | REPLAY (not in Pit) |
| L1 | Defeat header | OK | `07_defeat.png` |
| L2 | 20% of the winning XP | OK | warlord XP ×0.2 in `campaign_rewards`, `hideout_rewards` and `sw_rewards` (100 vs 500 in the shots). Player XP comes from energy, which is spent up front, so it's the same on a loss. That's the usual RAID behaviour; noted only |
| L3 | **Contributions dealt, taken, healed** | **WRONG** | same as W6 |
| L4 | Back + Replay, no next stage | OK | `07_defeat.png` |
| A1 | AI | DEVIATION | per the brief |

## 9. HUD, status icons, skill buttons and 3D (visual)

The 3D characters are visible and readable. Each has a coloured ground ring per side, a vertical HP bar, a turn-meter strip and a level. Damage numbers, skill banners and reticles all work (`03_action_*.png`, `04_midfight.png`). There's no debug or placeholder text. There's no turn-order bar, which is correct.

| # | Issue | Shot |
|---|---|---|
| V1 | **Enemy buffs are drawn in the same magenta as debuffs.** In `unit_hud._draw` (unit_hud.gd:82-84), `icol` for side 1 is `#ff4fb0`, the same as the debuff colour. On enemies you can't tell a buff from a debuff | `04_midfight.png` |
| V2 | Status icons are small: 22 px box, 15 px glyph, and an 11 px turn count drawn over the glyph's bottom-left. Only 6 show, with no "+N" when there are more | `04_midfight.png`, `03_action_2.png` |
| V3 | Status and skill icons are Unicode glyphs (☠ ♥ ✚ ϟ ⚙ ✸ …, from `Data.BUFFS/DEBUFFS[].icon`, `battle._skill_glyph` and the gear button at battle.gd:73). The design system uses stroke icons, and ☠ ♥ ⚙ can render as colour emoji on some platforms' fonts | all battle shots |
| V4 | Results: warlord names are clipped ("Deacon Cha", "Brother Grir"). The design shows the full name | `05_victory.png`, `07_defeat.png` |
| V5 | Results: the button row sits at y 662-718 of 720, touching the bottom edge. The design has it 34 px up, with the loot tray at y 458 | `05_victory.png` |
| V6 | Results: "REPLAY • 4" has no currency icon (the design shows the energy icon). Also, `cost_txt` is overwritten in the loop (battle.gd:747-749), so a multi-currency cost would show only the last one | `05_victory.png` |
| V7 | Results subtitle has no turn count (the design: "Slums 1-3 · Street Punk · 14 turns") | `05_victory.png` |
| V8 | The gear menu says "Battle paused menu", but the fight keeps running behind it on auto and on enemy turns (`_run` never waits on the menu). The HUD bars also show through the translucent modal | `06_menu.png` |
| V9 | The right-most skill caption ("HOLY FRACTURE") runs to the screen edge (`skill_bar.offset_right` -14) | `01_start_manual.png` |
| V10 | The camera sometimes puts a foreground wall or pillar over the left-most ally | `03_action_2.png` |

## 10. Prioritised fix list

**P1 (the rule doesn't match the GDD; changes balance, so ask the user first, per "GDD numbers are spec")**
1. **M2 mitigation curve**, `Battle.gd` const `ARMOUR_K`. The GDD's worked example (1518 armour = 50%) is reproduced exactly by `ARMOUR_K := 1518.0` with the current `arm/(arm+K)` form. That lowers mitigation a lot at today's armour values, so re-run `tests/BalanceProbe.tscn` and re-tune `DAMAGE_SCALE` (the documented open lever) to keep fights at 15-40 turns. If the user prefers to keep 500, add a row for `ARMOUR_K` to the "Balance tuning" table in `GDD_COVERAGE.md`.
2. **H2 Hacking vs Firewall**, `Battle._hack_check`. Either follow the GDD literally (`return eff(src,"hack") >= eff(tgt,"fw")`), or keep the roll and document it as a deviation in `GDD_COVERAGE.md` ("resist chance = Firewall - Hacking, max 85%"). Note: the literal check makes any boss with more firewall than your hacking fully immune.

**P2 (wrong or ugly)**
3. **W6/L3 contributions**, `battle._result_card`. Add a second stat row under "DMG": `UI.lbl("TAKEN %s  •  HEALED %s" % [U.fmt(c.taken), U.fmt(c.healed)], 12, UI.DIM)`. Raise `card.custom_minimum_size` from 236 to 254, or drop the portrait to 96 px.
4. **V1 buff vs debuff colour**, `unit_hud._draw`. Make the colour depend only on buff vs debuff: `var c: Color = Color("#ff4fb0") if ic.debuff else Color("#3DFF9A")`, and remove `icol`.
5. **Reduce Turn Meter ignores Block Debuffs**, `Battle._tm`. After the `immune` check, add `if has_buff(tgt, "blockDebuffs"): _ev({"e": "block", "u": tgt.uid}); return`.
6. **V4 clipped names**, `battle._result_card` (battle.gd:796). `nm` font 16 → 14, plus `nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS`. Or move "LV n" onto the XP-bar row so the name gets the full 166 px.
7. **V5 buttons at the edge**, `battle._finish`. `UI.vb(14)` → `UI.vb(8)`, `v.offset_top` 30 → 20, `v.offset_bottom` -20 → -34. That saves about 50 px and matches the design's bottom margin.
8. **V2 icon legibility**, `unit_hud.gd`. `ICON` 22 → 26, glyph size 15 → 18. Draw the turn count as a small badge at the bottom-right with a dark backing. When there are more than 6 icons, draw "+N" in the 6th slot.
9. **D6 buffs × passives**, `Battle.eff` ("fp", "arm") and `_scaling`. Apply passives as their own factor: `b * (1 + (fpUp - fpDown)/100) * (1 + fp_stacks/100)`, and for Hammer of Four `* (1 + 0.20 * shield_wall_count)` instead of adding to `m`.
10. **Reflect stacking**, `Data.BUFFS.reflect`. Remove `"stack": true`. In `Battle._place_debuff` (Battle.gd:896-898), replace the raw append with `_place_buff(src, src, {"id": "reflect", "turns": 2, "l": 1}, true)`.

**P3 (polish and completeness)**
11. **Cooldown buff Reset / Cooldown Increase Full**. In `Battle._apply_fx` "cd_reduce", support `f.get("reset", false)` → set every cd to 0. In `_place_debuff` "cdIncrease", when `int(e.l) == 1` set each `tgt.cds[k]` to that ability's full `cd`. No ability uses these yet, so it's for completeness only.
12. **M4 armour penetration**. Fix the misleading comment at Battle.gd:573. If a penetration source is ever added, apply it as `mit = max(0.0, mit - pen/100.0)` after the `ignore_arm` armour cut.
13. **V8 menu pause**, `battle._menu` / `_run`. Add `var paused := false`. Set it in `_menu` and clear it on Resume. At the top of the `_run` loop: `while paused: await get_tree().process_frame`. Make the modal background opaque enough that the HUD doesn't show through.
14. **V6 replay label**, `battle._finish` (battle.gd:745-749). Use `cost_txt += ...` and show the currency icon (`UI` energy icon) rather than a bare number.
15. **V3 glyph icons**. Replace the `icon` glyphs in `Data.BUFFS/DEBUFFS`, `battle._skill_glyph` and the "⚙" gear with stroke-icon textures (e.g. `assets/ui/BattleHUD/status_<id>.png`), drawn with `draw_texture_rect` in `unit_hud._draw`.
16. **V7** append the turn count to the results subtitle (`b.player_turns`). **V9** `skill_bar.offset_right` -14 → -30. **V10** keep the battle camera's look-from clear of the foreground set pieces in `battle_view_3d.gd`.
17. Docs: add `MAX_MITIGATION` 0.8 and the `max_turns` 400 hard loss to the `GDD_COVERAGE.md` "Fight length" row. They're treated as documented, but they aren't written there.

## Wave 1 applied (owner B)

Files edited: `scripts/combat/Battle.gd`, `scripts/combat/battle_view_3d.gd`, `scripts/ui/unit_hud.gd`, `scripts/ui/hex_button.gd`, `scripts/ui/screens/battle.gd`. 05:#1 and 05:#2 were applied after the user's decision (see "Combat decisions" below).

**Battle.gd**
- 05:#5 Reduce Turn Meter is blocked by Block Debuffs (`_tm`).
- 05:#9 buffs and passives are separate multipliers. New `_fp_mod()` used by `eff("fp")` and `_scaling`; Shield Wall is now its own armour factor.
- 05:#10 / 07:P2-2 Divine Retribution goes through `_place_buff` (Block Buffs applies). Stacking is still on: see Requests.
- 05:#11 `cdIncrease` large (`l: 1`) sets full cooldowns; `cd_reduce` with `"reset": true` clears all cooldowns.
- 05:#12 the mitigation comment now says what the code does (armour-ignore, no penetration source yet).
- 02:F9 Blitz is used up only by a damaging skill. 02:F10 `low_fired` re-arms when a heal brings HP back to 25% or more. 02:F11 Formations uses an armour snapshot, so two carriers don't compound.
- 03:#8 Jamming fires every round (next to Safeguard).
- 07:P1-2 Ragnarok revives only dead Raiders.
- 11:#1 the turn limit is checked before `player_turns` is incremented, so it never reports limit + 1. 11:#6 new `debuffs_on_boss` (player debuffs that landed on a boss).

**unit_hud.gd** (05:#4, #8, #15): buffs are green and debuffs pink on both sides. Icons are 26 px. Each status is a stroke pictogram: a stat icon plus an up/down arrow, or Icon shapes for heal, shield, poison, stun, shock and cooldown, or a 2-3 letter code for the rest. The turn count is a badge, and "+N" shows when there are more than 5.

**hex_button.gd**: new `icon_name`, drawn with `Icon.paint` in place of a font glyph. Skill hexes and the gear button use it (05:#15).

**screens/battle.gd**
- 05:#3 the result card shows TAKEN and HEALED.
- 05:#6 names are 14 px with an ellipsis.
- 05:#7 VBox spacing 8, offsets 20 and -34.
- 05:#13 the gear menu really pauses the `_run` loop.
- 05:#14 / 08:#7 / 09:P3-6 REPLAY is `UI.cta` with a bolt or ticket cost badge.
- 05:#16 the subtitle shows "N turns"; skill bar `offset_right` is -30.
- 11:#7 turn-limited fights get a top-centre boss panel (HP bar, TURNS, DAMAGE); the title is shortened; "ROUND 1 OF 1" is hidden for single-wave fights.
- 11:#12 the Bastion result shows "Tier X of Y reached today" (from `Content.bastion_tiers`).
- 16:P3-1 MVP and Level up / Defeated tags are 12 px.

**battle_view_3d.gd**
- 06:#6 `CAMPAIGN_PROPS` gives each campaign location its own prop set.
- 16:P2-1 SSR/SSAO removed; a box-projected `ReflectionProbe` (UPDATE_ONCE) plus a glossier puddle material.
- 05:#16 V10 the camera punch-in is smaller, so the near-left wall stays out of frame.

**Combat decisions (user, applied in wave 1)**
- 05:#1 `ARMOUR_K := 1518.0`: the GDD worked example now reproduces exactly (1518 armour = 50.0% mitigation; the probe prints it).
- 05:#2 `_hack_check` is the literal GDD check: a debuff or enemy turn-meter cut lands only if Hacking ≥ Firewall, with no roll. Probe: hack 0 vs fw 50 is resisted 200/200.
- `DAMAGE_SCALE` retuned from 2.2 to **1.6**. That's the value that brings fight lengths back to the pre-change numbers.

Probe numbers (player turns; win %). Team power varies about ±10% between runs because the gear is random. All runs were made **before** E's Hacker changes (base Hacking 0, `CLASS_SCALING.hacker`); re-run after they land.

| Setup | Mob 10-7 | Warl 1-1 | Warl 5-7 | Warl 10-1 | Warl 10-7 |
|---|---|---|---|---|---|
| Old (K 500, DS 2.2, roll), R6 L60 legendary +20 | 100% 38t | 100% 14t | 100% 37t | 100% 27t | 100% 44t |
| New (K 1518, DS 2.2), same band | 100% 27t | 100% 11t | 100% 25t | 100% 20t | 100% 32t |
| **New (K 1518, DS 1.6)**, same band | 100% 53t | 100% 16t | 100% 46t | 100% 30t | 100% 44t |
| New (K 1518, DS 1.3), same band | 100% 47t | 100% 14t | 100% 42t | 100% 28t | 100% 42t |
| Old, R6 L60 (epic, +16) | 90% 106t | 100% 28t | 30% 69t | 90% 43t | 90% 84t |
| **New DS 1.6**, R6 L60 (epic, +16) | 100% 78t | 100% 22t | 100% 65t | 100% 39t | 100% 58t |
| Old, R5 L50 | 80% 115t | 100% 37t | 10% 62t | 70% 47t | 50% 75t |
| **New DS 1.6**, R5 L50 | 100% 121t | 100% 42t | 0% 78t | 90% 57t | 100% 84t |

ClassProbe (mono-class R6 L60 legendary teams vs W5-7 / W10-1 / W10-7, player turns, all 100% wins):

| Class | Old (K 500, DS 2.2) | New DS 2.2 | **New DS 1.6** | New DS 1.3 |
|---|---|---|---|---|
| armour | 11 / 11 / 18 | 5 / 5 / 12 | 13 / 11 / 15 | 19 / 16 / 27 |
| firepower | 7 / 7 / 13 | 7 / 6 / 8 | 6 / 6 / 11 | 6 / 7 / 12 |
| modder | 25 / 23 / 29 | 17 / 15 / 21 | 27 / 21 / 30 | 37 / 28 / 37 |
| hacker | 15 / 9 / 21 | 10 / 5 / 12 | 15 / 12 / 21 | 15 / 9 / 15 |

With K = 1518, endgame armour (about 500-1260) now gives 25-45% mitigation instead of 48-71%. Armour-class eHP fell the most, and their own damage scales off armour, so the armour/firepower gap shrank: firepower teams are still the fastest. Notes for E and the coordinator:
- The literal hack check makes Firewall a hard wall. Probe: hack 0 vs fw 50 is resisted every time. Once Hacker base Hacking is 0, debuff-heavy kits only land debuffs on targets with equal or lower Firewall (most enemies have fw 30 at base). Keep an eye on Hacker win rates after E's change.
- `Battle.ARMOUR_K` and `MAX_MITIGATION` (0.8, now reached only at about 6000 armour) belong in GDD_COVERAGE ("GDD worked example" / "cap").

**Verification**
- Compile check clean (after H fixed `district_map.gd:60`). `TestRunner`: failures 0. `UiSmoke`: UI SMOKE DONE (only the usual headless dummy-renderer mesh errors).
- Screenshots re-taken in `shots_05/` (now also `08_bastion.png` boss panel, `09_bastion_result.png` tier line, `10_industrial.png` prop set). Checked: green/pink stroke status icons, TAKEN/HEALED rows, full names, buttons clear of the edge, REPLAY with the energy badge, boss panel.
- `tests/review/05/Probe.tscn`: 24/24 pass (Block Debuffs now stops TM reduction).
- New `tests/review/05/Probe2.tscn`: 8/8 pass (FP buff × passive, full cooldown, cooldown reset, Rapid Rescue re-arm, Blitz kept, `debuffs_on_boss`, Formations snapshot, turn limit ≤ limit).

**Requests**
- E (`Data.gd`): remove `"stack": true` from `BUFFS.reflect` (05:#10). Until then, Reflect stacks still add up.
- E (`Data.gd`): the `icon` glyph fields in `BUFFS`/`DEBUFFS` are no longer used by the battle HUD and can stay or go.
- C (`ui.gd` `UI.cta`): the cost badge is placed on the button's `resized` before the badge has a size, so in an HBox it lands outside the button. `battle.gd` now re-places it on the badge's own `resized`; the same fix in `UI.cta` would cover every caller.
- C (`Main.gd` modal): make the modal backdrop opaque enough that the battle HUD doesn't show through (05:V8).
- Coordinator (`GDD_COVERAGE.md`): document `MAX_MITIGATION` 0.8 and the `max_turns` 400 hard loss in the "Fight length" row (05:#17).

## Wave 2 applied (owner B)

**AUTO ×10 multi-battle** (`scripts/ui/screens/battle.gd`, FIXES wave 2 item 1):
- **Run state:** `params.run` = {total, n, wins, items, pxp, wxp, auto, stopped} is carried from battle to battle. `_setup_run()` starts the run when `enc.repeat > 1`, counts the battle number and forces AUTO on. The player's own AUTO setting comes back when the run ends.
- **During a battle:** an "AUTO n/10" tag and a STOP button sit under the title (`_build_run_hud`). STOP sets `enc.repeat = 0`, so the run ends after the current battle.
- **After a win:** if `repeat > 1`, the run isn't stopped and `Game.can_pay(cost)` succeeds, the result screen shows "AUTO n/10 • next battle starting…" with STAGE MAP and STOP AUTO only. After 1.5 s, `_next_run_battle()` pays and calls `main.replace("battle", …)` with `repeat - 1` (copied, because `Content.rebuild` drops it) and the run.
- **The run ends** on a loss, on STOP (in battle or on the result screen), when you leave, or when the cost can't be paid. The last result then shows the combined summary: "AUTO RUN DONE / STOPPED / DEFEATED / OUT OF ENERGY • N battles, W won • Warlord XP +X each", loot from all battles (repeated drops merged as "×N"), and the total Player XP.
- **Rewards are granted once per battle.** `Content.finish` runs once (`_summary`), so a STOP redraw reuses it. The heading shrinks to 60 px during a run so the buttons keep their margin.

**Verification:**
- Compile clean. TestRunner: failures 0. UiSmoke: done.
- New `tests/review/05/ShotsRun.tscn` (windowed): a 3-battle run gave 3 wins, energy 160 → 148 (4 per battle, paid once each), and AUTO restored to off. STOP during battle 1 ends with "AUTO RUN STOPPED • 1 battle". Screenshots: `shots_05/20_run_battle1.png`, `21_run_battle2.png` (tag + STOP), `22_run_result_1.png` (mid-run), `22_run_result_3.png` (combined summary), `23_run_stopped.png`.
- G must still pass `repeat` through `squad.gd`. My test goes straight to the battle screen, so the squad path isn't covered here.
