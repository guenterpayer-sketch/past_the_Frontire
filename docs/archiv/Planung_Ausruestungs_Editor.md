# Planung: Editor für eigene Waffen und Rüstungen (15.10.2026)

Entscheidungen des Nutzers (Koordinations-Chat). Editor im **Hauptmenü** (Startmenü), gebaut vom **Hub**.

## Entscheidungen

- **Waffen und Rüstungen** erstellen, **bearbeiten und löschen**.
- **Global** gespeichert (wie der Roster, in allen Spielständen und im Schnellkampf).
- **Fertigkeit und Angriffstabelle frei wählbar** aus den vorhandenen (Tabellen: Strahl, Projektil, Klinge, Wucht, Explosion, Psi). Beispiel des Nutzers: Revolver = Pistolen + Projektil. Keine neuen Angriffstabellen.
- **Zahlenwerte:** Start von einer **Vorlage** (vorhandene Waffe/Rüstung), Änderung in **Grenzen** um die Vorlage; zusätzlich **Option, Werte frei einzutragen** (ohne Grenzen).
- **3D-Modell** aus den vorhandenen Modellen wählen.
- **Crew** nutzt eigene Ausrüstung in der Waffenkammer; **Gegner** pro Waffe/Rüstung einstellbar („auch für Gegner“, ggf. Fraktion).

## Werte (heute in `data/types/weapon_data.gd` bzw. `armor_data.gd`)

Waffe: Fertigkeit, Angriffstabelle, Nah/Fern, Reichweite je Stufe, Stufen, Mindestabstand, Höchstergebnis, Patzer, Schaden, Angriffsbonus, Magazin, Munition, Druckwelle, ein-/zweihändig, Modell. Rüstung: Klasse (0–3), Verteidigungsbonus, Bewegungsabzug.

## Aufteilung

1. **Hub (zuerst):** Editor im Startmenü, Speicherung (z. B. `user://gear.json`), ein Baustein, der die eigenen Einträge als `WeaponData`/`ArmorData` liefert (inkl. Gegner-/Fraktions-Einstellung). Schnittstelle in `docs/module/hub.md` vermerken.
2. **Bodenkampf (danach):** `GameData.weapons()` (`core/game_data.gd`) liefert auch die eigenen Waffen; Gegner bekommen eigene Ausrüstung gemäß Einstellung (Missionsgenerator).
3. **Charakter (danach):** `Equipment.armors()` (`core/equipment.gd`) liefert auch eigene Rüstungen; Waffenkammer zeigt eigene Ausrüstung. Verhalten, wenn getragene Ausrüstung gelöscht wird (Vorschlag: zurück auf Standardwaffe/-rüstung).

## Offen (Hub-Chat klärt mit dem Nutzer, vor dem Bauen)

- Breite der Grenzen je Wert; Kennzeichnung frei eingetragener Ausrüstung (z. B. Hinweis „ohne Grenzen“).
- Gelöschte Ausrüstung, die getragen wird.
- Mockup des Editors.
