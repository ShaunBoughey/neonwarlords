# Fix wave 1: ownership and item lists

The coordinator assigns the fixes. Each owner edits **only the files it owns**. When a fix needs a change in someone else's file, use the API contract below. If the contract doesn't cover it, write it under "Requests" at the end of your report (`review/reports/<NN>_*.md`) and the coordinator will route it.

Item refs are `<report NN>:<item>`, from the "fix list" sections of `review/reports/*.md`. Unless your list says otherwise, apply P1, P2 and P3.

**HELD (do not apply; waiting on the user):**
- 05:#1 ARMOUR_K
- 05:#2 Hacking vs Firewall
- 04:#1 Hacker base Hacking
- 10:P3-1 / 12:#11 Pit invite cap
- heist overflow from rewards
- 13:#1 login Epic id
- 13:#6 jobs count only wins
- 13:Q1/Q2 GDD data cells
- 15:P2-4 subscriptions
- 15:P2-3 refill limit period
- 09:P3-1 starter Neons
- 06:#1 squad size (stays 4, the user agreed it earlier; the coordinator documents it)

GDD_COVERAGE.md edits are **coordinator only**. List any doc lines you want added in your report.

## Owners

| Owner | Session | Files it owns (only these) |
|---|---|---|
| A | gdd-01 | `scripts/ui/screens/warlord.gd`, `scripts/ui/item_view.gd`, `scripts/ui/screens/inventory.gd` |
| B | gdd-05 | `scripts/combat/Battle.gd`, `scripts/combat/battle_view_3d.gd`, `scripts/ui/unit_hud.gd`, `scripts/ui/hex_button.gd`, `scripts/ui/screens/battle.gd` |
| C | gdd-16 | `scripts/ui/ui.gd`, `scripts/ui/Main.gd`, `scripts/core/U.gd`, `scripts/ui/screen.gd`, `scripts/ui/coach.gd`, `scripts/ui/model_preview.gd`, `scripts/ui/screens/login.gd`, `settings.gd`, `city.gd`, `inbox.gd`, `events*.gd` |
| D | gdd-07 | `scripts/core/Content.gd`, `scripts/core/Warlords.gd`, `scripts/ui/screens/hideouts.gd`, `hideout_detail.gd` (delete), `data/gdd.json` |
| E | gdd-12 | `scripts/core/Game.gd`, `scripts/core/Data.gd` |
| F | gdd-15 | `scripts/ui/screens/shop.gd`, `battle_pass.gd`, `plaza.gd`, `gang.gd`, `recruit.gd`, `login_rewards.gd`, `safehouse.gd`, `missions.gd` |
| G | gdd-10 | `scripts/ui/screens/arena.gd`, `black_market.gd`, `syndicate_wars.gd`, `squad.gd` |
| H | gdd-06 | `scripts/ui/screens/campaign.gd`, `scripts/ui/district_map.gd`, `scripts/ui/district_diorama.gd`, `scripts/ui/screens/fight.gd` |

## Item lists

**A:**
- 01: #1-#13
- 02: F1 (warlord.gd parts only; read the max from `sk.max`), F2 (warlord.gd part, using `Data.ability_max_level`), F3, F4, F5, F7, F8 (warlord.gd), F12, F13, F14
- 03: #2, #3, #4, #6, #7, #9, #10
- 04: #2 (same as 03:#2), #6, #7
- 16: P2-6

**B:**
- 05: #3-#16
- 02: F9, F10, F11
- 03: #8
- 07: P1-2, P2-2 (same as 05:#10)
- 11: #1 (Battle.next_turn part), #6 (add `debuffs_on_boss` to Battle), #7, #12
- 08: #7 / 09: P3-6 (REPLAY cta)
- 06: #6
- 16: P2-1 (wet street), P3-1 (battle result tags)

**C:**
- 16: P1 (all except Game.gd:1802, which is E's), P2-2, P2-3 (Main pill, screen tabs, coach), P2-4, P2-5, P3-1 (ui.gd), P3-2 (login, settings), P3-3 (settings, events), P3-6, P3-7
- 12: #2, #3, #5 (Main side; the signal comes from E), #6
- 13: #2
- 15: P3-5, P3-6
- 14: P3-11 (city plaza sign)
- 11: #2 (city.gd text), #8 (Screen.header ellipsis), #15
- 08: #1 (the U.gd regex part)
- 10: P3-5

**D:**
- 07: all
- 08: #1 (the gdd.json part), #2, #3, #4, #5, #6, #8, #9, #10, #11
- 06: #2
- 11: #1 (BASTION_TURNS), #3, #4 (Content part), #6 (Content.finish uses `b.debuffs_on_boss`), #8, #10, #11
- 16: P2-3 (hideouts stage buttons), P3-4, P3-8
- Also: explain the Vikings stage 20 by day 13 vs Trolls stage 8 gap, and fix it with open levers.

**E:**
- 12: #1, #4 (refill reading), #5 (add the signal)
- 02: F1 (Data values, nn_can, save migration), F2 (`Data.ability_max_level` + Game usage), F6
- 03: #1
- 04: #3
- 10: P2-1, P3-6
- 11: #2 (stocks level read from claimed ambitions inside `Game.stocks_level()`; no new reward kind), #5 (Game part), #9 (Game part)
- 14: #1 (Game part), #4, #5 (Game part), #6 (store `S.gang.motd`), #8
- 15: P1 (Game part), P3-1 (Data.gd:290)
- 16: P1 (Game.gd:1802)

**F:**
- 15: P1 (button), P2-1, P2-2, P2-5, P2-6, P3-2, P3-3, P3-4, P3-7, plus the shop subtitle dev text (16:P3-2) and the battle_pass gold rule (16:P3-3)
- 14: #2, #3, #5 (card display), #6 (UI), #7, #9, #10, plus #1 (plaza.gd part)
- 13: #3, #4, #5, #7, #8, #9
- 12: #7, #8, #9, #11 (shop heist guard only)
- 11: #4 (gang.gd:39), #5 (UI), #14
- 16: P3-1 (shop, missions fonts)

**G:**
- 10: P2-2..P2-6, P3-2, P3-3, P3-4, P3-7
- 09: all P2, plus P3-2..P3-5 and P3-7
- 11: #13 (squad cost chip)
- 16: P3-1 (squad slot labels)

**H:**
- 06: #3, #4, #5, #7, #8, #9, #10, #11, #12, #15
- 16: P2-3 (district_map pins), P3-5

## API contract (cross-owner names: implement exactly, or code against them)

**E provides:**
- `Game.bp_reroll_weekly(id: String) -> String` (returns an error text, or "")
- `Game.plaza_buy(i: int, hour: int = -1)`
- `signal player_leveled(level: int, rewards: Array)` on Game
- `S.player.maxed`, and `Game.pxp_needed()` returning 0 when maxed
- `Data.ability_max_level(a: Dictionary) -> int`
- Neuronet skills carry `"max"` (default 2)
- `S.gang.motd: String`
- `S.stocks.cap_bonus: int`
- `S.gang.bastion.boss_hp` / `.defeated`

**D provides:**
- `Content.BASTION_TIERS[stage - 1]` (one table per stage), read via `Content.bastion_tiers(stage) -> Array`

**B provides:**
- `Battle.debuffs_on_boss: int`

**C provides:**
- `UI.reward_node(r, size)` as the single reward-icon path. Keep its signature.

## Rules
- Read `review/README.md` again: the rules still apply, except that you may now edit your owned files.
- Before editing a file, re-read it. Use Edit, never whole-file rewrites, and keep edits small.
- Compile-check with `--headless --path . --import | grep "SCRIPT ERROR"`. While wave 1 runs, errors in files you don't own may come from someone else's half-done work. Report them; don't fix them.
- When done:
  1. Run `res://tests/TestRunner.tscn` and `res://tests/UiSmoke.tscn` headless with your NW_SAVE.
  2. Re-take your screenshots and look at them.
  3. Append a "Wave 1 applied" section to your report: what you changed, anything skipped and why, and your Requests.
  4. Reply in 5 lines or fewer.

# Fix wave 2 (the user said go)

The owners and rules are the same as in wave 1.

1. **AUTO ×10 (B, G).** H has already added the button: `campaign.gd` sets `enc.repeat = 10` and calls `main.start_encounter(e)`.
   - **G:** make sure `squad.gd` passes `repeat` through to the battle untouched.
   - **B (`battle.gd`):** while `enc.repeat > 1`:
     - force auto on for the run;
     - after a **win**, if `Game.pay(cost)` succeeds, wait ~1.5 s and replay with `repeat - 1`; copy `repeat` across in `_replay`, because `Content.rebuild()` drops it;
     - show an "AUTO n/10" tag and a STOP button that sets repeat to 0;
     - stop on a loss, when energy runs out, or when STOP is pressed;
     - at the end, show one combined rewards summary if feasible.
2. **Top bar vs campaign difficulty tabs (H).** The energy pill overlaps the right end of the difficulty tabs ("WARLORD" is cut, see `shots_06` 03/04/07). Move or shrink the tabs in `campaign.gd` so they clear the HUD pills at 1920×1080 and at 4:3. Check the safe-area insets C added.
3. **Stocks cap upgrade.** This is the GDD's "additional caps being a microtransaction"; the price is an open lever.
   - **E:** add `Game.buy_stocks_cap() -> String`. It adds 25 to `S.stocks.cap_bonus`, up to 4 times (`Data.STOCKS_CAP_STEP := 25`, `Data.STOCKS_CAP_BUYS := 4`), and returns an error text or "".
   - **F:** add a "Stocks Vault +25 cap" row to the Trinium Exchange at GBP 1.99 (it follows the Free IAP setting like the other real-money rows). Disable it once all 4 are bought, and confirm before buying like the other real-money rows.
   - **C:** check that `city.gd` shows the new cap (`Game.stocks_cap()`).
4. **Hideout curve retune (D).** After the GDD armour constant (1518) and `DAMAGE_SCALE` 1.6 landed, the 30-day bot reached stage 19-20 on every hideout by about day 19, with an R5/R6 squad. Re-run `tests/HideoutProbe.tscn` and retune **only** `Content.hideout_level` (stages 11-20) and `boss_m`. Targets:
   - stage 10 needs an R5 squad;
   - stage 15 needs R6 for most hideouts;
   - stage 20 is ~50% for maxed R6 legendary+20, and under 15% for R6 epic+16.
   Also do report 12's Requests item: clamp enemy ability levels with `Data.ability_max_level(a)` at `Content.gd:16`.

When you're done: run the compile check, TestRunner and UiSmoke with your NW_SAVE, then append "Wave 2 applied" to your report and reply in 3 lines or fewer.
