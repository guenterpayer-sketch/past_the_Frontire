# Godot-Prototyp (Godot 4.7)

Vergleichsprototyp zur HTML-Version: Lagerhalle in 3D, Vela (Crew) gegen einen Plünderer auf der Galerie.

## Starten (Windows 11, GitHub Desktop)

1. GitHub Desktop: *File → Clone repository* → `past_the_frontire` klonen.
2. Oben *Current branch* → `claude/confident-edison-6mxzke` wählen.
3. Godot 4.7 starten → *Importieren* → im geklonten Ordner `godot/project.godot` wählen.
4. **F5** startet das Spiel.

Neuer Stand: in GitHub Desktop *Fetch origin* → *Pull origin*, dann in Godot wieder F5.
Für Fehlermeldungen beim Start: `Godot_v4.7.2-stable_win64_console.exe` verwenden, die Meldungen bleiben im Konsolenfenster stehen.

## Was drin ist

- Hexraster als Spielmechanik (1 Hex = 1,5 m, 1 Höhenstufe = 1,5 m), Galerie mit Brüstung (halbe Deckung), Treppe, Container (volle Deckung), Kisten (halbe Deckung)
- W100 aus zwei W10 (rot = Zehner, weiß = Einer, 00 = 100), offen nach oben und unten, Würfelanzeige bleibt bis Klick
- Angriffstabelle, Reichweitenstufen, Kernschussweite, Höhenmodifikator wie in der HTML-Version
- Sichtlinie und Deckung über Strahlen der Physik-Engine: Kopf sichtbar = Ziel sichtbar, Rumpf verdeckt = halbe Deckung
- Einfache Gegner-KI: schießt, wenn sie gut trifft, sucht sonst ein Feld mit Schussfeld und Deckung

**Vereinfacht gegenüber der HTML-Version:** kein Aktivitätssystem (pro Zug bis 6 Hex bewegen und einmal angreifen), keine Blickrichtung, kein Ducken, Kritische Treffer nur als Zusatzschaden, nur 1 gegen 1.

## Bedienung

| Aktion | Eingabe |
|---|---|
| Bewegen | blaues Feld anklicken |
| Angreifen | Gegner anklicken (Maus darüber zeigt Trefferchance und Modifikatoren) |
| Zug beenden | Button oder Enter |
| Kamera | rechte Maustaste ziehen oder WASD/Pfeiltasten, Mausrad = Zoom, Q/E = um 90° drehen |
| Raster | G |
| Neuer Kampf | R |

## Tests (ohne Fenster)

```
godot --headless --path godot --script res://tests/test_rules.gd
```

Selbsttest mit Screenshots (spielt bis zu 5 Runden): `godot --path godot -- --autotest` mit Umgebungsvariable `PTF_OUT` als Zielordner.

## Dateien

| Datei | Inhalt |
|---|---|
| `scripts/main.gd` | Halle, Kamera, Bedienung, Zugablauf, KI |
| `scripts/dice.gd` | W100 aus zwei W10, offener Wurf |
| `scripts/rules.gd` | Angriffstabellen, Waffen, Reichweite |
| `scripts/hexgrid.gd` | Hexraster (Feld ↔ Welt, Nachbarn, Abstand) |
| `scripts/unit.gd` | Figur (Modell, Namensschild) |
| `scripts/dice_panel.gd` | Würfelanzeige |
