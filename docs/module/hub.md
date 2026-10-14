# Modul Hub (Startmenü, Schiff, Sternenkarte, Spielstände)

- **Branch:** `claude/happy-lamport-u4fvya`
- **Zuständig für:** `godot/start.tscn`, `godot/hub.tscn`, `godot/core/hub_state.gd`, `sector.gd`, `save_slots.gd`, `godot/view/hub.gd`, `ship_view.gd`, `start_screen.gd`, `godot/ui/hub_ui.gd`, `star_map.gd`, `slots_dialog.gd`, `godot/assets/ship/`.

## Schnittstellen (laut Branch, Commit `7657fed`)

- Startet den Bodenkampf mit einer Mission von der Sternenkarte (`HubState.active_mission()`, `Mission.generate(…, faction_path)`), bekommt einen Einsatzbericht zurück (`HubState.game.finish_mission(…)`).
- Spielstände: 3 Slots, kopieren u. a. `user://crew.json`.

## Stand (14.10.2026)

- Branch ist 1 Commit über `main`. Probe-Zusammenführung nach dem Charakter-Modul: **Konflikte** in `CLAUDE.md`, `godot/view/battle.gd`, `godot/ui/modal.gd`, Charakterübersicht (`ui/end_dialog.gd` ↔ `ui/crew/crew_overview.gd`).

- 14.10.2026 (Hub-Chat): `main` (`6bcaeaa`) in den Hub-Branch geholt, ohne Konflikte; Tests `test_rules` und `test_hub` „OK“. Die Aufträge 1–5 warten darauf, dass das Charakter-Modul in `main` ist (Stand jetzt: `claude/elegant-gauss-hq5bus` mit `cb63a27` und `1c6b94d` ist noch nicht in `main`).

## Aufträge vom Koordinator

Sobald das Charakter-Modul in `main` ist, `main` in den Hub-Branch holen und dort anpassen:

1. Crewquartiere: `CrewOverview` aus dem Charakter-Modul verwenden (oder nach `crew.tscn` wechseln und zurück) statt `EndDialog`.
2. `Roster.save_progress()/load_progress()/build_team(…, progress)` durch `Campaign.crew()` / `Campaign.save()` / `Roster.build_crew()` ersetzen.
3. `finish_hub_mission()` in `battle.gd`: keine eigene EP-Gutschrift (`EndDialog.FREE_XP`), sondern `MissionResult` → `Campaign.finish_mission()`; Bericht aus dem `MissionResult`. Sonst werden EP doppelt verbucht.
4. Nach dem Laden eines Spielstands `Campaign` neu laden (mit dem Charakter-Modul abstimmen).
5. `ui/modal.gd`: beide neuen Variablen behalten (`closable` und `max_size`).

Details: `docs/Zusammenfuehrung.md`.
