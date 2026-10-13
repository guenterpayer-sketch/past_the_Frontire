# Past the Frontire – Godot-Version (Godot 4.7)

Rundenbasierter Bodenkampf im RMSS-Stil, 6 Crewmitglieder gegen 6 Söldner in einer zufällig erzeugten Lagerhalle (3D, isometrische Kamera).
Regeln wie in der HTML-Version (docs/Skillsystem.md): W100 aus zwei W10, offen nach oben und unten, Angriffstabellen, Kritische Treffer, Aktivitätssystem, Feuerbereitschaft, Blickrichtung, Deckung, Ducken, Abwarten, Erste Hilfe, Psi-Schild, Erfahrung nur für Benutztes.

## Starten (Windows 11, GitHub Desktop)

1. GitHub Desktop: *File → Clone repository* → `past_the_frontire`, Branch `claude/confident-edison-6mxzke`.
2. Godot 4.7 starten → *Importieren* → `godot/project.godot`.
3. **F5** startet das Spiel.

Neuer Stand: *Fetch origin* → *Pull origin*, dann F5. Fehlermeldungen bleiben sichtbar, wenn Godot über `Godot_v4.7.2-stable_win64_console.exe` gestartet wird.

## Bedienung

| Aktion | Maus / Tastatur | Handy / Tablet |
|---|---|---|
| Bewegen | Gangart wählen, blaues Feld anklicken | Feld antippen (Vorschau), nochmal antippen |
| Angreifen | Aktivität wählen (20–100 %), rot umrandeten Gegner anklicken | Gegner antippen, nochmal antippen |
| Vorschau | Maus über ein blaues Feld: grüner Ring + ◎ = von dort treffbar, roter Ring + ⚠ = wer dich dort trifft | erstes Antippen |
| Drehen | Rechtsklick auf ein Feld oder „Ausrichten“ | lange drücken |
| Kamera | Ziehen (links/Mitte), WASD/Pfeile, Mausrad = Zoom, Q/E = um 90° drehen | ein Finger ziehen, zwei Finger zoomen |
| Zug beenden | Enter oder Button | Button |
| Reichweite / Raster | R / G | Buttons |
| Abbrechen | Esc | – |

Oben: Charakterbogen, Tabellen, KI für Crew (zuschauen), Ton, Würfel, Neue Karte. Einspringen nach dem Abwarten über die Initiative-Leiste.

## Grafik: 3D-Modelle

Figuren, Waffen und Teile der Halle sind 3D-Modelle (frei lizenziert, siehe `assets/LICENSES.md`). Was kein Modell hat, wird weiter aus Grundkörpern gebaut.

| Was | Modell | Einstellen im Godot-Editor |
|---|---|---|
| Figuren (mit Animationen: stehen, gehen, laufen, zielen, schießen, Nahkampf, Psi, getroffen, fallen, Hocke, Erste Hilfe, nachladen) | Quaternius Modular Men/Women, Brecher = Mech | Figur in `data/units/…/*.tres` → Feld **Visual** → `data/visuals/characters/*.tres` (Modell, Größe, Animationen) |
| Waffen in der Hand | Quaternius Sci-Fi-Waffen (Gewehre, Pistole, Werfer); Vibroklinge und Psi leuchtende Grundformen | Waffe in `data/weapons/*.tres` → Gruppe **Darstellung** (Modell, Länge, Lage in der Hand) |
| Halle: Boden, Wände, Kisten, Fässer, Säulen, Regale | Quaternius Modular Sci-Fi / Cyberpunk | `data/visuals/warehouse.tres` (je Objektart ein Modell und wie es eingepasst wird) |
| Container, Barrieren, Galerie, Treppen, Leitern | Grundkörper (kein passendes Modell gefunden) | – |

**Eigene oder andere Modelle einsetzen:** `.glb` nach `godot/assets/…` kopieren, im Inspector in das passende Feld ziehen. Hallenobjekte werden automatisch in ihren Platz gestreckt bzw. wiederholt.
Für Figuren mit Quaternius-ähnlichem Skelett (Knochen `Hips`, `UpperArm.L` …) neue `CharacterVisual`-Datei anlegen und die Animationen übertragen:

```
godot --headless --path godot --script res://tools/bake_animations.gd
```

Das Werkzeug überträgt die 75 KayKit-Animationen (Auswahl von 18) auf jedes Modell mit „Bake From Kaykit“. Figuren mit eigenen Animationen (wie der Mech) bekommen stattdessen eine Namensliste („Anim Names“).

## Aufbau

| Ordner | Inhalt |
|---|---|
| `data/` | **Spieldaten als Ressourcen, im Godot-Editor bearbeitbar**: Waffen, Rüstungen, Angriffstabellen, Kritische Treffer, Patzer, Figuren (`units/crew/*.tres`, `units/enemies/*.tres`), Mannschaften (`units/crew.tres`, `units/enemies.tres`). `data/types/` enthält die Ressourcen-Klassen. |
| `core/` | Spiellogik ohne Grafik: `dice.gd` (W100 aus 2W10), `rules.gd` (Eigenschaften, Fertigkeiten, Proben, EP), `tables.gd`, `hex.gd`, `battle_map.gd` (Gelände, Sichtlinie, Deckung, Wege), `map_generator.gd`, `combatant.gd` (Figur im Kampf), `combat.gd` (Kampfablauf, meldet alles über Signale), `combat_ai.gd`, `roster.gd` (Fortschritt speichern), `prefs.gd`, `game_data.gd` |
| `view/` | Darstellung und Ablauf: `battle.gd` (Hauptszene, verbindet alles), `event_player.gd` (spielt die Kampf-Ereignisse nacheinander ab), `player_controller.gd` (Spielerseite: Modus, Vorschau, Tooltips), `map_view.gd` (Halle), `model_batch.gd` (Hallenmodelle einpassen und gesammelt zeichnen), `unit_view.gd` (Figur auf der Karte), `figure/` (Darstellung einer Figur: `model_figure.gd` mit 3D-Modell und Animationen, `procedural_figure.gd` aus Grundkörpern), `overlay.gd`, `fx.gd`, `camera_rig.gd` |
| `assets/` | 3D-Modelle (`characters/`, `weapons/`, `hall/`), übertragene Animationen (`characters/anims/`), Quelle der Animationen (`source/kaykit/`), Lizenzen |
| `tools/` | `bake_animations.gd` und `retarget.gd`: Animationen von einem Skelett auf ein anderes übertragen |
| `ui/` | Oberfläche: `battle_ui.gd` (Layout), `unit_panel.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, Dialoge (`sheet_dialog.gd`, `tables_dialog.gd`, `end_dialog.gd`, `modal.gd`), `ui_theme.gd` |
| `audio/` | `sfx.gd` (Autoload `Sfx`): Soundeffekte werden synthetisch erzeugt, keine Audiodateien |
| `tests/` | Regeltests und KI-gegen-KI-Simulation |

Grundregel: `core/` kennt keine Grafik. `Combat` meldet Würfe, Schritte, Treffer usw. über Signale; `EventPlayer` spielt sie der Reihe nach ab (Würfel rollen → Schuss → Treffer → Log). Die KI plant in einem eigenen Thread, damit die Halle bedienbar bleibt.

Der Fortschritt der Crew (Ränge und EP) liegt in `user://crew.json`, Einstellungen in `user://settings.cfg` (unter Windows: `%APPDATA%\Godot\app_userdata\Past the Frontire`).

## Tests

```
godot --headless --path godot --script res://tests/test_rules.gd
godot --headless --path godot --script res://tests/test_sim.gd -- 30
```

Selbsttests mit Screenshots (Ordner in `PTF_OUT`): `godot --path godot -- --autotest` (KI gegen KI, Dialoge) und `-- --autotest-player` (Bedienung mit simulierten Mausklicks). Figurengalerie (alle 12 Figuren in mehreren Haltungen): `godot --path godot --script res://tests/figure_gallery.gd`. `-- --no-shadows` schaltet Schatten aus (auf Handys automatisch).
