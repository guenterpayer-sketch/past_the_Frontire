# Planung: mehr Kampfkarten und Karteneditor

Stand 17.10.2026. Wunsch des Nutzers nach dem Spieltest: mehr Abwechslung als nur die Lagerhalle.

## Ist-Stand (geprüft)

- Ein Generator `core/map_generator.gd` (Lagerhalle: Galerie, Regale, Container, Kisten), Karte `core/battle_map.gd`. Keine weiteren Kartentypen, keine fertigen Karten.
- Bodenfraktionen: Vantar-Konzern, Kult des Leeren Lichts, Söldner der Roten Sonne, Kesslers Schmugglerbande (`data/missions/`).

## Entscheidungen des Nutzers (17.10.2026)

| Punkt | Entscheidung |
|---|---|
| Neue Kartentypen | **Bar**, **Straßenkampf**, **antiker Tempel**, **Büroräume**, **Raumschiff-Inneres** (zusätzlich zur Lagerhalle). |
| Fraktionsbindung | **Vorerst keine**: Kartentyp wird unabhängig von der Fraktion gewählt. Zuordnung (z. B. Tempel → Kult, Büro → Konzern) später. |
| Raumschiff-Inneres | **Jetzt mit dabei**; Entern (selbst entern und Abwehr, wenn Gegner entern) nutzt diese Karte statt der Lagerhalle. |
| Karteneditor | **Im Spiel, nach den Kartentypen**: Editor (wie der Ausrüstungs-Editor im Startmenü), eigene Karten gespeichert; im Spiel ein **Pool fertiger Karten plus Zufallskarten**. |

## Idee für später (nicht Teil dieses Auftrags)

- **Fraktionen mit Oberarten und Unterarten** (Nutzer): Oberarten z. B. Konzern, Söldner, Piraten, Syndikat, Kult; darunter benannte Fraktionen wie bei „Kult des Leeren Lichts“, z. B. Konzern → Vantar-Konzern, Semidrug Inc. … Danach Kartentypen an Oberarten binden (Bar ↔ Piraten/Plünderer, Straße ↔ Konzern/Syndikat, Tempel ↔ Kult, Büro ↔ Konzern).

## Offen (klärt der Bodenkampf-Chat mit dem Nutzer, dann Mockup)

- Aussehen und Bausteine je Kartentyp (Deckung, Höhen, Türen, Fenster, Engstellen), Größen, Lichtstimmung.
- Wie der Kartentyp gewählt wird (gleich verteilt? Gewichte?) und ob er im Briefing sichtbar ist.
- Editor: Bedienung (Raster, Bausteine, Startfelder Crew/Gegner, Höhen), Speicherort (Vorschlag `user://maps/`, wie `user://gear/`), Prüfung (erreichbar, genug Startfelder), Anteil Pool vs. Zufall.
- Ob mitgelieferte fertige Karten (in `res://`) dazukommen.

## Karteneditor: Entscheidungen (18.10.2026, gebaut)

| Punkt | Entscheidung |
|---|---|
| Bedienung | Draufsicht und 3D, umschaltbar (Nutzer); Pinsel, Rechteck, Pipette, Höhe 0–5, Rückgängig |
| Neue Karte | leer, Zufallskarte als Vorlage, Kopie (Nutzer); Größen wie die Zufallskarten (klein/mittel/groß, je auch quadratisch) |
| Weg ins Spiel | je Karte „Im Spiel verwenden“ (Nutzer); aktive Karten des Kartentyps ersetzen mit 30 % die Zufallskarte; im Schnellkampf fest wählbar |
| Startfelder | gezeichnet (mind. 8 Crew, 9 Gegner) für „Standard“, übrige Lagen automatisch; Ersatz, wenn eine Lage nicht geht |
| Prüfung | Startfelder je Lage, nicht erreichbare Felder rot; nur nutzbare Karten aktiv |
| Speicherort | `user://maps/<id>.json`, global für alle Spielstände |
| Mitgelieferte fertige Karten | vorerst keine |

Die übrigen Punkte hat der Nutzer dem Bodenkampf-Chat zur Entscheidung überlassen. Beschreibung: `godot/README.md`, „Karteneditor“.
