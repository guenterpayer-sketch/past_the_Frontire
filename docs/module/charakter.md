# Modul Charakter (Charakter-Modul und Charakter-Editor)

- **Branch:** `claude/elegant-gauss-hq5bus`
- **Zuständig für:** `godot/core/character.gd`, `roster.gd`, `campaign.gd`, `mission_result.gd`, `rules.gd` (Steigerung), `godot/crew.tscn`, `godot/ui/crew/`, `godot/ui/sheet_dialog.gd`, `godot/data/units/crew*`, Charakter-Editor.

## Schnittstellen (Stand dieses Branches)

- `Character`: Crewmitglied mit allen dauerhaften Werten (inkl. `station`), gespeichert in `user://crew.json` (Version 3; Version 1/2 werden auf die Startcrew gelegt).
- `Roster.load_crew()`, `save_crew()`, `start_crew()`, `build_crew()` (Kopien für den Kampf), `reset()`. Die alten `load_progress()`/`save_progress()` gibt es nicht mehr; `build_team(team, team_id)`/`build_units()` nur noch für Vorlagen (Gegner, Tests), ohne `progress`.
- `Campaign.crew()`, `Campaign.save()`, `Campaign.finish_mission(result)`, `Campaign.add_member(ch, replace)`, `Campaign.reset()`, **`Campaign.reload()`** (Crew neu von der Festplatte lesen, z. B. nach dem Laden eines Spielstands; verwirft `last_result`), `Campaign.CREW_SCENE`, `Campaign.BATTLE_SCENE`.
- `MissionResult.from_combat(combat, mission)` → Dictionary (EP je Fertigkeit, freie EP, Zustand, Verbrauch), `MissionResult.FREE_XP`.
- `CrewOverview.show_crew(crew: Array[Character], result)` in `crew.tscn` (ersetzt `ui/end_dialog.gd`), Signale `next_battle`, `reset_crew`, `create_member`, `open_sheet`.
- `CharacterEditor.open_new(crew, replace_idx)`, Signal `saved(ch, replace)`; Regeln in `Creation` (`core/creation.gd`), Psi-Listen in `PsiLists` (`core/psi_lists.gd`).
- Neu (nur Erweiterungen, keine Änderung bestehender Aufrufe): `Character.new_list` (in dieser Levelphase begonnene Psi-Liste, wird in `apply_result` geleert, gespeichert), `Rules.next_rank_cost(ch, id)`, `Rules.rank_block(ch, id)`, `Rules.is_psi_list(id)`; `Rules.rank_up`/`rank_up_cost`/`can_rank_up` rechnen damit (neue Liste doppelt, eine pro Phase). `FigurePreview` (`ui/crew/figure_preview.gd`): 3D-Vorschau einer Figur.
- `ui/modal.gd`: neue Variable `closable` (false = Klick daneben und Esc schließen nicht).
- **Regeländerungen in `Rules`** (wirken auf alle Figuren, auch Gegner): neue Fertigkeitsgruppen „Entwicklung“ (`koerper`, `psiPunkte`) und „Psi-Listen“; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung, nur mit Rang in einer Psi-Fertigkeit oder Liste (`Rules.PSI_SKILLS`).

## Stand (14.10.2026)

- In `main` zusammengeführt (Merge `cf5ad7e`). Branch danach auf `main` = `2c91832` gebracht.
- In Arbeit: **Aufleveln** in der Charakterübersicht (Mockup „Frontire Aufleveln“ vom Nutzer freigegeben): 3D-Vorschau, Name/Kürzel/Farbe/Station/Aussehen änderbar, Psi-Kräfte, keine Ranggrenze, neue Psi-Liste doppelt und eine pro Levelphase. `CrewOverview.show_crew(crew, result)` und die Signale bleiben unverändert.
- Noch nicht gebaut: Psi-Listen im Kampf.

## Aufträge vom Koordinator

- ~~Wird als erstes Modul zusammengeführt, sobald als bereit gemeldet.~~ → bereit (siehe Stand).
- ~~`Campaign` neu laden können~~ → `Campaign.reload()`; der Hub ruft es nach dem Laden eines Spielstands auf.
