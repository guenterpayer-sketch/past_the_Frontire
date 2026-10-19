
## Erledigt (in `main`, Merge von `b08d74d`)

## Aufträge vom Koordinator

- **Auftrag 1 (19.10.2026): Touch-Grundlagen, Punkte 1–4 oben** (Entscheidung des Nutzers: macht der Export-Chat). Gemeinsame Dateien (`ui/modal.gd`, `ui/ui_theme.gd`, `ui/ui_scale.gd`) darf er ändern; jede Änderung an fremden Dateien in „Stand“ vermerken.
  - Punkt 1: Schalter am `Modal` (z. B. `close_on_outside`). Welche Fenster offen bleiben, nach der Entscheidung des Nutzers: Fenster mit Eingaben bleiben offen, reine Anzeigen schließen. Die Liste der Fenster dem Nutzer vorher zeigen.
  - Punkt 2: ein zentraler Helfer für Wischen in `ScrollContainer`, möglichst ohne jede Aufrufstelle einzeln umzubauen.
  - Punkt 3: Mindestgrößen und Scrollbalken im Theme nur auf Touch-Geräten; am PC darf sich nichts ändern.
  - Punkt 4: Android-Zurück möglichst zentral auf Esc abbilden (z. B. in einem Autoload oder über die Eingabeaktion), damit `view/hub.gd`, `view/battle.gd` und die Crew-Bildschirme nicht angefasst werden müssen. Hub und Bodenkampf bauen parallel in diesen Dateien (Touch-Punkte 5 und 6).
  - Vor größeren Änderungen ein Mockup oder eine Liste zeigen. Tests: `test_rules`, `test_hub`, dazu `--autotest-hub` für geänderte Fenster. Vor der Fertigmeldung `main` holen.
- Punkt 5 (Schiff und Sternenkarte per Touch) und Punkt 6 (Drehen) bauen Hub und Bodenkampf (Hub Auftrag 6, Bodenkampf Auftrag 6).
