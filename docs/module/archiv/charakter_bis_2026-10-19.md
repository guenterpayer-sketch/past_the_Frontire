
## Früherer Stand (archiviert 19.10.2026)

## Stand

- (18.10.2026, `9228e24`) Absturz beim Ändern der Farbe in der Charakterübersicht behoben (`ColorPickerButton` nicht mehr im eigenen `popup_closed` aus dem Baum genommen), Autotest für alle drei Farbknöpfe. Details im Archiv.
- Alle Aufträge bis 16.10.2026 erledigt und in `main`. Verlauf im Archiv (siehe oben), Zusammenführungen in `docs/Zusammenfuehrung.md`.
- Neue Fertigmeldungen hier kurz eintragen (Commit, was neu, Schnittstellenänderungen). Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.
- **Fertig (18.10.2026): Fertigkeitstexte „ohne Wirkung“.** `core/skill_texts.gd`: `SOON` entfernt (Konstante gelöscht), die 9 Texte sagen jetzt, wo die Fertigkeit wirkt (Geschützstation, Station Schilde, Station Technik, Raumhafen). Danach trägt keine Fertigkeit mehr `SOON`; alle Fertigkeiten aus `Rules` haben einen Text. Keine Schnittstellenänderung.

