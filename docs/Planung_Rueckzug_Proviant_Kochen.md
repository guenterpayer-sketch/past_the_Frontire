# Planung: Rückzug im Bericht, Proviant und Kochen (16.10.2026)

Entscheidungen des Nutzers (Auswahl im Koordinations-Chat).

## Rückzug
- Heute: Rückzug endet als `outcome = niederlage`; der Bericht hat nur „(Rückzug)“ im Titel. Ausrüstung: Rückzug schützt vor Verlust (50 % nur bei Niederlage ohne Rückzug), Kampfunfähige bekommen auch beim Rückzug mit 25 % je Teil einen Schaden – bleibt so.
- **Neu:** eigener Ausgang **„Rückzug“** im Einsatzbericht (eigene Farbe/Text statt Niederlage); **der Auftrag bleibt offen** und kann bis zum Ablaufdatum erneut versucht werden. Kein Lohn, keine Beute (wie bisher).
- Dafür braucht der Hub ein Merkmal im `MissionResult` (Vorschlag: `retreated: bool`) → Bodenkampf.

## Proviant
- Neue Ressource **Proviant** im Spielstand; **Kauf im Raumhafen, 5 Cr** je Einheit (nach Handeln).
- **Verbrauch: 1 je Crewmitglied an Bord und Tag**, Reisetage zählen wie jeder Tag. **Im Raumhafen kein Verbrauch** (Restaurants).
- **Ohne Proviant: −10 auf alle Proben**, bis wieder Proviant da ist.

## Kochen (`kochen`, EMP + KOO)
- **Eine Kochprobe je Tag** (nicht im Raumhafen, dort wird nicht gekocht), Koch frei wählbar wie beim Handel; **EP** für die Fertigkeit wie bei allen Proben.
- **Verbrauch nach Ergebnis:** Patzer +25 % / Fehlschlag normal / Teilerfolg −10 % / Erfolg −20 % / Herausragend −30 %.
- **Training:** war unter den Kochproben der 5 Tage bis zum Training ein **Herausragend**, gibt das Training **+1 freie EP** (also 4 statt 3).
- Offen (Hub klärt mit dem Nutzer): Rundung beim Verbrauch, ob ohne gewählten Koch automatisch „Fehlschlag“ gilt (wie beim Handel), Startvorrat, Mockup.
