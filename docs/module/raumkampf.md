# Modul Raumkampf

- **Branch:** `claude/raumkampf-modul`
- **Zuständig für (Vorschlag, mit dem Koordinator abstimmen):** eigene Szene und eigene Dateien, z. B. `godot/space.tscn`, `godot/core/space_*.gd`, `godot/view/space_*.gd`, `godot/ui/space_*.gd`, `godot/data/ships/`. Keine Dateien anderer Module umbauen; nötige Änderungen an Schnittstellen in „Stand“ vermerken.

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
          "levels": {"shields": 0–3, "armor": 0–3, "reactor": 0–3, "slots": 0–3},   # Stufen aus ShipUpgrades
          "slots": {Slot-ID: {"key": Waffen-Key oder "", "damage": 0/−10/−20/−30}},
          "damage": {System-ID: "A"–"E"}},        # bleibende Systemschäden (fehlend = heil)
 "ship_ammo": {"schiffsraketen": int, "geschosse": int},
 "fuel": int,                            # für die Flucht per Sprung
 "credits": int,                         # Lösegeld wird nur angeboten, wenn bezahlbar
 "enemy": {"faction": Fraktions-ID oder Raumgegner-ID, "difficulty": "leicht"/"mittel"/"schwer"},
 "source": "reise"/"auftrag"/"vor_einsatz"/"schnell",
 "mission": Titel oder "",
 "return_scene": Szenenpfad}
```

Gegnerschiffe, Jäger, Verhalten bei Niederlage (`entern`/`abziehen`) und ob Lösegeld genommen wird, wählt der Raumkampf aus `faction` + `difficulty` (Vorlagen in `data/ships/`).

### IDs

- **Slots:** `bug`, `backbord`, `steuerbord`, `turm` (Start). Ausbau `slots`: Stufe 1 + `heck`, Stufe 2 + `bug2`, Stufe 3 + `turm2`. Turm-Slots nehmen nur Abwehrwaffen, alle anderen Slots jede andere Waffe.
- **Stationen:** `steuer`, `navigation`, `schilde` (verteilt auch die Energie), `technik`, `computer` und je bestücktem Slot eine Geschützstation `geschuetz_<Slot-ID>` (Turm-Slots = Punktverteidigung).
- **Systeme:** `antrieb`, `sensoren`, `lebenserhaltung`, `schilde`, `reaktor`, `slot_<Slot-ID>`, `station_<Station-ID>`. Schaden in Stufen `A`–`E` (E = ausgefallen).
- **Neue Ausbau-Bereiche (Hub, `ShipUpgrades`):** `shields`, `armor`, `reactor`, `slots`, je Stufe 0–3. Preise/Material wie die übrigen Bereiche (Sache des Hubs).
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
 "boarding": bool, "boarding_faction": Fraktions-ID,     # Niederlage gegen enternde Gegner → Hub startet Bodenkampf
 "emergency": bool,                                      # Niederlage gegen abziehende Gegner → Notfall-Regel des Hubs
 "ship": {"hull": int,                                   # neuer Stand (0 bei Niederlage möglich)
          "damage": {System-ID: "A"–"E"},                # neuer Gesamtstand der Systemschäden
          "slots": {Slot-ID: {"key", "damage"}}},        # neuer Stand der Slots (beschädigte Waffen)
 "ship_ammo_used": {Art: int}, "fuel_used": int,
 "ship_loot": {"credits": int, "material": int, "ship_ammo": {Art: int},
               "weapons": [{"key": Waffen-Key, "name": String, "damage": 0/−10/−20/−30}]}}   # nur bei Sieg
```

Der Hub bucht: Hülle, Systemschäden, Slots, Schiffsmunition, Treibstoff, Lösegeld, Beute (Waffen ins Lager), Einsatzbericht, Entern bzw. Notfall.

## Aufträge vom Koordinator

### Auftrag 1 (16.10.2026): Planung, noch nicht bauen

1. `CLAUDE.md`, `docs/module/README.md`, diese Datei und `docs/Raumkampf.md` in `main` lesen.
2. **Mit dem Nutzer klären (Auswahl-Buttons)**, was der Raumkampf sein soll, u. a.: Umfang der ersten Version (nur Mutterschiff oder gleich mit Jägern), Darstellung (2D/3D, Hexkarte), Stationen und wer sie besetzt, Schiffswerte und Gegner, Auslöser und Folgen im Hub (Hülle, Beute, Flucht), Verbindung zu Schiffsausbau und Munition.
3. Ergebnis als Planung `docs/Planung_Raumkampf.md` festhalten (Entscheidungen des Nutzers, offene Punkte, Schnittstellen-Vorschlag) und `docs/Raumkampf.md` angleichen.
4. Mockup der Oberfläche zeigen, erst nach Bestätigung bauen.
5. Branchnamen und Planung als Fertigmeldung an den Koordinator (über den Nutzer).

## Stand

- (16.10.2026) Moduldatei angelegt.
- (16.10.2026) Auftrag 1: Klärung mit dem Nutzer abgeschlossen, Planung in `docs/Planung_Raumkampf.md` (Entscheidungen, Vorschläge, offene Punkte, Schnittstellen-Vorschlag), `docs/Raumkampf.md` angeglichen. Mockup (Artifact „Raumkampf Mockup“) vom Nutzer bestätigt. Noch kein Code.
- (16.10.2026) Auftrag 2: offene Punkte mit dem Nutzer geklärt (`docs/Planung_Raumkampf.md` 1a), Schnittstelle als fester Stand oben unter „Schnittstellen“. Noch kein Code.

### Auftrag 2 (16.10.2026): Regelkern, Szene, Schnittstelle

Planung V1 (`8bd0e3a`) ist in `main`. **Zuständigkeit (Entscheidung Koordinator, im Auftrag des Nutzers):**
- **Raumkampf baut** nur eigene Dateien (`space.tscn`, `core/space_*.gd`, `view/space_*.gd`, `ui/space_*.gd`, `data/ships/`, `tests/test_space.gd`): Regelkern, Szene, Kampf-Briefing (Stationen ändern), Gegnervorlagen, Ergebnis. Dazu einen Einstieg, den der Hub nur aufruft, z. B. `SpaceBattle.start(setup)` / Szene mit `SpaceSetup`, und eine Funktion `SpaceSetup` für den Schnellkampf (feste Testwerte, ohne `HubState`). Ergebnis wie in `docs/Planung_Raumkampf.md` 4 (Format `MissionResult` + Schiffsteil).
- **Hub baut** alles in Hub-Dateien: alle vier Auslöser (Reiseereignis, Auftragsart, vor einem Bodeneinsatz, Schnellkampf-Knopf im Startmenü), `SpaceSetup` aus `HubState` zusammenstellen, Ergebnis auswerten (Hülle, Systemschäden, Schiffsmunition, Lösegeld, Beute, Einsatzbericht, Entern → Bodenkampf mit Lagerhalle, Notfall), `HubState`-Felder (Waffenslots, Schiffsmunition, Systemschäden, Posten „Station“), `ShipUpgrades` „Schilde“/„Panzerung“, Handel mit Schiffswaffen im Hafen, Reparatur der Systemschäden.
- **Bodenkampf:** in V1 nichts (Entern startet die normale Lagerhalle über den Hub). Karte „Schiffsinneres“ später.
- **Charakter:** nichts, solange das Ergebnis das `MissionResult`-Format hält.
- **Reihenfolge:** Raumkampf zuerst Schnittstelle (`SpaceSetup`-Felder, Ergebnis-Felder, Einstiegsfunktion, Daten der Waffen-Keys für Slots) als festen Stand in diese Datei unter „Schnittstellen“ schreiben und pushen (vorab meldbar wie beim Hub +5). Erst dann beginnt der Hub. Offene Zahlen und Punkte (Planung 3, u. a. Energie für Strahlwaffen) vorher mit dem Nutzer klären.
