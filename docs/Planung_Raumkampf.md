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
| Hub-Anbindung | **Koordinator entscheidet**, wer Auslöser und Sprung zur Szene im Hub baut (siehe 4). |

## 2. Vorschläge (noch zu bestätigen)

- **Bord-KI:** fester Gesamtbonus +20. **Doppelbesetzung:** beide Würfe −30 (aus dem Regelentwurf).
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
- Wie viele Gegner sind ein typischer Kampf je Schwierigkeit?
- Hexkarte: Größe, Hindernisse (Asteroiden, Trümmer, Nebel) – alle in V1 oder nur ein Teil?
- Zuständigkeit für Dateien anderer Module: `ShipUpgrades`, `HubState` (Hub), `Stock`/Raumhafen-Handel (Hub), Lagerhalle als Enter-Karte (Bodenkampf), Posten „Station“ im Hub, Startmenü-Schnellkampf.
- Wer baut die Auslöser im Hub (Koordinator).
- Treibstoff/Energie für Strahlwaffen: ja oder nein.
- Mockup der Oberfläche gezeigt (Artifact „Raumkampf Mockup“); Bestätigung des Gesamtbilds steht aus.

## 4. Schnittstellen-Vorschlag

### Eingang: `SpaceSetup` (Dictionary, vom Hub oder Schnellkampf)

```
{crew: [Character-Kopien an Bord],
 posts: {Station-ID: Figur-ID oder &"ki"},            # Vorbelegung aus dem Hub, im Kampf-Briefing änderbar
 ship: {hull, hull_max, shields_lv, armor_lv,          # aus HubState / ShipUpgrades
        slots: {Slot-ID: Waffen-Key oder ""},
        damage: {System: Stufe}},                       # bleibende Systemschäden
 ship_ammo: {Art: Schuss},                              # eigener Schiffsvorrat
 enemy: {faction, ships: [Vorlagen-ID], fighters: n, on_win, ransom},
 source: &"reise"/&"auftrag"/&"vor_einsatz"/&"schnell", mission: Titel oder ""}
```

### Ausgang: wie `MissionResult` plus Schiffsteil

Gleiche Felder wie `MissionResult.from_combat` (`outcome`, `retreated`, `units` mit EP je Fertigkeit, Zustand, `worst_crit`, …), damit Charakter-Modul und Einsatzbericht nichts Neues lesen müssen. Zusätzlich:

```
{ship: {hull, damage: {System: Stufe}},
 ship_ammo_used: {Art: Schuss},
 fuel_used,                       # Flucht per Sprung
 surrendered, ransom_paid: {credits, …},
 boarding: true/false,            # Niederlage → Bodenkampf (Entern) folgt
 loot: [{key, name, damage} …] für Schiffswaffen, dazu credits, material, ship_ammo}
```

### Eigene Dateien (Vorschlag aus der Moduldatei)

`godot/space.tscn`, `godot/core/space_*.gd`, `godot/view/space_*.gd`, `godot/ui/space_*.gd`, `godot/data/ships/`, Tests `godot/tests/test_space.gd`.

## 5. Reihenfolge (Vorschlag)

1. Mockup der Oberfläche → Bestätigung durch den Nutzer.
2. Regelkern ohne Grafik (`core/space_combat.gd`: Phasen, Stationen, Treffer, Schilde, Systemschäden) mit Test.
3. 3D-Hexkarte und Bedienung, Schnellkampf aus dem Startmenü.
4. Slots, Schiffsmunition, Ausbau-Stufen, Handel und Beute (Absprache mit dem Hub).
5. Anbindung der Auslöser und Entern (nach Entscheidung des Koordinators).
