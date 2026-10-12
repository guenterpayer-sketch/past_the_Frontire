# Past the Frontire

Party-RPG im Weltraum mit 6 Crewmitgliedern, rundenbasiertem Kampf am Boden und (geplant) im Weltraum.
Regelbasis: W100 im Rolemaster-Stil (offen nach oben und unten, über den Zielwert kommen), Angriffstabellen mit Kritischen Treffern, Erfahrung nur durch Benutzung.

## Starten

`index.html` im Browser öffnen (Doppelklick genügt). Es gibt keine Abhängigkeiten und keinen Build-Schritt.

## Prototyp: Bodenkampf 6 gegen 6

- Schauplatz: eine **Lagerhalle**, im Testmodus pro Mission zufällig klein (ca. 30×21 m), mittel (45×30 m) oder groß (60×40 m).
- Maßstab: **1 Hexfeld = 1,5 m**, 1 Höhenstufe = 1,5 m. Reichweiten in Metern mit Reichweitenstufen (−20 je Stufe).
- Höhen: Galerie mit Treppen und Leitern, Containerstapel, Hochregale, Kistenstapel.
- **Deckung**: halb (+20 VW, Kisten/Fässer/Barrieren) und voll (+40 VW, Container/Regale/Säulen); neben voller Deckung kann man um die Ecke schießen. Von oben herab sinkt die Deckung um eine Stufe.
- **Aktivitätssystem im RMSS-Stil**: Runde = 10 s, jede Figur hat 100 % Aktivität und teilt sie frei auf (Gehen/Laufen/Sprinten, Angriff mit 20–100 % = −40 bis +20, Erste Hilfe, Nachladen …). Übrige Aktivität ist Ausweichreserve. Initiative jede Runde neu, Crew und Gegner handeln gemischt.
- **Feuerbereitschaft**: Aktivität zurückhalten und auf den ersten Gegner schießen, der im Sichtfeld handelt.
- **Blickrichtung**: Sichtfeld 180°; Angriffe von der Flanke (+15) oder von hinten (+30) überraschen das Ziel (kein Ausweichen, kein Schild; Kampfsinn-Probe halbiert).
- Crew (Sturmgewehr, 2× Laserpistole, MG, Psi, Vibroklinge + Schild) gegen 6 Söldner (2× Gewehr, MG in Servo-Rüstung, Raketenwerfer, Klingenkämpfer, Psi-Hexer).
- Nach dem Kampf: Erfahrung pro benutzter Fertigkeit, Ränge steigern, 3 freie EP pro Figur. Der Fortschritt wird im Browser gespeichert (`localStorage`).

**Bedienung**

| Aktion | Eingabe |
|---|---|
| Bewegen | Gangart wählen, blaues Feld anklicken (Weg und Kosten in % werden angezeigt) |
| Angreifen | Aktivität für den Angriff wählen (20–100 %), rot umrandeten Gegner anklicken; Maus darüber zeigt Trefferchance und alle Modifikatoren |
| Feuerbereitschaft / Nachladen | Buttons im rechten Panel |
| Drehen | Rechtsklick auf ein Feld oder „Ausrichten“ |
| Waffe wählen | Waffen-Buttons im rechten Panel |
| Erste Hilfe / Psi-Schild | Button, dann grün markierte Figur anklicken |
| Abbrechen | Esc |
| Zug beenden | Button oder Enter (übrige Aktivität wird Ausweichreserve) |
| Kamera | Mausrad = Zoom, Ziehen oder Pfeiltasten/WASD = verschieben, +/− = Zoom |
| Zuschauen / Testen | „KI für Crew“ |

## Dokumente

- `docs/Charakterbogen_Grundgeruest.md` – das ursprüngliche Grundgerüst
- `docs/Skillsystem.md` – Eigenschaften, Fertigkeiten, Proben, Kampf, Kritische Treffer, Steigerung
- `docs/Raumkampf.md` – Regel-Gerüst für den Raumkampf (Mutterschiff mit Stationen + 2–3 Jäger), noch nicht umgesetzt

## Code

| Datei | Inhalt |
|---|---|
| `js/dice.js` | seedbarer Zufall, offener W100 |
| `js/rules.js` | Eigenschaften, Fertigkeiten, Proben, Erfahrung, abgeleitete Werte |
| `js/tables.js` | Rüstung, Waffen, Angriffstabellen, Kritische Treffer, Patzer |
| `js/hex.js` | Hex-Koordinaten, Linien |
| `js/map.js` | Hallenobjekte, Lagerhallen-Generator, Sichtlinie, Deckung, Wegfindung |
| `js/units.js` | Crew und Gegner |
| `js/combat.js` | Kampfablauf und Aktionen (ohne Grafik) |
| `js/ai.js` | Gegner-KI |
| `js/render.js` | isometrische Canvas-Grafik |
| `js/ui.js` | Steuerung, Panels, Charakterbogen, Tabellen, Kampfende |

Test (Regeln + 200 Kämpfe KI gegen KI): `node tests/sim.js`
