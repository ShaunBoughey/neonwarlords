# Audit 2 / 03: Warlord Equipment (GDD lines 185-276)

Probe: `tests/audit/03/probe.gd` (`probe.tscn`), run headless with `NW_SAVE=audit03`. It checks the slot matrix (600 R6 legendary rolls per slot), starting substats and leveling per rarity, primaries at +0, the neon rules, every 2-piece stat set through `Game.compute_stats`, every effect set through `Battle._attack`, `_round_start_effects` and `_turn_start` (400 seeded hits each), and the Black Market, Trinium shop and Pit cache equipment parsing. Script errors in the log only come from the probe's own "none" set key. Real failures: 3, all explained in row 12.

**Totals (62 rows): 49 OK, 0 MISSING, 1 WRONG, 9 PARTIAL, 3 DEVIATION/lever notes.** No P1.

## 1. GDD items

Layers: St = stored, Ru = rules, Sh = shown.

### Gear and Implants
| # | GDD item | St | Ru | Sh | Status | Evidence / note |
|---|---|---|---|---|---|---|
| 1 | Six gear slots: Weapon, Boots, Legs, Chest, Helmet, Gloves | Y | Y | Y | OK | `Data.gd:40`; Armoury Gear page `warlord.gd:_page_slots`, Inventory slot tabs |
| 2 | Gear works on a warlord of any level | Y | Y | Y | OK | `Game.equip_on` (Game.gd:923) has no level gate |
| 3 | Three implant slots: Limbs, Organs, Skeleton | Y | Y | Y | OK | `Data.gd:41`; Armoury Implants page; Inventory > Implants |
| 4 | Implants unlock at Reputation 2 / 4 / 6 | Y | Y | Y | OK | `Data.IMPLANT_UNLOCK` (Data.gd:72); enforced in `equip_on`, `auto_equip` and `warlord._select_slot` (warlord.gd:415) |
| 5 | Implant lock shown with its Rep requirement | Y | Y | partial | PARTIAL | The Armoury slot shows "REP n", a tooltip and the "IMPLANTS UNLOCK AT REP 2 / 4 / 6" hint (warlord.gd:384-409). The Inventory item popup (`item_view.gd`) and the item tooltip (`ui.gd:item_tooltip`) never say an implant needs Rep 2/4/6, and the equip delta in the gear modal doesn't say the slot is locked for this warlord |

### Neons
| # | GDD item | St | Ru | Sh | Status | Evidence / note |
|---|---|---|---|---|---|---|
| 6 | Neons attach to equipment and raise a matching substat by its designation | Y | Y | Y | OK | `Game.apply_neon` (Game.gd:1024) sets `sub.neon = SUBSTAT[stat][neon.rank]`; probe: an R5 Speed neon on R6 gear adds +5; `compute_stats` adds `neon` (Game.gd:768); shown magenta with a diamond icon |
| 7 | Same-or-higher equipment rank only (R5 neon on R5/R6, not R4) | Y | Y | Y | OK | `Game.neon_can` (Game.gd:1014); probe: R5 on R4 is rejected, R6 on R5 is rejected, R5 on R6 is accepted |
| 8 | Can't go on equipment without that substat (primary doesn't count) | Y | Y | Y | OK | probe: a neon matching only the primary is rejected |
| 9 | Ranks 1-6 | Y | Y | Y | OK | `add_neon(rank)`; SW stage rank weights from `gdd.json syndicateWars` |
| 10 | Cover every substat except Crit Chance | Y | Y | Y | OK | `Data.NEON_STATS` has 10 stats and no `cc` |
| 11 | Neons drop from Syndicate Wars (only) | Y | partial | Y | WRONG (minor, held) | The only drop is SW (`Content.sw_rewards`, Content.gd:366). But `Game.grant_starter_kit` (Game.gd:105-106) gives every new account 8 R2-3 neons. Round 1 HELD this (FIXES "09:P3-1"), and it is still not recorded in `GDD_COVERAGE.md`. The Trinium "Neon Pack"/"Massive Neon Pack" and the Battle Pass "Set of Rank N Neons" rows also grant neons, but those come from the GDD's own tables, so the conflict is inside the GDD. Black Market, caches, Plaza, hideouts and campaign give none (probe and grep) |
| 11b | One neon per substat | Y | Y | Y | DEVIATION (undocumented) | `neon_can` blocks a second neon on the same substat. The GDD doesn't say this. It's reasonable, but it should go in GDD_COVERAGE |
| 11c | Neon apply UI explains the legality rule | - | - | partial | PARTIAL | Armoury Upgrade shows "NO FITTING NEON" plus the rule (warlord.gd:551-552). The Inventory item popup **hides** the Apply Neon button when no neon fits (item_view.gd:71-75) and gives no reason. Neither screen says *why* an owned neon doesn't fit (rank too high / no matching substat / already grafted) |

### Equipment leveling
| # | GDD item | St | Ru | Sh | Status | Evidence / note |
|---|---|---|---|---|---|---|
| 12 | Primary stat rises every level | Y | Y | Y | OK | `Data.primary_value`, +15%/level (`PRIMARY_GROWTH` is an open lever) |
| 13 | Credits level equipment from 0 to 20 | Y | Y | Y | OK | `Game.equip_level_up` (Game.gd:875); the probe confirms the cap at 20 |
| 14 | A substat is added or raised every 5 levels | Y | Y | Y | OK | probe: Common subs at +5/10/15/20 = 1/2/3/4; Legendary gets 4 rolls. "Next substat at +N" is shown in both views |
| 15 | Level-up cost shown | Y | Y | Y | OK | ItemView "Level Up (X ¢)"; Armoury shows the current cost plus "TO +N: X ¢". ItemView "Level x5" shows no total (P3) |
| 16 | Equipment rank 1-6, fixed once acquired | Y | Y | Y | OK | nothing writes `it.rank` after `make_equipment` |
| 17 | Starting substats by rarity: Common 0, Uncommon 1, Rare 2, Epic 3, Legendary 4 | Y | Y | Y | OK | `Data.SUBS_BY_RARITY`; the probe confirms them |
| 18 | Cost curve | - | - | - | lever | the GDD gives no table; `EQUIP_LEVEL_COST` (R1 0->1 300, R6 19->20 232,550) |

### Primary / substat matrix (one row per slot, N/A cells included)
| # | Slot | Status | Evidence |
|---|---|---|---|
| 19 | Weapon: primaries HP, HP%, ARM, ARM%, FP, FP%, CC, CD; SPD/HACK/FW sub only | OK | `Data.gd:95`; probe |
| 20 | Helmet: primary ARM only | OK | probe |
| 21 | Chest: primaries HP, HP%, ARM, ARM%, FP, FP%, HACK, FW | OK | probe |
| 22 | Gloves: primary FP only (the round-1 fix is in) | OK | probe |
| 23 | Legs: primary HP only | OK | probe |
| 24 | Boots: primaries HP, HP%, ARM, ARM%, FP, FP%, SPD | OK | probe |
| 25 | Limbs: primaries HP, ARM, FP, HACK; Crit Chance N/A | OK | probe: no CC ever rolls |
| 26 | Organs: primaries HP, ARM, FP, CD; Speed and Crit Chance N/A | OK | probe |
| 27 | Skeleton: primaries HP, ARM, FP, FW; Crit Chance N/A | OK | probe |
| 28 | "Primary Sub" cells on single-primary slots (Helmet ARM, Gloves FP, Legs HP) as substats | PARTIAL / note | `_add_sub` never repeats the primary (RAID rule), and these slots always have that primary, so ARM can never be a helmet sub, FP a glove sub, or HP a legs sub. This is how RAID works, but it is not literally the GDD cell. Recommend recording it as a deliberate rule in GDD_COVERAGE (no code change) |

### Values
| # | Item | Status | Evidence |
|---|---|---|---|
| 29 | Primaries table R1-R6, all 11 rows | OK | `Data.PRIMARY`, cell by cell; probe: primary_value at +0 = table |
| 30 | Substats table R1-R6, all 11 rows | OK | `Data.SUBSTAT`, cell by cell |

### Sets (Data.SETS, Game.compute_stats, Battle.gd); every row re-probed
| # | Set (pieces) | Status | Evidence |
|---|---|---|---|
| 31 | HP +20% base HP (2) | OK | probe: +213 on base 1065 (named "Health" in code) |
| 32 | Armour +20% base (2) | OK | probe: +12 on 62 |
| 33 | Firepower +20% base (2) | OK | probe: +13 on 66 |
| 34 | Speed +10% base (2) | OK | probe: +9 on 92 (`spdP`) |
| 35 | Hacking +20 (2) | OK | probe |
| 36 | Firewall +20 (2) | OK | probe |
| 37 | Critical Chance +15% (2) | OK | probe |
| 38 | Critical Damage +30% (2) | OK | probe; 2-piece sets stack per pair (RAID) |
| 39 | Energy Drain: heal 30% of damage dealt (4) | OK | probe: exactly 30.0% (Battle.gd:623) |
| 40 | Pain Mirror: reflect 30% to the attacker (4) | OK | probe: 30.0% (Battle.gd:643) |
| 41 | Jamming: block debuffs for 2 turns (4) | OK | probe: blockDebuffs 2 turns at round start, every wave now (round-1 P3-8 fixed, Battle.gd:190) |
| 42 | Strike Back: 50% counter (4) | OK | probe: 51% |
| 43 | Plague 40% Poison (4) | OK | probe: 42% (the base attack adds a little); still subject to the literal Hacking >= Firewall check (user decision) |
| 44 | Sanguine 40% Bleed (4) | OK | probe: 42% |
| 45 | Discharge 30% Shock (4) | OK | probe: 31% |
| 46 | Truma/Trauma 20% Stun (4) | OK | probe: 24%; typo fixed to "Trauma" |
| 47 | Safeguard: 3-turn overshield of 30% of the wearer's HP on the team at round start (4) | OK | probe: all 3 allies get 788 = 30% for 3 turns |
| 48 | Goad 20% Enraged (4) | OK | probe: 24% |
| 49 | Stitcher: heal each ally 10% of this warlord's HP (4) | OK | probe: 263 = 10%; fires every turn of the wearer (open lever, GDD gives no frequency) |
| 50 | Ripper: ignore 25% of armour (4) | OK | Battle.gd:597; probe dmg 295 -> 302 against low armour |
| 51 | Set bonus display: active/inactive, piece count | PARTIAL | `warlord._stats_panel` (warlord.gd:359-371) lists **only active** sets (`times > 0`, at most 3). A 1/2 Speed or 3/4 Plague set is never shown. The gear modal and ItemView show "SET BONUS (4): desc" but not how many pieces this warlord wears ("2/4") or whether it's active. The item tooltip is the same |

### Drop locations (every one checked)
| # | Item | Status | Evidence |
|---|---|---|---|
| 52 | Campaign den 1-9 sets: HP, Armour, FP, Speed, Stitcher, Hacking, Firewall, CC, CD; den 10 rotates daily | OK | `gdd.json campaign[].set` + `Content.campaign_set` (Content.gd:133); `corpo_tower_set` rotates daily through all 20 sets |
| 53 | Vultures: HP, CD, Pain Mirror, Plague, Discharge | OK | `Data.HIDEOUT_SETS` (Data.gd:152); `hideout_rewards` (Content.gd:300) |
| 54 | Teratek: Armour, Hacking, Energy Drain, Safeguard, Stitcher | OK | same |
| 55 | Cardinal Trolls: FP, CC, Strike Back, Goad, Ripper | OK | same |
| 56 | Quantum Vikings: Speed, Firewall, Jamming, Sanguine, Trauma | OK | same |
| 57 | Drop locations shown to the player | PARTIAL | the hideouts and campaign screens are owned by other audits; the set item card and ItemView show no "drops in: Den N / Hideout X" line, so a player can't look up where to farm a set |

### Acquisition and selling
| # | Item | Status | Evidence |
|---|---|---|---|
| 58 | Hideouts are the main source, each with a different selection | OK | gear hideouts roll from their 5 sets; the Chopshop gives implants |
| 59 | Campaign drops selected sets at lower quality and rank | OK | `Data.CAMPAIGN_EQUIP`: Street Punk R1-3 up to Rare; Warlord R4-6 with 10% R6 and 5% legendary, against hideout stage 20 at 35% R6 and 30% legendary |
| 60 | Shops sell for Credits (Plaza) and premium (Trinium Equipment/Implant Pack); PvP rank rewards | OK | Plaza pool (Data.gd:384-396); probe: Trinium "Full Set of R6 Legendary Equipment/Implants" parse to gearSet/implantSet; Black Market R4-6 Epic gear and implants; an Exalted Cache (Pit tier reward) gives 6 gear |
| 61 | Selling equipment (and neons, implants) for credits | OK | `sell_equipment`, `sell_neon`; ItemView Sell with confirm, locked items refused, Inventory bulk sell Common/Uncommon. Sale value is an open lever. P3: the confirm doesn't warn that the item is equipped, and the Armoury gear modal has no Sell button |
| 62 | Filters/sort by slot/set/rank/rarity | PARTIAL | Inventory: slot tabs only, with a fixed rank>rarity>level sort; no set, rarity or rank filter and no sort choice (inventory.gd:30-37). Armoury drawer: Set/Stat/Slot filters (one click per option; there are 20 sets) plus Rank/Level/Rarity **sorts**, but no rarity or rank *filter* (warlord.gd:227-256, 1196-1220) |

## 2. Fix list

**P1** - none.

**P2**
1. **Set progress display.** `scripts/ui/screens/warlord.gd` `_stats_panel()`: list every set with at least 1 piece worn, not only `times > 0`. Show "NAME n/pieces" in green when active and dim when not (keep the 3-slot art and put the rest in the hit tooltip). In `_gear_modal()` change "SET BONUS (%d):" to "SET BONUS %d/%d:" using `Game.compute_stats(w).sets.get(it.set, 0)` and grey it out when inactive. In `scripts/ui/item_view.gd` `open()`, when `it.owner != ""`, add the owner's piece count the same way.
2. **Inventory filters and sort.** `scripts/ui/screens/inventory.gd` `_equip()`: add a Set dropdown (`OptionButton` over `Data.SETS.keys()`), a rarity chip row (like `armory.gd`), and a sort tab (Rank / Rarity / Level / Set) stored in `params`. Apply them in the existing `filter` and `sort_custom`.
3. **Neon legality in the item popup.** `scripts/ui/item_view.gd` `open()`: when `Game.S.neons` isn't empty but nothing fits, show a disabled "Apply Neon" with a dim line built from `Game.neon_can` on the closest neon ("Needs a Rank <= %d neon with a matching substat"). Also show the rule line when there are no neons at all ("Win Neons in Syndicate Wars").
4. **Implant Rep requirement on item views.** `scripts/ui/item_view.gd` `open()` and `scripts/ui/ui.gd` `item_tooltip()`: for `it.kind == "implant"`, add "Slot unlocks at Reputation %d" from `Data.IMPLANT_UNLOCK[it.slot]`. In `warlord.gd _gear_modal()`, when `w.rep < IMPLANT_UNLOCK[it.slot]`, replace "IF EQUIPPED" with "NEEDS REP %d".

**P3**
5. **Starter Neons (row 11).** Ask the user. Either delete `for i in 8: add_neon(U.ri(2, 3))` in `Game.grant_starter_kit` (Game.gd:105-106), or have the coordinator record it in GDD_COVERAGE as an onboarding deviation, together with the GDD's own Trinium and Battle Pass neon rows.
6. **Set drop source line.** `item_view.gd` / `ui.gd item_tooltip`: add "Drops: Campaign Den N, Hideout X" from `Data.HIDEOUT_SETS` and `gdd.json campaign[].set` (rows 52-57).
7. **Sell flow.** `item_view.gd`: when the item is equipped, say so in the confirm text ("Sell %s? It is equipped on %s."). Optionally add Sell to the Armoury gear modal.
8. **ItemView "Level x5"**: show the total cost (sum of `Data.equip_level_cost` over the next 5 levels) in the label.
9. **Armoury Set filter**: the cycling button needs up to 20 clicks; a popup list of sets would be quicker (`warlord.gd _filter`).

**GDD_COVERAGE lines to add (coordinator):** "One neon per substat"; "A substat never repeats the primary (RAID rule), so Helmet ARM / Gloves FP / Legs HP never roll as subs on those slots"; "Stitcher heals every turn of the wearer"; the starter-neons decision.

## Applied (fix owner B)
- P2 1: warlord.gd `_stats_panel` lists every set with a piece worn ("NAME n/p", green active / dim inactive, extras in the 3rd slot tooltip); `_gear_modal` shows "SET BONUS n/p" (with "IF EQUIPPED" count for unequipped pieces), greyed when inactive; ItemView shows the owner's "Set worn n/p - ACTIVE xN / inactive".
- P2 2: inventory.gd `_equip`: rarity chips, Rank and Set dropdowns, sort tabs Rank / Rarity / Level / Set (all in `params`).
- P2 3: ItemView shows a disabled "Apply Neon" plus a reason line (no neons -> "Win Neons in Syndicate Wars"; every sub has a neon; needs Rank <= N neon matching a free substat; owned matching neons too high rank).
- P2 4: ItemView + `UI.item_tooltip` show "<Slot> slot unlocks at Reputation N" for implants (red when the owner is below it); gear modal shows "NEEDS REP N" instead of IF EQUIPPED when locked.
- P3 6 (`UI.set_sources`: "Drops: Campaign N <loc>, <X> Hideout"), P3 7 (sell confirm names the wearer), P3 8 ("Level xN (cost)"), P3 9 (Armoury Set filter is a popup list). P3 5 is held (starter neons).
