# Planung Story/Kampagne

Stand: 19.10.2026, Story-Chat (Branch `claude/zen-sagan-9yn0le`). Auftrag 1: Planung. Auftrag 2: offene Punkte geklärt, Story-Engine, Logbuch und `StoryState` mit Test-Kette gebaut (noch nicht im Hub angebunden).

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

## Entscheidungen des Nutzers, zweite Runde (19.10.2026)

| Thema | Entscheidung |
|---|---|
| Ausgangslage Kapitel 1 | Alle vier: **Schiff auf Pump**, **Erbe des Kapitäns**, **Alter Verrat**, **Fracht verloren**. |
| Gläubiger | **Zufällig beim neuen Spiel**, ebenso die Ausgangslage. Umsetzung: **Bausteine kombiniert** (4 Ausgangslagen × 3 Gläubiger: Syndikat, Konzern-Bank, Einzelperson/Kredithai), die Szenen haben Textbausteine je Variante, der Ablauf bleibt gleich. |
| Story-Fraktionen | Drei: **Geheimbund**, **Psi-Orden**, **Konzern-Projekt**. Sie können sich gegenseitig in die Quere kommen oder zusammenarbeiten. |
| Gegner in Kapitel 1 | **Alle** möglich: Gläubiger, Story-Fraktionen, bestehende Fraktionen. |
| Kampagnenziele | **Schulden tilgen**, **Schiffsausbau**, **Crew-Ränge**, **Sektoren/Orte**. |
| Rückschläge | Alle: **Pfändung**, **Schuld steigt**, **Crew gefangen** (Befreiung als Einsatz), **Verfolgung** (mehr Feindkontakte, bis man zahlt). |
| Ereignisketten V1 | Drei: **Notruf/Wrack**, **Blinder Passagier**, **Schmuggelware**. **Crew-Vergangenheit** kommt später (braucht das Charakter-Modul). |
| Sektoren | **Sprungtore am Rand**, Kosten als **Nutzungsgebühr** (Credits, kein Treibstoff), dazu **Erlaubnis/Papiere** möglich, **Rückreise möglich**. |
| Größe | **15–20 Systeme** je Sektor, **2–4 Orte** je System, das Netz **besser vernetzt** (heute können die Routen fast einen Kreis bilden, dann werden Reisen sehr lang). |
| Kessler | Oberart **Syndikat**. |
| Siegbedingungen Bodenkampf | **Später.** In V1 sind Story-Einsätze normale Kämpfe mit eigenem Text und eigenen Gegnern. |
| Datenformat | **JSON-Dateien** in `godot/data/story/`. |
| Proben in Szenen | **Der Spieler wählt, wer würfelt**, der Beste an Bord ist vorausgewählt. Es zählen **nur vorhandene Fertigkeiten** (z. B. Verhandeln, Gassenwissen, Handeln, Computer, Pilot, Erste Hilfe, Psi-Listen), es kommen keine neuen dazu. |
| Bedingungen für Wahlen | **Fertigkeitsrang**, **Story-Flags**, **Ressourcen**, **Psi-Begabung** (eine Psi-Liste an Bord). |
| Mockup | Szenenfenster und Logbuch **passen** (Artifact „Frontire Story-Mockup“). Umsetzung in Godot nach zwei Fehlversuchen im Stil der vorhandenen Fenster abgenommen (19.10.2026). |

## Story-Fraktionen (Entscheidungen des Nutzers, 19.10.2026)

Oberart aller drei: eigene Oberart **„Story“** (außerhalb von Konzern, Söldner, Piraten, Syndikat, Kult).

| Fraktion | Was sie will / ist | Im Kampf (für die Fraktionsdaten im Bodenkampf) |
|---|---|---|
| **Die Stille Hand** (Geheimbund) | Macht über die Sektoren, hütet ein altes Geheimnis, will Psi kontrollieren, nutzt Geld und Schulden als Werkzeug. Lenkt Fraktionen verdeckt. | **Angeheuerte**: kämpft kaum selbst, schickt gemischte Söldner, dazu wenige eigene Agenten (Pistolen, Tarnung). |
| **Die Wacht von Seraph** (Psi-Orden) | **Gespalten** in zwei Flügel: die **Hirten** (sammeln und schützen Begabte, bilden sie aus) und die **Klingen** (sehen unkontrolliertes Psi als Gefahr und jagen Begabte). | **Psi-lastig**: viele Psi-Nutzer (Angriff, Schutz), Nahkampfklingen. |
| **Abteilung 9** (Konzern-Projekt) | Erforscht **Psi als Waffe** (Psi-Begabte als Soldaten). Gehört zu einem Konzern, der **je Spiel ausgewürfelt** wird: **Vantar-Konzern** oder **Semidrug Inc.** (neuer Konzern der Oberart Konzern). | **Psi-Soldaten**: gezwungene Psi-Begabte, dazu schwer gepanzerte Wachen. |

Beziehungen (alle gewählt): Die Stille Hand **lenkt und finanziert Abteilung 9** heimlich. Die **Klingen** arbeiten mit Abteilung 9 zusammen und liefern Begabte. Die **Hirten** bekämpfen die Stille Hand. Darüber hinaus **wechselnde Bündnisse** je nach Lage. Der **Gläubiger** hängt **manchmal** mit der Stillen Hand zusammen, je nach ausgewürfeltem Gläubiger (wird in Kapitel 1 festgelegt).

Für die Bausteine: neue Gruppe `konzern` (vantar, semidrug), ausgewürfelt beim Spielstart wie Ausgangslage und Gläubiger.

Auftrag an den Bodenkampf (über den Koordinator): Fraktionsdaten für die drei Story-Fraktionen und für Semidrug Inc. anlegen (Einheiten wie oben). Die Raumkampf-Seite (Schiffsvorlagen) wird bei Bedarf für Kapitel 1 nachgereicht.

## Kapitel 1 und Ereignisketten (Entscheidungen des Nutzers, Auftrag 3, 19.10.2026)

| Thema | Entscheidung |
|---|---|
| Art | **Ganz erzeugt**: Story-Schritte entstehen aus Vorlagen (wer, was, wo). Fest sind nur **Anfang** und **Ende**. Das gilt auch für die drei Ereignisketten. |
| Anfang | Der Gläubiger meldet sich **nach ein paar Tagen** freien Spiels. |
| Schulden | **5 000 Cr**, Rate **500 Cr je 10 Tage**. |
| Verpasste Rate | Rückschlag **zufällig** aus: Schuld steigt, Pfändung, Crew gefangen, Verfolgung. |
| Fortschritt | **Spuren sammeln**: erzeugte Schritte geben bei Erfolg eine Spur. Bei Fehlschlag gibt es keine Spur, und ein neuer Schritt wird erzeugt. Bis zum Finale braucht es **3–4 Spuren** (je Spiel ausgewürfelt). |
| Arten von Schritten | **Person befreien/holen** (Boden), **Daten/Ware bergen** (Boden), **Schiff abfangen** (Raum, ggf. Entern), **Gespräch/Probe** (ohne Kampf). |
| Gegner in Schritten | Story-Fraktionen (Abteilung 9, Klingen der Wacht, Angeheuerte der Stillen Hand) **und passende normale Fraktionen** der Gegend. |
| Einstieg der Schritte | alle vier Wege: Hafenkontakt, Story-Ort, Auftragsliste (ohne Zeitlimit), Reise-Ereignis. |
| Ende Kapitel 1 | **Rettung führt zur Spur**: Die Crew befreit eine Psi-Begabte aus Abteilung 9 und findet dabei die Spur zur Stillen Hand. |
| Die Begabte | **Der Spieler entscheidet** im Finale: anheuern, an die Hirten der Wacht übergeben oder verkaufen (an Abteilung 9 bzw. die Klingen). **Jede Entscheidung führt zu einer anderen Linie in Kapitel 2.** |
| Ereignisketten | **Notruf/Wrack**: Ausgänge Überlebende, Beute, Falle, Story-Spur (Wrack von Abteilung 9). **Blinder Passagier**: Flüchtling, Psi-Begabte(r), Dieb/Saboteur, Harmloser. **Schmuggelware**: Angebot im Hafen, Zoll/Kontrolle, Käufer verrät, Ware ist lebendig. Alle Ausgänge möglich, zufällig gewählt. |
| Kampagnenziele | **Story-Schlüssel**: Schiffsausbau, Crew-Ränge und Sektoren/Orte werden mitgezählt. Bestimmte Story-Schritte öffnen sich erst ab einem Stand, z. B. das Finale ab einer Ausbaustufe. Das Logbuch zeigt, was fehlt. Keine eigene Belohnung. |
| Crew gefangen | Die Figur ist **gesperrt, bis sie befreit ist** (erzeugter Befreiungs-Einsatz) oder die Schuld bezahlt ist. |
| Verfolgung | **Kopfgeldjäger**: sicher ein Hinterhalt beim nächsten Hafenbesuch. |
| Lager | **Ja, in V1**: Szenen können Gegenstände im Schiffslager prüfen (z. B. ein Medikit) und Ausrüstung ins Lager geben oder daraus nehmen. Umsetzung über `Stock.count/add/take`, keine Hub-Änderung nötig. |
| Bilder | Stil **Comic/Graphic Novel** (klare Linien, Schraffur, kräftige Schatten). |

## Entwurf: Story-Generator (noch nicht gebaut)

- **Vorlagen** in `data/story/vorlagen/`: je Art von Schritt eine Datei mit Varianten (Ziel, z. B. Zeuge/Begabte/Informant oder Datenkern/Fracht/Beweise; Kartentyp; Gegnergruppe; Einstieg) und Textbausteinen mit Platzhaltern (`{ziel}`, `{system}`, `{gegner}`, `{kontakt}`, `{glaeubiger}`, `{konzern}`).
- **Erzeugte Ketten** werden wie geschriebene Ketten behandelt (gleiches Format) und **im Spielstand gespeichert** (`StoryState.generated`), damit sie nach dem Laden gleich bleiben. Die Engine (`view`, `choose`, Folgen, Einsätze) bleibt, wie sie ist.
- **Rahmen von Kapitel 1** (`data/story/kapitel1.json`): Anfangsszene mit dem Gläubiger (Auslöser „start“ ab Tag 3), Ziel „Schulden“ mit wiederkehrender Rate, Spurenzähler, Finale (geschrieben, mit den drei Wahlen und Flags für Kapitel 2). Ist kein Schritt offen, erzeugt der Rahmen den nächsten.
- **Neue Engine-Teile:** wiederkehrende Rate (Ziel mit Betrag und Abstand), zufälliger Rückschlag, Bedingungen und Folgen für Lager-Gegenstände (`item`), Story-Schlüssel als Bedingung (`ship_level`, `crew_ranks`, `sectors`).
- **Ereignisketten:** je Kette eine Vorlage mit Eckpunkten (z. B. Wrack: anfliegen → untersuchen → Ausgang). Der Ausgang wird zufällig gewählt, Kampf und Proben über die vorhandenen Folgen.

### Nötige Anbindungen anderer Module (Vorschlag)

- **Hub:** Kopfgeldjäger-Hinterhalt beim Hafenbesuch (Story-Einsatz bei `on_arrive` im Hafen). Werte für die Story-Schlüssel: Summe der Ausbaustufen aus `HubState.upgrades`, später Sektoren und Orte nach dem Sektorumbau.
- **Charakter:** Status „gefangen“ (Figur gesperrt wie verwundet, mit Text „gefangen“), außerdem eine Psi-Begabte als anheuerbare Figur für das Finale (über `Campaign.hire`).
- **Bodenkampf:** Fraktionsdaten für die drei Story-Fraktionen und Semidrug Inc.

## Gebaut (Auftrag 2)

| Datei | Inhalt |
|---|---|
| `core/story_data.gd` (**StoryData**) | lädt die Ketten aus `data/story/*.json` und die Bausteine aus `bausteine.json`, `validate(kette)` prüft Szenen, Sprünge, Fertigkeiten, Psi-Listen, Bedingungen und Folgen |
| `core/story_state.gd` (**StoryState**) | Fortschritt: `vars` (ausgewürfelte Bausteine), `flags`, `chains`, `goals`, `logbook`, `mission`; `create(rng)` würfelt die Bausteine, `to_dict()`/`from_dict()` |
| `core/story.gd` (**Story**) | Engine: `start`, `view`, `roller_options`, `choose`, Bedingungen, Folgen, Ziele, Texte mit Bausteinen, Einhängepunkte für den Hub (unten) |
| `ui/story_dialog.gd` (**StoryDialog**) | Szenenfenster nach Mockup, gestaltet wie Feindkontakt/Krankenstation: goldener Titel, Zeile mit Art, Kette und Tag, oben Bild (`res://art/story/<bild>.png`, sonst Platzhalter) und Text (scrollt) mit Abschnitt ZIELE, darunter WAHL als Karten mit Beschreibung und goldenem Knopf (gesperrte nennen die Bedingung), „Wer würfelt?“ in der Karte (Crew mit Buchstabenkästchen und Bonus), Ergebnis als Karte, Fußleiste „Logbuch“ und „Weiter“ |
| `ui/story_log.gd` (**StoryLog**) | Logbuch, gestaltet wie die Enzyklopädie: Erklärzeile, links die Reiter mit Anzahl, rechts Überschrift und Karten (Aufträge, Hinweise, Ziele mit Balken und Frist, Verlauf) |
| `data/story/` | `bausteine.json` (4 Ausgangslagen, 3 Gläubiger, nur Namen), `test_kette.json` und `test_ort.json` (Test-Ketten, Platzhaltertexte, im Spiel nicht angeboten) |
| `tests/test_story.gd` | Tests ohne Grafik (Daten, Texte, Bedingungen, Proben, Ziele, Rückschlag, Einsatz, Orte, Speichern) |
| `tests/story_demo.tscn` | Demo mit der Test-Kette (F6), Screenshots mit `-- --shot` |

Proben nutzen `Voyage.check()` (W100 offen + Gesamtbonus + Schwierigkeit, EP wie bei den Reiseproben: Erfolg voll, sonst halb, Patzer 0). Eine eigene Probenfunktion im Charakter-Modul ist damit nicht nötig.

## Datenformat (JSON)

Eine Datei je Kette:

```json
{
  "id": "…", "kind": "haupt | kette", "title": "…", "test": false,
  "trigger": {"type": "start | auftrag | ort | reise | kontakt | keiner", "requires": [Bedingungen]},
  "contact": "Name des Kontakts im Hafen (nur bei kontakt)",
  "start": "szenen-id",
  "goals": [{"id": "schulden", "name": "Schulden tilgen", "value": 0, "target": 6000, "due_in": 5, "fail": "szenen-id"}],
  "scenes": {
    "szenen-id": {"title": "…", "image": "bild-id", "text": Text,
      "choices": [{"text": Text, "requires": [Bedingungen], "hide_locked": false,
        "check": {"skill": "verhandeln", "diff": "mittel", "mod": 0},
        "effects": [Folgen], "next": "szenen-id",
        "results": {"erfolg": {"text": Text, "effects": [Folgen], "next": "…"}, "fehlschlag": {…}}}]}
  }
}
```

- **Text**: Zeichenkette, Liste von Teilen oder Auswahl `{"var": "ausgangslage", "pump": "…", "*": "sonst"}`. Platzhalter: `{gruppe}` (Name des Bausteins), `{gruppe.feld}`, `{wuerfler}`.
- **Ergebnisstufen** in `results`: herausragend, erfolg, teilerfolg, fehlschlag, patzer. Fehlt eine Stufe, gilt herausragend → erfolg, teilerfolg und patzer → fehlschlag.
- **Bedingungen**: `{"flag"}`, `{"not_flag"}`, `{"var", "is"}`, `{"skill", "rank"}` (jemand an Bord hat den Rang), `{"psi": "lWahrnehmung"}`, `{"credits"}`, `{"material"}`, `{"provisions"}`, `{"fuel"}` (mindestens). Optional `reason` als Anzeigetext.
- **Folgen**: `flag`, `unflag`, `var`/`value`, `credits`/`material`/`provisions`/`fuel` (±), `hint` (Logbuch-Hinweis), `log` (Verlauf), `goal` mit `add`/`target`/`due`/`done`, `goal_new`, `mission` (Einsatz mit Folgeszenen `sieg`/`niederlage`/`rueckzug`), `end` (fertig/gescheitert), `chain` (andere Kette starten), `reveal` (Kette bekannt machen, bei Auslöser „ort“ mit Story-Ort).
- Ohne `next` und ohne `end` ist die Kette nach der Wahl fertig.
- **Rückschlag**: Läuft die Frist eines Ziels ab, springt die Kette zu dessen Szene `fail` (z. B. Pfändung).

## Schnittstellen (gebauter Stand)

Grundsatz wie bisher: Module tauschen nur Daten aus. Das Story-Modul ändert keine fremden Dateien. Wo eine Anbindung fehlt, arbeitet es mit einem Stub.

### Hub

| Was | Story-Seite (gebaut) | Hub-Seite (Auftrag) |
|---|---|---|
| Speicherstand | `StoryState.to_dict()` / `StoryState.from_dict(d)`, neues Spiel: `StoryState.create()` | **gebaut** (`main` `6aebcfb`): `HubState.story`, `HubState.story_engine()` hält das Story-Objekt. Der frühere Stub `Story.for_game` ist entfernt. |
| Story-Objekt | `Story.create(state, game)`; `crew()` = `Voyage.available(game)`, `today()` = `game.day` | ein `Story` je Spiel erzeugen und `HubState.story` beim Speichern zurückschreiben |
| Auftragsliste | `Story.offers()` → `[{chain, title, kind}]`, ohne Zeitlimit; Annehmen = `start(chain)` und `StoryDialog.show_on(parent, story, chain)` | markiert in der Auftragsliste (Brücke), ohne Ablauf |
| Sternenkarte | `Story.markers()` → `[{system, chain, title}]`; `Story.on_arrive(system)` → Kette oder "" | Marker zeichnen; bei Ankunft aufrufen und ggf. das Szenenfenster öffnen |
| Reise | `Story.travel_event(rng)` → Kette oder "" (Chance `TRAVEL_CHANCE` je Tag) | in `_travel` je Reisetag neben dem Feindkontakt |
| Raumhafen | `Story.contacts()` → `[{chain, title}]` | Bereich „Kontakte“; Ansprechen = `start(chain)` + Szenenfenster |
| Tagesende | `Story.on_day()` → Ketten mit verpasster Frist (Rückschlag-Szene ist dann aktiv) | nach `advance_days` aufrufen, Szenenfenster öffnen |
| Ressourcen | `Story.add_resource(feld, n)` → tatsächliche Änderung; im Spiel über `HubState.apply_story({feld: n})` | **gebaut**: Credits dürfen unter 0, Material und Proviant nicht, Treibstoff 0 bis Tankgröße |
| Logbuch | `StoryLog.show_on(parent, story)` | Knopf auf der Brücke und im Burgermenü |
| Sektorkarte | Story-Orte zurzeit ein ganzes System (`_pick_place`, Stub) | Umbau in `core/sector.gd` und der Sternenkarte: 15–20 Systeme, 2–4 Orte je System, besser vernetzt, mehrere Sektoren mit Sprungtoren (Nutzungsgebühr, Erlaubnis, Rückreise). Danach Story-Orte als Ort im System. |

### Bodenkampf und Raumkampf

- `Story.pending_mission()` → `{chain, kind (boden/blockade/…), title, difficulty, sieg, niederlage, rueckzug, …}`. Der Hub baut daraus ein Angebot (Bodenkampf über `Mission`, Raumkampf über `space_ctx`) mit Story-Text, Fraktion und festen Gegnern, sobald diese Felder in Kapitel 1 feststehen.
- Ende des Einsatzes: `Story.mission_done("sieg" | "niederlage" | "rueckzug")` → Kette steht auf der Folgeszene, der Hub öffnet das Szenenfenster.
- Eigene Siegbedingungen kommen später.

### Charakter

- Keine neue Funktion nötig: Proben über `Voyage.check()`, Ränge über `Rules.skill_rank()`, Psi über die Listen-Fertigkeiten.
- Später: Story-Crewmitglieder über `Campaign.hire()`, Kette „Crew-Vergangenheit“.

### Fraktionen

- `FactionData` bekommt eine Oberart (Konzern, Söldner, Piraten, Syndikat, Kult), neue benannte Fraktionen je Oberart, Fraktionen je Sektor, spielerisch unterschiedliche Unterfraktionen. Dazu kommen die drei Story-Fraktionen (Geheimbund, Psi-Orden, Konzern-Projekt). Zuordnung: Vantar → Konzern, Leeres Licht → Kult, Rote Sonne → Söldner, Kessler → Syndikat.

## Bilder

- Szenen haben ein optionales Feld `image`; die Datei liegt unter `godot/art/story/<image>.png`. Ohne Datei zeigt das Fenster nur Text.
- Die Bildliste mit Prompts (für einen Bildgenerator, vom Nutzer genannt: Artisly.ai) entsteht zusammen mit den Inhalten von Kapitel 1.

## Offene Punkte

1. **Inhalte**: Ablauf und Eckpunkte geklärt (Abschnitt „Kapitel 1 und Ereignisketten“). Offen: Generator bauen, Vorlagen und Texte schreiben, Werte der Story-Schlüssel (z. B. welche Ausbaustufe für das Finale).
2. ~~Story-Fraktionen~~ erledigt (Abschnitt „Story-Fraktionen“).
3. ~~Kampagnenziele~~ entschieden: Story-Schlüssel. Offen sind nur die Schwellenwerte.
4. ~~Rückschläge~~ entschieden: gefangen bis befreit, Verfolgung durch Kopfgeldjäger. Anbindung siehe Generator-Entwurf.
5. Lager-Gegenstände: entschieden (ja, V1), noch nicht gebaut.
6. Export: JSON-Dateien in `data/story/` müssen beim Export mitgenommen werden (Exportfilter `*.json`), sobald es einen Export gibt.
