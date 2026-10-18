# Zusammenführung der Module – Verlauf und offene Punkte

Stand: 16.10.2026. Ältere Einträge (Verlauf bis 16.10.2026, erledigte Punkte, alte offene Entscheidungen): `docs/module/archiv/Zusammenfuehrung_bis_2026-10-16.md`.

## Arbeitsweise mit Branches

- **`main`** ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat (`docs/module/koordination.md`). Jedes Modul arbeitet auf seinem eigenen Branch und meldet einen fertigen Zwischenstand; der Koordinator führt nur konfliktfreie Branches mit grünen Tests zusammen.
- Danach holt jeder Modul-Chat `main` in seinen Branch (`git merge origin/main`), damit alle mit dem gleichen Stand weiterarbeiten.

| Branch | Modul | Stand |
|---|---|---|
| `claude/confident-edison-6mxzke` | Bodenkampf | in `main` (`0736fda`); Auftrag Kampfkarten läuft |
| `claude/elegant-gauss-hq5bus` | Charakter-Modul und Charakter-Editor | in `main` (`2c8a590`) |
| `claude/happy-lamport-u4fvya` | Hub (Startmenü, Schiff, Sternenkarte, Spielstände) | in `main` (`4b16e4e`), nichts offen |
| `claude/raumkampf-modul` | Raumkampf (Mutterschiff, Jäger) | in `main` (`fcdbeba`), nichts offen |

## Verlauf

| Datum | Commit in `main` | Branch (Commit) | Ergebnis |
|---|---|---|---|
| 18.10.2026 | `ac7b351` | Hub `claude/happy-lamport-u4fvya` (`4b16e4e`) | ohne Konflikte; es fehlte nur ein Doku-Commit, Code identisch mit dem getesteten Stand, keine eigenen Tests. Crew-Reparatur des Schiffs als Arbeit wie Handwerk (kein Tag sofort, Figur wählbar, eine Arbeit je Figur). |
| 18.10.2026 | `7d03a47` | Bodenkampf `claude/confident-edison-6mxzke` (`0736fda`) | ohne Konflikte, enthielt `main`; keine eigenen Tests (Testregel). Zwischenstand: Steuerung Tab (Aufstellung Figur wechseln, Kampf Zug beenden), F/Shift+F Ziele durchschalten, Leertaste angreifen. Klärung Kampfkarten Runde 1 in `bodenkampf.md`. |
| 17.10.2026 | `fa52302` | Raumkampf `claude/raumkampf-modul` (`fcdbeba`) | ohne Konflikte, enthielt `main`; keine eigenen Tests (Testregel; laut Modul `test_space`, `test_rules`, `test_hub`, `test_sim -- 10` OK). Zahlen per Simulation (`tests/sim_space.gd`): Siege 87–91/67–70/47–49 %, 8–11 Runden. Waffenpreise geändert (Hub liest sie aus `ShipWeapons`). Gegnervorlagen als Ressourcen `data/ships/`; `SpaceTemplates.SHIPS`/`FACTIONS` entfernt (kein anderes Modul nutzte sie, geprüft). |
| 17.10.2026 | `f155ff3` | Hub `claude/happy-lamport-u4fvya` (`2876f93`) | ohne Konflikte, enthielt `main`; keine eigenen Tests (Testregel). Raumkampf im Spiel (Teil 2): Feindkontakt, Auftragsarten Blockade/Abfangen/Eskorte, Auswertung `finish_space`, Notfall, Abwehr beim Entern. Keine Änderung an Raumkampf-Dateien. Szenenwechsel Schiff ↔ `space.tscn` vom Nutzer im Spiel getestet: funktioniert. |
| 16.10.2026 | `d56de65` | Hub `claude/happy-lamport-u4fvya` (`5772000`) mit Raumkampf `f0334fd` | Konflikt nur in `docs/module/hub.md`, vom Koordinator gelöst. Raumkampf-Modul (Regelkern, `space.tscn`) und Hub-Anbindung (ShipArms liest `ShipWeapons`, Slots 0–5, Technik 2/3, selbst entern, „Schnellkampf im All“). Koordinator: `test_rules`, `test_hub`, `test_space` OK, `test_sim -- 10` 6 Siege / 0 hängengeblieben. |
| 16.10.2026 | `3d633b0` | Hub `claude/happy-lamport-u4fvya` (`0bb6c64`) | Konflikt nur in `docs/module/hub.md` (Kürzung vs. Nachträge), vom Koordinator gelöst (Nachträge ins Archiv, kurz unter „Stand“; Nutzer-Entscheidung). Branch enthielt `main` nicht: Koordinator `test_rules`, `test_hub` OK. Startmenü-Block links oben, einheitliche Ergebnisfarben, Erfahrung je Figur. |
| 16.10.2026 | `ba8e62a` | Bodenkampf `claude/confident-edison-6mxzke` (`2bd5ced`) | ohne Konflikte, enthielt `main`; keine eigenen Tests (Testregel). 3 `.import`-Dateien so, wie der Editor sie schreibt (VRAM, `detect_3d` aus), damit GitHub Desktop sie nicht ständig als geändert zeigt. Prüfung unter Windows durch den Nutzer offen. |
| 16.10.2026 | `147fa3a` | Hub `claude/happy-lamport-u4fvya` (`6dd6178`) | ohne Konflikte, enthielt `main`; keine eigenen Regeltests (Testregel). Raumhafen in eigenen Fenstern (Anzeigefehler: Raumhafen-Spalte schnitt rechts ab), Werft mit Reitern, Maschinenraum nur Crew-Arbeit. Koordinator: `--autotest-hub` durchgelaufen, Screenshots Sternenkarte/Schiffshändler/Werft angesehen, nichts abgeschnitten. Probe Raumkampf `93b12b0` + `main`: `test_rules`, `test_space` OK, `test_hub` 4 Fehler → nicht zusammengeführt. |
| 16.10.2026 | `4d89c1c` | Hub `claude/happy-lamport-u4fvya` (`bd2f56f`) | ohne Konflikte; es fehlte nur der Doku-Commit `9bd524f`, Code identisch mit dem getesteten Stand, keine eigenen Tests (Testregel). Anbindung Raumkampf Teil 1: `ShipArms`, Waffenslots, Posten, Schiffsmunition, Systemschäden, Reparatur, Handel „Schiff“, `ShipUpgrades` +4 Bereiche. Tests laut Hub: `test_rules`, `test_hub`, `test_sim -- 10`, `--autotest-hub` OK. |
| 16.10.2026 | `65bc896` | Raumkampf `claude/raumkampf-modul` (`8a0597f`) | ohne Konflikte, enthielt `main`, nur Doku, keine Tests. Schnittstelle fest (`docs/module/raumkampf.md` „Schnittstellen“, Entscheidungen `docs/Planung_Raumkampf.md` 1a): `SpaceBattle.start(tree, setup)`, `take_result()`, `SpaceSetup.quick()`, `ShipWeapons`. Hub kann mit „Anbindung Raumkampf“ beginnen. |
| 16.10.2026 | `a73bdec` | Raumkampf `claude/raumkampf-modul` (`8bd0e3a`) | ohne Konflikte, enthielt `main`, nur Doku, keine Tests. Planung V1 (`docs/Planung_Raumkampf.md`, `docs/Raumkampf.md` angepasst, Mockup „Raumkampf Mockup“ bestätigt). Zuständigkeit: Raumkampf eigene Dateien + Einstieg, Hub alle Auslöser und `HubState`/`ShipUpgrades`/Handel (`docs/module/raumkampf.md` Auftrag 2, `hub.md`). |
| 16.10.2026 | `abac709` | Raumkampf `claude/raumkampf-modul` (`8bdb04b`) | ohne Konflikte, nur Doku, keine Tests nötig. Branchname in `docs/module/README.md` und `docs/module/raumkampf.md` eingetragen. |
| 16.10.2026 | `50b08f5` | Bodenkampf `claude/confident-edison-6mxzke` (`8b5a91f`) | ohne Konflikte, enthielt `main`; keine eigenen Tests (Testregel). Waffen-Reparatur im Kampf (`Combat.repair_targets/do_repair`, 50 % Aktivität, einmal je Stück und Kampf, Probe Mittel: Herausragend +10, Erfolg +5, Patzer −10; Grenze im Kampf **−5** statt −10 laut Entscheidung des Nutzers; auch KI). |

Neueste Zeile oben. Nach jeder Zusammenführung: Zeilen, die älter als die letzte Runde sind, ins Archiv verschieben.
