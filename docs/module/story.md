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
- (19.10.2026) Auftrag 5: Story-Orte als `{sector, system, place}`, Entscheidungen des Nutzers (bekannte Sektoren, selten fremd; Kette startet erst beim Anfliegen des Orts; Ortsart passend zur Vorlage), `on_arrive(sector, system)`, neu `on_visit`, `at_place`, `markers(sector)`, `place_label`, `sectors()` = bekannte Sektoren, `pending_mission().loc`. Details: `docs/Planung_Story.md`, „Story-Orte mit Sektor und Ort“. **Fremde Datei:** `tests/test_hub.gd` (drei Zeilen im Story-Test: Ort als Dictionary, Start über `on_visit`). **An den Hub (Hub Auftrag 3, Punkt 5):** `on_visit(cur_sector, system, place)` in der Systemansicht aufrufen und Story-Orte dort zeigen (`at_place`), `on_arrive(cur_sector, position)` aufrufen; bis dahin starten Ketten an einem Ort im Spiel nicht.

## Hinweise und Bitte an den Koordinator

- **Layout (Nutzer, 19.10.2026):** Neue Fenster müssen zum restlichen Spiel passen und dürfen nicht wie ein Fremdkörper wirken. Lehre aus Auftrag 2: Vor dem Bauen einer Oberfläche Screenshots der vorhandenen Fenster ansehen (`-- --autotest-hub`) und daneben vergleichen, nicht nur Farben aus `UiTheme` übernehmen.
- **Bitte des Nutzers (erledigt 19.10.2026, `docs/Layout.md`):** feste Layoutregeln für alle Module. Muster, die der Story-Chat in den vorhandenen Fenstern gefunden hat: große feste Fenstergröße (`Modal.max_size`), goldener Titel mit grauer Erklärzeile darunter, Abschnittsüberschriften klein, grau, in Großbuchstaben, Auswahl als Karte (`PANEL2`, Rahmen `LINE`, Radius 8) mit Titel, grauer Beschreibung und Knopf mit goldener Schrift (Feindkontakt), Crew mit farbigem Buchstabenkästchen (`UiTheme.badge`), Seitenleiste mit gerahmten Reitern und Anzahl in Klammern (Enzyklopädie), Fußleiste rechts mit goldener Aktion und „Schließen“, keine gerahmten Etiketten, lange Texte mit Scrollbalken.

## Aufträge vom Koordinator

### Auftrag 6 (19.10.2026, dringend): Szenenfenster lässt sich nicht schließen

- Fehlermeldung des Nutzers (Probespiel): Erster Story-Kontakt, verhandelt, Probe erfolgreich. Das Fenster mit dem Ergebnis lässt sich nicht schließen, das Spiel hängt.
- Ursache laut Code (vom Koordinator gelesen, nicht nachgestellt): `StoryDialog._ready` setzt `closable = false`. „Schließen“ ruft `_finish()` → `close()` auf, und `Modal.close()` kehrt bei `closable == false` sofort zurück. Das Fenster bleibt offen, `finished` kommt zwar, aber das Fenster liegt weiter über allem. Dasselbe gilt für `_render()` mit leerer Ansicht.
- Bitte in `ui/story_dialog.gd` beheben (z. B. in `_finish` `hide()` statt `close()`, dann `closed`/`finished` senden), ohne `ui/modal.gd` zu ändern. Einen Test ergänzen, der eine Kette bis zum Ende durchklickt und prüft, dass das Fenster danach unsichtbar ist. Auch das Logbuch (`StoryLog`) auf dieselbe Falle prüfen.
