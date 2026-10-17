# Past the Frontire – Skillsystem (Entwurf v0.1)

Grundlage: der Charakterbogen in `Charakterbogen_Grundgeruest.md`.
Das Würfelsystem lehnt sich an Rolemaster an: **W100, offen nach oben und unten, man muss über einen Zielwert kommen.**

Alle Zahlen sind ein erster Vorschlag und werden im Prototyp (`index.html`) genau so verwendet (Quelltext: `js/rules.js`, `js/tables.js`). Punkte, die ich festgelegt habe, ohne dass sie vorgegeben waren, stehen in Abschnitt 9 als **Annahme**.

---

## 1. Der offene W100-Wurf

**Gewürfelt wird wie in Rolemaster mit zwei W10** (Seiten 0–9): ein Würfel gibt die Zehner, der andere die Einer (im Spiel: rot = Zehner, weiß = Einer). 0 und 0 ergibt **100** („00“), 0 und 7 ergibt 07. Jeder Wert von 1 bis 100 ist damit gleich wahrscheinlich (je 1 %). Auch Nachwürfe, Kritische Treffer und Patzer werden so gewürfelt.

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
| Waffen-Reparatur | INT + KOO | im Kampf: beschädigte Waffen instand setzen (eigene oder im Nachbarfeld) |

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
| Raketen-Geschütze (ID `raketen`) | INT + KOO |
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

**Entwicklung** (nur Ränge zählen, die Eigenschaften spielen keine Rolle)

| Fertigkeit | Wirkung |
|---|---|
| Körperentwicklung | +5 Trefferpunkte je Rang (Abschnitt 6) |
| Psi-Punkte-Entwicklung | +2 Psi-Punkte je Rang (Abschnitt 6) |

**Psi-Listen**: jede Liste ist eine eigene Fertigkeit (MEN + EMP), Regeln und Kräfte in Abschnitt 6.1.

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
- \+ Schild: 10 + ½ Rangbonus Schild (nur mit Schild, nicht bei Überraschung). Ein Schild geht nur mit **einhändigen Waffen** (Waffe 1 und Waffe 2; Fäuste zählen nicht als zweihändig), Entscheidung 15.10.2026.
- \+ Rüstung (schwere Rüstung macht unbeweglich: −5 / −10)
- \+ Deckung / Gelände (siehe 5.4)
- gegen **Psi**: stattdessen Psi-Verteidigung (voll) + Psi-Schild; Deckung und Ausweichen zählen nicht

### 5.2 Angriffstabellen (generisch)

Jede Tabelle hat einen Treffer-Schwellwert pro Rüstungsklasse. Ab dem Schwellwert trifft man; 40 Punkte darüber beginnt der kritische Bereich, alle 15 Punkte steigt der Grad (A, B, C, D, E; E ab Schwelle +100).

| Tabelle | Keine | Leicht | Mittel | Schwer | Kritische Art |
|---|---|---|---|---|---|
| Wucht (Fäuste, Hammer) | 75 | 80 | 90 | 100 | Wucht |
| Klinge | 75 | 80 | 85 | 95 | Schnitt |
| Strahl (Laser) | 80 | 85 | 90 | 95 | Hitze |
| Projektil (Gewehr, MG) | 80 | 85 | 90 | 100 | Durchschlag |
| Explosion (Rakete) | 70 | 70 | 75 | 80 | Explosion |
| Psi | 80 | 80 | 80 | 80 | Psi |

**Schaden bei Treffer** = (2 + (Ergebnis − Schwelle) / 8) × Waffenfaktor × Rüstungsfaktor
Rüstungsfaktor: Keine 1,0 · Leicht 0,9 · Mittel 0,8 · Schwer 0,65 (gilt nicht für Psi).

Beispiel Projektil gegen **Mittel** (Schwelle 90): 90–129 Treffer ohne Kritischen, 130–144 A, 145–159 B, 160–174 C, 175–189 D, ab 190 E. Weil Waffen höchstens 130–150 erreichen, sind D und E derzeit praktisch nicht erreichbar (offene Frage).

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
| **Halbe Deckung**: Hindernis in einem der 2 Felder vor dem Ziel (Richtung Angreifer; das 2. Feld nur ab 4 Feldern Abstand), 1,2–2,7 m höher als das Ziel steht: Kisten, Fässer, Betonbarrieren | **+40 VW**, man schießt darüber hinweg |
| **Volle Deckung**: wie oben, Hindernis mind. 2,7 m höher als das Ziel: Container, Hochregal, Säule, Galerie-Kante | **+70 VW**; auf ein Ziel in voller Deckung sind nur gezielte Schüsse möglich (mind. 60 % Aktivität), keine Reaktionsschüsse |
| Angreifer steht mind. 2 Stufen (3 m) über der Oberkante der Deckung | Deckung sinkt um eine Stufe (voll → halb → keine) |
| Hohe Hindernisse zwischen Schütze und Ziel | blockieren die Sichtlinie |
| **Kistenstapel** (1,5 m) zwischen Schütze und Ziel | ein einzelner Stapel auf der Linie sperrt die Sicht nicht, erst zwei oder mehr (Kistenwand); direkt vor dem Ziel bleibt er halbe Deckung (Entscheidung 15.10.2026) |
| Figur an der Kante der **Galerie** gegen tiefer stehende Schützen | **Geländer**: halbe Deckung (+40 VW) |
| Niedrige Deckung direkt neben Schütze oder Ziel | wird überschossen – aber nur, wenn das Auge des Schützen über ihrer Oberkante liegt (von unten blockiert sie) |

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
| Laserkarabiner (Fertigkeit Gewehre, seit 15.10.2026) | 15 m | 4 | 60 m |
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
| Trefferpunkte (TP) | 15 + KON / 3 + 5 × Rang Körperentwicklung (Rüstung wirkt über die Tabelle, nicht auf TP) |
| Bewusstlos | bei 0 TP oder weniger |
| Tot | bei −(KON / 5) TP oder durch Kritischen |
| Psi-Punkte (PP) | MEN / 10 + MEN-Bonus / 2 + 2 × Rang Psi-Punkte-Entwicklung, mindestens 0 (nur mit mindestens 1 Rang in einer Psi-Fertigkeit oder Psi-Liste) |
| Initiative (jede Runde neu) | 2W10 + Bonus GEW + Kampfsinn-Gesamtbonus / 5 |
| Bewegung | Gehen 1 Hex je 10 % Aktivität; dazu Gratis-Felder pro Runde = Bonus GEW / 5 (schwere Rüstung −1) |

### 6.1 Psi-Listen

Psi funktioniert wie Magie in Rolemaster: Kräfte sind in **Listen** geordnet.

- Jede Liste ist eine **eigene Fertigkeit**; Ränge kosten wie jede Fertigkeit (10 + 2 × Rang).
- **Rang = höchste verfügbare Stufe**: mit Rang 4 in „Schutz“ stehen alle Kräfte der Stufen 1–4 dieser Liste zur Verfügung. Nicht jede Stufe hat eine Kraft.
- **Kosten**: eine Kraft kostet **Stufe PP** und 40 % Aktivität.
- **Probe**: unterstützende Kräfte mit **Psi wirken** (Mittel), Angriffe mit **Psi-Angriffe** gegen die Psi-Verteidigung des Ziels. Kräfte, die einem Gegner etwas aufzwingen (Lähmen, Stoßen, Entwaffnen), sind Angriffe; einen eigenen Widerstandswurf gibt es nicht.

**Im Bodenkampf** (Stand 16.10.2026): Alle Kräfte außer Telekinese „Heranziehen“ und „Schweben“ sind nutzbar. Angriffskräfte (Psi-Nadel, Psi-Stoß, Lähmen, Psi-Lanze, Druckwelle, Stoßen, Entwaffnen) werden wie Waffen eingesetzt (Aktivität frei wählbar, Psi-Angriffe gegen Psi-VW). Unterstützende Kräfte kosten 40 % Aktivität; Probe Psi wirken (Mittel): herausragend = verstärkt, Erfolg = voll, Teilerfolg = schwach, Fehlschlag = nichts, Patzer = Rückkopplung (betäubt 1). „Wieder auf die Beine“ und „Am Leben halten“ wirken erst ab Erfolg. **„Am Leben halten“ stabilisiert eine sterbende Figur** (statt „Gestorbene ist bewusstlos“, weil im Kampf niemand mehr stirbt). **„Gedanken orten“ hebt 3 Runden lang die Deckung der Gegner in 10 Hex auf** (es gibt keine Sichtbeschränkung im Kampf). Psi-Listen bekommen keine EP durch Benutzung; EP gibt es für die Probe (Psi-Angriffe bzw. Psi wirken).

**Schutz** (Psi wirken)

| Stufe | Kraft | Wirkung |
|---|---|---|
| 1 | Abschirmen | selbst: +10 Psi-VW für 3 Runden |
| 2 | Psi-Schild | ein Ziel in Sicht: +20 VW und +20 Psi-VW für 1–3 Runden (im Spiel vorhanden) |
| 4 | Ablenkfeld | ein Ziel: Fernangriffe dagegen −20 für 2 Runden |
| 6 | Schildkuppel | alle Verbündeten in 2 Hex: +15 VW für 2 Runden |
| 9 | Letzte Barriere | ein Ziel: der nächste Kritische zählt eine Stufe schwächer |

**Heilung** (Psi wirken, Berührung)

| Stufe | Kraft | Wirkung |
|---|---|---|
| 1 | Blutung stillen | Blutung −3 |
| 3 | Wunden schließen | heilt 2W10 TP |
| 5 | Schmerz dämpfen | Wundmalus zählt 5 Runden nicht |
| 7 | Wieder auf die Beine | eine bewusstlose Figur steht mit 1 TP auf |
| 10 | Am Leben halten | eine in dieser Runde gestorbene Figur ist stattdessen bewusstlos |

**Angriff** (Psi-Angriffe gegen Psi-Verteidigung)

Reichweiten im Bodenkampf (`core/psi_combat.gd`, so zeigt sie auch die Übersicht der Psi-Listen): Psi-Nadel bis 5 m, Psi-Stoß bis 30 m, Lähmen bis 20 m, Psi-Lanze bis 30 m, Druckwelle 2 Hex um den Psioniker; Telekinese Stoßen und Entwaffnen bis 10 m. Die Meterangaben in der Tabelle unten sind der ursprüngliche Entwurf.

| Stufe | Kraft | Wirkung |
|---|---|---|
| 1 | Psi-Nadel | wie Psi-Stoß, 5 m, Angriff −20 |
| 2 | Psi-Stoß | Tabelle Psi, 10 m (im Spiel vorhanden) |
| 4 | Lähmen | kein Schaden, Ziel 1–2 Runden betäubt |
| 6 | Psi-Lanze | 30 m, Kritische eine Stufe stärker |
| 8 | Druckwelle | alle Gegner in 2 Hex, Angriff −20 |

**Wahrnehmung** (Psi wirken)

| Stufe | Kraft | Wirkung |
|---|---|---|
| 1 | Gefahrensinn | selbst: +10 Ausweichreserve bis zum nächsten Zug |
| 3 | Gedanken orten | Gegner in 10 Hex für 3 Runden sichtbar, auch hinter Deckung |
| 5 | Vorahnung | ein Verbündeter: +20 Ausweichen gegen den nächsten Angriff |
| 7 | Schwachstelle | ein Gegner wird markiert: der nächste Angriff eines Verbündeten auf ihn +20 |

**Telekinese** (gemischt)

| Stufe | Kraft | Probe | Wirkung |
|---|---|---|---|
| 1 | Heranziehen | Psi wirken | einen Gegenstand aus bis zu 5 Hex holen (z. B. Medikit) |
| 3 | Stoßen | Psi-Angriffe | Ziel 1 Hex zurück, bei starkem Treffer niedergeworfen |
| 5 | Entwaffnen | Psi-Angriffe | Ziel kann im nächsten Zug nicht angreifen |
| 8 | Schweben | Psi wirken | selbst: eine Höhenstufe ohne Treppe oder Leiter überwinden |

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
| Nachladen (Magazin aus der Reserve auffüllen) | 30 % |
| Aufstehen | 30 % |
| Waffe wechseln | 10 % |
| Drehen (Blickrichtung ändern) | kostenlos, jederzeit im eigenen Zug |

### 7.2 Ducken, Abwarten, Feuerbereitschaft und Blickrichtung

**Ducken** (10 %, Aufstehen ebenfalls 10 %): Geduckte Figuren bekommen +15 VW gegen Fernkampf und schießen ruhiger (+10 AW im Fernkampf). Geduckt hinter halber Deckung zählt als **volle Deckung**. Nahkämpfer bekommen +10 AW gegen Geduckte. Geduckt kann man nur gehen, mit halber Geschwindigkeit (1 Hex je 20 %, ohne Gratis-Felder).

**Abwarten** (10 %): Solange eine Figur in dieser Runde noch nichts getan hat, kann sie ihren Zug nach hinten schieben. Nach jedem beliebigen anderen Zug kann sie einspringen (im Spiel über „einspringen“ in der Initiative-Liste); wer nicht einspringt, handelt am Rundenende. Einmal pro Runde. Beim Einspringen stehen 10 % weniger Aktivität zur Verfügung; während des Wartens zählt die noch freie Aktivität als Ausweichreserve.

**Erste Hilfe:** Probe auf **Leicht** (+20). Jedes Crewmitglied trägt ein **Medikit** mit 3 Anwendungen (+20 auf die Probe). Auch die KI versorgt bewusstlose, sterbende oder stark blutende Kameraden.

**Waffen-Reparatur** (50 %, Entscheidungen des Nutzers 16.10.2026): eigene Waffe oder die Waffe einer Figur im **Nachbarfeld**, **einmal je Stück und Kampf** (auch ein misslungener Versuch zählt). Probe auf **Mittel** (±0): Herausragend +10, Erfolg +5, Teilerfolg und Fehlschlag keine Wirkung, Patzer −10 (bis −30). Im Kampf höchstens bis **−5**, den Rest repariert das Schiff; angeboten nur bei Schaden unter −5. Auch unbrauchbare Waffen (−30 → −25 bzw. −20 = wieder nutzbar); ein +5-Bonus kommt nie zurück. Die KI (mit Rang ≥ 1) repariert unbrauchbare Waffen benachbarter kampffähiger Figuren sofort, beschädigte (≤ −10), wenn sie von ihrem Feld aus nicht angreifen kann.

**Verwundung statt Tod:** Wer nach den Regeln sterben würde (TP ≤ −KON/5 oder tödlicher Kritischer), ist **sterbend**: kampfunfähig am Boden, aber nicht tot. Das gilt für Crew und Gegner. Sterbende bluten weiter (TP sinken höchstens bis −max. TP, ohne weitere Folgen). Eine **gelungene Erste Hilfe** (Erfolg oder besser) **stabilisiert**: Die Figur bleibt für den Rest des Kampfes kampfunfähig, zählt danach aber nur als kampfunfähig statt schwer verwundet. **Tod** nur, wenn die **ganze Crew fällt**: Dann stirbt jede noch unversorgte sterbende Figur mit **10 %** (W100 ≤ 10); Stabilisierte überleben. Heilung und Schwere nach dem Kampf: `docs/Planung_Roster_Verwundung.md`, Abschnitt B.


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
- **Galerie / Laufstege** in 4,5 m Höhe an der Rückwand (ab „mittel“ auch an der rechten Wand) mit Geländer (halbe Deckung), erreichbar über 2 Felder breite Treppen (2–3 an der Rückwand, 2 an der Seitengalerie) und Leitern; zwei Gegner starten erhöht
- **Container** (3 m hoch, teils doppelt gestapelt: 6 m), Aufstieg über eine Leiter oder eine Kiste
- **Hochregale** (4,5 m) in Reihen mit Gängen, je eine Leiter am Ende
- **Kistenstapel** (1,5 m, begehbar), **Fässer**, **Betonbarrieren**, **Stahlsäulen**
- Die Crew startet am Rolltor links, die Gegner in der rechten Hallenhälfte, einige davon erhöht.

Vereinfachung: Unter der Galerie kann man nicht hindurchgehen; sie wirkt wie ein massiver Block.

---

## 7a. Charaktererschaffung

Gilt für neue Crewmitglieder. Für das spätere Aufleveln wird eine Variante davon gebraucht (noch offen).

1. **Eigenschaften auswürfeln:** 7 Würfe mit W100, Würfe unter 20 werden wiederholt (jeder Wert 20–100 gleich wahrscheinlich). Der **niedrigste Wurf wird durch 90 ersetzt** (in Rolemaster abhängig vom Beruf; hier gibt es keine Berufe). Neu würfeln ist **beliebig oft** erlaubt.
2. **Verteilen:** Die 7 Werte werden frei auf die 7 Eigenschaften gelegt.
3. **Fertigkeitspunkte:** Eigenschaftssumme × **1,2** (abgerundet). Ränge kosten wie beim Steigern **10 + 2 × aktueller Rang** (Rang 1 kostet 10, Rang 5 insgesamt 70, Rang 8 insgesamt 136).
4. **Ranggrenze:** Bei der Erschaffung höchstens **Rang 5**, bei **zwei** Fertigkeiten höchstens **Rang 8**.
5. **Psi-Listen:** höchstens **zwei** Listen bei der Erschaffung; weitere später mit EP.
6. **Station** an Bord wählen (Steuer, Navigation, Geschütze, Schilde, Technik, Computer, Jäger; siehe `Raumkampf.md`). Jede Station nur einmal, Jäger mehrfach.
7. **Ausrüstung** (Waffen, Rüstung) und Aussehen werden frei gewählt; Regeln für Kauf und Ausrüstung gibt es noch nicht.

Zum Vergleich: Bei 1,2 bekommt eine neue Figur im Mittel etwa 580 Fertigkeitspunkte (80 % zwischen ca. 485 und 665); die Startcrew hat 586–846 verbaut (Ø 738), Gegner 182–408. Ausprobiert im Prototyp „Frontire Charakter-Editor“ (Artifact).

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

**Freie EP (sparen):** Pro Einsatz bekommt jede Figur **3 freie EP**, bei einem Sieg zusätzlich die **Missionsbelohnung** (leicht 2, mittel 3, schwer 5). Freie EP werden pro Figur gesammelt und bleiben gespart, bis sie ausgegeben werden:

- **Rangkauf auffüllen:** Fehlen einer Fertigkeit EP für den nächsten Rang, kommen die fehlenden EP aus den freien EP (Training, Lektüre). So lassen sich auch ungenutzte Fertigkeiten aufbauen.
- **Einzahlen:** Freie EP lassen sich in Schritten (+1 / +5) auf das Konto einer beliebigen Fertigkeit legen; den Rang kauft man, sobald das Konto reicht.
- **Keine Ranggrenze** beim Aufleveln (die Grenze 5/8 gilt nur bei der Erschaffung, 7a).
- **Neue Psi-Liste:** Der erste Rang einer Liste kostet **doppelt** (20 EP statt 10). Pro **Levelphase** (Zeit im Charakter-Modul zwischen zwei Einsätzen) darf jede Figur **höchstens eine neue Liste** beginnen; „begonnen“ heißt: Rang 1 gekauft. EP auf weitere neue Listen einzahlen ist erlaubt. Insgesamt ist die Zahl der Listen nicht begrenzt.
- **Eigenschaft steigern:** +1 auf eine Eigenschaft kostet **2 + Wert/10 freie EP** (abgerundet; Wert 50 → 7 EP, 70 → 9 EP, 90 → 11 EP), höchstens bis 100. Ein Punkt wirkt nur, wenn er eine Bonusstufe erreicht (z. B. 71, 81, 91), wirkt dann aber auf alle Fertigkeiten mit dieser Eigenschaft und auf abgeleitete Werte (KON → Trefferpunkte, MEN → Psi-Punkte).

---

**Training an Bord (Hub, 16.10.2026):** Alle **5 Spieltage** (Tag 5, 10, 15 …) bekommt die **ganze Crew an Bord** – auch Verwundete und das Personal der Krankenstation – **3 freie EP**, damit auch Mitglieder ohne Einsätze steigern können. Gezählt wird nach dem Spieltag (wer neu an Bord kommt, ab dem nächsten 5er-Tag). Angezeigt im Reisebericht, im Einsatzbericht und als Meldung beim Warten (`HubState.advance_days()`).

## 8a. Verwundung und Heilung

Kein Tod im Normalfall: Wer nach den Regeln sterben würde, ist **sterbend** (kampfunfähig, Erste Hilfe kann stabilisieren). Nur wenn die **ganze Crew fällt**, stirbt jede sterbende Figur mit 10 % (Todeswurf im Bodenkampf); Tote verlassen die Crew, ihr Roster-Eintrag bleibt.

Stufe am Kampfende (Charakter-Modul, `core/injury.gd`):

| Stufe | Bedingung | Grundtage | Einsatz bis zur Heilung |
|---|---|---|---|
| unverletzt | TP mindestens die Hälfte, kein Kritischer | – | ja |
| angeschlagen | TP unter der Hälfte oder ein Kritischer (A–E) erlitten, aber noch stehend | 2 | ja, Malus **−10** |
| kampfunfähig | bewusstlos | 5 | nein |
| schwer verwundet | sterbend (auch stabilisiert) | 10 | nein |

- **Zuschlag** für den schwersten erlittenen Kritischen: A +0, B +1, C +2, D +3, E +4 Tage.
- **Erneut verwundet:** die schlimmere Stufe, die Tage werden addiert.
- **Heilung:** jeder vergangene Spieltag (Reisen, Warten, Einsatz) zieht einen Tag ab; die Krankenstation (Hub) bringt je Tag mit einer Zweite-Hilfe-Probe +1 oder +2 Tage. Die Stufe bleibt bis zum letzten Resttag, danach unverletzt.

## 8b. Reise, Schiff, Credits

Entscheidungen des Nutzers (15.10.2026), umgesetzt im Hub (`godot/core/voyage.gd`, Werte im `HubState`).

**Reiseproben:** Je **Reisetag** vier Proben, Schwierigkeit **Mittel** (±0): **Pilot**, **Navigation**, **Computer**, **Reparatur** (`rsReparatur`). EP wie bei jeder Probe (Erfolg 2, Teilerfolg/Fehlschlag 1, Patzer 0) in der benutzten Fertigkeit.
- **Wer würfelt:** zuerst die **Station** (Steuer → Pilot, Navigation, Computer, Technik → Reparatur). Freie Posten übernehmen die Übrigen so, dass die Summe ihrer Werte am höchsten ist; jede Person höchstens einen Posten.
- **Nicht verfügbar:** Gesperrte (kampfunfähig, schwer verwundet) und wer in der **Krankenstation eingeteilt** ist (Arzt und Helfer, auch an Tagen ohne Patienten).

| Wert | Regel |
|---|---|
| Tank | 100, zu Beginn voll |
| Verbrauch je Reisetag | 10; je Probe in Pilot, Navigation, Computer: Teilerfolg −1, Erfolg −2, Herausragend −4; mindestens 3. Warten und Einsatz verbrauchen nichts |
| Leerer Tank | Die laufende Reise endet trotzdem am Ziel (**Notsprit**, kein Verbrauch); danach nur Kurs zum nächsten Hafen; das nächste Tanken kostet das Doppelte |
| Hülle | 100, zu Beginn voll. Reparaturprobe je Reisetag: Patzer −10, Fehlschlag −5, Teilerfolg ±0, Erfolg +2, Herausragend +4 (höchstens 100) |
| Hülle 0 | nur Kurs zum nächsten Hafen |
| Große Reparatur, Werft (Hafen) | +25 Hülle für 1 Schiffsmaterial + 40 Cr |
| Große Reparatur, Crew (überall) | 1 Tag, 1 Material, Reparaturprobe (Station Technik, sonst der Beste): Patzer −5, Fehlschlag ±0, Teilerfolg +10, Erfolg +20, Herausragend +40; das Material ist immer verbraucht |
| Schiffsmaterial | zu Beginn 2; 60 Cr im Hafen |
| Treibstoff | 5 Cr je Einheit, nach Notsprit 10 Cr |
| Credits | zu Beginn 300 |
| Lohn bei Sieg | leicht 80, mittel 140, schwer 220; Söldner der Roten Sonne und Vantar-Konzern ×1,2 |
| Beute bei Sieg | Schiffsmaterial: leicht 0, mittel 1, schwer 2; Schmuggler +1 |
| Munition (Schiffsvorrat je Art) | zu Beginn Energiezellen 200, Projektil 300, Raketen 6; Kauf im Hafen je Schuss 2 / 2 / 50 Cr (Pakete +30/+100, Raketen +1/+5); Verbrauch aus dem Einsatz wird abgezogen (Mitnahme und Feuerstoß: `core/ammo.gd`, Bodenkampf) |
| Munitions-Beute bei Sieg | eine zufällige Art: Energiezellen oder Projektil +10 bis +40, Raketen +1 |
| Niederlage, Rückzug | kein Lohn, keine Beute |
| Notkredit | Tanken geht immer, die Credits dürfen dabei ins Minus; der nächste Lohn gleicht aus. Material und Werft nur mit genug Credits (Ausnahme Hülle 0, siehe 9.) |

**Schiffsausbau** (Maschinenraum, `core/ship_upgrades.gd`, Entscheidungen des Nutzers 16.10.2026):

| Bereich | heute | Stufe 1 | Stufe 2 | Stufe 3 |
|---|---|---|---|---|
| Plätze an Bord | 8 | 9 | 10 | 12 |
| Tank | 100 | 130 | 160 | 200 |
| Hülle | 100 | 125 | 150 | 200 |
| Antrieb (Grundverbrauch je Reisetag) | 10 | 9 | 8 | 7 |
| Systeme (Bonus auf alle Reiseproben) | ±0 | +5 | +10 | +15 |
| Krankenstation (Bonus auf die Heilprobe, nur mit Personal) | ±0 | +10 | +20 | +30 |
| Trainingsraum (freie EP alle 5 Tage) | 3 | 4 | 5 | 6 |

- **Werft** (nur im Hafen, sofort, nur mit genug Credits): 600 / 1200 / 2200 Cr für Stufe 1 / 2 / 3.
- **Crew** (überall): 3 / 6 / 9 Schiffsmaterial (sofort verbraucht) und 3 / 5 / 8 Spieltage; am Ende eine Reparaturprobe (Mittel, Station Technik, sonst der Beste): Erfolg = fertig, Teilerfolg = 1 Tag länger, Fehlschlag oder Patzer = 1 Material verloren und 1 Tag länger. Nur ein Crew-Ausbau zur Zeit; wer baut, darf in Einsätze.
- Werkstatt-Ausbau folgt mit dem Handwerk.
- **Für den Raumkampf** (Entscheidungen des Nutzers 16.10.2026): Schilde, Panzerung, Reaktor (je Stufe 0–3, Wirkung im Kampf legt der Raumkampf fest) und **Waffenslots** (Start 4: Bug, Backbord, Steuerbord, Turm; 5 Stufen: + Heck, + Backbord 2, + Steuerbord 2, + Bug 2, + Turm 2). Preise und Material wie oben, Waffenslots Stufe 4/5: Werft 3200/4500 Cr, Crew 12/15 Material bei 10/12 Tagen.

**Schiff für den Raumkampf** (`core/ship_arms.gd`, Entscheidungen des Nutzers 16.10.2026, Schnittstelle `docs/module/raumkampf.md`):
- **Schiffswaffen** in Slots; Turm-Slots nur Abwehrwaffen, alle anderen jede andere Waffe. Ein- und Ausbau in der **Werft** (nur im Hafen), sofort, kostenlos; Waffen kommen aus dem Lager und gehen mit ihrem Schaden dorthin zurück. Startschiff: Bug Laserbank, Backbord Massebeschleuniger, Steuerbord Raketenwerfer, Turm Abwehrgeschütz.
- **Preise** aus dem Katalog des Raumkampfs (`ShipWeapons`, Platzhalter bis zur Simulation). Im zufälligen Hafensortiment (Gassenwissen). **Kauf und Verkauf nach Verhandeln** (Staffel wie Handeln: Kauf +20/+5/0/−10/−20 %, Verkauf 30/45/50/60/70 %), beschädigt je −10 um 25 % weniger.
- **Schiffsmunition** (getrennt vom Bodenvorrat): Schiffsraketen 60 Cr, Geschosse 3 Cr, Kauf und Verkauf nach Verhandeln. Startvorrat 6 / 40. Strahlwaffen brauchen Energie im Kampf.
- **Posten:** Steuer, Navigation, Schilde, Technik, Computer aus der Station in der Charakterübersicht; Geschützposten je bestücktem Slot im Maschinenraum (Crew ohne andere Station oder mit Station „Geschütze“, sonst Bord-KI). Verwundete ohne Einsatzfreigabe und Personal der Krankenstation: Bord-KI.
- **Systemschäden A–E** (E = ausgefallen) bleiben nach dem Kampf. Außerhalb des Kampfes: Antrieb → Pilot, Sensoren → Navigation, Reaktor → Computer, **je Stufe −5 auf die Reiseprobe**; **Antrieb E = keine Reise**, **Lebenserhaltung E = Proviant doppelt**. Schilde, Slots und Stationen wirken nur im Kampf.
- **Reparatur** von Systemen und beschädigten Schiffswaffen (Slot oder Lager): **Crew** überall, 1 Tag, 1 Schiffsmaterial, Reparaturprobe (Mittel, Station Technik, sonst der Beste): Patzer +1 Stufe bzw. −10 mehr, Fehlschlag/Teilerfolg nichts, Erfolg −1 Stufe bzw. −10 weg, Herausragend −2 Stufen bzw. −20 weg. **Werft** (nur im Hafen, sofort, nach Verhandeln): Systeme 50 Cr + 1 Material je Stufe, Waffen 10 % vom Kaufpreis je −10, ganz.

**Raumkampf im Spiel** (`core/space_events.gd`, Entscheidungen des Nutzers 16.10.2026):
- **Feindkontakt auf der Reise:** je Reisetag 5 % in neutralen Systemen, 20 % in Systemen einer Fraktion (Gegner = diese Fraktion, neutral = Piraten), höchstens einer je Reise. Die Reise hält an; Wahl: **ausweichen** (Probe Navigation, mittel, Reiseposten Navigation; Erfolg/Herausragend = ausgewichen, sonst Kampf) oder **kämpfen**. Danach fliegt das Schiff die übrigen Reisetage weiter (außer im Notfall).
- **Aufträge:** neu gewürfelt 60 % Boden (davon 25 % mit **Blockade**: erst Raumkampf, Sieg → Bodenkampf), 20 % **Abfangen** (Raumkampf, Lohn wie ein Bodeneinsatz plus Kampfbeute), 20 % **Eskorte** (Ziel 1–3 Reisetage, unterwegs sicher ein Raumkampf ohne Ausweichen, Lohn ×1,5 bei Ankunft). Flucht per Sprung: Auftrag bleibt offen (erneuter Versuch). Kapitulation: Lösegeld, Auftrag verloren (Eskorte bleibt offen).
- **Auswertung:** Hülle, Systemschäden, Slots, Schiffsmunition, Treibstoff, Lösegeld und Kampfbeute (Credits, Schiffsmaterial, Schiffsmunition, Schiffswaffen ins Schiffslager) bucht der Hub; EP und Verwundung der Raumkampf.
- **Notfall** (Niederlage gegen Gegner, die nicht entern, oder verlorener Bodenkampf gegen Enterer): **Plünderung** – 25 % der Credits (nur wenn positiv), 25 % jeder Schiffsmunition, bis zu 3 zufällige Stücke aus Lager und Schiffslager – dann **treibt** das Schiff: Hülle 0, nur noch Kurs zum nächsten Hafen. Gegner, die entern: Bodenkampf an Bord (Lagerhalle); gewonnen = abgewehrt.

**Lager und Handel** (`core/stock.gd`, Entscheidungen des Nutzers 16.10.2026): Das Schiff hat ein **Lager** mit Stückzahlen (Waffen, Rüstungen, Medikits; Munition bleibt im eigenen Vorrat). Zu Beginn leer – die Crew trägt ihre Ausrüstung. Im Hafen beim **Händler**: Kaufen ins Lager, Verkaufen aus dem Lager (Anteil nach Handeln), dazu Munition und Handwerksmaterial. Der **Schiffshändler** führt Treibstoff, Schiffsmaterial, Proviant, Schiffsmunition und Schiffswaffen (nach Verhandeln), die **Werft** Reparatur, Ausbau und Einbau (Entscheidungen des Nutzers 16.10.2026).

| Gegenstand | Preis | | Gegenstand | Preis |
|---|---|---|---|---|
| Vibroklinge | 120 Cr | | Flexanzug (leicht) | 150 Cr |
| Energiehammer | 250 Cr | | Kampfpanzer (mittel) | 350 Cr |
| Laserpistole | 150 Cr | | Servo-Rüstung (schwer) | 700 Cr |
| Laserkarabiner | 300 Cr | | Medikit | 30 Cr |
| Sturmgewehr | 280 Cr | | Schild | 150 Cr |
| Schweres MG | 500 Cr | | | |
| Raketenwerfer | 600 Cr | | | |

- Eigene Waffen/Rüstungen aus dem Editor: Preis der Vorlage, mit Vermerk „frei“ doppelt. Fäuste und „Keine“ sind kein Handelsgut.
- **Sortiment:** je Hafen ein zufälliger Anteil der Waffen/Rüstungen/Schilde (Gassenwissen, ohne Probe 50 %), neu gemischt alle 10 Spieltage; Medikits immer.

**Handelsfertigkeiten im Raumhafen** (`core/trade_skills.gd`, Entscheidungen des Nutzers 16.10.2026): Im Fenster wählt man je Fertigkeit, wer würfelt (Händler: Handeln und Gassenwissen, Schiffshändler: Verhandeln und Gassenwissen; Gassenwissen ist derselbe Wurf); Probe Mittel, **eine pro Tag und Hafen**, das Ergebnis gilt bis zum nächsten Tag. EP wie bei den Reiseproben. **Ohne Probe gilt das Ergebnis wie ein Fehlschlag.**

| Ergebnis | Handeln: Kauf | Handeln: Verkauf | Verhandeln | Gassenwissen (Sortiment) |
|---|---|---|---|---|
| Patzer | +20 % | 30 % | +20 % | 30 % |
| Fehlschlag / keine Probe | +5 % | 45 % | +5 % | 50 % |
| Teilerfolg | normal | 50 % | normal | 60 % |
| Erfolg | −10 % | 60 % | −10 % | 75 % |
| Herausragend | −20 % | 70 % | −20 % | 90 % |

- **Handeln:** Waffen, Rüstungen, Schilde, Munition, Medikits, Handwerksmaterial (Kauf und Verkauf). **Verhandeln:** Treibstoff, Proviant, Werft-Reparatur, Schiffsmaterial, Ausbau in der Werft, Schiffswaffen und Schiffsmunition (Kauf und Verkauf, Verkaufsanteil wie beim Handeln). **Gassenwissen:** Größe des Sortiments; mehr ergänzt das bisherige.

Gekauft wird im **Raumhafen** = neutrale Systeme (wie beim Anheuern).

**Waffenkammer am Lager** (`core/equipment.gd`, Entscheidungen des Nutzers 16.10.2026): Ausrüsten nimmt aus dem Lager, Ablegen legt zurück. Fäuste und „keine Rüstung“ sind immer verfügbar. Der **Schild** ist ein Lagergegenstand. **Medikits** (Anwendungen) nimmt eine Figur aus dem Lager, **höchstens 3**; im Einsatz verbrauchte fehlen danach. Ohne Spielstand (Schnellkampf) ist alles unbegrenzt.

Durchschnitt je Reisetag (simuliert, 200 000 Würfe): schwache Crew (alle Werte um −15) 9,6 Treibstoff, Hülle −4,6; Roster-Startcrew (Pilot +75, Navigation +0, Computer +20, Reparatur +55) 7,2 und +0,1; starke Crew (+90/+60/+60/+80) 4,9 und +1,5.

## 8c. Proviant und Kochen (Entscheidungen 16.10.2026)

Umgesetzt im Hub (`godot/core/galley.gd`, Werte im `HubState`; Planung `docs/Planung_Rueckzug_Proviant_Kochen.md`).

- **Proviant:** Startvorrat **60**; Kauf beim Schiffshändler im Hafen **5 Cr** je Einheit (nach **Verhandeln**, Entscheidung 16.10.2026). **Verbrauch je Tag 1 je Crewmitglied an Bord**, Reisetage zählen wie jeder Tag, **im Raumhafen kein Verbrauch**.
- **Kochen** (`kochen`, EMP + KOO): Ein **fester Koch** (Raum Kombüse) würfelt **jeden Tag außerhalb des Hafens** automatisch eine Probe (Mittel, EP wie bei jeder Probe). Ohne Koch – oder wenn der Koch gesperrt verwundet ist – gilt **Fehlschlag**. Der Koch darf zugleich Arzt, Helfer oder Handwerker sein.
- **Verbrauch nach Ergebnis:** Patzer +25 % · Fehlschlag normal · Teilerfolg −10 % · Erfolg −20 % · Herausragend −30 %; **kaufmännisch gerundet, mindestens 1**.
- **Mangel:** Reicht der Vorrat nicht, wird der Rest verbraucht. **Ohne Proviant −10 auf alle Proben im Schiff** (Reise, Handel, Heilung, Handwerk, Schiffsausbau, Kochen), **nicht im Bodenkampf**, bis wieder Proviant gekauft ist. Keine weiteren Folgen.
- **Training:** War unter den Kochproben seit dem letzten Training ein **Herausragend**, gibt das Training **+1 freie EP** (z. B. 4 statt 3).

## 9. Annahmen und offene Punkte

Diese Punkte habe ich festgelegt, ohne dass sie vorgegeben waren. Sie sind leicht zu ändern:

1. **Eigenschaftspaare** der Fertigkeiten (Abschnitt 3.2) sind mein Vorschlag.
2. **„Zweite Hilfe“**: Die Bedeutung weiß ich nicht; angenommen ist Behandlung nach dem Kampf.
3. **„Psi wirken“ vs. „Psi-Angriffe“**: angenommen ist, dass „Psi wirken“ für unterstützende Kräfte steht.
4. **„Panzerung“ (Raumschiff-Kampf)**: angenommen ist Schadenskontrolle / Panzerung umleiten.
5. **Zahlenwerte** (TP-Formel, Tabellen-Schwellen, Schadensfaktoren, EP-Kosten) sind ein erster Entwurf und noch nicht ausbalanciert.
6. **Munition (Entscheidungen 15.10.2026, `docs/Planung_Munition.md`):** Waffen mit Magazin brauchen Munition einer **Munitionsart** (Energiezellen, Projektil, Raketen; Schiffsvorrat je Art). Jede Figur nimmt je Waffe **3 Magazine** mit (Zweitwaffe **1 Magazin**), höchstens „Munition gesamt“ der Waffe, solange der Vorrat reicht; ohne Vorrat ist die Waffe im Kampf nicht nutzbar. **Feuerstoß:** Waffenwert *Schuss pro Angriff*; ab 2 Schuss ein Angriffswurf mit **+5 je Kugel** (MG: 3 Schuss = +15); reicht das Magazin nicht, mit dem Rest und anteiligem Bonus. Magazine der Standardwaffen (16.10.2026): Laserpistole 12, Laserkarabiner 20, Sturmgewehr 30, MG 60, Raketenwerfer 1 (2 insgesamt). Waffen ohne Magazinwert sind unbegrenzt.
7. Rolemaster arbeitet mit drei Eigenschaften pro Fertigkeit und ~20 Rüstungsarten; hier sind es zur Vereinfachung zwei Eigenschaften und vier Rüstungsklassen.
8. **Galerie** ist im Prototyp ein massiver Block (man kann nicht darunter hindurchgehen).
9. **Kosten für Eigenschaften** (2 + Wert/10) und die **Missionsbelohnung** sind ein erster Entwurf, nicht ausbalanciert.
9. **Höhen der Hallenobjekte** sind auf ganze Stufen (1,5 m) gerundet: Container 3 m statt real ca. 2,6 m.
10. **Aktivitätssystem:** Prinzip nach RMSS/RMFRP, alle Werte (Gangarten, Angriffsmodifikatoren, Kosten, Reserve 50 % vor dem ersten Zug, Feuerbereitschaft) sind eigene Vorschläge, nicht aus dem Regelwerk.
11. **Charaktererschaffung (7a):** Faktor 1,2, Ranggrenzen 5/8 und „niedrigster Wurf → 90“ sind festgelegt, aber noch nicht im Kampf getestet. Beliebig oftes Neuwürfeln erlaubt sehr starke Figuren (Eigenschaftssumme 600 und mehr in ca. 1 % der Würfe).
12. **Psi-Punkte:** Die neue Formel ergibt mehr PP als die alte (MEN 98: 19 statt 13 ohne Entwicklungsränge). Ob das mit „Kosten = Stufe“ passt, ist im Kampf zu prüfen.
13. **Psi-Listen (6.1)** sind ein Vorschlag. Im Spiel gibt es bisher nur Psi-Schild und Psi-Stoß, und sie sind noch nicht an Listen gebunden. Gedanken orten, Schwachstelle, Heranziehen und Schweben brauchen neue Mechanik im Bodenkampf.
14. **Startcrew** hat in Körperentwicklung, Psi-Punkte-Entwicklung und den Psi-Listen noch keine Ränge.
15. **Hülle 0 im Hafen ohne Credits** (8b): damit das Spiel nicht festsitzt, gehen Werft und Materialkauf bei Hülle 0 auch auf Notkredit. Vom Hub-Chat festgelegt, nicht vom Nutzer entschieden.
16. **Unbesetzter Reiseposten** (8b; zu wenig verfügbare Crew): keine Probe, keine Ersparnis beim Treibstoff, Hülle unverändert.

## Beute, Beschädigung und Verlust (Entscheidungen 16.10.2026)

- **Beschädigung** von Waffen und Rüstungen (Crew und Gegner): −10 je Schaden, summiert, ab −30 unbrauchbar. Waffe: Abzug auf Angriffe, ab −30 nicht nutzbar. Rüstung: Abzug auf die Verteidigung, ab −30 wie keine Rüstung. Ursachen im Kampf: Patzer „Waffe klemmt“ (41–70) beschädigt die eigene Waffe, ein Kritischer D oder E die Rüstung des Getroffenen. Am Kampfende (Sieg, Niederlage oder Rückzug) bekommt jedes Teil jeder kampfunfähigen Crew-Figur mit 25 % einen Schaden. Beschädigtes bleibt bis zur Reparatur beschädigt (mit Abzug nutzbar). **Gutes Stück** (+5, aus dem Handwerk bei „Herausragend“): Waffe +5 auf Angriffe, Rüstung +5 auf die Verteidigung; der erste Schaden nimmt den Bonus (+5 → 0 → −10 …). Beute ist nie +5.
- **Beute** bei Sieg: Waffen, Rüstungen und übrige Medikits der besiegten Gegner; Waffen mit 30 %, Rüstungen mit 60 % beschädigt (−10 bis −30, plus Schaden aus dem Kampf). Wie viel man mitnehmen kann, regelt die Beuteauswahl im Schiff.
- **Verlust** bei Niederlage ohne Rückzug: jedes Teil der zurückgebliebenen Figuren mit 50 %. Rückzug schützt.
- **Rückzug** (16.10.2026): eigener Ausgang im Einsatzbericht (nicht Niederlage); **der Auftrag bleibt offen** bis zum Ablaufdatum („erneuter Versuch“), kein Lohn, keine Beute, zählt nicht als erledigter Einsatz.
- **Beuteauswahl** im Einsatzbericht: mitnehmen kann man **1 Stück je Crewmitglied im Einsatz** (auch bewusstlose und sterbende zählen); vorausgewählt sind die wertvollsten. Medikits zählen nicht und gehen alle ins Lager; der Schild ist nie Beute. Nicht Mitgenommenes wird sofort als **Schrott** verkauft: 15 % vom Kaufpreis (gleich ob intakt, −10 oder −20), unbrauchbare Stücke (−30) bringen nichts; ohne Probe, auch außerhalb eines Hafens.
- **Beschädigte Stücke im Lager** liegen einzeln je Schaden („Sturmgewehr (−20)“); gleicher Schaden wird gezählt.
- **Reparatur:** (1) **Werkstatt im Raumhafen**: sofort und ganz, 10 % vom Kaufpreis je −10, nach Handeln (wie der Kauf von Ausrüstung); nur Stücke im Lager, Getragenes vorher in der Waffenkammer ablegen. (2) **Beschädigt verkaufen**: Verkaufspreis nach Handeln, je −10 um 25 % weniger (−10: 75 %, −20: 50 %, −30: 25 %). (3) Reparatur durch die Crew mit Probe kommt mit dem Handwerk.

## Handwerk (Entscheidungen 16.10.2026)

- **Handwerksmaterial**: eine Art, 1 Einheit = 10 Cr; im Raumhafen kaufen/verkaufen nach Handeln. Getrennt vom Schiffsmaterial.
- **Orte**: Werkstatt in der Waffenkammer (Waffen, Rüstungen, Munition; Fertigkeiten *Waffen herstellen* bzw. *Rüstung herstellen*), Krankenstation (Medikits; *Medikamente herstellen*). **Eine Arbeit je Figur**; der Handwerker ist nicht gesperrt (kann auf Einsätze). Probe am Ende der Arbeit, EP für die Fertigkeit (schwerere Proben geben mehr EP). **Schwierigkeit** beim Bauen und Reparieren von Waffen und Rüstungen nach Kaufpreis: bis 200 Cr mittel (±0) · bis 400 Cr schwer (−10) · bis 600 Cr sehr schwer (−20) · darüber extrem schwer (−30). Zerlegen, Munition und Medikits immer mittel.
- **Bauen**: Material im Wert von 50 % des Kaufpreises (aufgerundet), sofort verbraucht; Dauer 1 Spieltag je angefangene 200 Cr. Ergebnis: Patzer = Material weg · Fehlschlag Stück −20 · Teilerfolg −10 · Erfolg heil · **Herausragend +5** (Waffe +5 auf Angriffe, Rüstung +5 auf die Verteidigung). Munition (30 Energiezellen, 30 Projektil, 1 Rakete je Auftrag) und Medikits ohne Qualität: Patzer = Material weg, sonst das Stück. Auch eigene Ausrüstung aus dem Editor (Preis der Vorlage); Schild nicht.
- **+5-Stück**: Verkauf × 1,5; **der erste Schaden nimmt den Bonus** (+5 → heil → −10 …).
- **Zerlegen** (auch Beute und Beschädigtes): 1 Tag, Material nach Ergebnis 0 / 10 / 20 / 30 / 40 % des Kaufpreises (abgerundet).
- **Reparieren durch die Crew**: 1 Tag, Material 5 % des Kaufpreises je −10 (aufgerundet). Patzer −10 mehr · Fehlschlag nichts · Teilerfolg −10 weg · Erfolg heil · Herausragend heil und Material zurück.
- **Werkstatt-Ausbau** (Maschinenraum, Kosten wie die anderen Bereiche): Stufe 0 Bauen bis 200 Cr Kaufpreis · Stufe 1 +10 auf Handwerksproben, bis 400 Cr · Stufe 2 Dauer −50 % (mind. 1 Tag), alles baubar · Stufe 3 +20. Zerlegen und Reparieren auf jeder Stufe. Medikits bekommen stattdessen den Bonus des Ausbaus Krankenstation.
