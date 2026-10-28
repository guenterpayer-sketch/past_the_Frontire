
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


### Auftrag (27.10.2026): Psi-Liste „Stärkung“ lernbar machen – erledigt (`080ca33`)

Ergebnis: `lStaerkung` in `PsiLists.LISTS` (Stufen 1–8, 10, Wirkungstexte wie `PsiCombat.SUPPORT`), `Rules` (Gruppe „Psi-Listen“ als „Liste Stärkung“, MEN/EMP, `PSI_SKILLS`), `SkillTexts`; Editor, Aufleveln, Übersicht der Psi-Listen, Briefing und Enzyklopädie lesen die Listen generisch und brauchten keine Änderung. Test `_test_psi_view` prüft Stufen, Art, Ziele und gleiche Namen wie im Bodenkampf. Schnittstellen unverändert.

Bodenkampf ist fertig und in `main` (`2ff16dd`): Kräfte `lStaerkung/1`–`/8` und `/10` in `core/psi_combat.gd` (`PsiCombat.known` findet die Schlüssel selbst). Jetzt: Liste in `core/psi_lists.gd` (`LISTS`, Stufen 1–8 und 10), `core/rules.gd` (`PSI_SKILLS`, Gruppe „Psi-Listen“; der Bodenkampf hat `rules.gd` minimal geändert: `Rules.attr_bonus_of`), `core/skill_texts.gd`, Test in `test_rules.gd`. `main` vorher holen. Tests nach CLAUDE.md, Fertigmeldung.


### Auftrag (28.10.2026): Elite-Ausrüstung lässt sich nicht ausrüsten – erledigt (Branch, wartet auf Zusammenführung)

Ergebnis: Ursache wie vermutet (`Equipment.weapons()/armors()` lasen die Unterordner `elite/` nicht; der Reiter „Lager“ zeigte Elite-Stücke schon). Jetzt `Equipment.weapons(g)`/`armors(g)` mit Elite-Ordnern, nur mit Spiel (ohne Spielstand ist der Bestand unbegrenzt, dort keine Elite). Angezeigt wird weiter nur, was im Lager liegt oder getragen wird; Schaden bleibt beim Anlegen/Ablegen erhalten. Sortiment unverändert (`Stock.goods` filtert `is_elite`). Nebenbei: Rüstungsliste zeigt bei unbrauchbaren Stücken „wie keine“ statt eines Minuswerts (wie der Reiter „Lager“). Test in `test_hub.gd` (`_test_elite`).

Fehler (Nutzer, Spiel): Im Lager liegt „Sturmgewehr (Boss)“, in der Waffenkammer erscheint es nicht zur Auswahl.
Vermutung des Koordinators aus dem Code (nicht im Spiel geprüft): Die Waffenkammer listet nur `Equipment.weapons()` / `Equipment.armors()`. Diese lesen die Ordner `res://data/weapons` bzw. `res://data/armor` ohne Unterordner (`GameData.weapons()`, `list_directory`), die Elite-Stücke liegen aber in `data/weapons/elite/` und `data/armor/elite/` (Bodenkampf, Balancing-Paket 24.10.2026).
1. Ursache bestätigen und beheben: Elite-Waffen und -Rüstungen, die im Lager liegen, müssen ausrüstbar sein (mit Schaden −20/−30 wie geliefert). Im Händler-Sortiment weiter **nie** (Hub, `Stock.is_elite`).
2. Prüfen, ob auch andere Listen (Editor, Enzyklopädie, Charakterbogen) Elite-Stücke brauchen oder bewusst weglassen; dem Nutzer berichten.
3. Tests nach CLAUDE.md (test_sim nicht nötig), Fertigmeldung.
