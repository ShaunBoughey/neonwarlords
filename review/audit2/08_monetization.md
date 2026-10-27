# Audit 08 - Monetization (GDD lines 2093-2230)

Scope: Trinium Exchange (Packs, Trinium Vault, Credit Bank, Trinium Market), Subscriptions, Player Progress Double Rewards, Battle Pass (rules, challenges, 100-level reward track).

Probe: `tests/audit/08/probe.gd` (`probe.tscn`), run headless with `NW_SAVE=audit08`. It buys every shop row through `Game.shop_buy`, diffs the currencies, items, equipment, neons and roster, then repeats each limited row until refused. It also grants every non-empty battle-pass cell and checks the BP rules. Result: every shop row and all 155 BP cells parse with **0 unknown rewards**, and each grants the kind and amount its text names (details below).

Code paths: `Game.shop_buy` (Game.gd:1701), `Game.shop_limit_key` (1692), `Game.grant` (1081), `U.parse_one` / `U.parse_rewards` (U.gd:177 / 264), `shop.gd`, `battle_pass.gd`, `Game._check_bp` / `bp_*` (Game.gd:1747-1876), `Data.BP_*` (Data.gd:306-335), data in `data/gdd.json` `shop` (7152) and `battlePass` (7408).

## 1. Item table

### Trinium Exchange - intro and Packs (GBP; granted free while "Free IAP (dev)" is on, otherwise refused - offline stand-in)
| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| "Trinium Exchange is the in-game shop..." | yes | yes | yes | OK | shop.gd: rail Featured / Packs / Trinium Vault / Credit Bank / Trinium Market / Subscriptions |
| Small Rare Contracts Pack: 5 Rare, 125k, £4.99, limit 5 | yes | yes | yes | OK | probe: rare +5, credits +125000; refused after 5; card shows "n / 5" |
| Large Rare Contracts Pack: 15 Rare, 375k, £12.99, limit 3 | yes | yes | yes | OK | +15 rare, +375000; limit 3 |
| Small Epic Contract Pack: 1 Epic, 50k, £9.99, limit 5 | yes | yes | yes | OK | +1 epic, +50000; limit 5 |
| Medium Epic Contracts Pack: 3 Epic, 150k, £28.99, limit 3 | yes | yes | yes | OK | +3 epic, +150000; limit 3 |
| Large Epic Contract Pack: 10 Epic, 500k, £89.99, limit 1 | yes | yes | yes | OK | +10 epic, +500000; limit 1 |
| Small Legendary Contract Pack: 1 Leg, 100k, £19.99, limit 3 | yes | yes | yes | OK | +1 legendary, +100000; limit 3 |
| Large Legendary Contracts Pack: 3 Leg, 300k, £49.99, limit 1 | yes | yes | yes | OK | +3 legendary, +300000; limit 1 |
| Street Punk Pack: 1 Rare, 150k, 300 Trinium, 350 Energy, £4.99, limit 5 | yes | yes | yes | OK | all four grants match; limit 5 |
| Mob Boss Pack: 5 Rare, 1 Epic, 500k, 600 Tr, 700 En, £19.99, limit 2 | yes | yes | yes | OK | all match; limit 2 |
| Warlord Pack: 10 Rare, 2 Epic, 1 Leg, 1m, 1000 Tr, 1000 En, £49.99, limit 1 | yes | yes | yes | OK | U.gd:269 bundle split works; all match; Featured banner shows "Limit 0 / 1" |
| Scavenger Pack: 250 En, 150k, 1x Lvl3 Firmware, 1x 100% XP Boost, 5 Heist, £4.99, limit 5 | yes | yes | yes | OK | firmware.3 +1, xpBoost +1, heist +5 (allowed over the cap, as the user decided) |
| Vulture Pack: 500 En, 500k, 3x Lvl3 FW, 3x XP Boost, 5 Heist, £9.99, limit 2 | yes | yes | yes | OK | all match |
| Hunter Pack: 1000 En, 1m, 2x Lvl4 FW, 5x XP Boost, 5 Heist, £19.99, limit 1 | yes | yes | yes | OK | all match |
| Equipment Pack: Full Set of R6 Legendary Equipment, 500k, 200 En, £19.99, limit 5 | yes | yes | partial | OK | 6 gear pieces, all R6 legendary, one random set (Game.gd:1129). Label drops "Legendary" (U.gd:317 "Set of Rank 6 Equipment"), see P3 |
| Implant Pack: Full Set of R6 Legendary Implants, 300k, 150 En, £14.99, limit 5 | yes | yes | partial | OK | 3 implants (all implant slots), R6 legendary. Label also drops "Legendary" (U.gd:318) |
| Neon Pack: 12 Assorted R6 Neons, £4.99, limit 5 | yes | yes | yes | OK | 12 R6 neons, random stat each (Game.gd:1035) |
| Massive Neon Pack: 60 Assorted R6 Neons, £49.99, limit 1 | yes | yes | yes | OK | 60 R6 neons |

### Trinium Vault (GBP, no limit)
| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| Iota 660 Tr £4.99 | yes | yes | yes | OK | +660 |
| Bundle 1550 Tr £9.99 | yes | yes | yes | OK | +1550 |
| Consignment 3200 Tr £19.99 | yes | yes | yes | OK | +3200 |
| Cluster 4750 Tr £29.99 | yes | yes | yes | OK | +4750 |
| Plethora 8000 Tr £49.99 | yes | yes | yes | OK | +8000. The Stocks Vault cap card is an extra here (documented deviation) |

### Credit Bank (Trinium, no limit)
| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| Small Investment 100k for 60 Tr | yes | yes | yes | OK | trinium -60, credits +100000 |
| Medium 250k for 150 Tr | yes | yes | yes | OK | -150 / +250000 |
| Substantial 1.5m for 900 Tr | yes | yes | yes | OK | -900 / +1500000 |
| Exceptional 4m for 2000 Tr | yes | yes | yes | OK | -2000 / +4000000 |
| Masterful 10m for 5000 Tr | yes | yes | yes | OK | -5000 / +10000000 |

### Trinium Market (Trinium)
| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| Paragon Deeds 30 Minor / 20 Major / 10 Grand, 1200 Tr | yes | yes | yes | OK | Game.gd:1720 special case: paragon minor +30, major +20, grand +10 |
| Neutral Deeds same, 1200 Tr | yes | yes | yes | OK | as above |
| Renegade Deeds same, 1200 Tr | yes | yes | yes | OK | as above |
| Generic Deeds same, 1000 Tr | yes | yes | yes | OK | as above, -1000 |
| Energy Boost: 1x Energy, 60 Tr | yes | yes | yes | OK | grants 1 Energy Battery (+100 energy when used, Game.gd:370, Fight screen). Matches the build's "1x Energy" convention |
| Pit Brawl Refill: 10 invites, 100 Tr, limit 2 | yes | yes | **no** | PARTIAL (UI) | Game enforces 2 per day (key `...|d<day>`, Game.gd:1694). `shop.gd:_limit` (line 73) reads key `"%s|%d"` without the day suffix, so the card always shows "0 / 2" and the button is never disabled. Probe: Game count 2, UI key count 0 |
| Pit Royal Refill: 10 invites, 100 Tr, limit 2 | yes | yes | **no** | PARTIAL (UI) | same bug |
| 1 Day Boost: 1x 100% XP Boost, 100 Tr | yes | yes | yes | OK | xpBoost +1 (24h each, Game.gd:360) |
| 3 Day Boost: 3x 100% XP Boost, 250 Tr | yes | yes | yes | OK | xpBoost +3 |
| 3x Rare Contracts + 75k, 500 Tr | yes | yes | yes | OK | +3 rare, +75000 |
| 7x Rare Contracts + 175k, 1100 Tr | yes | yes | yes | OK | +7, +175000 |
| 15x Rare Contracts + 375k, 2200 Tr | yes | yes | yes | OK | +15, +375000 |
| Raid Boss Ticket: 1x, 300 Tr | yes | yes | partial | PARTIAL (UI) | maps to `cur.raidTicket`, which gives one extra Gang Bastion (raid boss) entry when the daily entries run out (Game.gd:1969-1984). Gang and Inventory screens show the count, but the shop card only says "1x Raid Boss Ticket". It never tells the player that the ticket buys an extra Bastion entry |
| Heist Plan: 5x, 1000 Tr | yes | yes | **wrong** | WRONG | `shop.gd:_buy_btn` lines 90-93 disables the button whenever the player holds any Heist Plan ("cap is 5, would waste Trinium"). The daily refresh is `max(heist, 5)` (Game.gd:264), and add_cur allows going over the cap (user decision: rewards and purchases may overflow). So the guard is out of date. With 5 plans refilled each day, the row can only be bought after spending all of them |

### Subscriptions / Double Rewards
| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| Subscriptions ("A Sub that gives you regular bonuses?") | - | - | - | DEVIATION | user decision: no subscriptions yet. The Shop "Subscriptions" tab only hosts Double Rewards plus a Battle Pass link |
| Player Progress Double Rewards: extra rewards on each player level | yes (`S.double_rewards`) | yes | yes | OK | Game.gd:411 doubles each level-up's rewards from purchase onward. The £9.99 price is not in the GDD (open lever) |

### Battle Pass - rules
| GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|
| Seasonal, 10 weeks + 2-week gap | yes | yes | yes | OK | Data.gd:334-335 (70 + 14 days), Game.gd:1747. The gap shows "next season starts in N days". A new season resets merits, premium and claims |
| Levels 1-100 | yes | yes | yes | OK | `bp_level` capped at 100 (Game.gd:1797); "Level n / 100" plus a MAX LEVEL state |
| Free and Premium tracks; free players get only free; premium gets both | yes | yes | yes | OK | `bp_claim` refuses paid cells without premium (probe). Track shows FREE / PREMIUM cells, LOCKED/CLAIM/CLAIMED, and Claim All |
| Premium £15 | yes | yes | yes | OK | battle_pass.gd:37 |
| Premium + 25 Levels £25: "boost straight to level 25" | yes | partial | partial | PARTIAL | Game.gd:1874 sets merits to max(merits, 500), so it only reaches level 25. A non-premium player already at level 25 or above still sees the £25 option and gets exactly what £15 gives (probe: level 30 before and after) |
| Extra "+25 LV £10" upgrade for premium owners | yes | yes | yes | DEVIATION (undocumented) | battle_pass.gd:33. The GDD lists only 3 price points, and this one is not in GDD_COVERAGE.md |
| Free £0 | - | yes | yes | OK | default |
| 20 Merits per level | yes | yes | yes | OK | Data.gd:333; the screen shows the merit bar |
| Daily x5, 15 merits each + 25 for full completion | yes | yes | yes | OK | Data.gd:329-330; Game.gd:1773 picks 5, bonus at 1823 |
| Weekly x4, 20 each + 20 full completion; a weekly set totals 100 merits | yes | yes | yes | OK | 4 x 20 + 20 = 100 (probe) |
| Challenges picked at random from the pools | yes | yes | yes | OK | seeded by day and week id (the same set for every player, fine offline) |
| Reset 1 weekly challenge per week | yes | yes | yes | OK | `bp_reroll_weekly`: the second reset is refused (probe). RESET button with tooltip |
| "each week during the season adds a set of Weekly challenges" | yes | partial | yes | PARTIAL | weeks follow calendar Mondays (`U.week_id`), but seasons start on a Thursday (epoch 20398). Week 1 is a 4-day stub and a season covers 11 weekly sets. Weekly progress outside a season is not counted (`track` checks season >= 0, which is fine) |

### Battle Pass - challenge pools
| GDD item | Status | Evidence / note |
|---|---|---|
| D: Kill 10 Warlords in the Pit | OK | `pitKill` from Content.gd:542 (enemy units dead) |
| D: Rank up Warlord to Rank 4+ | OK | `rankUp4` Game.gd:547 |
| D: Rank up an 'x' Warlord | PARTIAL | `rankAny`: any rank-up. The GDD's 'x' (rarity / syndicate / class placeholder) is not filled in, so the challenge is generic. Ask the user what x means |
| D: Level Equipment to 16 | OK | `equip16` Game.gd:889-891 |
| D: Level 3 Equipments to 12 | OK | `equip12` n=3 |
| D: Acquire 3 Equipment from Hideouts | OK | `hideoutEquip` per dropped piece, Content.gd:302 |
| D: Open 10 Contracts | OK | `recruit` in open_contract, Game.gd:1055 |
| D: Complete 10 Dens | WRONG | Content.gd:530 `Game.track("den", 1)` runs on losses too. The win check sits on the next line only for `campaign_record`. A lost den counts as "completed" (this also affects the daily Job "den" counter) |
| D: Complete 5 Hideouts | OK | Content.gd:336, after the `if not won: return` at 285 |
| D: Spend 100k Credits | OK | `spend()` tracks spendCredits, Game.gd:328 |
| W: Kill 25 in the Pit | OK | as daily |
| W: Rank up to Rank 5+ | OK | `rankUp5` Game.gd:550 |
| W: Rank up an 'x' Warlord | PARTIAL | `rankAnyW` n=1: the same placeholder issue, and a weekly that is trivial |
| W: Level 2 Equipment to 16 | OK | equip16 n=2 |
| W: Acquire 10 Equipment from Hideouts | OK | |
| W: Open 25 Contracts | OK | |
| W: Complete 50 Dens | WRONG | same loss-counting bug |
| W: Complete 25 Hideouts | OK | |
| W: Spend 500k Credits | OK | |

### Battle Pass - reward track (100 rows, 155 non-empty cells)
Every cell is granted by the probe. Mapping summary:
| GDD wording | Grants | Status |
|---|---|---|
| "Nx Rare/Epic/Legendary Contract" | contract.<r> +N | OK (all rows) |
| "NK / NM Credits" | credits exact | OK |
| "N Trinium" | trinium exact | OK |
| "Nx Energy" | N Energy Batteries | OK (same convention as the shop) |
| "Nx 100% XP Boost" | xpBoost +N | OK |
| "10% XP Boost" (L1, 20, 40, 60, 80 paid) | xpBoostMinor +1 (usable on the Fight screen, +10% for 24h) | OK |
| "Nx lvl N Firmware" | firmware.<lv> +N | OK |
| "2x Heist Plan" | heist +2 | OK |
| "Set of Rank N Equipment" | 6 gear pieces, rank N, one random set, random rarity (50/40/10 rare/epic/leg) | OK (GDD silent on rarity) |
| "Set of Rank N Implants" | 3 implants, rank N | OK |
| "Set of Rank N Neons" | 6 neons, rank N | OK (one per gear slot) |
| "Set Rare Warlord" (L25, L75 free), "Set Epic Warlord" (L50 free), "Set Legendary Warlord" (L100 free) | 1 random warlord of that rarity, shown as "1x Rare Warlord" | PARTIAL: "Set" (like "Specified Warlord" elsewhere in the GDD) reads as a fixed, pre-chosen season warlord, the way RAID passes work. The code picks at random and the track cannot show which warlord it is. Ask the user |

Row-by-row: rows 1-24, 26-49, 51-74 and 76-99 (both tracks) and row 100 paid are OK. Rows 25, 50, 75 and 100 have their paid cells OK and their free cells PARTIAL (listed above).

## Counts
- OK: 159 (intro + 37 shop rows, Double Rewards, 10 BP rules, 14 challenges, 96 reward rows)
- PARTIAL: 11 (Pit Brawl Refill, Pit Royal Refill, Raid Boss Ticket, +25 boost, weekly-week alignment, 2x "Rank up an 'x' Warlord", 4x "Set <rarity> Warlord" rows)
- WRONG: 3 (Heist Plan market row, Complete 10 Dens, Complete 50 Dens)
- DEVIATION: 2 (Subscriptions, per user decision; the undocumented £10 +25 upgrade)
- MISSING: 0

## 2. Fix list

### P1
None. Every row grants what it says, and real-money limits are enforced.

### P2
1. **Pit refill limits not shown or disabled in the shop.** `scripts/ui/screens/shop.gd`, `_limit()` line 73: replace `Game.S.shop_bought.get("%s|%d" % [sec, i], 0)` with `Game.shop_bought_count(sec, i)`, so Trinium Market rows use the daily key. Also show "today" (e.g. "0 / 2 today") when `sec == "Trinium Market"`.
2. **Heist Plan market row blocked while holding any plans.** `shop.gd`, `_buy_btn()` lines 90-93: remove the `Game.cur("heist") > 0` disable. Plans may overflow the 5 cap (user decision; the daily refresh is `max(heist, 5)`, Game.gd:264). Optionally keep a tooltip: "Plans above 5 are kept".
3. **Lost den battles count toward "Complete 10/50 Dens".** `scripts/core/Content.gd`, `finish()` line 530: move `Game.track("den", 1)` inside the `if won:` block.
4. **"Premium + 25 Levels" gives nothing extra at level 25 or above.** `scripts/ui/screens/battle_pass.gd` line 40: hide or disable the £25 button when `Game.bp_level() >= 25` (the £10 upgrade is already hidden at 25+). Alternatively make `Game.bp_buy_premium(true)` add 25 levels (`merits += 500`), but the GDD text says "straight to level 25", so prefer the UI guard.

### P3
5. Raid Boss Ticket card: add a description or tooltip in `shop.gd` `_card` ("+1 Gang Bastion entry after the daily entries are used").
6. "Set Rare/Epic/Legendary Warlord" rows: ask the user whether "Set" means a fixed season warlord. If yes, add a per-season warlord id to the BP row data and show its name and portrait on the track cell. For now, label the cell "Random <Rarity> Warlord".
7. "Rank up an 'x' Warlord": ask the user what x is (rarity, syndicate or class), then add `ev` variants in `Data.BP_DAILY` / `BP_WEEKLY` and `track()` calls in `Game.rank_up`.
8. Align BP weekly sets to season weeks: in `Game._check_bp`, key weekly picks and the reroll by `bp_season_info().week` instead of `U.week_id()`.
9. `U.reward_label` gearSet/implantSet: include the rarity when `r.r != ""` ("Set of Rank 6 Legendary Equipment") so the pack confirm dialog matches the GDD text.
10. Trinium Market and Credit Bank buys have no confirmation (up to 5000 Trinium per click): route `shop.gd:_buy` Trinium rows through `main.confirm`.
11. Document the £10 "+25 LV" upgrade for premium owners in GDD_COVERAGE.md deviations, or remove it.


**Applied (owner C):** P3 5 - added `Data.REWARD_INFO["raidTicket"]` ("+1 Gang Bastion (raid boss) entry after the daily entries are used."). The shop desc comes from GDD row text (parsed for rewards), so D should show it in `shop.gd _card` when the row parses to `raidTicket`.

## Applied (owner D, screens)
- P2 1 shop _limit uses Game.shop_bought_count; Trinium Market shows "x / 2 today" and a reset tooltip when maxed.
- P2 2 Heist Plan row no longer disabled while holding plans (tooltip "Plans above 5 are kept").
- P2 4 "PREMIUM +25 LV £25" hidden at BP level 25+.
- P3 5 Raid Boss Ticket card text appends Data.REWARD_INFO.raidTicket; P3 10 every Trinium-priced buy goes through main.confirm.
- Not done here: P3 9 set labels with "Legendary" live in U.reward_label (owner C file). P3 6/7/8/11 HELD or user questions.

**Applied (owner C):** P3 9 - `U.reward_label` keeps the rarity in gearSet/implantSet labels.
