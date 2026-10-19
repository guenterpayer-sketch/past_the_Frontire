# Modul Story/Kampagne

- **Branch:** noch offen – der Story-Chat trägt seinen Branchnamen hier und in `docs/module/README.md` ein (bzw. der Nutzer meldet ihn dem Koordinator).
- **Zuständig für (Vorschlag, mit dem Koordinator abstimmen):** eigene Dateien, z. B. `godot/core/story_*.gd`, `godot/ui/story_*.gd`, `godot/data/story/`, Planung `docs/Planung_Story.md`. Keine Dateien anderer Module umbauen; nötige Anbindungen (Hub: Aufträge, Sternenkarte, Berichte; Bodenkampf/Raumkampf: besondere Einsätze) als Schnittstelle vorschlagen und über den Koordinator beauftragen lassen.

## Grundlagen (in `main`)

- Gesamtstand: `CLAUDE.md` „Stand“. Spielwelt bisher: zufälliger Sektor mit Fraktionen (`core/sector.gd`, `data/missions/*.tres`: Vantar-Konzern, Kult des Leeren Lichts, Söldner der Roten Sonne, Kesslers Schmugglerbande), Aufträge mit Auftragsarten (Boden, Blockade, Abfangen, Eskorte; `core/mission.gd`, `core/space_events.gd`), Spieltage, Raumhafen, Crew mit Roster.
- Ideen des Nutzers für später: Fraktionen mit Ober- und Unterarten (`docs/Planung_Kampfkarten.md`), eigene Jäger/Hangar (V2).
- Regeln: `docs/Skillsystem.md`, `docs/Raumkampf.md`. Moduldateien der anderen Module: `docs/module/`.

## Schnittstellen

- Noch festzulegen (Auftrag 1).

## Stand

- (19.10.2026) Moduldatei angelegt.

## Aufträge vom Koordinator

### Auftrag 1 (19.10.2026): Planung, noch nicht bauen

- Mit dem Nutzer klären (Auswahl-Buttons, am Ende jeder Runde eine Freitext-Frage): Art der Story (feste Kampagne, lose Ereignisketten, offene Sandbox mit Zielen …), Ton und Setting, Rolle der Fraktionen, wie Story-Einsätze ins bestehende Spiel kommen (Sternenkarte, Aufträge, Ereignisse auf Reisen), Fortschritt und Speicherstand, Ende/Ziele, Umfang V1.
- Ergebnis: `docs/Planung_Story.md` mit Entscheidungen, Vorschlägen, offenen Punkten und einem Schnittstellen-Vorschlag (was Hub, Bodenkampf, Raumkampf, Charakter liefern müssten). Bei Bedarf Mockup.
- Danach melden; der Koordinator verteilt die Anbindungen an die anderen Module.
