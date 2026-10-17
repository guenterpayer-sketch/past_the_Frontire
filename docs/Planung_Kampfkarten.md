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
