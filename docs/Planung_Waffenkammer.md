# Planung: Waffenkammer (Ausrüstung ändern)

Stand: 15.10.2026. Entscheidungen des Nutzers im Koordinations-Chat.

## Heute (aus dem Code, `main`)

- Ausrüstung je Figur in `Character`: 2 Waffenplätze (`weapons`), Rüstung (`armor`), Schild (`shield`). Festgelegt nur im Charakter-Editor (Roster); im laufenden Spiel nicht änderbar.
- Waffen: Dateien in `godot/data/weapons/` (`WeaponData`: Fertigkeit, Tabelle, Reichweite, Schaden, Magazin …), Rüstungen in `godot/data/armor/` (`ArmorData`: Klasse 0–3, Verteidigungsmalus, Bewegungsmalus). Kein Bestand: jede Waffe/Rüstung beliebig oft.
- Rüstung wirkt über (1) Trefferschwelle der Angriffstabelle je Klasse, (2) Schadensfaktor 1,0 / 0,9 / 0,8 / 0,65 (nicht gegen Psi), (3) Verteidigung −5/−10 (mittel/schwer), schwer −1 Gratis-Feld. Keine Fertigkeit zum Tragen; „Rüstung“ (Handwerk) wird nirgends verwendet.
- Schild: Verteidigung +10 + ½ Rangbonus Schild (nicht bei Überraschung).
- Raum „Waffenkammer / Hangar“ im Schiff ist Platzhalter.

## Entschieden

- **Bestand: erst mal unbegrenzt** – alle Waffen und Rüstungen frei wählbar (wie im Editor). Bestand, Kauf und Beute sind ein späteres Thema.
- **Änderbar:** Waffe 1 und Waffe 2, Rüstung, Schild.
- **Medikits und Munition:** vorerst **nur anzeigen**, nicht wählbar (jeder Einsatz beginnt voll); Auswahl kommt später mit Bestand/Kauf.
- **Wann:** jederzeit im Schiff.
- **Anzeige mit Werten:** je Waffe Fertigkeit, Bonus der Figur in dieser Fertigkeit, Reichweite, Schaden(sfaktor), Magazin/Munition, Nah-/Fernkampf; je Rüstung Klasse, Verteidigungs- und Bewegungsmalus; Schild mit Bonus. (Deckt einen Teil der gewünschten „Enzyklopädie“ ab.)
- Änderungen gelten für die Figur im Spielstand (Kopie), nicht für den Roster-Eintrag.

## Zuständigkeit (Koordinator)

- **Charakter:** baut den Ausrüstungsdialog (`ui/crew/`, Muster wie `CrewOverview`), schreibt die Ausrüstung in `Character` und speichert über `Campaign`. Erst **Mockup**, Nutzer bestätigt. Er baut die Werte-Anzeige aus `WeaponData`/`ArmorData` (Dateien gehören dem Bodenkampf, nur lesen).
- **Hub:** macht den Raum „Waffenkammer“ nutzbar und öffnet den Dialog des Charakter-Moduls; **keine eigene Ausrüstungs-Oberfläche**.
- **Bodenkampf:** nichts zu bauen; Waffen- und Rüstungsdaten bleiben seine Dateien. Falls für die Anzeige Felder fehlen (z. B. Kurzbeschreibung), mit dem Charakter-Modul abstimmen.

## Offen (später)

- Bestand/Lager, Kauf im Hafen, Beute.
- Auswahl von Medikits und Munition (Grenze z. B. Traglast oder feste Plätze).
- Enzyklopädie als eigener Bildschirm.
- Ob der Hangar ein eigener Raum wird (heute ein Raum „Waffenkammer / Hangar“).

## Stand 15.10.2026

- **Charakter erledigt** (`14163cc`, in `main` `0c251f9`): `ArmoryDialog` mit Aufruf `ArmoryDialog.new()`, `open_for(Campaign.crew(), index)`, Signal `done` (danach ist gespeichert). Zusätzliche Regeln (vom Nutzer im Charakter-Chat entschieden): Waffe 1 Pflicht, Waffe 2 darf leer sein, keine Waffe doppelt, Psi-Waffen nicht wählbar, Schild nur mit einhändigen Waffen (Fäuste ausgenommen).
- **Datenänderungen (Bodenkampf-Dateien, Anweisung des Nutzers):** Vibroklinge einhändig; Laserkarabiner nutzt Gewehre statt Pistolen.
- ~~**Offen – Hub:** Raum „Waffenkammer“ öffnet den Dialog.~~ → erledigt (`d6478f3`, in `main` `7a9e704`); Waffenkammer und Hangar sind getrennte Räume, Hangar Platzhalter.

