# GDD 09 - Syndicate Wars: review report

Reviewer session: gdd-09. Save: `NW_SAVE=09`. Probe and screenshot scripts: `tests/review/09/probe.gd` (headless logic), `tests/review/09/shots.gd` (windowed).
Screenshots: `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_09\`.

**Summary: 17 OK, 0 MISSING, 1 WRONG (minor), 0 DEVIATION.** All the rules and tables are in place. The issues are in presentation: the screen doesn't follow the approved design pattern, the stage grid leaves a third of the screen empty, and you can only see milestone rewards in a hover tooltip.

## 1. GDD items

| # | GDD item | Status | Evidence |
|---|---|---|---|
| 1 | Each team must come from a single syndicate | OK | `Content.build_sw` sets `lock_syn` (Content.gd:289). `squad.gd:_allowed` (138-140) filters the roster, auto-fill and the remembered squad (line 19). START is disabled when the squad is empty (squad.gd:107). The squad screen shows "Syndicate Wars: X only". |
| 2 | Syndicate Wars is the **only** source of Neons | WRONG (minor) | `Game.grant_starter_kit` (Game.gd:100-101) gives every new account 8 Rank 2-3 Neons. (The dev test kit at Game.gd:134-135 is fine.) Other GDD tables (Shop "Neon Pack", "Set of Rank 4/5/6 Neons" rewards in data/gdd.json:7245-7877) also grant Neons. That conflicts inside the GDD itself, isn't this section's bug, and needs a user decision. |
| 3 | Gives lesser warlords a use / diverse rosters | OK | Design intent. It's enforced by #1, and the select screen shows "N Warlords owned" per syndicate. |
| 4 | 20 stages per syndicate | OK | `syndicate_wars.gd:_stages` makes 20 stage cards. `next_enc` stops at 20 (Content.gd:438-440). |
| 5 | 1-3 Chevrons per stage depending on circumstances | OK | `Content.chevrons` (Content.gd:397): win = 1, +1 if no warlord died, +1 if won within `chevron_turns` (14 for SW). The best result is kept (`Game.sw_record` uses max, verified). |
| 6 | Total completion fills a reward bar (each stage + all of SW) | OK | `Game.sw_total_stars` totals every syndicate and stage. The bar and 24 milestone buttons are in `_progress()`. |
| 7 | Bounty Tokens are needed to enter | OK | `cost: {"bounty": row.tokens}`, paid in `squad._start` and battle `_replay`. Paying with 0 tokens fails with "Not enough: 1 Bounty Token" (probe). |
| 8 | Tokens refresh each day to a max of 12 | OK | The daily reset sets bounty = 12 (Game.gd:243). `add_cur` caps at 12 (Game.gd:311-316). The probe confirmed that +5 at 12 stays at 12. |
| 9 | Cost: stages 1-5 = 1, 6-10 = 2, 11-15 = 3, 16-20 = 4 tokens | OK | data/gdd.json `syndicateWars[*].tokens`. The probe printed all 20 costs, and all match. |
| 10 | Neon rank odds, stages 1-5 (R1-3: 35/40/25 down to 15/40/45) | OK | The table matches cell for cell. Stage 1 over 20,000 rolls gave 35.2 / 40.1 / 24.8. |
| 11 | Neon rank odds, stages 6-10 (R2-4) | OK | The table matches. Stage 6 over 20,000 rolls gave 35.7 / 39.5 / 24.8. |
| 12 | Neon rank odds, stages 11-15 (R3-5) and 16-19 (R4-6) | OK | The table matches cell for cell. |
| 13 | Stage 20: R5 55% / R6 45% | OK | Rolls gave 54.8 / 45.2. |
| 14 | "Equal Chance Random Stat Focus 10" | OK | `add_neon` picks evenly from `Data.NEON_STATS` (10 stats, 10% each). Measured 9.5-10.4% for every stat. |
| 15 | Reward = 1 Neon (100%) per win, nothing on a loss | OK | `Content.sw_rewards`. A loss gives 0 items and 20% XP. |
| 16 | Progression rewards: 24 milestones, 15-360 chevrons | OK | `data/gdd.json swProgress` matches the GDD table exactly. All 24 parse without an "unknown" entry (probe). "Nx Energy" becomes N Energy Batteries; "Set of Rank N Equipment/Implants" gives 6 gear or 3 implants with rarity rolled 50/40/10 Rare/Epic/Legendary (Game.gd:1069-1078). The rarity is an open lever, because the GDD doesn't say. |
| 17 | Each milestone can be claimed once, and only when reached | OK | `Game.claim_sw_progress`: returns [] below the threshold and [] on a second claim. The 360 claim gave a Legendary warlord (probe). |
| 18 | Stage unlock order (not in the GDD) | OK | Stage N+1 unlocks after at least 1 chevron on stage N. NEXT STAGE works the same way. |

Notes:
- There are 7 syndicates, so the most chevrons you can earn is 7 x 60 = **420**, but the GDD bar ends at 360. You get every reward after 6 syndicates. That's fine, but the label can then read "Total chevrons: 400 / 360" (see P3-4).
- SW unlocks at Player Level 8 (`Data.FEATURE_LEVEL`). The GDD doesn't say when; that's an open lever.

## 2. Visual issues

| # | Issue | Screenshot |
|---|---|---|
| V1 | The stage grid (5 columns) only uses about 870 of the 1240 px width, leaving a big empty band on the right. Stages 16-20 are below the fold. | `shots_09/02_sw_stages.png`, `04b_sw_stages_scrolled.png` |
| V2 | The 24 milestone buttons show only the threshold number ("15", "30"...). What you win shows only in `tooltip_text`, which needs a mouse hover and doesn't work on touch. RAID shows a reward icon at each step on the bar. "DONE" and not-yet-reached milestones use the same ghost style, so you can't tell them apart. | `01_sw_select.png`, `04b_sw_stages_scrolled.png` |
| V3 | The screen doesn't follow the approved design canvas. The closest board is `project/Hideouts.dc.html`: a location rail with progress (x/20), a stage picker, a stage detail panel with recommended power vs yours and a drops row, and a BATTLE button with a cost icon. SW uses an older grid of FIGHT cards, with no drop odds, enemy syndicate or power. | `02_sw_stages.png` |
| V4 | Bounty Tokens show as plain yellow text under the top bar ("Bounty Tokens: 12 / 12"), not as a currency pill like Energy, Credits and Gems. | `01_sw_select.png` |
| V5 | Text glyphs instead of stroke icons: chevrons "▲△" (`UI.chevrons`), "◀ Syndicates", the "▲ 0 / 60" counter, and "¢" on the credits reward card. "◀ Syndicates" also repeats the header's back arrow. | `02_sw_stages.png`, `03_sw_claim.png` |
| V6 | Grammar: "1 Warlords owned". | `01_sw_select.png` |
| V7 | The result screen's "REPLAY • 2" shows a bare number with no token icon or name. The squad START button shows a ticket icon correctly. | `09_result.png` |
| V8 | Battle view: fine. The title "Syndicate Wars - Teratek Cybernetics 7 • vs Quantum Vikings" fits, and the AUTO and speed buttons work. Nothing is clipped. | `07_battle_start.png`, `08_battle_mid.png` |

Buttons I checked: syndicate cards → stage list. "◀ Syndicates" → back to select. Milestone button → reward modal → COLLECT → "DONE". FIGHT → squad (locked to the syndicate) → START → battle. The result's BACK and REPLAY are present. NEXT STAGE appears only after a win (`next_enc`). LOCKED cards are disabled. All lead somewhere; no dead buttons.

## 3. Fix list

### P1
None. No rule is broken and nothing crashes.

### P2
1. **Stage grid fills the width** (V1). In `scripts/ui/screens/syndicate_wars.gd` `_stages()`, inside the `for st` loop after `var p := UI.panel(...)`, add `p.size_flags_horizontal = Control.SIZE_EXPAND_FILL`. Also add `g.size_flags_horizontal = Control.SIZE_EXPAND_FILL` before `root.add_child(UI.scroll(g))`, so all 20 cards fill the width. Alternatively, cut the card height (merge the rank and token lines into one row) so that 4 rows fit at 720p.
2. **Show milestone rewards** (V2). In `syndicate_wars.gd` `_progress()`, replace each `UI.btn(str(thr))` with a small tile: the reward icon from `U.reward_icon(U.parse_rewards(r[1])[0])`, a short label (`U.reward_label`), and the threshold below it. Use 3 states: claimable (gold, pulsing), claimed (dim, with a check stroke icon), and not reached (ghost). Keep the tooltip as extra help. Twenty-four tiles fit as a horizontal scroll strip under the bar.
3. **Match the Hideouts design pattern** (V3). Rework `_stages()` along the lines of `project/Hideouts.dc.html`, reusing `hideouts.gd` layout code where you can:
   - On the left, a rail of the 7 syndicates showing "x/60" chevrons and owned count (replaces `_select()` grid, or keep the grid as the entry and add the rail).
   - A 20-stage picker (two pages of 10).
   - A detail panel showing:
     - the Neon rank odds from `Data.GDD.syndicateWars[st-1].ranks` (for example "R1 35% · R2 40% · R3 25%"),
     - the enemy syndicate (`build_sw(...).subtitle`),
     - recommended vs squad power (as squad.gd already computes),
     - a BATTLE `UI.cta(..., str(row.tokens), "ticket")`.

### P3
1. **Starter Neons** (item 2). Either remove `for i in 8: add_neon(U.ri(2, 3))` from `Game.grant_starter_kit` (Game.gd:100-101) to keep "only from SW", or record it in `GDD_COVERAGE.md` as a deliberate onboarding deviation. Ask the user, and also ask about the Shop and other tables in the GDD that grant Neons.
2. **Bounty pill** (V4). In `syndicate_wars.gd:build()`, replace the `UI.lbl("Bounty Tokens: ...")` with `UI.chip("", "%d / %d" % [...])` using the ticket stroke icon (the same icon `UI.cta` uses for `"ticket"`), placed in the header row next to the other currency pills.
3. **Stroke icons** (V5). Change `UI.chevrons` (ui.gd:282) to draw 3 chevron stroke icons via `Art.icon` instead of "▲△". Drop "◀ Syndicates" in `_stages()` in favour of the header back arrow: make header back go to the select view when `params.syn != ""`. Or use a stroke chevron icon on that button.
4. **Chevron label overflow**. In `_progress()`, display `mini(total, 360)` in the label, or "360 / 360 (+N)", because 7 syndicates give 420.
5. **Plural** (V6). In `_select()`, use `"%d Warlord%s owned" % [owned, "" if owned == 1 else "s"]`.
6. **Replay cost icon** (V7). In `scripts/ui/screens/battle.gd`, around line 749, build REPLAY with `UI.cta("REPLAY", _replay, str(cost), "bolt" if k == "energy" else "ticket")` to match the squad START button, instead of `"REPLAY  •  N"`.
7. **Stage cards: enemy and difficulty**. Until P2-3 is done, add the enemy syndicate name (`Content.build_sw(syn, st).subtitle`) as a dim line on each card.

Open levers I noticed but am not flagging: `chevron_turns` = 14 for every stage; the SW unlock level (8); the rarity mix in milestone gear and implant sets (50/40/10); SW enemy level curve `3*stage+2`.

## Wave 1 applied

Owner G (gdd-10). File edited: `scripts/ui/screens/syndicate_wars.gd`, reworked to the Hideouts pattern.

**Changed**
- **P2-3** (replaces the `_select()` grid and the `_stages()` 20-card grid). Below the milestone panel, the screen has three parts:
  - **Left (`_rail`):** a rail of the 7 syndicates showing "x/60" chevrons. The right-hand count is gold if you own warlords there.
  - **Centre (`_centre`):** the syndicate symbol, its name in the display font, its lore, "N Warlord(s) owned" (green if 4+, gold if 1-3, red if 0), and the single-syndicate rule.
  - **Right (`_stage_panel`):**
    - a 2-page, 10-stage picker,
    - the stage title with stroke-icon chevrons and the enemy syndicate ("vs X", which covers P3-7),
    - You vs Recommended power, with a split bar and a verdict (your best 4 of that syndicate),
    - Neon odds ("R1 35% • R2 40% • R3 25%") and Warlord XP,
    - a BATTLE CTA with the bounty-token cost; it is disabled when you own none of the syndicate's warlords.
  - The screen opens on the syndicate where you own the most warlords.
- **P2-1**: superseded by P2-3. The layout now fills the width at 720p, and nothing scrolls except the picker panel when needed.
- **P2-2** `_milestone()`: 24 tiles in a horizontal scroll strip. Each tile shows its reward icon (via `UI.reward_node`), its label (14px, ellipsized; the full text is in the tooltip) and its threshold. Tiles have three states:
  - claimable: gold border with a looping pulse,
  - claimed: dim, with a green check icon,
  - not reached: muted.
- **P3-2**: the bounty pill is a ticket stroke icon plus "N / 12", sitting in the milestone header row.
- **P3-3**: the "◀ Syndicates" button is gone, since the rail replaces the select view and the header back arrow leaves the screen. Chevrons use the `Icon` "up" stroke icon (local `_chevrons`). `UI.chevrons` in ui.gd still uses glyphs; see Requests.
- **P3-4**: the milestone label shows "360 / 360 (+N)" when the total passes 360, and the bar is clamped.
- **P3-5**: "1 Warlord owned" / "N Warlords owned".
- **P3-7**: the enemy syndicate is shown in the stage panel.

**Skipped**
- P3-1 (starter Neons) is HELD.
- P3-6 (REPLAY icon) belongs to owner B.

**Verified**
- Screenshots: `shots_10/w1_sw_default.png`, `w1_sw_stage9.png`, `w1_sw_other_syn.png`, `w1_squad_sw.png`.
- Every button has a handler: 7 rail rows, 10 stages, 2 page buttons and BATTLE. Milestones are wired only when claimable.
- TestRunner: failures 0. UiSmoke: done.

**Requests**
- Owner C: switch `UI.chevrons` (ui.gd) from "▲△" glyphs to `Icon.make("up", …)`, for the other screens that use it.
