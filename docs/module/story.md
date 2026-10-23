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

## Gültige Absprachen

- Bilder: Gleiche Szene in mehreren Vorlagen (Abfangen, Befreien, Bergen) bekommt **ein eigenes Bild pro Vorlage** (Nutzer 21.10.2026), kein geteiltes Bild.

## Aufträge vom Koordinator

- Keine offenen Aufträge. Offen beim Nutzer: Bilder malen (`docs/Story_Bilder.md`, Abschnitt „Ergänzt am 21.10.2026“, 41 Motive).
