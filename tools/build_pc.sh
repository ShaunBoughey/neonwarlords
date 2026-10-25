#!/usr/bin/env bash
# Build the Windows PC version into ../build:
#   NeonWarlords.exe  - the Godot 4.3 runtime (auto-loads the .pck with the same name)
#   NeonWarlords.pck  - the game (tests, tools and source art excluded; see export_presets.cfg)
# No export templates needed. Run from the project folder:  bash tools/build_pc.sh
set -e
cd "$(dirname "$0")/.."
GODOT=../tools/Godot_v4.3-stable_win64_console.exe
# never overwrite the pack under a running game (it streams resources from it and breaks):
# close a running copy first, then wait until Windows releases the files
if tasklist 2>/dev/null | grep -qi "NeonWarlords.exe"; then
	echo "Closing the running game before rebuilding..."
	taskkill //IM NeonWarlords.exe >/dev/null 2>&1 || true
	for i in 1 2 3 4 5 6 7 8 9 10; do
		tasklist 2>/dev/null | grep -qi "NeonWarlords.exe" || break
		sleep 1
	done
	taskkill //F //IM NeonWarlords.exe >/dev/null 2>&1 || true
	sleep 1
fi
mkdir -p ../build
"$GODOT" --headless --path . --export-pack "Windows Desktop" ../build/NeonWarlords.pck
cp ../tools/Godot_v4.3-stable_win64.exe ../build/NeonWarlords.exe
cp tools/build_readme.txt ../build/README.txt
echo "Built: $(cd ../build && pwd)"
