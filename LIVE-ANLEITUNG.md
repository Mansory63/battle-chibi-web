# BattleYaroo – TikTok-Live-Modus

## Starten
- Im Menü links unten auf **LIVE-MODUS** tippen, oder die Seite mit `?live=1` öffnen:
  `https://mansory63.github.io/battle-chibi-web/?live=1`
- `&demo=1` startet simulierte Zuschauer (zum Ausprobieren ohne TikTok).
- `&ws=ws://localhost:8765` verbindet das Spiel mit dem Relay (siehe unten).

## Ablauf
4 Teams (Rot, Blau, Grün, Gelb) mit je 12 Kämpfern, Runde 5 Minuten, 20 s Pause, danach automatisch die nächste.
Zuschauer schreiben `rot`, `blau`, `grün` oder `gelb` → eigener Kämpfer mit Namen. Nachrücken geht mitten in der Runde, wenn im Team ein Platz mit Bot frei ist.
Likes füllen eine Leiste (100) → Kiste für das Team. Alle 30 s fällt eine Gratis-Kiste (reihum). Geschenke geben dem Kämpfer eine Waffe (Stufe nach Münzwert: <10 selten, <100 episch, ab 100 legendär) und beleben ihn wieder. Teilen heilt das Team, Follow zeigt eine Begrüßung, `zeig mich` stellt ihn in die Kamera-Warteschlange.

## Testtasten (PC)
1–4 Beitritt, 5 viele, L Likes, G Geschenk, F Follow, S Teilen, Z zeig mich, N Runde beenden, D Demo an/aus, H Hilfe.

## Anbindung (UNGEPRÜFT)
Das Spiel nimmt JSON-Ereignisse an: `{"event":"chat|like|gift|follow|share","data":{"nickname":"..","comment":"..","likeCount":5,"giftName":"Rose","diamondCount":1}}`
- Per WebSocket (`?ws=`), z. B. mit `relay/tiktok-relay.js` (Node.js, inoffizielle Bibliothek tiktok-live-connector) oder einem Programm wie TikFinity, falls es ein passendes Format sendet.
- Per Browser-Konsole: `bcLive({event:'gift',data:{nickname:'Max',giftName:'Rose',diamondCount:1}})`.
Nichts davon wurde mit echtem TikTok getestet.

## Zusätzlich
Boss ab 1:40 (besiegen = 3 legendäre Waffen), Krone für den Top-Unterstützer je Team, Siegesserie in der Teamleiste.

## Offen
Kamera-Zoom nach Zonengröße, Kill-Wiederholung, 100+ Kämpfer. Geschenk-Zuordnung (GIFT_WEAPONS in live.gd) ist ein Vorschlag.

## Stand 24.10. (Handoff für ChatGPT/Claude)
- Performance: 2D-Draw-Calls ca. 1.240 → ca. 600 (Textur-Discs, Zonen-Shader).
- Hinzugekommen: Knast mit 14 Zombies (Ausbruch nach 45 s bzw. wenn man nahe kommt; Zombies zählen nicht für Sieg), Wahrzeichen (Eiffelturm, Big Ben, Pisa, Brandenburger Tor, Kolosseum), weniger Häuser (51 Gebäude).
- Atombombe: Geschenk „Universe“ oder ab 40.000 Münzen. 3 s Warnung, dann Druckwelle, Pilzwolke, nur Spender überlebt (Bunker), Rest wird zu Knochen. Testtaste B.
- Wake Lock für Dauerbetrieb.
- Offen: runde Figuren/bessere Effekte, Probelauf auf iPhone, TikTok-Geschenkdaten verifizieren (Name + Münzen), Dauertest, Sonderfall Einsturz/Ausbruch-Feinschliff.

## Entscheidungen (24.10., selbst getroffen)
- Zonen-Tempo: Standard 1,0 (Runde ca. 5 Min.). Einstellbar über [ ] bzw. ?zone=.
- Runde Figuren: noch NICHT umgebaut. Erst nach iPhone-Test, dann Probe-Figur.
- Geschenkwerte: Atombombe nur über Name „Universe“. Münz-Schwelle erst mit echtem TikTok-Geschenk ändern.
- Zone: Start außerhalb der Karte (3400), Feuer blendet erst bei Berührung ein.
