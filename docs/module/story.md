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

- (19.10.2026) Moduldatei angelegt.
- (19.10.2026) Auftrag 1 erledigt: Entscheidungen des Nutzers und Planung in `docs/Planung_Story.md`, offene Punkte dort. Nichts gebaut.
- (19.10.2026) Auftrag 2 erledigt: offene Punkte geklärt, Mockup abgenommen, gebaut: `core/story.gd`, `core/story_state.gd`, `core/story_data.gd`, `ui/story_dialog.gd`, `ui/story_log.gd`, `data/story/` (Bausteine, Test-Ketten), `tests/test_story.gd`, Demo `tests/story_demo.tscn`. Fremde Datei geändert: nur `godot/README.md` (Einträge Aufbau und Tests). Noch nicht im Hub angebunden.

## Hinweise und Bitte an den Koordinator

- **Layout (Nutzer, 19.10.2026):** Neue Fenster müssen zum restlichen Spiel passen und dürfen nicht wie ein Fremdkörper wirken. Lehre aus Auftrag 2: Vor dem Bauen einer Oberfläche Screenshots der vorhandenen Fenster ansehen (`-- --autotest-hub`) und daneben vergleichen, nicht nur Farben aus `UiTheme` übernehmen.
- **Bitte des Nutzers:** feste Layoutregeln für alle Module erstellen (z. B. `docs/Layout.md`). Muster, die der Story-Chat in den vorhandenen Fenstern gefunden hat: große feste Fenstergröße (`Modal.max_size`), goldener Titel mit grauer Erklärzeile darunter, Abschnittsüberschriften klein, grau, in Großbuchstaben, Auswahl als Karte (`PANEL2`, Rahmen `LINE`, Radius 8) mit Titel, grauer Beschreibung und Knopf mit goldener Schrift (Feindkontakt), Crew mit farbigem Buchstabenkästchen (`UiTheme.badge`), Seitenleiste mit gerahmten Reitern und Anzahl in Klammern (Enzyklopädie), Fußleiste rechts mit goldener Aktion und „Schließen“, keine gerahmten Etiketten, lange Texte mit Scrollbalken.

## Aufträge vom Koordinator

### Auftrag 3 (19.10.2026): Inhalte klären und schreiben

- Zuerst die drei Story-Fraktionen mit dem Nutzer ausarbeiten (Namen, Oberart, Ziele, wie sie zueinander stehen) und in `docs/Planung_Story.md` eintragen. Der Bodenkampf legt sie dann als Fraktionsdaten an, Auftrag über den Koordinator.
- Danach Kapitel 1 und die drei Ereignisketten: erst Ablauf und Eckpunkte klären, dann die Szenen als JSON in `data/story/` schreiben. Dazu die Bildliste mit Prompts. Die offenen Punkte 3–5 aus `docs/Planung_Story.md` mitklären.
- Parallel bindet der Hub die Story an (Hub Auftrag 1) und baut danach die Sektorkarte um (Hub Auftrag 2). Rückfragen dazu über den Nutzer an den Hub-Chat oder den Koordinator.
