# Export (Android-Tablet, Windows)

Branch `claude/inspiring-hypatia-5l2tq8`. Zuständig für Exporte und das App-Icon; Bedienung auf Touch-Geräten wird an die Module verteilt (unten).

## Stand

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/export_bis_2026-10-19.md`; Funktionen: `godot/README.md`.

## Gültige Absprachen

- `godot/export_presets.cfg` liegt ab 20.10.2026 im Repo (Entscheidung des Nutzers, damit der Export-Chat die Profile lesen kann; ersetzt die frühere Absprache „nur lokal“). Passwörter gehören nicht hinein (Godot 4: `godot/.godot/export_credentials.cfg`, ignoriert). Pfade darin sind die des Nutzers (Windows).

## Aufträge vom Koordinator

### Auftrag (28.10.2026): Exportgröße und Texturen fürs Tablet

Seit 28.10.2026 liegen neue Packs im Spiel: `godot/assets/packs/` (megakit, essentials, molten, kenney_space, ultimate; ca. 150 MB) und `godot/assets/ship/space/` (26 MB). Genutzt von Hub (Schiff) und Bodenkampf (Kampfkarten). Der Export nimmt alle Ressourcen (`all_resources`).
1. APK bzw. Export **messen** (vorher/nachher, soweit möglich) und berichten.
2. **Vorschlag**: ungenutzte Pack-Teile vom Export ausschließen (Filter in `export_presets.cfg` oder Export-Modus „nur benutzte Ressourcen“; prüfen, was mit Karten-Generator/Editor kompatibel ist, die Modelle zur Laufzeit laden).
3. **Texturen**: MegaKit-Texturen sind 2048 px. Vorschlag, ob/wie fürs Tablet verkleinert wird (z. B. Import-Einstellung Größenbegrenzung nur für Android), ohne die Dateien selbst zu ändern; Hub und Bodenkampf nutzen dieselben Dateien.
4. Erst nach Freigabe des Nutzers umsetzen. Test am Gerät macht der Nutzer.
- Keine offenen Aufträge. Nächster Schritt: neuen Export bauen und am Tablet prüfen (Nutzer).
