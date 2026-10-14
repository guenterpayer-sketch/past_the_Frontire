# Zusammenführung der Module – Verlauf und offene Punkte

Stand: 15.10.2026. Zuletzt zusammengeführt: Charakter `5c3a346` (Roster) als `f81e9fd`.

## Arbeitsweise mit Branches

- **`main`** ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat (`docs/module/koordination.md`). Jedes Modul arbeitet auf seinem eigenen Branch und meldet einen fertigen Zwischenstand; der Koordinator führt nur konfliktfreie Branches mit grünen Tests zusammen.
- Danach holt jeder Modul-Chat `main` in seinen Branch (`git merge origin/main`), damit alle mit dem gleichen Stand weiterarbeiten.
- Noch offen (nur in den GitHub-Einstellungen möglich): `main` als Standardbranch einstellen (Settings → Branches → Default branch). Bis dahin ist `claude/confident-edison-6mxzke` der Standardbranch.

| Branch | Modul | Stand |
|---|---|---|
| `claude/confident-edison-6mxzke` | Bodenkampf | in `main` (`381fb01`) |
| `claude/elegant-gauss-hq5bus` | Charakter-Modul und Charakter-Editor | in `main` (`5c3a346`, Roster); Klärung D aus `docs/Planung_Roster_Verwundung.md` noch offen |
| `claude/happy-lamport-u4fvya` | Hub (Startmenü, Schiff, Sternenkarte, Spielstände) | in `main` (`df91246`); muss `main` holen (Aufleveln, Bodenkampf `381fb01`, Änderung an `tests/autotest_hub.gd`) |

## Verlauf

| Datum | Commit in `main` | Branch (Commit) | Ergebnis |
|---|---|---|---|
| 14.10.2026 | `cf5ad7e` | Charakter `claude/elegant-gauss-hq5bus` (`73a73ed`) | ohne Konflikte; Ergebnis identisch mit dem getesteten Branch-Stand. Tests laut Modul-Chat: `test_rules` OK, `test_sim -- 30` 22 Siege / 8 Niederlagen / 0 hängengeblieben, `--autotest` und `--autotest-player` laufen durch. Koordinator: `test_rules` OK. |
| 15.10.2026 | `403b431` | Bodenkampf `claude/confident-edison-6mxzke` (`833875f`) | ohne Konflikte; nur `docs/module/bodenkampf.md` (Simulation zu den neuen TP/PP-Formeln, Entscheidung: Balancing bleibt). |
| 15.10.2026 | `012efdf` | Hub `claude/happy-lamport-u4fvya` (`77449d9`) | ohne Konflikte (der Hub hatte `main` mit dem Charakter-Modul schon eingeholt und die Konflikte im eigenen Branch gelöst); Ergebnis weicht vom getesteten Branch-Stand nur in `docs/module/bodenkampf.md` ab. Tests laut Modul-Chat: `test_rules`, `test_hub` OK, `test_sim -- 30` 22 Siege / 0 hängengeblieben, `--autotest`, `--autotest-player`, `--autotest-hub` laufen durch. Koordinator: `test_rules` und `test_hub` OK. |

| 15.10.2026 | `5d0bd94` | Hub `claude/happy-lamport-u4fvya` (`df91246`) | ohne Konflikte; Ergebnis identisch mit dem getesteten Branch-Stand. „Crew zurücksetzen“ im Schiff ausgeblendet, Schnellkampf aus dem Startmenü verbucht nichts und führt zurück ins Startmenü (`HubState.quick_battle`, Zweig in `Battle.finish_mission()`). Tests laut Modul-Chat: alle grün (`test_sim -- 30` 22 Siege / 0 hängengeblieben, Autotests inkl. `--autotest-hub`). Koordinator: `test_rules`, `test_hub` OK. |
| 15.10.2026 | `f7fe33a` | Charakter `claude/elegant-gauss-hq5bus` (`d375736`) | ohne Konflikte. Aufleveln in der Charakterübersicht (3D-Vorschau `ui/crew/figure_preview.gd`, Name/Kürzel/Farbe/Station/Aussehen, Psi-Kräfte), Regeln `docs/Skillsystem.md` 8. Schnittstellen unverändert, Erweiterungen: `Character.new_list`, `Rules.next_rank_cost/rank_block/is_psi_list`. Tests laut Modul-Chat mit Hub `77449d9` grün (inkl. `--autotest-hub`). Koordinator nach Zusammenführung mit Hub `df91246`: `test_rules`, `test_hub` OK; grafische Tests nicht selbst ausgeführt. |
| 15.10.2026 | `1dc3362` | Bodenkampf `claude/confident-edison-6mxzke` (`381fb01`) | ohne Konflikte (erste Probe mit `d483bf4`: Konflikt in `godot/README.md`, vom Bodenkampf-Chat gelöst); Ergebnis identisch mit dem getesteten Branch-Stand. Ergebnis-Banner (`ui/result_banner.gd`), Rückzug (`Combat.retreat()`, zählt als Niederlage), Rückfrage beim Abbrechen aus dem Schiff (`BattleUI.ask()`); Schnellkampf ohne Banner (Entscheidung Nutzer). Ändert `tests/autotest_hub.gd` (Hub). Tests laut Modul-Chat alle grün inkl. `--autotest-hub`. Koordinator: `test_rules`, `test_hub` OK. |
| 15.10.2026 | `f81e9fd` | Charakter `claude/elegant-gauss-hq5bus` (`5c3a346`) | ohne Konflikte; Ergebnis identisch mit dem getesteten Branch-Stand. Globaler Roster (`roster.tscn`, `user://roster.json`, `GlobalRoster`), Crew-Auswahl (`CrewPicker`, `Campaign.new_game`), Anheuern/Entlassen in der Charakterübersicht, Einsatztrupp (`Campaign.squad()`/`chosen_squad`); eine Zeile in `view/battle.gd`. Klärung D (Planung) noch nicht umgesetzt – auf Wunsch des Nutzers trotzdem zusammengeführt. Tests laut Modul-Chat alle grün; Koordinator: `test_rules`, `test_hub` OK. |

## Erledigte Punkte aus der ersten Probe (14.10.2026)

Die Brüche zwischen Charakter-Modul und Hub (doppelte Charakterübersicht, alte `Roster`-Speicherfunktionen, doppeltes Kampfende, `Campaign` nach dem Laden eines Spielstands, `ui/modal.gd`) hat der Hub-Chat in seinem Branch gelöst. Stand jetzt:

- **Ein Kampfende** in `view/battle.gd` (`Battle.finish_mission()`): `MissionResult.from_combat()` → `Campaign.finish_mission()`; aus dem Schiff mit Einsatzbericht (`HubState.game.finish_mission(hub_report(result))`) zurück ins Schiff, Schnellkampf nach `crew.tscn`. Keine eigene EP-Gutschrift im Kampf.
- Crewquartiere im Schiff nutzen `CrewOverview`, `CharacterEditor` und `SheetDialog` aus dem Charakter-Modul.
- Spielstände: `SaveSlots.load_slot()` ruft `Campaign.reload()`, `SaveSlots.save()` vorher `Campaign.save()`.
- Der Hub hat dafür Dateien des Bodenkampfs geändert: `view/battle.gd`, `ui/briefing_dialog.gd`, `ui/top_menu.gd`, `core/mission.gd`, `data/types/faction_data.gd`, `data/missions/*.tres` (Details in `docs/module/hub.md`).

## Offene Entscheidungen (für den Nutzer)

- **Rückzug im Schiffsbericht:** `MissionResult` liefert beim Rückzug `outcome = niederlage`; der Bericht zeigt „Niederlage (Rückzug)“. Ob der Hub eine eigene Anzeige dafür bekommt, ist offen.

- **Zustand nach dem Kampf:** Das `MissionResult` enthält schon bewusstlos/tot, TP, Blutung, verbrauchte Medikits und Munition, aber nichts davon wird ausgewertet (jeder Einsatz beginnt heil und voll ausgerüstet). → Entschieden am 15.10.2026: siehe `docs/Planung_Roster_Verwundung.md` (Verwundung statt Tod, Krankenstation in Spieltagen).
- **Nach dem ersten Spieltest (15.10.2026):** Roster und Crew-Auswahl, Verwundung statt Tod, Psi im Kampf, aktive Figur sichtbar – Entscheidungen und Aufträge in `docs/Planung_Roster_Verwundung.md` und den Moduldateien.
