
## Erledigt (in `main`, Merge von `49e14ad`)

- **Auftrag 6 (19.10.2026): Raumkampf-Seiten für die neuen Fraktionen.** Der Bodenkampf hat 6 Fraktionen mit Oberart angelegt (`data/missions/`, Feld `kind`; Eigenheiten in `docs/Skillsystem.md` 7.4): `semidrug` (Konzern), `eisenwoelfe` (Söldner), `schwarze_flagge` und `aasgeier` (Piraten), `neuntes_haus` (Syndikat), `kinder_der_glut` (Kult). `SpaceTemplates.faction()` fällt für sie bisher auf `piraten` zurück. Entscheidung des Nutzers: Sie bekommen **eigene Seiten** in `data/ships/seiten/` (Schiffe, Aufstellungen, Lösegeld, Verhalten bei Niederlage). Die Unterschiede passend zur Oberart und Eigenheit erst mit dem Nutzer klären, dann per Simulation abstimmen (`tests/sim_space.gd`).
  - Die drei Story-Fraktionen (Bodenkampf Auftrag 3) kommen später, wenn Kapitel 1 sie im Raum braucht.

