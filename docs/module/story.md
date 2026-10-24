# Modul Story/Kampagne

- **Branch:** `claude/zen-sagan-9yn0le`
- **Zuständig für (Vorschlag, mit dem Koordinator abstimmen):** eigene Dateien, z. B. `godot/core/story_*.gd`, `godot/ui/story_*.gd`, `godot/data/story/`, Planung `docs/Planung_Story.md`. Keine Dateien anderer Module umbauen; nötige Anbindungen (Hub: Aufträge, Sternenkarte, Berichte; Bodenkampf/Raumkampf: besondere Einsätze) als Schnittstelle vorschlagen und über den Koordinator beauftragen lassen.

## Grundlagen (in `main`)

- Gesamtstand: `CLAUDE.md` „Stand“. Spielwelt bisher: zufälliger Sektor mit Fraktionen (`core/sector.gd`, `data/missions/*.tres`: Vantar-Konzern, Kult des Leeren Lichts, Söldner der Roten Sonne, Kesslers Schmugglerbande), Aufträge mit Auftragsarten (Boden, Blockade, Abfangen, Eskorte; `core/mission.gd`, `core/space_events.gd`), Spieltage, Raumhafen, Crew mit Roster.
- Ideen des Nutzers für später: Fraktionen mit Ober- und Unterarten (`docs/Planung_Kampfkarten.md`), eigene Jäger/Hangar (V2).
- Regeln: `docs/Skillsystem.md`, `docs/Raumkampf.md`. Moduldateien der anderen Module: `docs/module/`.

## Schnittstellen

- Gebauter Stand in `docs/Planung_Story.md`, Abschnitt „Schnittstellen (gebauter Stand)“. Hub: `HubState.story` (Stub: `Story.for_game`), `Story.offers/markers/on_arrive/travel_event/contacts/on_day`, `StoryDialog.show_on`, `StoryLog.show_on`, Sektorumbau; Boden-/Raumkampf: `Story.pending_mission()` / `mission_done()`; Charakter: nichts Neues (Proben über `Voyage.check`); Fraktionen: Oberarten.

## Stand

- Alles in `main` (21.10.2026, Version 0.6), keine offenen Aufträge. Verlauf: `docs/module/archiv/story_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- Bildfelder: jede Szene hat `image` (Name `<Kette oder Vorlage>_<Szene>`), Startszenen `{bild}`. Prompts: `docs/Story_Bilder.md`. Bilder nur als `.png` (`ui/story_dialog.gd`). Fehlt in einer erzeugten Kette aus einem alten Spielstand das Feld, nimmt `Story.view` das Bild der Vorlage; `test_story` prüft, dass jede Szene ein Bildfeld hat (23.10.2026).
- (24.10.2026) Auftrag „Boss am Ende jeder Kette“ gebaut: Finale und Hinterhalt immer Boss, Schritte und Ereignisketten 30 % (Zoll nie), Boden/Raum wie bisher, Namen mit Titel (`StoryGen.BOSSE`, Raum: Schiffsname). Einsatz-Felder `elite: "boss"`, `boss_name`. Details: `docs/Planung_Story.md`, „Boss am Ende einer Kette“. **An den Hub:** `elite`/`boss_name` aus `Story.pending_mission()` an Boden (`Mission.elite`) und Raum (`setup.enemy.boss`/`boss_name`) weitergeben und „Boss“ in der Story-Karte zeigen.

## Gültige Absprachen

- Bilder: Gleiche Szene in mehreren Vorlagen (Abfangen, Befreien, Bergen) bekommt **ein eigenes Bild pro Vorlage** (Nutzer 21.10.2026), kein geteiltes Bild.

## Aufträge vom Koordinator

- Offen beim Nutzer: Bilder malen (`docs/Story_Bilder.md`, Abschnitt „Ergänzt am 21.10.2026“, 41 Motive).

### Auftrag (24.10.2026): Boss am Ende jeder Kette

Gemeinsame Elite-Regeln stehen in `docs/module/bodenkampf.md` und `docs/module/raumkampf.md` (Abschnitt „Elite-Gegner“). Ergänzt vom Nutzer am 24.10.2026:
- **Boss-Kampf:** Boss + 2 Leibwächter + Fußvolk (Form „Anführer“ aus dem Bodenkampf-Vorschlag), Siegquote wie Elite (70–75 %). Kommt vor (a) am Ende jeder Story-Kette (je nach Kette am Boden **oder** im Raum mit Boss-Schiff) und (b) bei Hub-Aufträgen, deren Ziel eine Person ist (z. B. „Beseitigt den Gangsterboss“).
- **Beute bei Elite und Boss:** selten (nicht bei jedem Kampf), dann höchstens 2–3 Stück der besseren Ausrüstung, gern stark beschädigt. Boden: Waffen/Rüstungen. Raum: ab und zu eine beschädigte Schiffswaffe.
- **Elite-Wurf** beim Hub (beim Erstellen von Auftrag/Feindkontakt, ca. 13 %), Anzeige „Elite“ bzw. „Boss“ im Angebot.

1. Jede Kette (Kapitel 1 und Vorlagen) bekommt am Ende einen Boss-Kampf, je Kette am Boden oder im Raum. Vorschlag mit dem Nutzer abstimmen (welche Kette wo, Text, Bild-ID).
2. Raum ist fertig: Ketten, die im Raum enden, setzen `setup.enemy.boss` (und `boss_name`). Bauen erst, wenn Bodenkampf und Raumkampf ihre Schnittstelle (`elite`/`form` bzw. `boss`) festgelegt haben; der Koordinator meldet das.

### Ergänzung (24.10.2026): Schnittstellen stehen

**Schnittstellen bestätigt (Koordinator mit Nutzer, 24.10.2026):**
- Mission-Feld `elite: StringName` = `""` | `&"elite"` | `&"boss"` (Form Trupp/Kern/Boss wählt der Bodenkampf). Raum: `setup.enemy.elite`/`boss`/`boss_name` (schon in `main`).
- Spieleinstellung **„Schwierigkeitsgrad“** leicht ×0,8 / normal ×1,0 / schwer ×1,25, gilt für **Boden und Raum** (Nutzer). Hub speichert sie und gibt sie an `Mission.generate` und an den Raumkampf (`setup.difficulty_factor: float`, fehlend = 1.0) weiter.
- Elite-Beute: `MissionResult.loot`-Einträge mit `elite: true`. Im Handel **verkaufen ja, kaufen nein** (Nutzer).
- Elite-/Boss-Anzahl auf „schwer“ klärt der Nutzer direkt mit dem Bodenkampf.

Boss am Boden: Mission mit `elite = &"boss"` (Bodenkampf: 1 Boss, 2 Hauptleute, Rest normal). Boss im Raum: `setup.enemy.boss` (+ `boss_name`). Vorschlag mit dem Nutzer abstimmen, dann bauen.
