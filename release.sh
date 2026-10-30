#!/bin/bash
# BattleYaroo Release (korrigiert 28.10.2026)
# Nutzung: ./release.sh "Commit-Nachricht"
# Variablen: GODOT, PROJ (Projektordner mit den aktuellen Dateien), REPO (Git-Repo)
# PUSH=1 setzt den Push nach origin frei. Ohne PUSH=1 wird nur lokal committet.
set -e
GODOT=${GODOT:-/home/claude/scratch/Godot_v4.7.2-stable_linux.x86_64}
PROJ=${PROJ:-/home/claude/scratch/fix-run}
REPO=${REPO:-/home/claude/battle-chibi-web}
MSG=${1:-"Update"}
BUILD=$(date +%Y%m%d%H%M%S)
cd "$PROJ"
sed -i "s/^const BUILD := \".*\"/const BUILD := \"$BUILD\"/" main.gd
mkdir -p ../build/web
"$GODOT" --headless --path . --export-release Web ../build/web/index.html
B=../build/web
cp $B/index.html $B/index.js $B/index.pck $B/index.png $B/index.wasm $B/index.icon.png $B/index.apple-touch-icon.png $B/index.audio.worklet.js $B/index.audio.position.worklet.js "$REPO"/
# Nur die Quelldateien aus dem Projektordner; keine Root-Kopien
# Nur Spielcode: Test-, Screenshot- und Render-Skripte bleiben lokal (nicht im Repo)
for f in "$PROJ"/*.gd; do
  case "$(basename "$f")" in test_*|shot_*|render_*) continue ;; esac
  cp "$f" "$REPO"/source/
done
cp "$PROJ"/project.godot "$PROJ"/export_presets.cfg "$REPO"/source/
echo "{\"v\": \"$BUILD\"}" > "$REPO"/version.json
cd "$REPO"
git add index.html index.js index.pck index.png index.wasm index.icon.png index.apple-touch-icon.png index.audio.worklet.js index.audio.position.worklet.js version.json source
git commit -qm "$MSG" -m "Co-Authored-By: Claude Haiku 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01UaRsDwqAQTZNMcAuRy8mb8"
if [ "${PUSH:-0}" = "1" ]; then
  git push -q origin HEAD:main
  echo "Release $BUILD veröffentlicht (Push nach origin)"
else
  echo "Release $BUILD lokal committet, KEIN Push (PUSH=1 zum Veröffentlichen)"
fi
