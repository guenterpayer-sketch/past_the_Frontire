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
| Ausbau | **Mischung**: Schiffswaffen in **Slots** (konkrete Waffen), **Schilde und Panzerung als Ausbau-Stufen**. |
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
- **Unverändert:** eigenes Schiff (`SpaceSetup`: Schilde, Panzerung, Reaktor, Startmunition 6/40), Ausbaustufen und ihre Zahl, Bord-KI +0. Eine höhere Startmunition (8/60) wurde gemessen, bringt aber nur wenige Prozent und würde `test_hub` (Hub-Datei) brechen – darum nicht übernommen.
- **Gegnervorlagen** liegen jetzt als Ressourcen in `data/ships/schiffe/*.tres` (`ShipTemplateData`) und `data/ships/seiten/*.tres` (`SpaceFactionData`, Aufstellungen je Zeile „korvette,jaeger“), im Editor bearbeitbar.

**Offen:** Ausbaustufen (halb/voll) sind nicht gemessen (Entscheidung: nur Startschiff); Menschen spielen vermutlich besser als die Crew-KI, die Quoten sind also eher untere Werte (Annahme, nicht gemessen).

## 2. Vorschläge (noch zu bestätigen)

- **Bord-KI:** fester Gesamtbonus +0 (Entscheidung des Nutzers). **Doppelbesetzung:** beide Würfe −30 (aus dem Regelentwurf).
- **Phasen im Detail:** 0 Initiative (Navigation) → 1 Schilde (Schutzschild) → 2 Bewegen (Pilot; gegnerische Jäger ziehen hier ebenfalls) → 3 Schießen (Geschützstationen, Punktverteidigung) → 4 Technik/Computer (Not-Reparatur, Panzerung, Zielerfassung/Störsender wirken ab der nächsten Runde).
- **Slots des Startschiffs:** 2 Bug, 1 je Seite, 1 Turm (Punktverteidigung). Startbewaffnung: 2× Laserbank (Strahl), 1× Massebeschleuniger (Ballistik), 1× Raketenwerfer, 1× Abwehrgeschütz.
- **Neue Ausbau-Bereiche:** „Schilde“ (Schildpunkte je Seite) und „Panzerung“ (Abzug je Treffer), je Stufe 0–3 wie die übrigen Bereiche in `ShipUpgrades`.
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
