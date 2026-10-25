
## Früherer Stand (archiviert 19.10.2026)

## Stand

- (18.10.2026, `9228e24`) Absturz beim Ändern der Farbe in der Charakterübersicht behoben (`ColorPickerButton` nicht mehr im eigenen `popup_closed` aus dem Baum genommen), Autotest für alle drei Farbknöpfe. Details im Archiv.
- Alle Aufträge bis 16.10.2026 erledigt und in `main`. Verlauf im Archiv (siehe oben), Zusammenführungen in `docs/Zusammenfuehrung.md`.
- Neue Fertigmeldungen hier kurz eintragen (Commit, was neu, Schnittstellenänderungen). Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.
- **Fertig (18.10.2026): Fertigkeitstexte „ohne Wirkung“.** `core/skill_texts.gd`: `SOON` entfernt (Konstante gelöscht), die 9 Texte sagen jetzt, wo die Fertigkeit wirkt (Geschützstation, Station Schilde, Station Technik, Raumhafen). Danach trägt keine Fertigkeit mehr `SOON`; alle Fertigkeiten aus `Rules` haben einen Text. Keine Schnittstellenänderung.



### Auftrag (25.10.2026): Waffenkammer läuft rechts aus dem Bild – erledigt (`bb43695`)

Ergebnis: Ursache war die Waffentabelle rechts (Namensspalte bis 336 px bei „Scharfschützengewehr (−30, unbrauchbar)“, Reichweite 201 px; zusammen 1000 px statt ~690 px Platz), nicht die Reiterzeile (12 Figuren ≈ 750 px). Jetzt: Namen und Zustand brechen um (Zustand in eigener Zeile), Fertigkeit/Reichweite/Besonderes brechen um, Hinweise im Reiter „Lager“ ebenso, Crew-Reiter als `HFlowContainer` (zweite Zeile bei vielen Figuren), linke Spalte 360 statt 400 px, langer Waffenname im Platz links mit „…“. Gemessen mit 12 Figuren bei 100 % und 125 %: Fenster bleibt 1180 px breit. Keine Änderung an Schnittstellen.

Fehler (Screenshot des Nutzers, 1920 × 1080, Spielstand mit 10 Figuren): Das Fenster „Waffenkammer“ (`ui/crew/armory_dialog.gd`) ist breiter als der Bildschirm, rechts sind die Reiterzeile der Crew, die Tabelle (Spalte „Besonderes“) und der Knopf „Fertig“ abgeschnitten.
Vermutung des Koordinators (ungeprüft): Die Reiterzeile mit allen Crewmitgliedern (je Knopf feste Mindestbreite) oder lange Waffennamen („Scharfschützen Gewehr (frei) (−30, unbrauchbar)“) erzwingen die Breite.
1. Ursache finden; das Fenster bleibt nach `docs/Layout.md` in fester Größe (`max_size`), Inhalte passen sich an (Reiter umbrechen oder scrollen, lange Namen umbrechen/kürzen). Auch mit 10–12 Figuren und UI-Größe 125 % prüfen.
2. `main` vor dem Arbeiten holen (Branch ist weit zurück). Tests nach CLAUDE.md, Screenshot der Waffenkammer, Fertigmeldung.
