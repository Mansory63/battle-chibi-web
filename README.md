# BattleChibi

Mobiles Chibi-Battle-Royale (Godot 4.7, 3D-Figuren, Web-Export). Spielbar im Browser:
https://mansory63.github.io/battle-chibi-web/ (iPhone: Safari -> Teilen -> "Zum Home-Bildschirm" für Vollbild)

## Steuerung (Querformat)
- Links: Daumen aufsetzen = Lauf-Joystick
- Rechts: FEUER halten = schießen, Daumen ziehen = zielen (ohne Ziehen: Auto-Ziel auf nächsten Gegner)
- Blitz-Knopf: Sprung (rote Kugel) oder Dash
- Pause-Knopf oben Mitte (PC: Esc/P). PC: WASD, Maus, Leertaste, Shift
- Kisten: ca. 3 Sekunden daneben stehen -> Waffe + Heilung + Schild (Seltenheit grün/blau/lila/gold)

## Features (Stand 1.0)
3D-Welt (Häuser, Bäume, Loot), 3D-Figuren mit Animationen (Kenney Mini Characters, CC0), 8 Kostüme (Saison-Pass, XP/Stufen),
7 Schusswaffen + 3 Nahkampfwaffen, Seltenheiten mit Schadensbonus, Power-Kugeln (Schild/Sprung/Power/Speed), Feuerzone,
Häuser mit Innenraum, 14 Bots (Hardcore: 20, schnellere Zone, stärkere Bots, 2x XP), Minikarte, Sound/Musik, Pause, Tutorial-Hinweise.

## Projektstruktur
- `index.*` = fertiger Web-Export (GitHub Pages), PWA-fähig
- `source/` = Godot-Projekt: `main.gd` (Spiel), `units3d.gd` (3D-Welt/Figuren/Loot), `touch_controls.gd` (Steuerung), `assets/`, `test_*.gd` (Headless-Tests)
- Export: `godot --headless --path source --export-release Web ../index.html` (Web-Vorlage nötig)

## Bekannte Lücken / Ideen
- Kein Online-Multiplayer (braucht Server, nicht kostenlos); Pause ist dafür vorbereitet (`ONLINE`-Flag)
- Boden/Straßen/Deko sind 2D, Schatten nur als Flecken
- Waffe sitzt fest in der Hand (keine Arm-Animation)
- Nur eine Karte (Insel); geplant: Länder-Karten pro Jahreszeit, Fahrzeuge (Skateboards), Events/Turniere
- Kein App-Store-Build (Apple-Entwicklerkonto 99 $/Jahr); kostenlose Alternative: itch.io

## Credits
3D-Figuren: Kenney "Mini Characters" (CC0). Eigene Grafiken/Sounds prozedural erzeugt.

## Changelog
- Block 1 (22.10.): Gras-Variation, animierte Wasserwellen, Schaum am Strand, Bots gleichmäßig verteilt.
- Block 2: Waffen-Rueckstoss beim Schiessen (Waffe ruckt zurueck und kippt).
- Block 3: Performance (3D-Schatten aus, Render-Aufloesung 1.0) fuer fluessigeres Spiel auf dem Handy.
- Block 4: neue Sounds (Kiste, Sieg, Niederlage).
- Block 5: Kartenwahl im Menue (Wiese/Wueste/Schnee), Modus-Button verkleinert.
- Block 6: Kill-Feed im HUD.
- Block 7: Minikarte passt zur gewaehlten Karte.
- Block 8: Treffer-Marker beim Treffen von Gegnern.
- Block 9: PWA-Offline-Cache abgeschaltet (lieferte alte Version aus); Kill-Switch-Service-Worker raeumt alte Caches.
- Block 10: Live-Spieltest ok; Landungs-Anzeige ueberdeckt Pause-Knopf nicht mehr.
- Fix (Nutzerhinweis): Letzte Gegner schwer zu finden -> bei <=3 Gegnern rote Punkte auf Minikarte + rote Pfeile am Bildschirmrand; Zonenschaden fuer Bots steigt im Spielverlauf.
- Grafik: Comic-Umrandung an allen Figuren, ziehende Wolkenschatten ueber der Karte.
