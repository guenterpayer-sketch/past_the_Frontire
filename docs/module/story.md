# Modul Story/Kampagne

- **Branch:** `claude/zen-sagan-9yn0le`
- **Zuständig für (Vorschlag, mit dem Koordinator abstimmen):** eigene Dateien, z. B. `godot/core/story_*.gd`, `godot/ui/story_*.gd`, `godot/data/story/`, Planung `docs/Planung_Story.md`. Keine Dateien anderer Module umbauen; nötige Anbindungen (Hub: Aufträge, Sternenkarte, Berichte; Bodenkampf/Raumkampf: besondere Einsätze) als Schnittstelle vorschlagen und über den Koordinator beauftragen lassen.

## Grundlagen (in `main`)

- Gesamtstand: `CLAUDE.md` „Stand“. Spielwelt bisher: zufälliger Sektor mit Fraktionen (`core/sector.gd`, `data/missions/*.tres`: Vantar-Konzern, Kult des Leeren Lichts, Söldner der Roten Sonne, Kesslers Schmugglerbande), Aufträge mit Auftragsarten (Boden, Blockade, Abfangen, Eskorte; `core/mission.gd`, `core/space_events.gd`), Spieltage, Raumhafen, Crew mit Roster.
- Ideen des Nutzers für später: Fraktionen mit Ober- und Unterarten (`docs/Planung_Kampfkarten.md`), eigene Jäger/Hangar (V2).
- Regeln: `docs/Skillsystem.md`, `docs/Raumkampf.md`. Moduldateien der anderen Module: `docs/module/`.

## Schnittstellen

- Vorschlag in `docs/Planung_Story.md`, Abschnitt „Schnittstellen-Vorschlag“ (Hub: `HubState.story`, Story-Aufträge ohne Ablauf, Kartenmarker, Reise-/Ankunfts-/Tages-Haken, Hafenkontakte, Logbuch, Sektorumbau; Bodenkampf/Raumkampf: Story-Einsätze; Charakter: Proben in Szenen; Fraktionen mit Oberarten). Noch nicht abgestimmt.

## Stand

- (19.10.2026) Moduldatei angelegt.
- (19.10.2026) Auftrag 1 erledigt: Entscheidungen des Nutzers und Planung in `docs/Planung_Story.md`, offene Punkte dort. Nichts gebaut.

## Aufträge vom Koordinator

### Auftrag 2 (19.10.2026): offene Punkte klären, dann Story-Engine

- Offene Punkte 1–9 aus `docs/Planung_Story.md` mit dem Nutzer klären (Auswahl-Buttons, am Ende jeder Runde eine Freitext-Frage), dazu ein Mockup für das Szenenfenster und das Logbuch.
- Danach im eigenen Bereich bauen: Story-Engine, Logbuch, `StoryState` mit einer Test-Kette. Keine fremden Dateien umbauen. Wo eine Anbindung fehlt, mit einem Stub im eigenen Code arbeiten.
- Den Schnittstellen-Vorschlag in `docs/Planung_Story.md` auf den gebauten Stand bringen (Funktionsnamen, Daten). Danach fertig melden. Erst dann verteilt der Koordinator die Aufträge an Hub, Bodenkampf und Raumkampf (Entscheidung des Nutzers 19.10.2026).
