# Past the Frontire – Godot-Version (Godot 4.7)

Rundenbasierter Bodenkampf im RMSS-Stil, 6 Crewmitglieder gegen eine zufällig zusammengestellte Gegnergruppe (3–9 Figuren) in einer zufällig erzeugten Lagerhalle (3D, isometrische Kamera).
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

Die Karte nutzt den ganzen Bildschirm, die Bedienung schwebt darüber:
- oben links die Initiative-Leiste (Einspringen nach dem Abwarten),
- oben rechts Runde/Auftrag und Symbolknöpfe (Charakterbogen, Tabellen, KI für Crew, Ton, Würfel, Menü mit Neue Mission, Raster, Reichweite, Bedienung), darunter der Infokasten für das Feld bzw. die Figur unter der Maus (auf Touchgeräten mit „Ausführen“),
- unten links Würfel, Kampflog (einklappbar) und die eigene Figur,
- unten rechts der Aktionsblock (Waffe, Gangart, Angriffsaktivität, Aktionen, Zug beenden) bzw. in Runde 0 die Aufstellung; ist die KI am Zug, steht dort deren Figur.

Basisauflösung der Oberfläche ist 1600×900 (Fenster 1600×900); größere Bildschirme skalieren die Oberfläche mit.

## Ablauf eines Einsatzes

1. **Briefing**: Auftrag, Gegnergruppe (Fraktion, Typen, Ausrüstung), Schwierigkeit, Hallengröße, Belohnung. „Andere Mission“ würfelt neu (Schwierigkeit wählbar oder zufällig).
2. **Runde 0 – Aufstellung**: Figur anklicken (oder im Panel wählen), dann ein blaues Feld im Eingangsbereich (Spalten 1–4 links): dorthin stellen, mit einer anderen Figur der Crew wird getauscht. Blickrichtung per Rechtsklick / lange drücken / „drehen“. „Kampf beginnen“ (oder Enter) startet Runde 1.
3. **Kampf** bis alle Gegner oder alle Crewmitglieder ausgeschaltet sind.
4. **Charakterübersicht = Aufleveln** (eigene Szene `crew.tscn`, das Charakter-Modul): Das Ergebnis des Kampfes ist dort schon verbucht und gespeichert. Reiter (oder Pfeiltasten) blättern durch die Crew. Je Figur: drehende 3D-Vorschau, Name, Kürzel, Farbe, Station und Aussehen änderbar, Psi-Kräfte der gelernten Listen. Keine Ranggrenze; neue Psi-Liste: erster Rang doppelt, höchstens eine neue Liste pro Levelphase (`Character.new_list`, nach jedem Einsatz geleert). Ränge kaufen (fehlende EP kommen aus den freien EP), Eigenschaften mit freien EP um +1 steigern, „zurücknehmen“ macht die Steigerungen der Figur rückgängig. Nicht ausgegebene freie EP bleiben gespart. „Neues Crewmitglied“ öffnet den Charakter-Editor (siehe unten). „Speichern & nächste Mission“.

## Charakter-Editor (neues Crewmitglied)

Im Charakter-Modul über „Neues Crewmitglied“. Regeln: `docs/Skillsystem.md`, Abschnitt 7a (Code: `core/creation.gd`).

- 7 Würfe 20–100, der niedrigste wird 90; „neu würfeln“ beliebig oft (verteilte Ränge verfallen dann).
- Würfe per Auswahlfeld auf die Eigenschaften legen (die Eigenschaft, die den Wurf hatte, bekommt den bisherigen).
- Fertigkeitspunkte = Eigenschaftssumme × 1,2; Rang kostet 10 + 2 × Rang; höchstens Rang 5, zwei Fertigkeiten bis 8; höchstens zwei Psi-Listen. Gesperrte „+“ zeigen den Grund als Tooltip.
- Neu: **Körperentwicklung** (+5 TP je Rang), **Psi-Punkte-Entwicklung** (+2 PP je Rang), **Psi-Listen** (`core/psi_lists.gd`, Kräfte werden angezeigt; im Kampf gibt es bisher nur Psi-Schild und Psi-Stoß).
- Station (jede einmal, Jäger mehrfach), Aussehen, zwei Waffen, Rüstung, Schild frei wählbar.
- „Übernehmen“ als neues Mitglied (bis 6) oder als Ersatz für ein vorhandenes; wird sofort gespeichert.
- Noch nicht gebaut: die Variante zum Aufleveln.

## Module und Schnittstelle

Charakter-Modul und Kampfmodule sind getrennt; sie tauschen nur Daten aus:

```
Charakter-Modul (crew.tscn)  ──Kopien der Charaktere──▶  Kampfmodul (main.tscn = Bodenkampf, später Raumkampf)
        ▲                                                         │
        └──────────────── MissionResult (Ergebnis) ◀──────────────┘
```

- `core/character.gd` (**Character**): ein Crewmitglied mit allen dauerhaften Werten (Name, Rolle, Farbe, Eigenschaften, Fertigkeiten mit Rang und EP, freie EP, Waffen, Rüstung, Schild, Medikits, Aussehen). Gespeichert in `user://crew.json` (Version 3: vollständige Charaktere; ohne Speicherstand gilt die Startcrew aus `data/units/crew.tres`, ältere Speicherstände werden auf die Startcrew gelegt).
- `core/campaign.gd` (**Campaign**): der laufende Spielstand zwischen den Szenen (Crew, letztes Ergebnis).
- Kampf: `Combatant.from_character()` macht eine Kopie mit vollen TP, PP und voller Ausrüstung. Der Kampf ändert die Charaktere nicht.
- `core/mission_result.gd` (**MissionResult**): was ein Kampfmodul zurückgibt, je Figur:
  `xp` (benutzte Fertigkeiten → EP), `free_xp` (3 + Missionsbelohnung bei Sieg), `kills`,
  `status` (`state` ok/ko/tot, `hp`, `max_hp`, `bleed`, `malus`), `used` (`medkits`, `ammo` je Waffe).
  `Character.apply_result()` verbucht EP und freie EP. Zustand und Verbrauch werden gespeichert, aber noch nicht ausgewertet (Heilung, Tod und Nachschub sind noch nicht gebaut; jeder Einsatz beginnt heil und voll ausgerüstet).

Ein neues Kampfmodul braucht also nur `Campaign.crew()` als Eingabe und muss am Ende `Campaign.finish_mission(Ergebnis)` aufrufen und nach `Campaign.CREW_SCENE` wechseln.

Missionsgenerator (`core/mission.gd`): Punktebudget je Schwierigkeit (leicht 42, mittel 58, schwer 76), Gegnertypen gewichtet nach Fraktion (`data/missions/*.tres`, Bedrohungswert `threat` in `data/units/enemies/*.tres`), einzelne Gegner als Veteran (+1 Rang, +5 Eigenschaften) oder Neuling (−1, −5). Hallengröße nach Gegnerzahl. Gleicher Seed = gleiche Mission.

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
| `data/` | **Spieldaten als Ressourcen, im Godot-Editor bearbeitbar**: Waffen, Rüstungen, Angriffstabellen, Kritische Treffer, Patzer, Figuren (`units/crew/*.tres`, `units/enemies/*.tres` mit Bedrohungswert), Mannschaften (`units/crew.tres`, `units/enemies.tres` = feste Gruppe für Tests), Fraktionen für den Missionsgenerator (`missions/*.tres`: Gegnertypen mit Gewichten). `data/types/` enthält die Ressourcen-Klassen. |
| `core/` | Spiellogik ohne Grafik: `dice.gd` (W100 aus 2W10), `rules.gd` (Eigenschaften, Fertigkeiten, Proben, EP), `tables.gd`, `hex.gd`, `battle_map.gd` (Gelände, Sichtlinie, Deckung, Wege), `map_generator.gd` (Menge des Kleinzeugs: `SCATTER_DENSITY`), `mission.gd` (Missionsgenerator), `combatant.gd` (Figur im Kampf), `combat.gd` (Kampfablauf, meldet alles über Signale), `combat_ai.gd`, `character.gd` (Crewmitglied mit allen dauerhaften Werten), `creation.gd` (Regeln der Charaktererschaffung), `psi_lists.gd` (Psi-Listen), `roster.gd` (Crew speichern und laden), `campaign.gd` (Spielstand zwischen den Szenen), `mission_result.gd` (Einsatzergebnis), `prefs.gd`, `game_data.gd` |
| `view/` | Darstellung und Ablauf: `battle.gd` (Hauptszene, verbindet alles), `event_player.gd` (spielt die Kampf-Ereignisse nacheinander ab), `player_controller.gd` (Spielerseite: Modus, Vorschau, Tooltips), `map_view.gd` (Halle), `model_batch.gd` (Hallenmodelle einpassen und gesammelt zeichnen), `unit_view.gd` (Figur auf der Karte), `figure/` (Darstellung einer Figur: `model_figure.gd` mit 3D-Modell und Animationen, `procedural_figure.gd` aus Grundkörpern), `overlay.gd`, `fx.gd`, `camera_rig.gd` |
| `assets/` | 3D-Modelle (`characters/`, `weapons/`, `hall/`), übertragene Animationen (`characters/anims/`), Quelle der Animationen (`source/kaykit/`), Lizenzen |
| `tools/` | `bake_animations.gd` und `retarget.gd`: Animationen von einem Skelett auf ein anderes übertragen |
| `ui/` | Oberfläche: `battle_ui.gd` (schwebendes Layout), `top_menu.gd`, `icon_button.gd`, `info_box.gd`, `unit_card.gd`, `action_panel.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, Dialoge (`briefing_dialog.gd`, `sheet_dialog.gd`, `tables_dialog.gd`, `modal.gd`), `crew/` (Charakter-Modul: `crew_screen.gd` = Szene `crew.tscn`, `crew_overview.gd` = Charakterübersicht/Aufleveln, `character_editor.gd` = neues Crewmitglied, `figure_preview.gd` = 3D-Vorschau einer Figur), `ui_theme.gd` |
| `audio/` | `sfx.gd` (Autoload `Sfx`): Soundeffekte werden synthetisch erzeugt, keine Audiodateien |
| `tests/` | Regeltests und KI-gegen-KI-Simulation |

Grundregel: `core/` kennt keine Grafik. `Combat` meldet Würfe, Schritte, Treffer usw. über Signale; `EventPlayer` spielt sie der Reihe nach ab (Würfel rollen → Schuss → Treffer → Log). Die KI plant in einem eigenen Thread, damit die Halle bedienbar bleibt.

Die Crew (vollständige Charaktere mit Rängen und EP, Eigenschaften, gesparten freien EP, Ausrüstung) liegt in `user://crew.json` (ältere Speicherstände werden weiter gelesen), Einstellungen in `user://settings.cfg` (unter Windows: `%APPDATA%\Godot\app_userdata\Past the Frontire`).

## Tests

```
godot --headless --path godot --script res://tests/test_rules.gd
godot --headless --path godot --script res://tests/test_sim.gd -- 30
godot --headless --path godot --script res://tests/test_sim.gd -- 45 missionen   # Siege je Schwierigkeit
```

Selbsttests mit Screenshots (Ordner in `PTF_OUT`): `godot --path godot -- --autotest` (KI gegen KI, Dialoge) und `-- --autotest-player` (Bedienung mit simulierten Mausklicks). Figurengalerie (alle 12 Figuren in mehreren Haltungen): `godot --path godot --script res://tests/figure_gallery.gd`. `-- --no-shadows` schaltet Schatten aus (auf Handys automatisch).
