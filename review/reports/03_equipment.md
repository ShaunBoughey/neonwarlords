# Review 03: Warlord Equipment (Gear, Implants, Neons, Leveling, Sets, Acquisition)

Reviewer session: GDD section 03. Source: `review/gdd/03_equipment.txt`. The slot/stat matrix was re-read from the .docx table directly, because the .txt flattens the merged "Primary/Sub" cells.
Probe and screenshot script: `tests/review/03/Shots03.tscn` (`shots03.gd`), run with `NW_SAVE=03`, 0 SCRIPT ERRORs.
Screenshots: `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_03\` (written below as `shots_03/...`).

**Totals (46 rows): 45 OK, 0 MISSING, 1 WRONG, 0 DEVIATION.** There are also 3 open levers, which are notes and not bugs.

## 1. GDD items vs code

### Gear and Implants
| # | GDD item | Status | Evidence |
|---|---|---|---|
| 1 | 6 gear slots: Weapon, Boots, Legs, Chest, Helmet, Gloves | OK | `Data.gd:40` GEAR_SLOTS |
| 2 | Gear usable at any warlord level | OK | `Game.equip_on` (Game.gd:859) has no level gate |
| 3 | 3 implant slots: Limbs, Organs, Skeleton | OK | `Data.gd:41` |
| 4 | Implants unlock at Reputation 2 / 4 / 6 | OK | `Data.gd:72` IMPLANT_UNLOCK; enforced in `equip_on`, `auto_equip`, `warlord._select_slot`; the slot shows "REP n" while locked |

### Primary / substat matrix (docx table "Equipment Piece")
| # | Slot | Status | Evidence |
|---|---|---|---|
| 5 | Weapon: primaries HP, HP%, ARM, ARM%, FP, FP%, CC, CD; SPD/HACK/FW sub only | OK | `Data.gd:95` |
| 6 | Helmet: primary Armour only | OK | `Data.gd:96` |
| 7 | Chest: primaries HP, HP%, ARM, ARM%, FP, FP%, HACK, FW | OK | `Data.gd:97` |
| 8 | **Gloves: primary Firepower only** (Crit Chance and Crit Damage are "Sub" for Gloves) | **WRONG** | `Data.gd:98`: GDD says gloves can only have an FP primary; the code also allows `cc` and `cd`. Seen in game: `shots_03/11_upgrade_no_neon.png` shows "Common / Gloves, PRIMARY: CRIT CHANCE +1%" |
| 9 | Legs: primary Health only | OK | `Data.gd:99` |
| 10 | Boots: primaries HP, HP%, ARM, ARM%, FP, FP%, SPD | OK | `Data.gd:100` |
| 11 | Limbs: primaries HP, ARM, FP, HACK; no Crit Chance | OK | `Data.gd:101` |
| 12 | Organs: primaries HP, ARM, FP, CD; no Speed and no Crit Chance | OK | `Data.gd:102` |
| 13 | Skeleton: primaries HP, ARM, FP, FW; no Crit Chance | OK | `Data.gd:103` |
| 14 | A substat never repeats the primary or another substat | OK | `Game._add_sub` (Game.gd:790); probe: 540 legendary pieces, 0 duplicates |

### Value tables
| # | GDD item | Status | Evidence |
|---|---|---|---|
| 15 | Primaries table R1-R6 (HP 250..600, % stats 1/2/4/6/8/10, ARM/FP 6..35, HACK/FW 1..17, SPD 1..6) | OK | `Data.gd:105-109`, every cell matches |
| 16 | Substats table R1-R6 (HP 75..500, % 1/2/3/5/7/10, ARM/FP/HACK/FW 10..30, SPD 1..6) | OK | `Data.gd:110-114`, every cell matches |

### Equipment leveling
| # | GDD item | Status | Evidence |
|---|---|---|---|
| 17 | Credits level equipment from 0 to 20 | OK | `Game.equip_level_up` (Game.gd:811), `MAX_EQUIP_LEVEL` 20 |
| 18 | Primary stat increases with each level | OK | `Data.primary_value`: +15%/level (`PRIMARY_GROWTH`, an open lever; R6 HP 600 becomes 2400 at +20) |
| 19 | A substat is awarded or increased every 5 levels | OK | Probe: common helmet gains subs at +5/10/15/20 (0→4); a legendary piece gets 4 rolls, each adding the full SUBSTAT[rank] value |
| 20 | Starting substats by rarity: Common 0, Uncommon 1, Rare 2, Epic 3, Legendary 4 | OK | `Data.SUBS_BY_RARITY`; probe confirmed 0/1/2/3/4 |
| 21 | Rank 1-6 is fixed at acquisition | OK | Nothing writes `it.rank` after `make_equipment` |
| 22 | Leveling cost table / success chance | OK | The GDD gives no cost or success table. The code always succeeds (consistent with the GDD); cost is `EQUIP_LEVEL_COST[rank] * (lv+1)^1.5`, an open lever. 0→20 totals: R1 228K, R3 609K, R6 1.98M credits |

### Neons
| # | GDD item | Status | Evidence |
|---|---|---|---|
| 23 | Neons improve a matching substat by their designation | OK | `Game.apply_neon` adds `SUBSTAT[stat][neon.rank]`; stats pick it up in `compute_stats` (Game.gd:704). Seen in game: FP +30 → +42 with an R2 neon (`10_neon_grafted.png`) |
| 24 | Neons fit only equipment of the same or higher rank | OK | `Game.neon_can`; probe: an R5 neon on R4 gear is rejected, R4 on R4 is accepted |
| 25 | Cannot be applied without a matching substat | OK | `Game.neon_can` returns "Equipment has no X substat" |
| 26 | Neon ranks 1-6 | OK | `add_neon(rank)`; SW grants by stage rank (Content.gd:297) |
| 27 | Cover all substats except Crit Chance | OK | `Data.NEON_STATS` has no `cc` (probe) |
| 28 | Drop from Syndicate Wars | OK | Content.gd:297. Other sources are GDD reward rows ("Set of Rank N Neons" packs), the starter kit and the dev kit |
| 29 | One neon per substat | OK | GDD is silent; the code blocks a second neon on the same substat. Reasonable |

### Equipment sets (Data.SETS, Game.compute_stats, Battle.gd)
| # | Set | Status | Evidence |
|---|---|---|---|
| 30 | HP: +20% base HP, 2 pieces | OK | probe: base 1065 → +213 |
| 31 | Armour: +20% base ARM, 2 pieces | OK | probe |
| 32 | Firepower: +20% base FP, 2 pieces | OK | probe |
| 33 | Speed: +10% base SPD, 2 pieces | OK | probe: 92 → +9 |
| 34 | Hacking +20, Firewall +20, Crit Chance +15%, Crit Damage +30% (2 pieces each) | OK | probe: exact flat adds; 2-piece sets stack per activation (RAID-style) |
| 35 | Energy Drain: heal 30% of damage dealt (4) | OK | Battle.gd:606 |
| 36 | Pain Mirror: reflect 30% to the attacker (4) | OK | Battle.gd:626 |
| 37 | Jamming: block debuffs for 2 turns (4) | OK | Battle.gd:182 applies blockDebuffs for 2 turns at round start (see P3-4) |
| 38 | Strike Back: 50% counter (4) | OK | Battle.gd:632 |
| 39 | Plague 40% Poison, Sanguine 40% Bleed, Discharge 30% Shock, Trauma 20% Stun ("Truma" typo fixed), Goad 20% Enraged (4) | OK | Battle.gd:612-615 (on hit; still subject to the hacking vs firewall check) |
| 40 | Safeguard: 3-turn overshield of 30% of this warlord's HP on the team at round start (4) | OK | Battle.gd:184 |
| 41 | Stitcher: heal each ally 10% of this warlord's HP (4) | OK | Battle.gd:368. The GDD gives no frequency; the code heals every turn of the wearer (open lever) |
| 42 | Ripper: ignore 25% Armour (4) | OK | Battle.gd:580 |

### Acquisition and drop locations
| # | GDD item | Status | Evidence |
|---|---|---|---|
| 43 | Hideout sets: Vultures (HP, CD, Pain Mirror, Plague, Discharge), Teratek (Armour, Hacking, Energy Drain, Safeguard, Stitcher), Trolls (FP, CC, Strike Back, Goad, Ripper), Vikings (Speed, Firewall, Jamming, Sanguine, Trauma) | OK | `Data.HIDEOUT_SETS`; `Content.hideout_rewards` |
| 44 | Campaign dens 1-9: HP, Armour, FP, Speed, Stitcher, Hacking, Firewall, CC, CD | OK | `gdd.json campaign[].set` + `Content.campaign_set`; den 10 rotates daily |
| 45 | Campaign drops are lower quality and rank | OK | `Data.CAMPAIGN_EQUIP` (Normal R1-3, max Rare) |
| 46 | Shops sell gear for credits and premium; PvP rank rewards | OK | Plaza / Black Market / Pit caches (GDD_COVERAGE "Verified (Playthrough)"); not re-run here |

## 2. Visual issues

The Armoury layout is kept as is, so only broken things are listed for it.

| # | Issue | Screenshot |
|---|---|---|
| V1 | **Upgrade > Neon panel: the neon title wraps and overprints the next line.** "R2 FIREPOWER NEON" wraps to 2 lines at 18px/220px, so "NEON" is drawn on top of "CURRENT FP ON GEAR:" and becomes unreadable. Happens for every long stat name (Firepower, Firewall, Crit Damage, Armour %...). | `shots_03/05_upgrade_before.png`, `07_upgrade_max.png`, `08_upgrade_drawer.png` |
| V2 | **Item popup (Inventory > tap a piece) uses a text glyph as the item icon.** `Data.SLOT_ICON` "▙" renders as a solid yellow L-block, not the slot art; the rest of the UI uses `Art.SLOT_BUTTON`. | `shots_03/16_item_view.png` |
| V3 | **Inventory > Gear: the slot tabs are cut off and can't be reached.** Only ALL / WEAPON / HELMET / "C..." are visible. The tab strip is a ScrollContainer with `SCROLL_MODE_SHOW_NEVER` that shares the row with the expanding spacer and the Sell button, so CHEST / GLOVES / LEGS / BOOTS can't be clicked with a mouse. | `shots_03/12_inventory.png` |
| V4 | Inventory item cards clip long set names on both sides ("ritical Damag"). | `shots_03/12_inventory.png` |
| V5 | Gear modal: "IF EQUIPPED: ..." is drawn below the modal art, over the 3D scene, and wraps to 2 lines in red. It is readable but sits outside the panel. | `shots_03/11_upgrade_no_neon.png` |
| V6 | Neon progress bar fills by `grafted / 4.0`, but the label says `grafted / subs.size()`. With 0 subs the label reads "0 / 0". | `shots_03/11_upgrade_no_neon.png` |
| V7 | Implants page hint "IMPLANT SLOTS UNLOCK AT REPUTATION 2 / 4 / 6" wraps the final "6" onto a second line. | `shots_03/04_implant_modal.png` |
| V8 | Dingbat glyphs used as markers: "✦" after neon-boosted substats (gear modal and item popup) and "●"/"◐" owner dots. They render, and they aren't emoji, but they aren't stroke icons either. | `10_neon_grafted.png`, `16_item_view.png` |

Buttons checked and working: slot select, Equip / Unequip, Upgrade (modal → page), Upgrade Once, Upgrade To with 5/10/15/20 (MAX state shown), the equipment drawer and its close button, the neon slot (cycles fitting neons, "1 / 12 FITTING"), Graft Neon, Auto Equip, Unequip All, Inventory Gear / Implants / Neons tabs, neon Sell, item popup Apply Neon / Lock / Unequip / Sell. The Neons inventory list looks clean (`14_inventory_neons.png`).

## 3. Prioritised fix list

**P1**
1. **Gloves primaries (WRONG #8).** `scripts/core/Data.gd:98` `SLOT_STATS.gloves.pri`: change `["fp", "cc", "cd"]` to `["fp"]`. Existing saved gloves with CC/CD primaries can stay (no migration needed), or optionally reroll them in the save loader.

**P2**
2. **V1 neon title overlap.** `scripts/ui/screens/warlord.gd` `_page_upgrade()`: in the neon title `_lbl("R%d %s NEON" ...)`, use `Data.STATS[ne.stat].short` instead of `.name` (e.g. "R2 FP NEON"), or pass `wrap=false` at font 15. Either keeps it to one line above "CURRENT ... ON GEAR".
3. **V3 inventory slot tabs unreachable.** `scripts/ui/screens/inventory.gd` `_equip()`: put the tabs on their own row (add `tabs(...)` straight to `root`, and the Sell button in a second `hb` below or right-aligned). Or, in `scripts/ui/screen.gd` `tabs()`, only wrap in a ScrollContainer when the names really don't fit. With 7 tabs at 13px the strip needs about 560px and fits on a full-width row.
4. **V2 item popup icon.** `scripts/ui/item_view.gd` `open()` line 9: replace `UI.lbl(Data.SLOT_ICON[it.slot], 48, col)` with `Art.icon(Art.SLOT_BUTTON[it.slot], Vector2(64, 78))` inside an `Art.rect(Art.equip_border(it.rarity), ...)` frame, matching the Armoury cards.

**P3**
5. **V4** `scripts/ui/ui.gd` `item_card()`: give the set label a fixed width (`custom_minimum_size.x = 88`) and use `text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS` instead of a centred clip, or abbreviate "Critical" to "Crit".
6. **V6** `warlord.gd` `_page_upgrade()`: use `grafted / float(max(1, it.subs.size()))` for the bar so it agrees with the label, and hide the bar and label when `subs.size() == 0`.
7. **V5** `warlord.gd` `_gear_modal()`: move the "IF EQUIPPED" label to `Vector2(165, 196)` at 13px with `wrap=false` so it sits inside the modal art.
8. **Jamming on later waves** `scripts/combat/Battle.gd` `_round_start_effects()`: Jamming sits inside `if first or u.side == 1`, so player warlords only get it on wave 1 (Safeguard fires every wave). If Jamming is meant to apply each round, move it next to the Safeguard block.
9. **V7** `warlord.gd` `_page_slots()`: widen the hint label (504 → 560) or shorten it to "IMPLANTS UNLOCK AT REP 2 / 4 / 6".
10. **V8**: replace the "✦" text markers with `Icon.make("diamond", UI.MAGENTA, 12)` and the owner dots with a small stroke icon, to follow the stroke-icon rule.

## Open levers (GDD leaves these unspecified; not bugs)
- `Data.EQUIP_LEVEL_COST` / `equip_level_cost` curve (R6 piece 0→20 ≈ 1.98M credits).
- `Data.PRIMARY_GROWTH` 0.15 per level (×4 at +20).
- Stitcher trigger frequency (currently every turn of the wearer).
