# Planung: neue Waffenmodelle und Waffenklänge (16.10.2026)

Entscheidungen des Nutzers (Koordinations-Chat).

## Entscheidungen

- **Modelle** aufnehmen (alle CC0, Eintrag in `godot/assets/LICENSES.md`):
  - Quaternius „Ultimate Guns Pack“ (25 Schusswaffen, u. a. Revolver, Scharfschützengewehre, Schrotflinten) – https://quaternius.com/packs/ultimategun.html
  - Quaternius „Modular Weapons Pack“ (24 Nahkampfwaffen; nur FBX/OBJ/Blend, ggf. nach `.glb` umwandeln) – https://quaternius.com/packs/medievalweapons.html
  - Kenney „Blaster Kit“ (Sci-Fi-Blaster) – https://kenney.nl/assets/blaster-kit
- **Klänge als Dateien (CC0)**, mindestens **Minigun, MP, Revolver**; Quelle z. B. „The Free Firearm Sound Library“ (CC0, https://opengameart.org/content/the-free-firearm-sound-library). Ob sie Minigun/MP enthält, ist nicht geprüft; ein CC-BY-Ersatz (z. B. „Chaingun, pistol, rifle, shotgun shots“, CC-BY 3.0) nur mit Namensnennung in `LICENSES.md`.
- **Klang pro Waffe im Editor wählbar** (neuer Waffenwert).

## Stand im Code (geprüft)

- Klang heute aus den Werten abgeleitet: `WeaponData.sound()` (`data/types/weapon_data.gd`); alle Klänge synthetisch in `audio/sfx.gd`.
- **Nebeneffekt der Munition:** `sound()` wählt „mg“ über `ob_bonus > 0`; das MG hat seit `7ffd55e` `ob_bonus` 0 und `shots = 3` → spielt jetzt den Gewehr-Klang.
- Editor bietet als Modelle nur die der mitgelieferten Waffen an (`Gear.models()`, `core/gear.gd`), weil Länge und Griff aus der Waffe kommen.

## Aufteilung

1. **Bodenkampf (zuerst):** Modelle einbinden (`assets/weapons/`, Länge/Griff je Modell, z. B. als Modell-Katalog, den der Editor lesen kann); Klangdateien einbinden, `WeaponData` um einen Wert *Klang* erweitern (leer = wie bisher abgeleitet), `Sfx` spielt Dateien; MG-Klang reparieren. Lizenzen eintragen. Schnittstelle (Modell-Katalog, Klangliste) unter „Schnittstellen“.
2. **Hub (danach):** Ausrüstungs-Editor bietet alle Modelle aus dem Katalog und die Klangliste an.

## Offen (Bodenkampf klärt mit dem Nutzer)

- Auswahl der Modelle (alle oder eine Auswahl), Umwandlung der Nahkampfwaffen, Griffpositionen.
- Herunterladen: ob der Chat die Pakete selbst laden kann oder der Nutzer sie ablegt (wie bei der Musik).
