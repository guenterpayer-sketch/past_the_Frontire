# Export (Android-Tablet, Windows)

Branch `claude/inspiring-hypatia-5l2tq8`. Zuständig für Exporte und das App-Icon; Bedienung auf Touch-Geräten wird an die Module verteilt (unten).

## Stand

- App-Icon `godot/assets/icon/` (Zuordnung im Android-Export: `godot/README.md`, „Starten“).
- Android-APK (Debug-Export) läuft auf dem Tablet des Nutzers (19.10.2026). Web-Export getestet: zu langsam, ohne Ton, Sonderzeichen wie ⏎ fehlen (keine eigene Schrift im Projekt) – nicht weiter verfolgt.
- Exportprofile (`export_presets.cfg`) liegen nur lokal beim Nutzer, nicht im Repo.
- Auftrag 1 (Touch-Grundlagen) gebaut (19.10.2026): neuer Autoload `TouchInput` (`ui/touch_input.gd`: Wischen in Listen, Android-Zurück = Esc), Test `tests/test_touch.gd`. Geänderte gemeinsame Dateien: `ui/modal.gd` (Klick neben ein Fenster bewirkt nichts – Entscheidung Nutzer: bei allen Fenstern), `ui/ui_theme.gd` (`is_touch()`, auf Mobilgeräten Mindesthöhe 44 px für Knöpfe/Eingabefelder, breitere Scrollbalken), `project.godot` (Autoload, `quit_on_go_back=false`). Am Tablet noch nicht geprüft.

## Für den Koordinator: Touch-Bedienung (Wunsch des Nutzers 19.10.2026, Tests am Tablet)

Ziel: eine Oberfläche für PC und Tablet, mit Anpassungen je nach Gerät (`DisplayServer.is_touchscreen_available()`, im Code bisher nicht genutzt). Am PC darf sich nichts verschlechtern. Mockup vor größeren UI-Änderungen, Layoutregeln `docs/Layout.md`.

1. **Außenklick schließt Fenster nur bei Info-Fenstern.** Heute schließt jeder Klick auf den abgedunkelten Hintergrund jedes `Modal` (`ui/modal.gd`, `dim.gui_input` → `close()`); im Charakter-Editor (Roster → neuer Charakter) ist dann alles weg. Entscheidung Nutzer: Fenster mit Eingaben (Editor, Waffenkammer, Handel, …) bleiben offen, reine Anzeigen schließen wie bisher. Vorschlag: Schalter am `Modal` (z. B. `close_on_outside`), Voreinstellung offen lassen.
2. **Wischen zum Scrollen in Listen.** Am Tablet scrollen Listen nur über den Scrollbalken. Annahme (nicht geprüft): Listeneinträge sind Knöpfe, die die Berührung abfangen, bevor der `ScrollContainer` sie sieht. Zentral lösen (ein Helfer für alle `ScrollContainer`, ca. 17 Stellen in `ui/`/`view/`); kurzer Tipp bleibt Klick, erst Bewegung scrollt; am PC auch mit gedrückter Maus.
3. **Größere Flächen auf Touch-Geräten.** Mindestgröße für Knöpfe/Listenzeilen und breitere Scrollbalken im Theme (`ui/ui_theme.gd`), ggf. weitere Stufe in `UiScale` (heute 75–125 %) und größere Voreinstellung auf Touch-Geräten.
4. **Android-Zurück-Taste wirkt wie Esc** (Fenster schließen, Menü). Esc wird heute an mehreren Stellen per `KEY_ESCAPE` abgefragt (`view/hub.gd`, `view/battle.gd`, `ui/crew/crew_screen.gd`, `ui/crew/roster_screen.gd`, …).
5. **Schiff und Sternenkarte per Touch:** Wischen zum Verschieben, Zwei-Finger-Zoom (heute nur Maus/Mausrad/Tasten in `view/hub.gd`, `ui/star_map.gd`). Vorbild: Touch-Behandlung im Bodenkampf (`view/battle.gd`, `_touch_input`).
6. **Karte drehen per Touch** im Bodenkampf und im Schiff. Heute nur Q/E. Art offen (z. B. Zwei-Finger-Drehen oder Drehknöpfe) – mit dem Nutzer klären.

Zuordnung (Vorschlag): 1–4 gemeinsame UI (Koordinator entscheidet, welcher Chat), 5 Hub, 6 Bodenkampf und Hub.

## Aufträge vom Koordinator

- **Auftrag 1 (19.10.2026): Touch-Grundlagen, Punkte 1–4 oben** (Entscheidung des Nutzers: macht der Export-Chat). Gemeinsame Dateien (`ui/modal.gd`, `ui/ui_theme.gd`, `ui/ui_scale.gd`) darf er ändern; jede Änderung an fremden Dateien in „Stand“ vermerken.
  - Punkt 1: Schalter am `Modal` (z. B. `close_on_outside`). Welche Fenster offen bleiben, nach der Entscheidung des Nutzers: Fenster mit Eingaben bleiben offen, reine Anzeigen schließen. Die Liste der Fenster dem Nutzer vorher zeigen.
  - Punkt 2: ein zentraler Helfer für Wischen in `ScrollContainer`, möglichst ohne jede Aufrufstelle einzeln umzubauen.
  - Punkt 3: Mindestgrößen und Scrollbalken im Theme nur auf Touch-Geräten; am PC darf sich nichts ändern.
  - Punkt 4: Android-Zurück möglichst zentral auf Esc abbilden (z. B. in einem Autoload oder über die Eingabeaktion), damit `view/hub.gd`, `view/battle.gd` und die Crew-Bildschirme nicht angefasst werden müssen. Hub und Bodenkampf bauen parallel in diesen Dateien (Touch-Punkte 5 und 6).
  - Vor größeren Änderungen ein Mockup oder eine Liste zeigen. Tests: `test_rules`, `test_hub`, dazu `--autotest-hub` für geänderte Fenster. Vor der Fertigmeldung `main` holen.
- Punkt 5 (Schiff und Sternenkarte per Touch) und Punkt 6 (Drehen) bauen Hub und Bodenkampf (Hub Auftrag 6, Bodenkampf Auftrag 6).
