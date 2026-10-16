# Zusammenführung der Module – Verlauf und offene Punkte

Stand: 16.10.2026. Ältere Einträge (Verlauf bis 16.10.2026, erledigte Punkte, alte offene Entscheidungen): `docs/module/archiv/Zusammenfuehrung_bis_2026-10-16.md`.

## Arbeitsweise mit Branches

- **`main`** ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat (`docs/module/koordination.md`). Jedes Modul arbeitet auf seinem eigenen Branch und meldet einen fertigen Zwischenstand; der Koordinator führt nur konfliktfreie Branches mit grünen Tests zusammen.
- Danach holt jeder Modul-Chat `main` in seinen Branch (`git merge origin/main`), damit alle mit dem gleichen Stand weiterarbeiten.

| Branch | Modul | Stand |
|---|---|---|
| `claude/confident-edison-6mxzke` | Bodenkampf | in `main` (`8b5a91f`) |
| `claude/elegant-gauss-hq5bus` | Charakter-Modul und Charakter-Editor | in `main` (`2c8a590`) |
| `claude/happy-lamport-u4fvya` | Hub (Startmenü, Schiff, Sternenkarte, Spielstände) | in `main` (`bd2f56f`); Teil 2 Raumkampf wartet auf Raumkampf-Code |
| `claude/raumkampf-modul` | Raumkampf (Mutterschiff, Jäger) | in `main` (`8a0597f`, Schnittstelle fest); Regelkern als Nächstes |

## Verlauf

| Datum | Commit in `main` | Branch (Commit) | Ergebnis |
|---|---|---|---|
| 16.10.2026 | `4d89c1c` | Hub `claude/happy-lamport-u4fvya` (`bd2f56f`) | ohne Konflikte; es fehlte nur der Doku-Commit `9bd524f`, Code identisch mit dem getesteten Stand, keine eigenen Tests (Testregel). Anbindung Raumkampf Teil 1: `ShipArms`, Waffenslots, Posten, Schiffsmunition, Systemschäden, Reparatur, Handel „Schiff“, `ShipUpgrades` +4 Bereiche. Tests laut Hub: `test_rules`, `test_hub`, `test_sim -- 10`, `--autotest-hub` OK. |
| 16.10.2026 | `65bc896` | Raumkampf `claude/raumkampf-modul` (`8a0597f`) | ohne Konflikte, enthielt `main`, nur Doku, keine Tests. Schnittstelle fest (`docs/module/raumkampf.md` „Schnittstellen“, Entscheidungen `docs/Planung_Raumkampf.md` 1a): `SpaceBattle.start(tree, setup)`, `take_result()`, `SpaceSetup.quick()`, `ShipWeapons`. Hub kann mit „Anbindung Raumkampf“ beginnen. |
| 16.10.2026 | `a73bdec` | Raumkampf `claude/raumkampf-modul` (`8bd0e3a`) | ohne Konflikte, enthielt `main`, nur Doku, keine Tests. Planung V1 (`docs/Planung_Raumkampf.md`, `docs/Raumkampf.md` angepasst, Mockup „Raumkampf Mockup“ bestätigt). Zuständigkeit: Raumkampf eigene Dateien + Einstieg, Hub alle Auslöser und `HubState`/`ShipUpgrades`/Handel (`docs/module/raumkampf.md` Auftrag 2, `hub.md`). |
| 16.10.2026 | `abac709` | Raumkampf `claude/raumkampf-modul` (`8bdb04b`) | ohne Konflikte, nur Doku, keine Tests nötig. Branchname in `docs/module/README.md` und `docs/module/raumkampf.md` eingetragen. |
| 16.10.2026 | `50b08f5` | Bodenkampf `claude/confident-edison-6mxzke` (`8b5a91f`) | ohne Konflikte, enthielt `main`; keine eigenen Tests (Testregel). Waffen-Reparatur im Kampf (`Combat.repair_targets/do_repair`, 50 % Aktivität, einmal je Stück und Kampf, Probe Mittel: Herausragend +10, Erfolg +5, Patzer −10; Grenze im Kampf **−5** statt −10 laut Entscheidung des Nutzers; auch KI). |

Neueste Zeile oben. Nach jeder Zusammenführung: Zeilen, die älter als die letzte Runde sind, ins Archiv verschieben.
