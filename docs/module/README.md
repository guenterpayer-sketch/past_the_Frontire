# Module

Jedes Modul wird in einem eigenen Chat auf einem eigenen Branch gebaut. Diese Dateien sind die Absprache zwischen den Modulen und dem Koordinations-Chat; sie liegen in `main`.

| Datei | Modul | Branch |
|---|---|---|
| `koordination.md` | Koordination, Hauptbranch `main` | `main` |
| `bodenkampf.md` | Bodenkampf (Lagerhalle, Missionen, Runde 0) | `claude/confident-edison-6mxzke` |
| `charakter.md` | Charakter-Modul und Charakter-Editor | `claude/elegant-gauss-hq5bus` |
| `hub.md` | Hub: Startmenü, Schiff, Sternenkarte, Spielstände | `claude/happy-lamport-u4fvya` |
| `raumkampf.md` | Raumkampf (Mutterschiff, Jäger) | `claude/raumkampf-modul` |
| `story.md` | Story/Kampagne | `claude/zen-sagan-9yn0le` |
| `export.md` | Export (Android-Tablet, Windows), App-Icon `godot/assets/icon/` | `claude/inspiring-hypatia-5l2tq8` |

## Ablauf für jeden Modul-Chat

1. Zu Beginn: die eigene Moduldatei in `main` lesen (`git fetch origin && git show origin/main:docs/module/<datei>`), vor allem „Aufträge vom Koordinator“.
2. Auf dem eigenen Branch arbeiten. Dateien anderer Module nur ändern, wenn es für die Schnittstelle nötig ist, und das in der eigenen Moduldatei unter „Stand“ vermerken.
3. **Vor der Fertigmeldung:** `main` in den eigenen Branch holen (`git merge origin/main`), Konflikte dort lösen, Tests laufen lassen, pushen.
4. Fertigmeldung an den Nutzer (er gibt sie an den Koordinations-Chat weiter): welcher Commit, was ist neu, was ändert sich an Schnittstellen.
5. Eigene Moduldatei aktuell halten. Sie wird in `main` gepflegt; Änderungen daran auf dem eigenen Branch werden mit dem nächsten Zusammenführen übernommen.

6. **Warnungen (Nutzer 20.10.2026):** Der Godot-Debugger soll übersichtlich bleiben, damit echte Fehler (rot) auffallen. `integer_division` ist projektweit abgeschaltet (`godot/project.godot`, `[debug]`). Andere GDScript-Warnungen (gelb) in Dateien, die man ohnehin bearbeitet, nebenbei beseitigen (z. B. `_` vor unbenutzten Parametern, keine Namen wie `name`/`action` für lokale Variablen, `as` bei Enums). Keine neuen Warnungen einbauen.

Neues Modul (z. B. Weltraumkampf, Story): Datei nach demselben Muster anlegen und in diese Tabelle eintragen.
