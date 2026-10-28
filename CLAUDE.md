# Past the Frontire – Hinweise für Claude

Weltraum-Rollenspiel mit einer sechsköpfigen Crew. Regeln im Stil von Rolemaster (RMSS): W100 aus zwei W10 (Zehner + Einer, 00 = 100), offen nach oben und unten, Angriffstabellen, Kritische Treffer, Erfahrung nur für benutzte Fertigkeiten.

## Stand

- **Aktive Version: Godot 4.7.2** im Ordner `godot/`. Überblick, Bedienung, Aufbau und Tests: `godot/README.md`. Versionsnummer: `application/config/version` in `godot/project.godot` (pflegt der Koordinator).
- **HTML/JS-Version** (Ordner `alt_html/`: `index.html`, `js/`, `css/`, `tests/`) ist **eingefroren**: nur Referenz, nicht weiterentwickeln.
- Regeln: `docs/Skillsystem.md` (Proben, Kampf, Steigerung, Fraktionen 7.4, Reise 8b …), `docs/Raumkampf.md`, `docs/Charakterbogen_Grundgeruest.md`. Story: `docs/Planung_Story.md`. Layout: `docs/Layout.md`.
- **Module** (je eigener Chat und Branch, Moduldatei in `docs/module/`): Bodenkampf, Charakter (Crew, Roster, Editor, Waffenkammer), Hub (Startmenü, Schiff, Sternenkarte mit Sektoren, Spielstände, Enzyklopädie), Raumkampf, Story/Kampagne, Export (Android, Windows, Touch). Module tauschen nur Daten aus (z. B. Kampf bekommt Kopien der `Character`, gibt ein `MissionResult` zurück; `godot/README.md`, „Module und Schnittstelle“).
- Noch nicht gebaut: eigene Jäger und Hangar (V2), Kapitel 2 der Story. Früherer ausführlicher Stand: `docs/module/archiv/CLAUDE_Stand_bis_2026-10-19.md`.

## Arbeitsweise mit dem Nutzer

- Antworten auf **Deutsch**.
- **Wissen und Annahme immer ausdrücklich trennen** („das weiß ich nicht“ / „das nehme ich an“). Keine plausiblen Abläufe als Tatsache darstellen; Lücken bleiben Lücken.
- **Erst klären, dann bauen**: keine fertigen Inhalte (Texte, Listen, Entwürfe, größere Umbauten), solange relevante Fragen offen sind. Klärungsfragen mit mehreren Antworten als **Auswahl-Buttons** (AskUserQuestion) stellen. **Am Ende jeder Fragerunde eine Abschlussfrage mit Freitext** (z. B. „Willst du noch etwas sagen?“), Wunsch des Nutzers 16.10.2026.
- Eigenes Verhalten ohne Formulierungen mit unterstelltem innerem Erleben beschreiben.
- Größere UI-Änderungen erst als Mockup zeigen, dann in Godot bauen. **Layoutregeln für alle Fenster: `docs/Layout.md`** (vorher Screenshots vorhandener Fenster vergleichen; Nutzer 19.10.2026).
- **Branches und Module:** `main` ist der gemeinsame Hauptbranch, gepflegt vom Koordinations-Chat. Jedes Modul (Bodenkampf, Charakter, Hub, …) arbeitet in einem eigenen Chat auf einem eigenen Branch. **Zu Beginn die eigene Moduldatei in `main` lesen** (`docs/module/`, Übersicht und Ablauf in `docs/module/README.md`); vor der Fertigmeldung `main` in den eigenen Branch holen und Konflikte dort lösen. Der Koordinator führt nur konfliktfreie Branches zusammen. Verlauf: `docs/Zusammenfuehrung.md`. Moduldateien enthalten nur Offenes und Gültiges; Erledigtes liegt in `docs/module/archiv/` (nur bei Bedarf lesen).
- Der Nutzer arbeitet unter Windows 11 mit GitHub Desktop und startet das Spiel lokal im Godot-Editor (F5). `.gitattributes` (`* text=auto eol=lf`) hält Zeilenenden auch unter Windows bei LF, `godot/project.godot` liegt in der Fassung, die der Editor schreibt (17.10.2026); `import_etc2_astc=true`, damit Windows- und Linux-Editor Texturen gleich importieren (18.10.2026). Ändert Godot sie trotzdem lokal, diese Änderungen nicht committen.

## Code (godot/)

- `core/`: Spiellogik ohne Grafik, meldet alles über Signale (`Combat`). `Character`/`Roster`/`Campaign`/`MissionResult`: Crew, Speicherstand, Schnittstelle zum Kampf. `view/`: Darstellung und Ablauf (`Battle`, `EventPlayer`, `PlayerController`). `ui/`: Oberfläche (schwebende Kästen über der Karte, Dialoge auf `Modal`). `data/`: Spieldaten als Ressourcen (`.tres`), im Editor bearbeitbar.
- Stil: GDScript mit Typangaben, deutsche Bezeichner in Texten und Kommentaren, Kommentare knapp mit `##` über Klassen und Funktionen.
- Tests (gestaffelt, Entscheidung des Nutzers 16.10.2026):
  - **Vor jedem Commit** (schnell): `godot --headless --path godot --script res://tests/test_rules.gd` und `… res://tests/test_hub.gd` (beide müssen „OK“ ausgeben)
  - **Vor der Fertigmeldung, nur bei Änderungen an Kampfregeln, KI oder Gegnern** (Boden oder Raum): `godot --headless --path godot --script res://tests/test_sim.gd -- 10` (KI gegen KI, kein Kampf darf hängen; `-- 45 missionen` = Siege je Schwierigkeit, nur bei Balancing-Fragen). Bei Hub, Story, Grafik oder Doku entfällt sie (Nutzer 28.10.2026).
  - **Vor der Fertigmeldung, nur für geänderte Bereiche** (mit Grafik, Screenshots nach `PTF_OUT`): Kampf → `godot --path godot -- --autotest`, `-- --autotest-player`, Psi → `-- --autotest-psi`, Hub/Startmenü/Schiff → `-- --autotest-hub`. Charakterübersicht/Roster → `-- --autotest` und `-- --autotest-hub`.
  - **Testregel des Nutzers (15.10.2026):** nur testen, was die Änderung betrifft, Unverändertes nicht extra. Grafische Tests nur für geänderte Oberflächenbereiche, oft reicht ein gezielter Screenshot. Grafik und Bedienung kann Claude nur bedingt prüfen; dort schaut der Nutzer selbst nach.
- **Verbrauch sparen (Nutzer 19.10.2026):** `main` nur vor der Fertigmeldung holen, nicht zwischendurch. Ausgaben kurz halten: `git merge -q`, `git fetch -q`, bei Tests nur die Ergebniszeilen lesen (z. B. `| grep -E "OK|FEHL|hängengeblieben" | tail -5`), keine langen Diffs oder Logs ausgeben. Lange Chats durch neue ersetzen (Übergabe in der Moduldatei).
- Neue Funktionen in `godot/README.md` und, wenn Regeln betroffen sind, in `docs/Skillsystem.md` nachtragen.
