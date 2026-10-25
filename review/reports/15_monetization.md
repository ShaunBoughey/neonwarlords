# Review 15: Monetization (Trinium Exchange, Subscriptions, Double Rewards, Battle Pass)

Reviewer: session gdd-15-monetization. Read-only; no game files edited.

**Evidence**
- Logic probe: `tests/review/15/probe.gd` (`Probe.tscn`), headless, NW_SAVE=15. It parses every shop and pass reward line with `U.parse_rewards`, simulates every purchase up to limit+1, toggles Free IAP, buys Double Rewards, and runs the whole Battle Pass loop (challenges, premium, +25, claiming all 100 levels).
- Screenshots: `tests/review/15/shots15.gd` (`Shots15.tscn`), saved to `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_15\`.
- Design reference: the canvas artboard `project/Shop.dc.html`. The canvas has no Battle Pass artboard.

**Totals:** 63 OK, 2 MISSING, 1 WRONG, 0 DEVIATION.

## 1. GDD item status

### Trinium Exchange: data and purchase flow
`data/gdd.json` `shop` matches the GDD table cell for cell: names, contents, prices and limits for all 41 rows.

| Item | Status | Notes |
|---|---|---|
| Packs (17 rows): Small/Large Rare, Small/Medium/Large Epic, Small/Large Legendary, Street Punk, Mob Boss, Warlord, Scavenger, Vulture, Hunter, Equipment, Implant, Neon, Massive Neon | OK x17 | Every row parses to the exact contents. For example, Warlord Pack = 10 Rare + 2 Epic + 1 Legendary contracts, 1M credits, 1000 Trinium, 1000 energy. Equipment and Implant packs grant a full R6 **legendary** set. The Neon packs grant 12 or 60 R6 neons. |
| Pack prices (GBP 4.99 to 89.99) | OK | Shown as £ prices on gold buttons. |
| Pack purchase limits (5/3/5/3/1/3/1/5/2/1/5/2/1/5/5/5/1) | OK | Enforced. The probe bought each pack exactly up to its limit, the next try was refused, and the button disables (shot 21). |
| Trinium Vault (5 rows: 660/1550/3200/4750/8000 for £4.99 to £49.99, no limit) | OK x5 | |
| Credit Bank (5 rows: 100K/250K/1.5M/4M/10M credits for 60/150/900/2000/5000 Trinium) | OK x5 | The probe confirmed the exact Trinium deducted on each row. |
| Trinium Market: Paragon/Neutral/Renegade/Generic Deeds (30 Minor, 20 Major, 10 Grand; 1200/1200/1200/1000 Tr) | OK x4 | `Game.shop_buy` maps the alignment from the row name. Paragon went from 10/0/0 to 70/40/20 after 2 buys. |
| Energy Boost (1x Energy, 60 Tr) | OK | Grants 1 Energy Battery. |
| Pit Brawl / Pit Royal Refill (10 invites, 100 Tr, limit 2) | OK x2 | The limit is lifetime; see fix P2-3. |
| 1 Day / 3 Day Boost (1x / 3x 100% XP Boost; 100 / 250 Tr) | OK x2 | |
| 3x / 7x / 15x Rare Contracts (+75K/175K/375K credits; 500/1100/2200 Tr) | OK x3 | |
| Raid Boss Ticket (300 Tr) | OK | |
| Heist Plan (5x for 1000 Tr) | OK | |
| Purchases simulated offline | OK | Settings has a "Free IAP (dev mode)" toggle, on by default. With it off, packs, Double Rewards and Premium are refused with a message, and Trinium items still work. |

### Subscriptions and Player Progress Double Rewards
| Item | Status | Notes |
|---|---|---|
| Subscriptions ("regular bonuses? more automated battles, more credits and XP?") | **MISSING** | The "Subscriptions" tab holds only Double Rewards, which is a one-time purchase, plus a link to the Battle Pass. Nothing recurring exists. The GDD text is a question, so the design is an open lever (fix P2-4). |
| Player Progress Double Rewards ("extra rewards on each player level") | OK | `Game.add_pxp` duplicates the level reward list when `S.double_rewards` is set. Probe: a level-up gave 10K credits before purchase, then 2x (1 battery, 20K credits, 20 Tr) after. The £9.99 price is an open lever, since the GDD gives none. The purchase can't be repeated ("Already owned"). |

### Battle Pass
| Item | Status | Notes |
|---|---|---|
| 10-week season, then a 2-week gap | OK | `BP_SEASON_DAYS=70` and `BP_GAP_DAYS=14`. A gap screen says when the next season starts. Season state resets at each new season. |
| Levels 1-100 | OK | `bp_level()` is capped at 100. A new season starts at Level 0, and Lv1 needs the first 20 merits. |
| Free track and Premium track (premium also gets the free track) | OK | Paid claims are refused without premium. Premium players claim both tracks. |
| Price points: Free £0, Premium £15, Premium + 25 levels £25 | OK x3 | `bp_buy_premium(plus25)` sets merits to at least 500, which is Lv25 (probe: Lv25). |
| Each level costs 20 merits | OK | `BP_MERITS_PER_LEVEL=20` |
| Daily: 5 challenges, 15 merits each, +25 for completing all | OK | 5 picked per day by a seeded RNG. Probe gained exactly 100 merits. |
| Weekly: 4 challenges, 20 merits each, +20 for completing all (100 total) | OK | Probe gained exactly 100 merits. |
| Challenges picked at random from a pool | OK | `_seeded_pick` |
| Daily pool (10): Pit kills 10, Rank 4+, rank up 'x', equip to 16, 3 equips to 12, 3 hideout gear, 10 contracts, 10 dens, 5 hideouts, spend 100K | OK | Every event is tracked (`pitKill`, `rankUp4`, `rankUp`, `equip16`/`equip12` via `track("equip%d")`, `hideoutEquip`, `recruit`, `den`, `hideout`, `spendCredits`). The GDD placeholder "an 'x' Warlord" is read as "any Warlord". |
| Weekly pool (9): Pit kills 25, Rank 5+, rank up 'x', 2 equips to 16, 10 hideout gear, 25 contracts, 50 dens, 25 hideouts, spend 500K | **WRONG** (minor) | `Data.gd:290`: the GDD says "Rank up An 'x' Warlord", but the code says "Rank up 2 Warlords" (n=2). The meaning of 'x' is an open lever (fix P3-1). The other 8 are OK. |
| Players can reset 1 weekly challenge per week | **MISSING** | There is no reroll function (`Game` has no reset or reroll method) and no button for it (fix P1-1). |
| Reward track, levels 1-100, free and paid columns | OK | `gdd.json battlePass` matches all 100 rows (57 free and 100 paid rewards). All 157 parse with no unknowns. "10% XP Boost" correctly becomes `xpBoostMinor`, "1x Energy" becomes a battery, "Set of Rank N Neons" becomes 6 neons, and "Set Rare/Epic/Legendary Warlord" becomes a random warlord of that rarity. At 100,000 merits all 157 could be claimed, and none twice. |

## 2. Visual review

The Shop follows the canvas `Shop.dc.html` closely: the category rail, the gold featured banner with a silhouette, the 4-column notched offer cards, gold £ buttons and cyan Trinium buttons. The Battle Pass has no canvas artboard and looks plainer than the rest of the UI.

| # | Issue | Shot |
|---|---|---|
| V1 | Offer titles are hard-clipped mid-word with no ellipsis: "Large Rare Contrac", "Medium Epic Contra", "Small Legendary Co", "Large Legendary Co", "Consignment of Trir". In Featured, "Small Rare Contract" is cut so it reads as a different item. | `shots_15/01_shop_packs.png`, `02_shop_trinium_vault.png`, `00_shop_featured.png` |
| V2 | Pack contents are cut to about 25 characters ("Full Set of Rank 6...", "1000 Energy, 1m..."), and buying is a single tap with no details or confirm step. Players can't see what a £89.99 pack contains before paying. The canvas uses short, curated descriptions instead. | `01_shop_packs.png`, `06_shop_packs_bottom.png` |
| V3 | Progress packs (Scavenger, Vulture, Hunter) show the **Credits** coin icon and category, because `_art_for` checks "credit" before "energy". The canvas splits these into "Contract packs" and "Progress packs". | `06_shop_packs_bottom.png`, `00_shop_featured.png` |
| V4 | With Free IAP off, the £ buttons still look active (gold) and only show an error toast when tapped. | `22_shop_iap_off.png`, `23_subs_iap_off.png` |
| V5 | Battle Pass reward track: the level panels run to the bottom edge of the window with no margin, and the bottom border is clipped. There is no visible horizontal scroll cue. | `30_bp_fresh.png`, `33_bp_premium25.png`, `34_bp_lv100.png` |
| V6 | Battle Pass reward cells are text only (e.g. "1x lvl 3 Firmware", using the GDD's lower-case "lvl"). They have no item icons or rarity frames, unlike every other reward surface. Empty free cells show a lone "-". This is below RAID-quality presentation. | `30_bp_fresh.png` |
| V7 | At Level 100 the header still reads "(0 / 20 to next level)" with an empty bar. | `34_bp_lv100.png` |
| V8 | There is no "Claim all". After the +25 boost the player taps about 45 buttons one at a time. | `33_bp_premium25.png` |
| V9 | After buying Premium £15, the "+25 Lv" option disappears, so it can't be bought as an upgrade later. | `33_bp_premium25.png` |
| V10 | The reward modal uses unicode glyphs as icons ("¢" for credits, a square for contracts), not stroke icons. This comes from the shared `U.REWARD_ICON`, so other sections may report it too. | `20_shop_buy_modal.png` |
| V11 | The "+" on the Trinium and Energy pills in the top bar opens Shop > Featured, not the matching category. | (code: `Main.gd:354,356`) |

All buttons were exercised:
- Rail categories (6): OK.
- Every £ and Trinium buy button (41): grants the item or refuses at the limit.
- Subscription £9.99: becomes OWNED.
- OPEN BATTLE PASS: goes to `battle_pass.gd`.
- Battle Pass Premium £15 and +25: OK.
- Challenge Claim: OK.
- Track Claim / LOCKED / CLAIMED states: correct.

No debug text was found. The "FREE IAP DEV MODE • NO PAYMENT TAKEN" subtitle is deliberate.

## 3. Prioritised fixes

### P1 (breaks a GDD rule)
1. **Weekly challenge reset (MISSING).**
   - `Game.gd`: add `func bp_reroll_weekly(id: String) -> String`. It refuses if `S.bp.get("wreroll", -1) == U.week_id()`, or if the challenge is already claimed. Otherwise it swaps `id` in `S.bp.weekly` for a random id from `Data.BP_WEEKLY` that isn't already in the list, sets `S.bp.wreroll = U.week_id()`, and calls `mark()`.
   - In `_check_bp()` nothing more is needed, because `wreroll` is compared against the week id.
   - `battle_pass.gd` `build()`: in the weekly loop, add a small ghost "Reset" button beside each unclaimed weekly row. It calls `err(Game.bp_reroll_weekly(cid)); rebuild()`, and is disabled once `S.bp.get("wreroll") == U.week_id()`.

### P2 (wrong or ugly)
1. **V1 and V2: truncated titles and contents, no confirm step.** In `shop.gd` `_card()`:
   - Change the title to `t.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS` and `t.tooltip_text = name`. Better: drop the font to 15 and allow 2 lines.
   - Change `_buy()` so real-money rows (`cost.begins_with("GBP")`) first open a confirm modal (`main.modal(...)` / `UI.panel`). It shows the full `U.rewards_text(U.parse_rewards(row[1]))` as reward chips, the price, and BUY / CANCEL, then calls `Game.shop_buy`. Trinium rows can stay one-tap.
2. **V5 and V7: Battle Pass layout.**
   - In `battle_pass.gd` `build()`, give the track scroll a bottom margin (e.g. `sc.custom_minimum_size.y = 250` inside a MarginContainer with bottom 16), or reduce `_reward_cell` height from 84 to 76.
   - When `lvl >= 100`, show "MAX LEVEL" instead of "(x / 20 to next level)" and a full bar.
3. **Pit Brawl and Royal Refill limits never reset.** `Game.shop_buy` keys `S.shop_bought` forever, so after 2 refills the item is gone for good. The GDD gives the limit (2) but not its period, which is an open lever. Recommendation, in line with RAID's daily refill caps:
   - In `Game.shop_buy` and `shop.gd` `_limit()`, key Trinium Market rows by day: `"%s|%d|d%d" % [section, i, U.day_id()]`.
   - Leave pack limits lifetime, or make them monthly. That is a design call for the user.
4. **Subscriptions (MISSING).** The GDD only asks a question, so this needs a user decision before building. Proposed minimal version, using only GDD-named perks:
   - A monthly "Syndicate Pass" in the Subscriptions tab (price is an open lever) with +X% credits and XP from battles and extra auto-battles.
   - `Game.gd`: `S.sub_until` timestamp; `buy_subscription()`; apply the multiplier where battle credits and XP are granted.
   - Ask the user for the X values.
5. **V3: wrong art for progress packs.** In `shop.gd` `_art_for()`, check for `"heist"`, `"firmware"` and `"xp boost"` before the credit branch, and return `["Progress", UI.GOLD, Icon.make("bag", UI.GOLD, 64)]`. Optionally split the rail "Packs" into "Contract packs" and "Progress packs" to match the canvas.
6. **V6: Battle Pass cells are text only.** In `battle_pass.gd` `_reward_cell()`, render the parsed reward with the same item chip/icon used by `main.show_rewards`: `U.parse_rewards(text)[0]`, then an icon plus a short label, with rarity border colour for gear and warlords. For empty cells, hide the "-" and dim the panel.

### P3 (polish)
1. **Weekly "Rank up an 'x' Warlord".** `Data.gd:290`: GDD 'x' is unspecified (open lever). Make the daily and weekly versions consistent. Suggested reading: 'x' = a random rarity or affiliation chosen when the challenge is rolled, e.g. "Rank up a Paragon Warlord". Otherwise use `"Rank up a Warlord", n: 1` in both pools, as the GDD writes it for both.
2. **V8: no Claim All.** Add a "CLAIM ALL" button to the `battle_pass.gd` header. It loops `Game.bp_claim(l, false/true)` for `l` in 1..lvl, collects the results, and calls one `main.show_rewards`.
3. **V9: no upgrade to +25.** When `S.bp.premium` is set and `bp_level() < 25`, keep the "+25 Lv" button visible. Price it at the £10 difference (£25 - £15) and have it call `Game.bp_buy_premium(true)`.
4. **V4: £ buttons look active with Free IAP off.** In `shop.gd` `_buy_btn()`, when `real and not Game.S.settings.free_iap`, use the "ghost" style or `b.disabled = true`. Do the same for the subscription and Battle Pass premium buttons.
5. **V11: top-bar "+" goes to the wrong category.** `Main.gd:354,356`: make the trinium pill call `go("shop", {"sec": "Trinium Vault"})` and the energy pill call `go("shop", {"sec": "Trinium Market"})`.
6. **V10: unicode glyph icons.** Replace the glyphs in `U.REWARD_ICON` with `Icon.make` names (coin, diamond, bolt, ...) in the reward modal. This is shared with other sections.
7. **Lower-case "lvl" in the track.** GDD text such as "1x lvl 3 Firmware" is shown raw on the track. Display `U.reward_label()` ("1x Mk 3 Firmware") instead of the raw text, consistent with the reward modal.

## Wave 1 applied (owner F)

Files edited: `shop.gd`, `battle_pass.gd`, `plaza.gd`, `gang.gd`, `recruit.gd`, `login_rewards.gd`, `safehouse.gd`, `missions.gd`. No other files were touched.

**Verification**
- `TestRunner`: failures 0.
- `UiSmoke`: all 8 owned screens report "screen ok".
- Screenshots re-taken in `shots_15/`, including `40_*` (plaza, gang, login, safehouse, missions), `41_missions_monthly`, `42_shop_market_heist_guard`, `20_shop_buy_confirm`, `33_bp_premium25` and `35_bp_claim_all`.

**15 (this report)**
- **P1 weekly reset button:** each unclaimed weekly row has a RESET button. It calls `Game.bp_reroll_weekly` and is disabled once `S.bp.wreroll == U.week_id()`.
- **P2-1:** card titles and descriptions now end in an ellipsis and show the full text as a tooltip. Real-money buys open a confirm modal (CONTAINS reward chips, CANCEL, BUY £x).
- **P2-2:** the Battle Pass track fits the screen (tighter rows, bottom margin). At level 100 the header shows "MAX LEVEL".
- **P2-5:** Scavenger, Vulture, Hunter and Heist rows are categorised as "Progress" with a bag icon.
- **P2-6:** track cells show a `UI.reward_node` icon and the `U.rewards_text` label, ellipsised with a tooltip. Empty cells are dimmed.
- **P3-2:** CLAIM ALL (n) button in the Battle Pass header.
- **P3-3:** "+25 LV £10" upgrade appears when premium is owned and the level is below 25.
- **P3-4:** £ buttons, the subscription button and the Battle Pass premium buttons use the ghost style when Free IAP is off.
- **P3-7:** covered by P2-6 ("Mk 3 Firmware" instead of "lvl 3").
- **16:P3-2:** the shop dev subtitle is gated by `OS.is_debug_build()` and shortened to "Free IAP dev mode".
- **16:P3-3:** Battle Pass gold rule: only PREMIUM £15 is gold. +25 is cyan outline, claims are cyan, and buttons are uppercase. The season moved to a tag, because the long title was ellipsised by the new header.
- **16:P3-1:** the shop BEST VALUE / LIMIT tags are 13 px.

**14**
- **#1:** Plaza captures the stock hour and passes it to `Game.plaza_buy(i, hour)` through `callv`. It also refuses locally when the hour has rolled over. The countdown ticks every second and the stock swaps live.
- **#2:** Plaza cards use `UI.reward_node` art and a stroke coin icon on the price button.
- **#3:** reached bastion tiers get a green chip with a check icon.
- **#5:** Plaza cards show the slot art plus "Boots • Hacking set" when the stock carries a slot or set, otherwise "Random slot and set".
- **#6:** MESSAGE button and modal (120 chars) saving `S.gang.motd`, pinned in yellow at the top of chat.
- **#7:** chat lines and speakers are shuffled with the daily seed, so they are distinct. The panel is titled "Gang chat (offline)".
- **#9:** RENAME and MESSAGE moved into the members header. The member list expands. The Bastion panel scrolls, with ATTACK kept fixed at the bottom.
- **#10:** Plaza cards have a category caption, a rank and a detail line.

**13**
- **#3:** text is at least 13-14 px (mission chips 14, PROGRESS 13, login day 13 and reward 14, safehouse bonus 14).
- **#4:** login cards show `U.rewards_text`.
- **#5:** today's login card stays ticked after claiming, so day 31 no longer wraps.
- **#7:** missions use one gold CLAIM; the others are cyan.
- **#8:** monthly jobs show "Jobs reset in …" using `U.secs_to_next_month()`.
- **#9:** safehouse uses "1 Warlord benefits", shows "Next +X", uses a 10-segment meter, and adds a TOTAL block per alignment. The subtitle is shortened.

**12**
- **#7 and #8:** the recruit reveal shows the best Warlord's name; the pull label moved to 312.
- **#9:** `sign.create_tween()`.
- **#11:** the Heist Plan shop row is disabled, with a tooltip, while any plans are held.

**11**
- **#4:** tier chips read `Content.bastion_tiers(stage)` when it exists.
- **#5:** boss HP bar and a DEFEATED tag from `b.boss_hp` and `b.defeated`.
- **#14:** abilities shown as ACTIVE/PASSIVE `UI.tag` rows; stage tiles fill the row.

**Skipped**
- 15:P2-3 and 15:P2-4, 13:#1 (portrait part): HELD.
- 13:#6 and #10: not owner F.

**Requests**
1. **Owner C, `ui.gd` `reward_tile`:** the new glyph fallback `{"k": _glyph_kind(icon)}` builds `{"k": "firmware"}` with no `lv`, so `reward_art` (ui.gd:304) throws "Invalid access to key 'lv'". It happens when `show_rewards` lists firmware, e.g. a Battle Pass CLAIM ALL. Use `r.get("lv", 1)` in `reward_art`, or have `Game.grant` attach the raw `reward` dict to each display entry.
2. **Owner C:** `Screen.header` now ellipsises long titles and subtitles. Owned screens were shortened to fit, but other screens with long subtitles will clip the same way.
3. **Coordinator, GDD_COVERAGE.md:** add "Battle Pass: weekly challenge reset (1/week); Premium→+25 upgrade priced at the £10 difference (open lever)" and "Plaza stock shows slot/set before purchase".

## Wave 2 applied (owner F)

- `shop.gd`: the Trinium Vault tab has a new card, "Stocks Vault +25 cap" (functions `_stocks_card`, `_stocks_buys` and `_buy_stocks`).
  - Price £1.99, shown with a 0/4 counter and the current cap.
  - Asks for confirmation first, then calls `Game.buy_stocks_cap()`.
  - Follows Free IAP: the button is ghost-styled and refuses when it is off.
  - The button changes to SOLD OUT (disabled) once `Data.STOCKS_CAP_BUYS` buys are done.
  - Step and buy count are read from `Data.STOCKS_CAP_STEP` and `Data.STOCKS_CAP_BUYS`.
- Verified with `tests/review/15/stocks15.gd`:
  - 4 buys through the confirm dialog took `cap_bonus` from 0 to 100 and the cap from 40 to 140; the fifth try was disabled.
  - With IAP off the card refused and opened no modal.
  - Screenshots: `shots_15/50_stocks_row`, `51_stocks_confirm` and `52_stocks_maxed`.
- Compile check clean. TestRunner: failures 0. UiSmoke: done, shop ok.
- Request: GDD_COVERAGE should note the Stocks cap microtransaction (+25 per buy, max 4, £1.99). The price is an open lever.
