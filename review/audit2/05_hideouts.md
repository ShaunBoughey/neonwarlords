# Audit 05 - Hideouts (GDD lines 665-1473)

Scope: hideout intro, Cardinal Trolls, Vultures, TeraTek, Quantum Vikings, the generic gear reward table, Synapse Centre, Heist, Chopshop and the four Deeds hideouts. I checked the code, the UI (`scripts/ui/screens/hideouts.gd`) and two headless probes:
- `tests/audit/05/probe.tscn` samples rewards (4000 wins per row) and spot-checks the mechanics.
- `tests/audit/05/sim.tscn` runs full hideout fights and counts the debuffs that land on the player's team.

Data check: a Python diff of every GDD table row against `data/gdd.json` (`hideoutGear`, `chopshop`, `synapse`, `heist`, `deeds`) found **no mismatches**. The only difference is the GDD typo "8600Credits" at Deeds stage 4, which the data fixes.

## 1. Item table

| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| 1 | Hideouts are set challenges built around mechanics | yes | **no** in practice | yes | **WRONG** | The boss mechanics almost never land on the player. `Battle._place_debuff` (Battle.gd:868-878) applies the literal check Hacking >= Firewall. Boss Hacking is 0 at stage 1, 24 at stage 10 and 40 at stage 20 (probe). Player Firewall is 30 base, 78-102 at R5 and 170-218 at R6. Sim results: ENRAGED, BREAK, BLEED and SHOCK landed **0 times** in 18 fights each for Trolls, Vultures and Vikings at stages 6, 10 and 18, against 99-427 resists. TeraTek only lands FIREWALL DOWN (`noCheck`), with a little STUPEFY/ARMOUR DOWN at low stages. The user decision (literal check) stands; the problem is the open lever, enemy Hacking scaling. |
| 2 | Example (two waves then a boss with minions that revive) | yes | yes | yes | OK | `Content.build_hideout` builds 2 waves (Content.gd:231-273); Vikings revive (Ragnarok). |
| 3 | "Certain Warlords excel in certain hideouts" | n/a | broken by #1 | - | PARTIAL | Counters such as cleanse or Block Debuffs are pointless while the debuffs never land. |
| 4 | Best source of high rank/rarity gear; payout chances rise over stages 1-20 | yes | yes | yes | OK | `hideout_rewards` (Content.gd:281-338); see #40-46. |
| 5 | Trolls lore/desc | yes | - | yes | OK | `HIDEOUTS.trolls.desc`, shown in centre header. |
| 6 | Deacon ATK1 Not So Fast: -10% TM, -20% if ENRAGED or BREAK, -40% if both | yes | yes | Intel | OK | `_special_after` "not_so_fast" (Battle.gd:1064-1071). Goes through the hack check (Battle.gd:836-842). |
| 7 | ATK2 Holy Torment: AoE + ENRAGED, CD 3 | yes | yes (rarely lands, #1) | Intel | OK | Warlords.gd:116. Enrage lasts 1 turn (the GDD gives no duration). |
| 8 | ATK3 Holy Fracture: AoE + BREAK, CD 4 | yes | yes (#1) | Intel | OK | Warlords.gd:117, 25% Break for 2 turns. |
| 9 | PASV1 Divine Retribution: one stack of 30% REFLECT per ENRAGE placed | yes | yes | Intel | OK | Battle.gd:921-922. Probe: 2 enrages give 60% reflect, from stacked buffs lasting 2 turns. Never triggers in real fights (#1). |
| 10 | PASV2 Bring It On (Trolls): STUN, SHOCK, STUPEFY, INCREASE CD, ENRAGE; **no** TM immunity | yes | yes | Intel | OK | `HIDEOUT_BOSS_IMMUNE.trolls` (Content.gd:219); probe: stun is blocked; TM -50 applies when hack passes. `BRING_IT_ON_TEXT` is shown in Intel. |
| 11 | Bishop Brick Celestial Strike: ignore 50% armour vs ENRAGED, 100% if also BROKEN | yes | yes | Intel | OK | Battle.gd:592-597. Has no effect while #1 stands. |
| 12 | Brick Mass: 2-turn 50% ARMOUR UP on Deacon, CD 3 | yes | yes | Intel | OK | Battle.gd:389-397 (`special_cd.minion` = 3; armUp l=1 = 50%). |
| 13 | Bishop Clyde Celestial Smite (mirror of #11 for BREAK) | yes | yes | Intel | OK | Battle.gd:592-597. |
| 14 | Clyde Prayer: 2-turn 10% CONTINUOUS HEAL on Deacon, CD 3 | yes | yes | Intel | OK | Battle.gd:395 (contHeal l=0 = 10%). |
| 15 | Trolls victory strategies | yes | - | yes | OK | `tips` are shown as "Counter with" chips. |
| 16 | Trolls sets: Firepower, Crit Chance, Strike Back, Goad, Ripper | yes | yes | yes | OK | `Data.HIDEOUT_SETS.trolls`; probe gives about 20% each; panel line "Sets:". |
| 17 | Vultures lore | yes | - | yes | OK | |
| 18 | Cormac ATK1 Open Wounds: double all BLEED stacks | yes | yes | Intel | OK | Battle.gd:1072-1079; probe: 3 stacks become 6 (capped at 10). |
| 19 | ATK2 Lacerate: AoE x3 hits, one 5% BLEED stack per hit, CD 4 | yes | yes (#1: never lands) | Intel | OK* | Warlords.gd:148 (hits 3, bleed l=1 = 5%). |
| 20 | ATK3 Devour: automatic, locked until 5 bleed stacks, ignores 100% armour, removes BLEED, heals 25% | yes | yes | Intel | OK* | Battle.gd:344-349 forces it, `auto` keeps it out of normal use (Battle.gd:293), effect at Battle.gd:1080-1084. **Can't trigger in practice** because bleed never lands (#1). |
| 21 | PASV1 Tear Stitches: Open Wounds on a random target when an opponent heals, 1-turn CD | yes | yes | Intel | OK | Battle.gd:803-808. |
| 22 | PASV2 Bring It On (Vultures) incl. TM | yes | yes | Intel | OK | Content.gd:220; probe: TM -50 on Cormac is ignored. |
| 23 | Vultures has no minions listed in the GDD | - | code adds 2 `thug_vultures` | Intel | DEVIATION (undocumented) | Content.gd:243. Not in `GDD_COVERAGE.md`; document it or keep only designed minions. |
| 24 | Vultures strategies | yes | - | yes | OK | |
| 25 | Vultures sets: HP, Crit Damage, Pain Mirror, Plague, Discharge | yes | yes | yes | OK | Data.gd:154 ("Health" = HP). |
| 26 | TeraTek lore | yes | - | yes | OK | |
| 27 | Issac Bribe: 1 hit, 50% STUPEFY | yes | yes | Intel | OK | Warlords.gd:185. |
| 28 | Hostile Takeover: FIREWALL UP allies 2t, FIREWALL DOWN enemies 2t, BLOCK BUFFS 1t, CD 4 | yes | yes | Intel | OK | Warlords.gd:186; Block Buffs goes on enemies (the GDD names no target). |
| 29 | Power Play: AoE x2, 25% STUN 1t, CD 4 | yes | yes | Intel | OK | Warlords.gd:187. |
| 30 | Cash Injection: heal all allies 10% max HP each turn | yes | yes | Intel | OK | turn_start hook (Issac's turn). |
| 31 | Bring It On (TeraTek): no TM immunity | yes | yes | Intel | OK | Content.gd:221. |
| 32 | Kellen Opportunist: AoE + ARMOUR DOWN 1t | yes | yes | Intel | OK | Warlords.gd:166. Kellen and Ried also have extra 2nd actives and leader skills that are not in the GDD (template is recruitable). |
| 33 | Kellen/Ried Capitalist: gain 2x the TM removed from '' (the GDD leaves the target blank) | yes | interpreted as TM removed from allies | Intel | PARTIAL | Battle.gd:848-853. Reasonable, but the interpretation is not in GDD_COVERAGE. |
| 34 | Ried Schemer: AoE + FIREPOWER DOWN 1t | yes | yes | Intel | OK | Warlords.gd:172. |
| 35 | TeraTek strategies, sets (Armour, Hacking, Energy Drain, Safeguard, Stitcher) | yes | yes | yes | OK | Data.gd:155 (the GDD says "Hackers" = Hacking set). |
| 36 | Vikings lore; Thunder God: AoE, 50% chance of 50% SHOCK | yes | yes (#1) | Intel | OK* | Warlords.gd:217. |
| 37 | To Valhalla: hit the target, then all allies use ATK1 on it | yes | yes | Intel | OK | `call` n=4 (Battle.gd:1033-1044). |
| 38 | Ragnarok: revive 1 minion at turn start, then trigger "ATK 3" (which doesn't exist), CD 3 | yes | revives a Raider at 30%, then Thunder God | Intel | PARTIAL | Battle.gd:398-406. Reading "ATK 3" as Thunder God and the 30% revive HP are both undocumented. The CD only starts if a revive happened. |
| 39 | Bring It On (Vikings) incl. TM; 4 Raiders; Hammer Time (heal Hammer 10% if target shocked); Shield Wall +20% armour each; Four's Chosen SHOCK immunity | yes | yes | Intel | OK | Content.gd:250-253 (5 in wave 2), Battle.gd:256-259, 633-636, Warlords.gd:338-342. Hammer Time never heals (#1: shock never lands). |
| 40 | Vikings sets: Firewall, Speed, Stun (= "Truma"/Trauma), Jamming, Sanguine | yes | yes | yes | OK | Data.gd:156. |
| 41 | Generic gear table: credits per stage | yes | yes | yes | OK | Probe: 3000/4000/4200/5400/8000 at stages 1/6/7/13/20. |
| 42 | Energy 10/12/14/16 by stage band | yes | yes (`Game.pay`) | CTA badge | OK | `hideout_cost`; BATTLE shows bolt + n. |
| 43 | Rank odds per stage | yes | yes | yes (tiles) | OK / note | Probe matches, e.g. s13 25.9/54.3/19.8 against 25/55/20. GDD stages 6-7 sum to **110%** (40/35/35) and stage 6 rarity to **95%**. Code and UI normalise, so stage 6 shows 36/32/32. The handling is not documented. |
| 44 | Rarity odds per stage | yes | yes | yes | OK | Probe s20 rare 35.5 / epic 33.1 / legendary 31.4. |
| 45 | Slot 16.6% each of 6 | yes | yes | **no** | PARTIAL (UI) | Uniform `U.pick` (Game.gd:872), but the panel never states the slot odds. |
| 46 | "Random Equipment 1-3 / 2-4 / 3-5 / 4-6" band | yes | yes | yes | OK | Follows from the rank rows. |
| 47 | Synapse: only source of Memory Fragments, farmable with energy | yes | yes | yes | OK | `kind: mf`. |
| 48 | Synapse table (tier 1/2/3 ranges, energy 8/10/12/14) | yes | yes | yes | OK | Each tier rolled independently, 0 = none. Stage 14 tier 1 is "42-52", kept literally (probably a typo for 42-62; ask the user). |
| 49 | Synapse boss blank + Bring It On incl. TM | designed (MNEMOSYNE) | yes | Intel shows template passive | OK | Warlords.gd:363-367 `IMMUNE_BOSS_TM`. |
| 50 | Heist: credits-focused, contracts as a rare drop, occasional huge payout | yes | yes | yes | OK | |
| 51 | Heist Plan required; 5 a day; capped at 5, unused lost | yes | yes | rail + Fight screen | OK | Game.gd:264 refreshes to 5 (overflow from rewards is a user decision). The cost is 1 plan (ticket icon). |
| 52 | Heist reward table per stage (one weighted outcome; rows sum to 100) | yes | yes | yes | OK | Probe s1: 50k 30.4, 75k 39.5, 100k 24.9, 500k 2.1, 1M 0.4, UC 2.1, R 0.5; s20 5xUC 2.2, 2xR 0.3. |
| 53 | Chopshop: primary implant source | yes | yes | yes | OK | |
| 54 | Chopshop table: credits, energy, rank and rarity per stage | yes | yes | yes | OK | Probe matches all sampled stages. |
| 55 | Chopshop slot 35/35/30; **stage 13 40/35/25** | yes | yes | yes ("Slot:" line) | OK | Probe s13 limbs 39.6 / organs 35.9 / skeleton 24.6. |
| 56 | Chopshop stage 20 "Rank 5-6" (Rank 4 = 0) | yes | yes | yes | OK | Probe 63.3/36.7. The tile is hidden for 0%. |
| 57 | Chopshop credits 6600/6800 at stages 18/19 (they differ from the gear table) | yes | yes | yes | OK | The data copies the GDD. |
| 58 | Paragon/Neutral/Renegade/Generic Deeds: boss blank + Bring It On incl. TM | designed | yes | Intel | OK | Warlords.gd:388-428 `IMMUNE_BOSS_TM`. |
| 59 | All-deeds table: one of Minor/Major/Grand, range per stage | yes | yes | yes | OK | Probe s14: minor 42 / major 38.6 / grand 19.2 against 42/38/20; ranges 4-8, 1-4 and 1-2 confirmed. Documented in GDD_COVERAGE. |
| 60 | Deeds credits 100%, rare contract 0.5/1/1.5/2% | yes | yes | yes | OK | Probe s1 rare contract about 0.5%. |
| 61 | Deeds energy 10/12/14/16 | yes | yes | yes | OK | |
| 62 | Deeds of the hideout's alignment | yes | yes | yes | OK | `HIDEOUTS.*.align`. |
| 63 | Stage unlock (stages 1-20, sequential) | yes | yes | yes | OK | `unlocked_max = max+1` (hideouts.gd:17), buttons above it are disabled, NEXT needs max >= stage (Content.gd:515). |
| 64 | Boss/minion abilities shown | yes | - | INTEL modal | OK | hideouts.gd:189-209. Wave-1 gang members are not described (acceptable). |
| 65 | Reward odds shown per stage | yes | - | partial | PARTIAL | Rank/rarity/credits, synapse ranges, heist %, deeds % and contract % are shown; gear slot odds are not (#45). |

\* OK as written, but the effect cannot happen in real fights because of #1.

**Counts:** OK 54 (incl. 5 OK* that #1 nullifies), PARTIAL 5, WRONG 1, MISSING 0, DEVIATION (undocumented) 1. Plus 2 notes on the GDD's own numbers (#43 sums, #48 typo).

## 2. Fix list

### P1
1. **Hideout boss/minion debuffs never land (the hideout mechanics are dead).**
   - Where: `Content.enemy` / `Content.enemy_unit` (Content.gd:12-24), or `build_hideout` (Content.gd:231).
   - Change: give hideout wave-2 units a Hacking value that grows with stage and keeps up with typical player Firewall at that stage. For example, add a per-stage Hacking bonus to `u.base.hack` in `build_hideout`, tuned with `tests/audit/05/sim.tscn` so that ENRAGE/BREAK/BLEED/SHOCK land a meaningful share of the time.
   - This is an **open lever** (the GDD gives no enemy Hacking). The literal Hacking >= Firewall rule stays. Ask the user before tuning.

### P2
2. **Gear slot odds are not shown.** In `hideouts.gd` `_reward_lines`, `kind == "gear"` branch, add "Slot: Weapon/Helmet/Chest/Gloves/Legs/Boots 16.6% each".
3. **Interpretations not documented** (Ragnarok "ATK 3" = Thunder God with a 30% HP revive; Capitalist = TM removed from allies; two extra Vultures thugs; normalising the GDD odds that sum to 110%/95%). Add them to `GDD_COVERAGE.md` deviations (a coordinator or user edit), or ask the user. Players see these effects in Intel, so the descriptions should match.

### P3
4. Synapse stage 14 tier 1 "42-52": ask the user whether this is a typo for 42-62 (kept literal).
5. The Intel modal also lists the non-GDD extra abilities on Kellen, Ried and the hideout bosses (leader and reinforce skills from the recruitable templates). Consider hiding leader/reinforce skills in hideout Intel (`hideouts.gd` `_intel`: skip `a.type in ["leader", "reinforce"]`).

## Applied (owner D, screens)
- P2 2 hideouts.gd _reward_lines gear: "Slot: Weapon / Helmet / Chest / Gloves / Legs / Boots, 16.6% each".


**Applied (owner C, user decision "scale enemy Hacking"):** `Content.enemy_hack(level)` = ENEMY_HACK_BASE 10 + ENEMY_HACK_PER_SQRT_LEVEL 14.4 * sqrt(level), applied as a Hacking floor (max with own) in `enemy_unit` (campaign, hideouts, SW) and `_pit_unit` (Pit); Bastion opted out. Probe `tests/fix/C/hack_sim.tscn`: checked debuffs landing on an unspecialised squad - Trolls/Vultures/Vikings s1 61/65/80%, s10 58/61/62%, s20 32/83/53%; Firewall-set squad 0% everywhere.
