# GDD audit, round 2 - rules for every audit agent

Project: Neon Warlords, Godot 4.3, at `G:\tst\NeonWarlords`. The GDD is extracted in full (paragraphs, headings and every table row, `|`-separated) to `review/gdd/00_full_gdd.txt`. The menu flow chart image is `review/gdd/flowchart.png`. Per-section extracts also exist in `review/gdd/NN_*.txt`.

A first review round already happened (`review/reports/*.md`, fixes in `review/FIXES.md`, decisions in `GDD_COVERAGE.md`). **Play-testing still found 10-20% of the GDD wrong or missing.** That round mostly checked numbers in tables. This round must be stricter and cover every sentence of your section, not only the tables.

## For every GDD item in your section (each sentence, rule, table row and named thing), check all three layers
1. **Stored**: is it in the data model / save (`Game.S`, `Data`, `Warlords`, `Content`)? Right type, right values, migrated for old saves?
2. **Rules**: does the logic do exactly what the GDD says (who, when, how much, caps, refresh timing, costs, edge cases)?
3. **Shown and usable**: can the player see it and act on it in the UI, everywhere it matters? E.g. an attribute of a warlord (rarity, class, syndicate, alignment, rank, rep, level) should be visible on every warlord card/tile/list where a RAID-style game shows it, filterable/sortable in the roster where sensible, explained in tooltips/info panels, and present in recruit reveals, squad pickers and battle HUD where relevant. A rule the player cannot see or reach counts as MISSING (UI).

Example of the kind of gap we are hunting: warlord **alignment** (Paragon / Neutral / Renegade) is stored on the template and used for reputation, but is it shown on the warlord cards, roster, squad picker, recruit reveal? Can you filter by it? Does the reputation screen make clear that a Paragon warlord needs Paragon + Generic deeds? Is there a consistent icon/colour?

Statuses: OK, MISSING (say which layer), WRONG (file:line, GDD says X, code does Y), PARTIAL, DEVIATION (already listed in `GDD_COVERAGE.md` as a deliberate choice - don't flag as bugs, but do flag if the documented deviation is not actually what the code does).

## Hard rules
- **Read-only for game code.** Do not edit anything under `scripts/`, `scenes/`, `assets/`, `data/`, `project.godot`, `GDD_COVERAGE.md`. You may create files only under `tests/audit/<NN>/` and your report `review/audit2/<NN>_<name>.md`.
- **GDD tables are the spec** (based on RAID's real stats). Never propose replacing a GDD table or curve. Where tuning is needed, name the open lever.
- **User decisions to respect** (don't flag): team size 4 (Royal 4+3); Armoury screen kept as is; no turn-order bar; no roster expansion yet; Quick Navigation removed on purpose; credits inflate on purpose; ARMOUR_K 1518; literal Hacking >= Firewall check; Hacker base Hacking 0; regen stops at caps but rewards may overflow; level-up energy = refill only; login day 31 random Epic; no subscriptions yet; Firmware Mk N substitutes one rank-N warlord in rank-up; everything else in GDD_COVERAGE.md "deviations" and "GDD rules enforced".
- Things that need a real backend (real PvP players, Firebase auth/cloud save/analytics) are out of scope; offline stand-ins are fine.
- **Running Godot** (optional but encouraged for logic checks): `G:/tst/tools/Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/audit/<NN>/probe.tscn -- --nwtest` with env `NW_SAVE=audit<NN>`, always under `timeout 300`. Headless only - **no windowed runs**. Never touch or kill a `NeonWarlords.exe` process. Copy patterns from `tests/test_runner.gd`. Compile errors show as `SCRIPT ERROR` lines.
- Entry points: `scripts/core/` (Data.gd tables, Game.gd rules/economy/save, Content.gd encounters/rewards, Warlords.gd roster + abilities, U.gd helpers/reward parsing), `scripts/combat/Battle.gd` (engine), `scripts/ui/Main.gd` (routes), `scripts/ui/ui.gd` (shared widgets incl. warlord cards), `scripts/ui/screens/*.gd`.

## Report (`review/audit2/<NN>_<name>.md`)
1. Table: GDD item | Stored | Rules | Shown | Status | Evidence (file:line) / note. Cover **every** item - a reader should be able to tick the GDD section off line by line.
2. Fix list, prioritised (P1 breaks a GDD rule or the game, P2 missing/wrong player-facing, P3 polish). For each: exact file, function, and the concrete change. Keep fixes inside the GDD; no new systems the GDD doesn't ask for.
3. Final reply to the coordinator: at most 15 lines - counts per status and the P1/P2 fix titles.
