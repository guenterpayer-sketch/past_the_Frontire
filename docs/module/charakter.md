# Modul Charakter (Charakter-Modul und Charakter-Editor)

- **Branch:** `claude/elegant-gauss-hq5bus`
- **Zuständig für:** `godot/core/character.gd`, `roster.gd`, `global_roster.gd`, `campaign.gd`, `mission_result.gd` (Format), `injury.gd`, `creation.gd`, `psi_lists.gd`, `rules.gd` (Steigerung), `godot/crew.tscn`, `godot/roster.tscn`, `godot/ui/crew/`, `godot/ui/sheet_dialog.gd`, `godot/data/units/crew*`.

## Schnittstellen

**Figur und Speicher**
- `Character`: Crewmitglied mit allen dauerhaften Werten (inkl. `station`, `roster_id` = Herkunft im Roster, `new_list`, `injury` + `injury_days`). Methoden: `apply_result(r)`, `heal(days)`, `is_locked()`, `injury_text()`, `to_dict()/from_dict()`.
- `Roster`: Crew des Spielstands in `user://crew.json` (Version 3, dazu `harbor` und `squad`): `load_crew()`, `load_extra()`, `save_crew(crew, harbor, squad_ids)`, `start_crew()`, `build_crew()` (Kopien für den Kampf), `reset()`. `build_team()/build_units()` nur für Vorlagen (Gegner, Tests).
- `GlobalRoster` (`user://roster.json`, gehört **keinem** Spielstand): `entries()`, `own()`, `find(id)`, `is_protected(ch)` (Startcharaktere), `add(ch)`, `update(ch)` (nur Name/Kürzel/Farbe/Aussehen), `remove(id)`, `copy(ch, name)`, `unique_id(name)`.

**Laufendes Spiel (`Campaign`)**
- `crew()`, `save()`, `reload()` (nach dem Laden eines Spielstands), `reset()`, `add_member(ch, replace)` (alt).
- `new_game(picked)` – Crew aus Roster-Kopien (1 bis 8).
- `hire(entry)` – Anheuern: eine Figur „im Hafen“ kommt mit Fortschritt zurück, sonst Kopie mit Roster-Stand; `null`, wenn schon an Bord. Ort (Hafen) und Platzprüfung macht der Hub.
- `fire(ch)` – Entlassen: Figur wartet mit Fortschritt „im Hafen“ (`harbor()`), Roster bleibt unberührt.
- `is_aboard(roster_id)`, `harbor()`, `patients()`.
- `finish_mission(result)` – verbucht EP, freie EP und **Verwundung**; Tote (`died`) verlassen die Crew, stehen in `last_fallen`.
- `pass_days(days, bonus_days = 0)` – Heilung (Hub ruft es je Tag mit dem Ergebnis der Zweite-Hilfe-Probe auf); gibt die Geheilten zurück.
- `candidates(quick = false, blocked_ids = [])` – Kandidaten für die Truppwahl: `[{ch, locked, reason, marked, note}]`; im Spiel die Crew, gesperrt = kampfunfähig/schwer verwundet/Arzt (`blocked_ids` vom Hub), markiert = angeschlagen; `quick = true`: Kopien aus dem globalen Roster.
- `suggested_squad(cands)` – Vorbelegung: letzter Trupp ohne Gesperrte, aufgefüllt aus der Reserve.
- `set_squad(chars)` – Ergebnis der Truppwahl (gespeichert); Schnellkampf stattdessen `quick_squad = chars` (nicht gespeichert, wird nach dem Kampf geleert).
- `squad()` – Figuren für den Kampf (`quick_squad`, sonst `chosen_squad`, sonst die ersten 6 nicht gesperrten).
- Konstanten: `START_SEATS = 8`, `MAX_SQUAD = 6`, `CREW_SCENE`, `BATTLE_SCENE`, `ROSTER_SCENE`.

**Verwundung (`Injury`, Regeln `docs/Skillsystem.md` 8a)**
- Stufen `""` (unverletzt), `angeschlagen` (darf mit, Malus −10), `kampfunfaehig`, `schwer` (beide gesperrt); `from_result(r)`, `combine(...)`, `is_locked(stage)`, `name(stage)`, `DAYS`, `CRIT_DAYS`, `LIGHT_MALUS`.
- `Combatant.from_character()` setzt bei „angeschlagen“ `malus = −10` (Datei des Bodenkampfs, nur diese Funktion).

**Ergebnis aus dem Kampf (`MissionResult`)** – Format siehe Kopf von `core/mission_result.gd` (Felder `status.state` ok/ko/sterbend/tot, `worst_crit`, `dying`, `stabilized`, `died` vom Bodenkampf).

**Oberfläche**
- `CrewOverview.show_crew(crew, result)` (Aufleveln, 3D-Vorschau, Zustand und Resttage, „Entlassen“), `current()`, `seats`, Signale `next_battle`, `reset_crew`, `open_sheet`, `crew_changed`; `create_member` bleibt nur für alte Verbindungen (wird nicht gesendet). Knopftexte „Crew zurücksetzen“ und „Speichern & nächste Mission“ bleiben (der Hub sucht danach).
- `roster.tscn` (`RosterScreen`, „Zurück“ → `res://start.tscn`), `CrewPicker.open_pick(subtitle, seats)` + Signal `picked(chars)`, `CharacterEditor.open_for_roster()`, `FigurePreview`, `CrewWidgets`.
- `ui/modal.gd`: `closable`.

**Regeln in `Rules`** (wirken auf alle Figuren, auch Gegner): Gruppen „Entwicklung“ und „Psi-Listen“; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung; neue Psi-Liste: erster Rang doppelt, eine pro Levelphase (`next_rank_cost`, `rank_block`).

**In Dateien anderer Module geändert:** `view/battle.gd` (eine Zeile: Kampf mit `Campaign.squad()`), `core/combatant.gd` (`from_character`: Malus für Angeschlagene).

## Stand (16.10.2026)

- Gültig ist die Klärung in `docs/Planung_Roster_Verwundung.md`, Abschnitt D (ersetzt frühere Einträge dieser Datei). Mockup „Frontire Roster“ ist vom Nutzer freigegeben und gebaut.
- Umgesetzt: Anheuern aus den Crewquartieren entfernt (nur noch im Hafen über den Hub), Entlassene „im Hafen“ mit Fortschritt (gespeichert), Trupp gespeichert, Verwundung aus dem `MissionResult` (Stufen, Tage, Malus, Tote), `pass_days`, Kandidatenliste mit Sperr-Status für die Truppwahl (auch Schnellkampf), Anzeige von Zustand, Resttagen und „sterbend/stabilisiert“ in der Charakterübersicht.
- Entscheidungen des Nutzers (16.10.): Kritischer C–E im Stehen = angeschlagen + Zuschlag; stabilisiert = schwer verwundet; angeschlagen = Malus −10; erneut verwundet = schlimmere Stufe, Tage addiert. Annahme: Die Stufe bleibt bis zum letzten Resttag, danach unverletzt.
- **Für den Hub:** Anheuern auf der Brücke im Hafen mit `Campaign.hire()` (Roster-Einträge und `Campaign.harbor()`), Krankenstation mit `Campaign.patients()` und je Tag `Campaign.pass_days(1, bonus)`; beim Reisen/Warten ohne Krankenstation `pass_days(n)`. Arzt-Sperre über `blocked_ids` in `candidates()`. Einsatzbericht: Gefallene stehen in `Campaign.last_fallen` (sie sind nach `finish_mission` nicht mehr in `crew()`).
- **Für den Bodenkampf:** Truppwahl im Briefing mit `Campaign.candidates(quick, blocked_ids)` und `suggested_squad()`; Ergebnis `Campaign.set_squad(chars)` bzw. im Schnellkampf `Campaign.quick_squad = chars`. `hub_report()` in `battle.gd` sollte `Campaign.last_fallen` mit aufnehmen.

## Aufträge vom Koordinator

- (16.10.2026) Klärung D, Verwundung auswerten, Kandidaten für die Truppwahl → erledigt (siehe Stand).
