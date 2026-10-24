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
| Computer | Computer | Zielerfassung (+AW für eine Station), Störsender (−AW für Gegner), Scannen (voller Zustand eines Gegners, 4d) |

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
- Niederlage **je nach Gegner**: **Entern** (Übergang in den Bodenkampf an Bord) oder **Notfall** wie bei Hülle 0 auf der Reise.

## 4c. Entern (Entscheidungen des Nutzers 18.10.2026)

Grundidee: Schiffe sind kostbar und werden nicht bis zum Letzten zerstört; eine Niederlage ist nicht endgültig – ein gewonnener Enterkampf wendet das Blatt (für beide Seiten).
- **Wrack:** Ein Schiff mit Besatzung bei Hülle 0 wird nicht zerstört, sondern zum Wrack (manövrierunfähig, kämpft nicht mehr, bleibt enterbar). Jäger und Drohnen werden weiter zerstört.
- **Selbst entern:** möglich, wenn ein Gegnerschiff **Antrieb E**, **Hülle unter 25 %** oder **Wrack** ist und **kein anderes Gegnerschiff mehr kämpft** (Jäger dürfen übrig sein und ziehen beim Entern ab). Die Entfernung ist egal. Das Spiel fragt „Entern ja/nein“.
- **Pilotenprobe zum Andocken** (Station Steuer, ein Versuch je Runde): Nachbarfeld leicht, 2–3 Felder mittel, 4–6 schwer, 7+ sehr schwer; **+20**, wenn das Ziel Antrieb E hat oder ein Wrack ist. Erfolg = angedockt, der Raumkampf endet, es folgt ein Bodenkampf an Bord des Gegners. Fehlschlag = der Kampf geht weiter. **Patzer = Kollision** (beide Schiffe 2W6 Hülle).
- Kämpft kein Gegner mehr und nur Wracks/angeschlagene Schiffe sind übrig, wartet der Kampf auf die Entscheidung: „Nein“ = Sieg ohne Entern; nach 3 Fehlversuchen endet er als Sieg.
- **Gegner entern früher:** Seiten mit `on_win = "entern"` versuchen anzulegen, sobald die Frontire **Hülle unter 25 %** oder **Antrieb E** hat: das Schiff fliegt heran und würfelt dieselbe Probe mit dem Bonus seiner Besatzung (statt seiner Bewegung, ein Versuch je Runde). Gelingt sie, folgt der Bodenkampf an Bord der Frontire. Bei Hülle 0 entern sie wie bisher.
- **Blatt wenden:** Gewinnt die Crew den Bodenkampf, gilt der Raumkampf als gewonnen – beim eigenen Entern mit der Beute an Bord, beim abgewehrten Entern mit der Beute des Enterschiffs (`board_loot`, bucht der Hub).

## 4d. Gegner-Info und Scan (Entscheidungen des Nutzers 23.10.2026)

- **Ohne Scan** sieht die Crew vom Gegner: Hülle grob in 3 Stufen (intakt über 50 %, beschädigt 25–50 %, schwer beschädigt unter 25 %), Schilde nur an/aus je Seite, Systemschäden nur aus **eigenen Treffern** (mit Runde). Systemtreffer anderer Herkunft (z. B. Patzer des Gegners) stehen nicht im Log.
- **Scannen** (Computer-Station, statt Zielerfassung oder Störsender, Probe wie Zielerfassung): bei Erfolg zeigt das Ziel **3 folgende Runden** lang alles (Hülle, Schild je Seite, alle Schäden). Danach bleibt der letzte Stand als „veraltet (Stand Runde X)“, dazu weiter die eigenen Treffer.
- Anzeige: Warnzeichen ⚠ am Namen nur bei bekannten Schäden ab C, Tooltip mit der Maus über dem Schiff, Klick schreibt den bekannten Stand ins Log.
- Die Gegner-KI kennt weiter alles; die Bord-KI scannt nicht von selbst (der Vorschlag bleibt Zielerfassung), Scannen ist eine Abwägung des Spielers.

## 4e. Gegner nach Crew-Stärke und Elite (Entscheidungen des Nutzers 24.10.2026)

- **Crew-Stärke P** = Mittel aus Pilot und den zwei besten Geschützstationen (ohne Turm), beim Kampfstart nach den Posten.
- **Normale Kämpfe (moderat):** Gegner-Besatzung + (P − 56) × 0,2, 0 bis +10. Schwache Crews merken nichts, starke etwa +4 bis +10.
- **Elite-Kämpfe** (`setup.enemy.elite`, gemeinsame Regel mit dem Bodenkampf: etwa jeder 7.–8. Kampf, vorher erkennbar): Waffen eine Stufe besser (Laserbank → Partikelkanone, Massebeschleuniger → Schnellfeuerkanone, Raketenwerfer → Raketenbatterie, Abwehrgeschütz → Abwehrlaser), Schilde +4 je Seite und +1 Aufladung (nicht Jäger), Besatzung (P − 56) × 0,5, −20 bis +30. Ziel: etwa 70–75 % Siege für jede Crew. Im Kampf „★ Elite-…“ in Gold.
- **Stationstreffer:** 25 % der Systemtreffer (vorher 15 %), damit im Raum Verletzte möglich werden.
- **Boss-Kampf** (`setup.enemy.boss`, Ende einer Story-Kette im Raum oder Auftrag gegen eine Person): Boss-Kreuzer mit Elite-Ausrüstung, Hülle ×1,3 und Namen (`boss_name`, sonst „Flaggschiff“), flieht nie; dazu 2 Jäger als Leibwache. Besatzung wie Elite −10. Nach 40 Runden drehen die Gegner wie sonst ab. Im Kampf „★★ Boss: …“.
- **Schwierigkeitsgrad** (Spieleinstellung, `setup.difficulty_factor` 0,8 / 1,0 / 1,25, Entscheidung des Nutzers 24.10.2026): Gegner-Hülle × (1 + (f − 1) × 0,5) und Besatzung + (f − 1) × 25 (leicht: Hülle ×0,9, −5; schwer: Hülle ×1,125, +6). Gilt für alle Kämpfe, auch Elite und Boss.
- **Waffen-Beute** (24.10.2026): Elite/Boss nach dem Sieg mit 20 % eine Elite-Waffe (−20/−30). Entern bringt höchstens eine Waffe: normal mit 50 % (−10…−30), Elite/Boss mit 30 % (−20/−30). Vorher brachte Entern alle Waffen des Schiffs, meist unbeschädigt.

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
