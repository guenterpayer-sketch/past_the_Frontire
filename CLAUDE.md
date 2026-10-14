# Past the Frontire – Hinweise für Claude

Weltraum-Rollenspiel mit einer sechsköpfigen Crew. Regeln im Stil von Rolemaster (RMSS): W100 aus zwei W10 (Zehner + Einer, 00 = 100), offen nach oben und unten, Angriffstabellen, Kritische Treffer, Erfahrung nur für benutzte Fertigkeiten.

## Stand

- **Aktive Version: Godot 4.7.2** im Ordner `godot/` (Überblick, Bedienung, Aufbau, Tests: `godot/README.md`).
- **HTML/JS-Version** (`index.html`, `js/`, `css/`, `tests/` im Wurzelordner) ist **eingefroren**: nur noch Referenz, nicht weiterentwickeln.
- Regeln und Entwürfe: `docs/Skillsystem.md` (Eigenschaften, Fertigkeiten, Proben, Kampf, Steigerung, offene Punkte), `docs/Charakterbogen_Grundgeruest.md`, `docs/Raumkampf.md`.
- Gebaut: Bodenkampf in zufälliger Lagerhalle (3D), Missionsgenerator (Fraktionen in `godot/data/missions`), Truppwahl im Briefing (bis 6, Gesperrte ausgegraut), Runde 0 (Aufstellung), aktive Figur mit Schild „am Zug“, Psi-Kräfte aus den Psi-Listen im Kampf (`core/psi_combat.gd`), Verwundung statt Tod (sterbend/stabilisiert, Todeswurf nur wenn die ganze Crew fällt), Ergebnis-Banner und Rückzug, Charakter-Modul `crew.tscn` mit Charakterübersicht (Ränge, Eigenschaften, freie EP), Speicherstand `user://crew.json` (vollständige Charaktere).
- Module: Charakter-Modul und Kampfmodule tauschen nur Daten aus (Kampf bekommt Kopien der `Character`, gibt ein `MissionResult` zurück: EP je benutzter Fertigkeit, freie EP, Zustand, Verbrauch). Details in `godot/README.md`, „Module und Schnittstelle“.
- Charakter-Editor für **neue** Crewmitglieder (Regeln `docs/Skillsystem.md` 7a, Psi-Listen 6.1). Prototyp zum Balancing: Artifact „Frontire Charakter-Editor“.
- Globaler Roster (`roster.tscn`, `user://roster.json`), Crew-Auswahl beim neuen Spiel (`CrewPicker`), Entlassen in der Charakterübersicht (Entlassene warten „im Hafen“), Anheuern über `Campaign.hire()`; Einsatz mit bis zu 6 (`Campaign.squad()`, Kandidaten mit Sperr-Status `Campaign.candidates()`); Verwundung mit Stufen und Resttagen (`core/injury.gd`, `docs/Skillsystem.md` 8a). Startmenü „Roster“, „Neues Spiel“ und Schnellkampf aus dem Roster sind über den Hub angebunden.
- Aufleveln in der Charakterübersicht (`ui/crew/crew_overview.gd`, Regeln `docs/Skillsystem.md` 8) mit 3D-Vorschau.
- Hub (Startmenü, Schiff, Sternenkarte, Spielstände): Startmenü (`start.tscn`, Hauptszene), Schiff als 3D-Deck (`hub.tscn`: Brücke mit Sternenkarte und Aufträgen, Crewquartiere mit der Charakterübersicht des Charakter-Moduls, Krankenstation mit Arzt/Helfer und täglicher Heilprobe (`core/medbay.gd`), Waffenkammer/Hangar als Platzhalter), zufälliger Sektor mit Fraktionen und Reisetagen, Anheuern im Hafen (neutrale Systeme), Plätze an Bord (Start 8), „1 Tag warten“, Aufträge mit Ablaufdatum, Bodenkampf aus dem Schiff und zurück mit Einsatzbericht, 3 Spielstand-Slots. Details: `docs/module/hub.md`.
- Noch nicht gebaut: Weltraumkampf, Story/Kampagne, Ausrüstung/Hangar, Ausbau des Schiffs (mehr Plätze an Bord).

## Arbeitsweise mit dem Nutzer

- Antworten auf **Deutsch**.
- **Wissen und Annahme immer ausdrücklich trennen** („das weiß ich nicht“ / „das nehme ich an“). Keine plausiblen Abläufe als Tatsache darstellen; Lücken bleiben Lücken.
- **Erst klären, dann bauen**: keine fertigen Inhalte (Texte, Listen, Entwürfe, größere Umbauten), solange relevante Fragen offen sind. Klärungsfragen mit mehreren Antworten als **Auswahl-Buttons** (AskUserQuestion) stellen.
- Eigenes Verhalten ohne Formulierungen mit unterstelltem innerem Erleben beschreiben.
- Größere UI-Änderungen erst als Mockup zeigen, dann in Godot bauen.
- **Branches und Module:** `main` ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat. Jedes Modul (Bodenkampf, Charakter, Hub, …) arbeitet in einem eigenen Chat auf einem eigenen Branch. **Zu Beginn die eigene Moduldatei in `main` lesen** (`docs/module/`, Übersicht und Ablauf in `docs/module/README.md`); vor der Fertigmeldung `main` in den eigenen Branch holen und Konflikte dort lösen. Der Koordinator führt nur konfliktfreie Branches zusammen. Verlauf: `docs/Zusammenfuehrung.md`.
- Der Nutzer arbeitet unter Windows 11 mit GitHub Desktop und startet das Spiel lokal im Godot-Editor (F5). Godot schreibt `godot/project.godot` beim Öffnen manchmal selbst um; diese lokalen Änderungen nicht committen (sonst Konflikte beim Pull).

## Code (godot/)

- `core/`: Spiellogik ohne Grafik, meldet alles über Signale (`Combat`). `Character`/`Roster`/`Campaign`/`MissionResult`: Crew, Speicherstand, Schnittstelle zum Kampf. `view/`: Darstellung und Ablauf (`Battle`, `EventPlayer`, `PlayerController`). `ui/`: Oberfläche (schwebende Kästen über der Karte, Dialoge auf `Modal`). `data/`: Spieldaten als Ressourcen (`.tres`), im Editor bearbeitbar.
- Stil: GDScript mit Typangaben, deutsche Bezeichner in Texten und Kommentaren, Kommentare knapp mit `##` über Klassen und Funktionen.
- Tests (gestaffelt, Entscheidung des Nutzers 16.10.2026):
  - **Vor jedem Commit** (schnell): `godot --headless --path godot --script res://tests/test_rules.gd` und `… res://tests/test_hub.gd` (beide müssen „OK“ ausgeben)
  - **Vor der Fertigmeldung** zusätzlich: `godot --headless --path godot --script res://tests/test_sim.gd -- 10` (KI gegen KI, kein Kampf darf hängen; `-- 45 missionen` = Siege je Schwierigkeit, nur bei Balancing-Fragen)
  - **Vor der Fertigmeldung, nur für geänderte Bereiche** (mit Grafik, Screenshots nach `PTF_OUT`): Kampf → `godot --path godot -- --autotest`, `-- --autotest-player`, Psi → `-- --autotest-psi`, Hub/Startmenü/Schiff → `-- --autotest-hub`. Charakterübersicht/Roster → `-- --autotest` und `-- --autotest-hub`.
- Neue Funktionen in `godot/README.md` und, wenn Regeln betroffen sind, in `docs/Skillsystem.md` nachtragen.
