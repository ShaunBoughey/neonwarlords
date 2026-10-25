# Section 10: The Pit and the Black Market (review)

Reviewer session: gdd-10. Code read: `Game.gd` (pit_*, _simulate_pit_defense, _defence_battle, _weekly_pit_rewards, open_cache, bm_*), `Content.gd` (pit_opponents, _pit_unit, build_pit), `Data.gd` (PIT_CAP, pit_loss), `data/gdd.json` (pitTiers, caches, blackMarket, shop), `U.gd` (parse_rewards), `arena.gd`, `black_market.gd`, `squad.gd`, `battle.gd`.

Probes (my own files, all under `tests/review/10/`):
- `Probe.tscn`: headless. Checks reward parsing, bracket boundaries, win and loss points, defence simulation, invite refills, weekly mail, 400 cache openings and every Black Market item bought twice.
- `Shots10.tscn` and `ShotsModal.tscn`: windowed screenshots. They also list every button on the Arena and Black Market screens with its connection count. All 18 Arena buttons and all 16 Black Market buttons have handlers.

Screenshots are in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_10\`.

## GDD items

| # | GDD item | Status | Evidence |
|---|---|---|---|
| 1 | Brawl Invites are needed to enter, capped at 10 | OK | `Data.PIT_CAP` is 10. `build_pit` costs `{mode: 1}`. Squad `_start` uses `Game.pay`, and the invite count went 6 to 5 after a fight. |
| 2 | Invites refresh daily | OK | `Game.tick` daily block sets `c.brawl = max(c.brawl, PIT_CAP)`. Probe: 3 became 10. |
| 3 | Invites can be earned from missions | OK | gdd.json jobs and ambitions grant "10x Pit Brawl Invites", and the parser reads it as `brawl`. |
| 4 | Invites can be bought with Trinium | OK | Shop "Pit Brawl Refill" and "Pit Royal Refill" cost 100 Trinium, limit 2. |
| 5 | Invites capped at 10 (when you get them from refills or rewards) | WRONG (minor) | `Game.grant` → `add_cur` doesn't clamp. In the probe, a refill took 15 invites to 25. GDD says "capped at 10". See fix P3-1: this is an open choice, since RAID lets refills overflow. |
| 6 | Defensive gang of 5 Warlords | DEVIATION | Team size 4 is documented in GDD_COVERAGE ("Team size 4"). |
| 7 | 10 opponent gangs from your skill bracket and ranking | OK | `pit_opponents` makes 10, with points = yours -60..+80 and strength scaled to your bracket. The screenshot shows 10 FIGHT rows. |
| 8 | You choose your attacking team | OK | FIGHT → `squad` screen (`squad_brawl.png`, `squad_royal.png`). |
| 9 | A win gives Pit Coin and ranking (Fight Rewards column) | OK | `pit_record`. Probe at 100/600/1500/3000 points: +10 pts and 10k/18k/26k/40k credits; 10/35/80/150 PC. All match the table. |
| 10 | 1-week ranking period, weekly rewards by bracket | OK | `tick` → `_weekly_pit_rewards` mails the bracket's cache for each mode. Probe: 1500 pts got 1x Sublime, 100 pts got 1x Meager. |
| 11 | You can move up brackets at any time | OK | `pit_tier` works from the live points. Boundaries are right: 199 is Runner, 200 Underling, 599 Enforcer, 600 Soldier, 3000 Neon Legend. |
| 12 | Ranking is lost only when your defence is beaten | OK (recent fix verified) | Probe: an attack lost at 500 pts stays at 500, logged "no points lost". Defence losses take `Data.pit_loss(tier)` (10/15/20/25). The GDD doesn't give that amount, so it's an open lever. |
| 13 | Defence is fought while you are away | OK for Brawl, WRONG for Royal | `_simulate_pit_defense` sends one attack per 4 h (max 4, 35% chance each) and runs a real `Battle` simulation. For Royal, `defenders.slice(0, 4)` and `_defence_battle` only use 4 attackers, with no reinforcements and no `no_revive`. So Royal defence plays as a Brawl. (Game.gd:1482, 1509, 1514) |
| 14 | Leaderboards show defence teams, weekly earned ranking and bracket | MISSING (defence teams) | `arena._board` shows rank, name, gang, bracket and points. No row shows or opens a defence team. Points are lifetime ranking, not weekly. The board is seeded locally (fine, since the game is offline). |
| 15 | Leaderboard filters: gang, friends, search players | OK | All, Gang and Friends tabs plus a search box and button. All work (`arena_brawl_leaderboard_gang.png`). |
| 16 | Royal: separate Royal Invites, cap 10, daily, missions, Trinium | OK | `cur.royal`, the same daily refill, and a shop refill. |
| 17 | Royal: 8 Warlords (5 + 3 reinforcements) | DEVIATION | 4 + 3, documented in GDD_COVERAGE. |
| 18 | A reinforcement takes a dead member's slot | OK | `Battle.gd:726-740` (both sides). `build_pit` gives the enemy 3 reinforcements. |
| 19 | NO REVIVES in Royal | OK for attack, WRONG for defence | `battle.gd:137` passes `no_revive: enc.royal`. The defence sim doesn't (see #13). |
| 20 | Reinforce abilities give a bonus when the unit enters | OK | `Battle._reinforce_fx` fires the `reinforce` ability when the unit enters. |
| 21 | Bracket table: 13 tiers, names, points, weekly caches, fight rewards | OK | `gdd.json pitTiers` matches the GDD exactly. |
| 22 | Meager Cache contents and chances | OK | Parsed correctly. Over 400 opens: contracts 51%, stimms 28%, credits 250k-498k, gear R4-5. |
| 23 | Substantial Cache | OK | Table matches, including the 20% chance of a Meager Cache. |
| 24 | Sublime Cache | OK | Table matches (`cache_open_modal_settled.png`: 6x R6 epic/legendary, 1.15M, 3x Rare Stimm, 1500 PC). |
| 25 | Exalted Cache | OK | Over 400 opens: contracts 67%, Sublime Cache 22%, credits 2M-2.5M, gear all R6 legendary. |
| 26 | Cache gear rarity mix ("Rare-Legendary") | OK (open lever) | Each piece is uniform across rare, epic and legendary (about 1/3 each). The GDD gives no weights. |
| 27 | Pit Coin is spent in the Black Market and Safehouse | OK | `bm_buy` and the Safehouse `spend("pitCoin")`. |
| 28 | Black Market: 16 items, prices, Daily/Weekly limits, Credits unlimited | OK | `gdd.json blackMarket` matches. Probe: each item buys once and its second buy is blocked. "250k Credits" can be bought again. Prices were deducted exactly. |
| 29 | Black Market items grant the right thing | OK | Lvl N Firmware gives Mk N Firmware. "Rank N Epic Equipment" and "Implant" give a random epic slot. 350 Energy can go over the cap (RAID-like). |

**Counts:** OK 23 (counting #13 and #19 as their OK parts), MISSING 1, WRONG 3 (Royal defence size/reinforcements, Royal defence revives, invite cap overflow), DEVIATION 2.

## Visual issues

The design canvas has no Pit artboard. I checked against the DesignSystem and Shop artboards: text at least 14px, notched panels, the catalogue pattern, and stroke icons.

1. **Fight tab: footer text contradicts the rule** (`arena_brawl_fight.png`). It says "Losses lose points by bracket." Since the fix, an attack loss costs no points. Only defence losses do.
2. **Fight tab: power colours are misleading** (`arena_brawl_fight.png`, `arena_royal_fight.png`). In Brawl every opponent is red. In Royal every opponent is green. `_fight` compares `o.power` (always normalised to 4 units) with `team_power(S.squads["pit_"+mode])`. That is the *defence* squad, and for Royal it sums 7 units.
3. **Leaderboard is bare text rows** (`arena_brawl_leaderboard.png`). There are no panels, no zebra striping, and your own row isn't pinned or highlighted beyond magenta text. You can't tap a row to see a defence team (GDD #14). Gang and bracket labels are 13px.
4. **Brackets tab is a bare grid** (`arena_brawl_brackets.png`). It fills only the left half of the screen, has no panels, and doesn't highlight your current bracket. It shows the raw GDD string "x10 Points, ...". All text is 13-14px.
5. **Text under the 14px minimum on the Arena**: opponent sub-line ("1315 pts • Lv 6 • Rank 3") is 12px, footer 13px, "Weekly cache" 13px, battle log 13px. "Weekly cache: 1x Meager Cache" wraps onto two lines.
6. **Royal Defence tab doesn't separate the 4 starters from the 3 reinforcements** (`arena_royal_defence.png`). The text says "last 3 are reinforcements", but the 7 cards are in one row. "Defence power" sums all 7, so it can't be compared with opponent power, which is shown for 4.
7. **Royal squad opens with empty reserve slots** (`squad_royal.png`). `squad.gd` seeds from `S.squads.royal`, which doesn't exist until your first Royal fight, so Reserve 1-3 start empty. You can start a Royal with only 4.
8. **Black Market: credits card shows "N/A"** as its limit tag (`bm_01.png`). That's raw GDD text. It should read "No limit".
9. **Black Market: naming mismatch.** Cards say "1x Lvl 3 Firmware" and the icon art says "MK 3". The reward and inventory say "Mk 3 Firmware".
10. **Black Market: price buttons spell out "PIT COIN"** instead of using the pit-coin stroke icon, which the HUD pill already uses. There's no category rail, which the design's catalogue pattern asks for. This is a P3 polish item.
11. **Cache reward modal: currency tiles use text glyphs** (`cache_open_modal_settled.png`). Credits shows "¢" where the HUD uses the © credit icon. Rare Stimm shows "+" where the Black Market uses stimm art. This comes from the `U.REWARD_ICON` fallback.
12. **No issues** in the Pit battle (`battle_brawl_start/mid.png`: street arena, the title shows the opponent and their points) or the result screen (`battle_brawl_result.png` shows "Lost to X (no points lost) • 1245 points (Diplomat)"). No emoji or debug text on any Pit or Black Market screen.

## Prioritised fixes

### P1: none
Nothing breaks the game. The recent "rank lost only on defence" fix is correct.

### P2

1. **Royal defence follows Royal rules.** In `Game._simulate_pit_defense`, keep the full `S.squads["pit_royal"]` list (up to 7). In `Game._defence_battle(mode, defenders, tier)`:
   - For royal, build attacker reinforcements from `opp.team.slice(4, 7)` with `Content._pit_unit(m, k, 0)`.
   - Split the defenders: `player_units(defenders.slice(0, 4))` as the wave and `player_units(defenders.slice(4, 7))` as reinforcements (side 1).
   - Call `b.setup(attackers, [defs], {"turn_limit": 0, "reinforcements": att_reinf, "enemy_reinforcements": def_reinf, "no_revive": mode == "royal"})`.
2. **Fix the stale rule text.** In `arena.gd _fight()`, change the footer to: "Opponents refresh hourly. Wins: +10 points, Credits & Pit Coin. A lost attack costs only the invite; points are lost when your defence is beaten."
3. **Make the power colours compare like with like.** In `arena.gd _fight()`, replace `var mine := Game.team_power(Game.S.squads["pit_" + mode])` with the attack squad's first 4: `Game.team_power(Game.S.squads.get("royal" if mode == "royal" else "last", []).slice(0, 4))`. Also move it out of the loop.
4. **Leaderboard shows defence teams (GDD MISSING).** In `arena.gd _board()`:
   - Give each seeded row a `team` (4 or 7 `tpl` ids from the same seeded `r`, picked from `Warlords.RECRUITABLE`). Use `Game.S.squads["pit_"+mode]` for "you".
   - Show 4 small `UI.portrait(tpl, 32)` per row, or open a modal with the team on click.
   - Put rows in `UI.panel()` and pin your own row at the top.
5. **Brackets tab styling.** In `arena.gd _brackets()`:
   - Put each tier in a notched `UI.panel` row at 14px or larger, full width.
   - Highlight the row where `row[0] == Game.pit_tier(points)` (gold border).
   - Show the per-win column as "+10 pts • 10K Credits • 10 Pit Coin" (format it from the parsed values, not the raw `row[4]`).
6. **Raise Arena text to 14px or more.** In `arena.gd`: the opponent sub-line (12 → 14), footer (13 → 14), "Weekly cache" label (13 → 14, and widen `iv` to about 280 so it fits on one line), battle log (13 → 14), and leaderboard gang and bracket labels (13 → 14).

### P3

1. **Invite cap (open lever).** Either clamp in `Game.add_cur` for `brawl`/`royal` (`min(PIT_CAP, ...)`, matching the GDD's "capped at 10"), or keep RAID-style overflow and add a line to GDD_COVERAGE. This is the user's call.
2. **Royal defence card layout.** In `arena.gd _defence()`, show cards 0-3, then a "Reinforcements" caption, then cards 4-6. Show "Defence power" for the first 4 only, so it matches opponent power.
3. **Seed the Royal squad.** In `squad.gd build()`, when `team_size == 7` and `S.squads.royal` is missing, fall back to `S.squads.pit_royal`, then to `last`.
4. **Black Market labels.** In `black_market.gd build()`:
   - Show `"No limit"` when `row[2] == "N/A"`.
   - Use `U.reward_label(rew[0])` for the card name, so it reads "1x Mk 3 Firmware".
   - Use the pit-coin `Icon` in the price button instead of the "PIT COIN" text.
5. **Cache and reward modal icons.** Make `UI.reward_node` use the same art and stroke icon as the Black Market and HUD for `credits`, `pitCoin` and `stimm`, not the `U.REWARD_ICON` glyphs.
6. **Defence sim side effect.** `_defence_battle` calls `Content.pit_opponents(mode)`. When that list is more than 1 h old, this silently regenerates the opponents the player sees. Generate a separate attacker instead, without writing to `p.opps`.
7. **Stale doc comment** at `arena.gd:2` ("Brawls (5v5) and Royals (5 + 3 reinforcements)"). Change it to 4v4 and 4 + 3.

## Wave 1 applied

Owner G (gdd-10). Files edited: `arena.gd`, `black_market.gd`, `squad.gd` (and `syndicate_wars.gd`, covered in report 09).

**Changed**
- **P2-2** `arena.gd _fight()`: the footer now says "A lost attack costs only the invite; points are lost when your defence is beaten". It is 14px and wraps.
- **P2-3** `arena.gd _fight()`: power colours now compare against the attack squad's first 4 (`squads.royal`, falling back to `pit_royal`, or `squads.last`). This is computed once, outside the loop.
- **P2-4** `arena.gd _board()` and new `_board_row()`:
  - Each row shows a 4-portrait defence team. Seeded rows get a seeded team, and your row shows your `pit_<mode>` squad.
  - Rows are notched panels. Your row is pinned above the list with a magenta panel.
  - Text is 14-16px.
- **P2-5** `arena.gd _brackets()`:
  - The table is now full-width notched panel rows with a header row.
  - Your current tier is highlighted gold.
  - Per-win reads "+10 pts • 10K Credits • 10 Pit Coin", formatted from the parsed values.
- **P2-6**: Arena text is now at least 14px (opponent sub-line, footer, weekly cache, battle log, leaderboard). The info column is 360 wide, so "Weekly cache" no longer wraps. I also shortened the subtitle to "Weekly reset Xh", because the new header ellipsis was cutting it.
- **P3-2** `arena.gd _defence()`: a purple "Reinforcements" caption now separates cards 4-6, and "Defence power" counts the first 4 only.
- **P3-3** `squad.gd build()`: a first Royal starts from `pit_royal` (falling back to `last`), so the reserve slots are filled.
- **P3-4** `black_market.gd`:
  - "N/A" now reads "No limit".
  - Card names use `U.reward_label`, so they read "1x Mk 3 Firmware".
  - Price buttons show the pit-coin stroke icon plus the amount; "PIT COIN" text is gone.
  - The subtitle is shortened to "Daily Xh • Weekly Xh".
- **P3-7**: the `arena.gd` doc comment now says 4v4 and 4 + 3.
- **16:P3-1** `squad.gd`: slot labels are 12px (were 11px). The 9px star is inside `UI.warlord_card`, which is owner C's.
- **11:#13** `squad.gd`: the Bastion START chip reads "1 Entry", or "1 Raid Ticket" once entries are 0. Pit invite costs now use the mail icon, matching the reward icons.

**Skipped**
- P2-1 and P3-6 belong to owner E (Game.gd).
- P3-1 (invite cap) is HELD.
- P3-5 belongs to owner C.

**Verified**
- `tests/review/10/ShotsW1.tscn` screenshots are `shots_10/w1_*.png`: arena tabs for both modes, Black Market, Syndicate Wars, and the squad screen for SW, Royal and Bastion.
- My 4 scripts load and compile.
- TestRunner: failures 0. UiSmoke: done.
- The remaining SCRIPT ERRORs are all in other owners' in-progress files: `district_map.gd:60`, `district_diorama.gd`, `battle_view_3d.gd`, `model_preview.gd`, `city.gd`. They make `squad.gd` report a dependency compile error at load, but the squad screen renders.

**Requests**
- Coordinator, GDD_COVERAGE: "Pit leaderboard is seeded locally (offline); defence teams are shown as seeded portraits. Points are lifetime ranking, not weekly."

## Wave 2 applied

- **Item 1 (AUTO ×10), G part:** no code change was needed. `squad.gd _start()` passes the same `enc` dictionary to `main.replace("battle", {"enc": enc, ...})`, and it never rebuilds or filters `enc`, so `repeat` arrives untouched.
- **Verified:** `tests/review/10/RepeatProbe.tscn` builds a campaign encounter with `repeat = 10` and starts it through the squad screen. It printed `REPEAT squad screen: 10` and `REPEAT battle screen: battle 10`.
- **Checks:**
  - Compile check: no SCRIPT ERRORs.
  - TestRunner: failures 0.
  - UiSmoke: done, with no SCRIPT ERRORs.
