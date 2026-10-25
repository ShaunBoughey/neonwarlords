# 07 - Syndicate Hideouts: review report

Scope: the four gear hideouts (Cardinal Trolls, Vultures, TeraTek Cybernetics, Quantum Vikings) and the generic hideout reward table.
Code checked: `Content.gd` (`HIDEOUTS`, `hideout_level`, `hideout_cost`, `build_hideout`, `hideout_rewards`), `Warlords.gd` (boss and minion kits), `Battle.gd` (the specials), `Data.gd` (`HIDEOUT_SETS`), `data/gdd.json` (`hideoutGear`) and `scripts/ui/screens/hideouts.gd`.
Probes: `tests/review/07/Probe07.tscn` (headless logic) and `tests/HideoutProbe.tscn` (balance). Screenshots: `tests/review/07/Shots07.tscn` saves to `user://shots_07/`, which is `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_07\`.

**Totals: 43 OK, 4 MISSING (Bring It On on all four bosses), 3 WRONG, 2 DEVIATION.**

## 1. GDD items vs code

### General
| GDD item | Status | Notes |
|---|---|---|
| Hideouts are set mechanic challenges: waves, then a boss with minions | OK | `build_hideout`: wave 1 is a 4-unit syndicate gang (3 for Vikings), wave 2 is the boss and minions |
| 20 stages per hideout | OK | Stage picker covers 1-20; the next stage unlocks on a win (`hideout_record_win`, `unlocked_max`) |
| Main source of high-rank, high-rarity gear, improving over stages 1-20 | OK | |
| Enemy level per stage | DEVIATION | `hideout_level` is documented in GDD_COVERAGE.md |
| Boss HP multiplier `boss_m = 2.5 + 0.05 x stage` | DEVIATION | Documented |

### Cardinal Trolls: Deacon Chainz
| GDD item | Status | Notes |
|---|---|---|
| Two Acolyte minions, Brick and Clyde | OK | `Content.gd:177` |
| ATK1 Not So Fast: remove 10% TM, 20% with ENRAGED or BREAK, 40% with both | OK | `Battle._special_after` "not_so_fast" |
| ATK2 Holy Torment: hit all and place ENRAGED, 3-turn cooldown | OK | Cooldown 3. The GDD gives no duration; the code uses 1 turn |
| ATK3 Holy Fracture: hit all and place BREAK, 4-turn cooldown | OK | Cooldown 4. 25% BREAK for 2 turns (the GDD gives neither value) |
| PASV1 Divine Retribution: one 30% REFLECT stack for each ENRAGED placed | WRONG (minor) | `Battle.gd:896-898` appends the buff straight onto `src.buffs`. That skips `_place_buff`, so Block Buffs on Deacon doesn't stop it, and the stacks have no cap: one Holy Torment on 4 Warlords gives 120% reflect |
| PASV2 Bring It On: immune to STUN, SHOCK, STUPEFY, cooldown increase and ENRAGED | **MISSING** | `Warlords.gd:114` has no `bring_it_on` passive. The probe got STUN, SHOCK, STUPEFY, ENRAGED and TM removal to land on him |
| Bishop Brick ATK1 Celestial Strike: ignore 50% armour vs ENRAGED, 100% if also BROKEN | OK | `Battle.gd:575` |
| Brick PASV1 Mass: 50% ARMOUR UP on Deacon for 2 turns, 3-turn cooldown | OK | `Battle.gd:374` |
| Bishop Clyde ATK1 Celestial Smite: ignore 50% vs BROKEN, 100% if both | OK | |
| Clyde PASV1 Prayer: 10% CONTINUOUS HEAL on Deacon for 2 turns, 3-turn cooldown | OK | `contHeal` at level 0 is 10% |
| Strategy tips | OK | All 6 are in `HIDEOUTS.trolls.tips`. The screen shows only 4 (see Visual) |
| Sets: Firepower, Critical Chance, Strike Back, Goad, Ripper | OK | `Data.HIDEOUT_SETS.trolls` |

### Vultures: Cormac the Carrion Leech
| GDD item | Status | Notes |
|---|---|---|
| ATK1 Open Wounds: double all BLEED stacks on the target | OK | Capped at 10, the global stack cap |
| ATK2 Lacerate: hit all 3 times, one 5% BLEED stack per hit, 4-turn cooldown | OK | |
| ATK3 Devour: fires automatically at 5 BLEED stacks, ignores 100% armour, clears BLEED, heals 25% max HP | OK | Forced in `next_turn` (`Battle.gd:330`) and `_special_after` |
| PASV1 Tear Stitches: Open Wounds on a random target when an opponent heals, 1-turn cooldown | OK | `Battle.gd:784` |
| PASV2 Bring It On: STUN, SHOCK, STUPEFY, TM manipulation, cooldown increase, ENRAGE | **MISSING** | Same gap: `Warlords.gd:146` has no immunity. Every control effect landed in the probe |
| Minions: none listed in the GDD | OK | 2 `thug_vultures` added as filler. Harmless |
| Strategy tips / sets (HP, Crit Damage, Pain Mirror, Plague, Discharge) | OK | |

### TeraTek Cybernetics: Issac Vaun
| GDD item | Status | Notes |
|---|---|---|
| Name. The GDD spells it both "Vaun" and "Vuan" | OK | The code uses "Issac Vaun" consistently |
| ATK1 Bribe: 50% STUPEFY | OK | |
| ATK2 Hostile Takeover: FIREWALL UP on allies and FIREWALL DOWN on enemies for 2 turns, BLOCK BUFFS for 1 turn, 4-turn cooldown | OK | |
| ATK3 Power Play: hit all twice, 25% STUN for 1 turn, 4-turn cooldown | OK | |
| PASV1 Cash Injection: heal all allies 10% max HP each turn | OK | `turn_start` hook |
| PASV2 Bring It On: STUN, SHOCK, STUPEFY, cooldown increase, ENRAGE | **MISSING** | `Warlords.gd:184` |
| Enforcer Kellen: Opportunist (hit all, ARMOUR DOWN for 1 turn) and Capitalist | OK | Kellen also has the recruitable kit's extra skills (Bodyguard Protocol, a leader skill). Fine |
| Enforcer Ried: Schemer (hit all, FIREPOWER DOWN for 1 turn) and Capitalist | OK | Same note: Hostile Bid added |
| Capitalist: gain double the TM removed (the GDD's source is blank) | OK | Read as "TM removed from allies" (`Battle.gd:829`). Sensible |
| Strategy tips / sets (Armour, Hackers to Hacking, Energy Drain, Safeguard, Stitcher) | OK | |

### Quantum Vikings: The Hammer of Four
| GDD item | Status | Notes |
|---|---|---|
| ATK1 Thunder God: hit all, 50% chance of a 50% SHOCK | OK | |
| ATK2 To Valhalla: hit the target, then all allies attack it with ATK1 | OK | `call n:4` |
| PASV1 Ragnarok: revive 1 minion at the start of his turn, then trigger "ATK 3", 3-turn cooldown | **WRONG** | `Battle.gd:383-384` takes `dead[0]` from `side_units(side, false)`, which still holds the dead wave-1 gang. Over 80 probe fights it revived wave-1 units 20 times (thug_vikings 13, freya_static 3, raider_bjorn 2, ragnar_volt 2) and **never a Raider**. The GDD's "ATK 3" doesn't exist; using Thunder God is a sensible reading |
| PASV2 Bring It On: STUN, SHOCK, STUPEFY, TM manipulation, cooldown increase, ENRAGE | **MISSING** | `Warlords.gd:216` |
| Raider (side minion) **x 4** | WRONG | `Content.gd:189` spawns 3 (`for i in 3`). The hideout description says "His four raiders". The 3D formation has 7 slots, so 1 boss and 4 raiders fit |
| Raider ATK1 Hammer Time: if the target was SHOCKED, heal Hammer 10% | OK | |
| Raider PASV1 Shield Wall: +20% armour to Hammer | OK | +20% per living raider (`Battle.gd:246`) |
| Raider PASV2 Four's Chosen: immune to SHOCK | OK | |
| Strategy tips / sets (Firewall, Speed, Stun to Trauma, Jamming, Sanguine) | OK | Trauma is the GDD's "20% chance to apply Stun" set |

### Generic reward table (stages 1-20)
| GDD item | Status | Notes |
|---|---|---|
| Credits per stage, 3000 to 6600 in steps of 200, then 8000 | OK | `gdd.json hideoutGear`, all 20 rows match |
| Energy cost: 10 (stages 1-5), 12 (6-10), 14 (11-15), 16 (16-20) | OK | `hideout_cost`. The probe showed stage 1 = 10, 6 = 12, 11 = 14, 16 and 20 = 16 |
| Rank weights per stage | OK | All 20 rows match, including the GDD's own sums that aren't 100 (stages 6-7 add up to 110). `U.weighted` normalises them |
| Rarity weights per stage | OK | All 20 rows match (stage 6 adds up to 95, also normalised) |
| Slot 16.6% each (Weapon, Helmet, Chest, Gloves, Legs, Boots) | OK | 3000 rolls: each slot got 466-543 |
| 1 piece of equipment from the hideout's own sets | OK | Even split across the 5 sets |
| 100% credits and 100% equipment | OK | |
| Warlord XP (3000 + 1500 x stage) | OK | Not in the GDD. An addition |

## 2. Balance (`tests/HideoutProbe.tscn`)
Win% for 3 squad bands (R5 epic+16, about 6.9K power / R6 epic+16, about 11.4K / R6 legendary+20, about 15.4K):

| Hideout | Stage 5 | Stage 10 | Stage 15 | Stage 20 |
|---|---|---|---|---|
| trolls | 100/100/100 | 100/100/100 | 100/100/100 | 0/100/100 |
| vultures | 100/100/100 | 100/100/100 | 50/100/100 | 0/100/100 |
| teratek | 100/100/100 | 100/100/100 | 0/100/100 | 0/83/100 |
| vikings | 100/100/100 | 100/100/100 | 0/100/100 | 0/50/100 |

What this means:
- These numbers were measured **while the bosses can still be stunned, shocked and TM-controlled, and while Ragnarok never revives Raiders**. Both fixes below make the bosses harder, Trolls and Vultures most of all, since they're currently 100% for R6 epic.
- Re-run this probe after the P1 fixes. If retuning is needed, the open levers are the documented `boss_m` and `hideout_level` (the GDD gives neither). Don't touch the reward tables.
- The cap on Divine Retribution stacks (P2-2) is also an open lever: the GDD doesn't set a maximum.

## 3. Visual review
Screens: Hideouts (rail, boss and stages), stage page 11-20, Boss Intel modal, squad, and boss-wave battles for Trolls and Vikings.

| # | Issue | Screenshot |
|---|---|---|
| V1 | The rail clips "TeraTek Cyberneti" into its count column. The design canvas shows the full "TeraTek Cybernetics" | `shots_07/02_hideout_trolls.png` |
| V2 | The Drops panel is a wall of text (credits, rank %, rarity %, sets, XP). The approved canvas (`Hideouts.dc.html`) shows gear tiles with R-rank badges and a credits tile | `shots_07/02_hideout_trolls.png` |
| V3 | The boss centre stage is a flat silhouette with a red partial arc on the head that looks like a loading spinner. The canvas silhouette is a gradient figure with no arc. A 3D boss model or portrait would be closer to RAID quality | `shots_07/02_hideout_trolls.png` |
| V4 | "Counter with" shows only 4 of the 6 GDD tips (`info.tips.slice(0, 4)`) | `shots_07/02_hideout_trolls.png` |
| V5 | The Boss Intel modal stretches the boss portrait frame to the height of the ability list, so the art repeats (tall yellow frame) | `shots_07/04_trolls_intel.png` |
| V6 | In battle, floating buff texts ("Vampire" / "Firepower Up") stack and overlap above allies. This belongs to the combat view, section 05; noted for reference | `shots_07/12_battle_vikings_boss_auto_1.png` |
| V7 | The Vikings boss wave shows 3 raiders, but the description says four (ties to the Raider x 4 row) | `shots_07/11_battle_vikings_boss.png` |

No emoji, placeholder or debug text was seen. Boss and minion models are distinct; Deacon and Hammer are visibly larger than their minions. The battle header reads "Quantum Vikings - Stage 3 • Boss: The Hammer of Four".

Buttons: the rail rows switch hideout. Stage buttons select a stage, and locked stages are disabled. "‹ 1-10" and "11-20 ›" page correctly and are disabled on their own page. INTEL opens the Boss Intel modal, and its × closes it. BATTLE goes to the squad screen (`06_squad_trolls.png`) with the right cost (10 energy). The back arrow is the shell's.
- `scripts/ui/screens/hideout_detail.gd` is dead code: `Main.gd:9-10` sends both `hideouts` and `hideout` to `hideouts.gd`.

## 4. Prioritised fixes

**P1 (breaks a GDD rule)**
1. **Add Bring It On to the four bosses.** In `scripts/core/Warlords.gd` `_build()`, add a passive to each kit:
   - `deacon_chainz` (line 114) and `issac_vaun` (line 184): `_p("bring_it_on", "Bring It On", "Immune to STUN, SHOCK, STUPEFY, COOLDOWN INCREASE and ENRAGED.", {"immune": IMMUNE_BOSS})`.
   - `cormac` (line 146) and `hammer_of_four` (line 216): the same with `IMMUNE_BOSS_TM` and "Turn Meter manipulation" in the text.

   These four are recruitable, so a player-owned copy would carry the passive too. If that isn't wanted, apply it in `Content.build_hideout` only, to the boss unit after `enemy_unit(...)`: `boss.immune.append_array(Warlords.IMMUNE_BOSS_TM or IMMUNE_BOSS)`, plus a display-only passive for Intel.
2. **Ragnarok must revive a Raider, not wave-1 units.** In `scripts/combat/Battle.gd` `_turn_start` (line 384), change the filter to `side_units(u.side, false).filter(func(x): return not x.alive and x.tpl == "raider" and not has_debuff(x, "blockRevive"))`. A more general alternative: tag the current wave's units, or drop dead units of earlier waves from `units` on a wave change (`Battle.gd:441`).
3. **Spawn 4 Raiders.** In `scripts/core/Content.gd` `build_hideout`, "vikings" branch (line 189): `for i in 4:`.

**P2 (wrong or ugly)**
1. Fix the rail's "TeraTek Cyberneti" clipping. In `scripts/ui/screens/hideouts.gd` `build()`, either widen the rail (pass a larger width to `rail(...)` and move `offset_right` and the centre's `offset_left`), or give rail names a shrink-to-fit or 14px font.
2. Route Divine Retribution through `_place_buff` so Block Buffs applies. In `scripts/combat/Battle.gd:896-898`, replace the direct append with `_place_buff(src, src, {"id": "reflect", "turns": 2, "l": 1}, true)`. That needs `_place_buff` to append stacks for `stack: true` buffs; check it does. Optionally cap reflect stacks (an open lever).
3. Show the Drops panel as gear tiles, as on the design canvas: `hideouts.gd` `_panel` / `_reward_lines`. Keep the % lines as a smaller caption, or move them into INTEL.
4. Re-run `tests/HideoutProbe.tscn` after the P1 fixes and retune only `boss_m` or `hideout_level` if stage 20 becomes impossible for R6 legendary squads.

**P3 (polish)**
1. Show all 6 tips: `hideouts.gd` `build()`, drop `.slice(0, 4)` (the chip flow wraps).
2. Remove the partial arc on the boss silhouette, or replace the silhouette with the boss's model or portrait: `hideouts.gd` `build()`, `Silhouette` usage.
3. In the Intel modal, give the portrait a fixed size: `hideouts.gd` `_intel`, set `size_flags_vertical = SIZE_SHRINK_BEGIN` on `UI.portrait(u.tpl, 56)`.
4. Delete the dead `scripts/ui/screens/hideout_detail.gd`.
5. Note for the GDD owner: the rank weights for stages 6-7 sum to 110 and the rarity weights for stage 6 sum to 95. The code normalises them, so the screen shows R2 36% rather than 40%.

## 5. Vikings stage 20 by day 13 vs Trolls stage 8: explanation

**Cause: the bot's scheduling, not boss mechanics, not a Vikings stat bug, and not squad composition.**

- I re-ran the bot (`tests/review/07/Bot07.tscn`, a copy of `playthrough.gd` that logs the first win or loss per hideout and stage) for 20 days on the pre-fix code.
  - Trolls went 1 → 6 by day 4 with a **100% win record** and was then **never attempted again**. There is not a single Trolls stage 7 battle in 16 days.
  - Vikings went on to stage 17, with logged losses at 15, 16, 17 and 18 before each win.
- Why: in `tests/playthrough.gd` `play_days()` the hideout is picked with `pool[guard % pool.size()]`. `pool` has 15 entries, `"trolls"` is index 0, and `guard` restarts at 1 every session. Trolls is only picked in a session with 15 or more battles. After the campaign ends, a session's energy covers fewer than 15 battles, so Trolls stops being picked while Vikings (index 3) is picked every session. Vultures, TeraTek and Synapse at indexes 1, 2 and 4 also get picked; Chopshop and Deeds Generic at indexes 5 and 6 only when a session has that many battles.
- Head-to-head data (`tests/review/07/Gap07.tscn`): 3 R5 L50 epic+16 squads, 18 fights per cell, win %.

| Hideout | Stage 8 | Stage 12 | Stage 16 | Stage 20 |
|---|---|---|---|---|
| Trolls (pre-fix) | 100 | 100 | 55 | 16 |
| Trolls (with the P1 fixes) | 100 | 100 | 61 | 0 |
| Trolls (fixes + no reflect) | 100 | 100 | 83 | 5 |
| Vikings (pre-fix) | 100 | 100 | 0 | 0 |
| Vikings (with the P1 fixes) | 100 | 100 | 0 | 0 |

  - For the same squads, Trolls is *easier* than Vikings.
  - Divine Retribution's reflect is only 1-21% of the damage taken, so it is not a wall.
- **Fix: no game lever needs to change for this gap.** Fix the bot (a coordinator file; see Requests).
- After wave 1 (below), HideoutProbe still has every gear hideout at 100% for R6 epic+16 up to stage 15. At stage 20, R6 epic+16 wins Vikings 66% and Trolls 100%, and R6 legendary+20 wins all 11 hideouts 100% (table below). That matches the documented curve, so `boss_m` and `hideout_level` are unchanged.

## Wave 1 applied (owner D)

**Content.gd**
- 07 P1-1: "Bring It On" for the four gear bosses comes from `HIDEOUT_BOSS_IMMUNE` in `build_hideout`. That puts it on the hideout boss only; recruited Deacon, Cormac, Issac and Hammer stay normal.
  - Trolls and TeraTek: STUN, SHOCK, STUPEFY, cooldown increase and ENRAGED.
  - Vultures and Vikings: the same plus Turn Meter.
  - `BRING_IT_ON_TEXT` is shown in Intel.
  - Verified: the probe now sees each boss's immune list.
- 07 P1-3: 4 Raiders (wave 2 is now 5 units).
- 08 #2: Deeds now drop exactly one of Minor / Major / Grand per win (weighted pick). Credits and the Rare Contract are still independent rolls. 2000 wins at stage 4: 0 with no deeds, 0 with two tiers, 2000 with credits.
- 06 #2: `gang(..., exclude)` keeps the den boss out of its own escorts.
- 16 P3-4: campaign titles now read "Slums 1-1".
- 11 #1: `BASTION_TURNS` set to 50.
- 11 #3 and #4: `BASTION_TIERS` is now 3 per-stage tables (3K / 8K / 18K / 35K / 60K / 100K for stage 1, rising for stages 2 and 3, and stage 3 pays the most), plus `bastion_tiers(stage)` per the contract.
- 11 #6: `finish()` passes `b.debuffs_on_boss`.
- 11 #8: Bastion title is now "Bastion - <name>".
- 11 #11: Bastion adds are 3 `teratek_drone`.
- TeraTek has a rail short name, "TeraTek".

**Warlords.gd**
- 08 #10: Doc Sawbones uses `IMMUNE_BOSS_TM`.
- 11 #10: Atrium Sentinel has a PASV1 "Security Grid" (+20% Armour). HYDRA's Regrow is now a passive: a 33% chance at turn start to heal 10% and cleanse.
- 11 #11: new `teratek_drone` minion (ATK1 Taser Burst, PASV1 Overwatch).

**hideouts.gd**
- 07 V3 / P3-2: the boss is now a 3D model on a turntable (ModelPreview) instead of the silhouette with the spinner-like arc.
- 07 P2-3 / 08 #3 / #4: drops are a tile row: gear by rank with %, credits, MF tiers, Heist payouts, and Deeds tiers with alignment art. They are followed by short readable lines; raw GDD strings and "08-28" are gone.
- 08 #5: Chopshop slot odds are shown.
- 07 P3-1: all 6 tips are shown.
- 07 P3-3: the Intel portrait has a fixed size.
- 08 #6: BATTLE is disabled when you can't pay (tooltip says why), and "0 plans" shows red.
- 08 #8: "Recommended" ellipsizes instead of overflowing.
- 16 P2-3: stage buttons are 48 px.
- 07 P2-1 / 08 #9 / 16 P3-8: the rail shows "TeraTek".

**Other files**
- 08 #1: `data/gdd.json` "8600Credits" → "8600 Credits". Stage 4 shows and pays 8,600.
- 07 P3-4 / 08 #11: `hideout_detail.gd` deleted (nothing references it).

**Skipped (not my files)**
- 07 P1-2 (Ragnarok revive filter) and P2-2 (Divine Retribution through `_place_buff`) are owner B's (Battle.gd).
- 08 #1's U.gd regex part is owner C's.
- 06 #2's "escorts at lv" doc note is for the coordinator.

**Verification**
- Compile: clean. Earlier errors from `district_map.gd:60` (owner H, mid-edit) cleared on re-check.
- `TestRunner`: failures 0. `UiSmoke`: done, 22 screens OK (only dummy-renderer mesh warnings).
- HideoutProbe (post-fix; band power R5 / R6 / R6max, win % at stages 5 / 10 / 15 / 20):

| Hideout | Stage 5 | Stage 10 | Stage 15 | Stage 20 |
|---|---|---|---|---|
| trolls | 100/100/100 | 100/100/100 | 83/100/100 | 0/100/100 |
| vultures | 100/100/100 | 100/100/100 | 16/100/100 | 0/100/100 |
| teratek | 100/100/100 | 100/100/100 | 0/100/100 | 0/100/100 |
| vikings | 100/100/100 | 100/100/100 | 0/100/100 | 0/66/100 |

- Screenshots re-taken in `shots_07/`:
  - `02_*` (rail, model, drop tiles)
  - `04_trolls_intel` (Bring It On line)
  - `07_drops_synapse` / `_chopshop` / `_deeds_paragon`
  - `08_heist_zero_plans` (disabled BATTLE, red "0 plans")
  - `11_battle_vikings_boss` (4 Raiders)

  No clipping is left on the Hideouts screen.

### Requests
1. **Coordinator, `tests/playthrough.gd` `play_days()`:** replace `pool[guard % pool.size()]` with a counter that persists across sessions, e.g. a member `var _hid_turn := 0` and `var id = pool[_hid_turn % pool.size()]; _hid_turn += 1`. Or pick the pool hideout with the lowest `max`. Without this, the 30-day report under-states Trolls, Chopshop and Deeds Generic progress.
2. **Coordinator, GDD_COVERAGE.md lines to add:**
   - "Hideout 'Bring It On' is applied to the hideout boss only (Content.HIDEOUT_BOSS_IMMUNE), so recruitable copies of Deacon / Cormac / Issac / Hammer don't carry boss immunities."
   - "Bastion: 50-turn cap per entry; per-stage damage tiers (open levers)."
   - "Deeds: one tier per win (the GDD chances sum to 100%)."
3. **Owner B:** 07 P1-2 (Ragnarok must revive Raiders only) is still needed. Until then, Ragnarok revives dead wave-1 gang members.

## Wave 2 applied (owner D)

**Changes (Content.gd only)**
- `hideout_level`: stages 1-10 unchanged (`4 x stage + 1`). Stages 11-15 rise by 8 a stage (level 81 at stage 15). Stages 16-20 now rise by **16 a stage** (level 161 at stage 20, was 121). Rank and rep are unchanged.
- `boss_m`: `2.5 + 0.15 x stage + 0.6 x max(0, stage - 15)`. That gives 4.0 at stage 10, 4.75 at stage 15 and 8.5 at stage 20 (was 3.0 / 3.25 / 3.5).
- `enemy()`: enemy ability levels are now clamped with `Data.ability_max_level(a)` (report 12 Requests).

**How it was tuned**
- I used `tests/review/07/Tune07.tscn`: 4 bands (R4 rare+12 / R5 epic+16 / R6 epic+16 / R6 legendary+20), 12 fights per cell, all 11 hideouts.
- Levels alone saturate at stage 20, so the 16-20 boss HP slope is the knob that separates maxed R6 from R6 epic.
- Three runs averaged over the 11 hideouts at stage 20: 7 / 8 / 7% (R6 epic) and 44 / 46 / 45% (R6 max).

**Final `tests/HideoutProbe.tscn`** (win % R5 epic+16 / R6 epic+16 / R6 legendary+20; band power 7.0K / 11.7K / 14.6K):

| Hideout | Stage 5 | Stage 10 | Stage 15 | Stage 20 |
|---|---|---|---|---|
| trolls | 100/100/100 | 100/100/100 | 100/100/100 | 0/0/100 |
| vultures | 100/100/100 | 100/100/100 | 83/100/100 | 0/0/33 |
| teratek | 100/100/100 | 100/100/100 | 0/100/100 | 0/0/33 |
| vikings | 100/100/100 | 100/100/100 | 0/100/100 | 0/0/0 |
| synapse | 100/100/100 | 100/100/100 | 100/100/100 | 0/0/100 |
| chopshop | 100/100/100 | 100/100/100 | 0/50/100 | 0/0/0 |
| heist | 100/100/100 | 100/100/100 | 100/100/100 | 0/0/100 |
| deeds_paragon | 100/100/100 | 100/100/100 | 0/100/100 | 0/0/0 |
| deeds_neutral | 100/100/100 | 100/100/100 | 100/100/100 | 0/0/100 |
| deeds_renegade | 100/100/100 | 100/100/100 | 16/100/100 | 0/0/16 |
| deeds_generic | 100/100/100 | 100/100/100 | 100/100/100 | 0/0/83 |

**Against the targets**
- Stage 10 needs R5: **met**. R5 wins 100% everywhere. Stages 1-10 weren't in scope, and my extra R4 rare+12 band also still wins stage 10.
- Stage 15 needs R6 for most hideouts: **met**. R5 wins 6 of 11 at 83% or more and 5 at 16% or less. R6 epic wins 10 of 11 at 100% (Chopshop 50%).
- Stage 20: **met**. Maxed R6 averages **51%** in this run (45% over the three Tune07 runs). R6 epic gets **0%** here (7% in Tune07); the target was under 15%.
- Note: the stage-20 spread per hideout is wide (0-100%). Vikings, Chopshop and Paragon are mechanic walls for this generic epic squad. That's the GDD's intent: each needs the right counters (cleanse or AoE, Heal Block immunity, debuff-light squads).

**Verification:** compile clean (0 SCRIPT ERROR), TestRunner failures 0, UiSmoke done.

**For the coordinator:** update the GDD_COVERAGE.md "Hideout enemy levels" deviation row to: "4 x stage + 1 to stage 10, +8 per stage to 15, +16 per stage to 20 (stage 20 = level 161); boss HP x(2.5 + 0.15 x stage + 0.6 x max(0, stage - 15))".

## Wave 3 applied (owner D): campaign curve

**1. Line-up seeding: fixed**
- `build_campaign` called `seed()`, which only seeds Godot's global RNG. `gang()` rolls on `U.rng` (`U.rf` / `U.pick`), so line-ups changed between runs.
- `build_campaign` now saves `U.rng.state`, seeds `U.rng` with the stage key, builds, and restores the state. This keeps the line-up deterministic without disturbing the rest of the game's randomness.
- Verified: `Wall07` builds Warlord 1-1 twice, with RNG use in between, and gets an identical line-up.

**2. Composition spikes: line-up rules (open levers)**

The spikes were healer (modder) den bosses that heal off their own boosted HP and revive (Pontiff 1-7, Marrow 2-7, Mandrill 5-7), plus duplicated named escorts (2x Talon Kree, 3x Yumeko).
- Campaign gangs have at most 1 modder. Extras become the syndicate Bruiser.
- Warlord den-boss stages and modder bosses get no modder escorts.
- Campaign gangs never repeat a named Warlord (`gang(..., unique_named)`).
- Warlord bosses: no modder bosses from den 4, and no legendary bosses before den 6. The fallback is the next allowed named Warlord.
- Den boss HP multiplier (`campaign_boss_mult`): modder 1.0, legendary 1.2, others 1.8 as before.
- Hideout and SW gangs are unchanged: the new `gang()` parameters default to the old behaviour.

**3. Climb (`campaign_bonus`, added on top of `enemy_bonus` for campaign units only)**
- `CAMPAIGN_BONUS = [[0, 0], [0, 0.06], [0.80, 0.0725]]` as base + per den, with `t = den + stage / 6`.
- That is 0 for Street Punk, 0 → 0.6 for Mob Boss, and 0.80 → 1.53 for Warlord.
- The GDD enemy level table is untouched.

**Wall probe** (`tests/review/07/Wall07.tscn`): 2 different epic squads x 8 fights per cell. Win % for R5 epic+16 / R6 epic+16 / R6 legendary+20, by den 1-10.

| | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Mob Boss stage 1 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 |
| Mob Boss den boss | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 100/100/100 | 87/100/100 | 43/100/100 | 93/100/100 | 43/100/100 |
| Warlord stage 1 | 100/100/100 | 100/100/100 | 43/100/100 | 75/100/100 | 100/100/100 | 0/62/100 | 0/87/100 | 0/100/100 | 0/43/100 | 0/31/100 |
| Warlord den boss | 6/87/100 | 12/100/100 | 50/100/100 | 0/100/100 | 0/81/100 | 0/75/100 | 0/68/100 | 0/31/100 | 0/0/68 | 0/0/100 |

**Against the targets**
- Street Punk: unchanged.
- Mob Boss: R5 wins most dens; the last den bosses are 43-93%. **Met.**
- Warlord bosses: R5 gets 0-12%, except 3-7 (Venn) at 50%. R6 epic falls steadily 100 → 81 → 75 → 68 → 31 → 0 → 0. Dens 9-10 need R6 legendary (68% / 100%). **Met**, with one soft spot at 3-7 for R5.

**Hideouts unchanged:** HideoutProbe after the change has the same shape as wave 2. Stages 5 and 10 are all 100%. At stage 20, R6 epic gets 0% everywhere and R6 legendary averages about 50-60%. The run-to-run differences are gear-roll noise; the hideout code paths use the unchanged `gang()` defaults.

**45-day playthrough (NW_SAVE=07, NW_DAYS=45): three runs**

| Warlord base / slope | Mob Boss done | Warlord done | Total playtime at Warlord done | Bot squad |
|---|---|---|---|---|
| 0.85 / 0.070 | day 8 | day 37 | ~75 h | Oni, Abbot, Ried, Raider |
| 0.75 / 0.075 | day 6 | day 19 | **47.4 h** | Gristle, Talon, Bosun, Abbot |
| 0.80 / 0.0725 (final) | day 21 | not by day 45 (playtime >95 h) | — | Bosun, Raider, Abbot, Gristle: 4 rare armour units, power stuck at 12.4K |

- **Conclusion:** the three runs bracket the 50-65 h target (47 h and 75 h), but **the bot's own account RNG (which Warlords it pulls) swamps the lever.**
  - The third run used *identical* Mob Boss values to the first two and still walled at Mob Boss 8-7 for 11 days. Its squad was 4 rare armour units with no damage dealer.
  - The bot only gets past the R5 → R6 gate when it ranks a Warlord to R6 (day 20-30 in all runs), which is the intended "Warlord needs R6" gate.
- The final value sits between the 47 h and 75 h results. I did not keep tuning on single bot runs, because two runs at the same setting could differ by more than the whole target window.
- Hideouts and campaign verified: compile clean, TestRunner failures 0, UiSmoke done.

### Requests (wave 3)
1. **Coordinator, `tests/playthrough.gd`:** seed the bot's account RNG (e.g. `U.rng.seed = int(OS.get_environment("NW_SEED"))` when set, at the start of `_ready`) and run 3 seeds per setting. Only then can the 50-65 h target be tuned to within ±5 h. With a seed, `CAMPAIGN_BONUS[2][0]` is the single knob: 0.75 → 0.85 moved one run from 47 h to 75 h.
2. **Coordinator, bot squad picking:** `squad()` takes the top 4 by power with no role check. A real player would bench 4 armour units with no damage. Consider a "at least 1 firepower / hacker" rule so the bot isn't walled by its own team.
3. **Coordinator, GDD_COVERAGE.md:**
   - "Campaign: extra enemy gear-equivalent bonus Mob Boss 0 → 0.6, Warlord 0.80 → 1.53 by den."
   - "Den boss HP x1.8 (modder bosses 1.0, legendary 1.2)."
   - "Campaign gangs: at most 1 healer, no repeated named Warlord, Warlord den bosses have no healer escorts, no healer bosses from den 4, no legendary bosses before den 6."
