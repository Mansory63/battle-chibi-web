# BattleYaroo – Grafik-Überarbeitung (Stand 28.10.2026)

Branch: `grafik-overhaul` (Backup des Vorstands: `backup/stand-2026-10-28`). Nichts ist auf GitHub veröffentlicht.

## Was geändert wurde
- **Arena (Live-Modus):** flache Cartoon-Fläche in der Briefing-Palette (#289B78, Muster #208164, Akzente #63D34E), warme Wege (#F7AD32) mit heller Kante. Foto-Textur für Gras und Asphalt ist im Live-Modus entfernt.
- **Figuren:** etwas größer (Sprite-Maßstab 1,25 statt 1,1), weicher Kontaktschatten unter jeder Figur, Teamringe schmaler und transparenter.
- **HUD:** Shop in einer Reihe über der Tipp-Leiste, Kampfbereich frei. Tipp-Text passt sich der Leiste an.
- **Match-Start:** Teamkarten zeigen zusätzlich zwei ausgewählte Kämpfer.
- **Einstellungen (Pausenmenü):** GRAPHICS LOW/MEDIUM/HIGH (gespeichert), EFFECTS FULL/REDUCED (weniger Erschütterung, nur große Mündungsblitze).
- **Pausenfenster:** Zwischenrunden-Infos wieder vollständig; Spielerpause ohne überlagerten Rahmen.
- **release.sh:** keine Root-Kopien mehr, gezieltes `git add`, Push nur mit `PUSH=1`.

## Getestet (tatsächlich ausgeführt)
- Headless-Start ohne Parse- oder Script-Fehler nach jeder Änderung (0 Fehler im finalen Lauf).
- Screenshots aus der laufenden Anwendung (xvfb, Software-Rendering): Arena, HUD, Shop, Pausenfenster, Zwischenrunde.
- Windows-Export erfolgreich (BattleYaroo-grafik.zip, 42 MB).

## NICHT getestet bzw. unbestätigt
- **15-Minuten-Dauerlauf:** lief 900 s, aber nur 3235 Frames bei ca. 3 fps. Keine einzige Runde wurde beendet. Dieser Lauf zählt nicht als Nachweis.
- **Leistung / 60 FPS:** nicht gemessen. Die Testumgebung ist Software-Rendering ohne GPU, die Werte sind nicht aussagekräftig.
- **Windows-Build:** nicht gestartet (Test-Rechner nicht verfügbar).
- **Live-Modus mit TikTok, Relay, Wiederverbindung, Teambeitritt, Likes, Geschenkserie:** nicht getestet, kein echter Stream.
- **Hochformat (1080×1920) und Querformat-Layouts:** nicht geprüft.
- **Match-Start-Karten mit Figuren:** Code vorhanden, aber im Screenshot nicht erfasst.
- **Animationen (Idle, Lauf, Angriff, Treffer, Ausscheiden, Wiedererscheinen, Siegerpose):** nicht neu umgesetzt.
- **Stream-Modus (Testknöpfe ausblenden), Waffen-Effekte, Sensenmann-Boss:** nicht umgesetzt.

## Bekannte Restmängel
- Shop und Angriffsknopf verdecken in der Arena noch Figuren rechts unten.
- Ein Banner „ROUND 1 – FIGHT!“ aus dem Pausen-Layer scheint im Hintergrund durch (Altbestand).
- Kamera ist noch nicht nach den Briefing-Werten (Neigung, Höhe) abgestimmt.

## Assets und Lizenzen
- Figurensprites: Free 2D Animated Vector Game Character Sprites von RGSDev, Lizenz CC0.
- Alle übrigen Grafiken sind prozedural im Code erzeugt oder stammen aus dem bestehenden Projekt.
- Keine Figuren, Symbole oder Karten aus den Referenzbildern übernommen.

## Veraltete Dateien
`live.gd`, `main.gd`, `units3d.gd` im Hauptverzeichnis sind alte Kopien (Stand 26.10.). Maßgeblich ist `source/`.
