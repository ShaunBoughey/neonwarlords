# Section 12 review: Currencies, Contracts, Player Level, Pit Rank

GDD text: `review/gdd/12_currencies-contracts-playerlevel-pitrank.txt`
Probes (mine): `tests/review/12/Probe.tscn` (headless logic), `tests/review/12/Shots.tscn` (windowed screenshots). Both run with `NW_SAVE=12 ... -- --nwtest`.
Screenshots: `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_12\`

**Totals: 27 OK, 0 MISSING, 3 WRONG, 1 DEVIATION.** Plus 9 visual issues.

## 1. GDD items

### Currencies
| # | Item | Status | Evidence |
|---|---|---|---|
| 1 | Credits: buy gear from shops; earned from PvE, rewards, missions, selling; no cap | OK | `Game.add_cur` has no cap; Plaza and shop spend credits |
| 2 | Contracts: recruit warlords of the matching rarity; earned from PvE, missions and rewards | OK | `Game.open_contract`; campaign drops (`Data.CAMPAIGN_DROPS`), level rewards, packs |
| 3 | Trinium: premium, 132 per £1, no cap | OK | Trinium Vault: 660 for £4.99 = 132.3 per £1 |
| 4 | Energy: cap 160 | OK | `Data.ENERGY_CAP = 160`. Regen of 1 per 180 s stops at the cap (`Game.tick`); rewards and batteries can go over the cap (same as RAID). The GDD gives no regen rate. |
| 5 | Brawl Invites: cap 10; from missions, Trinium and rewards | OK (note) | Daily reset tops up to 10 (`Game.tick` `max(c.brawl, PIT_CAP)`). The Trinium refill (100 Trinium) and rewards stack past 10 without a limit; probe: 10 + 10 = 20. See P3 #11. |
| 6 | Royal Invites: same as Brawl | OK (note) | Same as #5 |
| 7 | Heist Plan: 5 a day, cap 5 | OK | `CUR_CAP`, daily reset. Probe: 5 + 3 = 5 |
| 8 | Pit Coin: PvP wins; spent only in the Black Market and Safehouse; no cap | OK | `pit_record` and the weekly caches grant it; `bm_buy` and the safehouse spend it |
| 9 | Bounty Token: 12 a day, cap 12 | OK | Probe: 12 + 3 = 12 |
| 10 | Merits: level the Battle Pass; from BP missions; can be bought | OK | `bp_add_merits`; the "+25 Lv" premium purchase |

### Contracts
| # | Item | Status | Evidence |
|---|---|---|---|
| 11 | Uncommon contract: 90 / 9 / 1 (C/UC/R) | OK | `Data.CONTRACT_RATES`; over 20k rolls: 89.83 / 9.24 / 0.93 |
| 12 | Rare contract: 92 / 7.5 / 0.5 (R/E/L) | OK | 92.05 / 7.44 / 0.51 |
| 13 | Epic contract: 92 / 8 (E/L) | OK | 92.29 / 7.71. `open_contract("epic")` x50 gave 46 E / 4 L |
| 14 | Legendary contract: 100% Legendary; only from breaking legendaries, rewards and purchases | OK | 100%. Sources: legendary scrap, level 96-99 rewards, shop packs. No campaign drop. |
| 15 | Breaking down a warlord gives 1-2 scrap; 10 scrap = 1 contract | OK | `Game.break_down`: `U.ri(1,2)`, `SCRAP_TO_CONTRACT = 10`. Common warlords give uncommon scrap (`SCRAP_FOR`). |
| 16 | Pity / mercy | OK (n/a) | The GDD has no pity rule and the code has none. If one is wanted, it is an open lever and the user's call. |

### Player level
| # | Item | Status | Evidence |
|---|---|---|---|
| 17 | XP comes from Jobs and Life Goals | OK | Job rewards include "100 XP", parsed to `pxp` |
| 18 | 1 XP for each energy spent | OK | `Game.spend("energy")` calls `add_pxp(n)`. Probe: 100 energy gave 100 XP, so level 1 went to 2 |
| 19 | Each level gives a full energy refill | OK | `add_pxp`: `energy = max(energy, 160)` |
| 20 | XP Required column, levels 1-100 | OK | `data/gdd.json` `playerLevels` matches every row (total XP from 1 to 100 is 989,450) |
| 21 | Reward column, levels 1-100 | OK | All 100 rows parse with no unknowns: credits, Trinium, UC/R/E/L contracts, Lvl 3/4/5 firmware (incl. "2 Lvl 5", "lvl 5"), 1L Warlord |
| 22 | The "1x Energy" in each level reward | WRONG (likely) | `Game.gd:375-377`: each level gives the full refill **and** parses "1x Energy" into an **Energy Battery** item (+100 energy, `use_battery`). The GDD text says the energy reward is the refill, so the player gets energy twice. Needs a decision (P2 #4). |
| 23 | 100 levels in the table (max level 100) | WRONG | `Game.gd:371` loops `while p.level <= size`, so the 30,000 XP from row 100 takes the player to **level 101**. After that `pxp_needed()` is 0 and XP keeps building forever (probe: level 101 with 99,999 XP). The HUD shows "101" with an empty XP bar, and the inbox shows "Player Level 101" (shots 30, 31). |

### Pit rank
| # | Item | Status | Evidence |
|---|---|---|---|
| 24 | 13 tiers with the names and point thresholds in the table | OK | `pitTiers` matches. `pit_tier`: 199 = Runner, 200 = Underling, 600 = Soldier, 1500 = Captain, 3000 = Neon Legend. New players start at 100 (Runner). |
| 25 | Two separate rank sets, Brawl and Royal | OK | `S.pit.brawl` and `S.pit.royal` |
| 26 | Weekly cache reward per rank | OK | `_weekly_pit_rewards` mails the cache for the player's tier in each mode |
| 27 | Point loss by tier: 1-4 lose 10, 5-8 lose 15, 9-12 lose 20, 13 loses 25 | OK | `Data.pit_loss` |
| 28 | "Losses on offence and defence lose points" | DEVIATION | The GDD contradicts itself. Section 10 says only a beaten *defence* loses points. `GDD_COVERAGE.md` records the choice of defence-only losses (`pit_record`). The arena footer copy still says otherwise (P3 #10). |
| 29 | Offensive wins give +10 points each | OK | `pit_record`: `points += 10` |

### Feature unlocks by player level (`Data.FEATURE_UNLOCK`; the GDD doesn't specify these)
| # | Item | Status | Evidence |
|---|---|---|---|
| 30 | Locked features are gated and say their unlock level | OK | City cards, Fight tiles and nav all use `feature_ok`/`feature_level` (shot 01: "Unlocks at Player Level 4", "Events • Lv 6", locked Plaza and Gang nav) |
| 31 | An announcement for every feature that unlocks | WRONG (bug) | `Game.take_new_unlocks` marks **every** newly unlocked feature as seen, but `Main._announce_unlocks` only shows `fresh[0]`. Level 4 opens Plaza and Black Market, and only Plaza is announced (shots 03, 04). Level 10 opens The Pit and Safehouse, and only one is announced. After a multi-level jump (level 4 to 10 in shot 05) only "Hideouts" is shown, and Events, Syndicate Wars, The Pit and Safehouse are never announced. |

## 2. Visual issues

| # | Issue | Screenshot |
|---|---|---|
| V1 | Features unlocked at the same level as another are never announced (item 31) | `shots_12/03_unlock_modal_lv4.png`, `04_after_close_lv4.png`, `05_unlock_modal_lv10.png`, `06_after_close_lv10.png` |
| V2 | City cards are stale after a level-up. At level 4 the Black Market card still says "Unlocks at Player Level 4". At level 10, Black Market and Safehouse still show their lock text and Events still shows the "Lv 6" lock. Nothing rebuilds the screen until you navigate away. | `04_after_close_lv4.png`, `06_after_close_lv10.png` |
| V3 | A level-up is only a one-line toast ("PLAYER LEVEL UP! 4") plus an inbox mail. There is no RAID-style level-up card showing the new level, the energy refill and the rewards, so the reward goes unnoticed until the player opens the inbox. | `02_levelup_toast.png`, `31_inbox_levelmails.png` |
| V4 | The toast stack sits on the bottom CTA row. It covers OPEN ×1 / OPEN ×10 on Recruit and the Next Goal "GO" button on City. | `10_recruit_rare.png`, `11_recruit_legendary_none.png`, `02_levelup_toast.png` |
| V5 | The reveal card truncates the recruit's name ("Enforcer Kell…", "Madame M…"). The approved canvas (Recruit board) shows the full name on the reveal. | `12_recruit_open1_reveal.png`, `13_recruit_open10_reveal.png` |
| V6 | The "RARE PULL" and "10 RECRUITS • BEST: EPIC" labels overlap the top edge of the open case | `12_…`, `13_…` |
| V7 | Level 101 shows in the HUD hex with an empty XP bar, and the inbox has a "Player Level 101" mail (item 23) | `30_city_lv_after_100.png`, `31_inbox_levelmails.png` |
| V8 | The arena footer says "Losses lose points by bracket", but failed attacks cost nothing | `20_arena_topbar.png` |
| V9 | Console: `ERROR: Infinite loop detected. Check set_loops()` once each time Recruit rebuilds. The looping PAWN-sign tween belongs to the screen, so it keeps running after the sign is freed. | console during the Shots run |

The top bar matches the canvas: Energy x/160 and Trinium have "+" buttons that open the Shop, Credits has none, and Pit Coin appears only on the Pit, Black Market and Safehouse screens. The XP bar sits under the player name. The Recruit pawn shop matches the canvas: neon PAWN sign, case shelf with owned counts, a price tag with the odds and scrap progress, the case slide and lid, the beam and card reveal. Its buttons work: cases switch, OPEN ×1/×10 are disabled when you don't have enough contracts, and SEE ALL N and NEXT CASE work. I saw no emoji and no debug text on these screens.

## 3. Fix list

### P1
1. **Cap the player level at 100** (item 23, V7). In `Game.add_pxp` (`scripts/core/Game.gd:368`), the current mapping (reaching level L+1 grants row L) can stay, but stop at 100. When the row-100 XP (30,000) is earned at level 100, grant the row-100 reward (6M credits, 1L Warlord) as a "max level" milestone, set `S.player.maxed = true`, keep the level at 100 and clamp `xp`. `pxp_needed()` returns 0 when `maxed`, and `Main._refresh_hud` shows "MAX" in place of the bar. (How the rows map to levels is an open lever, because the GDD doesn't say whether row L is "to reach L" or "to leave L". Pick one and keep it at 100 levels.)

### P2
2. **Announce every unlocked feature** (item 31, V1). In `Main._announce_unlocks` (`scripts/ui/Main.gd:387`), loop over all of `fresh` and build one modal with a row per feature: tag, name, description, and a GO button per row (or one GO for the first). Alternatively, change `Game.take_new_unlocks` to return and mark only the first unseen feature, and call `_announce_unlocks()` again from the modal's LATER/GO/close handler so they chain.
3. **Rebuild the current screen when a level-up unlocks features** (V2). In `Main._announce_unlocks`, call `refresh()` (`current.rebuild()`) as soon as `fresh` is not empty, before opening the modal. A more general fix: emit a `Game.player_leveled(level)` signal from `add_pxp` and have Main call `refresh()` when `_cur_name in ["city", "fight"]`.
4. **Settle the "1x Energy" level reward** (item 22). Ask the user. If the refill is the "1x Energy" (my reading), filter the battery out in `Game.add_pxp` after `U.parse_rewards(row[2])`: `rewards = rewards.filter(func(r): return r.k != "battery")`, and change the mail body to "Energy refilled (1x Energy)". Leave Jobs and Shop "1x Energy" as batteries.
5. **Add a level-up card** (V3). Emit a `player_leveled(level, rewards)` signal from `Game.add_pxp`. In Main, show a modal like the unlock card: "PLAYER LEVEL N" in display type, "Energy refilled", the reward chips (`U.reward_label`/`reward_icon`) and a CLAIM button that claims that inbox mail. Queue it ahead of `_announce_unlocks`, with the same guards for battle, login, squad and coach.

### P3
6. **Move the toasts off the CTA row** (V4). `scripts/ui/Main.gd:66-67`: anchor `toast_box` with `PRESET_CENTER_TOP` and `position = Vector2(-220, 76)` (just under the HUD), or raise it to `-200` so it clears the 74 px CTA row and the nav.
7. **Show the full recruit name on the reveal** (V5). In `recruit.gd` `_reveal`, add `UI.disp(Game.tpl(best).name, 26, bcol)` centred under the `pull` label, or give `UI.warlord_card` a wider variant with no truncation for the 1.3x reveal.
8. **Move the pull label off the case lid** (V6). In `recruit.gd` `_reveal`, change `pull.offset_top = 290` to about `312` so it sits between the card (ends near y 305) and the case top (near y 375). If #7 adds a name line, push both down together.
9. **Stop the tween error** (V9). `scripts/ui/screens/recruit.gd:32`: change `var tw := create_tween().set_loops()` to `var tw := sign.create_tween().set_loops()` so the tween dies with the sign when the screen rebuilds.
10. **Fix the arena footer copy** (V8, item 28). `scripts/ui/screens/arena.gd:80`: change it to "Wins: +10 points, Credits & Pit Coin. Losing on defence costs 10/15/20/25 points by bracket." This is section 10's screen; flagged here because it states the rule from this section.
11. **Make currency purchases respect the caps** (items 5-7, cross-section with the Shop in section 15). "Heist Plan: 5x for 1000 Trinium" goes through `add_cur`, which clamps to 5, so a player holding plans loses the Trinium for nothing. Disable that row in `shop.gd` when `Game.cur("heist") > 0`, or at least warn. The Brawl/Royal refills can stack past 10. Decide whether 10 is a hard cap; if it is, add `"brawl": Data.PIT_CAP, "royal": Data.PIT_CAP` to `Game.CUR_CAP` and give the refill rows the same guard.

## Wave 1 applied (owner E: `Game.gd`, `Data.gd`)

Checked with `tests/review/12/Wave1.tscn` (new headless probe; all checks pass). TestRunner: failures 0, no script errors. UiSmoke finishes, but it shows errors from other owners' files that are still being edited: `city.gd` compile, `syndicate_wars.gd` parse, `district_map.gd:60` type inference, and `district_diorama.gd`, which calls `declutter`/`stage_name`. None of these are in Game.gd or Data.gd. I re-took my screenshots into `shots_12/`; the pre-fix set is now in `shots_12/wave0/`.

### What changed
- **API contract (all "E provides" names):**
  - `signal player_leveled(level, rewards)`: emitted once per level-up, after the mail is sent.
  - `S.player.maxed`; `pxp_needed()` returns 0 when maxed.
  - `bp_reroll_weekly(id) -> String`: one reroll per week, stored in `S.bp.wreroll`. It refuses claimed or inactive challenges.
  - `plaza_buy(i, hour = -1)`: if the hour is stale it shows "The Plaza restocked" and returns `[]`.
  - `Data.ability_max_level(a)` and `Data.ability_scales(a)`: return 1 for 25 of 143 player abilities, the ones where leveling changes nothing.
  - Every `NN_BY_ID` skill carries `max` (2 by default).
  - `S.gang.motd`.
  - `S.stocks.cap_bonus`.
  - `S.gang.bastion.boss_hp` and `.defeated`.
- **12 #1:** The player level now caps at 100. Row 100's 30,000 XP is a final "Max Player Level" milestone that grants 6M credits and a Legendary Warlord, then sets `maxed`. Old saves above level 100 are clamped in `_fix_types`.
- **12 #4:** Level rewards no longer add an Energy Battery. The full refill is the "1x Energy", and the mail now says "Energy refilled (1x Energy)". Jobs and Shop "1x Energy" are still batteries.
- **02 F1 / F6:**
  - Siphon 10, Wrath 65, Fracture 50, Adware 35 and Personal Ads 35 are now 1-point skills, with the GDD wording restored.
  - `nn_can` reads `sk.max` and checks "maxed" first.
  - Save migration refunds the extra point's fragments.
- **02 F2:** `feed_duplicate` and `use_stimm` now use `Data.ability_max_level`. The save migration clamps ability levels to that max.
- **03 #1:** Gloves primary is now `["fp"]` only.
- **04 #3:** The Vultures and Teratek descriptions now match the GDD.
- **10 P2-1:** Royal defence uses up to 7 defenders (4 + 3 reinforcements), 3 attacker reinforcements and `no_revive`.
- **10 P3-6:** The defence sim no longer replaces the opponent list the player sees (probe: list unchanged).
- **11 #2:** `stocks_level()`:
  - Level 1 from the start.
  - Level 2 and 3 once "Complete All Tier 1 / Tier 2 Campaign Ambitions" is claimed (`Data.STOCK_LEVEL_AMBITION`, an open lever).
  - New helpers `stocks_level_req(i)` and `stocks_cap()`. `STOCK_LEVEL_AT` is kept only because `city.gd` still reads it.
- **11 #5:**
  - Daily `boss_hp` is 1.2 x (your power + 14 NPC powers) x 40.
  - `defeated` is set when gang damage + your damage reaches it, with a toast, and resets each day.
- **11 #9:** Stocks accumulate up to `stocks_cap()`, which adds `cap_bonus`.
- **14 #4:** NPC member power is your squad power x k (k from 0.6 to 2.5). It grows with you each day and never shrinks.
- **14 #5:** When the Plaza stock rolls, gear and implant items get a fixed `r.slot` (and `r.set` for gear), and `grant` honours them. Probe: the bought item matched the shown slot and set.
- **14 #6 / #8:** `S.gang.motd` exists, including on old saves. NPC Bastion damage now applies on day one (`_npc_bastion_dmg`).
- **15 P1:** `bp_reroll_weekly`, as above.
- **15 P3-1:** The weekly "Rank up 2 Warlords" is now "Rank up a Warlord", n 1, as the GDD writes it.
- **16 P1 (Game.gd:1802):** The energy cost now reads "4 Energy" instead of the glyph.

### Skipped
- 12 #11 (HELD): no change to invite caps.

### Requests
- **C (Main / city):**
  - In `_refresh_hud`, show "MAX" (or full bar) when `S.player.maxed`. The level hex also clips "100" to "00" (`shots_12/30_city_lv_after_100.png`).
  - Connect `Game.player_leveled` for the level-up card (12 #5).
  - In `city.gd:209/216/219`, use `Game.stocks_cap()` in place of `Data.STOCKS[lv].cap`, and `Game.stocks_level_req(i)` in place of "unlocks at player level %d".
- **A (warlord.gd:894, 912):** Use `Data.ability_max_level(a)` in place of `Data.ABILITY_MAX_LEVEL[a.type]`. The neuronet pips and labels come from `sk.max`.
- **D (Content.gd:16):** Clamp enemy ability levels with `Data.ability_max_level(a)`.
- **F:**
  - `plaza.gd`: pass `int(Game.S.plaza.hour)` to `plaza_buy`, and show `r.slot` / `r.set` on gear cards.
  - Shop row that raises `S.stocks.cap_bonus`.
  - `gang.gd`: motd UI and a boss HP bar from `bastion.boss_hp` / `gang_dmg + my_dmg` / `defeated`.
  - `battle_pass.gd`: Reset button calling `bp_reroll_weekly`.
- **GDD_COVERAGE (coordinator), lines to add:**
  - "Player level: reaching L+1 grants row L; max level 100; row 100 is a max-level milestone."
  - "Stocks levels 2/3 unlock with the Tier 1/2 Campaign tier-completion ambitions (open lever)."
  - "Abilities with nothing to scale have max level 1."
  - "Gang NPC power scales from the player's squad; the Bastion boss pool is 1.2x the gang's expected damage."

### Wave 1: decided HELD items (applied)
- **04 #1, Hacker base Hacking (GDD literal):**
  - `Data.HACKER_BASE_HACK` is now `[0, 0]`. `Warlords._base_stats` already reads it, so it rolls 0.
  - The Hacker hack growth (`base.hack *= lvl_f(60) * rank_f(40)`) is removed from `Game.compute_stats`.
  - ClassProbe now, before B's armour/hack changes: hacker dmg per 1.0 mult vs 600 armour is 604-985 (armour 479-647, firepower 916-1211, modder 684-699). Mono-hacker 4 team: 100% win in 7-13 turns at W5-7, W10-1 and W10-7.
  - No `CLASS_SCALING.hacker` retune yet. Re-run `tests/ClassProbe.tscn` after B lands.
- **Caps:**
  - The `CUR_CAP` clamp in `add_cur` is removed, so rewards and purchases may overflow (probe: heist 5 + 3 = 8, bounty 15, brawl 20).
  - The daily refresh now tops up to the cap: heist `max(c, 5)`, bounty `max(c, 12)`, invites `max(c, 10)`. This keeps any purchased extras rather than wiping them. Energy regen still stops at 160.
- **12 #4:** Already applied: the refill only, with no battery.
- **15 P2-3:**
  - New `Game.shop_limit_key(section, i)`: Trinium Market limits are keyed by `U.day_id()` (daily), and pack limits stay lifetime.
  - New `Game.shop_bought_count(section, i)`.
- **No change:** login day 31, subscriptions, starter Neons, jobs count rule.

**Requests:**
- **F:** `shop.gd:65` reads `S.shop_bought["%s|%d"]` directly. Change it to `Game.shop_bought_count(sec, i)` so the "bought x/limit" display matches the daily Trinium Market limit.
- **D:** `Warlords._base_stats` needs nothing more for 04 #1, because it uses `Data.HACKER_BASE_HACK`, which is now 0. If it has other Hacker hack growth, remove it.
- **Coordinator:** In GDD_COVERAGE, replace the "Heist Plans ... unused ones lost / no longer stack past 5" and "Bounty Tokens" lines with "caps stop the daily refresh and regen; rewards and purchases may overflow (user decision)".

Compile: no script errors in the whole project. TestRunner: failures 0.

## Wave 2 applied (owner E)
- Added `Data.STOCKS_CAP_STEP := 25` and `Data.STOCKS_CAP_BUYS := 4`.
- Added `Game.buy_stocks_cap() -> String`:
  - Adds 25 to `S.stocks.cap_bonus`, up to 4 times.
  - Returns "The Stocks vault is fully upgraded." once all 4 are bought, otherwise "".
  - Shows a toast.
  - The caller (F's shop row) handles payment and confirmation.
- Probe (`Wave1.tscn`): 4 buys take the bonus to 100 and the cap to 140 at level 1. The 5th buy is refused.
- Compile: no script errors. TestRunner: failures 0. UiSmoke: done, no script errors.
