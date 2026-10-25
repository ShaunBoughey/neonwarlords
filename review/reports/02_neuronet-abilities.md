# 02 - Warlord Neuronet & Warlord Abilities - review

GDD text: `review/gdd/02_neuronet-abilities.txt`. I checked the code by reading it and with two headless probes (`tests/review/02/Probe.tscn` for the rules, costs and template audit, and `tests/review/02/Scale.tscn` for abilities whose level does nothing). Screenshots come from a windowed run of `tests/review/02/Shots02.tscn` (NW_SAVE=02) and are saved in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_02\`.

**Totals:** 66 items checked (11 rules, 42 skills, 13 ability rules). **OK 61 · MISSING 0 · WRONG 5 · DEVIATION 0.** R5 is counted as OK; its 5 exceptions are the 5 WRONG skills. All 5 WRONG items share one cause: skills the GDD gives a single value are built as 2-point skills at half value. There are also 3 design gaps: things the GDD doesn't specify that don't work well in practice.

## 1. Neuronet rules

| # | GDD item | Status | Evidence |
|---|---|---|---|
| R1 | 7 synapse layers | OK | `Data.NEURONET[*]` has 7 layers; probe passes |
| R2 | 3 careers: Assault, Protection, Control | OK | `Data.NN_CAREERS` |
| R3 | 2 skills presented per career per layer (42 skills) | OK | probe: 42 |
| R4 | 4 memory slots (points) per synapse layer | OK | `Game.nn_can` returns "This synapse layer is full (4 points)" |
| R5 | "Most skills allow two points each" | OK for 37 skills, **WRONG for 5** (see S-table: Siphon, Wrath, Fracture, Adware, Personal Ads) | `Game.nn_can` caps every skill at 2 |
| R6 | Only 1 of the 2 skills per career in each layer | OK | probe: Blitz is refused after Precision Strike |
| R7 | Fragment tier and cost per point: L1 50xT1, L2 100xT1, L3 150xT2, L4 200xT2, L5 250xT3, L6 300xT3, L7 350xT3 | OK | `Data.NN_COST` matches exactly; probe deducted 50 T1 |
| R8 | Skills cost more as the tree progresses | OK | same |
| R9 | MF tiers 1/2/3 come from the associated hideout, with more at later stages | OK | `Content` "synapse" uses the GDD `synapse` table (owned by section 08) |
| R10 | Layer progression (layers act as "progression levels") | OK | `nn_can` needs 2 points in layer N-1. The GDD doesn't give the threshold, so 2 is an open lever. |
| R11 | Respec | OK (extra) | `Game.nn_reset`: 100 Trinium, full fragment refund (probe: 200 T1 refunded) |

## 2. Neuronet skills (`Data.NEURONET` → `Game.compute_stats` / `Battle._nn`)

| Skill | GDD | Code | Status |
|---|---|---|---|
| Precision Strike | CC +5/10% | +5/10 CC (probe: +10.0) | OK |
| Blitz | First attack +5/10% dmg | `first_attack` bonus | OK (P3: lost if the first action is a buff, see F9) |
| Munitions Dump | FP +5/10% | fpP | OK |
| Force Measure | CD +10/20% | cd | OK |
| Essence Shield | OVERSHIELD 5/10% Max HP on kill | `_die` → `_shield(...,2)` | OK |
| Grand Challenge | +5/10% vs target with higher HP | compares current HP | OK |
| Blood Frenzy | +3/6% per kill, max 9/18% | capped at 3 stacks | OK |
| Accruing Assault | +2/4% per skill use, max 6/12% | `uses-1`, capped at 3 | OK |
| Open Opportunity | +5/10% vs debuffed | OK | OK |
| Berserker Rage | +10/20% per own debuff, max 30/60% | capped at 3 | OK |
| Pummel | +5/10% vs ≤50% HP | OK | OK |
| **Siphon Essence** | **Heal 10% of dmg dealt at ≤30% HP (one value)** | `v: [5, 10]`, 2 points | **WRONG** (`Data.gd:214`) |
| **Warlord's Wrath** | **65% chance of +50% dmg (one value)** | `v: [32.5, 65]` | **WRONG** (`Data.gd:215`) |
| **Fracture** | **50% chance to ignore 30% Armour (one value)** | `v: [25, 50]` | **WRONG** (`Data.gd:215`) |
| Heavy Plating | ARM +5/10% | armP (probe: 62→68) | OK |
| Fitness Regime | HP +5/10% | hpP | OK |
| Egocentric | Heal/shield received +5/15% | `_heal`, `_shield` | OK |
| Altruistic | Heal/shield given +5/15% | same | OK |
| Guardian Angel | Absorb 5/10% of damage to allies | `_deal` | OK |
| Prepared Defense | First hit −10/20% | `first_hit` | OK |
| Desperate Parry | 15/25% counter on crit, once per enemy turn | `countered_turn` | OK |
| Field Surgeon | Healing abilities +50/100% | `from_ability` | OK |
| Medical Learning | Heal 5/10% of enemy heals | `_heal` | OK |
| Galvanized Metals | ARM +10/20% | armP | OK |
| White Knight | 15/25% counter when ally is critted, once per enemy turn | OK | OK |
| Rapid Rescue | +15/25% TM when an ally drops below 25% | `low_fired`, once per ally per battle | OK (P3: doesn't re-fire if the ally is healed and drops again) |
| Battlefield Foresight | Gang OVERSHIELD 5/10% of own Max HP at start | `_round_start_effects`, 3 turns | OK |
| Advanced Formations | Allies gain 5/10% of this Warlord's Armour | `_apply_formations` | OK (P3: compounds when 2 carriers, F11) |
| Malware Packages | HACK +5/15 | OK | OK |
| Real Time Monitoring | FW +10/20 | OK | OK |
| Adaptive Networks | Heal 5/10% when this Warlord blocks a debuff | only on BLOCK DEBUFFS | OK |
| System Exploits | 20/40% for +10% TM when own debuff expires | `_tick_effects` | OK |
| Syphon Intel | Heal 5/10% when an enemy blocks a debuff | on block and on resist | OK |
| Packet Filtering | 20/40% for +10% TM when own buff expires | OK | OK |
| **Adware** | **35% chance debuff +1 turn (one value)** | `v: [17.5, 35]` | **WRONG** (`Data.gd:226`) |
| **Personal Advertisements** | **35% chance buff +1 turn (one value)** | `v: [17.5, 35]` | **WRONG** (`Data.gd:226`) |
| DDoS | 10/20% spread debuff to all enemies | OK | OK |
| Encrypt NeuroNet | FW +30/60 | OK | OK |
| Pull Metadata | 10/20% spread buff to all allies | OK | OK |
| Ransomware | HACK +25/50 | OK | OK |
| Bait and Switch | 15/25% deflect debuff to attacker | OK | OK |
| Breach | +5/10% debuff placement chance | OK | OK |

**Why the 5 are WRONG:** the GDD says "*most* skills allow for two points". Exactly these 5 skills are written with one number instead of an "a/b" pair, so they are the 1-point skills. The build halves them at 1 point and lets them take 2. At 2 points the effect equals the GDD value, but a player pays twice for it (e.g. Wrath costs 700 T3 instead of 350) and the layer budget is wrong: a 1-point skill should leave 3 points for the other careers in that layer. This interpretation is not documented in `GDD_COVERAGE.md`.

## 3. Ability rules

| # | GDD item | Status | Evidence |
|---|---|---|---|
| A1 | Consuming a duplicate levels the skill by 3 levels | OK | `Game.feed_duplicate`; probe: +3 (chosen skill first, the rest spills to random skills, see F4) |
| A2 | Stimm raises an ability by 1 level | OK | `Game.use_stimm` |
| A3 | Stimm rarity must be equal or higher than the warlord's | OK | probe: Rare refused on Epic, Epic accepted. UI dims too-low stimms. |
| A4 | Ability count varies per warlord | OK | 2 to 6 abilities (template audit) |
| A5 | Active abilities, max 3 | OK | all 77 templates have ≤3 (Cormac's 3rd is the automatic Devour) |
| A6 | Passive abilities, always on | OK | `compute_stats` stats; `Battle._hooks` |
| A7 | Leader/Syndicate, max 1, only when leading | OK | max 1 per template; `Battle._apply_leader` uses `team[0]` |
| A8 | Reinforce, max 2, triggers on Pit Royal reinforcement or at the start of a combat round | OK | max 1 per template; `_reinforce_fx` from Pit Royal entry and from new waves (`_round_start_effects(false)`) |
| A9 | Each ability has its own damage multiplier | OK | `mult` per ability |
| A10 | Damage scales off the multiplier and the right stat | OK | `Battle._scaling` × `mult` × level (CLASS_SCALING is a documented deviation) |
| A11 | Cooldowns (Bob example: "cooldown of 3 turns") | OK | `act` sets `cds = cd`, decremented at `_turn_start`, so a CD 3 ability used on turn 1 is ready on turn 4 (RAID semantics). All 36 recruitable templates: A1 has CD 0 and the other actives have CD >0. |
| A12 | Bob example (TM reduction, SPEED UP, 50% ARMOUR DOWN) | OK | all supported by the effect format (`tm`, `buff`, `debuff` with chance) |
| A13 | "Link to a table listing all Warlords and their abilities" | OK (GDD placeholder) | the GDD has no table, so `Warlords.gd` is the source of truth |

Ability levels: max 5 for actives and 3 for others (`Data.ABILITY_MAX_LEVEL`). Each level gives +5% (`ABILITY_LEVEL_BONUS`) to damage, heals, shields, TM gains and debuff chance (<100%), and to leader/passive stats. **The GDD doesn't say what a level does, so this is an open lever.** Design gap (F2): `Scale.tscn` finds about 30 player abilities where leveling changes nothing. These are pure-buff actives (Sanctuary, Holy Rave, Blood Rite, Bodyguard, Hostile Takeover, Shield Wall, Iron Vow, Ninja Protocol, Gene Boost), immunity and "special" passives (Fours Chosen, Adaptive Genome, Conductive, Predator, Ragnarok, Divine Retribution, Tear Stitches, Capitalist ×2, Smuggler, Silent Steps), and every 100%-chance reinforce (Late Mass, Fresh Meat, Headbutt, Boarding Party). The list slightly overcounts hook-based passives such as Fervor and Morbid Feast, whose heal/TM does scale. Players spend stimms and duplicates on these for no gain, and the UI still shows "LVL 1/3".

## 4. Screens and buttons

Screens: Armoury → NEURONET and ABILITIES pages (`scripts/ui/screens/warlord.gd`). The design canvas (DMTXzGtAtiDqeKPyEyxZ7h) has no Armoury board, and the user decided to keep the Armoury as is. So the visual fixes below are label and state fixes only, with no layout changes.

Buttons, all working:
- career tabs switch careers
- skill hexes select a skill
- INSTALL calls `nn_add` and spends fragments
- RESET opens a confirm, then refunds
- duplicate slots open the duplicate drawer (pick up to 2, ✕ closes it)
- stimm icons select a stimm, or show an error when its rarity is too low
- the stimm slot clears the selection
- LEARN applies the selection
- the right bar pages and BACK/home/prev/next work as on the other pages

No emoji found. The RESET button uses a "◆" glyph (F12).

| ID | Issue | Screenshot |
|---|---|---|
| V1 | Career tab art reads "ASSUALT" (typo in `NeuroNetScreenG/AssualtTabButton` PNG) | `shots_02/01_nn_assault_noselect.png` |
| V2 | Locked layers (previous layer <2 points) look identical to open ones. The player only learns about the lock from the modal text after clicking | `shots_02/04_nn_assault_layer3_ready.png`, `05_nn_assault_bottom.png` |
| V3 | A maxed skill (2/2) in a full layer says "THIS SYNAPSE LAYER IS FULL" instead of "MAXED", because the checks run in the wrong order | `shots_02/02_nn_assault_selected_maxed.png` |
| V4 | Rows are labelled "TIER 1-7", which reads like the fragment tier (T1-T3 cost labels sit in the same row). The GDD calls them synapse layers | `shots_02/01_nn_assault_noselect.png` |
| V5 | The Control/Protection tabs show "4/4" on layers where that career has no points. It's correct (the 4 points are shared) but looks like a bug, and the other career's skills give no visual hint that they can't be picked | `shots_02/07_nn_control_layerfull.png` |
| V6 | Ability slot level text "LVL: 1/5" is drawn on top of the "LVL" already baked into `AbilitySlotNLevelBG.png`, so "LVL" appears twice | `shots_02/10_ab_default.png` |
| V7 | Ability names overflow or break mid-word inside the hexes: "CONGREGATIO / N", "DIVINE RETRIBUTION" runs past the hex, "HOLY TORMENT" overlaps the border | `shots_02/10_ab_default.png` |
| V8 | Slot 4 (PASV) level badge runs past the right edge of the abilities panel | `shots_02/10_ab_default.png` |
| V9 | The selection highlight is a pink rectangle laid over a hexagon | `shots_02/11_ab_divine_retribution.png` |
| V10 | LEARN with 2 duplicates and a Legendary Stimm on a skill that has 4 levels left: the duplicates' extra levels spill into random skills, the stimm fails, and the screen shows both "Ability is max level." and "Ability improved". The stimm stays selected | `shots_02/13_ab_dup_and_stimm_selected.png`, `14_ab_after_learn.png` |
| V11 | Help text "DUPLICATE: +3 LEVELS / STIMM: +1 LEVEL…" is 12 px on the 1920 canvas (about 8 px on screen), too small to read | `shots_02/10_ab_default.png` |
| V12 | The ability modal shows no per-level effect (RAID lists what each level adds), and the Neuronet modal shows "5/10%" without saying which value is active now | `shots_02/10_ab_default.png`, `02_nn_assault_selected_maxed.png` |

## 5. Prioritised fixes

### P1
None. No GDD rule is broken badly enough to stop play.

### P2
- **F1: 1-point skills (WRONG ×5).**
  - `scripts/core/Data.gd` `NEURONET`: set `"v": [10], "max": 1` on `siphon`, `[65]` on `wrath`, `[50]` on `fracture`, `[35]` on `adware` and `[35]` on `personalAds`. Restore the GDD descriptions: "Heal by 10% of damage dealt when at 30% HP or less.", "65% chance to deal extra damage equal to 50% of the damage dealt.", "50% chance to ignore 30% Armour when attacking.", "35% chance that each debuff created lasts an extra turn.", "35% chance that each buff created lasts an extra turn."
  - `scripts/core/Game.gd` `nn_can`: replace `>= 2` with `>= int(sk.get("max", 2))`.
  - `scripts/ui/screens/warlord.gd`:
    - `_page_neuronet`: change the pip loop to `for p in int(sk.get("max", 2))`, and the tooltip to `"%s %d/%d" % [sk.name, pts, sk.get("max", 2)]`.
    - `_nn_modal`: change the `"%d/2"` label the same way.
  - `Battle._nn` and `compute_stats` need no change (`v[p-1]`).
  - Existing saves with 2 points in these skills: in `Game` load/migration, clamp to 1 and refund one point of fragments.
- **F2: Ability levels that do nothing (open lever).**
  - Recommended (RAID's skill-book pattern): in `scripts/core/Data.gd`, add `func ability_max_level(a) -> int` that returns 1 when the ability has nothing to scale. Use the same test as `tests/review/02/scale.gd`, extended to look inside `hooks` fx.
  - Use it in `Game.feed_duplicate`, `Game.use_stimm` and `warlord.gd _page_abilities` in place of `Data.ABILITY_MAX_LEVEL[a.type]`.
  - Alternative that keeps the levels: in `Battle._apply_fx` "buff", add +1 turn at max level, and in `Battle.act`, apply `cd - 1` at max level for actives with `cd > 0`. Both are open levers, since the GDD doesn't say what levels do.
- **F3: Learn flow (V10).** In `scripts/ui/screens/warlord.gd` `_learn`:
  - Apply the stimm first.
  - Before feeding duplicates, compute the levels left on `st.ability`. If a duplicate would spill into other skills, show `main.confirm("X levels will go to other abilities. Continue?")`.
  - Set `did` only when no error came back, and say "Ability improved" only then.
  - Clear `st.stimm` after a successful use.
  - In `_pick_warlord` "dup", stop selecting more duplicates once `ceil(levels_left / 3)` are picked.
- **F4: Ability slot labels (V6, V7, V8).** In `warlord.gd` `_page_abilities`:
  - Level label: change the text to `"%d/%d"`, since the art already says LVL.
  - Name label: call `_lbl(..., wrap=false)` (it trims with an ellipsis) at 12-13 px, or add a 2-line WORD wrap with a font-size step-down for names over 12 characters.
  - Slot 4 badge: clamp its x so it ends inside the panel (e.g. `pos.x + 68` → `min(pos.x + 68, 1298 + 476 - 125)`).
- **F5: Lock state on the Neuronet (V2, V5).** In `warlord.gd` `_page_neuronet`:
  - When `li > 0 and Game.nn_layer_points(w, li) < 2`, set `row.modulate = Color(0.5, 0.5, 0.5)` and add a centred "LOCKED: 2 POINTS IN LAYER N" label.
  - For a skill whose pair partner has points, or whose layer is full, dim the hex (`ic.modulate`) as for an unowned skill.

### P3
- **F6 (V3):** in `Game.nn_can`, move the "Skill is maxed." check above the "layer is full" check.
- **F7 (V4):** in `warlord.gd` `_page_neuronet`, change `"TIER %d"` to `"LAYER %d"` (the GDD calls them synapse layers).
- **F8 (V12):** in `_nn_modal`, add the current value line `"NOW: %s  NEXT: %s"` from `sk.v`. In `_page_abilities`, add `"+%d%% per level"` (`Data.ABILITY_LEVEL_BONUS`) under the description, for scaling abilities.
- **F9 (Blitz):** in `Battle._use_ability`, set `u.first_attack = false` only inside the `mult > 0` branch, so a buff on turn 1 doesn't use up Blitz.
- **F10 (Rapid Rescue):** in `Battle._absorb_and_apply`, reset `tgt.low_fired = false` in `_heal` when HP goes back to ≥25%, so the skill fires "whenever" an ally drops below 25%.
- **F11 (Formations):** in `Battle._apply_formations`, snapshot `var base_arm := {}` for every unit before applying, and use `base_arm[u]` so two carriers don't compound.
- **F12:** in `warlord.gd` `_page_neuronet`, change the RESET label's "◆" to the Trinium icon (`Art` currency icon) to match the stroke-icon rule.
- **F13 (V9):** in `_page_abilities`, replace the selection `ColorRect` with the hex outline art (as the Neuronet uses `SkillIconOutline.png`), or drop it and modulate the slot button.
- **F14 (V11):** in `_page_abilities`, raise the help text from 12 to 16 px.
- **F15 (V1):** fix the "ASSUALT" typo in `assets/.../NeuroNetScreenG/AssualtTabButton*.png` (art change). `Art.nn_icon` file names also say "Assualt" but those are internal.
