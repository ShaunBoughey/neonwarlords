# GDD section review - rules for every review session

Project: Neon Warlords, Godot 4.3, at `G:\tst\NeonWarlords`. The source GDD is `C:\Users\sboug\Downloads\NeonWarlords-GGD.docx`. Your section's text is extracted to `review/gdd/<NN>_<name>.txt`: one paragraph or table cell per line, with the style in [brackets]. Open the .docx only if a table is unreadable there.

## Your job
1. **Implemented correctly:** check every rule, table value and feature in your section against the code. Each item gets one of these statuses:
   - OK
   - MISSING
   - WRONG (file:line, GDD says X, code does Y)
   - DEVIATION (already documented in `GDD_COVERAGE.md` as a deliberate tuning choice; don't flag these as bugs)
2. **Looks good in game:** take screenshots of the screens and battles your section owns, then look at them. Check:
   - RAID: Shadow Legends-quality presentation that matches the approved design canvas (https://claude.ai/artifact/DMTXzGtAtiDqeKPyEyxZ7h; read it with the Artifact tool, action read).
   - No clipped or overflowing text, no placeholder or debug text, no emoji (the UI uses stroke icons).
   - Every button on your screens leads somewhere and works.
3. **Write your report** to `review/reports/<NN>_<name>.md`:
   - A table of every GDD item with its status.
   - Visual issues, each with the screenshot path.
   - A prioritised fix list (P1 breaks a rule or the game, P2 wrong or ugly, P3 polish). For each fix, give the exact file, function and change.

## Hard rules
- **Do not edit anything under `scripts/`, `scenes/`, `assets/`, `data/` or `project.godot`.** Other review sessions share this folder. Fixes are applied centrally by the coordinating session, from your report.
- You may create files only under `tests/review/<NN>/` (your own probe or screenshot scripts and .tscn files) and your report file.
- **GDD tables are the spec** (they are based on RAID's real stats). Never propose replacing a GDD table or curve with your own. Where tuning is needed, name the open lever (one the GDD leaves unspecified).
- **User decisions to respect** (don't flag these):
  - Armoury screen is kept as is.
  - No turn-order bar in battle.
  - No roster expansion yet.
  - Quick Navigation was removed on purpose.
  - Campaign pacing target is 3-4 weeks for a real player; the bot finishing in ~10 days is fine.
  - Credits inflate heavily with level on purpose.
- **Running Godot:**
  - Portable exe: `G:/tst/tools/Godot_v4.3-stable_win64_console.exe`. Run from the project folder.
  - Always set `NW_SAVE=<NN>` (e.g. `NW_SAVE=07`) and pass `-- --nwtest`. Your test save is then `user://test_save_<NN>.json` and you can't clobber anyone else's.
  - Headless runs (`--headless`) are for logic checks only.
  - Screenshots need a windowed run (no `--headless`); copy `tests/shots.gd` as the pattern. Save them to `user://shots_<NN>/`, which is `C:\Users\sboug\AppData\Roaming\Godot\app_userdata\Neon Warlords\shots_<NN>\`. Keep each windowed run short, and make your script call `get_tree().quit()` when it's done.
  - Compile check: `--headless --path . --import`, then grep the output for `SCRIPT ERROR`. A test runner can print "failures: 0" even when compile fails.
  - Use `timeout` on every run. Never touch or kill a NeonWarlords.exe process (that's the user's own game).
- Helpful entry points:
  - `scripts/core/` (Data.gd tables, Game.gd rules and economy, Content.gd encounters, Warlords.gd roster)
  - `scripts/combat/Battle.gd` (engine) and `battle_view_3d.gd` (3D view)
  - `scripts/ui/Main.gd` (shell and routes), `scripts/ui/ui.gd` (design system), `scripts/ui/screens/*.gd` (one per screen)
  - `tests/test_runner.gd`, `tests/ui_smoke.gd` and `tests/shots*.gd` (examples of driving the game)
  - `GDD_COVERAGE.md` (what was built, and the documented deviations)
- When done, reply with a summary of 5 lines or fewer: counts of OK/MISSING/WRONG, your top 3 fixes, and the report path.
