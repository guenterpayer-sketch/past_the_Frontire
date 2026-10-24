# Modul Raumkampf

- **Branch:** `claude/raumkampf-modul`
- **Zuständig für (Vorschlag, mit dem Koordinator abstimmen):** eigene Szene und eigene Dateien, z. B. `godot/space.tscn`, `godot/core/space_*.gd`, `godot/view/space_*.gd`, `godot/ui/space_*.gd`, `godot/data/ships/`. Keine Dateien anderer Module umbauen; nötige Änderungen an Schnittstellen in „Stand“ vermerken.

> Planung, Aufträge 1–2 und alter Stand: `docs/module/archiv/raumkampf_bis_2026-10-16.md` (nur bei Bedarf lesen).

## Grundlagen (in `main`)

- Regel-Entwurf: `docs/Raumkampf.md` (Hexkarte ohne Höhe, Ausrichtung/Trägheit, Mutterschiff mit Stationen, 2–3 Jäger, Schild je Seite, Struktur, Systemschaden). Nur Entwurf, nicht vom Nutzer bestätigt.
- Fertigkeiten (`core/rules.gd`, Gruppe Raumschiff-Kampf, bisher ohne Wirkung): `strahlGeschuetze`, `ballistikGeschuetze`, `raketen` (angezeigt „Raketen-Geschütze“), `schutzschild`, `panzerung`, `notReparatur`; dazu Raumschiff-Technik `pilot`, `navigation`, `computer`, `rsReparatur` (werden schon bei Reiseproben benutzt).
- Würfel, Proben, Schwierigkeiten: `core/dice.gd`, `core/rules.gd` (W100 offen, `DIFFICULTY`). Angriffstabellen-Muster: `core/tables.gd`, `data/tables/` (Bodenkampf).
- Vorbild für Ablauf und Datenaustausch: Bodenkampf (`core/combat.gd` meldet alles über Signale, `MissionResult` als Ergebnis).

## Schnittstellen (fester Stand 16.10.2026, Auftrag 2)

Verbindlich für Hub und Raumkampf. Änderungen nur nach Absprache über den Koordinator. Alle Schlüssel in Dictionaries sind **Strings** (speicherbar als JSON); Zahlenwerte hinter den Stufen (Schildpunkte, Energie usw.) gehören dem Raumkampf und sind bis zur Simulation Platzhalter.

### Einstieg und Rückweg

- `SpaceBattle.start(tree: SceneTree, setup: Dictionary)` (`core/space_battle.gd`): merkt sich `setup`, macht Kopien der `Character` und wechselt zu `res://space.tscn`. Der Hub ruft nur diese Funktion auf.
- `SpaceSetup.quick() -> Dictionary` (`core/space_setup.gd`): Schnellkampf mit festen Testwerten, ohne `HubState`. Crew: `Campaign.quick_squad`, falls gesetzt, sonst Testfiguren aus dem Roster. `return_scene` = Startmenü. Nichts wird verbucht.
- Am Ende: Raumkampf ruft (außer im Schnellkampf) `Campaign.finish_mission(result)` auf (EP, freie EP, Verwundung wie am Boden), legt das Ergebnis in `SpaceBattle.last_result` und wechselt zu `setup.return_scene`.
- Der Hub holt das Ergebnis mit `SpaceBattle.take_result() -> Dictionary` (gibt es einmal zurück und leert es) und wertet es aus. Bei `boarding: true` startet der Hub den Bodenkampf (Lagerhalle).

### Eingang `setup`

```
{"crew": [Character, …],                 # alle an Bord, nicht gesperrt (Verwundete ohne Einsatzfreigabe weglassen)
 "posts": {Station-ID: Figur-ID oder "ki"},   # feste Posten aus dem Hub; im Kampf-Briefing änderbar.
                                         # Dieselbe Figur auf zwei Stationen = Doppelbesetzung (−30), höchstens zwei.
 "ship": {"hull": int, "hull_max": int,
          "levels": {"shields": 0–3, "armor": 0–3, "reactor": 0–3, "slots": 0–5},   # Stufen aus ShipUpgrades
          "slots": {Slot-ID: {"key": Waffen-Key oder "", "damage": 0/−10/−20/−30}},
          "damage": {System-ID: "A"–"E"}},        # bleibende Systemschäden (fehlend = heil)
 "ship_ammo": {"schiffsraketen": int, "geschosse": int},
 "fuel": int,                            # für die Flucht per Sprung
 "credits": int,                         # Lösegeld wird nur angeboten, wenn bezahlbar
 "enemy": {"faction": Fraktions-ID oder Raumgegner-ID, "difficulty": "leicht"/"mittel"/"schwer",
           "elite": bool,                  # neu 24.10.2026, fehlend = false (docs/Raumkampf.md 4e)
           "boss": bool, "boss_name": String},   # neu 24.10.2026, optional; Boss-Kampf (feste Gruppe, gilt auch als Elite)
 "difficulty_factor": float,             # neu 24.10.2026, Spieleinstellung 0.8 / 1.0 / 1.25, fehlend = 1.0
 "source": "reise"/"auftrag"/"vor_einsatz"/"schnell",
 "mission": Titel oder "",
 "return_scene": Szenenpfad}
```

Gegnerschiffe, Jäger, Verhalten bei Niederlage (`entern`/`abziehen`) und ob Lösegeld genommen wird, wählt der Raumkampf aus `faction` + `difficulty` (Vorlagen in `data/ships/`).

### IDs

- **Slots:** `bug`, `backbord`, `steuerbord`, `turm` (Start). Ausbau `slots` mit **5 Stufen** (geändert 16.10.2026): Stufe 1 + `heck`, 2 + `backbord2`, 3 + `steuerbord2`, 4 + `bug2`, 5 + `turm2` (`SpaceSetup.SLOTS_BY_LEVEL`, `SpaceSetup.slots_for(lv)`). Turm-Slots nehmen nur Abwehrwaffen, alle anderen Slots jede andere Waffe.
- **Stationen:** `steuer`, `navigation`, `schilde` (verteilt auch die Energie), `technik`, `computer`, je bestücktem Slot eine Geschützstation `geschuetz_<Slot-ID>` (Turm-Slots = Punktverteidigung) und die weiteren Techniker `technik_2`, `technik_3` (neu 16.10.2026; nur mit Crew besetzbar, `"ki"` = frei).
- **Systeme:** `antrieb`, `sensoren`, `lebenserhaltung`, `schilde`, `reaktor`, `slot_<Slot-ID>`, `station_<Station-ID>`. Schaden in Stufen `A`–`E` (E = ausgefallen).
- **Neue Ausbau-Bereiche (Hub, `ShipUpgrades`):** `shields`, `armor`, `reactor` je Stufe 0–3, `slots` Stufe 0–5. Preise/Material wie die übrigen Bereiche (Sache des Hubs).
- **Schiffsmunition:** `schiffsraketen`, `geschosse`. Strahlwaffen brauchen keine Munition, sondern Energie im Kampf (bleibt nicht über den Kampf hinaus).

### Waffen-Katalog `ShipWeapons` (`core/space_weapons.gd`, gehört dem Raumkampf)

Der Hub liest daraus für Handel, Lager und Anzeige: `ShipWeapons.keys() -> Array[String]`, `name(key)`, `price(key)` (Credits, Platzhalter), `ammo(key)` (`""`/`schiffsraketen`/`geschosse`), `fits(key, slot_id) -> bool`, `describe(key) -> String`.

| Key | Name | Art | Slot | Munition |
|---|---|---|---|---|
| `laserbank` | Laserbank | Strahl | normal | Energie |
| `partikelkanone` | Partikelkanone | Strahl | normal | Energie |
| `massebeschleuniger` | Massebeschleuniger | Ballistik | normal | geschosse |
| `schnellfeuerkanone` | Schnellfeuerkanone | Ballistik | normal | geschosse |
| `raketenwerfer` | Raketenwerfer | Rakete | normal | schiffsraketen |
| `raketenbatterie` | Raketenbatterie | Rakete | normal | schiffsraketen |
| `abwehrgeschuetz` | Abwehrgeschütz | Abwehr | Turm | geschosse |
| `abwehrlaser` | Abwehrlaser | Abwehr | Turm | Energie |

**Startschiff** (für einen neuen Spielstand, `SpaceSetup.START_SLOTS`): `bug` laserbank, `backbord` massebeschleuniger, `steuerbord` raketenwerfer, `turm` abwehrgeschuetz. Startvorrat `SpaceSetup.START_AMMO`: schiffsraketen 6, geschosse 40.

### Ausgang (Ergebnis)

Alle Felder von `MissionResult` (`outcome`, `retreated`, `mission`, `rounds`, `reward_xp`, `units` mit EP je Fertigkeit, `free_xp`, `status`, `worst_crit`, `dying`, `stabilized`, `died`; `ammo_used` und `loot` der Crew bleiben leer). Verletzungen entstehen über Stationstreffer. Zusätzlich:

```
{"space": true,
 "retreated": true bei Flucht per Sprung (outcome "niederlage", keine Beute, Auftrag bleibt offen),
 "surrendered": bool, "ransom": {"credits": int, "ship_ammo": {Art: int}},   # bezahlt bei Kapitulation
 "boarding": bool, "boarding_faction": Fraktions-ID,     # Gegner entern (ab eigener Hülle < 25 % oder bei 0) → Hub startet Bodenkampf
                                                         # (neu 18.10.2026: dann auch board_ship = Enterschiff und board_loot = dessen Beute,
                                                         #  vom Hub zu buchen, wenn die Crew das Entern abwehrt)
 "emergency": bool,                                      # Niederlage gegen abziehende Gegner → Notfall-Regel des Hubs
 "ship": {"hull": int,                                   # neuer Stand (0 bei Niederlage möglich)
          "damage": {System-ID: "A"–"E"},                # neuer Gesamtstand der Systemschäden
          "slots": {Slot-ID: {"key", "damage"}}},        # neuer Stand der Slots (beschädigte Waffen)
 "ship_ammo_used": {Art: int}, "fuel_used": int,
 "ship_loot": {"credits": int, "material": int, "ship_ammo": {Art: int},
               "weapons": [{"key": Waffen-Key, "name": String, "damage": 0/−10/−20/−30}]},   # nur bei Sieg
 # neu 16.10.2026 – selbst entern (outcome "sieg"; der Hub startet den Bodenkampf gegen die Besatzung):
 "board_enemy": bool, "board_faction": Fraktions-ID, "board_ship": Name,
 "board_loot": {"credits", "material", "ship_ammo", "weapons"}}   # erst verbuchen, wenn die Crew den Bodenkampf gewinnt
```

Der Hub bucht: Hülle, Systemschäden, Slots, Schiffsmunition, Treibstoff, Lösegeld, Beute (Waffen ins Lager), Einsatzbericht, Entern bzw. Notfall. Bei `board_enemy` startet er den Bodenkampf (vorerst Lagerhalle) und bucht `board_loot` nur bei Sieg.

## Stand

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/raumkampf_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- (23.10.2026) Wunsch des Nutzers direkt im Raumkampf-Chat: Gegner-Info und Scan (`docs/Raumkampf.md` 4d, `docs/Planung_Raumkampf.md` 1g). Ohne Scan nur grobe Hülle, Schilde an/aus und Schäden aus eigenen Treffern; Computer-Wahl „Scannen“ zeigt 3 Runden alles; Tooltip mit der Maus über dem Gegner. Schnittstelle unverändert.

- (24.10.2026) Auftrag „Balancing – Ursache finden“ (Analyse, nichts gebaut). Simulation mit dem Spielstand `spielstaende/24-10-2026/slot_1.json` (60 Kämpfe je Stufe, alle Seiten; Skript nur im Chat, nicht im Repo): Siege leicht/mittel/schwer **98/96/90 %** in 4–5 Runden, Hüllenverlust Ø 4/13/23 (Schnellkampf-Testcrew 93/68/51 %, 7–11 Runden, 17/55/68). Schiff kaum ausgebaut (Schilde/Panzerung/Reaktor 0, 5. Slot Heck-Laserbank) – **Ursache ist die Crew**: Schützen +75/+65 statt KI +0/+25 (Treffer 56 statt 37 %, davon kritisch 51 statt 22 %), Pilot +86 (Gegner treffen 38 statt 85 % ohne Pilot). Probe: nur Schützen auf KI → 88/70/53 %, nur Steuer auf KI → 81/60/41 %, beide → 63/18/6 %; Navigation, Computer, Heck-Slot je nur wenige Punkte. Ränge seit Roster-Start: Pilot 8→13, Navigation 5→11, Computer 0→7, Strahl-Geschütze 1→6, Ballistik 5→8; die Eigenschaftsboni (KOO 99–100, INT 91) geben schon bei Rang 1 etwa +45. Gegner wachsen nicht mit (Besatzung 20–30, Aufstellungen fest, Schwierigkeit zufällig 1:3:1). Verletzungen im Raum: Ø 0,02 je Kampf (auch Testcrew nur 0,03–0,08) – Stationstreffer sind selten (15 % der Systemtreffer). Wege (Entscheidung offen): Gegner skalieren, Steigerung dämpfen, stärkere Gegner über Sektoren/Stufen.
  - **Entscheidungen des Nutzers (24.10.2026):** Gegner nur **moderat** anpassen (das Besserwerden der Crew soll sich richtig anfühlen); dazu ab und zu **Elite-Gegner**, die sich an die Crew anpassen – **mit dem Bodenkampf abstimmen** (über den Koordinator). Stationstreffer im Raum **etwas häufiger**, damit Verletzte möglich werden. Noch nichts gebaut; Vorschlag mit Zahlen folgt nach der Abstimmung.
- (24.10.2026) **Elite-Gegner, moderate Anpassung, Stationstreffer 25 % gebaut** (`docs/Raumkampf.md` 4e, Messung `docs/Planung_Raumkampf.md` 1h): Elite-Siege 67–79 % je nach Crew (Spielstand 73 %), normale Kämpfe nur für starke Crews etwas härter. **Schnittstelle ergänzt:** `setup.enemy.elite: bool` (fehlend = false). **Für den Hub:** bei Aufträgen und Feindkontakt etwa 13 % Elite würfeln (gleiche Regel wie Boden), im Angebot/Kontakt „Elite“ zeigen (ausweichen möglich) und `elite` in `enemy` mitgeben.
- (24.10.2026) **Auftrag Elite-Beute und Boss-Schiff gebaut** (`docs/Raumkampf.md` 4e, Messung `docs/Planung_Raumkampf.md` 1i): Elite/Boss-Beute selten (20 % nach Sieg, 30 % beim Entern, je eine Waffe −20/−30), normales Entern höchstens eine Waffe (50 %, −10…−30). Boss: Kreuzer (Elite, Hülle ×1,3, Name) + 2 Jäger, Siege 66–89 % je nach Crew. **Schnittstelle ergänzt:** `setup.enemy.boss: bool`, `setup.enemy.boss_name: String` (beide optional; Boss gilt auch als Elite). **Für Story/Hub:** Story-Ketten, die im Raum enden, und Aufträge gegen eine Person setzen `boss` (und den Namen); Anzeige „Boss“ im Angebot. **Für den Hub:** `board_loot` hat jetzt höchstens eine Waffe.
- (24.10.2026) **Auftrag Schwierigkeitsgrad gebaut:** `setup.difficulty_factor` (0,8 / 1,0 / 1,25, fehlend = 1,0) wirkt auf Gegner-Hülle (halb) und Besatzung (+(f − 1) × 25), auch bei Elite und Boss (Entscheidungen des Nutzers; `docs/Raumkampf.md` 4e, Messung `docs/Planung_Raumkampf.md` 1j). Siege Spielstand normal 97 / 94 / 76–90 %, Testcrew 80 / 66 / 56 %. Schnittstelle wie vom Koordinator bestätigt, keine weitere Änderung.

## Aufträge vom Koordinator

- Schnittstellen nur ergänzen und dem Hub über den Nutzer melden.
- Story-Fraktionen im Raum erst, wenn Kapitel 1 sie braucht.

### Auftrag (24.10.2026): Balancing – Ursache finden

Analyse, **nichts bauen**. Anlass (Nutzer 24.10.2026): Die Crew ist inzwischen so stark, dass Kämpfe keine Herausforderung mehr sind. Betrifft Boden- **und** Raumkampf. Anzeichen laut Nutzer: Gegner fallen zu schnell, keine Verletzungen oder Verluste, zu wenige Gegner. Entscheidung des Nutzers: erst die Ursache finden, dann Wege vorschlagen.

1. Spielstand des Nutzers lesen: `spielstaende/24-10-2026/` (`slot_1.json`, `auto.json`, `crew.json`, `roster.json`; Tag 60, 6 Einsätze, 10 Figuren). Eigene Ausrüstung: `spielstaende/24-10-2026/gear/` (7 Waffen, 2 Rüstungen).
2. Raumkampf prüfen: Gegnerschiffe, Anzahl und Stärke gegen das Schiff und die Crew des Nutzers (Stationen, Fertigkeiten, Schiffswaffen, Ausbauten im Spielstand). Woran liegt es, dass Gegner schnell fallen und es kaum Schaden gibt?
3. Ergebnis als Bericht an den Nutzer: Ursachen mit Zahlen (was ist Wissen, was Annahme), dazu 2–3 Wege zum Ausgleich mit Vor- und Nachteilen. Bericht kurz in die Moduldatei unter „Stand“ eintragen. Kein Code ändern, bis der Nutzer entschieden hat.

### Elite-Gegner – gemeinsame Regeln Boden und Raum (Nutzer 24.10.2026)

- **Häufigkeit:** etwa jeder 7.–8. Kampf (Zufall, ca. 13 %), gleich für Boden und Raum.
- **Stärke:** nach **Ziel-Siegquote**: per Simulation mit der Crew so einstellen, dass der Nutzer etwa 70–75 % der Elite-Kämpfe gewinnt. Nicht an den Durchschnitt der Crew angleichen (Sorge des Nutzers: zu schwer).
- **Woher die Stärke kommt:** bessere Ausrüstung mit höheren Boni (Boden: Waffen/Rüstung; Raum: stärkere Schiffswaffen/Schilde), dazu Werte nach Bedarf.
- **Erkennbar:** schon vorher im Auftrag/Feindkontakt („Elite“, ausweichen möglich) und im Kampf markiert (Zeichen/Farbe am Gegner bzw. Schiff).
- Keine Extra-Belohnung festgelegt (Nutzer hat sie nicht gewählt).
- **Elite-Wurf (Nutzer 24.10.2026):** Der Hub entscheidet schon beim Erstellen des Auftrags bzw. Feindkontakts (ca. 13 %), zeigt „Elite“ im Angebot und gibt nur „Elite ja/nein“ an den Kampf weiter. Boden wählt die Form selbst. Story kann Elite für eigene Missionen fest setzen.
- **Ablauf:** Bodenkampf und Raumkampf legen dieselbe Auswahl (Häufigkeit, Kennzeichen „Elite“ im Angebot/Kontakt) fest; Wer das Angebot erzeugt (Hub), bekommt die Kennzeichnung über den Koordinator. Erst Vorschlag mit Simulation an den Nutzer, dann bauen.
