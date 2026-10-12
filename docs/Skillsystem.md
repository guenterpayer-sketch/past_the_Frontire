# Past the Frontire – Skillsystem (Entwurf v0.1)

Grundlage: der Charakterbogen in `Charakterbogen_Grundgeruest.md`.
Das Würfelsystem lehnt sich an Rolemaster an: **W100, offen nach oben und unten, man muss über einen Zielwert kommen.**

Alle Zahlen sind ein erster Vorschlag und werden im Prototyp (`index.html`) genau so verwendet (Quelltext: `js/rules.js`, `js/tables.js`). Punkte, die ich festgelegt habe, ohne dass sie vorgegeben waren, stehen in Abschnitt 9 als **Annahme**.

---

## 1. Der offene W100-Wurf

| Wurf (unmodifiziert) | Folge |
|---|---|
| 01–05 | **offen nach unten**: nochmal W100 würfeln und **abziehen**. Ist dieser zweite Wurf 96–00, wird weiter gewürfelt und weiter abgezogen. |
| 06–95 | normaler Wurf |
| 96–00 | **offen nach oben**: nochmal W100 würfeln und **addieren**, bei 96–00 weiter würfeln. |

**Ergebnis = offener Wurf + Fertigkeitsbonus + Modifikatoren**

- Bei **Proben (Manövern)** wird das Ergebnis mit der Manöver-Tabelle verglichen (Abschnitt 4). Ab **101** ist die Probe gelungen.
- Bei **Angriffen** wird das Ergebnis auf der Angriffstabelle der Waffe nachgeschlagen (Abschnitt 5).

---

## 2. Eigenschaften

Die sieben Eigenschaften haben Werte von **1 bis 100**. Jeder Wert ergibt einen Bonus:

| Wert | 1–5 | 6–15 | 16–30 | 31–70 | 71–80 | 81–90 | 91–95 | 96–98 | 99 | 100 |
|---|---|---|---|---|---|---|---|---|---|---|
| Bonus | −15 | −10 | −5 | 0 | +5 | +10 | +15 | +20 | +25 | +30 |

| Kürzel | Eigenschaft | wofür sie hauptsächlich zählt |
|---|---|---|
| STÄ | Stärke | Nahkampf, schwere Waffen, Schild |
| GEW | Gewandtheit | Ausweichen, Initiative, Bewegung, Pilot |
| KOO | Koordination | Fernkampf, Feinarbeit, Reparatur |
| KON | Konstitution | Trefferpunkte, Zweihandwaffen |
| INT | Intelligenz | Technik, Medizin, Taktik |
| EMP | Empathie | Soziales, Psi-Wirkung |
| MEN | Mentale Stärke | Psi, Ruhe unter Druck, Psi-Punkte |

---

## 3. Fertigkeiten

### 3.1 Gesamtbonus einer Fertigkeit

**Gesamtbonus = Rangbonus + Bonus Eigenschaft 1 + Bonus Eigenschaft 2 (+ Ausrüstung)**

Rangbonus nach Rolemaster-Staffel (abnehmender Zuwachs):

| Ränge | Rangbonus |
|---|---|
| 0 (ungeübt) | −25 |
| 1–10 | +5 je Rang (Rang 10 = +50) |
| 11–20 | +2 je Rang (Rang 20 = +70) |
| 21–30 | +1 je Rang (Rang 30 = +80) |
| über 30 | +½ je Rang |

### 3.2 Fertigkeitsliste mit Eigenschaftspaaren

**Kampf**

| Fertigkeit | Eigenschaften | Einsatz |
|---|---|---|
| Waffenloser Kampf | STÄ + GEW | Angriffswert ohne Waffe |
| Einhand-Waffen | STÄ + GEW | Klingen, Schlagstöcke |
| Zweihand-Waffen | STÄ + KON | schwere Nahkampfwaffen |
| Pistolen | KOO + GEW | Handfeuerwaffen |
| Gewehre | KOO + MEN | Gewehre, Präzisionswaffen |
| Schnellfeuerwaffen | KOO + STÄ | MGs, Feuerstoß-Waffen |
| Raketenwerfer | KOO + INT | Raketen, Granatwerfer |
| Geschütze | KOO + INT | stationäre/montierte Bodengeschütze |
| Kampfsinn | INT + GEW | Initiative, Lagegefühl |
| Ausweichen | GEW + KOO | Verteidigungswert |
| Schild | STÄ + KOO | Verteidigung mit Schild |
| Psi-Angriffe | MEN + EMP | Angriffswert für Psi-Angriffe |
| Psi-Verteidigung | MEN + INT | Verteidigung gegen Psi |

**Allgemein**

| Fertigkeit | Eigenschaften | Einsatz |
|---|---|---|
| Erste Hilfe | INT + KOO | im Kampf: Blutung stoppen, Bewusstlose stabilisieren |
| Zweite Hilfe | INT + EMP | **Annahme:** Behandlung nach dem Kampf (Operation, Heilung schwerer Wunden) |
| Psi wirken | MEN + EMP | **Annahme:** unterstützende Psi-Kräfte (Schild, Heilung), keine Angriffe |
| Waffen-Reparatur | INT + KOO | Waffen instand setzen |

**Raumschiff-Technik**

| Fertigkeit | Eigenschaften |
|---|---|
| Reparatur | INT + KOO |
| Navigation | INT + MEN |
| Pilot | GEW + KOO |
| Computer | INT + MEN |

**Raumschiff-Kampf** (Regeln: `Raumkampf.md`)

| Fertigkeit | Eigenschaften |
|---|---|
| Strahl-Geschütze | KOO + INT |
| Ballistische Geschütze | KOO + INT |
| Raketen | INT + KOO |
| Schutzschild | INT + MEN |
| Panzerung | INT + KON – **Annahme:** Schadenskontrolle, Panzerung umleiten |
| Not-Reparatur | KOO + MEN |

**Sozial / Handel**

| Fertigkeit | Eigenschaften |
|---|---|
| Handeln | EMP + INT |
| Gassenwissen | EMP + INT |
| Verhandeln | EMP + MEN |

**Handwerk**

| Fertigkeit | Eigenschaften |
|---|---|
| Rüstung | KOO + INT |
| Waffen | KOO + INT |
| Kochen | EMP + KOO |
| Medikamente herstellen | INT + KOO |

---

## 4. Proben (Manöver)

**Ergebnis = offener W100 + Gesamtbonus + Schwierigkeit + sonstige Modifikatoren (Wunden, Gelände, Ausrüstung)**

| Schwierigkeit | Modifikator | Erfahrung bei Erfolg |
|---|---|---|
| Routine | +30 | 0 |
| Leicht | +20 | 1 |
| Einfach | +10 | 1 |
| Mittel | ±0 | 2 |
| Schwer | −10 | 3 |
| Sehr schwer | −20 | 4 |
| Extrem schwer | −30 | 5 |
| Wahnsinnig | −50 | 7 |
| Absurd | −70 | 10 |

| Ergebnis | Ausgang |
|---|---|
| −26 und weniger | **Patzer** – etwas geht schief, der GM/das Spiel legt eine Folge fest |
| −25 bis 75 | **Fehlschlag** |
| 76 bis 100 | **Teilerfolg** – halber Effekt oder Erfolg mit Nachteil |
| 101 bis 175 | **Erfolg** |
| 176 und mehr | **Herausragender Erfolg** – doppelter Effekt oder Bonus |

---

## 5. Kampf

### 5.1 Angriff

**Ergebnis = offener W100 + Angriffswert (AW) − Verteidigungswert (VW) + Modifikatoren**

- **Patzer:** Liegt der *unmodifizierte* erste Wurf im Patzerbereich der Waffe (z. B. 01–03), entfällt der Angriff → Patzer-Tabelle.
- Das Ergebnis wird auf das **Maximalergebnis** der Waffe begrenzt (kleine Waffen erreichen keine E-Kritischen).
- Nachschlagen auf der **Angriffstabelle** der Waffe in der Spalte der **Rüstungsklasse** des Ziels → Schaden (TP) und evtl. **Kritischer Treffer A–E**.

**Angriffswert (AW)** = Gesamtbonus der Waffenfertigkeit + Waffenmodifikator + Modifikatoren

**Verteidigungswert (VW)** =
- Ausweichen: ½ × Ausweichen-Gesamtbonus (mindestens 0) **plus** ½ × Ausweichen × (zurückgehaltene Aktivität / 100) – siehe Abschnitt 7
- **Überraschung** (Angreifer außerhalb des Sichtfelds des Ziels, Abschnitt 7.2): kein Ausweichen und kein Schild; eine gelungene Kampfsinn-Probe (Mittel) des Ziels lässt das Ausweichen halb zählen
- \+ Schild: 10 + ½ Rangbonus Schild (nur mit Schild, nicht bei Überraschung)
- \+ Rüstung (schwere Rüstung macht unbeweglich: −5 / −10)
- \+ Deckung / Gelände (siehe 5.4)
- gegen **Psi**: stattdessen Psi-Verteidigung (voll) + Psi-Schild; Deckung und Ausweichen zählen nicht

### 5.2 Angriffstabellen (generisch)

Jede Tabelle hat einen Treffer-Schwellwert pro Rüstungsklasse. Ab dem Schwellwert trifft man; 40 Punkte darüber beginnt der kritische Bereich, alle 15 Punkte steigt der Grad (A, B, C, D, E; E ab Schwelle +100).

| Tabelle | Keine | Leicht | Mittel | Schwer | Kritische Art |
|---|---|---|---|---|---|
| Wucht (Fäuste, Hammer) | 65 | 70 | 80 | 90 | Wucht |
| Klinge | 65 | 70 | 75 | 85 | Schnitt |
| Strahl (Laser) | 70 | 75 | 80 | 85 | Hitze |
| Projektil (Gewehr, MG) | 70 | 75 | 80 | 90 | Durchschlag |
| Explosion (Rakete) | 60 | 60 | 65 | 70 | Explosion |
| Psi | 70 | 70 | 70 | 70 | Psi |

**Schaden bei Treffer** = (2 + (Ergebnis − Schwelle) / 8) × Waffenfaktor × Rüstungsfaktor
Rüstungsfaktor: Keine 1,0 · Leicht 0,9 · Mittel 0,8 · Schwer 0,65 (gilt nicht für Psi).

Beispiel Projektil gegen **Mittel** (Schwelle 80): 80–119 Treffer ohne Kritischen, 120–134 A, 135–149 B, 150–164 C, 165–179 D, ab 180 E. Weil Waffen höchstens 130–150 erreichen, sind D und E derzeit praktisch nicht erreichbar (offene Frage).

### 5.3 Kritische Treffer

Kritischer Wurf: W100 (geschlossen) + Grad-Modifikator (A −20, B −10, C ±0, D +10, E +20).
Sechs Tabellen (Durchschlag, Hitze, Wucht, Schnitt, Explosion, Psi) mit je 7 Stufen (≤20, 21–40, 41–60, 61–80, 81–95, 96–110, 111+). Mögliche Folgen:

- **Zusatzschaden**
- **Blutung X**: X TP Verlust zu Beginn jeder Runde (stapelt, wirkt auch bei Bewusstlosen; Erste Hilfe stoppt sie)
- **Betäubt N**: N Züge nur 1 Aktion und kein Angriff, Ausweichen zählt nicht
- **Niedergeworfen**: nächster Zug −1 Aktion (Aufstehen)
- **Malus**: dauerhafter Abzug auf alle Würfe für den Rest des Kampfes (stapelt)
- **Bewusstlos / Tot**

Die vollständigen Texte stehen in `js/tables.js` und im Spiel unter „Tabellen“.

### 5.4 Maßstab, Höhe, Deckung, Reichweite

**Maßstab:** 1 Hexfeld = 1,5 m (von Mitte zu Mitte), 1 Höhenstufe = 1,5 m. Eine Figur ist etwa 1,8 m groß.

| Situation | Wirkung |
|---|---|
| Angreifer höher als Ziel | +5 AW je Höhenstufe (max. +15) |
| Angreifer tiefer als Ziel | −5 AW je Höhenstufe (max. −15) |
| Nahkampf | nur gegen Nachbarfelder mit max. 1 Stufe Höhenunterschied; höher stehend +10 / tiefer −10 |
| **Halbe Deckung**: Hindernis in einem der 2 Felder vor dem Ziel (Richtung Angreifer; das 2. Feld nur ab 4 Feldern Abstand), 1,2–2,7 m höher als das Ziel steht: Kisten, Fässer, Betonbarrieren | **+30 VW**, man schießt darüber hinweg |
| **Volle Deckung**: wie oben, Hindernis mind. 2,7 m höher als das Ziel: Container, Hochregal, Säule, Galerie-Kante | **+50 VW** |
| Angreifer steht mind. 1 Stufe über der Oberkante der Deckung | Deckung sinkt um eine Stufe (voll → halb → keine) |
| Hohe Hindernisse zwischen Schütze und Ziel | blockieren die Sichtlinie |

**Um die Ecke schießen:** Wer direkt neben voller Deckung steht, darf die Sichtlinie auch von einem benachbarten Feld derselben Höhe aus ziehen (seitlich herauslehnen). Das gilt für Angreifer und Ziel gleichermaßen. Wird ein Ziel so gesehen, steht es in voller Deckung.

**Reichweitenstufen:** Jede Fernkampfwaffe hat eine Grundreichweite in Metern (eine Stufe) und eine Anzahl Stufen.

| Entfernung | Modifikator |
|---|---|
| bis 3 m (Kernschussweite) | +10 |
| Stufe 1 (bis 1 × Grundreichweite) | ±0 |
| jede weitere Stufe | −20 (Stufe 2: −20, Stufe 3: −40, Stufe 4: −60) |
| über der letzten Stufe | kein Schuss |

| Waffe | Grundreichweite | Stufen | max. |
|---|---|---|---|
| Laserpistole | 10 m | 4 | 40 m |
| Sturmgewehr | 25 m | 4 | 100 m |
| Schweres MG | 20 m | 4 | 80 m |
| Raketenwerfer | 30 m | 3 | 90 m (mind. 6 m Abstand) |
| Psi-Stoß | 10 m | 3 | 30 m |

**Raketen:** Die Druckwelle trifft Figuren in 1,5 m Abstand mit −20 und in 3 m Abstand mit −40 (gleicher Wurf, eigener Tabelleneintrag), Freund wie Feind.

### 5.5 Patzer (W100)

| Wurf | Folge |
|---|---|
| 01–40 | Zögern: Rest des Zuges verloren |
| 41–70 | Waffe klemmt / überhitzt: nächster Angriff −20 |
| 71–90 | Stolpern: niedergeworfen |
| 91–00 | Querschläger / Rückkopplung: 1W10 Schaden am Angreifer |

---

## 6. Abgeleitete Werte

| Wert | Formel |
|---|---|
| Trefferpunkte (TP) | 15 + KON / 3 (+10 mit schwerer Rüstung **nicht**, Rüstung wirkt über Tabelle) |
| Bewusstlos | bei 0 TP oder weniger |
| Tot | bei −(KON / 5) TP oder durch Kritischen |
| Psi-Punkte (PP) | MEN / 10 + Ränge Psi wirken / 2 (nur mit mindestens 1 Rang in einer Psi-Fertigkeit) |
| Initiative (jede Runde neu) | 2W10 + Bonus GEW + Kampfsinn-Gesamtbonus / 5 |
| Bewegung | Gehen 1 Hex je 10 % Aktivität; dazu Gratis-Felder pro Runde = Bonus GEW / 5 (schwere Rüstung −1) |

---

## 7. Rundenablauf Bodenkampf (Aktivitätssystem im RMSS-Stil)

Vorbild ist das Aktivitätssystem von RMSS/RMFRP. **Alle Zahlen sind eigene Werte**, nicht aus dem Regelbuch übernommen.

1. **Eine Runde = 10 Sekunden.** Zu Rundenbeginn wirkt Blutung, dann würfeln alle Initiative (2W10 + GEW-Bonus + Kampfsinn/5). Gehandelt wird nacheinander in absteigender Initiative, Crew und Gegner gemischt.
2. Jede Figur hat pro Runde **100 % Aktivität** und verteilt sie in 10-%-Schritten. **Höchstens 1 Angriff pro Runde**; ein Angriffswurf steht für mehrere Schüsse oder Schläge.
3. **Niedergeworfen:** Aufstehen kostet 30 %. **Betäubt:** höchstens 50 % Aktivität und kein Angriff.
4. Nicht verbrauchte Aktivität ist bis zum nächsten eigenen Zug **Ausweichreserve** (siehe 5.1). Vor dem ersten eigenen Zug gilt eine Reserve von 50 %.

**Bewegung** (Wegkosten in Hexfeldern wie unten):

| Gangart | Hexfelder je 10 % | bei 100 % | Folge |
|---|---|---|---|
| Gehen | 1 | 15 m | – |
| Laufen | 2 | 30 m | danach Angriff −20 |
| Sprinten | 3 | 45 m | kein Angriff in dieser Runde (auch nicht nach einem Angriff möglich) |

Dazu kommen **Gratis-Felder** pro Runde: GEW-Bonus / 5 (z. B. GEW 92 → +15 → 3 Felder), schwere Rüstung −1.

**Angriff** – Modifikator nach eingesetzter Aktivität:

| Aktivität | 20 % | 30 % | 40 % | 50 % | **60 %** | 70 % | 80 % | 90 % | 100 % |
|---|---|---|---|---|---|---|---|---|---|
| Modifikator | −40 | −30 | −20 | −10 | **±0** | +5 | +10 | +15 | +20 |

Ein Waffenwechsel kostet zusätzlich 10 %.

**Sonstige Handlungen:**

| Handlung | Aktivität |
|---|---|
| Erste Hilfe (Leicht, +20 mit Medikit) | 50 % |
| Ducken / Aufstehen | 10 % |
| Abwarten (siehe 7.2) | 10 % |
| Psi-Schild (Psi wirken, Mittel, 2 PP): +20 VW und +20 Psi-VW für 1–3 Runden | 40 % |
| Nachladen (Raketenwerfer: 1 Schuss pro Ladung, 2 insgesamt) | 30 % |
| Aufstehen | 30 % |
| Waffe wechseln | 10 % |
| Drehen (Blickrichtung ändern) | kostenlos, jederzeit im eigenen Zug |

### 7.2 Ducken, Abwarten, Feuerbereitschaft und Blickrichtung

**Ducken** (10 %, Aufstehen ebenfalls 10 %): Geduckte Figuren bekommen +15 VW gegen Fernkampf und schießen ruhiger (+10 AW im Fernkampf). Geduckt hinter halber Deckung zählt als **volle Deckung**. Nahkämpfer bekommen +10 AW gegen Geduckte. Geduckt kann man nur gehen, mit halber Geschwindigkeit (1 Hex je 20 %, ohne Gratis-Felder).

**Abwarten** (10 %): Solange eine Figur in dieser Runde noch nichts getan hat, kann sie ihren Zug nach hinten schieben. Nach jedem beliebigen anderen Zug kann sie einspringen (im Spiel über „einspringen“ in der Initiative-Liste); wer nicht einspringt, handelt am Rundenende. Einmal pro Runde. Beim Einspringen stehen 10 % weniger Aktivität zur Verfügung; während des Wartens zählt die noch freie Aktivität als Ausweichreserve.

**Erste Hilfe:** Probe auf **Leicht** (+20). Jedes Crewmitglied trägt ein **Medikit** mit 3 Anwendungen (+20 auf die Probe). Auch die KI versorgt bewusstlose oder stark blutende Kameraden.


**Feuerbereitschaft:** Wer noch nicht angegriffen hat und mindestens 30 % übrig hat, kann die gesamte restliche Aktivität zurückhalten; der Zug endet damit. Handelt danach ein Gegner im Sichtfeld und in Reichweite (bewegt sich Feld für Feld oder setzt zum Angriff an), wird sofort geschossen: Modifikator nach den zurückgehaltenen Prozent (Tabelle oben) und −10 für die Reaktion. Ein Treffer kann den Gegner mitten in der Bewegung stoppen. Einmal pro Runde; die Bereitschaft endet mit dem nächsten eigenen Zug. Danach ist keine Ausweichreserve mehr übrig.

**Blickrichtung:** Jede Figur schaut zu einer Hexseite. Nach einer Bewegung schaut sie in Laufrichtung, beim Angriff zum Ziel; im eigenen Zug kann sie sich jederzeit kostenlos drehen.

| Lage des Angreifers (vom Ziel aus) | Wirkung |
|---|---|
| vorne (Sichtfeld 180°, vordere 3 Hexseiten) | normal |
| Flanke (90°–150°) | +15 AW, **Überraschung** |
| Rücken (über 150°) | +30 AW, **Überraschung** |

**Überraschung:** Das Ziel bekommt keinen Ausweich- und keinen Schildbonus. Es darf eine Kampfsinn-Probe (Mittel) würfeln; gelingt sie, zählt das Ausweichen halb.

**Bewegungskosten** (je Hexfeld = 1,5 m):
- Boden, Galerie, Treppe, Container- und Kistenoberseite 1, Regaloberseite 2
- 1 Stufe hoch (z. B. auf eine Kiste): +1; 1 Stufe runter: ±0
- 2 Stufen herunterspringen (3 m): +1; höher springen geht nicht
- mehr als 1 Stufe hoch nur über **Treppe** (Stufe für Stufe) oder **Leiter**: +1 je Stufe
- Fässer, Barrieren, Säulen und Wände sind nicht begehbar

### 7.3 Schauplatz Lagerhalle (Prototyp)

Hindernisse (Regalreihen, Container, Barrieren, Kistenwände) stehen waagerecht oder senkrecht, damit es Deckung in beide Richtungen gibt.

Die Größe wird im Testmodus pro Mission zufällig gewählt: **klein ca. 30×21 m**, **mittel ca. 45×30 m**, **groß ca. 60×40 m**. Die Halle enthält:
- **Galerie / Laufstege** in 4,5 m Höhe an der Rückwand (ab „mittel“ auch an der rechten Wand), erreichbar über Treppen und Leitern
- **Container** (3 m hoch, teils doppelt gestapelt: 6 m), Aufstieg über eine Leiter oder eine Kiste
- **Hochregale** (4,5 m) in Reihen mit Gängen, je eine Leiter am Ende
- **Kistenstapel** (1,5 m, begehbar), **Fässer**, **Betonbarrieren**, **Stahlsäulen**
- Die Crew startet am Rolltor links, die Gegner in der rechten Hallenhälfte, einige davon erhöht.

Vereinfachung: Unter der Galerie kann man nicht hindurchgehen; sie wirkt wie ein massiver Block.

---

## 8. Steigerung – Erfahrung nur durch Benutzung

Jede Fertigkeit hat ein eigenes Erfahrungskonto. Erfahrung (EP) bekommt eine Fertigkeit **nur, wenn sie benutzt wurde**:

| Ereignis | EP für die Fertigkeit |
|---|---|
| Probe gelungen | EP laut Schwierigkeit (Tabelle Abschnitt 4) |
| Probe misslungen (kein Patzer) | halbe EP, abgerundet (aus Fehlern lernen) |
| Angriff ausgeführt | +1 Waffenfertigkeit |
| Angriff getroffen | +1 zusätzlich, +1 bei Kritischem, +2 wenn die Modifikatoren zusammen −20 oder schlechter waren |
| Angegriffen und nicht getroffen | +1 Ausweichen (bzw. Psi-Verteidigung, mit Schild zusätzlich +1 Schild) |
| Kampfrunde handlungsfähig überstanden | +1 Kampfsinn |

**Rangsteigerung:** Hat das Konto genug EP, kann ein Rang gekauft werden.
Kosten für den nächsten Rang = **10 + 2 × aktueller Rang** (Rang 0→1: 10 EP, 5→6: 20 EP, 10→11: 30 EP).

**Freier Pool:** Pro Einsatz bekommt jede Figur **3 freie EP**, die auf eine beliebige Fertigkeit gelegt werden dürfen (Training, Lektüre). So lassen sich auch ungenutzte Fertigkeiten langsam aufbauen.

---

## 9. Annahmen und offene Punkte

Diese Punkte habe ich festgelegt, ohne dass sie vorgegeben waren. Sie sind leicht zu ändern:

1. **Eigenschaftspaare** der Fertigkeiten (Abschnitt 3.2) sind mein Vorschlag.
2. **„Zweite Hilfe“**: Die Bedeutung weiß ich nicht; angenommen ist Behandlung nach dem Kampf.
3. **„Psi wirken“ vs. „Psi-Angriffe“**: angenommen ist, dass „Psi wirken“ für unterstützende Kräfte steht.
4. **„Panzerung“ (Raumschiff-Kampf)**: angenommen ist Schadenskontrolle / Panzerung umleiten.
5. **Zahlenwerte** (TP-Formel, Tabellen-Schwellen, Schadensfaktoren, EP-Kosten) sind ein erster Entwurf und noch nicht ausbalanciert.
6. **Munition / Nachladen** gibt es im Prototyp nur beim Raketenwerfer (2 Schuss).
7. Rolemaster arbeitet mit drei Eigenschaften pro Fertigkeit und ~20 Rüstungsarten; hier sind es zur Vereinfachung zwei Eigenschaften und vier Rüstungsklassen.
8. **Galerie** ist im Prototyp ein massiver Block (man kann nicht darunter hindurchgehen).
9. **Höhen der Hallenobjekte** sind auf ganze Stufen (1,5 m) gerundet: Container 3 m statt real ca. 2,6 m.
10. **Aktivitätssystem:** Prinzip nach RMSS/RMFRP, alle Werte (Gangarten, Angriffsmodifikatoren, Kosten, Reserve 50 % vor dem ersten Zug, Feuerbereitschaft) sind eigene Vorschläge, nicht aus dem Regelwerk.
