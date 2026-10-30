# Export (Android-Tablet, Windows)

Branch `claude/inspiring-hypatia-5l2tq8`. Zuständig für Exporte und das App-Icon; Bedienung auf Touch-Geräten wird an die Module verteilt (unten).

## Stand

- Alles bis 19.10.2026 in `main`. Verlauf: `docs/module/archiv/export_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- Auftrag „Exportgröße und Texturen“ (29.10.2026) erledigt, Ergebnis unten.

## Gültige Absprachen

- `godot/export_presets.cfg` liegt ab 20.10.2026 im Repo (Entscheidung des Nutzers, damit der Export-Chat die Profile lesen kann; ersetzt die frühere Absprache „nur lokal“). Passwörter gehören nicht hinein (Godot 4: `godot/.godot/export_credentials.cfg`, ignoriert). Pfade darin sind die des Nutzers (Windows).

## Aufträge vom Koordinator

### Auftrag (28.10.2026): Exportgröße und Texturen fürs Tablet

Seit 28.10.2026 liegen neue Packs im Spiel: `godot/assets/packs/` (megakit, essentials, molten, kenney_space, ultimate; ca. 150 MB) und `godot/assets/ship/space/` (26 MB). Genutzt von Hub (Schiff) und Bodenkampf (Kampfkarten). Der Export nimmt alle Ressourcen (`all_resources`).
1. APK bzw. Export **messen** (vorher/nachher, soweit möglich) und berichten.
2. **Vorschlag**: ungenutzte Pack-Teile vom Export ausschließen (Filter in `export_presets.cfg` oder Export-Modus „nur benutzte Ressourcen“; prüfen, was mit Karten-Generator/Editor kompatibel ist, die Modelle zur Laufzeit laden).
3. **Texturen**: MegaKit-Texturen sind 2048 px. Vorschlag, ob/wie fürs Tablet verkleinert wird (z. B. Import-Einstellung Größenbegrenzung nur für Android), ohne die Dateien selbst zu ändern; Hub und Bodenkampf nutzen dieselben Dateien.
4. Erst nach Freigabe des Nutzers umsetzen. Test am Gerät macht der Nutzer.

**Ergebnis (29.10.2026):**
- Gemessen (Spielpaket PCK, Godot 4.7.2, Profile aus `export_presets.cfg`; APK selbst nicht gemessen, kein Android-SDK im Cloud-Container): Android und Windows je **441 MB**. Größte Blöcke: Musik 142 MB, essentials 123 MB, Story-Bilder 47 MB, molten 41 MB, megakit 40 MB, Raumschiffe 22 MB. Ohne die neuen Packs gerechnet ca. 212 MB.
- Ungenutzte Pack-Teile: ca. 37 MB. Modus „nur benutzte Ressourcen“ geht nicht (`core/map_types.gd` und `view/space_ship_view.gd` laden Modelle über zusammengesetzte Pfade). Ausschlussliste: Nutzer hat abgelehnt („vorerst nicht“, Risiko fehlender Modelle).
- Texturen: eine Größenbegrenzung nur für Android gibt es in Godot 4 nach Kenntnis des Export-Chats nicht. Nutzer hat Variante B gewählt (nach Vergleichsbildern): **essentials und megakit mit höchstens 1024 px** (`process/size_limit=1024` in 48 `.png.import`, Bilder unverändert, gilt auch am PC). Android-Paket danach **321 MB** (−120 MB). Tests `test_rules`, `test_hub` OK.
- **Für Hub und Bodenkampf:** neue Texturen aus essentials/megakit im Import-Dock auf „Size Limit“ 1024 setzen, sonst kommen sie in voller Größe in den Export.
- **Nachtrag 30.10.2026 (Freigabe des Nutzers):** Story-Bilder `art/story` verlustbehaftet importiert (WebP 0.8, 44 `.png.import`; 47 → 7 MB). Musik `audio/music` auf 128 kbit/s neu kodiert (26 Dateien, Namen und Länge gleich, `music.gd` unverändert; 142 → 75 MB). Android-Paket damit **217 MB** (vorher 441, nach Texturgrenze 321). Geänderte Dateien anderer Module: Musik (Hub), Story-Bilder-Import (Story). Doppelte Musikdateien (arpmedia 3×, Distant Metallic Pulse 2×, zusammen ca. 8 MB nach Neukodierung) liegen weiter im Projekt; vermeiden ginge nur über eine Codeänderung in `audio/music.gd` (Hub).
- **Für Hub und Story:** neue Musik mit 128 kbit/s ablegen, neue Story-Bilder im Import-Dock auf „Lossy“ 0.8.
- Nächster Schritt: neuen Export vom Branch `claude/inspiring-hypatia-5l2tq8` (bzw. nach dem Zusammenführen von `main`) bauen und am Tablet prüfen (Nutzer).
