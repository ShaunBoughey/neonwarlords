# Audit 07 - Gameplay: currencies, contracts, player level, pit rank, login, jobs, ambitions, safehouse

GDD section: `review/gdd/00_full_gdd.txt` lines 1712-2087.
Evidence:
- `tests/audit/07/compare.py` compares every row of `data/gdd.json` with the GDD text. Player levels 100/100 match. Login 31/31, jobs 22/22 and ambitions 192/192 match. The only differences are the 4 documented typo fixes.
- `tests/audit/07/probe.gd` (headless, `NW_SAVE=audit07`, exit 0, no script errors) parses every reward string in the section: 100 level rows, 22 jobs, 192 ambitions and 31 login days. Every chunk maps to the right kind and amount (0 chunk-count mismatches, 300/300 credit values exact). It also runs `ambition_progress` on all 192 rows. Every row resolves to a real counter with the target from the text, and none falls through to the default `[0,1]`. It then checks the rules (level-ups, energy, pit loss, safehouse, login, jobs, daily refresh).

Statuses: OK, MISSING, WRONG, PARTIAL, DEVIATION (as in `GDD_COVERAGE.md`).

## 1. Item table

### Currencies
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| C1 | Credits: buy gear in shops; from PvE, rewards, missions, selling equipment / neons / implants; no cap | `S.cur.credits` | `sell_equipment` Game.gd:913 (implants are equipment), `sell_neon` :1003, Plaza :1655 | HUD pill Main.gd:379 | OK | |
| C2 | Contracts: recruit by rarity; from PvE, missions, rewards; no cap | `S.items.contract{uncommon..legendary}` Game.gd:47 | `open_contract` :1049 | Recruit screen "Owned N" recruit.gd:110, Inventory > Items inventory.gd:98 | OK | |
| C3 | Trinium: premium, 132 per GBP 1; bought with real money | `S.cur.trinium` | Trinium Vault rows (660 for 4.99 = 132/GBP) | HUD pill Main.gd:380 (opens the Vault) | OK | |
| C4 | Energy: cap 160 | `Data.ENERGY_CAP` 160 Data.gd:45 | regen 1 per 180 s stops at the cap (Game.gd:251); rewards and batteries may go over it | HUD "x/160" Main.gd:404 | OK | Overflow is a user decision. |
| C5 | Brawl Invites: Pit Brawl entry; from missions, Trinium, rewards; cap 10 | `S.cur.brawl` | daily top-up to 10 (Game.gd:265, Pit section says "refreshed daily"); refill shop row 100 Trinium | Arena "invites" arena.gd:42, Inventory :114 | OK | |
| C6 | Royal Invites: same, cap 10 | `S.cur.royal` | Game.gd:266 | same | OK | Probe: after a day both are 10. |
| C7 | Heist Plan: Heist hideout only; 5 a day; cap 5 | `S.cur.heist`, `HEIST_DAILY` 5 | `max(heist, 5)` at the daily reset Game.gd:263; the shop refuses a refill while plans are held (shop.gd:91) | Fight hub "x / 5" fight.gd:21, hideout list, Inventory | DEVIATION | It matches the user decision that caps stop only the refresh. But GDD_COVERAGE "GDD rules enforced" still says "capped at 5, unused ones lost (reward plans no longer stack past 5)", which the code no longer does. The doc wording is stale; the code is right. |
| C8 | Pit Coin: Black Market and Safehouse only; from PvP wins | `S.cur.pitCoin` | spent only in `bm_buy` Game.gd:1624 and `safehouse_upgrade` :1678; earned in `pit_record` :1525 | HUD pill on arena / black market / safehouse only (Main.gd:393) | OK | Not in Inventory > Items. That is fine, because it shows where it is used. |
| C9 | Bounty Token: Syndicate Wars entry; 12 a day; cap 12 | `S.cur.bounty`, `BOUNTY_DAILY` 12 | Game.gd:264 | Fight hub, SW screen "x / 12" syndicate_wars.gd:50 | OK | Probe: 0 becomes 12 next day. |
| C10 | Merits: level the Battle Pass; from BP missions; purchasable | `S.bp.merits` | `bp_add_merits`, BP challenges, premium +25 | Battle Pass screen battle_pass.gd:19-24 | OK | Detail belongs to the BP audit. |

### Contracts
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| K1 | Uncommon contract 90 C / 9 U / 1 R | `Data.CONTRACT_RATES` Data.gd:246 | `U.weighted` in `open_contract` | Rates panel recruit.gd:136-141 | OK | 7 commons, 7 uncommons, 8 rares, 7 epics and 7 legendaries can be recruited. |
| K2 | Rare 92 R / 7.5 E / 0.5 L | same | same | same | OK | |
| K3 | Epic 92 E / 8 L | same | same | same | OK | |
| K4 | Legendary 100% L; only from breaking legendaries, rewards and purchase | same | Sources: scrap (SCRAP_FOR legendary), level rows 96-99, tier-3 ambitions, Packs | same | OK | No other source exists. |
| K5 | Breaking a warlord gives 1-2 scrap | `S.items.scrap{tier}` | `break_down` Game.gd:1058 `U.ri(1,2)` | Armoury SCRAP button with confirm text warlord.gd:311 | OK | |
| K6 | 10 scrap = 1 contract, per contract tier | `SCRAP_TO_CONTRACT` 10, `SCRAP_FOR` | auto-assembles Game.gd:1072-1075 | Recruit "Scrap: n / 10" for the selected case recruit.gd:143; Inventory "(n/10 scrap)" per tier; city tip city.gd:10 | OK | Common warlords give Uncommon scrap. There is no Common contract, so this is a sensible fill. |

### Player level
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| P1 | XP from Jobs | `S.player.xp` | Job rewards parse "N XP" to `pxp`, then `add_pxp` | Reward chips on job rows | OK | |
| P2 | XP from "Life Goals" (Ambitions) | - | No ambition row in the GDD lists XP, so none is given | account.gd:47 says "Earn player XP from Jobs, Ambitions and 1 XP per energy" | PARTIAL | The tables are the spec, so giving no XP is right. The account text promises Ambition XP that never comes (P3). |
| P3 | 1 XP per energy spent | - | `spend("energy")` calls `add_pxp(n)` Game.gd:323 | | OK | Probe: spending 8 energy gives +8 XP. |
| P4 | 100-row XP / reward table | `data/gdd.json playerLevels` | 100/100 rows match; every reward parses (credits, Trinium, UC/R/E/L contracts, Lvl 3/4/5 firmware incl. "2 Lvl 5", 1L Warlord) | Account > "Upcoming player level rewards" | OK | |
| P5 | Each level refills energy to max | | `energy = max(energy, 160)` Game.gd:407 | Level-up card, mail body "Energy refilled (1x Energy)" | OK | Probe: 10 energy goes to 160 on level-up. |
| P6 | "1x Energy" in each row | | Filtered out; the refill is the energy reward | | DEVIATION | User decision (level-up energy = refill only). |
| P7 | Level 100 cap; row L granted on reaching L+1; row 100 = max milestone | `S.player.maxed` | Game.gd:392-416 | HUD hex shows 100 | DEVIATION | Documented. Probe: 10M XP gives level 100, maxed, and row 100 gives 6M credits + a Legendary warlord. |
| P8 | Level rewards delivered | `send_mail` | Inbox is capped at 60 by `resize(60)` Game.gd:468, which drops the **oldest mails even if unclaimed** | Inbox | PARTIAL | A big XP jump plus weekly pit / gang mail can silently delete unclaimed level rewards. The probe kept only 60 of 99 level mails, so the oldest were lost. |
| P9 | Level and XP visible | | | HUD level hex + XP bar Main.gd:400-403; Account "XP x / y"; level-up card Main.gd:465 | OK | |

### Pit rank
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| R1 | 13 ranks, names and point thresholds | `gdd.json pitTiers` | `pit_tier` Game.gd:1503 | Arena bracket ladder arena.gd:208 | OK | Probe: 99 and 100 = tier 1, 2999 = 12, 3000 = 13. |
| R2 | Separate sets for Brawl and Royal | `S.pit.brawl / royal` | | Arena per mode | OK | |
| R3 | Weekly cache per set | | `_weekly_pit_rewards` Game.gd:1600 mails both | Inbox | OK | |
| R4 | Loss values 10 (1-4) / 15 (5-8) / 20 (9-12) / 25 (13) | | `Data.pit_loss` | Defence log "-N pts" | OK | Probe: all 13 tiers correct. |
| R5 | Losses on **offence** lose points | | Offence loss costs only the invite Game.gd:1529 | arena.gd:82 note | DEVIATION | GDD_COVERAGE "Pit ranking" user decision. The code matches it. |
| R6 | Losses on defence lose points | | `_simulate_pit_defense` Game.gd:1536 (real off-screen battles) | Defence log | OK | Offline stand-in. |
| R7 | +10 per offensive win | | Game.gd:1522 | Log "+10 pts", arena note | OK | |

### Monthly login rewards
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| L1 | 5 x 7 grid, exact items (31 days) | `gdd.json login` 31 | every day parses right (batteries, XP boosts, Rare T3 gear, Firmware lvl 2/3, UC T2 implant, UC/Rare contracts, credits, 250 Trinium, Epic Warlord) | login_rewards.gd 7-column grid with Mon-Sun headers, reward art and label | OK | |
| L2 | Progresses only on login; no reset on missed days | `S.login.progress` | `_check_login` resets only `claimed` | Today's card highlighted, done ones ticked | OK | Probe: after missing 5 days, progress stays 1. |
| L3 | Month 1 releases a specified Epic Warlord | | Random Epic from `by_rarity("epic")` | events.gd:15 "An Epic Warlord awaits" | DEVIATION | User decision (day 31 random Epic). |
| L4 | Becomes a rolling reward after some months | | `login_index` = progress mod 31 | | OK | Probe: day 31 claimed, then the index wraps to 0. |
| L5 | Optional: randomise the groupings per month | - | - | - | MISSING | The GDD calls this an "additional feature" (P3). |
| L6 | Reachable | | | City gift button with badge city.gd:74, Events card | OK | Not auto-shown at login. That is fine; RAID behaves the same. |

### Jobs
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| J1 | Daily: 3 Pit Brawls / 100 XP, 1x Energy, 10k | `JOB_DEFS` Data.gd:338 | `track("pitBrawl")` on every Brawl (not Royal) win or loss, Game.gd:1519 | missions.gd rows with reward chips and progress bar | OK | "1x Energy" gives 1 Energy Battery. |
| J2 | Daily: 10 Den battles any difficulty / 100 XP, 10 Brawl invites, 10k | | `track("den")` Content.gd:530 also counts **losses** | | PARTIAL | "Complete" usually means win (P3). |
| J3 | Daily: buy 1 Plaza item / 100 XP, 10 Generic Minor Deeds, 10k | | `plazaBuy` Game.gd:1667 | | OK | |
| J4 | Daily: recruit 3 / 100 XP, 10 Trinium, 10k | | `recruit` in `open_contract` | | OK | |
| J5 | Daily: 3 equipment to 8+ / 100 XP, lvl 3 Firmware, 10k | | `equip8` when level hits 8, also through firmware (Game.gd:889) | | OK | |
| J6 | Daily: raise a warlord's level / 100 XP, 1 Heist Plan, 10k | | `warlordLevel` in `add_wxp` | | OK | |
| J7 | Daily: 3 equipment from hideouts / 100 XP, 10 Trinium, 10k | | `hideoutEquip` per drop Content.gd:302 | | OK | |
| J8 | Daily: complete all / 300 XP, 50 Trinium, 50K | | counts the other 7 claimed jobs | | OK | Probe: 7/7, then claimable. |
| J9 | Weekly: all dailies 5x / 20 brawls / +1 rep / 15 hideout equipment / rank 3 / 3 to 12+ / complete all, with exact rewards | | `dailyAll` is tracked when the daily "all" row is claimed Game.gd:1242 | | OK | Probe: weekly dailyAll went to 1. |
| J10 | Monthly: all dailies 30x / 150 brawls / 400 dens / rank 5 / 3 to 16 / 100 hideout equipment / complete all | | Calendar month (`U.month_id`) | Reset countdown missions.gd:44 | PARTIAL | In February (28/29 days) "Complete all Daily Jobs 30 Times", and so "Complete All Monthly Jobs", cannot be done. The table number is spec. The open lever is the monthly period: use a fixed 30/31-day window, or count from the start of the month the job was seen (P3). |
| J11 | Jobs for features that are not unlocked yet | | Pit is level 10, Hideouts level 5, Plaza level 4 (`FEATURE_UNLOCK`) | Rows show "IN PROGRESS" with no lock hint | PARTIAL | "Complete All Daily Jobs" is impossible before level 10 and the player isn't told why (P3). |

### Ambitions
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| A1 | 6 tables, 192 rows, exact text and rewards | `gdd.json ambitions` | All rewards parse (energy batteries, XP boosts, generic deeds, Rank 4-6 Epic equipment/implants, Trinium, heist, firmware, credits, brawl invites, pit coin, T1-3 MF, R/E/L contracts) | missions.gd ambition tabs | OK | |
| A2 | Hideout order 11 says "Paragon" (repeat); Warlord tier 3 "Recruit 50" (repeat) | | Changed to Generic Deeds / Recruit 100 | | DEVIATION | Documented typo fixes. |
| A3 | Campaign: Den N:7 per difficulty | | `campaign_stars(d, den, 6) > 0` | | OK | |
| A4 | Hideout: stage X, N times | | `hideout_wins_at_or_above` (counts wins at stage >= X) | | OK | All 11 hideout names map to ids. |
| A5 | Equipment tier 1 #1-6 (set + slot + primary), #9-11 | | `eq_seen` key set, slot, primary | | OK | |
| A6 | Equipment tier 1 #7 "Crit Chance Set **Gloves** with Crit Chance% Primary" and #8 "Crit Damage Set Gloves with Crit Damage% Primary" | | Gloves primary is only Firepower: `Data.SLOT_STATS.gloves.pri = ["fp"]` Data.gd:98, from the GDD primary matrix (00_full_gdd.txt:205-216; CC%/CD% are Weapon primaries) | Rows stay "IN PROGRESS 0/1" forever | **WRONG** | They can never complete. So "Complete All Tier 1 Equipment Ambitions" is unreachable, and the tier gating (`ambitions_list` Game.gd:1376-1380) **hides all of Equipment tiers 2 and 3** (24 rows, an Epic and a Legendary contract). This is a GDD self-contradiction that round 1 missed. |
| A7 | Equipment tier 2-3 sets / full set / sell / level | | `_count_with_set`, `_count_full_set`, `sold`, `equip_to_N` | | OK | Not reachable today because of A6. |
| A8 | Reputation: N deeds of tier+alignment; raise an X-aligned warlord to rep R | | `deeds_<al>_<tier>` stat from `grant` (all sources); best rep per alignment | | OK | |
| A9 | Warlord: Recruit 25/50/100 | `stats.recruited` | `add_warlord` counts the **5 starter warlords** (and debug or reward adds) | Shows 5/25 on a new account | WRONG | Minor (P3). |
| A10 | Warlord: level N to L, rank N to R, consume N, class to level | | roster counts; `consumed` from break-down, rank-up and feeding | | OK | Rank counts include warlords that start at a higher rank. That is RAID-like, so OK. |
| A11 | Bastion & Pit: damage, boss debuffs, entries, turns survived, pit entries, kills, debuffs, safehouse purchase level | | stats at Content.gd:540-550, `safehouse_max_level` | | OK | 45-turn row works with the 50-turn cap. |
| A12 | "Complete all Tier N" rows and tier gating | | counts claimed rows in the tier; next tier shown when the current one is fully claimed | "Tier N" headers, "Complete a tier to reveal the next" | OK | |

### Safehouse
| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| H1 | On the City Centre hub; nodes per core stat, split by morality | `S.safehouse{paragon,neutral,renegade}{node}` | 6 nodes (`SAFEHOUSE_NODES`) x 3 alignments | city.gd:88 sign; safehouse.gd 3 alignment columns with "N Warlords benefit" | OK | Unlocks at player level 10 (`FEATURE_UNLOCK`, open lever). |
| H2 | 10 levels, costs 100 ... 1,250 Pit Coin | `SAFEHOUSE_COST` | `safehouse_upgrade` Game.gd:1673 | cost button "N PC", disabled if short | OK | Probe: levels 1-10 cost 6,650 total; level 11 gives "Max level." |
| H3 | HP / Armour / Firepower / Crit Damage 1-20% | `SAFEHOUSE_PCT` | `compute_stats` Game.gd:792-801 adds to the percentage pool (CD additively) | "+N% Next +M%", totals | OK | Probe at level 10: HP 1065 to 1278 (+20%), CD 50 to 70. |
| H4 | Hacking / Firewall flat 2-40 | `SAFEHOUSE_FLAT` | flat add | "+N" | OK | Probe: Hack 0 to 40, FW 30 to 70. |
| H5 | Applies only to the matching alignment, player warlords only | | `S.safehouse[t.align]`, skipped for enemies | Stat breakdown includes "safehouse" in base (warlord.gd:1255) | OK | |

## 2. Fix list

### P1
1. **Equipment ambitions T1 #7/#8 can't be done and hide tiers 2-3.** This is a GDD contradiction (primary matrix vs ambition text), so ask the user first. The recommended fix follows the earlier typo fixes:
   - Data fix: in `data/gdd.json` Equipment rows [1,7] and [1,8], read "Gloves" as "Weapon", the only slot where CC%/CD% are primaries.
   - Rule alternative: in `Game.ambition_progress` (Game.gd:1265-1269), when the named slot can't roll that primary (`not Data.SLOT_STATS[slot].pri.has(pri)`), match any slot that can.
   - Either way, add one line to GDD_COVERAGE "GDD typos fixed".
   - Do **not** add CC/CD to `SLOT_STATS.gloves`, because that would change the GDD matrix.

### P2
None. All tables, parsing and caps are right. Only the issue above breaks a rule.

### P3
2. **Inbox trimming deletes unclaimed rewards.** In `Game.send_mail` (Game.gd:466-469), drop claimed mails first (oldest first) and only then trim, or never drop a mail with unclaimed rewards.
3. **"Recruit N Warlords" counts the starter crew.** In `Game.new_game` (Game.gd:79-80), the starter warlords are added with `silent=true`. Either skip `stat_add("recruited")` when `silent`, or subtract 5 after the starter loop.
4. **Den job counts losses.** In `Content.finish` (Content.gd:530), call `Game.track("den", 1)` only when `won`. Same question for `pitBrawl` (Game.gd:1519): the GDD says "Complete"; ask the user.
5. **February makes the monthly "all dailies 30x" impossible.** The lever is the monthly period in `Game._check_job_periods` / `U.month_id`. Keep the table number.
6. **Jobs for locked features.** In `missions.gd _row` / `Game.jobs_list`, add "Unlocks at Player Level N" (from `Data.FEATURE_UNLOCK`) to the Pit Brawl, Plaza and Hideout job rows while those features are locked.
7. **Account text.** `account.gd:47` should not promise XP from Ambitions. Suggested text: "Earn player XP from Jobs and 1 XP per energy spent."
8. **Login.** The optional per-month regrouping (GDD "additional feature") is not built. The weekday headers (Mon-Sun) don't match the real weekday of day 1. Either label the columns "Week 1-5 / Day 1-7" or leave as the GDD grid.
9. **GDD_COVERAGE wording.** The Heist line says "unused ones lost / no longer stack past 5", but the code (correctly, per the user decision) lets rewards overflow. Update the doc line only.

## 3. Counts
OK 52, DEVIATION 6, PARTIAL 5, WRONG 2, MISSING 1 (66 items).


**Applied (owner C):** P3 2 - `Game.send_mail` trims oldest *claimed* mail only, never unclaimed rewards. P3 3 - `new_game` resets `stats.recruited` after the starter crew (old saves unchanged). P3 7 (account.gd text) is D-owned - passed to coordinator.

## Applied (owner D, screens)
- P3 6 missions.gd: Pit Brawl / Plaza / Hideout job rows show "<Feature> unlocks at Player Level N" while locked.
- P3 7 account.gd text: "Earn player XP from Jobs and 1 XP per energy spent."

**Applied (owner C, HELD decisions):** player XP now granted at battle end via `Game.battle_pxp` (full on win, 20% on loss, fractions banked in `player.xp_frac`); `spend("energy")` no longer grants XP. "den" and "pitBrawl" tracks count wins only (hideout already did). Equipment ambition 1-7/1-8 read as Weapon (data/gdd.json text). Starter Neons removed.
