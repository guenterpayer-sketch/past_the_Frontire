# Modul Charakter (Charakter-Modul und Charakter-Editor)

- **Branch:** `claude/elegant-gauss-hq5bus`
- **Zuständig für:** `godot/core/character.gd`, `roster.gd`, `campaign.gd`, `mission_result.gd`, `rules.gd` (Steigerung), `godot/crew.tscn`, `godot/ui/crew/`, `godot/ui/sheet_dialog.gd`, `godot/data/units/crew*`, Charakter-Editor.

## Schnittstellen (laut Branch, Commit `cb63a27`)

- `Character`: Crewmitglied mit allen dauerhaften Werten, gespeichert in `user://crew.json` (Version 3).
- `Roster.load_crew()`, `save_crew()`, `start_crew()`, `build_crew()` (Kopien für den Kampf), `reset()`. Die alten `load_progress()`/`save_progress()` gibt es dort nicht mehr.
- `Campaign.crew()`, `Campaign.finish_mission(result)`, `Campaign.CREW_SCENE`.
- `MissionResult.from_combat(combat, mission)`, `MissionResult.FREE_XP`.
- `CrewOverview.show_crew(crew: Array[Character], result)` in `crew.tscn` (ersetzt `ui/end_dialog.gd`).

## Stand (14.10.2026)

- Branch ist 1 Commit über `main` (Modul-Trennung). Charakter-Editor selbst noch nicht gepusht. Probe-Zusammenführung mit `main`: **ohne Konflikte**.

## Aufträge vom Koordinator

- Wird als erstes Modul zusammengeführt, sobald als bereit gemeldet.
- Hinweis für danach: `Campaign` hält die Crew statisch im Speicher. Der Hub lädt Spielstände durch Überschreiben von `user://crew.json`; dafür braucht es eine Möglichkeit, `Campaign` neu zu laden (Abstimmung mit dem Hub).
