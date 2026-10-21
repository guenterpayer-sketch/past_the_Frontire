# Planung: Munition, Feuerstoß, Bestand (15.10.2026)

Entscheidungen des Nutzers (Koordinations-Chat).

## Stand im Code (geprüft)

- Jede Waffe hat `magazine` und `ammo_total` (`data/types/weapon_data.gd`); 0 = unbegrenzt. Heute nur der Raketenwerfer mit Munition.
- Jeder Angriff verbraucht 1 Schuss (`core/combat.gd` `_resolve_attack`), leere Waffe ist nicht wählbar, Nachladen 30 % Aktivität, KI lädt nach.
- Jeder Einsatz beginnt mit voller Munition (`core/combatant.gd`); `MissionResult` meldet den Verbrauch, er wird nirgends abgezogen.
- Feuerstoß = fester Angriffsbonus `ob_bonus` (MG +15), kostet 1 Schuss. Keine Regel in `docs/Skillsystem.md`.

## Entscheidungen

1. **Munitionswerte** trägt der Nutzer selbst ein (über den Ausrüstungs-Editor, `docs/archiv/Planung_Ausruestungs_Editor.md`); vorhandene Waffen behalten ihre Werte, bis er sie ändert.
2. **Feuerstoß:** neuer Waffenwert **Schuss pro Angriff** (z. B. 3 bei „3/30“). Wirkung: **ein Angriffswurf mit Bonus** (wie heute `ob_bonus`), verbraucht aber die Schuss pro Angriff. **Fest je Waffe** (keine Wahl Einzel/Feuerstoß).
3. **Bestand:** **Schiffsvorrat je Munitionsart** (z. B. Energiezellen, Projektil, Raketen; Waffen gleicher Art teilen sich den Vorrat). Neuer Waffenwert **Munitionsart**. Verbrauch nach dem Einsatz vom Vorrat abziehen; **Kauf im Raumhafen**.

## Aufteilung (Vorschlag Koordinator)

- **Bodenkampf (zuerst):** `WeaponData` um *Schuss pro Angriff* und *Munitionsart* erweitern; Verbrauch je Angriff; beim Einsatzstart Munition aus einem übergebenen Vorrat statt immer voll (Schnellkampf: voll); `MissionResult` meldet Verbrauch je Munitionsart; KI-Verhalten bei leeren Waffen prüfen (`test_sim`). Liste der Munitionsarten festlegen (mit dem Nutzer).
- **Hub (danach):** Schiffsvorrat je Munitionsart im Spielstand, Anzeige, Kauf im Raumhafen, Abzug nach dem Einsatz, Übergabe an den Kampf; im Ausrüstungs-Editor die neuen Felder.
- Schnittstelle (Übergabe Vorrat → Kampf, Rückgabe Verbrauch) stimmen Bodenkampf und Hub ab und tragen sie unter „Schnittstellen“ ein.

## Offen (mit dem Nutzer klären)

- Munitionsarten und Zuordnung der vorhandenen Waffen; Preise.
- Verteilung des Vorrats auf die Trupp-Mitglieder beim Einsatzstart (z. B. je Waffe bis zu Magazin × N, Rest bleibt an Bord).
- Was passiert bei leerem Vorrat (Waffe nur mit dem, was geladen ist / gar nicht nutzbar).
