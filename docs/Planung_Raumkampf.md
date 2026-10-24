# Planung Raumkampf (Version 1)

Stand: 16.10.2026, Modul Raumkampf, Branch `claude/raumkampf-modul`. Entscheidungen des Nutzers aus dem Klärungsgespräch (Auftrag 1). Noch nichts gebaut. Regeln im Einzelnen: `docs/Raumkampf.md`.

Kennzeichnung: **Entscheidung** = vom Nutzer gewählt. **Vorschlag** = von Claude, noch nicht bestätigt. **Offen** = ungeklärt.

## 1. Entscheidungen des Nutzers

| Thema | Entscheidung |
|---|---|
| Umfang V1 | **Nur Mutterschiff** auf Spielerseite. Eigene Jäger in Version 2; das Datenmodell wird so angelegt, dass Jäger später als weitere Einheiten dazukommen. |
| Darstellung | **3D mit Hexkarte** (eine Ebene, ohne Höhe), wie der Bodenkampf. |
| Stationen | Steuer, Navigation, Schilde, Technik, Computer und **mehrere Geschützstationen** (je Waffengruppe/Slot-Gruppe eine). |
| Besetzung | **Feste Posten an Bord** (im Hub festgelegt, wie der Koch in der Kombüse), **vor dem Kampf änderbar**. |
| Freie Stationen | **Beides wählbar** je Station: Bord-KI mit festem Bonus oder Doppelbesetzung durch eine Person (beide Würfe mit Malus). |
| Gegner | **Schiffe und gegnerische Jäger**. Gegnerseiten: **Fraktionen aus den Missionen** (`data/missions`) bekommen Schiffe, dazu **eigene Raumgegner** (z. B. Piraten, Militär, Drohnen). |
| Gegen Jäger | **Beides**: Hauptgeschütze können Jäger treffen (Spalte „Jäger“), eine **Punktverteidigung** ist dafür besser (auch gegen Raketen). |
| Rundenablauf | **Phasen**: Schilde → Bewegen → Schießen → Technik/Computer; innerhalb jeder Phase nach Initiative. **Schildphase vor dem Schießen.** |
| Auslöser | **Reiseereignis**, **Auftrag** (eigene Auftragsart), **vor einem Bodeneinsatz** (z. B. Blockade), **Schnellkampf im Startmenü**. |
| Kampfende außer Sieg | **Flucht per Sprung**, **Kapitulation/Lösegeld**, Niederlage → **Entern (Bodenkampf)** oder **Notfall**, **je nach Gegner** (z. B. Piraten entern, Militär/Drohnen nicht). |
| Entern in V1 | Übergang in den Bodenkampf mit der **Lagerhalle als Platzhalter**; Karte „Schiffsinneres“ als späterer Auftrag an das Bodenkampf-Modul. |
| Schaden danach | **Hüllenschaden geht auf `HubState.hull`**, **Systemschäden bleiben** bis zur Reparatur. |
| Crew-Verletzung | **Ja**, über den Kritischen „Crew-Station“ (Verwundung wie am Boden, `core/injury.gd`). |
| Ausbau | **Mischung**: Schiffswaffen in **Slots** (konkrete Waffen), **Schilde und Schiffspanzerung als Ausbau-Stufen**. |
| Munition | **Eigene Schiffsmunition**, getrennt vom Bodenvorrat `HubState.ammo`. |
| Beute bei Sieg | **Credits, Schiffsmaterial, Schiffsmunition, Schiffswaffen** (ggf. beschädigt, ins Lager). |
| Umfang V1 bei Ausbau/Handel | **Alles in V1**: Slots, Kauf im Hafen, Beute ins Lager, Munitionskauf. |
| Schiffsanzeige | **Schildring (6 Segmente) und Hüllenbalken immer in 3D an jedem Schiff** auf der Karte; dazu ein **Kasten links oben** für das eigene Schiff, per Klick zwischen **Schema** (Umriss mit Schildbögen und Systemsymbolen) und **Zahlen** (Hüllenbalken, Schild je Seite, Systemschäden) umschaltbar. |
| Stationen auf dem Bildschirm | **Einklappbare Seitenleiste rechts**, wie im Bodenkampf. |
| Hub-Anbindung | Koordinator hat entschieden: **Hub baut die Auslöser** (siehe 1a). |

## 1a. Entscheidungen des Nutzers (Auftrag 2, 16.10.2026)

| Thema | Entscheidung |
|---|---|
| Energie | **Energie im Kampf**: Reaktor gibt je Runde Energiepunkte; verbraucht von **Strahlwaffen, Schild-Aufladung, Antrieb, Sprung vorbereiten**. Verteilt von der **Schild-Station**. Nichts bleibt nach dem Kampf. |
| Reaktor | Neuer Ausbau-Bereich **„Reaktor“** (Stufen 0–3). |
| Schiffsmunition | **2 Arten**: Schiffsraketen, Geschosse. |
| Slots | Start **Bug, Backbord, Steuerbord, Turm**; neuer Ausbau-Bereich **„Waffenslots“**: Stufe 1 Heck, Stufe 2 Bug 2, Stufe 3 Turm 2. |
| Slotgrößen | **Nur der Turm ist besonders** (nur Abwehrwaffen); sonst passt jede Waffe überall, der Feuerbogen hängt am Slot. |
| Bestätigt | Bord-KI **+0** (Änderung des Nutzers 16.10.2026, vorher +20), Doppelbesetzung −30, Flucht: Sprung nach 2 Runden Vorbereitung (Probe Navigation mittel), kostet Energie und Treibstoff, Ende ohne Beute, Auftrag bleibt offen. |
| Systemschäden | **Stufen A–E** (E = ausgefallen); betroffen: Antrieb, Sensoren, Lebenserhaltung, Schilde, Reaktor, einzelne Waffenslots, Stationen (Person dort verletzt). |
| Zahlen | **Erst nach dem Bau**: Platzhalter, Feinschliff per Simulation. Ebenso die **Gegnerzahl je Schwierigkeit**. |
| Beute, Lösegeld | **Raumkampf würfelt aus**, der Hub bucht nur. |
| Waffendaten | **Raumkampf-Katalog** `ShipWeapons`; der Hub liest Keys, Namen, Preise. |
| Karte V1 | **Mittel (ca. 20×14) mit Asteroiden** (Deckung, blockieren); Trümmer und Nebel später. |
| Zuständigkeit | Koordinator, Auftrag 2: Raumkampf nur eigene Dateien, Hub alle Auslöser und Hub-Dateien, Bodenkampf und Charakter in V1 nichts. |

## 1b. Entscheidungen nach dem ersten Testkampf (16.10.2026)

| Thema | Entscheidung |
|---|---|
| Bewegung | **Ziel-Check** in der Steuer-Karte (welche Waffe trifft nach dem Plan wen) und **Schatten** der geschätzten Gegnerpositionen (Schätzung der KI). |
| Waffenslots | Ausbau mit **5 Stufen**: Heck, Backbord 2, Steuerbord 2, Bug 2, Turm 2. |
| Notreparatur | **Bis zu 3 Techniker** (auch von anderer Station abgezogen = Doppelbesetzung), jeder **eine 2. Baustelle mit −20**. |
| Selbst entern | **Ja, in V1:** Gegner benachbart, mit Besatzung (kein Jäger/Drohne), Antrieb E oder Hülle < 25 %, **nur wenn kein anderer Gegner mehr kämpft**. Raumkampf endet, Hub startet Bodenkampf; Beute an Bord nur bei Sieg dort. |
| Schwierigkeit mittel | **Zwei Varianten:** Korvette mit 1 Jäger oder mit 2 Jägern (Annahme: Fregatte nur noch bei schwer). |
| Modelle | Bug war hinten → um 180° gedreht. |
| Fragerunden | Am Ende jeder Fragerunde eine **Abschlussfrage mit Freitext** (Wunsch des Nutzers, auch für die anderen Module). |
| Umbesetzen im Kampf | **Nur zu Rundenbeginn** (Schildphase) über den Knopf **„Posten umbesetzen“**; wer an eine Station neu kommt, hat dort in dieser Runde **−10**. |
| Schildverteilung | Gab es schon (Auswahl in der Schilde-Karte), war aber leicht zu übersehen → deutlicher beschriftet, dazu **Schieberegler je Seite** (Schwerpunkt setzt sie vor; zu viel wird gekürzt, Rest geht auf die schwächsten Seiten). |

## 1c. Abstimmung per Simulation (Auftrag 3, 17.10.2026)

**Ziele des Nutzers:** Siegquote der Crew 90 / 70 / 45 % (leicht / mittel / schwer), Kampfdauer 8–12 Runden, Flucht unter 10 %; Kapitulation und eigenes Entern nur ausweisen; Entern durch Gegner folgt aus den Niederlagen. Crew-Seite = Vorschlag der Bord-KI, gemessen nur mit dem Startschiff und der Startcrew. Waffenpreise nach Stärke. Gegnervorlagen nach `data/ships/`.

**Simulation:** `godot --headless --path godot --script res://tests/sim_space.gd -- 150` (Kämpfe je Schwierigkeit, alle Gegnerseiten reihum) und `… -- 200 waffen` (Wirkung je Waffe im Bug bzw. Turm, reichlich Munition).

**Ergebnis** (3 Messreihen × 150 Kämpfe, Schwankung etwa ±4 %):

| Schwierigkeit | Siege (Ziel) | Runden Ø | Flucht | Abbruch (40 R.) | geentert | Notfall | selbst entert |
|---|---|---|---|---|---|---|---|
| leicht | 87–91 % (90) | 7,6–8,1 | ≤ 1 % | 0 % | 5–8 % | 4–6 % | 0–2 % |
| mittel | 67–70 % (70) | 11,0–11,1 | ≤ 1 % | 1–2 % | 15–19 % | 12–13 % | 0–2 % |
| schwer | 47–49 % (45) | 11,0–11,9 | ≤ 1 % | 1–2 % | 29–32 % | 20 % | 3–5 % |

**Geändert:**
- **Crew-KI** (auch Knopf „Vorschlag“): wählt die Bewegung nach dem Ziel-Check (möglichst viele Waffen feuerbereit gegen die geschätzten Gegnerpositionen) statt nur den Bug zum Gegner; ohne Schussfeld nähert sie sich an. **Gegner-KI** meidet Endfelder ohne Sicht. Damit gibt es kaum noch Patts hinter Asteroiden (vorher 30 % Abbrüche an der Rundengrenze).
- **Trefferschwellen** je um 25 gesenkt (`SpaceCombat.THRESHOLDS`), **Schaden** aller Waffen ×0,9 (`DMG_SCALE`).
- **Gegner** (`data/ships/schiffe/`): Besatzung Jäger 20, Drohne 15, Korvette 25, Fregatte 20, Kreuzer 20 (vorher 35/30/35/45/50); Korvette Hülle 70, Fregatte Hülle 80 / Schild 10 / Aufladung 3 / Panzerung 1, Kreuzer Hülle 100 / Schild 14 / Aufladung 4 / Panzerung 2 mit 3 statt 4 Waffen.
- **Aufstellungen:** schwer = Fregatte + 1 Jäger, Kreuzer, oder 2 Korvetten; Drohnen mittel 5 Drohnen, schwer Fregatte + 2 Drohnen.
- **Waffenpreise** (`ShipWeapons`, ≈ 415 Cr je Schadenspunkt pro Runde, Laserbank = 900): Laserbank 900, Partikelkanone 1350 (vorher 1800), Massebeschleuniger 1050 (1200), Schnellfeuerkanone 1300 (1100), Raketenwerfer 2150 (1300), Raketenbatterie 2100 (2200), Abwehrgeschütz 1150 (800), Abwehrlaser 1150 (1000). Raketenwaffen sind mit genug Munition die stärksten, verbrauchen aber Raketen (60 Cr je Stück).
- **Unverändert:** eigenes Schiff (`SpaceSetup`: Schilde, Schiffspanzerung, Reaktor, Startmunition 6/40), Ausbaustufen und ihre Zahl, Bord-KI +0. Eine höhere Startmunition (8/60) wurde gemessen, bringt aber nur wenige Prozent und würde `test_hub` (Hub-Datei) brechen – darum nicht übernommen.
- **Gegnervorlagen** liegen jetzt als Ressourcen in `data/ships/schiffe/*.tres` (`ShipTemplateData`) und `data/ships/seiten/*.tres` (`SpaceFactionData`, Aufstellungen je Zeile „korvette,jaeger“), im Editor bearbeitbar.

**Offen:** Ausbaustufen (halb/voll) sind nicht gemessen (Entscheidung: nur Startschiff); Menschen spielen vermutlich besser als die Crew-KI, die Quoten sind also eher untere Werte (Annahme, nicht gemessen).

## 1d. EP im Raumkampf begrenzt (Auftrag 4, 18.10.2026)

Befund: Schützen bekamen EP je Schuss (bis ~30 je Kampf). **Entscheidungen des Nutzers:** Schützen +1 je Runde mit Schuss/Abfangen, +1 bei Treffer; **höchstens 2 EP je Station und Runde für alle Stationen**; Navigation würfelt jede Runde eine Initiative-Probe (mittel, Erfolg +2/Herausragend +4 Initiative); Doppelbesetzung: EP je Station; **keine** Obergrenze je Kampf.

Messung `tests/sim_space.gd -- 60 ep` (Startcrew, 3 Aufstellungen × 3 Schwierigkeiten × 60 Kämpfe; nur von Crew besetzte Stationen; Ø 7–11 Runden je Kampf):

| Station | vorher Ø je Kampf | vorher höchstens | vorher je Runde | nachher Ø je Kampf | nachher höchstens | nachher je Runde |
|---|---|---|---|---|---|---|
| Steuer | 9,8 | 73 | 1,30 | 10,0 | 75 | 1,30 |
| Navigation | 0,3 | 5 | 0,05 | 8,4 | 54 | 1,40 |
| Schilde | 9,0 | 63 | 1,18 | 9,1 | 61 | 1,19 |
| Technik | 6,6 | 62 | 0,81 | 5,9 | 55 | 0,71 |
| Technik 2 | 2,8 | 13 | 0,46 | 3,1 | 32 | 0,51 |
| Technik 3 | 2,4 | 11 | 0,39 | 2,4 | 11 | 0,40 |
| Computer | 7,1 | 48 | 0,88 | 7,2 | 49 | 0,87 |
| Geschütz Bug | 3,5 | 13 | 0,53 | 3,1 | 10 | 0,48 |
| Geschütz Backbord | 3,9 | 24 | 0,47 | 4,1 | 23 | 0,48 |
| Geschütz Steuerbord | 4,5 | 10 | 0,70 | 4,3 | 9 | 0,67 |
| Punktverteidigung Turm | 12,3 | 35 | 1,89 | 6,7 | 20 | 1,04 |

Lesart: Alle Stationen liegen jetzt bei höchstens 2 EP je Runde, also höchstens etwa 16–22 EP in einem Kampf von 8–11 Runden. Die Höchstwerte über 40 stammen aus sehr langen Kämpfen (bis 40 Runden, keine Obergrenze je Kampf gewünscht). Die Schützen liegen in der Simulation niedriger als im Spieltest des Nutzers, weil die Crew-KI die Seitengeschütze seltener in den Bogen bringt (Annahme; ein Mensch, der jede Runde feuert und trifft, kommt auf 2 EP je Runde). Siegquoten nach der Änderung unverändert im Ziel (91 / 67 / 47 %).

## 1e. Entern (Auftrag 5, 18.10.2026)

Meldung des Nutzers: nie selbst geentert, nie geentert worden. **Messung vorher** (`tests/sim_space.gd`-Umgebung, 3 × 150 Kämpfe, Entern-Bedingung nach jeder Phase geprüft): selbst entern möglich in **1 / 0 / 1 %** der Kämpfe (leicht/mittel/schwer) – Hauptgrund: Nachbarfeld nötig, die Gegner halten ~4 Felder Abstand; geentert werden bei **9 / 41 / 58 %** der Kämpfe gegen enternde Seiten (jede Niederlage dort). Varianten gemessen: Grenze 40/50 % kaum Wirkung, 2 Felder Reichweite +5–7 Punkte, Kombinationen 11–20 %, „einholbar“ (≤ 5 Felder) 37–59 %.

**Entscheidungen des Nutzers** (Grundidee: Schiffe sind kostbar, Niederlage nicht endgültig): Wrack statt Zerstörung; selbst entern bei Antrieb E / Hülle < 25 % / Wrack, Entfernung egal, Pilotenprobe nach Entfernung (+20 bei hilflosem Ziel), Frage „Entern ja/nein“, nur wenn kein anderes Schiff mehr kämpft (Jäger ziehen ab); Patzer = Kollision; Gegner entern früher mit Anflug (ab eigener Hülle < 25 %); gewonnener Enterkampf = Raumkampf gewonnen (beide Richtungen). Regeln: `docs/Raumkampf.md` 4c.

**Messung nachher:** selbst entern möglich in **35 / 49 / 49 %** der Kämpfe (davon erst als Wrack 9 / 18 / 13 %); Gegner können entern in **13 / 47 / 68 %** der Kämpfe gegen enternde Seiten. In der Simulation (Crew-KI entert immer, wenn möglich) endeten **30–34 / 62–65 / 79–83 %** der Siege mit Andocken; Siegquoten 91 / 67–78 / 47–55 % – dabei zählt ein gelungenes Andocken als Sieg, der Bodenkampf an Bord ist nicht mitgerechnet.

## 1f. Seiten der neuen Fraktionen (Auftrag 6, 19.10.2026)

Entscheidungen des Nutzers: eigene Seiten in `data/ships/seiten/` für `semidrug`, `eisenwoelfe`, `schwarze_flagge`, `aasgeier`, `neuntes_haus`, `kinder_der_glut`; **kein** neues Eigenheit-Feld, die Eigenheiten vom Boden (`docs/Skillsystem.md` 7.4) werden sinngemäß über die vorhandenen Felder und **einen eigenen Schiffstyp je Fraktion** (Abwandlung der Korvette) übertragen; Ziel wie bisher (etwa 90/70/45 %). Aufstellungen = Standardaufstellungen mit dem eigenen Typ statt der Korvette (Fregatte, Kreuzer, Jäger gemeinsam).

| Seite | Niederlage / Lösegeld / Flucht | Schiffstyp: Abweichung von der Korvette (nach Abstimmung) |
|---|---|---|
| Semidrug Inc. | abziehen / 800 / nie | Semidrug-Korvette: Initiative 8 (+2), Laserbank + Partikelkanone, Besatzung 26 (+1) |
| Eisenwölfe | entern / 600 / 20 % | Wolfskorvette: Hülle 77 (+10 %), Massebeschleuniger statt Laserbank, Besatzung 21 (−4) |
| Schwarze Flagge | entern / 400 / 25 % | Enterkorvette: Tempo 4/5 (+1) |
| Aasgeier | entern / 300 / 35 % | Aasgeier-Korvette: Besatzung 20 (−5), Hülle 63 (−10 %), Material 4 (+1); je Aufstellung ein Jäger mehr |
| Das Neunte Haus | entern / 500 / 35 % | Schattenkorvette: VW 7 (+2), Besatzung 26 (+1), Credits 400 |
| Kinder der Glut | entern / 0 / nie | Glutkorvette: Partikelkanone statt Laserbank, Besatzung 23 (−2) |

Änderungen beim Abstimmen (Startwerte siehe Vorschlag im Chat): Wolfskorvette Besatzung 25 → 21 und Flucht 10 → 20 %, Glutkorvette Besatzung 30 → 23, Schattenkorvette VW 10 → 7 und Besatzung 30 → 26, Semidrug Besatzung 25 → 26, Enterkorvette Drehungen 3 → 2.

Messung (`tests/sim_space.gd -- 100 fraktionen`, neu: Siege je Seite) nach der Abstimmung, Sieg leicht/mittel/schwer: Semidrug 79/69/45, Eisenwölfe 88/56/35, Schwarze Flagge 88/65/42, Aasgeier 85/73/40, Neuntes Haus 88/66/50, Kinder der Glut 90/66/40; zum Vergleich die alten Seiten 87–93 / 58–72 / 39–48 (Drohnen 100/97/59). Die Werte schwanken zwischen Läufen um etwa ±7 Punkte (Würfelfolge hängt von der Reihenfolge der Kämpfe ab; Eisenwölfe mittel z. B. 56–67 % bei gleichen Werten). Die neuen Seiten liegen damit in der Streuung der alten.

## 1g. Gegner-Info und Scan (23.10.2026, Wunsch des Nutzers)

Frage des Nutzers: Infos vom Gegnerschiff (Antrieb beschädigt, Waffen beschädigt usw.). Vorher lag alles im Spielzustand, sichtbar über Klick-Log, Hüllenbalken, Schildring und ein allgemeines ⚠. Entscheidungen: Mouseover über dem Schiff; Umfang „eigene Treffer + Scan“; ohne Scan Hülle und Schilde nur grob; Scan gilt einige Runden (Vorschlag 3 bestätigt), Hülle in 3 Stufen; Mockups bestätigt. Regel in `docs/Raumkampf.md` 4d.

Umsetzung: `SpaceShip.known`/`scan_until`/`scan_live`/`scan_seen`, `seen_damage()`, `hull_stage()`; `SpaceCombat.SCAN_ROUNDS`, Computer-Modus `"scan"`; Tooltip `SpaceUI.hover_ship()`/`enemy_info()`, Hover in `SpaceView._input`; Karte in `SpaceShipView` (Balken 3 Stufen, Schildring an/aus). Test `test_space.gd` `_test_scan`, Screenshots `-- --autotest-space` (8_gegner_grob, 9_gegner_scan). Kein Balancing nötig: Gegner-KI und Bord-KI handeln wie vorher (`test_sim -- 10` OK). Auf Touch-Geräten gibt es keinen Mouseover; dort bleibt der Klick (Log).

## 1h. Elite-Gegner, moderate Anpassung, Stationstreffer (24.10.2026, gebaut)

Grundlage: gemeinsame Elite-Regeln in `docs/module/raumkampf.md` (13 % der Kämpfe, Ziel 70–75 % Siege, Stärke aus Ausrüstung, vorher erkennbar). Gemessen mit Prototyp-Skript (nur im Chat), Schwierigkeit wie im Spiel 1:3:1, alle Seiten, 150–200 Kämpfe je Zeile.

- **Crew-Stärke P** = Mittel aus Pilot und den zwei besten Geschützstationen (Turm ausgenommen). Spielstand 24.10.: P 75; derselbe mit KI-Schützen: P 28; Schnellkampf-Testcrew: P 33.
- **Elite:** Waffen eine Stufe besser (Laserbank → Partikelkanone, Massebeschleuniger → Schnellfeuerkanone, Raketenwerfer → Raketenbatterie, Abwehrgeschütz → Abwehrlaser), Schilde +4 je Seite und +1 Aufladung (nicht bei Jägern), Besatzung **E = (P − 52) × 0,45** (gerundet, −15 bis +30).
  - Nur Ausrüstung (E 0): Siege 89 / 60 / 53 % (P 75 / 28 / 33) – für schwache Crews schon zu hart, daher E auch negativ.
  - Mit Formel: **74 / 79 / 70 %** Siege, Runden 5,5 / 9,0 / 10,4, Hüllenverlust Ø 39 / 32 / 46.
- **Normale Kämpfe moderat:** Besatzung + (P − 52) × 0,2 (0 bis +10), keine Ausrüstung: Spielstand 95 → **92 %**, Hüllenverlust Ø 13 → 20; schwache Crews unverändert (72–73 %).
- **Stationstreffer** (Anteil der Systemtreffer, heute 15 %): 25 % → Verletzte etwa +30–80 %, 35 % → etwa doppelt so viele; Siegquoten messbar unverändert (Spielstand Ø 0,06 → 0,08 → 0,10 je Kampf, Testcrew 0,10 → 0,15 → 0,24).
- Schnittstelle: Ergänzung `setup.enemy.elite: bool` (setzt, wer Auftrag/Kontakt erzeugt).
- **Entscheidungen des Nutzers:** Elite so bauen, normale Kämpfe moderat, Stationstreffer 25 %.
- **Beim Bauen nachgestimmt** (mit dem eingebauten Code, 200 Kämpfe je Zeile): mit 52 / 0,45 kam die Testcrew nur auf 63 % Elite-Siege, daher **Basis 56, Faktor 0,5, Untergrenze −20**. Ergebnis Elite: Spielstand **73 %** (Bonus +10), mit KI-Schützen 79 % (−14), Testcrew 67 % (−12); normal: Spielstand 92 % (+4), die anderen unverändert (0). `tests/sim_space.gd -- 100` normal 93/72/45 % wie vorher, `-- 100 elite` 95/70/55 % (gemischt 1:3:1 etwa 72 %), Abbruch nach 40 Runden 1–3 %.
- Kennzeichen: „★ Elite-…“ in Gold am Namen (statt goldenem Ring, der Auswahlring ist schon gold). Selbsttest `-- --autotest-space --elite`.

## 1i. Elite-Beute und Boss-Schiff (Auftrag 24.10.2026, gebaut)

- **Befund vorher** (200 Kämpfe je Zeile): Waffen aus Wracks nur bei 1–2 % der Siege; Entern (in der Simulation nach etwa 55 % der Siege) brachte Ø 2,2 Waffen, fast alle unbeschädigt – bei Elite also die besseren Waffen.
- **Entscheidungen des Nutzers:** Elite/Boss nach dem Sieg 20 % eine Waffe, Entern 30 % eine (je −20/−30); normales Entern auch begrenzen (Zahlen von Claude: 50 % eine Waffe, −10…−30).
- **Boss-Varianten gemessen** (150 Kämpfe, Spielstand / mit KI-Schützen / Testcrew): 5 Elite-Schiffe (Kreuzer, 2 Korvetten, 2 Jäger) selbst mit −20 nur 18 / 30 / 6 %; Fregatte + Korvette + 2 Jäger mit −10: 45 / 69 / 40 %; Fregatte + 2 Jäger mit −10: 80 / 95 / 74 %; **Kreuzer + 2 Jäger mit −10: 76 / 85 / 70 %** (gewählt). Nutzer: Boss dreht nach 40 Runden ab wie sonst.
- **Nachmessung mit dem eingebauten Code** (200 Kämpfe): Boss-Siege 80 / 89 / 66 %, Abbruch nach 40 Runden 0 / 3 / 9 %; Waffen je Elite-/Boss-Sieg 0,15–0,23, je Entern 0,21–0,34 (Elite/Boss) bzw. 0,47–0,57 (normal). Elite-Siegquoten unverändert (73 / 79 / 67 %).

## 2. Vorschläge (noch zu bestätigen)

- **Bord-KI:** fester Gesamtbonus +0 (Entscheidung des Nutzers). **Doppelbesetzung:** beide Würfe −30 (aus dem Regelentwurf).
- **Phasen im Detail:** 0 Initiative (Navigation) → 1 Schilde (Schutzschild) → 2 Bewegen (Pilot; gegnerische Jäger ziehen hier ebenfalls) → 3 Schießen (Geschützstationen, Punktverteidigung) → 4 Technik/Computer (Not-Reparatur, Panzerung, Zielerfassung/Störsender wirken ab der nächsten Runde).
- **Slots des Startschiffs:** 2 Bug, 1 je Seite, 1 Turm (Punktverteidigung). Startbewaffnung: 2× Laserbank (Strahl), 1× Massebeschleuniger (Ballistik), 1× Raketenwerfer, 1× Abwehrgeschütz.
- **Neue Ausbau-Bereiche:** „Schilde“ (Schildpunkte je Seite) und „Schiffspanzerung“ (Abzug je Treffer; bis 18.10.2026 „Panzerung“), je Stufe 0–3 wie die übrigen Bereiche in `ShipUpgrades`.
- **Schiffsmunition:** Arten „Schiffsraketen“ und „Geschosse (Schiff)“; Strahlwaffen ohne Munition (verbrauchen nichts, evtl. später Energie).
- **Systemschäden:** Antrieb, Waffen-Slot, Schilde, Sensoren, Lebenserhaltung, Station. Reparatur im Hub mit Schiffsmaterial und Probe `rsReparatur` (wie Crew-Ausbau) oder in der Werft gegen Credits.
- **Flucht:** Navigation bereitet den Sprung vor (2 Runden, Probe mittel), kostet Treibstoff; bei Erfolg Ende ohne Beute, Auftrag bleibt offen (wie `retreated` am Boden).
- **Kapitulation:** nur bei Gegnern mit Eigenschaft „nimmt Lösegeld“; Kosten in Credits oder Schiffsmunition/Ladung.
- **Fraktionen:** Missionsfraktion-Ressourcen erhalten eine Liste von Schiffsvorlagen; reine Raumgegner als eigene Ressourcen in `data/ships/`.
- **Gegnerverhalten Niederlage:** je Gegner-Vorlage ein Feld `on_win`: `&"entern"` oder `&"abziehen"` (→ Notfall-Regel des Hubs).

## 3. Offene Punkte

- Zahlen: abgestimmt für das Startschiff (1c); Ausbaustufen noch nicht gemessen.

- Energiewerte je Reaktorstufe und Verbrauch je Aktion (nach dem Bau per Simulation).

## 4. Schnittstelle

Fester Stand in `docs/module/raumkampf.md`, Abschnitt „Schnittstellen“ (ersetzt den früheren Vorschlag hier).

## 5. Reihenfolge (Vorschlag)

1. ~~Mockup der Oberfläche~~: vom Nutzer bestätigt (16.10.2026).
2. Regelkern ohne Grafik (`core/space_combat.gd`: Phasen, Stationen, Treffer, Schilde, Systemschäden) mit Test.
3. 3D-Hexkarte und Bedienung, Schnellkampf aus dem Startmenü.
4. Slots, Schiffsmunition, Ausbau-Stufen, Handel und Beute (Absprache mit dem Hub).
5. Anbindung der Auslöser und Entern (nach Entscheidung des Koordinators).
