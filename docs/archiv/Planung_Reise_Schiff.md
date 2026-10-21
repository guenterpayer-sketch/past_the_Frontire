# Planung: Reise, Schiff, Credits (15.10.2026)

Entscheidungen des Nutzers (Koordinations-Chat). Umsetzung: **Hub-Modul allein** (`docs/module/hub.md`). Bodenkampf und Charakter bauen nichts.

## Reiseproben

- Bei jeder Reise (`HubState.travel_to()`) **pro Reisetag** je eine Probe in **Pilot, Navigation, Computer** und **Reparatur** (`rsReparatur`, Gruppe Raumschiff-Technik, `core/rules.gd`).
- **Wer würfelt:** nach **Station** des Charakters (`Character.station`: Steuer → Pilot, Navigation, Computer, Technik → Reparatur). Ist die Station unbesetzt oder die Person nicht verfügbar (z. B. verletzt) oder schon einer anderen der vier Reisestationen zugeteilt, übernimmt **das verfügbare Crewmitglied mit dem höchsten Wert** in der Fertigkeit; es bekommt dann auch die EP.
- **Erfahrung** in der benutzten Fertigkeit (wie im Kampf: nur benutzte Fertigkeiten), Verbuchung über das vorhandene `Character.apply_result` bzw. denselben Weg wie die EP der Krankenstation.
- **Wirkung:**
  - Erfolgreiche Proben in Pilot, Navigation, Computer **senken den Treibstoffverbrauch**.
  - Misslungene Reparaturprobe **beschädigt die Hülle**, erfolgreiche **repariert** sie (wenig, ohne Material).

## Schiff

- Neue Werte: **Treibstoff** (Tank), **Hülle** (Zustand), **Schiffsmaterial**, **Credits** – im Spielstand speichern, im Schiff anzeigen.
- **Leerer Tank:** Notsprit bis zum nächsten Raumhafen, dort Tanken mit **100 % Aufschlag**.
- **Hülle 0:** Reise nur noch bis zum nächsten Hafen.
- **Schiffsmaterial:** nur für **große Reparaturen** nötig; kaufbar im Raumhafen, außerdem Beute bei erfolgreichen Einsätzen.

## Credits

- Einnahmen: **Missionslohn** bei Sieg; **Beute** (Material) bei Sieg. Höhe nach **Fraktion und Schwierigkeit** des Auftrags (Missionstypen gibt es noch nicht).
- Ausgaben: **Treibstoff kaufen**, **Reparatur kaufen** (Werft), **Schiffsmaterial kaufen**.

## Offen (Hub-Chat schlägt vor, Nutzer bestätigt vor dem Bauen)

- Alle Zahlen: Tankgröße, Verbrauch pro Tag, Ersparnis je Erfolg (ggf. nach Ergebnisstufe), Hüllenschaden/Reparatur je Probe, Größe einer „großen Reparatur“ und ihr Materialbedarf, Preise, Startcredits, Lohn und Beute je Fraktion/Schwierigkeit, EP je Probe.
- Wo gekauft wird (Raumhafen = neutrales System?) und Anzeige im Schiff/Reisebericht → Mockup vor dem Bauen.
- Später: Hüllenschaden im Raumkampf, Kosten beim Anheuern/Sold.
