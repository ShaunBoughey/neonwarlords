# Review 13: Monthly Login Rewards, Jobs, Ambitions, Safehouse

How I checked:
- `tests/review/13/compare13.py`: compares every login, job and ambition cell in the GDD text with `data/gdd.json`. Result: 0 mismatches (31 login days, 8/7/7 jobs, 192 ambition rows).
- `tests/review/13/Probe13.tscn` (headless, NW_SAVE=13):
  - parses every reward string with `U.parse_rewards`: 0 unparsed pieces;
  - matches every ambition description to a progress rule in `Game.ambition_progress`: 0 without a rule;
  - checks every hideout name, set, slot, primary stat and class: all valid;
  - runs the jobs, safehouse and login flows end to end.
- `tests/review/13/Shots13.tscn` (windowed): screenshots, and a button and handler census of each screen.

Screenshots are in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_13\` (written below as `shots_13/`).

**Counts: 25 OK (the table rows group the 192 ambition rows and 22 jobs, which all check out), 1 WRONG, 1 MISSING (optional feature), 0 DEVIATION.** I also raise 2 GDD questions (table typos). I have not flagged them as bugs.

## 1. GDD items

### Monthly Login Rewards
| # | GDD item | Status | Notes |
|---|---|---|---|
| L1 | 31-day table (20K Credits ... Epic Warlord, plus 4 N/A cells) | OK | `gdd.json.login` matches the GDD cell for cell. Every reward parses (for example "Rare T3 Gear Piece" gives Rank 3 Rare Equipment and "Firmware lvl 2" gives Mk 2 Firmware). |
| L2 | Progress only on login; a missed day does not reset or delete progress | OK | `Game.claim_login` advances `S.login.progress` only when the player claims. `_check_login` only reopens the claim on a new day. Claiming twice on one day returns []. |
| L3 | Month 1 releases **a specified Epic Warlord** for everyone | **WRONG** | `Game.gd:1055` (grant, "warlord") gives `U.pick(Warlords.by_rarity("epic"))`, so each player gets a random Epic. The probe got Quartermaster Venn on one run and Dr. Lysa Vohn on another. The GDD says it is a specified Warlord that everyone gets. |
| L4 | After some months it becomes a rolling reward | OK | `login_index()` = progress % 31, so the table loops. The GDD does not say how many months the specified Epic runs before rolling (open lever). |
| L5 | Optional: randomise the groupings per month (for example energy on yellow in month 1, XP in month 2) | MISSING | The GDD calls this an "additional feature". Low priority. |

### Jobs and Rewards
| # | GDD item | Status | Notes |
|---|---|---|---|
| J1 | 8 daily jobs: targets 3 brawls, 10 dens, 1 Plaza buy, 3 recruits, 3 items to 8+, 1 level, 3 hideout items, all | OK | `Data.JOB_DEFS.daily` matches. Every event has a `track()` call: pitBrawl `Game.gd:1455`, den `Content.gd:451`, plazaBuy `Game.gd:1574`, recruit `Game.gd:991`, equip8 `Game.gd:827`, warlordLevel `Game.gd:453`, hideoutEquip `Content.gd:236`. |
| J2 | Daily rewards (100 XP + item + 10k; the all-jobs reward is 300 XP, 50 Trinium, 50K) | OK | All 8 parse exactly. XP is granted as Player XP. |
| J3 | 7 weekly jobs and rewards (all dailies x5, 20 brawls, rep up, 15 hideout items, rank 3, 3 items to 12+, all) | OK | Targets and rewards match. "Complete all Daily Jobs" counts claims of the daily all-jobs job (`claim_job`, `track("dailyAll")`). Verified: the weekly counter went 0 to 1/5. |
| J4 | 7 monthly jobs and rewards (dailies x30, 150 brawls, 400 dens, rank 5, 3 items to 16, 100 hideout items, all; 3200 XP, Epic Contract, 1M) | OK | Match. |
| J5 | The daily, weekly and monthly "Complete All" jobs | OK | Targets are 7, 6 and 6 (every other job in the period). Progress = the other jobs claimed. |
| J6 | Daily, weekly and monthly reset | OK | `_check_job_periods` clears both counters and claims when `day_id`, `week_id` or `month_id` changes. |
| J7 | "1x Energy" reward | OK | Granted as 1 Energy Battery (the refill item). This is a reasonable reading of the GDD. |
| J8 | "Complete N Den battles" and "Complete N Pit Brawls" | OK | Losses count too (`Content.finish` tracks "den" before `if won`; `pit_record` tracks "pitBrawl" on both outcomes). The GDD says "Complete", so this is an open lever (see P3-6). |

### Ambitions (192 rows, 6 categories)
| # | GDD item | Status | Notes |
|---|---|---|---|
| A1 | Campaign: 33 rows, Den 1-10 stage 7 on Street Punk, Mob Boss, Warlord | OK | Rows identical. Progress = stars on (diff, den-1, stage index 6). There are 10 dens in the data. |
| A2 | Hideout: 36 rows, stage 10/15/20 x 20 wins (Heist x 5) | OK | All 10 hideout names resolve to a valid `Content.HIDEOUTS` id. Wins count at or above the stage. |
| A3 | Equipment: 36 rows (gain set+slot+primary; sell 10/50/100; level 6 items to 4/12/16; equip sets and full sets) | OK | All 8 "Gain X Set <slot> with <stat> Primary" combinations can drop (checked against `SLOT_STATS`). `_check_equipment_ambitions` records every generated item. |
| A4 | Reputation: 33 rows (gain 10 deeds per alignment and tier; raise rep 1-6 per alignment) | OK | Deed counters come from `grant` (`Game.gd:1048`). Rep progress is the best Warlord of that alignment. |
| A5 | Warlord: 27 rows (recruit 25/50, level 10 Warlords to 10/30/50, rank 10 Warlords to 2/4/6, consume, level a class to 30/40/60) | OK | Classes armour, firepower, modder and hacker all resolve. |
| A6 | Bastion & Pit: 27 rows (damage 10m/50m/150m, boss debuffs, entries, turns survived, pit entries, kills, debuffs, Safehouse level 1/5/10) | OK | Stats: `bastion_dmg`, `bastion_debuffs`, `bastion_entries`, `bastion_turns_best`, `pit_entries`, `ev_pitKill`, `pit_debuffs`, `safehouse_max_level`. |
| A7 | "Complete All Tier N" reward (Rare, Epic, Legendary Contract) | OK | Progress = the other rows in that tier claimed. The case difference ("All" vs "all") is handled in `ambitions_list`. |
| A8 | Tiered lifetime progression | OK | Tier N+1 appears once every row of tier N is claimed. Counters are lifetime, so progress made earlier carries over. |
| A9 | All rewards (energy, XP boosts, deeds, R4/5/6 Epic gear and implants, Trinium, Heist Plans, firmware 3/4/5, credits, Brawl Invites, Pit Coin, Memory Fragments) | OK | 0 unparsed pieces across all 192 rows. |

### Safehouse Upgrade
| # | GDD item | Status | Notes |
|---|---|---|---|
| S1 | Location on the City Centre hub | OK | City sign "Safehouse" (`city.gd:79`). Unlocks at Player Level 10 (`FEATURE_UNLOCK`, open lever). |
| S2 | Nodes for each core stat, split by morality | OK | 3 alignments x 6 nodes (`Data.SAFEHOUSE_NODES`). Bonuses apply only to player Warlords of that alignment (`compute_stats`, `enemy_bonus <= 0`). |
| S3 | Pit Coin costs 100/225/350/475/600/725/850/975/1,100/1,250 | OK | `SAFEHOUSE_COST` matches. Two nodes taken 0 to 10 spent 13,300 Pit Coin, exactly 2 x the table total. An 11th upgrade returns "Max level.". Too little Pit Coin returns "Requires 100 Pit Coin.". |
| S4 | HP, Armour, Firepower and Crit Damage: 1/2/3/4/6/8/10/14/16/20% | OK | `SAFEHOUSE_PCT` matches. Verified: HP 1065 to 1278 (+20%) at level 10. Crit Damage is added as +N percentage points. |
| S5 | Hacking and Firewall: 2/4/6/8/12/16/20/28/32/40 | OK | `SAFEHOUSE_FLAT` matches. Verified: Hacking 0 to 40 at level 10. |

### GDD questions (not bugs; for the user to decide)
- **Q1, Hideout ambitions order 11** (all 3 tiers): "Beat Hideout **Paragon Deeds** Stage N, 20 Times" repeats order 8 word for word, with a Memory Fragments reward. The Generic Deeds hideout (`deeds_generic`, The Archivist) has no ambition, so order 11 was probably meant to be **Generic Deeds**. As written, finishing order 8 also finishes order 11.
- **Q2, Warlord ambitions tier 3 order 1**: "Recruit 50 Warlords" is the same as tier 2. It completes automatically when tier 3 opens. Was 100 intended?

The code follows the GDD exactly in both cases. I propose no change until the user answers.

## 2. Visual review

Every button on these screens has a handler. The census listed no unhandled button and no dead button. Checked:
- the rail tabs (3 job periods and 6 ambition categories);
- CLAIM, IN PROGRESS and CLAIMED;
- CLAIM DAY N and CLAIMED TODAY;
- the 18 Safehouse upgrade buttons (disabled when Pit Coin is short, MAX at level 10);
- the reward modal's COLLECT and ✕;
- Back, which returns to the previous screen.

The city Missions badge = `jobs_claimable() + ambitions_claimable()`. The rail shows "N ready".

| # | Issue | Screenshot |
|---|---|---|
| V1 | The reward chips on Missions and the "Job Complete" modal use Unicode glyphs from `U.REWARD_ICON` (★ ¢ ◆ ▤ ⇮ ✉) instead of the stroke `Icon` set. ✉ (Brawl Invite) renders as a **colour emoji envelope** in the modal. ⇮ (XP Boost) is a tiny arrow. The design rule is stroke icons only, no emoji. | `shots_13/03_missions_claim_modal.png`, `01_missions_daily.png` |
| V2 | Text is below the design system's 14px minimum on all three screens: reward chips 12px and the "PROGRESS" caption 11px (Missions), the day caption 11px and the reward text 12px (Login), the bonus line "+1%" 12px (Safehouse). | `01_missions_daily.png`, `06_login_unclaimed.png`, `11_safehouse_levels.png` |
| V3 | The login day 31 card shows a generic "users" icon and "Epic Warlord". RAID headlines the month's champion with a portrait. This depends on L3. | `06_login_unclaimed.png`, `09b_login_day31_modal.png` |
| V4 | The login cards show raw GDD text ("1x Firmware lvl 2", "2 x Energy Battery", "1x XP Boost"). Elsewhere the same items are called "Mk 2 Firmware" and "100% XP Boost", and spacing ("2 x" vs "2x") is inconsistent. | `06_login_unclaimed.png` |
| V5 | After day 31 is claimed, progress wraps to 0 (31 % 31). For the rest of that day the calendar shows no ticks, while the button says CLAIMED TODAY. | logic in `login_rewards.gd` build |
| V6 | Up to 3 gold CLAIM buttons show at once on Daily. The design system says gold is the one forward action per screen. | `01_missions_daily.png` |
| V7 | The Safehouse panels leave the lower ~40% empty. They show no next-level preview (for example "+2% next"). Level 0-10 is a count, but it uses a smooth bar where the design system calls for a segmented meter. "1 Warlords benefit" is not singular. | `11_safehouse_levels.png` |
| V8 | The Monthly tab says "Jobs reset at the start of next month." with no countdown. Daily and weekly have one. | `02_missions_monthly.png` |

The pages are otherwise clean: no clipped or overflowing text, no debug or placeholder text. The ambition rows read well (`04_amb_*.png`). The rail matches the "Catalogue" pattern, and the reward modal matches the design system.

## 3. Prioritised fixes

**P1**
1. **Login day 31 must be a specified Epic Warlord (L3, V3).**
   - `Data.gd`: add `const LOGIN_EPIC := ["<tpl_id>"]`, one Epic template id per month. The ids are an open lever, so ask the user which Warlord, and after how many months the table rolls.
   - `Game.claim_login`: when `text == "Epic Warlord"`, grant `add_warlord(Data.LOGIN_EPIC[min(int(S.login.progress) / 31, LOGIN_EPIC.size() - 1)])` instead of the parsed random-epic reward. Keep the rest of `grant` for the other days.
   - `login_rewards.gd` build: on the "Epic Warlord" card, render that template's portrait and name (the same portrait node the recruit and roster cards use) instead of `UI.reward_node`.

**P2**
2. **Stroke icons in reward chips and the reward modal (V1).**
   - `ui.gd` `reward_chips`: replace the glyph `chip(U.reward_icon(r), …)` with the icon from `reward_node(r, size + 6)`. That map already uses `Icon.make` (coin, diamond, bolt, mail, up, ticket, case, users …).
   - `Main.gd` `show_rewards`: when an entry has no `equip`/`warlord` art, build its tile from `UI.reward_node` rather than the `icon` glyph string.
   - Remove ✉ from `U.REWARD_ICON` so no emoji fallback is left.
3. **Raise text to at least 14px (V2).**
   - `missions.gd` `_row`: `UI.reward_chips(rewards, 12)` to 14, and `UI.lbl("PROGRESS", 11, …)` to 13 as a caption (or 14).
   - `login_rewards.gd` build: `UI.cap("Day %d", …, 11)` to 13, and the reward `UI.lbl(text, 12, …)` to 14.
   - `safehouse.gd` build: the bonus line `UI.lbl("+%d…", 12, …)` to 14.

**P3**
4. `login_rewards.gd` build (V4): show `U.rewards_text(rew)` on each card instead of the raw GDD `text`, so names match the rest of the game.
5. `login_rewards.gd` build (V5): base the display on `var shown := int(Game.S.login.progress) - (1 if claimed_today else 0)` and `cur_i := shown % total`. Mark days `i <= cur_i` as done when `claimed_today`, so day 31 stays ticked on the day it is claimed. Also remove the unused `done` variable.
6. `Content.finish` and `Game.pit_record` (J8, open lever): if "Complete" should mean a win, move `Game.track("den", 1)` inside `if won` and `track("pitBrawl", 1)` inside `if won:`. Ask the user first, because the current reading (every finished battle counts) is also valid.
7. `missions.gd` `_ambitions`/`_jobs` (V6): keep gold only for the first claimable row and draw the others with the cyan "primary" style. Or add one gold "CLAIM ALL" in the header and make the row CLAIM buttons cyan.
8. `missions.gd` `_jobs` (V8): add `U.secs_to_next_month()` (next 1st of the month, 00:00 local, the same basis as `U.month_id`) and show "Jobs reset in …" for monthly too.
9. `safehouse.gd` build (V7):
   - use "Warlord" when `count == 1`;
   - add "Next +X%" under each node from `SAFEHOUSE_PCT[lv + 1]` / `SAFEHOUSE_FLAT[lv + 1]`;
   - replace `UI.bar(lv, 10, …)` with a 10-segment meter;
   - put a short totals block in the empty lower area of each panel (for example "Total: +X% HP, +Y Hacking").
10. GDD questions Q1 and Q2: ask the user. If they confirm, edit only those cells in `data/gdd.json`: order 11 becomes "Beat Hideout Generic Deeds Stage N, 20 Times", and tier 3 recruit becomes the value the user gives. `_hideout_id_from_name` already maps "Generic Deeds" to `deeds_generic`.
