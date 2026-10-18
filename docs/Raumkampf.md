# Past the Frontire – Raumkampf (Regel-Gerüst, noch nicht im Prototyp)

Stand: Entwurf, angeglichen an die Entscheidungen des Nutzers vom 16.10.2026 (`docs/Planung_Raumkampf.md`). Noch nicht gebaut. Dieses Dokument legt fest, wie der Raumkampf an das Skillsystem (`Skillsystem.md`) anschließt.

**Crew-Aufteilung:** Version 1 nur mit dem **Mutterschiff**; die ganze Crew an Bord besetzt Stationen. Stationen sind **feste Posten an Bord** (im Hub festgelegt) und vor dem Kampf änderbar. **Eigene Jäger kommen in Version 2** (dann 2–3 Personen in Jägern, Rest an den Stationen). Gegner haben schon in Version 1 Jäger.

---

## 1. Karte und Ablauf

- Hexkarte wie am Boden, ohne Höhe. Statt Höhe gibt es **Hindernisse** (Asteroiden: Deckung, Trümmer: Bewegungskosten, Nebel: Sichtmalus).
- Schiffe haben eine **Ausrichtung** (eine der 6 Hexseiten) und eine **Geschwindigkeit** (Felder pro Runde, die beibehalten wird: Trägheit).
- Darstellung **3D**, Hexfelder auf einer Ebene (wie der Bodenkampf).
- Initiative pro **Schiff/Jäger** = 2W10 + Navigation-Gesamtbonus / 5 (Mutterschiff) bzw. Pilot-Gesamtbonus / 5 (Jäger).
- **Runde in Phasen** (Entscheidung des Nutzers), innerhalb jeder Phase nach Initiative: **Schilde → Bewegen → Schießen → Technik/Computer**. Die Schildphase liegt vor dem Schießen.

## 2. Mutterschiff: Stationen

Jede besetzte Station handelt einmal pro Runde mit der passenden Fertigkeit.

| Station | Fertigkeit | Aktion |
|---|---|---|
| Steuer | Pilot | Bewegen/Drehen; der halbe Pilot-Gesamtbonus ist der VW des Schiffs |
| Navigation | Navigation | Initiative, Kurs plotten (+1 Geschwindigkeit ohne Malus), Sprung vorbereiten |
| Geschütze (mehrere) | Strahl- / Ballistische / Raketen-Geschütze | Je Geschützstation Angriff mit einer Waffengruppe (Waffen in Slots) |
| Punktverteidigung | Ballistische Geschütze (Vorschlag) | Abwehr gegen Jäger und Raketen; Hauptgeschütze können Jäger ebenfalls treffen |
| Schilde | Schutzschild | Schildpunkte zwischen Bug/Heck/Seiten verschieben, regenerieren |
| Technik | Panzerung / Not-Reparatur / Reparatur | Systemschaden beheben, Hüllentreffer umleiten |
| Computer | Computer | Zielerfassung (+AW für eine Station), Störsender (−AW für Gegner) |

- Freie Stationen: je Station wählbar (Entscheidung des Nutzers) – **Doppelbesetzung** durch eine Person (beide Würfe −30) oder **Bord-KI** mit festem Bonus +0 (Entscheidungen des Nutzers).

## 3. Jäger (eigene ab Version 2, gegnerische ab Version 1)

- Eine Person pro Jäger: **Pilot** für Bewegung und VW, Waffenfertigkeit (meist Strahl-Geschütze oder Raketen-Geschütze) für den Angriff.
- Aktivitätssystem wie am Boden (100 % pro Runde für Bewegen, Angriff, Ausweichmanöver; übrige Aktivität = Ausweichreserve).
- Jäger haben wenig Struktur und keinen Schild, aber einen hohen VW.

## 4. Treffer und Schaden

- Gleiche Formel: **offener W100 + AW − VW + Modifikatoren**, Nachschlagen auf einer Schiffswaffen-Tabelle (Strahl, Ballistik, Rakete) mit den Spalten **Jäger / leicht / mittel / schwer**.
- Treffer gehen erst auf den **Schild der getroffenen Seite**, der Rest auf die **Struktur**.
- **Kritische Systemtreffer** (A–E) statt Körper-Kritischer: Antrieb, Waffen, Schilde, Sensoren, Lebenserhaltung, Crew-Station (eine Person an der Station bekommt einen Kritischen der Art Explosion; Verwundung wie am Boden).
- Nach dem Kampf: Hüllenschaden geht auf die Schiffshülle im Hub, **Systemschäden bleiben bis zur Reparatur**.

## 4a. Schiff: Waffen, Schilde, Munition

- Schiffswaffen sitzen in **Slots** (konkrete Waffen, Kauf im Raumhafen, Beute aus Wracks ins Lager). **Schilde und Schiffspanzerung** sind **Ausbau-Stufen** wie Hülle oder Tank.
- **Eigene Schiffsmunition** (Schiffsraketen, Geschosse), getrennt vom Munitionsvorrat der Crew. Strahlwaffen brauchen **Energie**.
- **Energie im Kampf:** Der Reaktor (Ausbau-Stufe) gibt je Runde Energiepunkte; die Schild-Station verteilt sie auf Strahlwaffen, Schild-Aufladung, Antrieb und die Sprungvorbereitung.
- Slots: Start Bug, Backbord, Steuerbord, Turm; mehr durch Ausbau (Heck, Bug 2, Turm 2). Turm-Slots nur für Abwehrwaffen.

## 4b. Kampfende

- Sieg: Beute aus Credits, Schiffsmaterial, Schiffsmunition, Schiffswaffen.
- **Flucht per Sprung** (Navigation bereitet vor, kostet Treibstoff), **Kapitulation/Lösegeld** (nur bei passenden Gegnern).
- Niederlage **je nach Gegner**: **Entern** (Übergang in den Bodenkampf; vorerst Lagerhalle als Platzhalter) oder **Notfall** wie bei Hülle 0 auf der Reise.

## 5. Erfahrung

Jede Stationsaktion ist eine Probe der jeweiligen Fertigkeit und bringt EP nur dieser Fertigkeit, aber **höchstens 2 EP je Station und Runde** (Entscheidungen des Nutzers 18.10.2026):
- **Schützen** (Geschütze, Punktverteidigung): +1, wenn die Station in der Runde gefeuert oder abgefangen hat, +1 bei mindestens einem Treffer (gelungenes Abfangen zählt als Treffer). Nicht mehr je Schuss.
- **Steuer, Schilde, Computer, Technik** (jeder Techniker einzeln): normale Probe-EP, auf 2 je Runde gekürzt (z. B. 2. Baustelle).
- **Navigation:** Initiative-Probe (mittel) zu Rundenbeginn, Erfolg +2, Herausragend +4 auf die Initiative; dazu die Sprungvorbereitung, zusammen höchstens 2 EP je Runde.
- Wer zwei Stationen bedient (Doppelbesetzung), bekommt die EP **je Station**. Keine Obergrenze je Kampf.

## 6. Offene Fragen

- ~~Kombination mit Bodenkampf~~: ja, Entern nach Niederlage (je nach Gegner) und Raumkampf vor einem Bodeneinsatz.
- ~~Schiffsausbau~~: ja, Waffen in Slots, Schilde/Schiffspanzerung als Stufen.
- Wie viele Gegnerschiffe und -jäger sind ein typischer Kampf je Schwierigkeit?
- Zahlenwerte, Tabellen, Hindernisse auf der Karte: siehe `docs/Planung_Raumkampf.md`, Abschnitt „Offene Punkte“.
