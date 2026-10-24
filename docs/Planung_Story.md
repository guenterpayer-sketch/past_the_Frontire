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

## Story-Generator (gebaut, Auftrag 3)

- **`core/story_gen.gd` (StoryGen):** `make(story, vorlage, extra)` baut aus einer Vorlage eine Kette im Format der JSON-Ketten und legt sie in `StoryState.generated` ab. Damit bleibt sie im Spielstand und ist nach dem Laden gleich. `step(story, rahmen)` erzeugt den nächsten Schritt eines Rahmens. Gewürfelt werden die Werte der Vorlage (Ziel, Gegner, Schwierigkeit …), der Einstieg (Kontakt in einem Hafen, Story-Ort, Auftrag, Reise), der Ort, ein Kontaktname und bei Ereignisketten der Ausgang.
- **Vorlagen** (`data/story/vorlagen/`):
  - Schritte: `befreien`, `bergen`, `abfangen` (Raumkampf: abfangen oder Blockade mit Entern), `gespraech` (nur Proben, Bestechen, Psi).
  - Rückschlag: `hinterhalt` (Kopfgeldjäger).
  - Ereignisketten: `wrack` (Überlebende, Beute, Falle, Spur), `passagier` (Flüchtling, Begabte, Dieb, Ausreißer), `schmuggel` (Zoll, Verrat, lebende Fracht).
  - Platzhalter: `{wert}`/`{wert.feld}`, `{gegner}`, `{gegner_id}`, `{diff}`, `{diff_leichter}`, `{diff_schwerer}`, `{system}`, `{kontakt}`, `{einstieg}`.
- **Kapitel 1** (`data/story/kapitel1.json`):
  - Rahmen `kapitel1`: startet ab Tag 3, mit den Zielen „Schulden“ (5 000, Rate 500 alle 10 Tage) und „Spuren“ (3–4).
  - `glaeubiger_rate`: wiederholbarer Hafenkontakt „Rate zahlen“.
  - Rückschläge `rueck_zins` (+10 % der Restschuld), `rueck_pfaendung` (−25 % Credits, −2 Material, ein Stück aus dem Lager), `rueck_gefangen` (Crewmitglied gefangen, Befreiung wird erzeugt) und `rueck_verfolgung` (Kopfgeldjäger im nächsten Hafen).
  - Finale `kapitel1_finale`: Station von Abteilung 9, Begabte „Lio“, drei Wahlen mit den Flags `k2_anheuern`, `k2_hirten`, `k2_verkauft` für Kapitel 2.
- **Ablauf:** Ein erfolgreicher Schritt gibt eine Spur, ein Fehlschlag keine; in beiden Fällen wird der nächste Schritt erzeugt (höchstens einer offen). Ereignisketten wie Wrack, Passagier und Schmuggel können ebenfalls eine Spur geben. Sind die Spuren voll, wird das Finale bekannt. Es erscheint in der Auftragsliste, sobald die Bedingungen erfüllt sind; bis dahin zeigt das Logbuch, was fehlt.
- **Neu in der Engine:**
  - Bedingungen `day`, `item`/`count`, `ship_level`, `crew_ranks`, `sectors`, `goal_open`.
  - Folgen `item` (`add`/`take`), `item_random`, `credits_pct`, `goal` mit `pay` und `target_pct`, `step`, `step_done`, `step_failed`, `spur`, `capture`, `recruit`.
  - Ziele mit `target_rand`, `rate`/`every`/`backlash`; Ketten mit `repeat`; Dateien mit mehreren Ketten unter `chains`.
  - Gefangene fehlen in `Story.crew()`. Sind die Schulden getilgt, kommen sie frei.
- **Eigener Zufall:** Die Story würfelt mit einem eigenen Generator (`Story.rng`), damit sie die Zufallsfolge von Hub und Kampf nicht verschiebt.
- **Häufigkeiten:**
  - Story-Schritt mit Einstieg „Reise“: 45 % je Reisetag.
  - Ereigniskette Wrack oder Passagier: 8 % je Reisetag, wenn keine offen ist.
  - Schmuggel-Kontakt: 25 % je Hafenankunft, wenn keiner offen ist.
  - Diese Werte sind vorläufig und noch nicht mit dem Nutzer abgestimmt.
- **Vorschlag, noch zu bestätigen:** Das Finale braucht **Schiffsausbau 2** (Summe der Ausbaustufen).
- **Gegner-Fraktionen (Auftrag 4):** Die Story nutzt die Fraktionen des Bodenkampfs: `abteilung_9`, `wacht_klingen`, `wacht_hirten`, `stille_hand`, dazu `aasgeier` (Plünderer), `semidrug` und `konzern` (Vantar). `tests/test_story.gd` (`_test_faction_ids`) prüft, dass jede genannte Fraktion als Datei vorhanden ist. Der Ersatz (`fallback` in `StoryGen.GEGNER`) greift nur noch, wenn eine Datei fehlt.
- **Hirten als Gegner (Entscheidung des Nutzers 19.10.2026: „selten“):** Die Hirten der Wacht kommen erst als Gegner vor, wenn die Crew gegen Begabte gehandelt hat. Das sind drei Wahlen: Lio verkaufen, die junge Begabte an die Klingen verraten, lebende Fracht abliefern. Jede setzt das Flag `hirten_feind`. Danach stehen die Hirten mit in der Gegnerliste von Befreiung, Bergung und Abfangen.
- **Bilder:** Liste und Prompts in `docs/Story_Bilder.md`.

### Nötige Anbindungen anderer Module

- **Hub:**
  - Kopfgeldjäger und Schmuggel-Kontakte laufen über das vorhandene `on_arrive`. Die Kontakte erscheinen über `contacts()`, das jetzt nur Kontakte des Hafens liefert, in dem das Schiff liegt.
  - Offen: Der Story-Einsatz sollte die Kartenart aus der Vorlage übernehmen; heute zufällig.
  - Offen: Gefangene Crew (`Story.state.captured`, Character.id als Text) muss in Truppwahl, Reiseposten und Krankenstation gesperrt sein. Heute fehlt sie nur bei Proben in Szenen.
  - Erledigt (Auftrag 5): `Story.sectors()` liest `HubState.known_sectors`.
- **Charakter:**
  - Status „gefangen“ (gesperrt wie verwundet, mit Text „gefangen“).
  - Eine Psi-Begabte „Lio“ als Figur, wenn `state.recruits` den Eintrag `begabte` enthält. Anheuern über `Campaign.hire`.
- **Bodenkampf:** erledigt (Fraktionen `abteilung_9`, `wacht_klingen`, `wacht_hirten`, `stille_hand`).
- **Offene Hub-Punkte** (gehen über den Koordinator an den Hub, sobald dessen Sektorumbau in `main` liegt; Stand 19.10.2026):
  1. Kartenart des Story-Einsatzes aus der Vorlage übernehmen (heute zufällig).
  2. Gefangene Crew (`Story.state.captured`) in Truppwahl, Reiseposten und Krankenstation sperren.
  3. ~~Story-Schlüssel `sectors`~~: erledigt auf Story-Seite (Auftrag 5), `Story.sectors()` = Zahl von `HubState.known_sectors`.
  4. Story-Orte mit Sektor: Story-Seite gebaut (Auftrag 5, Abschnitt „Story-Orte mit Sektor und Ort“). Hub-Seite offen: `on_visit` in der Systemansicht aufrufen, Story-Orte dort zeigen, `on_arrive(sector, system)` mit Sektor aufrufen.

### Boss am Ende einer Kette (gebaut, Auftrag 24.10.2026)

Entscheidungen des Nutzers (24.10.2026):
- **Welche Ketten:** Finale von Kapitel 1 und Hinterhalt (Kopfgeldjäger) **immer**. Story-Schritte (Befreien, Bergen, Abfangen) und Ereignisketten (Passagier, Schmuggel, Wrack) **zufällig mit 30 %**. Gespräch, Rate, Rückschläge und der Rahmen haben keinen Kampf und bleiben ohne Boss. Im Schmuggel ist die Zollstreife nie ein Boss-Kampf (dort hängt der Boss nur am Verrat; im Schnitt also seltener als 30 %).
- **Form:** Der vorhandene entscheidende Kampf wird zum Boss-Kampf. Keine neuen Szenen, keine neuen Bilder.
- **Boden oder Raum:** wie der Kampf heute. Abfangen im Raum mit Boss-Schiff, alles andere am Boden.
- **Namen:** Name mit Titel, Frauen und Männer gemischt, je Gegnergruppe aus `StoryGen.BOSSE` (Abteilung 9, Klingen, Hirten, Stille Hand, Plünderer, Gläubiger, Kopfgeldjäger, sonst „lokal“). Finale: fest „Direktorin Kessa Vohl, Leiterin der Station“. Im Raum ist `boss_name` der Schiffsname aus `StoryGen.BOSS_SCHIFFE` (der Raumkampf benennt damit das Boss-Schiff; das ist meine Annahme zur Bedeutung des Felds, laut `core/space_combat.gd` heißt das Schiff so).

Umsetzung:
- Vorlagen haben das Feld `boss` = `{chance, gruppe}` (`gruppe` optional, z. B. `kopfgeld`). Der Wurf fällt einmal beim Erzeugen (`StoryGen.make`, Zufall `story.rng`) und gilt für alle Einsätze der Kette (Start, Vorteil, Entdeckt usw.). Ein Einsatz mit `"boss": false` wird nie Boss.
- Einsatz-Felder für den Hub: `elite: "boss"` und `boss_name` in `Story.pending_mission()`. Die Szene mit dem Einsatz nennt den Boss im Text („Angeführt werden sie von …“ bzw. „Als Begleitschutz fliegt die … mit …“), das Ergebnis im Szenenfenster zeigt „Einsatz: … · Boss: …“.
- **An den Hub:** `elite` und `boss_name` aus dem Story-Einsatz weitergeben: Boden `Mission.elite = &"boss"` (in `_story_ground`), Raum `setup.enemy.boss = true` und `setup.enemy.boss_name` (über `space_ctx`). Heute gibt der Hub beides noch nicht weiter. Anzeige „Boss“ in der Story-Karte der Sternenkarte.
- Test: `test_story` (`_test_boss`).

### Story-Orte mit Sektor und Ort (gebaut, Auftrag 5)

Entscheidungen des Nutzers (19.10.2026):
- **Sektor:** Story-Orte liegen meist im aktuellen Sektor, manchmal in einem anderen bekannten. Nur Schritte der Hauptstory (Ketten mit `frame`, z. B. die Schritte von Kapitel 1) dürfen selten in einem noch unbekannten Sektor liegen; der Text nennt dann „in einem noch unbekannten Sektor, jenseits eines Sprungtors“. Werte (vorläufig, nicht abgestimmt): `Story.OTHER_SECTOR_CHANCE` 30 %, `Story.FAR_CHANCE` 10 %. Kontakte liegen in einem Hafen des aktuellen oder eines bekannten Sektors.
- **Auslösen:** Eine Kette an einem Story-Ort beginnt erst, wenn das Schiff in der Systemansicht genau diesen Ort anfliegt (`on_visit`). Die Ankunft im System reicht nicht. Ausnahme: Orte ohne Ort im System (`place` = −1, z. B. alte Testdaten) beginnen weiter bei der Ankunft.
- **Ortsart passend zur Vorlage:** Feld `orte` in der Vorlage (auch in geschriebenen Ketten mit Auslöser „ort“). Gebaut: Bergung → Wrack; Befreiung → Station, Planet; Abfangen → Gasriese, Nebel, Wrack (meine Wahl); Gespräch → Station, Planet (meine Wahl). Fehlt die Ortsart im Sektor, nimmt die Story irgendeinen Ort. Nie im System, in dem das Schiff gerade liegt.

Datenform:
- `StoryState.chains[id].place` = `{sector, system, place}` (place = Index in `systems[i].places`, −1 = ganzes System) oder `{}` (überall). Eine Zahl (alter Stand, Tests) gilt als System im aktuellen Sektor.
- `Story.loc_of(chain)`, `system_of(loc)`, `place_label(loc)` (Ortsname für Texte und Logbuch, mit Sektor, wenn es nicht der aktuelle ist).
- `Story.markers(sector = -2)` → `[{sector, system, place, chain, title}]`; −2 = nur der aktuelle Sektor (Standard, so zeigt die Sternenkarte schon jetzt nichts Falsches), −1 = alle.
- `Story.at_place(sector, system, place)` → Story-Orte an einem Ort (für die Systemansicht).
- `Story.on_arrive(sector, system)`; `on_arrive(system)` gilt weiter für den aktuellen Sektor. Startet nur Ketten für das ganze System, dazu Kopfgeldjäger und Schmuggel im Hafen.
- `Story.on_visit(sector, system, place)` → Kette oder "": beim Anfliegen eines Orts in der Systemansicht.
- `Story.pending_mission().loc` = Ort der Kette; der Hub kann daraus die Kartenart nehmen (`Places.map_for(kind, seed)`).
- Platzhalter `{ort}` in Vorlagen; Einstieg „ort“: „Ein Hinweis führt zu {ort}.“

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
      "choices": [{"text": Text, "requires": [Bedingungen], "hide_locked": false, "result": Text (Ergebnistext ohne Probe),
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
| Sternenkarte | `Story.markers(sector)` → `[{sector, system, place, chain, title}]`; `Story.on_arrive(sector, system)` und `Story.on_visit(sector, system, place)` → Kette oder ""; `Story.at_place(...)` | Marker im aktuellen Sektor zeichnen; bei Ankunft `on_arrive`, beim Anfliegen eines Orts `on_visit` aufrufen und ggf. das Szenenfenster öffnen |
| Reise | `Story.travel_event(rng)` → Kette oder "" (Chance `TRAVEL_CHANCE` je Tag) | in `_travel` je Reisetag neben dem Feindkontakt |
| Raumhafen | `Story.contacts()` → `[{chain, title}]` | Bereich „Kontakte“; Ansprechen = `start(chain)` + Szenenfenster |
| Tagesende | `Story.on_day()` → Ketten mit verpasster Frist (Rückschlag-Szene ist dann aktiv) | nach `advance_days` aufrufen, Szenenfenster öffnen |
| Ressourcen | `Story.add_resource(feld, n)` → tatsächliche Änderung; im Spiel über `HubState.apply_story({feld: n})` | **gebaut**: Credits dürfen unter 0, Material und Proviant nicht, Treibstoff 0 bis Tankgröße |
| Logbuch | `StoryLog.show_on(parent, story)` | Knopf auf der Brücke und im Burgermenü |
| Sektorkarte | Story-Orte als `{sector, system, place}` (Auftrag 5) | Sektorumbau gebaut; offen: `on_visit` in der Systemansicht, Story-Orte dort zeigen |

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
- Bildliste mit Prompts: `docs/Story_Bilder.md` (Stil Comic/Graphic Novel).

## Offene Punkte

1. **Inhalte**: Ablauf und Eckpunkte geklärt (Abschnitt „Kapitel 1 und Ereignisketten“). Offen: Generator bauen, Vorlagen und Texte schreiben, Werte der Story-Schlüssel (z. B. welche Ausbaustufe für das Finale).
2. ~~Story-Fraktionen~~ erledigt (Abschnitt „Story-Fraktionen“).
3. ~~Kampagnenziele~~ entschieden: Story-Schlüssel. Offen sind nur die Schwellenwerte.
4. ~~Rückschläge~~ entschieden: gefangen bis befreit, Verfolgung durch Kopfgeldjäger. Anbindung siehe Generator-Entwurf.
5. Lager-Gegenstände: entschieden (ja, V1), noch nicht gebaut.
6. Export: JSON-Dateien in `data/story/` müssen beim Export mitgenommen werden (Exportfilter `*.json`), sobald es einen Export gibt.
