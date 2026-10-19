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

### Auftrag 2 (19.10.2026): offene Punkte klären, dann Story-Engine

- Offene Punkte 1–9 aus `docs/Planung_Story.md` mit dem Nutzer klären (Auswahl-Buttons, am Ende jeder Runde eine Freitext-Frage), dazu ein Mockup für das Szenenfenster und das Logbuch.
- Danach im eigenen Bereich bauen: Story-Engine, Logbuch, `StoryState` mit einer Test-Kette. Keine fremden Dateien umbauen. Wo eine Anbindung fehlt, mit einem Stub im eigenen Code arbeiten.
- Den Schnittstellen-Vorschlag in `docs/Planung_Story.md` auf den gebauten Stand bringen (Funktionsnamen, Daten). Danach fertig melden. Erst dann verteilt der Koordinator die Aufträge an Hub, Bodenkampf und Raumkampf (Entscheidung des Nutzers 19.10.2026).
