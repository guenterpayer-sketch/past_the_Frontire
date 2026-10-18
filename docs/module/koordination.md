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
4. **Moduldateien kurz halten (Entscheidung des Nutzers 16.10.2026):** Nach jeder Zusammenführung erledigte Aufträge und alten Stand der betroffenen Moduldatei nach `docs/module/archiv/<modul>_bis_<datum>.md` verschieben (anfügen, nicht löschen); in der Moduldatei bleiben Zuständigkeit, Schnittstellen, gültige Absprachen, kurzer Stand und offene Aufträge. Ebenso in `docs/Zusammenfuehrung.md` nur die letzte Runde behalten. Nur Dateien kürzen, deren Branch keine ungemergten Commits hat.
5. **Dokumentation in `main`:** `CLAUDE.md` (gemeinsame Regeln), `docs/Zusammenfuehrung.md` (Verlauf der Zusammenführungen), `godot/README.md`. Inhaltliche Änderungen an Spielregeln (`docs/Skillsystem.md`) nur, wenn ein Modul sie geliefert hat.

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
**Nur nötig, wenn der Branch `main` nicht vollständig enthielt** (Kombination ungetestet); dann zusätzlich `test_sim.gd -- 10`. Enthielt er `main`, ist das Ergebnis identisch mit dem vom Modul getesteten Stand: keine eigenen Tests (Testregel des Nutzers, `CLAUDE.md`). Grafische Tests machen die Modul-Chats (gestaffelt, siehe `CLAUDE.md`).
Weitere Tests der Module (z. B. `tests/test_hub.gd`, Selbsttests mit `--autotest…`) stehen in `godot/README.md` bzw. in der Moduldatei. Godot 4.7.2 für Linux muss dazu in der Umgebung heruntergeladen werden (GitHub-Release `godotengine/godot`, Datei `Godot_v4.7.2-stable_linux.x86_64.zip`); grafische Tests mit `xvfb-run` und `--rendering-driver opengl3`.

## Arbeitsweise

Es gelten die Regeln aus `CLAUDE.md` (Deutsch, Wissen und Annahme trennen, erst klären dann handeln, Auswahl-Buttons).

## Übergabe (18.10.2026)

Dritter Koordinations-Chat beendet (langer Verlauf). Ein neuer Chat startet nur von diesen Dateien aus.

**Stand `main`:** alle Module zusammengeführt; Raumkampf V1 inkl. Wracks/Entern (`c0e578c`), Hub bis `608be25` (Abwehr als Sieg), Charakter bis `9228e24` (Farb-Absturz behoben), Bodenkampf bis `bb89c03` (Kartentypen, Startlagen). Verlauf: `docs/Zusammenfuehrung.md`.

**Offen:**
- **Bodenkampf:** Truppgröße in `main` (`e931e13`). Karteneditor **ruht** (Fragen in `bodenkampf.md`).
- Alle anderen Module: keine offenen Aufträge.
- Ideen für später: Fraktionen mit Ober-/Unterarten (`docs/Planung_Kampfkarten.md`), eigene Jäger/Hangar (V2), Story/Kampagne, Balancing Boden/Charakter (`docs/Skillsystem.md` 9).

**Branches:** `claude/confident-edison-6mxzke` (Bodenkampf), `claude/elegant-gauss-hq5bus` (Charakter), `claude/happy-lamport-u4fvya` (Hub), `claude/raumkampf-modul` (Raumkampf). Immer `git fetch origin` ohne Branch-Angabe.

**Arbeitsweise, die sich bewährt hat:**
- Pro Fertigmeldung: `git fetch origin`; `git rev-list --count <branch>..main` (0 = enthält `main`); `git merge-tree --write-tree --name-only main <branch>` auf Konflikte; `git merge --no-ff`. Eigene Tests (`test_rules`, `test_hub`, bei Raumkampf `test_space`, bei Kampf-Änderungen `test_sim -- 10`; Godot 4.7.2 unter `~/godot/`, vorher `--headless --import`) nur, wenn der Branch `main` nicht enthielt. Dann Zeile in `docs/Zusammenfuehrung.md`, erledigten Auftrag der Moduldatei ins Archiv (`docs/module/archiv/`), pushen.
- Konflikt nur in der eigenen Moduldatei (Doku) darf der Koordinator lösen (Nutzer einverstanden); Code-Konflikte nie.
- Moduldateien nur ändern, wenn der Branch keine ungemergten Commits hat; sonst Planungsdokument und Prompt an den Nutzer.
- Nutzer-Rückmeldungen: erst im Code prüfen, Fragen mit Auswahl-Buttons + Freitext am Ende, dann Auftrag in die Moduldatei und kurzer Prompt.
- Lokale Probleme beim Nutzer (Windows): Scheinänderungen sind über `.gitattributes` und `import_etc2_astc` gelöst; bei Skriptfehlern nach Pull zuerst „Godot schließen, Discard, Pull, neu öffnen“. Godot-Log: `%APPDATA%\Godot\app_userdata\Past the Frontire\logs\godot.log`.
- **Antworten kurz halten**, Chat bei langem Verlauf ersetzen.
