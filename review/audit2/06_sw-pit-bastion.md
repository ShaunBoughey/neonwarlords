# Audit 06 - Syndicate Wars, The Pit, Black Market, Bastions, Stocks, Gang, Plaza

GDD: `review/gdd/00_full_gdd.txt` 1474-1711, 2088-2092. Probe: `tests/audit/06/probe.gd` (headless, `NW_SAVE=audit06`). It parses every SW / progression / bracket / cache / Black Market row, Monte-Carlos the stage-1 Neon odds, and exercises Black Market limits, a Pit win and loss, and the daily refresh.

Probe highlights:
- All 20 SW rows match the GDD (tokens 1/2/3/4, rank odds).
- Stage-1 MC over 2000 drops gave R1 35% / R2 41% / R3 24%. The 10 Neon stats came out uniform, about 10% each.
- All 24 progression rows parse, up to 360 = Legendary Warlord.
- All 13 brackets parse, and so do all cache rows (ranges and nested caches). An Exalted cache gave 6x R6 legendary set, Epic Contract, 2.25M credits, Rare Stimm and 2000 PTC.
- Black Market credits can be bought 3 times in a row; Rare Stimm stops at 1 per day.
- A Pit win took points from 100 to 110 and paid 10k credits + 10 PTC. A lost attack kept the points at 110.
- The daily tick refilled bounty 3 -> 12 and brawl 2 -> 10.

## 1. Item table

| # | GDD item | Stored | Rules | Shown | Status | Evidence / note |
|---|---|---|---|---|---|---|
| 1 | SW team from a single syndicate | Y | Y | Y | OK | `Content.build_sw` lock_syn (Content.gd:358); `squad.gd:145` filters roster; "X only" label squad.gd:92; SW centre text |
| 2 | SW is the only source of Neons | Y | ~ | Y | PARTIAL | `sw_rewards` Content.gd:360. `grant_starter_kit` gives 8 Neons (Game.gd:105-106), which goes against "only location". Other GDD tables (shop packs, campaign progression) also list Neons, so the GDD contradicts itself there |
| 3 | Encourages use of lesser warlords | - | Y | Y | OK | Owned count per syndicate in the rail and centre (syndicate_wars.gd:121,146) |
| 4 | 20 stages | Y | Y | Y | OK | 2 pages of 10, unlocked in order (syndicate_wars.gd:157-196) |
| 5 | 1-3 chevrons per stage "depending on circumstances" | Y | Y | ~ | PARTIAL | `Content.chevrons` (Content.gd:476): win / no warlord lost / within 14 turns; best kept per stage (`sw_record`). Chevrons are shown per stage, but the SW screen never says how to earn them |
| 6 | Reward bar for full completion, chevron table 15..360 | Y | Y | Y | OK | `Data.GDD.swProgress`, `claim_sw_progress` Game.gd:1496; milestone strip and bar syndicate_wars.gd:60-117; all 24 rows parse (probe) |
| 7 | Bounty Tokens needed to enter | Y | Y | Y | OK | cost `{"bounty": tokens}`; cost shown on the BATTLE button; `Game.pay` |
| 8 | Tokens refresh daily to a max of 12 | Y | Y | ~ | PARTIAL | Game.gd:265 tops up to 12 (overflow allowed, user decision). Pill shows x / 12, but there is **no countdown to the refill** |
| 9 | Token cost per stage (1x/2x/3x/4x) | Y | Y | Y | OK | probe: all 20 rows match |
| 10 | Neon rank odds per stage | Y | Y | Y | OK | `_rank_weights` + `U.weighted`; MC matches; `_odds_text` shows "R1 35% • R2 40% • R3 25%" |
| 11 | "Equal Chance Random Stat Focus 10" | Y | Y | N | PARTIAL | `add_neon` picks evenly from 10 `NEON_STATS` (10% each, MC confirmed). The odds text never says the stat is random with equal odds |
| 12 | Brawl Invites needed | Y | Y | Y | OK | cost `{mode: 1}` (Content.gd:436) |
| 13 | Brawl Invites cap 10 | Y | Y | Y | OK | `Data.PIT_CAP`; "x / 10" + segments (arena.gd:44-46); overflow by user decision |
| 14 | Invites refresh daily | Y | Y | ~ | PARTIAL | Game.gd:266-267. Arena subtitle shows only the weekly reset; **no daily refill countdown** |
| 15 | Invites earned through missions | Y | Y | Y | OK | GDD jobs/ambitions "10x Pit Brawl Invites" parse and grant |
| 16 | Invites bought with Trinium | Y | Y | Y | OK | Trinium Market "10x Pit Brawl Invites" (gdd.json shop). Arena has no shortcut to it when you are out (P3) |
| 17 | 5-warlord defence gang | Y | Y | Y | DEVIATION | team size 4 (user decision); Defence tab arena.gd:121 |
| 18 | 10 opponents from Skill Bracket and Ranking | Y | Y | Y | DEVIATION | `Content.pit_opponents` (10, points ±, bracket-scaled, hourly) - offline stand-in, matches GDD_COVERAGE |
| 19 | Tailor the offensive team | Y | Y | Y | OK | squad picker per fight |
| 20 | Win: Pit Coin + PvP ranking | Y | Y | Y | OK | `pit_record` Game.gd:1515 (+10 pts, bracket credits/PTC; probe) |
| 21 | Weekly rewards by Skill Bracket | Y | Y | Y | OK | `_weekly_pit_rewards` mails the bracket caches (Game.gd:1600); weekly cache line + "Weekly reset" timer in arena |
| 22 | Ascend brackets at any time | Y | Y | Y | OK | `pit_tier` computed live from points |
| 23 | Lose ranking when defence is beaten | Y | Y | Y | OK | `_simulate_pit_defense` + `Data.pit_loss`; failed attack loses nothing (probe); Defence log |
| 24 | Leaderboard shows defence teams | Y | Y | Y | OK | `_board_row` portraits (arena.gd:203) |
| 25 | Leaderboard shows weekly earned rankings | N | N | ~ | PARTIAL | Shows lifetime points only. Nothing tracks or shows the points earned this week |
| 26 | Leaderboard shows bracket | - | Y | Y | OK | arena.gd:214 |
| 27 | Filters Gang / Friends / Search | - | Y | Y | OK | arena.gd:170-189 (offline rows) |
| 28 | Royal Invites cap 10, daily refill | Y | Y | ~ | PARTIAL | same as 13/14 - no refill countdown |
| 29 | Royal refills through missions | N | N | N | PARTIAL | No mission grants Royal Invites: the GDD jobs table lists only Brawl Invites. GDD-internal gap, open lever for the user |
| 30 | Royal Invites bought with Trinium | Y | Y | Y | OK | Trinium Market "10x Pit Royal Invites" |
| 31 | 8 warlords = 5 + 3 reinforcements | Y | Y | Y | DEVIATION | 4 + 3 (user decision): squad.gd:12, Content.gd:376, arena Defence "Reinforcements" |
| 32 | A reinforcement takes the slot of a gang member who dies | - | Y | Y | OK | Battle.gd:743-757 (both sides), spawn event |
| 33 | NO REVIVES in Royal | - | Y | N | PARTIAL | `no_revive` battle.gd:224, Battle.gd:400,761,1051. The squad picker, Royal fight list and battle never tell the player |
| 34 | Reinforce abilities trigger on entry | Y | Y | Y | OK | `_reinforce_fx` Battle.gd:198 called on spawn; 10 reinforce abilities in Warlords.gd |
| 35 | Bracket table: 13 tiers, names, points | Y | Y | Y | OK | `Data.GDD.pitTiers`; Brackets tab arena.gd:220 |
| 36 | Weekly cache per tier | Y | Y | Y | OK | probe parses all 13 |
| 37 | Fight rewards (x10 pts, credits, PTC) | Y | Y | Y | OK | regex Game.gd:1526; Brackets "Per win" column |
| 38 | Bracket progress | Y | Y | ~ | PARTIAL | Current tier and points shown; no "N pts to next bracket" bar |
| 39 | Meager Cache contents and chances | Y | Y | - | OK | `open_cache` Game.gd:1161 (equipment regex, ranges, %) |
| 40 | Substantial (incl. 20% Meager) | Y | Y | - | OK | nested cache goes to inventory |
| 41 | Sublime (incl. 20% Substantial) | Y | Y | - | OK | |
| 42 | Exalted (incl. 25% Sublime) | Y | Y | - | OK | probe opened one |
| 43 | Cache contents visible to the player | - | - | N | MISSING (UI) | inventory.gd:118-125 only has "Open X (n)"; arena shows only "Weekly cache: 1x Meager Cache". No list of contents or chances anywhere |
| 44 | Black Market: all 16 items, PTC costs | Y | Y | Y | OK | `Data.GDD.blackMarket` (probe: all parse) |
| 45 | 1 per day / 1 per week limits | Y | Y | Y | OK | `bm_period_key`/`bm_can_buy` Game.gd:1606; daily and weekly countdowns in subtitle; "Sold out" |
| 46 | Credits not limited | Y | Y | Y | OK | "No limit" tag; probe 3 buys |
| 47 | Bastion is gang-wide | Y | Y | Y | OK | NPC members' damage + a shared boss HP pool (Game.gd:1905-1920; offline) |
| 48 | 3 days, one stage per day | Y | Y | Y | OK | stage = day%3+1 (Game.gd:1932); 3-stage strip in gang.gd:27 |
| 49 | Rewards by damage after each daily reset | Y | Y | ~ | OK | `_daily_gang` mails `bastion_rewards` (Game.gd:1928); explained in text. No reset countdown (P3) |
| 50 | Can still enter after full defeat | Y | Y | Y | OK | `defeated` doesn't block; "Defeated - you can still attack" tag |
| 51 | Everyone can get max rewards with enough damage | Y | Y | Y | OK | personal cumulative tiers (Content.gd:467); tier chips tick |
| 52 | Assault on Teratech: Atrium / Foundry / Head of the Hydra | Y | Y | Y | OK | `BASTION_STAGES` |
| 53 | Bring It On immunities (STUN, SHOCK, STUPEFY, TM, CD increase, ENRAGE) | Y | Y | Y | OK | `IMMUNE_BOSS_TM` Warlords.gd:88,416,422,428; Battle.gd:836,868; ability list in gang screen |
| 54 | Side minion | Y | Y | Y | OK | 3x teratek_drone |
| 55 | Boss / minion abilities (blank in GDD) | Y | Y | Y | DEVIATION | designed to fit (GDD_COVERAGE) |
| 56 | Reward tables (blank), turn cap | Y | Y | Y | DEVIATION | `BASTION_TIERS`, 50 turns (GDD_COVERAGE) |
| 57 | Stocks 22 / 44 / 66 per day | Y | Y | Y | OK | `Data.STOCKS`, tick accrual; city stocks modal |
| 58 | Caps 40 / 60 / 75 | Y | Y | Y | OK | `stocks_cap` |
| 59 | Levels from progression missions | Y | Y | Y | DEVIATION | tier-completion ambitions (GDD_COVERAGE); unlock text in modal |
| 60 | Extra cap as a microtransaction | Y | Y | Y | DEVIATION | Stocks Vault +25 x4 (shop.gd:307) |
| 61 | Gang required before Bastions | Y | ~ | ~ | PARTIAL | Every player is auto-placed in an NPC gang (`_init_gang`), so the requirement is always met. No join / leave flow (offline stand-in) |
| 62 | Gang chatroom | - | ~ | ~ | PARTIAL | 3 seeded fake lines, read-only; the player can't post (offline) |
| 63 | Gang messages for the leader | Y | Y | Y | OK | MOTD, MESSAGE button (gang.gd:94,140) |
| 64 | Plaza: hourly credit market | Y | Y | Y | OK | `plaza_items` seeded per hour, credits, "New stock in" countdown, stale-buy guard |

**Counts:** OK 44, PARTIAL 12, MISSING 1, WRONG 0, DEVIATION 7 (64 items).

## 2. Fix list

### P1
None. Every rule in the GDD tables is implemented and matches the probe.

### P2
1. **Daily refill countdown for Bounty Tokens and Pit Invites.**
   - `scripts/ui/screens/syndicate_wars.gd` `_bounty_pill()`: add a label "Refills in " + `U.dur(U.secs_to_next_day())`, and put the same text in the tooltip.
   - `scripts/ui/screens/arena.gd` `build()`, invites row (`ihh`/`iv`): add "Refills to 10 in " + `U.dur(U.secs_to_next_day())`.
2. **Show Pit Cache contents and chances.**
   - Add a helper `UI.cache_info(name) -> String` that lists `Data.GDD.caches[name]` rows as "text - chance%".
   - Use it as the tooltip or an info modal on the arena "Weekly cache" label (arena.gd:47).
   - Use it on the Brackets tab weekly-reward cells (arena.gd `_brackets`).
   - Use it on the inventory "Open X" buttons (inventory.gd:123).

### P3
3. SW stage panel (`syndicate_wars.gd` `_stage_panel`): add the chevron criteria under the chevron row: "1 win • 2 no warlord lost • 3 win within %d turns" % enc.chevron_turns.
4. SW `_odds_text`: append "Stat: random, equal chance (1 in %d)" % Data.NEON_STATS.size().
5. Leaderboard weekly earned rankings:
   - In `Game._weekly_pit_rewards`, store `S.pit[mode].week_start = points`, and migrate old saves to the current points.
   - In arena.gd `_board_row`, show "+N this week" (points - week_start) for your own row. NPC rows can use a seeded value.
6. Arena info panel: a progress bar to the next tier's points ("N pts to <next name>"), using `Data.GDD.pitTiers`.
7. Royal "no revives" note: add a line in squad.gd's side panel when `enc.royal`, and in the arena Royal fight note: "Reinforcements replace fallen warlords. No revives in Pit Royal."
8. Gang screen: add "Next stage and rewards in " + `U.dur(U.secs_to_next_day())` near the Bastion header.
9. Arena: when out of invites, add a button to the Trinium Market refill (shop route).
10. Ask the user: the starter kit's 8 Neons (Game.gd:105-106) contradict "SW is the only source of Neons". Should they stay?
11. Ask the user: the GDD gives Royal Invites through missions, but the jobs table lists only Brawl Invites. This is an open lever; don't change the GDD tables.
12. Optional: let the player post in the offline gang chat, stored in `S.gang.chat`. GDD: "gang chatroom".

## Applied (fix owner A - combat)
- P3 Royal: battle opens with a "NO REVIVES IN PIT ROYAL" banner and the top bar reads "... • NO REVIVES" for royal fights (`battle.gd` `_run`, `_update_top`). Squad picker / arena notes are other owners' files.

## Applied (fix owner B)
- P2 2 (inventory part): each "Open <cache>" button gets a "?" button opening `CacheInfo.show(main, kind)`, and both carry `CacheInfo.text(kind)` as tooltip.

## Applied (owner D, screens)
- P2 1 SW bounty pill shows "Refills in <time>" (and tooltip); arena invites row "Refills to 10 in <time>".
- P2 2 new scripts/ui/cache_info.gd (CacheInfo.show/text/link/kind_in) from Data.GDD.caches; arena weekly-cache label and Brackets weekly-reward cells open it. Inventory hook is owner B.
- P3 3 chevron criteria under SW stage; P3 4 "Stat: random, equal chance (1 in 10)"; P3 6 arena progress bar + "N pts to <next>"; P3 7 arena Royal note "No revives in Pit Royal" (squad.gd not owned); P3 8 Bastion "Next stage and rewards in"; P3 9 "Buy invites" button to Trinium Market when out.
- Skipped: P3 5 (needs Game save field, owner C), P3 12 (optional chat).
