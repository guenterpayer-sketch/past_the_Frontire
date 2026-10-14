# Zusammenführung der Module – Stand und offene Punkte

Stand: 14.10.2026, nach der Zusammenführung des Charakter-Moduls (`cf5ad7e`).

## Verlauf

| Datum | Commit in `main` | Branch (Commit) | Ergebnis |
|---|---|---|---|
| 14.10.2026 | `cf5ad7e` | Charakter `claude/elegant-gauss-hq5bus` (`73a73ed`) | ohne Konflikte; Ergebnis identisch mit dem getesteten Branch-Stand. Tests laut Modul-Chat: `test_rules` OK, `test_sim -- 30` 22 Siege / 8 Niederlagen / 0 hängengeblieben, `--autotest` und `--autotest-player` laufen durch. Koordinator: `test_rules` OK; `test_sim` nicht selbst ausgeführt. |

Der Abschnitt „Ergebnis der Probe“ weiter unten stammt von der ersten Probe (Grundlage `9fde5fe`); die Probe mit dem neuen `main` ist darunter ergänzt.

## Arbeitsweise mit Branches

- **`main`** ist der gemeinsame Hauptbranch. Jedes Modul arbeitet auf seinem eigenen Branch und wird, wenn ein Zwischenstand fertig ist, in `main` zusammengeführt.
- Danach holt jeder Modul-Chat `main` in seinen Branch (`git merge origin/main`), damit alle mit dem gleichen Stand weiterarbeiten.
- Noch offen (nur in den GitHub-Einstellungen möglich): `main` als Standardbranch einstellen (Settings → Branches → Default branch). Bis dahin ist `claude/confident-edison-6mxzke` der Standardbranch.

| Branch | Modul | Stand |
|---|---|---|
| `claude/confident-edison-6mxzke` | Bodenkampf | 1 Commit hinter `main` (Charakter-Modul fehlt), nichts Eigenes neu |
| `claude/elegant-gauss-hq5bus` | Charakter-Modul und Charakter-Editor | in `main` (`73a73ed`) |
| `claude/happy-lamport-u4fvya` | Hub (Startmenü, Schiff, Sternenkarte, Spielstände) | `31144f9`, hat `main` vom Stand `6bcaeaa` geholt; Charakter-Modul fehlt noch, **Konflikte** (siehe unten) |

**Reihenfolge:** Charakter-Modul ist in `main`. Als Nächstes holt der Hub `main` und passt sich an (Aufträge in `docs/module/hub.md`).

## Ergebnis der Probe

- `main` + Charakter-Editor: **ohne Konflikte**.
- danach + Hub: **4 Dateien mit Konflikten**: `CLAUDE.md`, `godot/view/battle.gd`, `godot/ui/modal.gd`, `godot/ui/crew/crew_overview.gd` (im Hub-Branch noch `ui/end_dialog.gd`, im Charakter-Editor umbenannt).

**Probe vom 14.10.2026 mit `main` = `cf5ad7e` (Charakter-Modul enthalten) + Hub `31144f9`:** dieselben 4 Dateien mit Konflikten (`CLAUDE.md`, `godot/view/battle.gd`, `godot/ui/modal.gd`, `godot/ui/crew/crew_overview.gd`). Zusätzlich verweisen im Hub-Branch noch `ui/battle_ui.gd`, `ui/hub_ui.gd`, `view/hub.gd` und `view/battle.gd` auf `EndDialog` bzw. `Roster.load_progress()/save_progress()`, die es in `main` nicht mehr gibt. Punkt 4 unten ist vom Charakter-Modul gelöst: `Campaign.reload()`.

## Was nicht zusammenpasst (gefunden im Code)

1. **Charakterübersicht doppelt.** Der Charakter-Editor hat sie in die Szene `crew.tscn` verlegt (`CrewOverview.show_crew(crew: Array[Character], result)`, Klasse `EndDialog` gibt es dort nicht mehr). Der Hub nutzt für die Crewquartiere noch `EndDialog.new()` und `show_crew(crew: Array[Combatant])` mit Signal `crew_done` (`ui/hub_ui.gd`, `view/hub.gd`).
2. **Speichern über die alte Schnittstelle.** Der Hub ruft `Roster.save_progress()`, `Roster.load_progress()` und `Roster.build_team(…, progress)` auf. Im Charakter-Editor heißen sie `Roster.load_crew()`, `save_crew(Array[Character])`, `build_crew()`; die alten gibt es nicht mehr.
3. **Kampfende doppelt.** Charakter-Editor: Kampf → `MissionResult.from_combat()` → `Campaign.finish_mission()` (verbucht EP und 3 + Belohnung freie EP) → Szene `crew.tscn`. Hub: eigenes `finish_hub_mission()` in `battle.gd`, das freie EP selbst gutschreibt (`EndDialog.FREE_XP`) und ins Schiff zurückwechselt. Beides gleichzeitig würde EP doppelt gutschreiben.
4. **Crew im Speicher vs. Spielstände.** `Campaign` hält die Crew als statische Variable. Der Hub lädt Spielstände, indem er `user://crew.json` überschreibt (`core/save_slots.gd`). Ohne Neuladen von `Campaign` bliebe nach dem Laden eines Spielstands die alte Crew im Speicher.
5. **Zwei Spielstand-Halter.** `Campaign` (Crew, letztes Ergebnis) und `HubState.game` (Schiff, Sternenkarte, laufender Auftrag). Wer was speichert und wie ein Spielstand-Slot beides enthält, ist nicht festgelegt.
6. **Kleinere Überschneidungen:** `ui/modal.gd` (beide fügen eine Variable hinzu: `closable` bzw. `max_size` – beide behalten), `CLAUDE.md` (beide ändern den Abschnitt „Stand“).

## Was der Kampf danach anders machen muss (Vorschlag)

- **Ein Kampfende** für alle Fälle: `MissionResult` erzeugen → `Campaign.finish_mission()` → Ziel je nach Start:
  - aus dem Schiff: zurück ins Schiff mit Einsatzbericht (Inhalt aus dem `MissionResult`), Steigern in den Crewquartieren;
  - Schnellkampf aus dem Startmenü: in die Szene `crew.tscn`.
- `finish_hub_mission()` rechnet keine EP mehr selbst; `EndDialog.FREE_XP` → `MissionResult.FREE_XP`.
- Mission aus der Sternenkarte (`new_battle(…, m)`, feste Fraktion) bleibt wie im Hub-Branch.
- „Neue Mission“/„Andere Mission“ wird im Schiffsmodus zu „Einsatz abbrechen“ (wie im Hub-Branch).
- Crewquartiere im Hub nutzen die `CrewOverview` aus dem Charakter-Modul (oder wechseln in `crew.tscn` und zurück).
- `Campaign` nach dem Laden eines Spielstands neu laden.
- Tests: `tests/autotest.gd` (geht im Charakter-Editor schon in `crew.tscn`) und `tests/autotest_hub.gd` müssen beide Wege abdecken.

## Offene Entscheidungen (für den Nutzer)

- **Zustand nach dem Kampf:** Das `MissionResult` enthält schon bewusstlos/tot, TP, Blutung, verbrauchte Medikits und Munition, aber nichts davon wird ausgewertet (jeder Einsatz beginnt heil und voll ausgerüstet). Soll die Krankenstation im Schiff das übernehmen, und was passiert bei Tod?
- ~~**Wer führt zusammen?**~~ Der Koordinations-Chat (`docs/module/koordination.md`).
