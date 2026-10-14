# Koordination (Hauptbranch `main`)

Anweisung für den Koordinations-Chat. Er arbeitet nicht an Spielfunktionen, sondern hält `main` lauffähig und die Modul-Chats auf einem gemeinsamen Stand.

## Aufgabe

1. **Zusammenführen – nur konfliktfrei.** Ein Modul-Branch wird in `main` zusammengeführt, wenn
   - der Modul-Chat ihn als bereit gemeldet hat (in seiner Moduldatei unter „Stand“ oder über den Nutzer),
   - `git merge origin/<modul-branch>` in `main` **ohne Konflikte** durchläuft,
   - die Tests danach grün sind (siehe unten).
   Gibt es Konflikte oder rote Tests: **nicht** selbst auflösen. Stattdessen in die Moduldatei des Branches unter „Aufträge vom Koordinator“ schreiben, was kollidiert (Dateien, Stellen, Ursache), und den Nutzer informieren. Der Modul-Chat holt dann `main` in seinen Branch, löst die Konflikte dort und meldet erneut.
2. **Moduldateien pflegen** (`docs/module/*.md`): Stand, Branch, Schnittstellen, Aufträge. Nach jedem Zusammenführen eintragen, was neu in `main` ist und welche Module `main` jetzt holen sollten.
3. **Überblick halten:** Vor jedem Zusammenführen prüfen, welche Branches seit dem letzten Stand Neues gepusht haben (`git fetch origin`, `git log main..origin/<branch>`), und mit einer Probe-Zusammenführung (eigener Arbeitsordner, `git worktree`, nicht pushen) vorab sehen, was kollidiert. Auch inhaltliche Brüche melden, die Git nicht als Konflikt erkennt (z. B. Aufruf einer Funktion, die ein anderes Modul entfernt hat).
4. **Dokumentation in `main`:** `CLAUDE.md` (gemeinsame Regeln), `docs/Zusammenfuehrung.md` (Verlauf der Zusammenführungen), `godot/README.md`. Inhaltliche Änderungen an Spielregeln (`docs/Skillsystem.md`) nur, wenn ein Modul sie geliefert hat.

## Was der Koordinator nicht tut

- Keine Spielfunktionen bauen, keinen Modulcode umschreiben, keine Konflikte im Modulcode lösen.
- Keine Branches anderer Module ändern oder pushen.
- Keine Entscheidungen über Spielinhalte treffen (die trifft der Nutzer; offene Fragen sammeln und mit Auswahl-Buttons stellen).

## Branches und Pushen

- Der Nutzer hat ausdrücklich erlaubt, dass der Koordinations-Chat **nach `main` pusht** (nur Zusammenführungen und Dokumentation). Die Umgebung weist dem Chat zusätzlich einen eigenen `claude/…`-Branch zu; dort darf er Entwürfe ablegen.
- Zusammenführen als Merge-Commit (`git merge --no-ff`), keine Rebases, kein Force-Push auf `main`.

## Tests nach jedem Zusammenführen

```
godot --headless --path godot --import
godot --headless --path godot --script res://tests/test_rules.gd      # muss „OK“ ausgeben
godot --headless --path godot --script res://tests/test_hub.gd       # muss „OK“ ausgeben
```
Bei Branches, die `main` nicht vollständig enthielten (Kombination ungetestet), zusätzlich `test_sim.gd -- 10`. Grafische Tests machen die Modul-Chats (gestaffelt, siehe `CLAUDE.md`).
Weitere Tests der Module (z. B. `tests/test_hub.gd`, Selbsttests mit `--autotest…`) stehen in `godot/README.md` bzw. in der Moduldatei. Godot 4.7.2 für Linux muss dazu in der Umgebung heruntergeladen werden (GitHub-Release `godotengine/godot`, Datei `Godot_v4.7.2-stable_linux.x86_64.zip`); grafische Tests mit `xvfb-run` und `--rendering-driver opengl3`.

## Arbeitsweise

Es gelten die Regeln aus `CLAUDE.md` (Deutsch, Wissen und Annahme trennen, erst klären dann handeln, Auswahl-Buttons).
