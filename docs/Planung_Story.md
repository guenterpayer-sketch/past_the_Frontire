# Planung Story/Kampagne

Stand: 19.10.2026, Story-Chat (Branch `claude/zen-sagan-9yn0le`). Nur Planung, noch nichts gebaut.

## Entscheidungen des Nutzers (19.10.2026)

| Thema | Entscheidung |
|---|---|
| Art der Story | **Sandbox mit Hauptstrang**, dazu **lose Ereignisketten** und **Kampagnenziele**. Keine feste Kapitelfolge. Inspiration (nicht Nachbau): MegaTraveller (PC, um 1990): freie Sandbox, die Hauptgeschichte läuft nebenher. |
| Ton | **Gemischt**: rauer Grundton, einzelne düstere oder heitere Stränge. |
| Kerne des Hauptstrangs | **Schulden & Vergangenheit**, **Verschwörung**, **Psi-Geheimnis**. „Grenze erkunden“ nicht als Kern, aber durch neue Sektoren ohnehin im Spiel. |
| Gegenspieler | **Eine Fraktion darf Gegner im Hauptstrang sein.** |
| Fraktionen | **Nur Kulisse**: kein Ruf-System. |
| Fraktions-Oberarten | **Ja, mit Story V1**: Oberarten nach Vorschlag des Nutzers (Konzern, Söldner, Piraten, Syndikat, Kult) mit je 2–3 benannten Fraktionen, **eigene Fraktion(en) für die Story**, **andere benannte Fraktionen je Sektor**, **Unterfraktionen spielerisch unterschiedlich** (Waffen, Psi, Truppen). |
| Sektorkarte | **Muss angepasst werden**: **mehrere Sektoren** (der Hauptstrang und das freie Spiel führen in weitere Sektoren) und **mehr/größere Systeme** (mehr Systeme, mehr Orte je System). |
| Einstieg der Story-Einsätze | Alle vier Wege: **Auftragsliste** (Story-Aufträge **ohne Zeitlimit**), **Story-Orte auf der Karte**, **Reise-Ereignisse**, **Kontakte im Hafen**. |
| Darstellung | **Textfenster mit Wahl**, **Fertigkeitsproben in Szenen**, **Logbuch**. **Bilder** später über einen Bildgenerator (Nutzer nennt Artisly.ai); Claude liefert die **Prompts**. |
| Speicherstand | **Im Spielstand-Slot** (keine globalen Freischaltungen). |
| Ende | **Offen fortlaufend**: kein Ende, der Hauptstrang wird in Kapiteln erweitert. |
| Ziele | **Kampagnenziele** mit Anzeige; **Scheitern möglich** als **Rückschlag** (harte Folgen, aber kein Game Over). |
| Umfang V1 | **Story-Engine + Logbuch**, **erstes Kapitel**, **2–3 Ereignisketten**, **Oberarten + Sektoren**. |

Hinweis zu Artisly.ai: Den Dienst kenne ich nicht genau. Die Prompts schreibe ich allgemein (Motiv, Stil, Format) und gebunden an keinen bestimmten Generator.

## Vorschlag: Aufbau

### Story-Engine (Story-Modul, ohne Grafik)

- **Szene** (`StoryScene`, Daten als `.tres` oder JSON in `godot/data/story/`): Text, optional Bild-ID, Liste von **Wahlmöglichkeiten**. Eine Wahl hat: Bedingungen (Flags, Credits, Fertigkeit vorhanden, Crewmitglied an Bord), optional eine **Probe** (Fertigkeit, Modifikator, wer würfelt: beste Crew/gewählt) und **Folgen** je Ergebnis (Flag setzen, Credits/Material/Proviant, EP, Verwundung, nächste Szene, Einsatz starten, Logbuch-Eintrag, Ziel ändern).
- **Probe**: nutzt die vorhandenen Regeln (W100 offen, Ergebnisstufen wie in `docs/Skillsystem.md`), EP für die benutzte Fertigkeit wie sonst.
- **Kette** (`StoryChain`): Hauptstrang-Kapitel oder Ereigniskette. Hat einen **Auslöser** (Auftragsliste, Ort, Reise-Ereignis, Hafenkontakt), Bedingungen (Tag, Sektor, Flags) und Schritte.
- **Zustand** (`StoryState`, im Spielstand): Flags, aktive Ketten mit Schritt, erledigte Ketten, Logbuch-Einträge, Kampagnenziele, bekannte Story-Orte.
- **Einsatz aus der Story**: eine Szene kann einen Boden- oder Raumkampf als Auftrag erzeugen (Fraktion, Schwierigkeit, Karte, Startlage, besondere Gegner). Ergebnis (Sieg/Niederlage/Rückzug) führt zur Folgeszene.
- **Rückschlag**: Scheitern löst Folgen aus (z. B. Credits/Schiffsteile gepfändet, Crewmitglied gefangen, Schulden steigen), die Kette läuft mit einem anderen Zweig weiter.

### Oberfläche (Story-Modul)

- **Szenenfenster** auf `Modal`: Text, optional Bild, Wahlknöpfe, Probenergebnis.
- **Logbuch**: Hinweise, Verlauf, offene Story-Aufträge, Kampagnenziele. Aufruf vom Hub (Vorschlag: Brücke und Burgermenü).
- Größere UI erst als Mockup (CLAUDE.md).

### Sektoren und Fraktionen

- **Oberarten**: neuer Datentyp oder Feld in `FactionData` (`kind`: Konzern, Söldner, Piraten, Syndikat, Kult, Story). Die vier vorhandenen Fraktionen werden zugeordnet (Vantar → Konzern, Leeres Licht → Kult, Rote Sonne → Söldner, Kessler → Syndikat oder Piraten, offen).
- **Fraktionen je Sektor**: jeder Sektor zieht aus jeder Oberart eine oder mehrere benannte Fraktionen.
- **Mehrere Sektoren**: Sektoren über Sprungpunkte verbunden; ein neuer Sektor wird beim ersten Betreten erzeugt (Seed). Der Spielstand enthält alle bekannten Sektoren.
- **Größere Systeme**: mehr Systeme je Sektor und mehrere Orte je System (Station, Planet, Wrack …); Story-Orte sind solche Orte.

## Schnittstellen-Vorschlag für die anderen Module

Grundsatz wie bisher: Module tauschen nur Daten aus. Das Story-Modul verändert keine fremden Dateien, sondern bekommt Einhängepunkte.

### Hub

| Was | Vorschlag |
|---|---|
| Speicherstand | `HubState.story: Dictionary` (vom Story-Modul geschrieben/gelesen), in `to_dict`/`from_dict` durchreichen. |
| Auftragsliste | Story-Aufträge als Angebot mit `"story": "<ketten-id>:<schritt>"`, **kein Ablauf** (`expires` leer/−1) und Markierung in der Liste. Story liefert über `Story.offers(g)` die Angebote. |
| Sternenkarte | Story-Orte und Sprungpunkte markieren (`Story.markers(g, sector)`); Ankunft in einem System ruft `Story.on_arrive(g, system)` auf, das eine Szene zurückgeben kann. |
| Reise | in `_travel` je Reisetag `Story.roll_travel_event(g, day)` neben dem Feindkontakt; Rückgabe: Szene oder nichts. |
| Raumhafen | Bereich „Kontakte“: `Story.contacts(g, system)` liefert Personen mit Szenen. |
| Tagesende | `Story.on_day(g)` (Fristen in Ketten, Schulden). |
| Ressourcen | Story-Folgen ändern Credits, Material, Proviant, Hülle, Lager über eine kleine Funktion des Hub (z. B. `HubState.apply_story(effects)`), damit die Regeln dort bleiben. |
| Logbuch | Knopf auf der Brücke und im Burgermenü. |
| Sektorkarte | mehrere Sektoren, Sprungpunkte, größere Systeme mit Orten: **Umbau in `core/sector.gd` und der Sternenkarte durch den Hub**, das Story-Modul liefert nur die Anforderungen. |

### Bodenkampf

- Story-Einsätze über das vorhandene `Mission`-Objekt, erweitert um: feste Karte (eigene Karte aus `user://maps/` oder `res://`), feste Gegnerliste/benannte Gegner (Anführer), Startlage, Text im Briefing, optional Siegbedingung (z. B. Person retten, Gegenstand bergen, Anführer ausschalten). Ob Siegbedingungen jenseits „alle Gegner“ in V1 nötig sind, ist offen.
- `MissionResult` zurück wie bisher; zusätzlich (wenn Siegbedingungen kommen) welche Bedingung erfüllt ist.

### Raumkampf

- Story-Einsätze über `space_ctx` mit fester Gegnerzusammenstellung, Fraktion und Text; Ergebnis (Sieg, Flucht, Kapitulation, Entern) zurück an die Story.

### Charakter

- Proben in Szenen brauchen: bester Wert einer Fertigkeit in der Crew an Bord, Wurf und EP-Gutschrift für die benutzte Fertigkeit (wie im Kampf). Vorschlag: kleine Funktion im Charakter-Modul, die das Story-Modul aufruft.
- Optional später: Story-Crewmitglieder (feste Personen, die anheuern) über `Campaign.hire()`.

### Fraktionen (Bodenkampf + Hub)

- `FactionData` um Oberart erweitern, neue benannte Fraktionen je Oberart mit eigenen Gegnern (Bodenkampf für Einheiten, Raumkampf für Schiffsvorlagen). Wer die neuen Fraktionen anlegt, verteilt der Koordinator.

## Bilder

- Liste der Bilder (Szenen, Hafenkontakte, Story-Orte) mit Prompts entsteht zusammen mit den Inhalten von Kapitel 1. Ablage-Vorschlag: `godot/art/story/<id>.png`; ohne Bild zeigt das Szenenfenster nur Text.

## Offene Punkte (vor dem Bauen klären)

1. **Inhalt Kapitel 1**: Ausgangslage (wessen Schulden, welche Vergangenheit), Gegnerfraktion, Einsätze, Szenen. Noch keine Inhalte geschrieben (Absprache „erst klären, dann bauen“).
2. **Story-Fraktion(en)**: Name, Oberart, Rolle in Verschwörung/Psi-Linie.
3. **Kampagnenziele**: welche genau (z. B. Schulden, Schiffsausbau, Crew-Ränge), Anzeige wo.
4. **Rückschläge**: welche Folgen konkret und wie hart.
5. **Ereignisketten**: Themen der 2–3 Ketten für V1.
6. **Sektoren**: Anzahl Systeme und Orte, wie man in einen neuen Sektor kommt (Sprungtor, Story-Freischaltung, Treibstoff), ob man zurückreisen kann.
7. **Kessler**: Oberart Syndikat oder Piraten.
8. **Siegbedingungen** im Bodenkampf für Story-Einsätze in V1 ja/nein.
9. **Datenformat** der Szenen (`.tres` im Editor bearbeitbar oder JSON/Text, leichter zu schreiben). Vorschlag: Text-/JSON-Datei, weil Szenen viel Text haben.
10. Mockup für Szenenfenster und Logbuch.

## Vorschlag Reihenfolge

1. Offene Punkte 1–9 mit dem Nutzer klären, Mockup Szenenfenster/Logbuch.
2. Story-Engine + Logbuch + Speicherstand (Story-Modul) mit Test-Kette.
3. Koordinator verteilt: Hub-Einhängepunkte, Oberarten/Fraktionen, Sektorumbau, Story-Einsätze im Boden-/Raumkampf.
4. Kapitel 1 und Ereignisketten als Inhalte, Bild-Prompts.
