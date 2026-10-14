# Past the Frontire – Hinweise für Claude

Weltraum-Rollenspiel mit einer sechsköpfigen Crew. Regeln im Stil von Rolemaster (RMSS): W100 aus zwei W10 (Zehner + Einer, 00 = 100), offen nach oben und unten, Angriffstabellen, Kritische Treffer, Erfahrung nur für benutzte Fertigkeiten.

## Stand

- **Aktive Version: Godot 4.7.2** im Ordner `godot/` (Überblick, Bedienung, Aufbau, Tests: `godot/README.md`).
- **HTML/JS-Version** (`index.html`, `js/`, `css/`, `tests/` im Wurzelordner) ist **eingefroren**: nur noch Referenz, nicht weiterentwickeln.
- Regeln und Entwürfe: `docs/Skillsystem.md` (Eigenschaften, Fertigkeiten, Proben, Kampf, Steigerung, offene Punkte), `docs/Charakterbogen_Grundgeruest.md`, `docs/Raumkampf.md`.
- Gebaut: Bodenkampf in zufälliger Lagerhalle (3D), Missionsgenerator (Fraktionen in `godot/data/missions`), Runde 0 (Aufstellung), Charakter-Modul `crew.tscn` mit Charakterübersicht (Ränge, Eigenschaften, freie EP), Speicherstand `user://crew.json` (vollständige Charaktere).
- Module: Charakter-Modul und Kampfmodule tauschen nur Daten aus (Kampf bekommt Kopien der `Character`, gibt ein `MissionResult` zurück: EP je benutzter Fertigkeit, freie EP, Zustand, Verbrauch). Details in `godot/README.md`, „Module und Schnittstelle“.
- Charakter-Editor für **neue** Crewmitglieder (Regeln `docs/Skillsystem.md` 7a, Psi-Listen 6.1). Prototyp zum Balancing: Artifact „Frontire Charakter-Editor“.
- Noch nicht gebaut: Editor-Variante zum Aufleveln, Psi-Listen im Kampf (außer Psi-Schild/Psi-Stoß), Startmenü, Weltraumkampf, Story/Kampagne, Heilung/Tod zwischen Einsätzen.

## Arbeitsweise mit dem Nutzer

- Antworten auf **Deutsch**.
- **Wissen und Annahme immer ausdrücklich trennen** („das weiß ich nicht“ / „das nehme ich an“). Keine plausiblen Abläufe als Tatsache darstellen; Lücken bleiben Lücken.
- **Erst klären, dann bauen**: keine fertigen Inhalte (Texte, Listen, Entwürfe, größere Umbauten), solange relevante Fragen offen sind. Klärungsfragen mit mehreren Antworten als **Auswahl-Buttons** (AskUserQuestion) stellen.
- Eigenes Verhalten ohne Formulierungen mit unterstelltem innerem Erleben beschreiben.
- Größere UI-Änderungen erst als Mockup zeigen, dann in Godot bauen.
- Der Nutzer arbeitet unter Windows 11 mit GitHub Desktop und startet das Spiel lokal im Godot-Editor (F5). Godot schreibt `godot/project.godot` beim Öffnen manchmal selbst um; diese lokalen Änderungen nicht committen (sonst Konflikte beim Pull).

## Code (godot/)

- `core/`: Spiellogik ohne Grafik, meldet alles über Signale (`Combat`). `Character`/`Roster`/`Campaign`/`MissionResult`: Crew, Speicherstand, Schnittstelle zum Kampf. `view/`: Darstellung und Ablauf (`Battle`, `EventPlayer`, `PlayerController`). `ui/`: Oberfläche (schwebende Kästen über der Karte, Dialoge auf `Modal`). `data/`: Spieldaten als Ressourcen (`.tres`), im Editor bearbeitbar.
- Stil: GDScript mit Typangaben, deutsche Bezeichner in Texten und Kommentaren, Kommentare knapp mit `##` über Klassen und Funktionen.
- Tests (vor jedem Commit):
  - `godot --headless --path godot --script res://tests/test_rules.gd` (muss „OK“ ausgeben)
  - `godot --headless --path godot --script res://tests/test_sim.gd -- 30` (KI gegen KI; `-- 45 missionen` = Siege je Schwierigkeit)
  - mit Grafik: `godot --path godot -- --autotest` und `-- --autotest-player` (Screenshots nach `PTF_OUT`)
- Neue Funktionen in `godot/README.md` und, wenn Regeln betroffen sind, in `docs/Skillsystem.md` nachtragen.
