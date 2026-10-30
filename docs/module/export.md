# Export (Android-Tablet, Windows)

Branch `claude/inspiring-hypatia-5l2tq8`. Zuständig für Exporte und das App-Icon; Bedienung auf Touch-Geräten wird an die Module verteilt (unten).

## Stand

- Alles bis 19.10.2026 in `main`. Verlauf: `docs/module/archiv/export_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- Auftrag „Exportgröße und Texturen“ (29.10.2026) erledigt (Texturgrenze 1024 für essentials/megakit, Spielpaket 441 → 321 MB).
- **Nachtrag 30.10.2026 (Freigabe des Nutzers), in `main` seit 30.10.2026 (`4c8e912`):** Story-Bilder `art/story` verlustbehaftet importiert (WebP 0.8, 44 `.png.import`; im Export 47 → 7 MB). Musik `audio/music` auf 128 kbit/s neu kodiert (26 Dateien, Namen und Länge gleich, `music.gd` unverändert; 142 → 75 MB). Android-Paket damit **217 MB**. Geänderte Dateien anderer Module: Musik (Hub), Import der Story-Bilder (Story). Doppelte Musikdateien (arpmedia 3×, Distant Metallic Pulse 2×, zusammen ca. 8 MB) bleiben; vermeiden ginge nur über eine Codeänderung in `audio/music.gd` (Hub).
- **Für Hub und Story:** neue Musik mit 128 kbit/s ablegen, neue Story-Bilder im Import-Dock auf „Lossy“ 0.8.

## Gültige Absprachen

- `godot/export_presets.cfg` liegt ab 20.10.2026 im Repo (Entscheidung des Nutzers, damit der Export-Chat die Profile lesen kann; ersetzt die frühere Absprache „nur lokal“). Passwörter gehören nicht hinein (Godot 4: `godot/.godot/export_credentials.cfg`, ignoriert). Pfade darin sind die des Nutzers (Windows).

## Aufträge vom Koordinator

- Keine offenen Aufträge. Nächster Schritt: neuen Export bauen und am Tablet prüfen (Nutzer). Messung 29.10.2026: Spielpaket 441 MB, Details im Archiv.
