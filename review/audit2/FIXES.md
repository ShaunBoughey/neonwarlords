# Audit round 2 - fix wave

Reports: `review/audit2/0N_*.md`. Item refs are `<report>:<item>` from each report's fix list. Each owner edits **only its own files**. Coordinator already applied: alignment badge/tooltip/rank stars on cards (`UI.warlord_card`, `UI.align_badge`, `UI.rank_stars`, `UI.warlord_tooltip`, `UI.ALIGN_INFO`, Icon "paragon/neutral/renegade/generic"), Armory alignment + class filters and Rank/Rep sorts, warlord detail alignment chip + info modal, rep page alignment line + cost table, Dojo label + matching metabolic "+50%" mark, drawer card badge, recruit reveal tags, battle hover tags, starter kit generic metabolics removed, Vikings desc (01:P2 1-6, 01:P3 7, 10, 12, 16). Don't redo those.

**HELD (user decision pending - do not change):** hideout/enemy Hacking (05:P1), equipment ambition Gloves CC/CD (07:P1), starter neons, feeding XP, alignment distribution, Royal invites from missions, player XP on loss, whether jobs/BP "Complete N dens" count only wins, BP "Set <rarity> Warlord" meaning, Synapse 42-52 typo, the £10 +25 upgrade.

## Owners and items

**A - combat** (`scripts/combat/Battle.gd`, `scripts/combat/battle_view_3d.gd`, `scripts/ui/unit_hud.gd`, `scripts/ui/hex_button.gd`, `scripts/ui/screens/battle.gd`)
- 02:P2 1 Adaptive Networks heals on Hacking-vs-Firewall resists too; 02:P2 2 debuff check order per GDD (chance > Hacking vs Firewall > Block Debuffs > existing > refresh/stack > place); buff order likewise.
- 02:P2 4 status icons: unique, readable glyph per buff/debuff (no shared star/bolt, no cryptic letter codes), and a per-icon hover/tap tooltip with name, value and turns left (unit_hud + battle.gd `_hover`).
- 02:P3 armour penetration into the mitigation step exactly as the GDD example (mitigation% - penetration%), sourced from the existing ignore-armour effects (Fracture, Ripper, Celestial Strike/Smite, Devour) so behaviour is consistent; DDoS-spread Bleed uses a real damage basis; Bait and Switch respects the attacker's immunities and Block Debuffs; an extra turn cannot be stolen by another unit over 100% TM.
- 06:P3 Pit Royal: show "No revives in Pit Royal" in the battle intro/HUD for royal fights.

**B - warlord & equipment UI** (`scripts/ui/screens/warlord.gd`, `scripts/ui/item_view.gd`, `scripts/ui/screens/inventory.gd`, `scripts/ui/ui.gd`) - note the coordinator's new code in warlord.gd/ui.gd; re-read before editing.
- 02:P2 3 Neuronet info shows flat Hacking/Firewall as flat numbers, not %.
- 03:P2 1 set display: show partial sets with pieces worn (e.g. "Plague 3/4"), active vs inactive.
- 03:P2 2 inventory filters: set, rarity, rank + a sort choice.
- 03:P2 3 item popup explains why Apply Neon is unavailable.
- 03:P2 4 implant Rep 2/4/6 requirement in item popup + tooltip; gear modal flags a locked implant slot.
- 01:P3 8 uncommon Stimm slot; 01:P3 9 ability modal shows multiplier and scaling stat.
- 03 other P3s in its report if cheap.
- 06:P2 2 inventory cache "Open" buttons: show cache contents via `CacheInfo.show(main, kind)` (provided by D).

**C - core rules** (`scripts/core/Content.gd`, `scripts/core/Game.gd`, `scripts/core/Data.gd`, `scripts/core/U.gd`, `scripts/core/Warlords.gd`)
- 04:P2 1 campaign additional drops: exactly one drop per win, picked by the GDD chances (like the deeds hideouts).
- 07:P3 inbox trimming must never delete unclaimed rewards.
- 07:P3 "Recruit N Warlords" ambitions don't count the starter warlords; Account screen text claim about ambition XP - report to coordinator (screen is D's).
- 01:P3 15 Plaza pool: add missing metabolic alignment/tier combos (costs = open lever, keep in line with existing rows).
- 08:P3 add a description string for the Raid Boss Ticket where shop rows get their text, if it lives in Data.

**D - screens** (`scripts/ui/screens/shop.gd`, `battle_pass.gd`, `arena.gd`, `syndicate_wars.gd`, `black_market.gd`, `city.gd`, `campaign.gd`, `hideouts.gd`, `gang.gd`, `missions.gd`, `account.gd`, `scripts/ui/district_diorama.gd`, `scripts/ui/Main.gd`, new file `scripts/ui/cache_info.gd`)
- 08:P2 1 refill limit key; 08:P2 2 Heist Plan row not disabled while holding plans; 08:P2 4 hide/disable "Premium + 25" when it would give nothing; 08:P3 Raid Ticket card text, Trinium-buy confirmation, set labels keep "Legendary".
- 06:P2 1 countdown to daily refresh for Bounty Tokens and Brawl/Royal Invites (and Bastion reset 06:P3).
- 06:P2 2 new `scripts/ui/cache_info.gd` (`class_name CacheInfo`, `static func show(main, kind: String)`) - modal listing Meager/Substantial/Sublime/Exalted contents and chances from the GDD table data; hook into arena weekly cache label and brackets tab.
- 06:P3 SW chevron criteria explained, SW neon stat "random, equal chance", bracket progress bar, buy-invites shortcut when out.
- 05:P2 gear slot odds (16.6% each) in `hideouts.gd` `_reward_lines`.
- 04:P2 2 Tavern/Dojo box on the City Centre that opens the warlord Level (Dojo) page; 04:P3 say when the next campaign difficulty unlocks; drop preview rarity from real odds; 10-den overview if cheap.
- 07:P3 locked-feature jobs show an unlock hint.

## Rules
- Read `review/audit2/README.md` hard rules (GDD tables are spec; respect user decisions). You may now edit your owned files only. Use Edit, keep edits small, re-read before editing.
- Compile check: `timeout 300 G:/tst/tools/Godot_v4.3-stable_win64_console.exe --headless --path . --import 2>&1 | grep "SCRIPT ERROR"` (errors in others' files may be their half-done work - report, don't fix).
- When done: run `res://tests/TestRunner.tscn` headless with `NW_SAVE=fix<owner>` and `-- --nwtest` under timeout; no windowed runs; never touch NeonWarlords.exe.
- Append "Applied" to your section of the relevant report(s) and reply in at most 8 lines: what changed, what was skipped and why, and any request for another owner.
