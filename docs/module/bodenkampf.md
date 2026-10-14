# Modul Bodenkampf

- **Branch:** `claude/confident-edison-6mxzke`
- **Zuständig für:** `godot/main.tscn`, `godot/view/` (außer Hub-Szenen), `godot/core/combat*.gd`, `combatant.gd`, `battle_map.gd`, `map_generator.gd`, `mission.gd`, `tables.gd`, `dice.gd`, `hex.gd`, `godot/ui/` des Kampfes (`battle_ui.gd`, `action_panel.gd`, `unit_card.gd`, `top_menu.gd`, `info_box.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, `briefing_dialog.gd`), `godot/data/` für Waffen, Rüstungen, Tabellen, Gegner, Fraktionen.

## Schnittstellen

- **Eingang:** Crew (heute `Roster.build_team(GameData.crew(), …, Roster.load_progress())`; nach dem Zusammenführen des Charakter-Moduls: Kopien aus `Campaign.crew()`), optional eine fertige `Mission` (aus der Sternenkarte des Hubs).
- **Ausgang:** heute Charakterübersicht im Kampf (`ui/end_dialog.gd`) und `Roster.save_progress()`; nach dem Zusammenführen: `MissionResult` → `Campaign.finish_mission()`.

## Stand (14.10.2026)

- In `main`: Kampf, Missionsgenerator, Runde 0, schwebende Kampf-UI, Charakterübersicht nach dem Kampf mit Einzahlen und Bogen.

## Aufträge vom Koordinator

- Nach dem Zusammenführen von Charakter-Modul und Hub: **ein einziges Kampfende** (`MissionResult` → `Campaign.finish_mission()` → aus dem Schiff zurück ins Schiff mit Bericht, Schnellkampf in `crew.tscn`). Keine eigene EP-Gutschrift mehr im Kampf. Details: `docs/Zusammenfuehrung.md`.
