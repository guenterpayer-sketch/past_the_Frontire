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
- (19.10.2026) Auftrag 3, Hub-Punkt erledigt: `Story.add_resource` nutzt `HubState.apply_story` (gibt die tatsächliche Änderung zurück), Stub `Story.for_game` entfernt, Tests angepasst.
- (19.10.2026) Auftrag 3, Inhalte: Fraktionen, Kapitel 1 und Ereignisketten mit dem Nutzer geklärt („ganz erzeugt“). Gebaut: Generator `core/story_gen.gd`, Vorlagen `data/story/vorlagen/` (8), `data/story/kapitel1.json` (Rahmen, Rate, 4 Rückschläge, Finale), Engine-Erweiterungen (Raten, Rückschläge, Lager, Story-Schlüssel, erzeugte Ketten im Spielstand), Logbuch zeigt Wartepunkt und fehlende Bedingung, Bildliste `docs/Story_Bilder.md`. **Fremde Dateien:** `tests/test_hub.gd` (eine Zeile: Kapitel 1 im Story-Test ausgeschlossen, weil es ab Tag 3 von selbst startet), `tests/autotest_hub.gd` (eine Zeile: `Story.auto_start = false`, sonst hält das Szenenfenster von Kapitel 1 den Selbsttest an).
- (19.10.2026) Auftrag 4: Fraktions-IDs auf die des Bodenkampfs umgestellt (`abteilung_9`, `wacht_klingen`, `wacht_hirten`), Test `_test_faction_ids`, Hirten als seltene Gegner (Flag `hirten_feind`, Entscheidung des Nutzers). Hub-Punkte in `docs/Planung_Story.md` gesammelt.

## Hinweise und Bitte an den Koordinator

- **Layout (Nutzer, 19.10.2026):** Neue Fenster müssen zum restlichen Spiel passen und dürfen nicht wie ein Fremdkörper wirken. Lehre aus Auftrag 2: Vor dem Bauen einer Oberfläche Screenshots der vorhandenen Fenster ansehen (`-- --autotest-hub`) und daneben vergleichen, nicht nur Farben aus `UiTheme` übernehmen.
- **Bitte des Nutzers (erledigt 19.10.2026, `docs/Layout.md`):** feste Layoutregeln für alle Module. Muster, die der Story-Chat in den vorhandenen Fenstern gefunden hat: große feste Fenstergröße (`Modal.max_size`), goldener Titel mit grauer Erklärzeile darunter, Abschnittsüberschriften klein, grau, in Großbuchstaben, Auswahl als Karte (`PANEL2`, Rahmen `LINE`, Radius 8) mit Titel, grauer Beschreibung und Knopf mit goldener Schrift (Feindkontakt), Crew mit farbigem Buchstabenkästchen (`UiTheme.badge`), Seitenleiste mit gerahmten Reitern und Anzahl in Klammern (Enzyklopädie), Fußleiste rechts mit goldener Aktion und „Schließen“, keine gerahmten Etiketten, lange Texte mit Scrollbalken.

## Aufträge vom Koordinator

### Auftrag 4 (19.10.2026): Fraktions-IDs angleichen, Hub-Punkte sammeln

- **IDs passen nicht:** `core/story_gen.gd` (`GEGNER`) und `data/story/kapitel1.json` nutzen `abteilung9` und `seraph`. Der Bodenkampf hat `abteilung_9`, `wacht_klingen` und `wacht_hirten` angelegt (außerdem `stille_hand`, `aasgeier`, `semidrug`; Vantar heißt `konzern`). Dadurch nimmt die Story für Abteilung 9 und die Klingen stillschweigend die Ersatzfraktion. Bitte auf die echten IDs umstellen und einen Test ergänzen, der jede genannte Fraktion als Datei findet. Ob die Hirten als Gegner vorkommen, mit dem Nutzer klären.
- Die offenen Hub-Punkte aus `docs/Planung_Story.md` (Kartenart aus der Vorlage, gefangene Crew sperren, Story-Schlüssel `sectors`, Story-Orte mit Sektor) gehen über den Koordinator an den Hub, sobald dessen Sektorumbau in `main` liegt. Den Stand dort aktuell halten.
