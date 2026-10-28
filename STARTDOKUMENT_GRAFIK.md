# BattleYaroo – Grafik-Überarbeitung (Stand 28.10.2026)

Branch: `grafik-overhaul` (Backup des Vorstands: `backup/stand-2026-10-28`). Nichts ist auf GitHub veröffentlicht.

## Was geändert wurde
- **Arena (Live-Modus):** flache Cartoon-Fläche in der Briefing-Palette (#289B78, Muster #208164, Akzente #63D34E), warme Wege (#F7AD32) mit heller Kante. Foto-Textur für Gras und Asphalt ist im Live-Modus entfernt.
- **Figuren:** etwas größer (Sprite-Maßstab 1,25 statt 1,1), weicher Kontaktschatten unter jeder Figur, Teamringe schmaler und transparenter.
- **HUD:** Shop in einer Reihe über der Tipp-Leiste, Kampfbereich frei. Tipp-Text passt sich der Leiste an.
- **Match-Start:** Teamkarten zeigen zusätzlich zwei ausgewählte Kämpfer.
- **Kamera:** Neigung auf ca. 53 Grad unter dem Horizont (vorher ca. 46).
- **Trefferreaktion:** kurze Trefferpose (0,2 s), wenn Lebenspunkte sinken.
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
- **Animationen:** Idle, Lauf, Treffer und Ausscheiden sind vorhanden. Angriff, Wiedererscheinen und Siegerpose fehlen.
- **Stream-Modus:** Debug-Zeile ist standardmäßig aus (`help := false`), nicht gesondert geprüft.
- **Waffen-Effekte, Sensenmann-Boss:** nicht umgesetzt.

## Bekannte Restmängel
- Shop und Angriffsknopf verdecken in der Arena noch Figuren rechts unten.
- Ein Banner „ROUND 1 – FIGHT!“ aus dem Pausen-Layer scheint im Hintergrund durch (Altbestand).
- Kamera-Höhe und Zoom sind nicht gegen Screenshots geprüft.

## Assets und Lizenzen
- Figurensprites: Free 2D Animated Vector Game Character Sprites von RGSDev, Lizenz CC0.
- Alle übrigen Grafiken sind prozedural im Code erzeugt oder stammen aus dem bestehenden Projekt.
- Keine Figuren, Symbole oder Karten aus den Referenzbildern übernommen.

## Veraltete Dateien
`live.gd`, `main.gd`, `units3d.gd` im Hauptverzeichnis sind alte Kopien (Stand 26.10.). Maßgeblich ist `source/`.

## Stand 28.10. (Nachtrag)
- **Profilbilder:** Relay (`relay/tiktok-relay.js`) schickt Zuschauer-Avatare einmal pro Name als Base64; das Spiel zeigt sie als runde Bubbles in Teamfarbe. Ungetestet mit echtem TikTok-Live (Pakete `tiktok-live-connector` und `ws` auf dem PC per `npm install` nötig).
- **Befehle:** Geschenk-Zuordnung vervollständigt (8 Geschenke), Waffenkauf per Chat (`!`-Wörter), Shop-Labels korrigiert. Automatischer Test `test_commands.gd`: 28/28 bestanden.
- **Hochformat:** Layout für Portrait (540x960) mit angepasstem Shop und Tipp-Leiste.
- **Pause:** Qualitätsprofil (niedrig/mittel/hoch) und „Reduzierte Effekte“ über Pausenmenü, gespeichert.
- **Kamera:** Neigung VIEW_TILT 0.80 (ca. 53° nach unten).
- **Figuren (3D-Modelle aktiv, Sprite-Variante aus):** Treffer-Reaktion, Sieg-Pose mit Hüpfen, Wachsen beim Wiederbeleben, Rückstoß beim Schuss.
- **Stresstest:** 15 Minuten Logik-Test ohne Rendering, 5 Runden, keine Fehler. Echte Bildrate ist auf diesem Server nicht messbar (kein GPU).
- **Web-Build:** lädt ohne Konsolenfehler (Playwright-Test).

## Offen
- Windows-Build: `BattleYaroo-final2.zip` (Stand 28.10., Preset „Windows Desktop“ nur in der Testkopie, nicht im Repo).
- Sensenmann-Boss: neu gebaut (Kapuze mit Schädel und glühenden Augen, Knochenhände, gebogene Sense, roter Schimmer, schwebt). Im Test: Spawn ab Sekunde 60, Schaden und K.O. mit Punktevergabe funktionieren. Standbild geprüft.
- Angriffspose für die Sprite-Variante fehlt (3D-Variante hat sie).
- Echte Leistung auf einem PC mit GPU und Windows-Build auf Windows noch nicht geprüft.
