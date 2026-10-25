# Review 11: Bastions ("Assault on TeraTek Cybernetics") and Trinium Stocks

GDD text: `review/gdd/11_bastions-stocks.txt`. Probe and screenshot scripts: `tests/review/11/` (`Probe11.tscn` headless, `Shots11.tscn` windowed, both run with `NW_SAVE=11`). Screenshots are in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_11\`. Both runs logged 0 `SCRIPT ERROR`.

Most of the GDD's Bastion section is an empty template: boss names, abilities, minions, strategies and reward tables are all blank. GDD_COVERAGE line 47 says these were "designed to fit". In this report, those designed parts are checked only against the template's *shape* (2 ATK + 2 PASV per boss, one side minion with ATK1 + PASV1, one rewards table per stage).

## Probe results (headless, `tests/review/11/probe11.gd`)

| Check | Result |
|---|---|
| Stocks level by player level 1 / 19 / 20 / 40 | 1 / 1 / 2 / 3 |
| Stocks: 3 days offline at Lv 3 | stored = 75 (cap holds) |
| Bastion boss HP: S1 / S2 / S3 | 224,460 / 234,720 / 489,780 |
| Damage per entry, team of five Lv 60 Rank 6 with epic +gear (3 seeds per stage) | S1 30-45K, S2 32-43K, S3 33-34K. Every run hits the turn limit (`timeout`), and the boss never drops below 75% HP. |
| Same, weak team (Lv 20 Rank 3) | 15K |
| `player_turns` at the end of a full run | **21** (limit is 20) |
| Entries | 3 a day. The 4th `pay` is refused with the correct message. Raid Boss Tickets are used next. |
| Rewards at max damage | All 6 tiers stack (cumulative), the same for every stage |

## GDD items

### Bastions

| # | GDD item | Status | Notes |
|---|---|---|---|
| B1 | Gang-wide activity: everyone combines damage | OK | `Game.bastion_record` (Game.gd:1788) adds to `my_dmg`. NPC members add `gang_dmg` at each reset (`_daily_gang`, Game.gd:1784). The Gang screen shows both. |
| B2 | Each Bastion lasts 3 days, one stage per day | OK | `stage = day_id % 3 + 1` (Game.gd:1768, 1778). |
| B3 | At each daily reset, rewards are paid by damage dealt | OK | `_daily_gang` mails `Content.bastion_rewards(stage, my_dmg)` to the inbox (Game.gd:1776-1777). |
| B4 | The next stage begins after the reset | OK | Game.gd:1778-1783 resets damage and entries. |
| B5 | "Even when fully defeated, players are still able to enter to deal damage" | MISSING (partial) | Entering always works, but the gang can never defeat the Bastion: there is no shared boss HP pool, no "defeated" state and no progress bar. `gang_dmg` is only a number. Boss HP inside one battle (224K-490K) has no link to a gang-wide pool. |
| B6 | "Everyone can achieve max rewards if they deal enough damage" | WRONG (tuning) | Content.gd:386 sets the top tier at 280K. A strong late-game team deals about 35K per entry, so 3 entries make about 105K a day. Max rewards need about 8 entries' worth, so in practice nobody reaches them. The thresholds were designed (the GDD tables are blank), so this is an open lever. |
| B7 | Bastion name "Assault on Teratech's Cybernetics" | OK | Shown as "Bastion: Assault on TeraTek Cybernetics" (the project uses the TeraTek spelling everywhere). |
| B8 | Stage names: The Atrium / The Foundry / Head of the Hydra | OK | `Content.BASTION_STAGES` (Content.gd:370). |
| B9 | Each boss has ATK1, ATK2, PASV1, PASV2 | WRONG (shape) | Warlords.gd:407-423. Foundry Titan fits (2 ATK + Forge Heart + Bring It On). Atrium Sentinel has 2 ATK + 1 PASV and no PASV1. HYDRA has 3 ATK (Hydra Bite, Hostile Merger, Regrow) + 1 PASV and no PASV1. |
| B10 | PASV2 "Bring It On": immune to STUN, SHOCK, STUPEFY, TM manipulation, INCREASE COOLDOWN, ENRAGE (all 3 bosses) | OK | All three carry `IMMUNE_BOSS_TM` = stun, shock, stupefy, cdIncrease, enraged, tm (Warlords.gd:88). The rules engine enforces it at Battle.gd:817, 849 and 1151. |
| B11 | Side minion: one minion with ATK1 + PASV1 | WRONG (shape) | `build_bastion` (Content.gd:381) fields 3 generic TeraTek gang members (bruiser, medic, netrunner). They are reused campaign mobs and none has a Bastion passive. |
| B12 | "Possible Victory Strategies" | OK (blank in GDD) | The Gang screen lists the boss's abilities, which covers the need. |
| B13 | A separate Rewards Table for each stage | WRONG (shape) | `bastion_rewards(stage, dmg)` (Content.gd:388) ignores `stage`. All three stages share `BASTION_TIERS`, even though the Stage 3 boss has 2x the HP. |
| B14 | Reachable from the UI | OK | Battle hub "Bastion" card goes to `gang` (fight.gd:28,48). The Events card goes to `gang` (events.gd:13). The Gang tab in the bottom nav has an entry-count badge (Main.gd:253). ATTACK goes to the squad screen, then the battle, then the result screen. |
| X1 | (Cross-section 13) Ambitions "Survive 30 / 45 Turns Inside a Bastion" | WRONG | `BASTION_TURNS = 20` (Content.gd:375). Battle.gd:312 ends the fight when `player_turns > 20`, so the stat can never pass 21. The Tier 2 and Tier 3 ambitions can never be completed. Off by one: `bastion_turns_best` records 21 (probe). |
| X2 | (Cross-section 13) "Apply N Debuffs to a Bastion Boss" | WRONG | Content.gd:467 passes `b.debuffs_placed_by_player`, which counts debuffs on all enemies, minions included. |
| X3 | Damage dealt counts toward rewards | OK (note) | `damage_to_side(1)` includes damage to the minions (Content.gd:466). RAID counts boss damage only. Fine as long as the tiers are tuned with this in mind. |

### Trinium Stocks

| # | GDD item | Status | Notes |
|---|---|---|---|
| S1 | A location in the city | OK | City signboard "Trinium Stocks" (city.gd:81) opens a modal with levels, a fill bar and a Collect button (city.gd:211). |
| S2 | Daily Trinium 22 / 44 / 66 at Lv 1 / 2 / 3 | OK | `Data.STOCKS` (Data.gd:261). Accrues continuously at daily/86400 per second (Game.gd:258-263). |
| S3 | Max level 3 | OK | |
| S4 | Caps 40 / 60 / 75 | OK | Applied per level (Data.gd:261). The probe confirms 75 after 3 days offline. |
| S5 | "Additional caps being a microtransaction" | MISSING | The Shop has no offer to raise the Stocks cap, and nothing reads an extra cap. |
| S6 | "Additional Stocks levels are gained through player progression missions" | WRONG | Levels unlock at player level 1 / 20 / 40 (`Data.STOCK_LEVEL_AT`, Data.gd:262; `Game.stocks_level`, Game.gd:383). The GDD ties them to progression missions (Ambitions are the GDD's "overall mission progression", section 13). |

**Counts:** OK 14 / MISSING 2 (B5 partial, S5) / WRONG 7 (B6, B9, B11, B13, X1, X2, S6) / DEVIATION 0.

## Visual issues

| # | Issue | Screenshot |
|---|---|---|
| V1 | Bastion battle top text is a single plain label that runs under the ROUND chip and the settings hex: "...in 20 turns TURNS 0/20 DAMAG" is clipped. The turns and damage counters are the most important Bastion numbers, and they are the ones cut off. | `shots_11/21_bastion_battle_start.png`, `22_bastion_battle_mid_2.png` |
| V2 | The Bastion battle has no boss HP bar or damage counter of the kind RAID shows for a clan boss (a big bar at top, running damage). The boss gets only the same small vertical bar as the minions. "ROUND 1 OF 1" is meaningless here. | `21_bastion_battle_start.png` |
| V3 | Squad screen: the long title "BASTION: ASSAULT ON TERATEK - HEAD OF THE HYDRA" pushes the currency bar off-screen, and the Trinium "300" is clipped at the right edge. | `20_squad_bastion.png` |
| V4 | Squad START cost chip shows only a ticket glyph and "1". Nothing says it costs a Bastion Entry, or a Raid Ticket once entries run out. | `20_squad_bastion.png` |
| V5 | Result screen: warlord names are truncated ("Deacon Cha", "Shogun Ra", "Pontiff Ruc"). The REPLAY chip reads "Replay • 1" with no unit. The loot tray says "No item drops this time.", which is misleading for a Bastion because rewards come by mail. | `23_bastion_result.png` |
| V6 | Gang screen: boss abilities are printed as debug-style lines ("[ACTIVE] Security Sweep: ..."), unlike the ability cards used elsewhere. There is no boss HP or progress bar for the gang (see B5). The three stage tiles leave about 40% of the row empty. | `10_gang.png`, `11_gang_stage3.png` |
| V7 | Gang screen tier chips look the same whether reached or not (both pass `""` as the icon). Already reported as V4 in report 14. "Gang damage: 0" on day one is report 14 V8. | `24_gang_after.png` |
| V8 | The Stocks modal always shows "Collect" enabled, even with 0 stored or at Stocks Lv 0. Clicking it closes the modal and nothing happens. | city.gd:221 (screenshot `03_stocks_modal_lv1_empty.png` caught the fade-in) |
| V9 | Fight-hub Bastion card art is the shared silhouette placeholder. The design canvas expects boss key art here ("renders replace silhouettes"). This is shared with the other cards. | `10_fight.png` |

The city sign, the Stocks modal (`02_stocks_modal.png`) and the Events card are clean: no emoji, no overflow, and they match the canvas style. Every button tested routes correctly: Bastion card, Events card, Gang tab, ATTACK, START, BACK, REPLAY, Stocks sign, Collect and the modal close.

## Prioritised fix list

### P1
1. **Bastion turn cap makes the ambitions impossible (X1).**
   - `scripts/core/Content.gd`, `build_bastion()`: the 20-turn limit is not in the GDD (open lever). Set `BASTION_TURNS` to at least 50 so "Survive 45 Turns" can be done. Alternatively, follow RAID's clan boss and drop `turn_limit`, letting the fight run until the team dies, with `max_turns` as the safety cap. That way "survive N turns" actually measures survival.
   - `scripts/combat/Battle.gd`, `next_turn()` (line 312): check `player_turns >= turn_limit` *before* incrementing, or decrement on timeout, so `player_turns` never reports limit+1 (it gives 21 today).
2. **Stocks levels come from player level, not progression missions (S6).**
   - `scripts/core/Data.gd`: replace `STOCK_LEVEL_AT` with a mapping to ambition milestones. Which ambition is an open lever; a suggestion is "Complete all Tier 1 / Tier 2 / Tier 3 Campaign Ambitions" for Lv 1 / 2 / 3 (Lv 1 can stay free from the start).
   - `scripts/core/Game.gd`, `stocks_level()`: read from a stored `S.stocks.level` that the ambition claim raises (add a `"stocksLevel"` reward kind in `U.parse_rewards`/`Game.grant`).
   - `city.gd:216`: change the row text to "(unlocked by <ambition name>)".

### P2
3. **Max Bastion rewards are unreachable (B6).** `Content.gd:386` `BASTION_TIERS` is an open lever (the GDD tables are blank). Rescale the thresholds so the top tier needs about 3 good entries from an endgame team. Probe numbers: about 35K per entry for Lv 60 R6, about 15K for Lv 20 R3. For example 3K / 8K / 18K / 35K / 60K / 100K.
4. **Per-stage rewards tables (B13).** Make `BASTION_TIERS` an array of 3 tables (`BASTION_TIERS[stage-1]`) and use `stage` in `Content.bastion_rewards()` and `gang.gd:39`. Stage 3 (HYDRA, 2x HP) should pay the most.
5. **No gang-wide boss pool or "defeated" state (B5).** `Game._new_bastion_cycle()`/`_daily_gang()`: add `b.boss_hp` (e.g. sum of the 15 members' expected damage x 1.2) and a `b.defeated` flag once `gang_dmg + my_dmg >= boss_hp`. In `gang.gd`, show a big boss HP bar and a "DEFEATED - you can still attack for rewards" banner. Entering stays allowed.
6. **Debuff ambition counts minion debuffs (X2).** `scripts/combat/Battle.gd`: track `debuffs_on_boss` where `debuffs_placed_by_player` is incremented (only when `tgt.boss`). In `Content.finish()` (Content.gd:467), pass that instead.
7. **Battle header clipped (V1/V2).** `scripts/ui/screens/battle.gd`, `_update_top()`: for `turn_limit > 0`, move TURNS and DAMAGE into a dedicated top-centre panel (big boss HP bar using `b.side_units(1,false)[0]`, "TURNS 6/20" and a running damage number) and hide `round_label` when `wave_total == 1`. Shorten `top_label` to the title only.
8. **Squad title pushes the currency bar off-screen (V3).** `Content.build_bastion()`: shorten the title to `"Bastion - " + info.name`, or clip/ellipsize the header label in `Screen.header()`.
9. **Missing microtransaction cap upgrade (S5).** Add a Shop row (Trinium Exchange) "Stocks Vault +N cap" that raises `S.stocks.cap_bonus`. Read `cap + cap_bonus` in Game.gd:262 and city.gd:209/219. The size and price are an open lever.

### P3
10. **Boss template shape (B9).** `Warlords.gd`: give Atrium Sentinel a PASV1 (e.g. "Security Grid: reduces damage from AoE by 20%"). Turn HYDRA's Regrow into its PASV1 (e.g. "Regrow: every 3 turns heals 10% and cleanses"), so it has 2 ATK + 2 PASV.
11. **Side minion (B11).** Add one Bastion minion template per stage (or one shared "TeraTek Security Drone") with ATK1 + PASV1, and use it in `build_bastion()` instead of the 3 campaign mobs.
12. **Result screen for Bastion (V5).** In `battle.gd` `_finish()`: when `bastion`, replace "No item drops this time." with the tier reached ("Tier 3 of 6 reached today, rewards by mail"). The REPLAY label should use `Game.cost_text(enc.cost)`. Widen or ellipsize the name label in `_result_card`.
13. **START cost chip (V4).** Squad screen: when `enc.cost.has("bastion")`, label it "1 Entry" (or "1 Raid Ticket" once `entries == 0`).
14. **Gang ability lines (V6).** In `gang.gd:34-35`, render the boss abilities with the same ability card or chip used in the Armoury/Hideout boss panel instead of "[ACTIVE] ..." text, and let the stage tiles fill the row (`size_flags_horizontal = EXPAND_FILL`).
15. **Stocks Collect button (V8).** `city.gd:_stocks()`: set `disabled = lv == 0 or Game.S.stocks.stored < 1.0` on the Collect button.
