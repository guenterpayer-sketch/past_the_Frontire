# Modul Bodenkampf

- **Branch:** `claude/confident-edison-6mxzke`
- **Zuständig für:** `godot/main.tscn`, `godot/view/` (außer Hub-Szenen), `godot/core/combat*.gd`, `combatant.gd`, `battle_map.gd`, `map_generator.gd`, `mission.gd`, `tables.gd`, `dice.gd`, `hex.gd`, `godot/ui/` des Kampfes (`battle_ui.gd`, `action_panel.gd`, `unit_card.gd`, `top_menu.gd`, `info_box.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, `briefing_dialog.gd`), `godot/data/` für Waffen, Rüstungen, Tabellen, Gegner, Fraktionen.

## Schnittstellen

- **Eingang:** Crew als Kopien aus `Campaign.crew()` (`Roster.build_crew()`), optional eine fertige `Mission` (aus der Sternenkarte des Hubs).
- **Ausgang:** `MissionResult.from_combat()` → `Campaign.finish_mission()` → Szene `crew.tscn`. `ui/end_dialog.gd` und `Roster.load_progress()/save_progress()` gibt es nicht mehr.

## Stand (14.10.2026)

- In `main`: Kampf, Missionsgenerator, Runde 0, schwebende Kampf-UI.
- Seit `cf5ad7e` (Charakter-Modul) in `main`: Kampf übergibt nur noch Daten (`MissionResult`), Charakterübersicht liegt im Charakter-Modul. **Regeländerung, die auch den Kampf betrifft:** neue Fertigkeiten Körperentwicklung, Psi-Punkte-Entwicklung, 5 Psi-Listen; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung (gilt auch für Gegner, Psi-Figuren haben mehr PP). Bodenkampf-Branch ist 1 Commit hinter `main`.

## Aufträge vom Koordinator

- Vor der nächsten Arbeit `main` holen (`git merge origin/main`, Charakter-Modul ist drin) und Gegner-Werte/Balancing mit den neuen TP/PP-Formeln prüfen.

- Nach dem Zusammenführen von Charakter-Modul und Hub: **ein einziges Kampfende** (`MissionResult` → `Campaign.finish_mission()` → aus dem Schiff zurück ins Schiff mit Bericht, Schnellkampf in `crew.tscn`). Keine eigene EP-Gutschrift mehr im Kampf. Details: `docs/Zusammenfuehrung.md`.
