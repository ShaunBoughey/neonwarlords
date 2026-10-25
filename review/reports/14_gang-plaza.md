# Review 14 - Gang (clan) and The Plaza

GDD text: `review/gdd/14_gang-plaza.txt` (2 short paragraphs + one open TODO).
Code checked: `scripts/ui/screens/gang.gd`, `scripts/ui/screens/plaza.gd`, `Data.PLAZA_POOL` / `FEATURE_UNLOCK` (`scripts/core/Data.gd:339-381`), `Game.plaza_items/plaza_buy` (`scripts/core/Game.gd:1549-1575`), `Game._init_gang/_daily_gang/can_pay` (`Game.gd:1759-1830`), `Main.gd` nav/gates.
Probe: `tests/review/14/Shots14.tscn` (windowed, `NW_SAVE=14`). Screenshots in `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_14\`.

Probe output (all as expected): Gang locked at Lv1 (stays on City with toast); ATTACK opens `squad.gd`; Plaza buy spent 25,000, marked index 0 sold, tracked `plazaBuy` + `spendCredits`; re-buy returns `[]`; forcing an hour change rerolls 6 items and clears `bought`.

## GDD items

| # | GDD item | Status | Notes |
|---|---|---|---|
| G1 | Player must join a Gang before taking part in Bastions | MISSING (partly) | No join/browse/leave flow. Every new account is auto-placed in "Neon Jackals" with 14 NPC members (`Game._init_gang`, `Game.gd:1760`). The gate is satisfied trivially; the real gate is Player Level 12 (`Data.FEATURE_UNLOCK.gang`). Acceptable for an offline build (GDD_COVERAGE: "Implemented (offline)"), but there is no "you are in a gang" moment for the player. |
| G2 | Bastions are a clan-only activity | OK | Bastion lives only inside the Gang screen; Fight hub / Events cards route to `gang`. Entries/raid tickets gated in `Game.can_pay` (`Game.gd:1811`). (Bastion rules themselves are section 11.) |
| G3 | Gang chatroom | MISSING (stub) | `gang.gd:72-80` shows 3 read-only fake lines, seeded per day, with no input box. The same line can repeat (screenshot 01: "Anyone got a spare Stitcher set?" twice). |
| G4 | Gang messages, available to the Gang leader | MISSING | The player is shown as "Leader", but there is no leader message/announcement (message of the day or mail to all members). Only leader action is Rename. |
| G5 | "Think up reason to have clan other than Bastions" (open TODO) | OK (open lever) | Already used beyond Bastion: Pit leaderboard "Gang" filter (`arena.gd:121-146`), Friends list shows gang mates (`inbox.gd:45-55`). The GDD leaves this open; see P3 suggestions, nothing to flag as wrong. |
| P1 | The Plaza is a market in the city centre | DEVIATION-ish / OK | Reachable from the bottom nav (Plaza tab) and the Events card, not from the City map itself (City map has a Black Market sign but no Plaza sign, `city.gd:78`). Fine functionally; see P3. |
| P2 | Updates hourly with new items | OK | `Game.plaza_items` rerolls 6 items from `PLAZA_POOL` when `U.hour_id()` changes (`Game.gd:1549-1563`); `bought` resets. Countdown shown. But see P1 bug below: an open screen does not notice the hour change. |
| P3 | Items purchased with credits | OK | `plaza_buy` spends `credits` only (`Game.gd:1565-1575`). Pool: gear R3-R6, implants R3-R6, metabolics, deeds, memory fragments, stimm, firmware, contract (`Data.gd:353-381`). R5-R6 legendary stock is the documented late-game credit sink (GDD_COVERAGE line 68). |
| P4 | (implied) unlock timing | OK (open lever) | Plaza unlocks at Player Level 4 (`FEATURE_UNLOCK.plaza`), GDD leaves this open. |

Counts: OK 5 (incl. 2 open levers), MISSING 3 (G1 partial, G3 stub, G4), WRONG 0 against GDD text. One logic bug in the Plaza implementation (stale stock purchase, below).

## Visual and button check

Design canvas (https://claude.ai/artifact/DMTXzGtAtiDqeKPyEyxZ7h) has no Gang or Plaza artboard; the nearest is `Shop.dc.html` (notched offer cards with a category caption, real item art, name, sub-line, and a gold notched price button with a stroke coin icon). Compared against that.

Buttons found: Gang = Rename (opens modal, Save works), ATTACK (opens squad select), bottom nav. Plaza = 6 price buttons (disabled when unaffordable or sold; "Sold" state shown), bottom nav. Every button leads somewhere.

| # | Issue | Screenshot |
|---|---|---|
| V1 | **Emoji in Plaza cards.** The card art is `U.reward_icon` text glyphs; gear shows the colour crossed-swords emoji and metabolic shows the alembic emoji. Breaks the "no emoji, stroke icons" rule. | `shots_14/04_plaza_rich.png` |
| V2 | Plaza cards are bare compared with the Shop design: a text glyph, one label, price. No category caption, no item art (the game has `UI.reward_node`), no description, card heights uneven (Memory Fragments card is taller because the glyph's line height differs). Price uses a "¢" text character instead of the stroke coin icon. Bottom ~40% of the screen is empty. | `shots_14/04_plaza_rich.png`, `06_plaza_sold.png` |
| V3 | Plaza gear/implant stock is blind: "1x Rank 5 Legendary Equipment" for 900K credits, slot, set and stats rolled only on purchase (`Game.grant` -> `gen_equipment`, `Game.gd:1058-1063`). RAID's market shows the actual item. | `shots_14/04_plaza_rich.png` |
| V4 | Bastion damage tier chips: reached and unreached look identical. `gang.gd:40` passes `""` as the icon in both branches, and `UI.chip` only uses the colour for the icon, so the green "reached" colour never shows. | `shots_14/01_gang.png` |
| V5 | Member power scale mismatch: the player row shows "Leader • 730" (`team_power` of the starter squad) while NPC members show 8.6K-37K (`U.ri(8000, 40000)`, `Game.gd:1763`). The leader looks like the weakest member by 10-50x. | `shots_14/01_gang.png` |
| V6 | Gang chat repeats lines and has no input; reads as placeholder. | `shots_14/01_gang.png` |
| V7 | Rename button sits alone on its own row at the far right, above the panels; members column has a large empty gap between the list and the chat box. | `shots_14/01_gang.png` |
| V8 | "Gang damage: 0" on a new account's first day: `_init_gang` -> `_new_bastion_cycle` never runs the NPC chip-in that `_daily_gang` does, so the gang looks inactive until the first reset. | `shots_14/01_gang.png` |
| V9 | Reward modal after a Plaza buy: the tile label "5x Paragon Minor Deeds" wraps to two lines below the tile (shared `show_rewards`, not Plaza-specific). Minor. | `shots_14/05_plaza_bought_modal.png` |
| V10 | Plaza countdown is static ("New stock in 49m 59s" never ticks) because the screen only builds once. | `shots_14/06_plaza_sold.png` |

## Prioritised fix list

**P1**
1. **Plaza can sell a different item from the one shown.** If the Plaza screen is open across the hour boundary, the buttons still show the old stock, but `Game.plaza_buy(i)` calls `plaza_items()`, which rerolls, and then charges for and grants item `i` of the *new* stock. Fix:
   - `scripts/core/Game.gd`, `plaza_buy(i: int)` -> `plaza_buy(i: int, hour: int = -1)`: at the top, `if hour >= 0 and hour != U.hour_id(): say("The Plaza restocked", UI.GOLD) ; return []` (use the existing `say` colour convention).
   - `scripts/ui/screens/plaza.gd`, `build()`: capture `var hour := int(Game.S.plaza.hour)` after `Game.plaza_items()` and pass it: `Game.plaza_buy(idx, hour)`.
   - Same file: add a 1 s refresh so the countdown ticks and the stock swaps live, e.g. `func _process(_d): if U.hour_id() != _hour: rebuild()` plus updating the countdown label text each second (keep a reference to it).

**P2**
2. **Emoji in Plaza cards (V1/V2).** `scripts/ui/screens/plaza.gd`, `build()`: replace `v.add_child(UI.lbl(U.reward_icon(r), 44, col, HORIZONTAL_ALIGNMENT_CENTER))` with a centred `UI.reward_node(r, 64)` (wrap in a `CenterContainer` or set `size_flags_horizontal = SIZE_SHRINK_CENTER`). This also evens out card heights. Price button: use the stroke coin icon like `shop.gd:174` (`Icon.make("coin", ...)`) instead of the "¢" character.
3. **Bastion tier chips never show "reached" (V4).** `scripts/ui/screens/gang.gd:40`: change `UI.chip("" if reached else "", ...)` to `UI.chip("✓" if reached else "", ...)` and give reached chips a visible state (e.g. green text: build the label colour from `reached`, or add a green border via a chip variant).
4. **Leader power vs NPC power (V5).** `scripts/core/Game.gd`, `_init_gang()`: scale NPC member power from the player's own power instead of a fixed 8K-40K, e.g. `var base: int = max(1000, team_power(S.squads.last)); ... "power": int(base * (0.6 + U.rf() * 1.9))` (`U.rf()` takes no args), and in `_daily_gang` drift it upward with the player's power so members stay comparable. (Open lever: the GDD gives no member power numbers.) Note `arena.gd:122` and `inbox.gd:55` also read `m.power`.
5. **Blind gear purchase (V3).** `Game.plaza_items()`: when rolling the hour's stock, pre-generate a concrete slot and set for gear/implant entries (store `slot`/`set` on the item's `r` dict; `grant` already honours `r.set`, pass `r.get("slot", "")` as the 5th arg of `gen_equipment` at `Game.gd:1062`, which already accepts `slot`) and show slot icon + set name in the card. Keeps hourly randomness, lets the player know what 900K buys.
6. **Gang messages for the leader (G4).** `scripts/ui/screens/gang.gd`: add a "Gang Message" button next to Rename (leader only) opening a modal with a `LineEdit` (max ~120 chars) that saves to `Game.S.gang.motd` and shows it pinned at the top of the chat panel. Smallest offline-faithful reading of the GDD line.
7. **Chat repeats (V6/G3).** `gang.gd:72-80`: pick 3 distinct lines (shuffle `lines` with the seeded RNG and take the first 3) and distinct speakers; title the panel "Gang chat (offline)" or add a disabled input row with "Chat connects when online play is live", matching the Friends screen wording in `inbox.gd:45`.

**P3**
8. **Gang damage 0 on day one (V8).** `Game._init_gang()`: after `_new_bastion_cycle()`, run the same NPC chip-in loop as `_daily_gang` (factor into a helper `_npc_bastion_dmg()`).
9. **Layout polish (V7).** `gang.gd:8-9`: put Rename (and the new Gang Message) in the members panel header row instead of a lone header row; let the member list `UI.scroll` expand (`size_flags_vertical = SIZE_EXPAND_FILL`) so the empty gap goes away.
10. **Plaza fills half the screen (V2).** `plaza.gd`: add a rarity/category caption line per card (as in `Shop.dc.html`) and a one-line description, or raise the stock count (open lever: the GDD does not fix how many items the Plaza shows; 6 is a free choice).
11. **Plaza "in the city centre" (P1).** Optional: add a Plaza sign to the City map next to the Black Market sign in `city.gd:78` (`_sign(..., "The Plaza", "Hourly credit market", UI.YELLOW, func(): main.go("plaza"), false, "plaza")`). Also `Main.NAV_GROUP.plaza` groups Black Market and Safehouse under the Plaza tab, but the Plaza screen offers no link to them; consider two header buttons to those screens.
12. **Join flow (G1).** Optional, offline-safe: a one-time "Join a Gang" card when the gang unlocks at Lv12 (pick from 3 generated gangs, then `_init_gang` with that name) so the GDD's "must join" step exists. Today the player is silently pre-joined.
13. **More reasons to be in a gang (G5, open lever).** Ideas that reuse existing systems without touching GDD tables: daily gang check-in reward from the inbox, a gang-wide Missions bonus, gang Pit leaderboard. Needs a user decision; not a bug.
