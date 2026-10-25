# Neon Warlords - GDD coverage

Source of truth: `NeonWarlords-GGD.docx` (all tables are machine-extracted into `data/gdd.json`).
"Verified" = checked by an automated test (`tests/TestRunner.tscn`, `tests/UiSmoke.tscn`, `tests/Playthrough.tscn`).

| GDD section | Where it lives | Status |
|---|---|---|
| **Warlord Rank** - consume N rank-N warlords, must be max level, start rank by rarity | `Game.rank_up`, Armoury > Rank | Verified (Playthrough part 1) |
| **Reputation** - deed tables per rarity, alignment + generic deeds, capped at rank | `Data.REP_*`, `Game.rep_up`, Armoury > Rep | Verified |
| **Warlord Level** - 500 XP base, +10% per level and per rank, losses 20% XP, XP split across the squad | `Data.xp_to_next`, `Content.finish` | Verified (XP table spot checks) |
| **Leveling methods** - battle XP + Dojo metabolics, alignment bonus | Armoury > Level (metabolics + warlord feeding) | Verified |
| **Neuronet** - 7 layers x 3 careers, 4 points per layer, 1 of 2 per career, MF tiers & costs, all 42 skill effects in combat | `Data.NEURONET`, `Game.nn_*`, `Battle._nn` | Verified (rules); effects exercised in combat sims |
| **Abilities** - duplicate = +3 levels, Stimm (>= rarity) = +1, active / passive / leader / reinforce | `Warlords.gd`, Armoury > Abilities | Verified |
| **Gear (6 slots) & Implants (3, unlock at rep 2/4/6)** | `Game.equip_on` | Verified (all 9 slots equip, lock rules) |
| **Neons** - same-or-higher rank, matching substat, no crit chance, only from Syndicate Wars | `Game.apply_neon`, Armoury > Upgrade | Verified (exact value added) |
| **Equipment leveling** - credits, 0-20, substat every 5 levels, rarity sets starting substats, rank fixed | `Game.equip_level_up` | Verified (+5/+10/+15 unlocks, +20 roll) |
| **Primary stat matrix / primaries & substats tables** | `Data.SLOT_STATS / PRIMARY / SUBSTAT` | Verified (every slot rolls only legal stats; values = table) |
| **Equipment sets** (8 stat sets + 12 effect sets) | `Data.SETS`, `Game.compute_stats`, `Battle` | Verified (stat sets add exactly); effect sets in combat |
| **Equipment acquisition** - hideouts, campaign (lower quality), shops (credits & premium), PvP rewards | `Content.*_rewards`, Plaza, Black Market, Trinium Exchange, Pit caches | Verified (Playthrough) |
| **Warlord classes / syndicates / statistics / base ranges / scaling** | `Data`, `Warlords._base_stats`, `Game.compute_stats` | Verified (stat sum check) |
| **Combat flow, speed/turn meter, damage & mitigation equations, armour penetration, hacking vs firewall, all buffs/debuffs** | `scripts/combat/Battle.gd` | Verified by thousands of simulated fights |
| **Winning / losing screens** (content, difficulty, stage, XP, drops, contributions, next/replay) | `battle.gd _finish` | Verified (UiSmoke) |
| **Campaign** - 10 locations x 7 stages x 3 difficulties, reward table, drops, chevrons, progression rewards, enemy level table, rotating Corpo Tower set | `Content.build_campaign`, Campaign screen | Verified (Playthrough progression) |
| **Hideouts** - Cardinal Trolls / Vultures / TeraTek / Quantum Vikings bosses as written, generic gear table, Synapse Centre, Heist (5 plans/day), Chopshop, Deeds | `Content.build_hideout`, `Warlords._build_enemies` | Verified |
| **Syndicate Wars** - single-syndicate squads, 20 stages, neon table, bounty tokens 12/day, progression rewards | `Content.build_sw`, SW screen | Verified |
| **Pit Brawls / Pit Royal** - invites (cap 10), defence gang, 10 opponents, brackets, weekly caches, points lost on defence, leaderboards (gang/friends/search), Royal reinforcements & no revives | `Content.pit_*`, `Game.pit_*`, Arena screen | Verified |
| **Pit caches & Black Market** | `Game.open_cache`, `Game.bm_*` | Verified |
| **Bastions** - gang raid, 3 stages over 3 days, damage-based rewards | `Content.build_bastion`, Gang screen | Verified |
| **Trinium Stocks** - 22/44/66 per day, caps 40/60/75 | `Game.stocks_*` | Verified |
| **Currencies & caps** (energy 160, heist 5, bounty 12, invites 10) | `Game.tick` | Verified |
| **Contracts** - pull rates, scrap (10 = contract) | `Game.open_contract / break_down` | Verified (2000-pull distribution) |
| **Player level** - 100-level XP/reward table, energy refill | `Game.add_pxp` | Verified |
| **Monthly login rewards** (no reset on missed days) | Login Rewards screen | Verified |
| **Jobs** daily / weekly / monthly | Missions screen | Verified |
| **Ambitions** (6 categories, tiers) | Missions screen | Verified |
| **Safehouse** - pit-coin nodes per alignment | Safehouse screen | Verified |
| **Gang (clan)** | Gang screen (simulated members) | Implemented (offline) |
| **The Plaza** - hourly credit market | Plaza screen | Verified |
| **Trinium Exchange** - packs, vault, credit bank, market | Shop screen | Verified (all rows purchasable) |
| **Subscriptions** - Player Progress Double Rewards | Shop > Subscriptions | Implemented |
| **Battle Pass** - 100 levels, free/premium, merits, daily x5 / weekly x4, +25 boost | Battle Pass screen | Verified |
| **UI flow chart** - every box | `Main.gd` SCREENS | Verified (UiSmoke opens all) |

Design choices where the GDD is silent or contradictory (all easy to change):
- **Team size 4** (user decision; GDD said 5). Pit Royal = 4 + 3 reinforcements.
- **Firmware Mk N** counts as one rank-N warlord when ranking up (from the Rank screen art and "Rank 3 Firmware" reward wording).
- **Bosses for Synapse / Chopshop / Heist / Deeds / Bastion** were blank in the GDD and were designed to fit.
- **Combat presentation** is RAID-style 3D (user request); models are placeholders pending real art.
- "Tavern" appears in one flow chart but has no GDD text, so it is not implemented.

## Balance tuning: deviations from the GDD's literal numbers

The GDD's stated goal is a long-term gacha with "months of grindy progression". Its literal tables let a
player finish everything in 2-3 weeks, and some exceed its own player cap, so these numbers were re-tuned
toward that intent (structure, modes, stages and reward types are unchanged). Verified with
`tests/ClassProbe.tscn`, `tests/BalanceProbe.tscn` and `tests/Playthrough.tscn`.

| Area | GDD literal | Build | Why |
|---|---|---|---|
| Class damage scaling | "scales off the appropriate stat" (no coefficients) | `Data.CLASS_SCALING`: armour 0.78 x ARM, firepower 1.08 x FP, modder 0.037 x HP, hacker 0.72 x FP + 1.2 x HACK | Damage x effective HP within ~15% per class at R6 (modders were ~2x everyone) |
| Power score | not specified | `Data.stat_power`: geometric mean of offence and effective HP; same formula for players, enemies and Pit opponents | The old weighted sum ignored class and misjudged difficulty |
| Fight length | not specified | `Battle.DAMAGE_SCALE` 1.6 (retuned for the GDD armour constant); mitigation capped at 80%; Overtime after 140 turns (healing cut, damage up); hard loss at 400 turns | Fights ran 100+ player turns; target 15-40 |
| Campaign enemy levels | "Campaign Enemy Warlord Levels" table (to level 125) | **unchanged - GDD table as written** | The GDD scales stats linearly per level, so enemies past the player cap are intended (RAID-based) |
| Den bosses | not specified | strongest named warlord; a syndicate's second den uses another named warlord | Bosses repeated across dens |
| Campaign difficulty climb | not specified (GDD level table kept exactly) | extra enemy gear-equivalent bonus: Street Punk 0, Mob Boss 0 -> 0.6, Warlord 0.80 -> 1.53 by den; den boss HP x1.8 (modder bosses x1.0, legendary x1.2) | Warlord was a random cliff (healer line-ups walled R5, R6 beat everything); now Mob Boss needs R5, Warlord needs R6 and dens 9-10 need maxed R6. Target ~50-65h of total play to finish (RAID ~60h) |
| Campaign line-ups | not specified | fully seeded per stage; at most 1 healer per gang, no repeated named warlord, no healer escorts on Warlord den bosses, no healer bosses from den 4, no legendary bosses before den 6 | Composition spikes made difficulty random |
| Hideout enemy levels | not specified | 4 x stage + 1 to stage 10, +8 per stage to 15, then +16 per stage (stage 20 = level 161); boss HP x(2.5 + 0.15 x stage + 0.6 x max(0, stage - 15)) | Retuned after the GDD armour constant landed. Probe: R5 clears stage 10, stage 15 needs R6, stage 20 is ~50% for a maxed R6 legendary squad and ~0% for R6 epic |
| Pit opponents | real players' defence squads in your bracket | geared squads scaled to 80-115% of your top warlords' power, bracket-adjusted; Royal fields 4 + 3; defence results are simulated battles | Offline stand-in for real players; was trivially winnable |
| Den-boss escorts | not specified | built at boss level -2, never a copy of the boss | Escorts were the boss's own clones |
| Bastion | turn cap and reward tiers blank | 50-turn cap per entry; one damage-tier table per stage; gang boss pool = 1.2x the gang's expected damage | Lets the "Survive 30/45 turns" ambitions complete; makes the top tier reachable |
| Gang NPCs | not specified | member power scales from the player's squad | Offline stand-in for real members |
| Stocks levels | "unlocked through progression missions" (none named) | Lv 2/3 unlock with the Tier 1/2 Campaign tier-completion ambitions | Picks a specific mission for the GDD rule |
| Ability levels | not specified what each level does | abilities with nothing to scale have max level 1 | Duplicates were spent on levels that did nothing |
| Stocks cap upgrade | "additional caps being a microtransaction" (no price) | "Stocks Vault +25 cap", GBP 1.99, up to 4 buys | Price is an open lever |
| Multi-battle | not specified ("idle the game" audience) | AUTO x10 on the campaign stage sheet: replays on auto while energy lasts, stops on a loss | Matches the design canvas and RAID's multi-battle |
| Plaza | "credits buy gear from shops" | adds R5-R6 legendary/epic gear and implants (0.5-1.8M credits) | Late-game credit sink |

## GDD rules enforced (bugs fixed against the document)

- **Heist Plans**: refresh to 5 a day, capped at 5, unused ones lost (reward plans no longer stack past 5).
- **Bounty Tokens**: refresh each day to a max of 12 (same stacking bug).
- **Armour mitigation** follows the GDD worked example: `ARMOUR_K` 1518, so 1518 armour = 50% (was 500; user decision).
- **Hacking vs Firewall** is the literal check: a debuff lands only if Hacking >= Firewall (user decision; was a resist roll).
- **Hacker base Hacking** is 0 with no level or rank growth, as the GDD states (user decision).
- **Caps**: regen and daily resets stop at the cap (Heist 5, Bounty 12, Pit invites 10), but rewards and purchases may go over it, RAID-style (user decision).
- **Player level** stops at 100; reaching L+1 grants row L, and row 100 is a max-level milestone. A level-up's "1x Energy" is the refill, with no extra battery (user decision).
- **Deeds hideouts** drop exactly one of Minor / Major / Grand per win (the GDD chances sum to 100%).
- **Hideout "Bring It On"** is on the hideout boss only (`Content.HIDEOUT_BOSS_IMMUNE`); recruited copies of those warlords don't carry boss immunities.
- **GDD typos fixed** (user decision): Hideout ambition order 11 is Generic Deeds (it repeated Paragon); Warlord ambitions tier 3 is "Recruit 100" (it repeated tier 2's 50).
- **Pit ranking**: wins give x10 points; ranking is only lost when your *defence* is beaten. A failed attack just costs the invite (the build had also docked points for lost attacks).
