#!/bin/bash
# BattleChibi Release: setzt Build-ID, exportiert Web, kopiert ins Repo, schreibt version.json, committet und pusht.
# Nutzung: ./release.sh "Commit-Nachricht"
# Variablen: GODOT (Pfad zur Godot-4.7-Binary), PROJ (Projektordner), REPO (Git-Repo mit der Web-Ausgabe)
set -e
GODOT=${GODOT:-/home/claude/scratch/Godot_v4.7.2-stable_linux.x86_64}
PROJ=${PROJ:-/home/claude/scratch/proj}
REPO=${REPO:-/home/claude/battle-chibi-web}
MSG=${1:-"Update"}
BUILD=$(date +%Y%m%d%H%M%S)
cd "$PROJ"
sed -i "s/^const BUILD := \".*\"/const BUILD := \"$BUILD\"/" main.gd
mkdir -p ../build/web
"$GODOT" --headless --path . --export-release Web ../build/web/index.html
B=../build/web
cp $B/index.html $B/index.js $B/index.pck $B/index.png $B/index.wasm $B/index.icon.png $B/index.apple-touch-icon.png $B/index.audio.worklet.js $B/index.audio.position.worklet.js "$REPO"/
cp main.gd units3d.gd touch_controls.gd project.godot export_presets.cfg "$REPO"/source/
echo "{\"v\": \"$BUILD\"}" > "$REPO"/version.json
cd "$REPO"
git add -A
git commit -qm "$MSG" -m "Co-Authored-By: Claude Sonnet 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01UaRsDwqAQTZNMcAuRy8mb8"
git push -q || git push -q
echo "Release $BUILD veröffentlicht"
