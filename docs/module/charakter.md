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

**Waffenkammer (neu, 15.10.2026)**
- `ArmoryDialog` (`ui/crew/armory_dialog.gd`, erbt `Modal`): **Aufruf für den Hub** im Raum „Waffenkammer“:
  ```
  var armory := ArmoryDialog.new()   # einmal anlegen, z. B. neben crew/editor in hub_ui
  add_child(armory)
  armory.open_for(Campaign.crew(), index_der_gewählten_figur := 0)
  armory.done.connect(...)           # nach „Fertig“; Campaign.save() ist dann schon erfolgt
  ```
  Schließen per Klick daneben/Esc wie jedes `Modal` (dann **ohne** Speichern der Datei; die Änderungen bleiben aber an den `Character`-Objekten im Speicher – der nächste `Campaign.save()` schreibt sie).
- `Equipment` (`core/equipment.gd`): `weapons()` (ohne Psi), `armors()`, `weapon(ch, slot)`, `weapon_block/set_weapon(ch, slot, w)` (Platz 1 = `null` → Waffe 2 leer), `blocks_shield(w)`, `shield_block/set_shield(ch, on)`, `shield_bonus(ch)`, `damage_taken(armor)`.
- Regeln (Nutzer 15.10.2026): Waffe 1 Pflicht, Waffe 2 darf leer sein; keine Waffe doppelt; Psi-Waffen nicht wählbar; Schild nur mit einhändigen Waffen (Fäuste zählen nicht als zweihändig); eine zweihändige Waffe legt den Schild ab.
- **In Dateien des Bodenkampfs geändert (auf Anweisung des Nutzers):** `data/weapons/vibroklinge.tres` → `two_handed = false` (einhändig; wirkt auch auf die Haltung des 3D-Modells), `data/weapons/laserkarabiner.tres` → Fertigkeit `gewehre` statt `pistolen`. Folge: Ikko und Rhea (Laserkarabiner, keine Ränge in Gewehre) treffen damit deutlich schlechter (Pistolen +65/+40 → Gewehre −15); Nutzer: „so lassen“, umrüsten in der Waffenkammer.

**Regeln in `Rules`** (wirken auf alle Figuren, auch Gegner): Gruppen „Entwicklung“ und „Psi-Listen“; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung; neue Psi-Liste: erster Rang doppelt, eine pro Levelphase (`next_rank_cost`, `rank_block`).

**In Dateien anderer Module geändert:** `view/battle.gd` (eine Zeile: Kampf mit `Campaign.squad()`), `core/combatant.gd` (`from_character`: Malus für Angeschlagene).

## Stand (15.10.2026)

- Waffenkammer gebaut nach Mockup „Frontire Waffenkammer“ (vom Nutzer bestätigt): `ArmoryDialog` + `Equipment`, Tests in `test_rules.gd` (`_test_equipment`). Der Hub muss nur noch den Raum „Waffenkammer“ anbinden (Aufruf oben).
- Davor (16.10.): Klärung D, Verwundung, Kandidaten für die Truppwahl – in `main`.

## Aufträge vom Koordinator

- (16.10.2026) Klärung D, Verwundung auswerten, Kandidaten für die Truppwahl → erledigt (siehe Stand).

## Aufträge vom Koordinator (16.10.2026, nach Merge `4e282e1`)

In `main`, nichts offen. `main` holen (Hub `479e767` ist drin). Schnittstellen und Knopftexte der Charakterübersicht nur nach Ankündigung ändern (Hub benennt/blendet über die Texte um). Auf Fragen von Hub (Krankenstation, Anheuern) und Bodenkampf (Truppwahl) antworten; nächste Aufgabe kommt vom Nutzer.

## Aufträge vom Koordinator (15.10.2026): Waffenkammer

Grundlage: `docs/Planung_Waffenkammer.md`. Du baust den **Ausrüstungsdialog** (Waffe 1/2, Rüstung, Schild ändern; Medikits/Munition nur anzeigen; Werte aus `WeaponData`/`ArmorData` inkl. Bonus der Figur in der Waffenfertigkeit). Bestand unbegrenzt, Änderung gilt für die Figur im Spielstand. **Erst Mockup**, vom Nutzer bestätigen lassen, dann bauen. Der Hub öffnet den Dialog aus dem Raum „Waffenkammer“ – Aufruf (Funktion/Signal) in den Schnittstellen vermerken.
- (15.10.2026) Waffenkammer: Ausrüstungsdialog → gebaut (siehe Stand); Aufruf für den Hub unter „Schnittstellen“.
