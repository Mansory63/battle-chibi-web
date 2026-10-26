#!/usr/bin/env bash
# Startet BattleChibi lokal auf dem PC (kein GitHub Pages nötig).
# Aufruf: ./start_local.sh  -> öffnen: http://localhost:8080/
cd "$(dirname "$0")"
PORT="${1:-8080}"
echo "BattleChibi läuft auf http://localhost:${PORT}/  (Strg+C beendet)"
exec python3 -m http.server "$PORT" --bind 127.0.0.1
