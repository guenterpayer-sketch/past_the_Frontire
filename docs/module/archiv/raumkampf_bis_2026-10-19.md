
## Erledigt (in `main`, Merge von `49e14ad`)

- **Auftrag 6 (19.10.2026): Raumkampf-Seiten für die neuen Fraktionen.** Der Bodenkampf hat 6 Fraktionen mit Oberart angelegt (`data/missions/`, Feld `kind`; Eigenheiten in `docs/Skillsystem.md` 7.4): `semidrug` (Konzern), `eisenwoelfe` (Söldner), `schwarze_flagge` und `aasgeier` (Piraten), `neuntes_haus` (Syndikat), `kinder_der_glut` (Kult). `SpaceTemplates.faction()` fällt für sie bisher auf `piraten` zurück. Entscheidung des Nutzers: Sie bekommen **eigene Seiten** in `data/ships/seiten/` (Schiffe, Aufstellungen, Lösegeld, Verhalten bei Niederlage). Die Unterschiede passend zur Oberart und Eigenheit erst mit dem Nutzer klären, dann per Simulation abstimmen (`tests/sim_space.gd`).
  - Die drei Story-Fraktionen (Bodenkampf Auftrag 3) kommen später, wenn Kapitel 1 sie im Raum braucht.


## Früherer Stand (archiviert 19.10.2026)

## Stand

- (17.10.2026) Auftrag 3: Zahlen per Simulation abgestimmt (`tests/sim_space.gd`, Ergebnisse und Änderungen in `docs/Planung_Raumkampf.md` 1c): Siege 87–91 / 67–70 / 47–49 %, 8–11 Runden. Crew-KI zielt mit der Bewegung auf Schussfeld, Trefferschwellen −25, Schaden ×0,9, Gegner schwächer besetzt, Aufstellungen schwer angepasst, **Waffenpreise geändert** (`ShipWeapons.price`), Gegnervorlagen als Ressourcen in `data/ships/`. Schnittstelle und Ausbaustufen unverändert.
- (18.10.2026) Auftrag 4: EP im Raumkampf je Station und Runde höchstens 2; Schützen je Runde (+1 gefeuert/abgefangen, +1 Treffer) statt je Schuss; Navigation würfelt jede Runde die Initiative; Messung vorher/nachher in `docs/Planung_Raumkampf.md` 1d (`tests/sim_space.gd -- ep`), Regel in `docs/Raumkampf.md` 5 und `docs/Skillsystem.md` 8. Schnittstelle unverändert.
- (18.10.2026) Auftrag 5: Entern neu (Entscheidungen des Nutzers, `docs/Raumkampf.md` 4c, Messung `docs/Planung_Raumkampf.md` 1e): Wracks statt Zerstörung bei Schiffen, selbst entern bei Antrieb E / Hülle < 25 % / Wrack in jeder Entfernung mit Pilotenprobe (Frage „Entern ja/nein“), Gegner entern ab eigener Hülle < 25 % mit Anflug. **Für den Hub:** `boarding` kommt jetzt oft vor Hülle 0 (eigene Hülle 1–24 %); bei `boarding` liegen neu `board_ship` und `board_loot` (Enterschiff) im Ergebnis – bei abgewehrtem Entern soll der Raumkampf als gewonnen gelten und `board_loot` gebucht werden (Wunsch des Nutzers). Sonst Schnittstelle unverändert.
- (19.10.2026) Fehlermeldung des Nutzers (liegt bei Hub/Bodenkampf, an den Koordinator gemeldet; verteilt als Bodenkampf Auftrag 2): Im Briefing des Enter-Bodenkampfs beendet „Zurück ins Schiff“ das Entern endgültig (`HubState.abort_mission()` löscht `board_pending` bzw. wertet die Abwehr als verloren; `view/hub.gd` ruft `abort_mission()` beim Betreten des Schiffs). Entscheidung des Nutzers: beim Entern (selbst und Abwehr) **kein** „Zurück ins Schiff“, stattdessen ein Knopf **„Ausrüstung“** im Briefing (Waffenkammer-Dialog); Entern lässt sich **nicht absagen** (weder selbst noch Abwehr).
- (19.10.2026) Auftrag 6: eigene Seiten für `semidrug`, `eisenwoelfe`, `schwarze_flagge`, `aasgeier`, `neuntes_haus`, `kinder_der_glut` in `data/ships/seiten/`, je ein eigener Schiffstyp (Korvetten-Abwandlung) in `data/ships/schiffe/`, Eigenheiten sinngemäß über vorhandene Felder (kein neues Feld). Werte und Messung: `docs/Planung_Raumkampf.md` 1f; neue Simulation je Seite `tests/sim_space.gd -- 100 fraktionen [Seiten-IDs]`. `SpaceTemplates.faction()` fällt für sie nicht mehr auf `piraten` zurück. Schnittstelle unverändert.
- Bis 16.10.2026 alles in `main` (`f0334fd`, mit dem Hub): Regelkern `core/space_*.gd` (Phasen Schilde → Bewegen → Schießen → Technik/Computer, Bord-KI +0, Doppelbesetzung −30, Energie, Schilde je Seite, Systemschäden A–E, Flucht, Kapitulation, Entern durch Gegner/selbst), Szene `space.tscn` (F6 = Schnellkampf), bis 3 Techniker, Umbesetzen zu Rundenbeginn (−10), Schieberegler je Schildseite, Test `tests/test_space.gd`, Selbsttest `-- --autotest-space`. Entscheidungen: `docs/Planung_Raumkampf.md` 1a/1b.
- Offen: eigene Jäger erst V2. Neu abstimmen mit `tests/sim_space.gd`, wenn sich Regeln ändern.
- Neue Fertigmeldungen hier kurz eintragen. Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.



### Auftrag (24.10.2026): Elite-Beute und Boss-Schiff (erledigt, `98c1769`)

Gemeinsame Elite-Regeln stehen in `docs/module/bodenkampf.md` und `docs/module/raumkampf.md` (Abschnitt „Elite-Gegner“). Ergänzt vom Nutzer am 24.10.2026:
- **Boss-Kampf:** Boss + 2 Leibwächter + Fußvolk (Form „Anführer“ aus dem Bodenkampf-Vorschlag), Siegquote wie Elite (70–75 %). Kommt vor (a) am Ende jeder Story-Kette (je nach Kette am Boden **oder** im Raum mit Boss-Schiff) und (b) bei Hub-Aufträgen, deren Ziel eine Person ist (z. B. „Beseitigt den Gangsterboss“).
- **Beute bei Elite und Boss:** selten (nicht bei jedem Kampf), dann höchstens 2–3 Stück der besseren Ausrüstung, gern stark beschädigt. Boden: Waffen/Rüstungen. Raum: ab und zu eine beschädigte Schiffswaffe.
- **Elite-Wurf** beim Hub (beim Erstellen von Auftrag/Feindkontakt, ca. 13 %), Anzeige „Elite“ bzw. „Boss“ im Angebot.

1. Beute nach Elite-Raumkampf: selten eine beschädigte Schiffswaffe (über das bestehende Beute-Ergebnis an den Hub).
2. Boss-Schiff für Story-Ketten, die im Raum enden: Vorschlag (Schnittstelle z. B. `setup.enemy.boss: bool`), Siegquote wie Elite. Erst Vorschlag mit Simulation, dann bauen.
