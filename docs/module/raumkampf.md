# Modul Raumkampf

- **Branch:** `claude/raumkampf-modul`
- **Zuständig für (Vorschlag, mit dem Koordinator abstimmen):** eigene Szene und eigene Dateien, z. B. `godot/space.tscn`, `godot/core/space_*.gd`, `godot/view/space_*.gd`, `godot/ui/space_*.gd`, `godot/data/ships/`. Keine Dateien anderer Module umbauen; nötige Änderungen an Schnittstellen in „Stand“ vermerken.

## Grundlagen (in `main`)

- Regel-Entwurf: `docs/Raumkampf.md` (Hexkarte ohne Höhe, Ausrichtung/Trägheit, Mutterschiff mit Stationen, 2–3 Jäger, Schild je Seite, Struktur, Systemschaden). Nur Entwurf, nicht vom Nutzer bestätigt.
- Fertigkeiten (`core/rules.gd`, Gruppe Raumschiff-Kampf, bisher ohne Wirkung): `strahlGeschuetze`, `ballistikGeschuetze`, `raketen` (angezeigt „Raketen-Geschütze“), `schutzschild`, `panzerung`, `notReparatur`; dazu Raumschiff-Technik `pilot`, `navigation`, `computer`, `rsReparatur` (werden schon bei Reiseproben benutzt).
- Würfel, Proben, Schwierigkeiten: `core/dice.gd`, `core/rules.gd` (W100 offen, `DIFFICULTY`). Angriffstabellen-Muster: `core/tables.gd`, `data/tables/` (Bodenkampf).
- Vorbild für Ablauf und Datenaustausch: Bodenkampf (`core/combat.gd` meldet alles über Signale, `MissionResult` als Ergebnis).

## Schnittstellen (noch festzulegen, mit Hub und Charakter abstimmen)

- **Eingang:** Crew als Kopien der `Character` (wie Bodenkampf), Schiffswerte aus dem Hub (`HubState`: Hülle `hull`/`hull_max()`, Ausbau `ShipUpgrades`, Munition `HubState.ammo`, Treibstoff).
- **Ausgang:** Ergebnis ähnlich `MissionResult` (EP je benutzter Fertigkeit, Zustand der Crew, Hüllenschaden, Verbrauch, Beute) – Format mit dem Hub vereinbaren.
- **Auslöser:** Wann kommt es zum Raumkampf (Reiseereignis, Auftrag, Piraten)? Sache des Hubs, mit dem Nutzer klären.

## Aufträge vom Koordinator

### Auftrag 1 (16.10.2026): Planung, noch nicht bauen

1. `CLAUDE.md`, `docs/module/README.md`, diese Datei und `docs/Raumkampf.md` in `main` lesen.
2. **Mit dem Nutzer klären (Auswahl-Buttons)**, was der Raumkampf sein soll, u. a.: Umfang der ersten Version (nur Mutterschiff oder gleich mit Jägern), Darstellung (2D/3D, Hexkarte), Stationen und wer sie besetzt, Schiffswerte und Gegner, Auslöser und Folgen im Hub (Hülle, Beute, Flucht), Verbindung zu Schiffsausbau und Munition.
3. Ergebnis als Planung `docs/Planung_Raumkampf.md` festhalten (Entscheidungen des Nutzers, offene Punkte, Schnittstellen-Vorschlag) und `docs/Raumkampf.md` angleichen.
4. Mockup der Oberfläche zeigen, erst nach Bestätigung bauen.
5. Branchnamen und Planung als Fertigmeldung an den Koordinator (über den Nutzer).

## Stand

- (16.10.2026) Moduldatei angelegt, noch kein Branch, noch kein Code.
