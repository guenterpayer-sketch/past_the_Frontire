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
- **Roster (neu):** `GlobalRoster` (`core/global_roster.gd`, `user://roster.json`, gehört keinem Spielstand): `entries()`, `own()`, `find(id)`, `is_protected(ch)`, `add(ch)`, `update(ch)` (nur Name/Kürzel/Farbe/Aussehen), `remove(id)`, `copy(ch, name)`. `Character.roster_id` = Herkunft im Roster (wird gespeichert).
- **Campaign (neu):** `new_game(picked: Array[Character])` (Crew aus Roster-Kopien), `hire(entry)` (null, wenn schon an Bord), `fire(ch)`, `is_aboard(roster_id)`, `squad()` (Figuren für den Einsatz: `chosen_squad` oder die ersten 6), `chosen_squad` (vom Hub vor dem Einsatz zu setzen), `START_SEATS = 8`, `MAX_SQUAD = 6`, `ROSTER_SCENE`.
- **UI (neu):** `roster.tscn` (`RosterScreen`, „Zurück“ → `res://start.tscn`), `CrewPicker` (`open_pick(subtitle, seats)`, Signal `picked(chars)`), `CrewOverview.seats` und Signal `crew_changed` (nach Anheuern/Entlassen; die Übersicht baut sich dabei neu auf – eigene Knopftexte des Aufrufers danach neu setzen). „Neues Crewmitglied“ ist aus der Übersicht entfernt; das Signal `create_member` bleibt bestehen, wird aber nicht mehr gesendet. `CharacterEditor.open_for_roster()`.
- **Geändert in `view/battle.gd` (Bodenkampf, eine Zeile):** der Kampf nimmt `Roster.build_crew(Campaign.squad())` statt der ganzen Crew (sonst kämen bis zu 8 Figuren in den Kampf).
- `ui/modal.gd`: neue Variable `closable` (false = Klick daneben und Esc schließen nicht).
- **Regeländerungen in `Rules`** (wirken auf alle Figuren, auch Gegner): neue Fertigkeitsgruppen „Entwicklung“ (`koerper`, `psiPunkte`) und „Psi-Listen“; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung, nur mit Rang in einer Psi-Fertigkeit oder Liste (`Rules.PSI_SKILLS`).

## Stand (15.10.2026)

- Roster gebaut nach Mockup „Frontire Roster“ (vom Nutzer freigegeben): Roster-Bildschirm, Crew-Auswahl, Anheuern/Entlassen, Trupp über `Campaign.squad()`. Tests in `test_rules.gd` (`_test_roster`).
- **Für den Hub zum Anbinden** (seine Dateien, daher nicht von mir geändert):
  1. Startmenü: Punkt „Roster“ → `get_tree().change_scene_to_file(Campaign.ROSTER_SCENE)`.
  2. „Neues Spiel“: nach Slot und Name `CrewPicker.open_pick("Spielstand … · Slot …", seats)` öffnen; bei `picked(chars)` statt `Campaign.reset()` → `Campaign.new_game(chars)`, dann wie bisher `HubState.new_game(…)` und speichern.
  3. Crewquartiere: `ui.crew.seats` aus den Plätzen an Bord setzen; `crew_changed` → Knopftext „Speichern & zurück“ erneut setzen; Verbindung zu `create_member` und den Editor in den Crewquartieren entfernen.
  4. Briefing/Truppwahl: vor dem Start `Campaign.chosen_squad` setzen (bis 6; Gesperrte kommen mit Auftrag 2 Verwundung).
  5. Spielstände: `user://roster.json` gehört **nicht** in die Slots.
- Verwundung (Auftrag 2) wartet auf die `MissionResult`-Felder vom Bodenkampf.

## Aufträge vom Koordinator

- ~~Wird als erstes Modul zusammengeführt, sobald als bereit gemeldet.~~ → bereit (siehe Stand).
- ~~`Campaign` neu laden können~~ → `Campaign.reload()`; der Hub ruft es nach dem Laden eines Spielstands auf.
- In `main` seit 14.10.2026 (`cf5ad7e`). Hub ist seit 15.10.2026 in `main` (`012efdf`) und nutzt `Campaign`, `CrewOverview`, `CharacterEditor`, `SheetDialog` direkt in den Crewquartieren: `main` holen; Änderungen an diesen Schnittstellen vorher in dieser Datei ankündigen.
- Hub `df91246` ist in `main`: blendet im Schiff „Crew zurücksetzen“ aus, indem er in `footer` nach dem Knopftext sucht. Knopftexte „Crew zurücksetzen“ und „Speichern & nächste Mission“ nicht ändern, ohne das hier anzukündigen. `main` holen.
- Bodenkampf `381fb01` ist in `main` (Ergebnis-Banner vor dem Wechsel nach `crew.tscn`): `main` holen.

### Nach dem Spieltest (15.10.2026) – Grundlage: `docs/Planung_Roster_Verwundung.md`

1. **Globaler Roster** (Abschnitt A): 6 Startcharaktere + selbst erstellte Figuren, unabhängig von Spielständen. Neues Spiel = Crew aus dem Roster wählen (Kopien), 6 im Einsatz + Reserve (Plätze vom Hub, zu Beginn 8). Im Spiel kein Editor mehr, sondern Anheuern aus dem Roster. Offene Punkte aus Abschnitt A mit dem Nutzer klären, Roster-Bildschirm und Auswahl erst als **Mockup** (mit dem Hub abstimmen: Startmenü).
2. **Verwundung** (Abschnitt B, Teil Charakter): `Character` speichert Verwundung (Stufe, Resttage) und Tod; `Campaign.finish_mission()` wertet die neuen `MissionResult`-Felder aus (kommen vom Bodenkampf); Funktion für „Tage vergehen“ für den Hub; Charakterübersicht zeigt den Zustand.
3. **Psi im Kampf:** Der Bodenkampf braucht die gelernten Listen und Ränge aus `Character`; Schnittstelle mit ihm abstimmen.

### Entscheidungen zu Abschnitt A (Roster), 15.10.2026

- Startmenü bekommt einen eigenen Punkt **„Roster“** (ansehen, erschaffen, bearbeiten); „Neues Spiel“ führt danach zur **Crew-Auswahl aus dem Roster** (dort auch „Neue Figur“ → Roster).
- Roster: eigene Figuren **bearbeiten** (nur Name, Kürzel, Farbe, Aussehen – Werte fest), **löschen** (mit Abfrage), **kopieren** (exakte Kopie unter neuem Namen, auch von Startcharakteren); die 6 **Startcharaktere sind schreibgeschützt**.
- Neues Spiel: **1 bis 8** Figuren wählen (Plätze an Bord zu Beginn 8); jede Roster-Figur **höchstens einmal** pro Spiel.
- Im Spiel: Crewquartiere bekommen **„Anheuern“** (Roster-Figuren, die nicht an Bord sind; nur bei freiem Platz; Kopie mit Roster-Stand) und **„Entlassen“** (Fortschritt im Spiel geht verloren, Roster-Eintrag bleibt). Kein Editor mehr im Spiel.
- **Einsatztrupp vor jedem Einsatz wählen** (bis zu 6, Gesperrte ausgegraut) – im Briefing des Hubs.
- Mockup: Artifact „Frontire Roster“ (https://claude.ai/artifact/2jBTihVzLwRHSbuA7VwpJh), wartet auf Freigabe durch den Nutzer und Abstimmung mit dem Hub (Startmenü, Briefing, Plätze an Bord).

### Auftrag vom Koordinator (15.10.2026, nach Merge `f81e9fd`)

Roster ist in `main`. **Klärung aus `docs/Planung_Roster_Verwundung.md`, Abschnitt D, umsetzen** (ersetzt die abweichenden Einträge oben unter „Entscheidungen zu Abschnitt A“):
1. „Anheuern“ aus den Crewquartieren entfernen – Anheuern findet auf der Brücke nur im Hafen statt (Oberfläche baut der Hub, er nutzt `Campaign.hire()`).
2. Entlassen: Fortschritt bleibt im Spielstand; entlassene Figuren in einer Liste in `Campaign` („im Hafen“), mit der Crew gespeichert, in diesem Spiel wieder anheuerbar (`hire` aus dieser Liste mit ihrem Stand). Text im Entlassen-Dialog anpassen.
3. `Campaign.chosen_squad` merken und speichern (letzter Trupp wird im Briefing vorbelegt); Sperr-Status je Figur für die Truppwahl bereitstellen (kommt mit der Verwundung).
4. Moduldatei an D anpassen; Widerspruch „Mockup freigegeben“ / „wartet auf Freigabe“ klären.
Danach Verwundung (Auftrag 2), sobald der Bodenkampf mit den `MissionResult`-Feldern in `main` ist.

## Aufträge vom Koordinator (16.10.2026)

Bodenkampf (Verwundung, Psi) und Hub (Plätze an Bord) sind in `main` (`fdb96d9`). Zuerst `main` holen. Grundlage: `docs/Planung_Roster_Verwundung.md`, Abschnitte B, D, E.
1. **Klärung D** (Auftrag oben vom 15.10.): Anheuern aus den Crewquartieren entfernen, Entlassene mit Fortschritt „im Hafen“ (Liste in `Campaign`, gespeichert), `chosen_squad` speichern, Moduldatei bereinigen.
2. **Verwundung auswerten:** `Campaign.finish_mission()` liest `worst_crit`, `dying`, `stabilized`, `died` aus dem `MissionResult` → Stufe und Resttage in `Character` (Werte aus `hub.md`: angeschlagen 2, kampfunfähig 5, schwer verwundet 10 Tage; Zuschlag A+0 … E+4). Tote verlassen die Crew (Roster-Eintrag bleibt). Funktion „Tage vergehen“ für den Hub (Heilung um n Tage, Ergebnis der Arzt-Probe kommt vom Hub). Charakterübersicht zeigt Zustand und Resttage; die Ergebniszeile kennt „sterbend“ noch nicht (zeigt leer).
3. **Kandidaten für die Truppwahl:** eine Funktion, die die wählbaren Figuren mit Sperr-Status liefert (im Spiel: Crew + Reserve, gesperrt = kampfunfähig/schwer verwundet/Arzt, markiert = angeschlagen; im Schnellkampf: Kopien aus dem globalen Roster). Mit dem Bodenkampf abstimmen (er baut die Truppwahl im Briefing).
