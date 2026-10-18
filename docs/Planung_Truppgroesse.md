# Planung: Truppgröße nach Schwierigkeit

Stand 18.10.2026. Wunsch des Nutzers nach dem Spieltest: Schwere Aufträge werden gemieden, weil 6 Crewmitglieder gegen 8 oder mehr Gegner unfair wirken.

## Ist-Stand (geprüft)

- `Campaign.MAX_SQUAD = 6` (`core/campaign.gd`, Charakter-Modul), gilt für alle Schwierigkeiten; benutzt in `ui/briefing_dialog.gd` (Truppwahl, Bodenkampf), `ui/crew/crew_picker.gd` (nur Text/Anzeige, Charakter), `Campaign.suggested_squad()`/`squad()`.
- Kartengenerator verlangt genau 6 Startfelder für die Crew (`core/map_generator.gd`, `crew.size() < 6`).
- Gegner nach Punktebudget (`Mission.DIFFICULTIES`: leicht 42, mittel 58, schwer 76).

## Entscheidungen des Nutzers (18.10.2026)

- **Schwer: bis zu 8 Crewmitglieder**, leicht und mittel weiter höchstens 6.
- **Per Simulation nachjustieren**: Budget/Gegner bei „schwer“ so anpassen, dass es mit 8 Figuren schwer bleibt (Messung mit `test_sim`, Siegquote vorher/nachher als Tabelle).
- **Zuständig: Bodenkampf** (Briefing, Startfelder aller Kartentypen, Simulation); darf dafür `Campaign` minimal ändern (z. B. `Campaign.max_squad(difficulty)`, `MAX_SQUAD` bleibt 6 als Standard) und vermerkt das.
- **Zeitpunkt:** nach dem laufenden Auftrag des Bodenkampfs (Nutzer wartet, bis der fertig ist). Der Koordinator trägt den Auftrag in `docs/module/bodenkampf.md` ein, sobald dessen Branch zusammengeführt ist.

## Offen (Bodenkampf klärt mit dem Nutzer)

- Gilt die 8 auch für Blockade-Aufträge „schwer“ und für die Abwehr beim Entern (Hub-Ablauf)?
- Schnellkampf: Auswahl bis 8, wenn „schwer“ gewürfelt/gewählt ist?
