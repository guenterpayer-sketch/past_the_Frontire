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

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/story_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- (21.10.2026) Auftrag „Bild für jede Szene“ erledigt: 41 Szenen mit Bildfeld (`image`, Name `<Kette oder Vorlage>_<Szene>`). Alle 41 Motive fehlen noch, Liste mit Prompts in `docs/Story_Bilder.md` (Abschnitt „Ergänzt am 21.10.2026“). Offen (Nutzer): gleiche Texte in Abfangen/Befreien/Bergen mit einem gemeinsamen Bild oder je eigenem.

## Aufträge vom Koordinator

### Auftrag (21.10.2026): Bild für jede Szene

1. Bilder in `godot/art/story/` sind in `main` (Commit `5cff85f`, 16 PNG). Die Liste mit Prompts steht in `docs/Story_Bilder.md`.
2. Fehler: Nur die Szene „start“ jeder Kette hat ein Bildfeld (`"image": "{bild}"`, z. B. `godot/data/story/vorlagen/abfangen.json`). Die Szene „Entdeckt“ zeigt deshalb „Bild folgt“ (Screenshot des Nutzers 21.10.2026).
3. Entscheidung des Nutzers (21.10.2026): **Jede Szene bekommt ein eigenes Bild.** Dafür pro Szene ein Bildfeld setzen, wo es passt, und eine Liste der Szenen ohne Datei in `docs/Story_Bilder.md` eintragen (ID, Szene, Prompt). Fehlende Dateien: nur als Liste, nicht erfinden.
4. Tests nach CLAUDE.md. Danach Fertigmeldung mit Liste der fehlenden Motive.
