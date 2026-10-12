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
- ½ × Ausweichen-Gesamtbonus (mindestens 0); in **Abwehrhaltung** der volle Wert
- \+ Schild: 10 + ½ Rangbonus Schild (nur mit Schild)
- \+ Rüstung (schwere Rüstung macht unbeweglich: −5 / −10)
- \+ Deckung / Gelände (siehe 5.4)
- gegen **Psi**: stattdessen Psi-Verteidigung (voll) + Psi-Schild; Deckung und Ausweichen zählen nicht

### 5.2 Angriffstabellen (generisch)

Jede Tabelle hat einen Treffer-Schwellwert pro Rüstungsklasse. Ab dem Schwellwert trifft man; 30 Punkte darüber beginnt der kritische Bereich, alle 10 Punkte steigt der Grad (A, B, C, D, E).

| Tabelle | Keine | Leicht | Mittel | Schwer | Kritische Art |
|---|---|---|---|---|---|
| Wucht (Fäuste, Hammer) | 65 | 70 | 80 | 90 | Wucht |
| Klinge | 65 | 70 | 75 | 85 | Schnitt |
| Strahl (Laser) | 70 | 75 | 80 | 85 | Hitze |
| Projektil (Gewehr, MG) | 70 | 75 | 80 | 90 | Durchschlag |
| Explosion (Rakete) | 60 | 60 | 65 | 70 | Explosion |
| Psi | 70 | 70 | 70 | 70 | Psi |

**Schaden bei Treffer** = (3 + (Ergebnis − Schwelle) / 5) × Waffenfaktor × Rüstungsfaktor
Rüstungsfaktor: Keine 1,0 · Leicht 0,9 · Mittel 0,8 · Schwer 0,65 (gilt nicht für Psi).

Beispiel Projektil gegen **Mittel** (Schwelle 80): 80–109 Treffer ohne Kritischen, 110–119 A, 120–129 B, 130–139 C, 140–149 D, ab 150 E.

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

### 5.4 Gelände, Höhe, Deckung

| Situation | Wirkung |
|---|---|
| Angreifer höher als Ziel | +5 AW je Höhenstufe (max. +15) |
| Angreifer tiefer als Ziel | −5 AW je Höhenstufe (max. −15) |
| Nahkampf | nur bei max. 1 Stufe Höhenunterschied; höher stehend +10 / tiefer −10 |
| Ziel hinter Ruinenmauer oder Geländekante (vom Angreifer aus gesehen) | +20 VW (**Deckung**) |
| Angreifer ≥ 2 Stufen höher als die Mauer | Deckung durch Mauer entfällt |
| Ziel in Kristallflora (Wald) | +10 VW |
| 1 Waldfeld in der Schusslinie | −10 AW, ab 2 Feldern keine Sicht |
| Ziel steht im Wasser | −10 VW |
| Felsnadeln / höheres Gelände | blockieren die Sichtlinie |

**Reichweite:** bis ½ Reichweite +10, bis Reichweite ±0, bis 1,5 × Reichweite −25, darüber kein Schuss.

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
| Bewegung pro Bewegungsaktion | 4 + Bonus GEW / 5 (+ Rüstung: schwer −1) |

---

## 7. Rundenablauf Bodenkampf

1. Rundenbeginn: alle würfeln Initiative, gehandelt wird in absteigender Reihenfolge (Crew und Gegner gemischt).
2. Ebenfalls zu Rundenbeginn wird Blutung abgezogen. Zugbeginn: niedergeworfene Figuren stehen auf (−1 Aktion), Betäubte haben nur 1 Aktion.
3. Jede Figur hat **2 Aktionen**, davon höchstens **ein Angriff**:
   - **Bewegen** (Hexfelder nach Kosten)
   - **Angriff** (Waffe oder Psi-Stoß)
   - **Zielen**: +15 auf den nächsten Angriff in diesem Zug
   - **Abwehrhaltung**: voller Ausweichen-Bonus bis zum nächsten eigenen Zug
   - **Erste Hilfe** an einer benachbarten Figur
   - **Psi-Schild** (Psi wirken, 2 PP): +20 VW und +20 Psi-VW für 2 Runden
4. Bewegungskosten: Ebene 1, Geröll 2, Kristallflora 2, Wasser 3; bergauf +1 je Stufe, 2 Stufen hoch = Klettern (+3); ab 3 Stufen nicht passierbar. Abwärts bis 2 Stufen ohne Aufschlag. Felsnadeln und Ruinenmauern sind nicht begehbar.

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
