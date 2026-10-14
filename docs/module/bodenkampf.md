# Modul Bodenkampf

- **Branch:** `claude/confident-edison-6mxzke`
- **Zuständig für:** `godot/main.tscn`, `godot/view/` (außer Hub-Szenen), `godot/core/combat*.gd`, `combatant.gd`, `battle_map.gd`, `map_generator.gd`, `mission.gd`, `tables.gd`, `dice.gd`, `hex.gd`, `godot/ui/` des Kampfes (`battle_ui.gd`, `action_panel.gd`, `unit_card.gd`, `top_menu.gd`, `info_box.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, `briefing_dialog.gd`), `godot/data/` für Waffen, Rüstungen, Tabellen, Gegner, Fraktionen.

## Schnittstellen

- **Eingang:** Crew als Kopien aus `Campaign.crew()` (`Roster.build_crew()`), optional eine fertige `Mission` (aus der Sternenkarte des Hubs).
- **Ausgang:** `MissionResult.from_combat()` → `Campaign.finish_mission()` → Szene `crew.tscn`. `ui/end_dialog.gd` und `Roster.load_progress()/save_progress()` gibt es nicht mehr.

## Stand (14.10.2026)

- In `main`: Kampf, Missionsgenerator, Runde 0, schwebende Kampf-UI.
- Seit `cf5ad7e` (Charakter-Modul) in `main`: Kampf übergibt nur noch Daten (`MissionResult`), Charakterübersicht liegt im Charakter-Modul. **Regeländerung, die auch den Kampf betrifft:** neue Fertigkeiten Körperentwicklung, Psi-Punkte-Entwicklung, 5 Psi-Listen; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung (gilt auch für Gegner, Psi-Figuren haben mehr PP). Bodenkampf-Branch ist 1 Commit hinter `main`.

- **15.10.2026, Bodenkampf-Branch:** `main` (`2c91832`) ohne Konflikte eingeholt; `test_rules.gd` OK, `--autotest` (Kampf → `crew.tscn` inkl. Editor) läuft durch.
- **Auswirkung der neuen TP/PP-Formeln** (Gegner- und Crewwerte unverändert): TP bleiben bei allen Figuren gleich (niemand hat Körperentwicklung). PP: Nyx 13 → 19, Hexer 11 → 14, Corvin 0 → 7 (Rang in Psi-Verteidigung, aber keine Psi-Waffe, im Kampf ohne Wirkung). Simulation `test_sim.gd -- 150 missionen` (gleiche Startwerte, 50 Kämpfe je Stufe), Siege der Crew alt → neu: leicht 49 → 50, mittel 35 → 36, schwer 18 → 24 (gesamt 68 % → 73 %). Der Unterschied bei „schwer“ liegt innerhalb der Zufallsschwankung bei 50 Kämpfen (grob ±10 Prozentpunkte); eine Tendenz zugunsten der Crew ist möglich, aber nicht belegt. Gegnerwerte nicht angepasst; **Entscheidung des Nutzers: so lassen.**
- **15.10.2026, nach Hub in `main` (`1cf8d86` eingeholt, ohne Konflikte):** Kampfende des Hubs geprüft (ein Kampfende, keine doppelten EP, Bericht im Schiff; `test_hub.gd` und `--autotest-hub` laufen durch). Entscheidungen des Nutzers umgesetzt:
  - **Ergebnis-Banner** (`ui/result_banner.gd`) über der Karte: Sieg/Niederlage/Rückzug mit Bilanz; Szenenwechsel erst auf „Weiter“ (bzw. Enter). `Battle.finish_mission()` wartet darauf.
  - **Abbrechen im Schiffsmodus** mit Rückfrage (`BattleUI.ask()`): vor Runde 1 zurück ins Schiff (Auftrag bleibt offen, wie bisher `return_to_ship()`); ab Runde 1 **Rückzug** (`Combat.retreat()`: `result = niederlage`, `retreated = true`), Ergebnis läuft über das normale Kampfende; im Bericht ans Schiff steht „(Rückzug)“ hinter dem Titel. Das Briefing-„Zurück ins Schiff“ bleibt ohne Rückfrage. Schnellkampf („Neue Mission“) unverändert.
  - **Hinweis an Hub:** `tests/autotest_hub.gd` drückt jetzt den „Weiter“-Knopf des Banners (sonst bleibt der Test im Kampf stehen). `HubState`/`hub_ui.gd` unverändert; ein eigener Ausgang „Rückzug“ im Bericht wäre Sache des Hubs (`MissionResult` liefert weiter `outcome = niederlage`).
  - Rückzug ist im Regeltest geprüft (`test_rules.gd`), im grafischen Hub-Selbsttest noch nicht.
  - **Später, eigenes Thema (Entscheidung Nutzer):** Zustand nach dem Kampf (Verletzte, Tote, Vorräte) auswerten.
- **15.10.2026, `main` (`c3be261`) eingeholt:** Konflikt in `godot/README.md` gelöst (Punkt 3 mit Ergebnis-Banner, Rückzug und Schnellkampf ohne Banner; Punkt 4 „Aufleveln“ aus `main`). `Battle.finish_mission()`: Schnellkampf-Zweig aus `main` steht vor dem Banner (Entscheidung: kein Banner beim Schnellkampf). Tests: `test_rules.gd` OK, `test_hub.gd` OK, `test_sim.gd -- 30` ohne Hänger, `--autotest`, `--autotest-player`, `--autotest-hub` (inkl. Schnellkampf: zurück ins Startmenü, nichts verbucht) laufen durch. **Bereit zum Zusammenführen.**

## Aufträge vom Koordinator

- ~~`main` holen und Balancing mit den neuen TP/PP-Formeln prüfen~~ → erledigt (Entscheidung: so lassen).
- **Hub ist seit 15.10.2026 in `main` (`012efdf`).** Das gemeinsame Kampfende hat der Hub-Chat bereits in `view/battle.gd` gebaut (`Battle.finish_mission()`: `MissionResult` → `Campaign.finish_mission()` → aus dem Schiff mit Bericht zurück ins Schiff, Schnellkampf nach `crew.tscn`; keine eigene EP-Gutschrift). `main` holen und die Änderungen des Hubs an Bodenkampf-Dateien durchsehen: `view/battle.gd` (`finish_mission()`, `hub_report()`, `return_to_ship()`, `new_battle(…, m)`), `ui/briefing_dialog.gd` (`hub_mode`), `ui/top_menu.gd` (`set_menu_text()`), `core/mission.gd` (`faction_path`), `data/types/faction_data.gd` und `data/missions/*.tres` (`color`). Was davon noch fehlt oder anders sein soll, mit dem Nutzer klären, bevor gebaut wird.
- Neu in `main`: Hub `df91246` hat in `view/battle.gd` einen Zweig für den Schnellkampf ergänzt (`HubState.quick_battle`: nichts verbuchen, zurück ins Startmenü). Mit durchsehen.
- **15.10.2026, Probe `main` (`e2ea8c4`) + Bodenkampf `d483bf4`: Konflikt, nicht zusammengeführt.** Der Branch ist 9 Commits hinter `main` (Hub `df91246` und Charakter-Aufleveln `d375736` fehlen). Bitte `main` holen und dort lösen:
  1. **Konflikt in `godot/README.md`**, Abschnitt Ablauf, Punkte 3 und 4: `main` beschreibt die Charakterübersicht schon als „Aufleveln“ (3D-Vorschau, Reiter, `Character.new_list` …), der Branch das Ergebnis-Banner und den Rückzug. Beides behalten.
  2. **Inhaltlich, ohne Git-Konflikt:** In `main` hat `Battle.finish_mission()` vorne einen Zweig für den Schnellkampf aus dem Startmenü (`HubState.quick_battle`: nichts verbuchen, Meldung im Kampflog, nach 2,5 s zurück ins Startmenü). Nach dem Zusammenführen kehrt dieser Zweig vor dem Ergebnis-Banner zurück, der Schnellkampf zeigt also kein Banner. **Entscheidung des Nutzers: so lassen** (kein Banner beim Schnellkampf; Kampflog-Zeile und nach 2,5 s zurück ins Startmenü). Der Zweig aus `main` bleibt beim Zusammenführen also vor dem Banner.
  3. Danach Tests inkl. `--autotest-hub` (Schnellkampf-Teil, `HubState.quick_battle = true`) und als bereit melden.
- ~~Probe-Konflikt `godot/README.md`, Schnellkampf-Zweig~~ → gelöst, in `main` seit 15.10.2026 (`1dc3362`).
