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

- Konkrete Zahlen: Struktur/Schild/VW der Schiffsklassen, Tabellen Strahl/Ballistik/Rakete mit Spalten Jäger/leicht/mittel/schwer, Systemkritische A–E.
- Wie viele Gegner sind ein typischer Kampf je Schwierigkeit? (nach dem Bau per Simulation)
- Energiewerte je Reaktorstufe und Verbrauch je Aktion (nach dem Bau per Simulation).

## 4. Schnittstelle

Fester Stand in `docs/module/raumkampf.md`, Abschnitt „Schnittstellen“ (ersetzt den früheren Vorschlag hier).

## 5. Reihenfolge (Vorschlag)

1. ~~Mockup der Oberfläche~~: vom Nutzer bestätigt (16.10.2026).
2. Regelkern ohne Grafik (`core/space_combat.gd`: Phasen, Stationen, Treffer, Schilde, Systemschäden) mit Test.
3. 3D-Hexkarte und Bedienung, Schnellkampf aus dem Startmenü.
4. Slots, Schiffsmunition, Ausbau-Stufen, Handel und Beute (Absprache mit dem Hub).
5. Anbindung der Auslöser und Entern (nach Entscheidung des Koordinators).
