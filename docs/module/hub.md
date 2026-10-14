# Modul Hub (Startmenü, Schiff, Sternenkarte, Spielstände)

- **Branch:** `claude/happy-lamport-u4fvya`
- **Zuständig für:** `godot/start.tscn`, `godot/hub.tscn`, `godot/core/hub_state.gd`, `sector.gd`, `save_slots.gd`, `godot/view/hub.gd`, `ship_view.gd`, `start_screen.gd`, `godot/ui/hub_ui.gd`, `star_map.gd`, `slots_dialog.gd`, `godot/assets/ship/`.

## Schnittstellen (laut Branch, Commit `7657fed`)

- Startet den Bodenkampf mit einer Mission von der Sternenkarte (`HubState.active_mission()`, `Mission.generate(…, faction_path)`), bekommt einen Einsatzbericht zurück (`HubState.game.finish_mission(…)`).
- Spielstände: 3 Slots, kopieren u. a. `user://crew.json`.

## Stand (14.10.2026)

- 14.10.2026 (Hub-Chat): `main` (`2c91832`, mit Charakter-Modul) in den Hub-Branch geholt. Konflikte gelöst in `CLAUDE.md`, `godot/view/battle.gd`, `godot/ui/modal.gd` (beide Variablen `closable` und `max_size`), `godot/ui/crew/crew_overview.gd` (Fassung aus `main` übernommen, Hub-Änderungen daran verworfen).
- Aufträge 1–5 erledigt:
  1. Crewquartiere nutzen `CrewOverview` (mit `CharacterEditor` und `SheetDialog` wie in `crew.tscn`) direkt im Schiff; der Knopf „Speichern & nächste Mission“ wird im Schiff zu „Speichern & zurück“ umbenannt (von außen, ohne Änderung an `crew_overview.gd`).
  2. Hub nutzt nur noch `Campaign.crew()`, `Campaign.save()`, `Campaign.reset()`, `Campaign.add_member()`, `Roster.build_crew()`.
  3. `Battle.finish_mission()` ist das eine Kampfende: `MissionResult.from_combat()` → `Campaign.finish_mission()`; aus dem Schiff dann `HubState.game.finish_mission(hub_report(result))` und zurück ins Schiff, sonst nach `crew.tscn`. Keine eigene EP-Gutschrift mehr (geprüft: 3 + 3 = 6 freie EP nach einem Sieg „mittel“, nicht doppelt).
  4. `SaveSlots.load_slot()` ruft `Campaign.reload()`, `SaveSlots.save()` vorher `Campaign.save()`; Neues Spiel: `Campaign.reset()` + `Campaign.save()`.
  5. `ui/modal.gd`: `closable` und `max_size` beide da.
- Änderungen an Dateien anderer Module: `godot/view/battle.gd` (Bodenkampf: `finish_mission()` mit Weg ins Schiff, `hub_report()`, `return_to_ship()`, `new_battle(…, m)`), `ui/briefing_dialog.gd` (`hub_mode`), `ui/top_menu.gd` (`set_menu_text()`), `core/mission.gd` (`faction_path`), `data/types/faction_data.gd` + `data/missions/*.tres` (`color`). Am Charakter-Modul nichts geändert.
- Tests: `test_rules` OK, `test_hub` OK, `test_sim -- 30` OK (22 Siege, 0 hängengeblieben), `--autotest` (Schnellkampf → `crew.tscn`, Editor) fertig, `--autotest-player` fertig, `--autotest-hub` (Schiff → Kampf → zurück, Crewquartiere mit Ergebnis, Laden mit `Campaign.reload()`) fertig.
- Neu seit `77449d9` (noch nicht in `main`): Entscheidungen des Nutzers umgesetzt: „Crew zurücksetzen“ ist in den Crewquartieren im Schiff ausgeblendet. Der Schnellkampf aus dem Startmenü (`HubState.quick_battle`) nutzt die aktuelle Crew, verbucht nichts (kein `Campaign.finish_mission()`) und kehrt ins Startmenü zurück. Bodenkampf ohne Startmenü (Tests, „Speichern & nächste Mission“ in `crew.tscn`) verbucht wie bisher und geht nach `crew.tscn`.
- 15.10.2026: `main` (`1cf8d86`) erneut geholt, ohne Konflikte (nur Doku). **Bereit zum Zusammenführen.**

## Aufträge vom Koordinator

- ~~Aufträge 1–5 (Anpassung an das Charakter-Modul)~~ → erledigt, in `main` seit 15.10.2026 (`012efdf`).
- `main` holen (enthält jetzt die Moduldatei des Bodenkampfs).
- Charakter-Modul (Aufleveln, `d375736`) ist seit 15.10.2026 in `main`: `main` holen. Die Charakterübersicht in den Crewquartieren hat jetzt eine 3D-Vorschau; in den Crewquartieren einmal prüfen, ob sie dort richtig angezeigt wird (vom Koordinator nicht grafisch getestet).
- Bodenkampf `381fb01` ist in `main` (15.10.2026): Ergebnis-Banner mit „Weiter“, Rückzug ab Runde 1 (Bericht: Titel mit „(Rückzug)“, `outcome = niederlage`). Der Bodenkampf hat `tests/autotest_hub.gd` angepasst (drückt „Weiter“). `main` holen. Eigene Anzeige für Rückzug im Bericht: nur nach Entscheidung des Nutzers.

### Nach dem Spieltest (15.10.2026) – Grundlage: `docs/Planung_Roster_Verwundung.md`

1. **Roster und neues Spiel** (Abschnitt A, Teil Hub): Startmenü-Eintrag „Roster“, „Neues Spiel“ → Crew aus dem Roster wählen (UI mit dem Charakter-Modul abstimmen, erst **Mockup**). Plätze an Bord im `HubState` (zu Beginn 8, später ausbaubar), Anheuern aus dem Roster im Schiff. Spielstände enthalten die Crew, nicht den Roster.
2. **Krankenstation** (Abschnitt B, Teil Hub): Verwundete und Resttage anzeigen, Tage vergehen beim Reisen/Einsatz → Heilung (Funktion vom Charakter-Modul), vor dem Einsatz Gesperrte nicht mitnehmen, leicht Verletzte mit Malus. **Tage-Werte vorschlagen** (anhand typischer Reise- und Auftragsdauer) und vom Nutzer entscheiden lassen.
3. Rückzug im Bericht: weiter offen (nur nach Entscheidung des Nutzers).
