# Audit 02 - Neuronet (GDD 126-173) and Combat (GDD 366-444)

Method: read `Data.gd` (NEURONET, NN_COST, BUFFS, DEBUFFS), `Game.gd` nn_* and compute_stats, all of `Battle.gd`, the Neuronet page in `warlord.gd`, `battle.gd` and `unit_hud.gd`. Headless probe `tests/audit/02/probe.gd` (run: `NW_SAVE=audit02 timeout 300 Godot_console --headless --path . res://tests/audit/02/probe.tscn -- --nwtest`) exercised neuronet rules and 15 combat scenarios. Probe output:

```
layer2 before layer1: Spend 2 points in synapse layer 1 first.
pair rule blitz: Only 1 of the 2 skills per career can be chosen in each layer.
precision 3rd: Skill is maxed.          5th point layer1: This synapse layer is full (4 points).
t3 spent for 3 L5 points: 750 (expect 750)      siphon max: 1 wrath max: 1
adaptive on resist healed: false (debuff landed false)      <- Adaptive Networks does not fire on a resist
blocked+lowhack event: ["block", "heal"]                    <- Block Debuffs checked before Hacking vs Firewall
fwDown lands with hack0<fw: true          stupefy hack 80 -> 30
mark ratio avg: 2.22 (crit noise), mark consumed            spread bleed hit basis: 0   <- DDoS-spread Bleed ticks for 1
ddos 20% spread 7/60      guardian took 100 of 1000       prepared first/second ratio: 0.80
foresight shields ally 117 = 10% max HP     formations ally arm 62 -> 68 (+10% of 63)
armour nn 30%: x1.302     adware extra-turn rate 36%      siphon healed 11 of 113 dealt     medLearning 10% of heal
```

## 1. Item table

### Neuronet structure

| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| 7 synapse layers | Y | Y | Y | OK | `Data.gd:203-231`; `warlord.gd:866` |
| 3 careers Assault / Protection / Control | Y | Y | Y | OK | `Data.NN_CAREERS`; career tabs `warlord.gd:848` |
| Memory fragments tier 1/2/3 | Y | Y | Y | OK | `items.mf`; owned counts `warlord.gd:911-913`; Synapse hideout is the source (`Content.gd:179,303`) |
| Costs rise through the tree (50/100 T1, 150/200 T2, 250/300/350 T3) | Y | Y | Y | OK | `Data.NN_COST:200`; charged in `Game.nn_add:706`; per-layer "50 T1" label `warlord.gd:877`, cost slot `:918-920`; probe 750 T3 for 3 L5 points |
| 4 memory slots per layer | Y | Y | Y | OK | `Game.nn_can:695`; "x/4" `warlord.gd:876` |
| 2 points per skill ("most skills"); single-value skills 1 | Y | Y | Y | OK | `max` 1 on Siphon, Wrath, Fracture, Adware, Personal Ads (the GDD gives them one value); pips `warlord.gd:901-904` |
| Only 1 of the 2 per career per layer | - | Y | Y | OK | `Game.nn_can:697-700`; partner greyed `warlord.gd:893-898` |
| Layer N needs 2 points in layer N-1 | - | Y | Y | PARTIAL | Not in the GDD and not listed in `GDD_COVERAGE.md`; `Game.nn_can:693`, "LOCKED" label `warlord.gd:908`. Fine as a design choice, needs documenting |
| Reset (100 Trinium, full refund) | - | Y | Y | OK | Extra, not in GDD; harmless (`Game.nn_reset:718`) |
| Skill modal NOW / NEXT values | - | - | Y | WRONG | `warlord.gd:947-948` always appends "%": Malware 5/15, Real Time Monitoring 10/20, Encrypt 30/60, Ransomware 25/50 are flat Hacking/Firewall points, shown as "15%" |

### Neuronet skills (combat effect checked in `Battle.gd`)

| Skill | Status | Evidence / note |
|---|---|---|
| Precision Strike +5/10% CC | OK | `Game.compute_stats:797` |
| Blitz first attack +5/10% | OK | `Battle._attack:548`, cleared on first damaging skill `:514` |
| Munitions Dump +5/10% FP | OK | `compute_stats:798` (see "neuronet multiplier" row) |
| Force Measure +10/20% CD | OK | `compute_stats:799` |
| Essence Shield 5/10% max HP shield on kill | OK | `_die:731-733` (2 turns) |
| Grand Challenge vs higher HP | OK | `_attack:550` (current HP) |
| Blood Frenzy 3/6% per kill, max 9/18% | OK | `_attack:552` |
| Accruing Assault 2/4% per use, max 6/12% | OK | `_attack:553` |
| Open Opportunity vs debuffed | OK | `_attack:554` |
| Berserker Rage 10/20% per own debuff, max 30/60% | OK | `_attack:556` |
| Pummel vs <=50% HP | OK | `_attack:558` |
| Siphon Essence 10% lifesteal at <=30% HP | OK | `_attack:625`; probe 11/113 |
| Warlord's Wrath 65% for +50% | OK | `_attack:615` |
| Fracture 50% to ignore 30% armour | OK | `_attack:599` |
| Heavy Plating +5/10% ARM | OK | `compute_stats:800` |
| Fitness Regime +5/10% HP | OK | `compute_stats:801` |
| Egocentric +5/15% heal/shield received | OK | `_heal:781`, `_shield:813` |
| Altruistic +5/15% heal/shield given | OK | `_heal:783`, `_shield:813` (also boosts non-ability heals, minor) |
| Guardian Angel absorbs 5/10% of ally damage | OK | `_deal:670-675`; probe 100/1000 |
| Prepared Defense first hit -10/20% | OK | `_attack:605`; probe 0.80 |
| Desperate Parry 15/25% counter on crit, once per enemy turn | OK | `_attack:651-657` (`countered_turn`) |
| Field Surgeon +50/100% ability heals | OK | `_heal:784` (`from_ability`) |
| Medical Learning 5/10% of enemy heals | OK | `_heal:796-802`; probe |
| Galvanized Metals +10/20% ARM | OK | `compute_stats:800` |
| White Knight 15/25% counter when ally crit, once per turn | OK | `_attack:658-664` |
| Rapid Rescue 15/25% TM when ally < 25% | OK | `_absorb_and_apply:702-708` (re-arms on heal above 25%) |
| Battlefield Foresight gang shield 5/10% max HP at start | OK | `_round_start_effects:185-188`; probe |
| Advanced Formations allies +5/10% of this ARM | OK | `_apply_formations:168`; probe |
| Malware Packages +5/15 Hacking | OK | `compute_stats:802` (UI shows "%", see above) |
| Real Time Monitoring +10/20 Firewall | OK | `compute_stats:803` |
| Adaptive Networks heal 5/10% when this Warlord blocks a debuff | WRONG | `Battle._place_debuff:873-874` only fires on the Block Debuffs buff (4 sources in the game). A Hacking vs Firewall resist (`:878-882`) - the normal way a debuff is "blocked by this Warlord" - does not heal. Its mirror Syphon Intel fires on both (`:875,880`). Probe: "adaptive on resist healed: false" |
| System Exploits 20/40% +10% TM when own debuff expires | OK | `_tick_effects:440-442` |
| Syphon Intel heal 5/10% when an enemy blocks your debuff | OK | `_place_debuff:875,880` |
| Packet Filtering 20/40% +10% TM when own buff expires | OK | `_tick_effects:432-434` |
| Adware 35% debuff +1 turn | OK | `_place_debuff:887`; probe 36% |
| Personal Advertisements 35% buff +1 turn | OK | `_place_buff:938` |
| DDoS 10/20% spread debuff to all enemies | PARTIAL | `_place_debuff:923-927`. A spread Bleed copies `ctx.hit` for the other enemies, which is 0, so it ticks for 1 damage (probe "spread bleed hit basis: 0") |
| Encrypt NeuroNet +30/60 Firewall | OK | `compute_stats:803` |
| Pull Metadata 10/20% spread buff to all allies | OK | `_place_buff:953-956` |
| Ransomware +25/50 Hacking | OK | `compute_stats:802` |
| Bait and Switch 15/25% deflect debuff to attacker | PARTIAL | `_place_debuff:883-885` swaps target after all checks, so the deflected debuff ignores the attacker's immunities and Block Debuffs |
| Breach +5/10% debuff chance | OK | `_place_debuff:865` |

### Combat

| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| Start fight, teams face each other | - | Y | Y | OK | `battle.gd` / 3D view |
| All turn meters run until the first bar fills | - | Y | Y | OK | `Battle.next_turn:300-316` (start 0-6% random) |
| Pick ability, then target | - | Y | Y | OK | `battle.gd:367-374`, hex skills with tooltips `:448` |
| Ability applies TM / damage / buffs / debuffs | - | Y | Y | OK | `_use_ability:481` |
| Passives trigger; most passives don't trigger more passives | - | ~ | - | PARTIAL | Counters cannot chain (`counter` flag, `_in_assist`), but there is no general guard: Reflect / Guardian Angel / counter damage still fire Rapid Rescue, `ally_low`, `hit_taken`, `kill` hooks (`_absorb_and_apply:700-709`, `_attack:646`) |
| Meters resume from last position | - | Y | - | OK | `_end_turn:422` |
| Repeat until a team is dead; win/loss screen and back | - | Y | Y | OK | `_check_end:444`; `battle.gd` `_finish`, back `:897` |
| Speed -> % fill, first full goes first | - | Y | - | OK | `next_turn:304-317` (no bar: user decision) |
| Bars pause during a turn | - | Y | - | OK | meters only advance between turns |
| Pause for extra turns | - | ~ | - | PARTIAL | `_end_turn:422` sets the actor to exactly 1000; another unit pushed above 1000 during that turn (TM gain caps at 1500, `_tm:846`) is sorted first (`next_turn:317`) and pre-empts the extra turn |
| Total damage = base x ability mult x level mult x crit x neuronet x buffs x passives | - | Y | - | OK | `_attack:545-579`; `DAMAGE_SCALE` 1.6 is a documented DEVIATION |
| Neuronet bonuses as their own multiplier (damage and armour equations) | - | ~ | - | PARTIAL | NN % stats (Munitions, Plating, Galvanized, Fitness) are added into the same % pool as gear/passives/safehouse (`compute_stats:776-807`), and NN damage bonuses share one additive pool with passive specials (`_attack:546-564`). GDD multiplies them separately. Gearless probe x1.302 matches; with gear % it is lower than the GDD |
| ±5% damage variance | - | - | - | PARTIAL | `_attack:614`; not in the GDD and not in `GDD_COVERAGE.md` |
| Mitigation from total armour (1518 = 50%) | - | Y | - | OK | `ARMOUR_K` `Battle.gd:11`, `_attack:601-602` (user decision) |
| 80% mitigation cap | - | Y | - | DEVIATION | documented (`GDD_COVERAGE.md:62`) |
| Armour penetration subtracted from mitigation % (5437 x (1 - (50% - 5%)) = 2990) | N | N | N | MISSING | `Battle.gd:589-590` comment: "has no source in the game yet". The formula has no pen term at all; only "ignore X% armour" exists. `GDD_COVERAGE.md:21` claims armour penetration "Verified" - that claim is false |
| Hacking vs Firewall for debuffs and TM manipulation | - | Y | Y | OK | `_hack_check:856`, `_tm:842`; "RESISTED" float `battle.gd:591` |
| Debuff order: chance > Hacking vs Firewall > Block Debuffs > already has > refresh/stack > place | - | ~ | - | WRONG | `_place_debuff:865-882` checks chance > immune > **Block Debuffs > Hacking**. Probe: low-hack attacker vs Block Debuffs shows BLOCKED (and heals via Adaptive) instead of a resist. Refresh/stack/place parts are OK (`:900-915`) |
| Buff order: chance > Block Buffs > already has > refresh > place | - | Y | - | OK | `_place_buff:932-951` (no buff has a chance in the content) |
| Firewall Down skips the check | Y | Y | - | OK | `noCheck` `Data.gd:181`; probe |
| Buffs table (16 rows): Speed Up 15/30, Armour Up 25/50, Firepower Up 25/50, Hacking Up 40/70, Firewall Up 40/70, Crit Chance Up 15/30, Crit Damage Up 25/50, Block Debuffs, Continuous Heal 10/20, Bolster 15/25, Reflect 15/30, Overshield, Vampire 15/30, Counter 50/100, Cooldown decrease/reset, Increase TM | Y | Y | ~ | OK (x16) | `Data.BUFFS:160-176`; `eff:248-266`; contHeal `_turn_start:380`; bolster `_attack:604`; reflect `:643`; vampire `:622`; counter `:648`; Cooldown `cd_reduce` `_apply_fx:1056`; TM `_tm`. Overshield is ability-% based (Data 10/30 unused) |
| Debuffs table (19 rows): Speed/Armour/Firepower Down, Firewall Down (no check), Hacking Down, Crit Chance/Damage Down, Poison 2.5/5% HP, Bleed 2.5/5% of damage dealt, Shock 25/50% skip, Stun, Break 15/25, Mark x2/x3, Enraged, Block Buffs, Cooldown Increase / Full, Reduce TM, Heal Block, Stupefy 35% + Hacking -50 | Y | Y | ~ | OK (x19) | `Data.DEBUFFS:177-197`; DoTs `_turn_start:371-377`; shock/stun/stupefy `:410-418`; mark/break `_attack:582-588`; enraged `next_turn:350`; blockBuffs `_place_buff:932`, `_shield:811`; cdIncrease `_place_debuff:890-899`; healBlock `_heal:774`; stupefy hack `eff:262`; probe |
| Battle HUD shows buffs/debuffs readably | - | - | ~ | PARTIAL | `unit_hud.gd:80-101,116-137`: icons are drawn only (no per-icon tooltip). Stun and Crit Chance both use "star", Shock and Speed both "bolt"; others are 2-3 letter codes (BD, BB, BR, HB, STU). Value (small/large) and source are never shown; hover text (`battle.gd:328-335`) lists names + turns only. Max 5 icons then "+N" |

Counts: OK 96, PARTIAL 8, WRONG 3, MISSING 1, DEVIATION 2 (DAMAGE_SCALE, 80% cap).

## 2. Fix list

### P1
None found. No rule breaks a fight or the progression.

### P2
1. **Adaptive Networks never triggers on a resist.** `scripts/combat/Battle.gd` `_place_debuff`: in the failed `_hack_check` branch (line 878-882) also apply `var ad := _nn(tgt, "adaptive"); if ad > 0.0: _heal(tgt, tgt, tgt.max_hp * ad / 100.0, false)`, matching Syphon Intel.
2. **Debuff check order does not match the GDD.** `Battle._place_debuff`: move the `_hack_check` block (878-882) above the `has_buff(tgt, "blockDebuffs")` block (871-877), keeping `noCheck` and the immunity check. Order then reads chance > hack vs firewall > block > existing > refresh/stack > place.
3. **Neuronet modal shows flat stats as %.** `scripts/ui/screens/warlord.gd` `_nn_modal` 947-948: no "%" suffix for `malware`, `monitoring`, `encrypt`, `ransomware` (e.g. a `flat` set or `"unit": ""` in `Data.NEURONET`).
4. **Battle status icons not readable.** `scripts/ui/unit_hud.gd` `_paint_status` / `STATUS_ICON`: give Stun and Shock their own glyphs (not "star"/"bolt", which are Crit Chance and Speed); and in `scripts/ui/screens/battle.gd` `_hover` (328-335) add each effect's value from `Data.BUFFS/DEBUFFS[id].val[l]` and `desc` (e.g. "Speed Down -30% (2t)"), so the codes BD/BB/HB/STU can be decoded. A per-icon tooltip on the HUD would be better still.

### P3
5. **Armour penetration term missing; coverage claim false.** `Battle._attack` 601-603: change to `mit = max(0, min(MAX_MITIGATION, arm/(arm+ARMOUR_K)) - pen/100)` with `pen` from a unit field (0 today), so the GDD equation exists; fix `GDD_COVERAGE.md:21` to say no source exists yet.
6. **DDoS-spread Bleed ticks for 1.** `Battle._place_debuff` 923-927: when spreading a `bleed`, pass the original target's hit (`ctx.hit[tgt.uid]`) as the basis for the copies.
7. **Bait and Switch bypasses the attacker's defences.** `Battle._place_debuff` 883-885: after swapping to `src`, re-check `src.immune` and `has_buff(src, "blockDebuffs")`.
8. **Extra turn can be pre-empted.** `Battle._end_turn` 422 / `next_turn` 317: on an extra turn, give the actor priority (e.g. `opts`/flag `_extra_uid` checked before the TM sort) instead of relying on tm = 1000.
9. **Neuronet as its own multiplier.** `Game.compute_stats`: apply the NN % stats (`munitions`, `plating`, `galvanized`, `fitness`) as a separate factor after the gear % pool, matching "Total Base x Neuronet x Buffs x Passives".
10. **Document undocumented choices** in `GDD_COVERAGE.md`: layer N needs 2 points in N-1; ±5% damage variance; passive chaining not generally guarded.

## Applied (fix owner A - combat)
- P2 1/2: `Battle._place_debuff` now checks chance > Hacking vs Firewall > Block Debuffs > existing > refresh/stack > place; Adaptive Networks and Syphon Intel fire on both resist and block (`_debuff_blocked_heals`). `_place_buff` rolls an optional chance before Block Buffs. Probe: resist heals, event order ["resist","heal"].
- P2 4: `unit_hud.gd` gives every buff/debuff its own stroke glyph (no shared star/bolt, no letter codes); per-icon tooltip (hover) and tap/click (`status_pressed` -> info line) with name, value and turns left; "+N" box lists the rest. `battle.gd` `_status_list` builds the texts, `_hover` uses them.
- P3 5: armour penetration is now the GDD step `mit = min(cap, arm/(arm+K)) - pen%`, pen from the ignore-armour sources (ability ignore_arm/Devour, Celestial Strike/Smite, Ripper, Fracture) plus an optional unit `pen` field. GDD_COVERAGE.md:21 not edited (not owner A's file).
- P3 6: DDoS-spread Bleed copies use the original target's hit as basis (probe 10000).
- P3 7: Bait and Switch re-checks the attacker's immunity and Block Debuffs after the deflect.
- P3 8: extra turns get priority (`_extra_uid`) over other units above 100% TM.
- Not done: P3 9 (Game.gd, owner C), P3 10 (GDD_COVERAGE.md).

## Applied (fix owner B)
- P2 3: warlord.gd `_nn_modal` shows Malware / Real Time Monitoring / Encrypt / Ransomware values as flat numbers (no "%").
