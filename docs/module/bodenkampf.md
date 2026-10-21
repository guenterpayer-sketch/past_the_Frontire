# Modul Bodenkampf

- **Branch:** `claude/confident-edison-6mxzke`
- **Zuständig für:** `godot/main.tscn`, `godot/view/` (außer Hub-Szenen), `godot/core/combat*.gd`, `combatant.gd`, `battle_map.gd`, `map_generator.gd`, `mission.gd`, `tables.gd`, `dice.gd`, `hex.gd`, `godot/ui/` des Kampfes (`battle_ui.gd`, `action_panel.gd`, `unit_card.gd`, `top_menu.gd`, `info_box.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, `briefing_dialog.gd`), `godot/data/` für Waffen, Rüstungen, Tabellen, Gegner, Fraktionen.
> Erledigte Aufträge und alter Stand bis 16.10.2026: `docs/module/archiv/bodenkampf_bis_2026-10-16.md` (nur bei Bedarf lesen).


## Schnittstellen

- **Eingang:** im Briefing gewählter Trupp als Kopien (`Roster.build_crew(Battle.squad)`), optional eine fertige `Mission` (aus der Sternenkarte des Hubs).
- **Truppwahl (seit 16.10.2026, Auftrag Truppwahl):** Kandidaten `Campaign.candidates(HubState.quick_battle, HubState.blocked_ids())` (Charakter/Hub), Vorbelegung `Campaign.suggested_squad()`; Ergebnis beim Schließen des Briefings → `Campaign.set_squad()` (im Spiel, gespeichert) bzw. `Campaign.quick_squad` (Schnellkampf). Schnellkampf: Kandidaten einmal je Szene geholt, Auswahl bleibt bei „Andere Mission“ erhalten. `Campaign.chosen_squad`/`squad()` liest der Bodenkampf nicht mehr direkt. Neu in `Battle`: `candidates`, `squad`, `_pick_squad()`, `_on_squad()` (anderer Trupp → Runde 0 mit derselben Karte neu); `BriefingDialog.show_mission(m, cands, selected)`, Signal `accepted(squad)`, `quick`, `selection()`, `toggle()`. `hub_report()` nimmt `Campaign.last_fallen` auf.
- **Munition (seit 15.10.2026, mit dem Hub abzustimmen):** Eingang Schiffsvorrat `HubState.game.ammo = {Art: Schuss}` (Arten `Ammo.TYPES`: `energie`, `projektil`, `raketen`; `Battle.ammo_stock()` liest ihn, fehlt er oder Schnellkampf → alles voll). Ausgang `MissionResult` neu `ammo_used = {Art: Schuss}` (ganze Crew); der Hub zieht ihn vom Vorrat ab. Neue Waffenwerte (Ausrüstungs-Editor): `WeaponData.shots` (Schuss pro Angriff, Feuerstoß), `ammo_type`; `ammo_total` = Obergrenze der Mitnahme (0 = nur 3 Magazine). Regeln in `core/ammo.gd` (`carry`, `plan`, `apply`, `used`, `burst_bonus`). MG: `ob_bonus` 15 → `shots` 3 (gleicher Bonus).
- **Waffenmodelle und Klänge (seit 16.10.2026):** Katalog `WeaponModels` (`all()`, `find()`, `apply()`), Klangliste `WeaponData.SOUNDS`, Waffenwert `sound_id`; Klangdateien in `audio/sfx/`.
- **Ausgang:** `MissionResult.from_combat()` → `Campaign.finish_mission()` → Szene `crew.tscn`. `ui/end_dialog.gd` und `Roster.load_progress()/save_progress()` gibt es nicht mehr.
- **Rückzug (seit 16.10.2026):** `MissionResult.retreated: bool` – true nur, wenn sich die Crew zurückgezogen hat (`Combat.retreated`); `outcome` bleibt dabei `&"niederlage"`. Bei Sieg und Niederlage ohne Rückzug false.
- **Seit 16.10.2026 (Verwundung statt Tod, Auftrag 3) – Änderung am `MissionResult` (Datei des Charakter-Moduls, vom Bodenkampf erweitert):**
  - `status.state` kann jetzt `"ok"`, `"ko"`, **`"sterbend"`** oder `"tot"` sein (vorher `"ok"/"ko"/"tot"`; `"tot"` kommt nur noch durch den Todeswurf vor). **Achtung Charakter-Modul:** `crew_overview.gd` kennt `"sterbend"` noch nicht (zeigt dann nichts an).
  - Neu je Figur: `worst_crit` (`""` oder `"A"`–`"E"`, schwerster erlittener Kritischer), `dying` (bool: am Ende sterbend und nicht stabilisiert), `stabilized` (bool: sterbend, per Erster Hilfe stabilisiert → laut Nutzer „kampfunfähig“ statt „schwer verwundet“), `died` (bool: tot durch den Todeswurf).
  - `Combatant`: `State { OK, KO, DYING, DEAD }`, `stabilized`, `worst_crit`, `is_down()`; `Combat.DEATH_CHANCE = 10`.
- **Seit 16.10.2026 (Psi im Kampf, Auftrag 2) – Schnittstelle zum Charakter-Modul:** Der Kampf liest die Psi-Kräfte nur aus den **Listen-Rängen** des `Character` (`PsiLists.LISTS`, Rang = höchste Stufe; `core/psi_combat.gd` legt die Kampfwirkung je `"Liste/Stufe"` fest). **Waffen mit `psi = true` (alte Psi-Stoß-Waffe) werden im Kampf ignoriert** → **Auftrag an Charakter:** alte Spielstände umwandeln (Psi-Stoß-Waffe → Listen-Ränge; Entscheidung des Nutzers: „Charakter-Modul regelt“). Startcrew-Daten geändert (Datei des Charakter-Moduls, Entscheidung des Nutzers): `data/units/crew/nyx.tres` ohne Psi-Stoß-Waffe, dafür `lAngriff` 4 und `lSchutz` 4; Gegner `hexer.tres`: `lAngriff` 4, `lSchutz` 2. `tests/test_rules.gd` `_test_leveling` nutzt jetzt `lWahrnehmung` als neue Liste (Nyx hat Schutz). Texte in `PsiLists`/`Skillsystem.md` für „Am Leben halten“ (stabilisiert Sterbende) und „Gedanken orten“ (hebt Deckung auf) sollte das Charakter-Modul angleichen.
  - Neu: `WeaponData.power`, `power_effect` (Laufzeit-Felder für Psi-Angriffskräfte); `Combatant.powers`, `buffs`, `disarmed`; `Combat.power_targets()`, `can_power()`, `do_power()`; `PlayerController.choose_power()`, `context_powers()`; `ui/context_menu.gd`. `Combat.psi_shield_targets()`/`do_psi_shield()` entfernt (Psi-Schild ist jetzt `lSchutz/2`).

## Stand

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/bodenkampf_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- **Fertig (21.10.2026, Klick auf verdeckten Gegner):** Ein Klick auf einen Gegner unter dem Infokasten oben rechts griff nicht an. Der Kasten fing alle Klicks ab (`MOUSE_FILTER_STOP`) und zählte in `BattleUI.covers()` als Sperre. Jetzt lässt er Klicks zur Karte durch, nur der Knopf „Ausführen“ fängt sie; `covers()` zählt ihn nicht mehr. Geprüft: temporärer Klick-Test auf einen verdeckten Gegner löste einen Angriff aus (Test danach entfernt). Seitenleiste, Menü und Würfel bleiben Sperren. Keine Schnittstellenänderung.

## Aufträge vom Koordinator

- Keine offenen Aufträge. Nächste Aufgabe kommt vom Nutzer.
