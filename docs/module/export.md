# Export (Android-Tablet, Windows)

Branch `claude/inspiring-hypatia-5l2tq8`. Zuständig für Exporte und das App-Icon; Bedienung auf Touch-Geräten wird an die Module verteilt (unten).

## Stand

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/export_bis_2026-10-19.md`; Funktionen: `godot/README.md`.

## Gültige Absprachen

- `godot/export_presets.cfg` liegt ab 20.10.2026 im Repo (Entscheidung des Nutzers, damit der Export-Chat die Profile lesen kann; ersetzt die frühere Absprache „nur lokal“). Passwörter gehören nicht hinein (Godot 4: `godot/.godot/export_credentials.cfg`, ignoriert). Pfade darin sind die des Nutzers (Windows).

## Aufträge vom Koordinator

- Später (Nutzer 28.10.2026): Exportgröße prüfen. Seit Hub Auftrag 12 liegen ca. 150 MB Packs in `godot/assets/packs/`; der Export nimmt alle Ressourcen (`all_resources`), ungenutzte Teile ggf. per Filter ausschließen. MegaKit-Texturen sind 2048 px (Hub und Bodenkampf nutzen dieselben Dateien); ob 1024 fürs Tablet nötig ist, mit prüfen. Erst angehen, wenn Hub und Bodenkampf die Packs eingebaut haben.
- Keine offenen Aufträge. Nächster Schritt: neuen Export bauen und am Tablet prüfen (Nutzer).
