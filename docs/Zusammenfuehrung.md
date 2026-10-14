# Zusammenführung der Module – Verlauf und offene Punkte

Stand: 15.10.2026. Alle drei Modul-Branches sind in `main` (`012efdf`).

## Arbeitsweise mit Branches

- **`main`** ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat (`docs/module/koordination.md`). Jedes Modul arbeitet auf seinem eigenen Branch und meldet einen fertigen Zwischenstand; der Koordinator führt nur konfliktfreie Branches mit grünen Tests zusammen.
- Danach holt jeder Modul-Chat `main` in seinen Branch (`git merge origin/main`), damit alle mit dem gleichen Stand weiterarbeiten.
- Noch offen (nur in den GitHub-Einstellungen möglich): `main` als Standardbranch einstellen (Settings → Branches → Default branch). Bis dahin ist `claude/confident-edison-6mxzke` der Standardbranch.

| Branch | Modul | Stand |
|---|---|---|
| `claude/confident-edison-6mxzke` | Bodenkampf | in `main` (`833875f`); muss `main` holen (Hub fehlt) |
| `claude/elegant-gauss-hq5bus` | Charakter-Modul und Charakter-Editor | in `main` (`73a73ed`); muss `main` holen (Hub fehlt) |
| `claude/happy-lamport-u4fvya` | Hub (Startmenü, Schiff, Sternenkarte, Spielstände) | in `main` (`77449d9`); muss `main` holen (Moduldatei Bodenkampf fehlt) |

## Verlauf

| Datum | Commit in `main` | Branch (Commit) | Ergebnis |
|---|---|---|---|
| 14.10.2026 | `cf5ad7e` | Charakter `claude/elegant-gauss-hq5bus` (`73a73ed`) | ohne Konflikte; Ergebnis identisch mit dem getesteten Branch-Stand. Tests laut Modul-Chat: `test_rules` OK, `test_sim -- 30` 22 Siege / 8 Niederlagen / 0 hängengeblieben, `--autotest` und `--autotest-player` laufen durch. Koordinator: `test_rules` OK. |
| 15.10.2026 | `403b431` | Bodenkampf `claude/confident-edison-6mxzke` (`833875f`) | ohne Konflikte; nur `docs/module/bodenkampf.md` (Simulation zu den neuen TP/PP-Formeln, Entscheidung: Balancing bleibt). |
| 15.10.2026 | `012efdf` | Hub `claude/happy-lamport-u4fvya` (`77449d9`) | ohne Konflikte (der Hub hatte `main` mit dem Charakter-Modul schon eingeholt und die Konflikte im eigenen Branch gelöst); Ergebnis weicht vom getesteten Branch-Stand nur in `docs/module/bodenkampf.md` ab. Tests laut Modul-Chat: `test_rules`, `test_hub` OK, `test_sim -- 30` 22 Siege / 0 hängengeblieben, `--autotest`, `--autotest-player`, `--autotest-hub` laufen durch. Koordinator: `test_rules` und `test_hub` OK. |

## Erledigte Punkte aus der ersten Probe (14.10.2026)

Die Brüche zwischen Charakter-Modul und Hub (doppelte Charakterübersicht, alte `Roster`-Speicherfunktionen, doppeltes Kampfende, `Campaign` nach dem Laden eines Spielstands, `ui/modal.gd`) hat der Hub-Chat in seinem Branch gelöst. Stand jetzt:

- **Ein Kampfende** in `view/battle.gd` (`Battle.finish_mission()`): `MissionResult.from_combat()` → `Campaign.finish_mission()`; aus dem Schiff mit Einsatzbericht (`HubState.game.finish_mission(hub_report(result))`) zurück ins Schiff, Schnellkampf nach `crew.tscn`. Keine eigene EP-Gutschrift im Kampf.
- Crewquartiere im Schiff nutzen `CrewOverview`, `CharacterEditor` und `SheetDialog` aus dem Charakter-Modul.
- Spielstände: `SaveSlots.load_slot()` ruft `Campaign.reload()`, `SaveSlots.save()` vorher `Campaign.save()`.
- Der Hub hat dafür Dateien des Bodenkampfs geändert: `view/battle.gd`, `ui/briefing_dialog.gd`, `ui/top_menu.gd`, `core/mission.gd`, `data/types/faction_data.gd`, `data/missions/*.tres` (Details in `docs/module/hub.md`).

## Offene Entscheidungen (für den Nutzer)

- **Zustand nach dem Kampf:** Das `MissionResult` enthält schon bewusstlos/tot, TP, Blutung, verbrauchte Medikits und Munition, aber nichts davon wird ausgewertet (jeder Einsatz beginnt heil und voll ausgerüstet). Soll die Krankenstation im Schiff das übernehmen, und was passiert bei Tod?
