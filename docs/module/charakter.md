# Modul Charakter (Charakter-Modul und Charakter-Editor)

- **Branch:** `claude/elegant-gauss-hq5bus`
- **Zuständig für:** `godot/core/character.gd`, `roster.gd`, `global_roster.gd`, `campaign.gd`, `mission_result.gd` (Format), `injury.gd`, `creation.gd`, `psi_lists.gd`, `rules.gd` (Steigerung), `godot/crew.tscn`, `godot/roster.tscn`, `godot/ui/crew/`, `godot/ui/sheet_dialog.gd`, `godot/data/units/crew*`.

## Schnittstellen
> Erledigte Aufträge und alter Stand bis 16.10.2026: `docs/module/archiv/charakter_bis_2026-10-16.md` (nur bei Bedarf lesen).


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
- `ui/modal.gd`: `closable`, `title_bar` (Titelzeile; Knöpfe rechts anhängen). `CrewWidgets.burger(host)`: Burgermenü mit „Enzyklopädie“ (`Encyclopedia.show_on(host)`), `CrewWidgets.close_encyclopedia(host)` für Esc.

**Übersicht Psi-Listen (neu, 15.10.2026)** – gemeinsamer Baustein, auch für den Bodenkampf
- `PsiListView` (`ui/crew/psi_list_view.gd`, erbt `Modal`): einmal anlegen und einhängen, dann
  ```
  var psi := PsiListView.new()
  add_child(psi)
  psi.open_for(figur, &"lSchutz")   # figur: Character oder Combatant (gelesen: name, skills, attrs, max_pp) oder null = nur die Listen;
                                    # Liste leer = erste gelernte Liste
  ```
  Schließen per Klick daneben oder `close()`; Esc muss der Aufrufer weiterreichen (wie bei jedem `Modal`).
- Texte für Zeilen: `PsiListView.next_hint(ch, list)` („Rang 5: keine neue Kraft · Rang 6: Psi-Lanze (…)“), `PsiListView.preview_hint(ch, list)` (Editor), `PsiListView.chip(text, color)`.
- Daten in `PsiLists`: `LISTS` (Wirkungstexte wie im Bodenkampf, ohne Ziel), `kind(list, stufe)` → `ATTACK`/`SUPPORT`/`OFF`, `target(list, stufe)` (Ziel, bei Angriffen Reichweite aus `PsiCombat.weapon(k).max_range_m()`), `next_power(ch, list)`, `power_at(list, stufe)`.
- Geändert in `core/psi_lists.gd`: die Wirkungstexte enthalten kein Ziel mehr (steht in `target()`). Die Seitenleiste des Bodenkampfs zeigt `p[2]` im Tooltip der Angriffskräfte; dort steht jetzt z. B. „Psi-Nadel: Schaden nach Tabelle Psi, Angriff −20“.

**Waffenkammer (neu, 15.10.2026)**
- `ArmoryDialog` (`ui/crew/armory_dialog.gd`, erbt `Modal`): **Aufruf für den Hub** im Raum „Waffenkammer“:
  ```
  var armory := ArmoryDialog.new()   # einmal anlegen, z. B. neben crew/editor in hub_ui
  add_child(armory)
  armory.open_for(Campaign.crew(), index_der_gewählten_figur := 0)
  armory.done.connect(...)           # nach „Fertig“; Campaign.save() ist dann schon erfolgt
  ```
  Schließen per Klick daneben/Esc wie jedes `Modal` (dann **ohne** Speichern der Datei; die Änderungen bleiben aber an den `Character`-Objekten im Speicher – der nächste `Campaign.save()` schreibt sie).
- `Equipment` (`core/equipment.gd`): `weapons(g = null)` (ohne Psi, dazu eigene aus `Gear.weapons()`; mit Spiel `g` auch die Elite-Waffen aus `data/weapons/elite/`), `armors(g = null)` (dazu `Gear.armors()`; mit Spiel auch `data/armor/elite/`), `label(r)` (Name, „(frei)“ bei `Gear.is_free`), `weapon(ch, slot)`, `weapon_block/set_weapon(ch, slot, w)` (Platz 1 = `null` → Waffe 2 leer), `blocks_shield(w)`, `shield_block/set_shield(ch, on, g)`, `shield_bonus(ch)`, `damage_taken(armor)`. Lager (`g = HubState.game`, null = unbegrenzt): `set_weapon(ch, slot, w, g)`, `set_armor(ch, a, g)`, `set_medkits(ch, n, g)` (0 … `MAX_MEDKITS` = 3), `restore(ch, snap, g)`, `in_stock(g, r)`, `listed(g, r, worn)`, `is_free_item(r)`, `SHIELD` (Lager-Schlüssel des Schilds).
- Regeln (Nutzer 15.10.2026): Waffe 1 Pflicht, Waffe 2 darf leer sein; keine Waffe doppelt; Psi-Waffen nicht wählbar; Schild nur mit einhändigen Waffen (Fäuste zählen nicht als zweihändig); eine zweihändige Waffe legt den Schild ab.
- **In Dateien des Bodenkampfs geändert (auf Anweisung des Nutzers):** `data/weapons/vibroklinge.tres` → `two_handed = false` (einhändig; wirkt auch auf die Haltung des 3D-Modells), `data/weapons/laserkarabiner.tres` → Fertigkeit `gewehre` statt `pistolen`. Folge: Ikko und Rhea (Laserkarabiner, keine Ränge in Gewehre) treffen damit deutlich schlechter (Pistolen +65/+40 → Gewehre −15); Nutzer: „so lassen“, umrüsten in der Waffenkammer.

**Regeln in `Rules`** (wirken auf alle Figuren, auch Gegner): Gruppen „Entwicklung“ und „Psi-Listen“; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung; neue Psi-Liste: erster Rang doppelt, eine pro Levelphase (`next_rank_cost`, `rank_block`).

**In Dateien anderer Module geändert:** `view/battle.gd` (eine Zeile: Kampf mit `Campaign.squad()`), `core/combatant.gd` (`from_character`: Malus für Angeschlagene).

## Stand

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/charakter_bis_2026-10-19.md`; Funktionen: `godot/README.md`.

## Aufträge vom Koordinator

### Auftrag (28.10.2026): Elite-Ausrüstung lässt sich nicht ausrüsten – erledigt (Branch, wartet auf Zusammenführung)

Ergebnis: Ursache wie vermutet (`Equipment.weapons()/armors()` lasen die Unterordner `elite/` nicht; der Reiter „Lager“ zeigte Elite-Stücke schon). Jetzt `Equipment.weapons(g)`/`armors(g)` mit Elite-Ordnern, nur mit Spiel (ohne Spielstand ist der Bestand unbegrenzt, dort keine Elite). Angezeigt wird weiter nur, was im Lager liegt oder getragen wird; Schaden bleibt beim Anlegen/Ablegen erhalten. Sortiment unverändert (`Stock.goods` filtert `is_elite`). Nebenbei: Rüstungsliste zeigt bei unbrauchbaren Stücken „wie keine“ statt eines Minuswerts (wie der Reiter „Lager“). Test in `test_hub.gd` (`_test_elite`).

Fehler (Nutzer, Spiel): Im Lager liegt „Sturmgewehr (Boss)“, in der Waffenkammer erscheint es nicht zur Auswahl.
Vermutung des Koordinators aus dem Code (nicht im Spiel geprüft): Die Waffenkammer listet nur `Equipment.weapons()` / `Equipment.armors()`. Diese lesen die Ordner `res://data/weapons` bzw. `res://data/armor` ohne Unterordner (`GameData.weapons()`, `list_directory`), die Elite-Stücke liegen aber in `data/weapons/elite/` und `data/armor/elite/` (Bodenkampf, Balancing-Paket 24.10.2026).
1. Ursache bestätigen und beheben: Elite-Waffen und -Rüstungen, die im Lager liegen, müssen ausrüstbar sein (mit Schaden −20/−30 wie geliefert). Im Händler-Sortiment weiter **nie** (Hub, `Stock.is_elite`).
2. Prüfen, ob auch andere Listen (Editor, Enzyklopädie, Charakterbogen) Elite-Stücke brauchen oder bewusst weglassen; dem Nutzer berichten.
3. Tests nach CLAUDE.md (test_sim nicht nötig), Fertigmeldung.
