# Planung: Schiffsausbau, Lager, Beute, Handwerk (16.10.2026)

Ziel des Nutzers: Motivation, Credits zu jagen. Entscheidungen des Nutzers (Koordinations-Chat).

## Entscheidungen

**Schiffsausbau**
- Ausbaubar: **Plätze an Bord** (heute 8), **Tank und Hülle**, **Räume** (z. B. Krankenstation: Heilbonus; Waffenkammer/Werkstatt: Lager und Handwerk; Training), **Antrieb/Systeme** (weniger Verbrauch, Bonus auf Reiseproben).
- Ausbau **beides**: in der **Werft im Raumhafen** (Credits, schnell/teuer) oder **durch die Crew an Bord** (Schiffsmaterial + Technik-Probe, langsam/billig).

**Lager (Bestand der Waffenkammer)**
- **Stückzahl je Gegenstand** (Waffen, Rüstungen, Munition, Medikits); Ausrüsten nimmt aus dem Lager, Ablegen legt zurück.
- **Start:** nur was die Crew trägt, Lager leer.
- **Quellen:** Kauf im Raumhafen, Beute nach Sieg, Verkauf im Hafen, Bauen (Handwerk).
- **Eigene Waffen/Rüstungen** aus dem Editor: **kaufbar und baubar**.

**Beute und Verlust**
- **Sieg:** Auswahl aus der Ausrüstung der besiegten Gegner (bis zu N Stück, Tragkraft – Wert offen).
- **Niederlage:** Kampfunfähige/Sterbende, die zurückbleiben, verlieren mit einer Chance ihre Ausrüstung; **Rückzug schützt** (kein Verlust).

**Handwerk**
- Material: **Schiffsmaterial** (gibt es) und neu **Handwerksmaterial**.
- Fertigkeiten (gibt es, `core/rules.gd`, Gruppe Handwerk): **Waffen** (`hwWaffen`, auch Munition), **Rüstung** (`hwRuestung`), **Medikamente herstellen** (`medikamente`, Medikits). (Kochen bleibt ohne Verwendung.)
- **Zerlegen:** Waffen/Rüstungen (auch Beute) zu Handwerksmaterial; Menge je nach Probenerfolg.
- **Bauen:** alles Verbrauchbare (Munition, Medikits) sowie Waffen und Rüstungen (auch eigene aus dem Editor), z. B. um bessere/teurere Waffen zum Verkaufen herzustellen.
- **Ort:** Waffenkammer/Werkstatt (Waffen, Rüstungen, Munition; Werkstatt ausbaubar) und Krankenstation (Medikits).
- **Dauer in Spieltagen**; der Handwerker ist **nicht gesperrt**, er kann trotzdem auf Einsätze.

## Stand im Code (geprüft)

- Medikits je Figur (`Character.medkits`), Verbrauch wird gemeldet, aber nicht ausgewertet.
- Waffenkammer heute mit unbegrenztem Bestand (`ArmoryDialog`, Charakter-Modul).
- Credits, Schiffsmaterial, Raumhafen, Werft (Hülle) im Hub (`core/voyage.gd`).

## Aufteilung und Reihenfolge (Vorschlag Koordinator)

1. **Hub – Schiffsausbau** (unabhängig, kann sofort beginnen).
2. **Hub – Lager** im Spielstand (Stückzahlen), Kauf/Verkauf im Raumhafen (Sortiment, Preise), Schnittstelle zum Lager für die anderen Module.
3. **Charakter – Waffenkammer am Lager** (Ausrüsten nimmt/legt zurück, Medikits aus dem Lager); danach.
4. **Bodenkampf – Beute und Verlust im `MissionResult`** (Gegnerausrüstung der Besiegten; verlorene Gegenstände bei Niederlage ohne Rückzug); **Hub** zeigt danach die Beuteauswahl im Einsatzbericht und bucht ins Lager.
5. **Hub – Handwerk** (Zerlegen, Bauen, Aufträge über Spieltage, Werkstatt in der Waffenkammer, Medikits in der Krankenstation), sobald Lager steht.

Jeder Schritt: Zahlen (Preise, Ausbaustufen, Materialmengen, Bauzeiten, N der Beute) und Mockups vorher mit dem Nutzer klären. Regeln danach in `docs/Skillsystem.md`.
