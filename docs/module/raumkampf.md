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

- (16.10.2026) Moduldatei angelegt.
- (16.10.2026) Auftrag 1: Klärung mit dem Nutzer abgeschlossen, Planung in `docs/Planung_Raumkampf.md` (Entscheidungen, Vorschläge, offene Punkte, Schnittstellen-Vorschlag), `docs/Raumkampf.md` angeglichen. Mockup (Artifact „Raumkampf Mockup“) vom Nutzer bestätigt. Noch kein Code.

### Auftrag 2 (16.10.2026): Regelkern, Szene, Schnittstelle

Planung V1 (`8bd0e3a`) ist in `main`. **Zuständigkeit (Entscheidung Koordinator, im Auftrag des Nutzers):**
- **Raumkampf baut** nur eigene Dateien (`space.tscn`, `core/space_*.gd`, `view/space_*.gd`, `ui/space_*.gd`, `data/ships/`, `tests/test_space.gd`): Regelkern, Szene, Kampf-Briefing (Stationen ändern), Gegnervorlagen, Ergebnis. Dazu einen Einstieg, den der Hub nur aufruft, z. B. `SpaceBattle.start(setup)` / Szene mit `SpaceSetup`, und eine Funktion `SpaceSetup` für den Schnellkampf (feste Testwerte, ohne `HubState`). Ergebnis wie in `docs/Planung_Raumkampf.md` 4 (Format `MissionResult` + Schiffsteil).
- **Hub baut** alles in Hub-Dateien: alle vier Auslöser (Reiseereignis, Auftragsart, vor einem Bodeneinsatz, Schnellkampf-Knopf im Startmenü), `SpaceSetup` aus `HubState` zusammenstellen, Ergebnis auswerten (Hülle, Systemschäden, Schiffsmunition, Lösegeld, Beute, Einsatzbericht, Entern → Bodenkampf mit Lagerhalle, Notfall), `HubState`-Felder (Waffenslots, Schiffsmunition, Systemschäden, Posten „Station“), `ShipUpgrades` „Schilde“/„Panzerung“, Handel mit Schiffswaffen im Hafen, Reparatur der Systemschäden.
- **Bodenkampf:** in V1 nichts (Entern startet die normale Lagerhalle über den Hub). Karte „Schiffsinneres“ später.
- **Charakter:** nichts, solange das Ergebnis das `MissionResult`-Format hält.
- **Reihenfolge:** Raumkampf zuerst Schnittstelle (`SpaceSetup`-Felder, Ergebnis-Felder, Einstiegsfunktion, Daten der Waffen-Keys für Slots) als festen Stand in diese Datei unter „Schnittstellen“ schreiben und pushen (vorab meldbar wie beim Hub +5). Erst dann beginnt der Hub. Offene Zahlen und Punkte (Planung 3, u. a. Energie für Strahlwaffen) vorher mit dem Nutzer klären.
