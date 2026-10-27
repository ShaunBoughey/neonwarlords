# Audit 04 - Win/Lose screens, City Centre, Campaign, Level Design, UI flow chart

GDD: `review/gdd/00_full_gdd.txt` 445-664, 2231-2239, `review/gdd/flowchart.png`.
Probe: `tests/audit/04/probe.gd` (headless, `NW_SAVE=audit04`). Table check: a script diffed every row of the
Campaign Reward Table and the Campaign Enemy Warlord Levels table in the GDD text against `data/gdd.json`. **0 mismatches**
(70 stages x 3 difficulties x {XP, credits, slot, level, rank, rep}). Every stage builds with the right energy cost and enemy level (probe `ENERGY_BAD 0`, no level mismatch).

Note: the brief names `scripts/ui/screens/district_map.gd`. That file does not exist. The den map is `scripts/ui/district_diorama.gd` (`DistrictDiorama`), used by `campaign.gd`.

## 1. Item table

| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| **Winning screen** shows XP gained and other rewards | y | y | y | OK | `battle.gd:_finish` 753+ |
| Win: Content Name | y | y | y | OK | sub-line `enc.title` ("Slums 1-1"), battle.gd ~806 |
| Win: Content Difficulty | y | y | y | OK | `enc.subtitle` = `Data.DIFFS[d]` (Content.gd:112) |
| Win: Stage Number | y | y | y | OK | in title "%s %d-%d" |
| Win: Victory Header | - | - | y | OK | "VICTORY" |
| Win: Player XP Gained | y | y | y | OK | loot tray "Player XP +n" (= energy spent, Game.spend -> add_pxp, Game.gd:324) |
| Win: Item Rewards/Drops | y | y | y | OK | loot tray reward tiles, incl. credits |
| Win: Warlords Used | y | y | y | OK | `_result_card` per `contrib` |
| Win: Contributions (Dmg Dealt / Taken / Healed) | y | y | y | OK | DMG / TAKEN / HEALED on each card |
| Win: Warlord XP Gained | y | y | y | OK | "+n XP" per card plus level-up flag |
| Win: Back to Upper Menu | - | y | y | OK | "STAGE MAP" -> `main.back()` pops to campaign |
| Win: Continue To Next Stage | - | y | y | OK | `Content.next_enc` -> NEXT STAGE (only when unlocked, only on win) |
| Win: Replay | - | y | y | OK | REPLAY CTA with cost badge |
| **Losing screen**: 20% of the win XP | y | partial | y | PARTIAL | Warlord XP is 20% (Content.gd:146; probe LOSE xp 600/1600/2600). Player XP on a loss is still 100% of the energy spent (`finish` pxp = energy cost). GDD says the losing screen gives "20% of the amount of XP you would get from winning". |
| Lose: Content Name / Difficulty / Stage / Defeat header | y | y | y | OK | same sub-line, "DEFEAT" |
| Lose: Player XP, Warlords Used, Contributions, Warlord XP | y | y | y | OK | same cards and tray |
| Lose: Back + Replay (no Next) | - | y | y | OK | NEXT gated on `won` |
| **City Centre** is the hub every menu sprouts from | - | y | y | OK | `city.gd`; `main.back()` with an empty stack goes to city |
| Flow: Player Start -> Login Screen | - | y | y | OK | `login.gd` |
| Flow: Login -> Tutorial (dashed, optional) | y | y | y | OK | coach FTUE (`coach.gd`, `S.tutorial_done`/`ftue`); replayable in Settings |
| Flow: Login -> City Centre | - | y | y | OK | `login.gd:_enter` -> `main.home()` |
| Flow: City -> Shop | - | y | y | OK | bottom nav + energy/trinium HUD pills |
| Flow: City -> Settings | - | y | y | OK | city signboard |
| Flow: City -> Inbox/Friends | - | y | y | OK | city rail "Inbox"; `inbox.gd` has Inbox/Friends tabs |
| Flow: City -> Account | - | y | y | OK | HUD player-level button -> `account` (Main.gd:363) |
| Flow: City -> Clans | - | y | y | OK | bottom nav "Gang" |
| Flow: City -> Events | - | y | y | OK | city rail |
| Flow: City -> Login Rewards | - | y | y | OK | city rail "Daily login" |
| Flow: City -> Missions | - | y | y | OK | city rail |
| Flow: City -> Inventory | - | y | y | OK | city signboard |
| Flow: City -> Recruitment Office | - | y | y | OK | bottom nav "Recruit" |
| Flow: City -> Black Market | - | y | y | OK | city signboard |
| Flow: City -> **Tavern** | y | y | n | MISSING (UI entry) | See section 3. The Dojo (metabolics + feeding) exists as the per-warlord "Level" page (`warlord.gd:_page_from_tab` "Dojo" -> "level"), but no Tavern/Dojo entry exists on the City Centre. GDD_COVERAGE.md:49 says "not implemented". That note is out of date: the feature exists, but the flow-chart box is missing. |
| Flow: City -> Safe house | - | y | y | OK | city signboard |
| Flow: City <-> Fight | - | y | y | OK | BATTLE hex -> `fight.gd` |
| Flow: Fight <-> Campaign map | - | y | partial | PARTIAL | `fight.gd` card -> `campaign`. No 10-location campaign map exists. The screen opens on one den, and you move with the prev / DEN n+1 buttons only, so you cannot jump to a den directly. |
| Flow: Campaign area level selection (stages) | - | y | y | OK | `DistrictDiorama` 7 landmarks + stage sheet |
| Flow: level selection <-> Squad selection -> Fighting -> Result | - | y | y | OK | `start_encounter` -> squad -> `replace("battle")` -> `_finish` |
| Flow: Result <-> level selection | - | y | y | OK | STAGE MAP / REPLAY / NEXT STAGE |
| Flow: Fight <-> Hideout map -> level select 1-20 -> squad -> fight -> result | - | y | y | OK | `hideouts.gd` (stage picker 1-20) |
| Flow: Fight -> Syndicate Wars -> Syndicate Selection -> Stage Selection 1-20 -> squad -> fight -> result | - | y | y | OK | `syndicate_wars.gd:39` range(1,21), BATTLE at :250 |
| Flow: Fight -> Arena -> Opponent selection -> squad -> fight -> result | - | y | y | OK | `arena.gd:79` FIGHT per opponent |
| Campaign: 10 locations x 7 stages | y | y | y | OK | gdd.json `campaign` 10x7, names and sets match |
| 3 difficulties | y | y | y | OK | `Data.DIFFS`; difficulty tabs on the campaign screen |
| Reward table XP/credits per stage per difficulty (210 cells) | y | y | y | OK | probe diff 0 mismatches; Content.gd:142-147 |
| Sky Street Street Punk "Silver" header | y | y | y | OK | treated as Credits (GDD typo; only currency in the table); values 4600-5200 continue the credit curve |
| Stages reward credits + XP | y | y | y | OK | shown as XP/Credits tiles on the stage sheet |
| Chance to drop a warlord common-rare | y | y | y | OK | CAMPAIGN_DROPS; preview tiles with % |
| Equipment of the location's set | y | y | y | OK | `campaign_set`; "Gear: <set> set • <slot>" line |
| Slot per stage (Weapon..Boots, stage 7 Random Piece) | y | y | y | OK | Content.gd:162-163; shown as "any slot" on stage 7 |
| Corpo Tower set rotates daily | y | y | y | OK | `Game.corpo_tower_set` by `U.day_id()`, shown "(today)". It draws from all 20 sets, including the 4-piece effect sets. The GDD gives no list, so this is acceptable. |
| Additional drops table: kinds and chances | y | **wrong** | y | WRONG | Each GDD difficulty column sums to exactly 100% (15+5+75+5; 17.5+2.5+75+5; 15+5+75+5), so the GDD means one drop per win. `Content.campaign_rewards` (Content.gd:153-165) rolls every row independently. Probe, 3000 wins per difficulty: about 18% of wins drop nothing and about 17% drop 2-4 items. The Deeds hideouts already use "exactly one" for the same 100% pattern (GDD_COVERAGE.md:87), so the two rules are inconsistent. |
| Energy cost 4 / 6 / 8 | y | y | y | OK | `CAMPAIGN_ENERGY`; BATTLE CTA badge; probe ENERGY_BAD 0 |
| Drop preview (what can drop, %) | y | y | partial | OK (P3 note) | The equipment tile always has a "rare" border, but the actual rarity follows the CAMPAIGN_EQUIP weights |
| Each stage has requirements for 3 chevrons | y | y | y | OK | `Content.chevrons` (win / no warlord lost / within 12+st turns); "Chevron goals" list with filled chevrons per stage |
| Chevrons accumulate into progression rewards | y | y | y | OK | `campaign_total_stars(d)`; REWARDS button with claimable badge; den chevron bar x/21 |
| Campaign Progression Rewards table (14 thresholds x 3) | y | y | y | OK | all 42 cells parse correctly (probe PROG lines); claim grants once (probe CLAIM75 / again []) |
| Progression track visible and claimable | y | y | y | OK | `campaign.gd:_rewards` modal, x/210 bar, CLAIM / CLAIMED |
| Next difficulty opens after finishing | y | y | y | OK | `campaign_unlocked` needs (d-1, 9, 6); probe false -> true; locked tab says "Clear X first" |
| XP divided equally among the squad ("5 Warlords") | y | y | y | DEVIATION | split over `team.size()` (4 = team-size user decision); Content.gd:549-555 |
| Enemy level / rank / rep table | y | y | y | OK | probe and diff: 0 mismatches; enemy LV shown on enemy tiles |
| Enemies scale "in considerable difficulty" | y | y | y | DEVIATION | extra gear bonus and line-up rules (GDD_COVERAGE.md:65-66); the code matches the documented values (`CAMPAIGN_BONUS`, boss mult 1.3/1.0) |
| Level Design: look and feel per location (Slums images) | y | - | y | OK | template text only; per-den diorama tinted by syndicate colour |
| User Interface: flow chart | - | - | - | see flow rows | Every box is reachable except Tavern (missing) and the Campaign map (partial) |

**Counts:** OK 52, PARTIAL 2, WRONG 1, MISSING 1, DEVIATION 2.

## 2. Fix list

### P1
None. Every GDD number in this section matches the code, and the campaign loop works end to end.

### P2
1. **Campaign additional drops: exactly one drop per win.** In `scripts/core/Content.gd` `campaign_rewards`, replace the per-row `U.chance` loop with a single weighted pick over `Data.CAMPAIGN_DROPS[enc.d]`. For example, build `{i: dr[2]}` and use `U.weighted`, then grant only that row. This matches the deeds-hideout rule (GDD_COVERAGE "GDD rules enforced"). Add the rule to GDD_COVERAGE.
2. **Tavern box missing from the City Centre.** RAID's Tavern is where you feed champions to level them. That is the GDD's "Dojo" (Leveling Methods: metabolics, plus alignment bonus), and it already exists as `warlord.gd` page "level" (tab "Dojo"). In `scripts/ui/screens/city.gd` `build`, add a signboard: `_sign(right, "Tavern", "Level Warlords with Metabolics", UI.CYAN, func(): main.go("armory", {"pick_for": "Dojo"}))`. The `pick_for` param is new: `armory.gd` should open `warlord` with `{"tab": "Dojo"}` when a warlord is picked from that list. Also update GDD_COVERAGE.md:49, which wrongly says the Tavern has no GDD text and is not implemented.
3. **Losing screen gives full Player XP.** In `Content.finish`, return `pxp = int(energy * 0.2)` when the battle is lost, and award only that. To do this, `Game.spend` must stop auto-adding player XP for battles: move `add_pxp` for encounter energy into `finish`, with the full amount on a win and 20% on a loss. The `run.pxp` tally in `battle.gd` already reads `summary.pxp`.

### P3
4. **Campaign map overview.** In `scripts/ui/screens/campaign.gd`, add a "MAP" button next to the den nav that opens a modal grid of the 10 dens (name, chevrons x/21, locked state), each calling `_den(i)`. This matches the flow chart's "Campaign map" box before the area level selection.
5. **Equipment drop preview rarity.** In `campaign.gd` `_sheet`, base the `_art_tile` border and tooltip on `Data.CAMPAIGN_EQUIP[diff]` (show a rank/rarity range such as "R1-3 Common-Rare") instead of a fixed "rare".
6. **No hint after the last stage.** After the last stage (10-7) is won, `next_enc` returns {}. In `battle.gd _finish`, show a "<next difficulty> unlocked" line or a toast when `enc.loc == 9 and enc.st == 6` and the stage was cleared for the first time.


**Applied (owner C):** P2 1 - `Content.campaign_rewards` now makes one weighted pick over `Data.CAMPAIGN_DROPS[d]` (exactly one additional drop per win). GDD_COVERAGE note left to coordinator (not C-owned).

## Applied (owner D, screens)
- P2 2 Tavern signboard on City Centre opens the warlord Dojo (level) page (first squad warlord; prev/next on that page). Armoury left as is (user decision), so no pick_for param.
- P3 4 MAP button on campaign den nav: modal of 10 dens with chevrons x/21 and lock state.
- P3 5 equipment drop tile border = most likely rarity from Data.CAMPAIGN_EQUIP[diff]; tooltip lists rank and rarity odds.
- P3 6 stage sheet says "Clear Den 10 stage 7 to unlock <next>" / "Winning this stage unlocks <next>" (campaign.gd; battle.gd toast is owner A).
