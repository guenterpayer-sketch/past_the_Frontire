# Modul Hub (Startmenü, Schiff, Sternenkarte, Spielstände)

- **Branch:** `claude/happy-lamport-u4fvya`
- **Zuständig für:** `godot/start.tscn`, `godot/hub.tscn`, `godot/core/hub_state.gd`, `sector.gd`, `save_slots.gd`, `godot/view/hub.gd`, `ship_view.gd`, `start_screen.gd`, `godot/ui/hub_ui.gd`, `star_map.gd`, `slots_dialog.gd`, `godot/assets/ship/`.

## Schnittstellen (laut Branch, Commit `7657fed`)

- Startet den Bodenkampf mit einer Mission von der Sternenkarte (`HubState.active_mission()`, `Mission.generate(…, faction_path)`), bekommt einen Einsatzbericht zurück (`HubState.game.finish_mission(…)`).
- Spielstände: 3 Slots, kopieren u. a. `user://crew.json`.

## Stand (14.10.2026)

- 14.10.2026 (Hub-Chat): `main` (`2c91832`, mit Charakter-Modul) in den Hub-Branch geholt. Konflikte gelöst in `CLAUDE.md`, `godot/view/battle.gd`, `godot/ui/modal.gd` (beide Variablen `closable` und `max_size`), `godot/ui/crew/crew_overview.gd` (Fassung aus `main` übernommen, Hub-Änderungen daran verworfen).
- Aufträge 1–5 erledigt:
  1. Crewquartiere nutzen `CrewOverview` (mit `CharacterEditor` und `SheetDialog` wie in `crew.tscn`) direkt im Schiff; der Knopf „Speichern & nächste Mission“ wird im Schiff zu „Speichern & zurück“ umbenannt (von außen, ohne Änderung an `crew_overview.gd`).
  2. Hub nutzt nur noch `Campaign.crew()`, `Campaign.save()`, `Campaign.reset()`, `Campaign.add_member()`, `Roster.build_crew()`.
  3. `Battle.finish_mission()` ist das eine Kampfende: `MissionResult.from_combat()` → `Campaign.finish_mission()`; aus dem Schiff dann `HubState.game.finish_mission(hub_report(result))` und zurück ins Schiff, sonst nach `crew.tscn`. Keine eigene EP-Gutschrift mehr (geprüft: 3 + 3 = 6 freie EP nach einem Sieg „mittel“, nicht doppelt).
  4. `SaveSlots.load_slot()` ruft `Campaign.reload()`, `SaveSlots.save()` vorher `Campaign.save()`; Neues Spiel: `Campaign.reset()` + `Campaign.save()`.
  5. `ui/modal.gd`: `closable` und `max_size` beide da.
- Änderungen an Dateien anderer Module: `godot/view/battle.gd` (Bodenkampf: `finish_mission()` mit Weg ins Schiff, `hub_report()`, `return_to_ship()`, `new_battle(…, m)`), `ui/briefing_dialog.gd` (`hub_mode`), `ui/top_menu.gd` (`set_menu_text()`), `core/mission.gd` (`faction_path`), `data/types/faction_data.gd` + `data/missions/*.tres` (`color`). Am Charakter-Modul nichts geändert.
- Tests: `test_rules` OK, `test_hub` OK, `test_sim -- 30` OK (22 Siege, 0 hängengeblieben), `--autotest` (Schnellkampf → `crew.tscn`, Editor) fertig, `--autotest-player` fertig, `--autotest-hub` (Schiff → Kampf → zurück, Crewquartiere mit Ergebnis, Laden mit `Campaign.reload()`) fertig.
- Neu seit `77449d9` (noch nicht in `main`): Entscheidungen des Nutzers umgesetzt: „Crew zurücksetzen“ ist in den Crewquartieren im Schiff ausgeblendet. Der Schnellkampf aus dem Startmenü (`HubState.quick_battle`) nutzt die aktuelle Crew, verbucht nichts (kein `Campaign.finish_mission()`) und kehrt ins Startmenü zurück. Bodenkampf ohne Startmenü (Tests, „Speichern & nächste Mission“ in `crew.tscn`) verbucht wie bisher und geht nach `crew.tscn`.
- 15.10.2026: `main` (`1cf8d86`) erneut geholt, ohne Konflikte (nur Doku). **Bereit zum Zusammenführen.**

## Aufträge vom Koordinator

- ~~Aufträge 1–5 (Anpassung an das Charakter-Modul)~~ → erledigt, in `main` seit 15.10.2026 (`012efdf`).
- `main` holen (enthält jetzt die Moduldatei des Bodenkampfs).
- Charakter-Modul (Aufleveln, `d375736`) ist seit 15.10.2026 in `main`: `main` holen. Die Charakterübersicht in den Crewquartieren hat jetzt eine 3D-Vorschau; in den Crewquartieren einmal prüfen, ob sie dort richtig angezeigt wird (vom Koordinator nicht grafisch getestet).
- Bodenkampf `381fb01` ist in `main` (15.10.2026): Ergebnis-Banner mit „Weiter“, Rückzug ab Runde 1 (Bericht: Titel mit „(Rückzug)“, `outcome = niederlage`). Der Bodenkampf hat `tests/autotest_hub.gd` angepasst (drückt „Weiter“). `main` holen. Eigene Anzeige für Rückzug im Bericht: nur nach Entscheidung des Nutzers.

### Nach dem Spieltest (15.10.2026) – Grundlage: `docs/Planung_Roster_Verwundung.md`

1. **Roster und neues Spiel** (Abschnitt A, Teil Hub): Startmenü-Eintrag „Roster“, „Neues Spiel“ → Crew aus dem Roster wählen (UI mit dem Charakter-Modul abstimmen, erst **Mockup**). Plätze an Bord im `HubState` (zu Beginn 8, später ausbaubar), Anheuern aus dem Roster im Schiff. Spielstände enthalten die Crew, nicht den Roster.
2. **Krankenstation** (Abschnitt B, Teil Hub): Verwundete und Resttage anzeigen, Tage vergehen beim Reisen/Einsatz → Heilung (Funktion vom Charakter-Modul), vor dem Einsatz Gesperrte nicht mitnehmen, leicht Verletzte mit Malus. **Tage-Werte vorschlagen** (anhand typischer Reise- und Auftragsdauer) und vom Nutzer entscheiden lassen.
3. Rückzug im Bericht: weiter offen (nur nach Entscheidung des Nutzers).

### Stand 16.10.2026, zweite Runde (Hub-Chat) – **bereit zum Zusammenführen**

- `main` (`92f2d5b`) geholt, ohne Konflikte.
- **Anheuern im Hafen:** Brücke, System neutral und Schiff liegt dort → Abschnitt „Hafen: Crew“ mit Plätzen an Bord, Liste „im Hafen“ (`Campaign.harbor()`) und Roster-Figuren, die weder an Bord noch im Hafen sind; „Anheuern“ → `Campaign.hire()`, nur bei freiem Platz (`HubState.free_berths()`).
- **Krankenstation** (`core/medbay.gd`, `ui/medbay_dialog.gd`, Raum im Schiff jetzt nutzbar): Patienten, Personal bis 2 (`HubState.medics`, im Spielstand), Arzt/Helfer nach Zweiter Hilfe, Tagesprobe 100/150, 1 EP je Behandlungstag, Protokoll (`HubState.medlog`), „1 Tag warten“. Alle vergangenen Tage (Reisen, Einsatz, Warten) laufen über `HubState.advance_days(n)` → je Tag Probe und `Campaign.pass_days(1, Zusatztage)`; Geheilte werden im Schiff gemeldet.
- **Arzt-Sperre für die Truppwahl (Schnittstelle für den Bodenkampf):** `HubState.blocked_ids()` liefert die IDs, die gesperrt sind (der Arzt; im Schnellkampf und ohne Spiel leer). Der Bodenkampf ruft im Briefing `Campaign.candidates(HubState.quick_battle, HubState.blocked_ids())` auf.
- Ausblenden von „Anheuern“ in den Crewquartieren entfernt (Knopf gibt es nicht mehr); „Crew zurücksetzen“ wird weiter ausgeblendet.
- Tests: `test_rules` OK, `test_hub` OK (neu: Schwellen, Arzt/Helfer, Bonus, Sperre in `candidates`, Heilung mit/ohne Personal, EP, Reisen heilt, Hafen, Speichern von Personal/Protokoll, entlassenes Personal), `test_sim -- 30` OK (19 Siege, 0 hängengeblieben), `--autotest`, `--autotest-player`, `--autotest-hub` (neu: Entlassen und im Hafen wieder anheuern, Krankenstation mit Probe) durchgelaufen.
- Noch offen beim Bodenkampf: Truppwahl im Briefing mit `HubState.blocked_ids()`; `hub_report()` mit `Campaign.last_fallen`.

### Stand 16.10.2026 (Hub-Chat)

- `main` (`d8903d8`) geholt, ohne Konflikte.
- Auftrag 1 erledigt: Startmenü-Punkt **„Roster“** → `Campaign.ROSTER_SCENE`. **„Neues Spiel“** → Slot und Name → `CrewPicker.open_pick("Spielstand … · Slot …", HubState.BERTHS_START)` → `Campaign.new_game(chars)` → `HubState.new_game(…)` → speichern (`StartScreen.start_new_game()`). **Crewquartiere:** `CrewOverview.seats` = `HubState.berths`; nach `crew_changed` werden die Knopftexte neu gesetzt; Editor und `create_member` im Schiff entfernt. „Anheuern“ und „Crew zurücksetzen“ werden in den Crewquartieren ausgeblendet (Suche nach dem Knopftext in `footer` – Charakter-Modul bitte Knopftexte „Anheuern“, „Crew zurücksetzen“, „Speichern & nächste Mission“ nicht ohne Ankündigung ändern). `user://roster.json` ist nicht in den Slots (Test in `test_hub`).
- Auftrag 2 erledigt: **Schnellkampf** nutzt `Campaign.new_game(GlobalRoster.entries())` (Trupp wählt der Bodenkampf im Briefing über `Campaign.squad()`), keine Auswahl im Hub, nichts wird verbucht. Hinweis: dabei wird die Crew-Arbeitskopie `user://crew.json` durch die Roster-Figuren ersetzt; Spielstände bleiben unverändert (geprüft im `--autotest-hub`).
- Tests: `test_rules` OK, `test_hub` OK, `test_sim -- 30` OK (19 Siege, 0 hängengeblieben), `--autotest`, `--autotest-player`, `--autotest-hub` (Roster, CrewPicker, neues Spiel, Einsatz, Laden, Schnellkampf) durchgelaufen.
- Auftrag 3 (Anheuern im Hafen, Krankenstation, Arzt-Zuweisung) wartet auf das Charakter-Modul (Verwundung, „Tage vergehen“, Sperr-Status).

### Gültig: Klärung Hub ⇄ Charakter (`docs/Planung_Roster_Verwundung.md`, Abschnitt D)

Ersetzt abweichende Einträge weiter unten:
- **Neues Spiel:** Der Hub ruft den **`CrewPicker` des Charakter-Moduls** auf (1 bis 8 Figuren) und baut keine eigene Auswahl. Mockup-Bildschirm „6 Neues Spiel“ entfällt.
- **Roster im Startmenü:** Punkt „Roster“ → `Campaign.ROSTER_SCENE`.
- **Anheuern:** nur im Hafen (neutrale Systeme) auf der Brücke, bei freiem Platz; Funktion `Campaign.hire()` vom Charakter-Modul, Hafen-Bedingung und UI vom Hub.
- **Entlassen:** Liste „im Hafen“ gehört zu `Campaign` (mit der Crew gespeichert); der Hub zeigt sie im Hafen an. Entlassen-Knopf in den Crewquartieren (Charakter-Modul).
- **Einsatztrupp:** wählt der **Bodenkampf im Briefing** (auch beim Schnellkampf), Ergebnis `Campaign.chosen_squad`; der Hub liefert die Arzt-Zuweisung (Arzt gesperrt).
- **Offen:** Im Hub-Chat hatte der Nutzer für den Schnellkampf „6 aus dem Roster wählen“ entschieden; Abschnitt D sagt nur „Truppwahl im Briefing auch beim Schnellkampf“. Woher die Figuren beim Schnellkampf kommen (Roster oder Crew des Spielstands), ist damit noch nicht eindeutig.

### Entscheidungen des Nutzers zum Spieltest-Auftrag (15.10.2026, im Hub-Chat) – teilweise ersetzt durch Abschnitt D

**Heilung (Abschnitt B):**
- Grundtage je Stufe („mittel“): angeschlagen **2**, kampfunfähig **5**, schwer verwundet **10** Tage. Zuschlag für den schwersten erlittenen Kritischen: A **+0**, B **+1**, C **+2**, D **+3**, E **+4**. (Grundlage: ein Einsatz-Zyklus – zum nächsten Auftrag fliegen + 1 Tag Einsatz – dauert im Schnitt 2,5 Tage, gemessen über 100 simulierte Spiele; eine Route zwischen zwei Systemen Ø 3,7 Tage, ein Sprung Ø 1,65.) → Stufe und Tage berechnet das Charakter-Modul in `Campaign.finish_mission()`.
- **Krankenstation:** bis zu 2 Crewmitglieder zugewiesen. Wer die höchste **Zweite Hilfe** hat, ist **Arzt** (voller Bonus), der zweite **Helfer** (halber Bonus).
- **Jeden Tag** eine **Zweite-Hilfe-Probe**: W100 offen + Arzt-Bonus + Helfer-Bonus/2. Unter 100: der normale Heiltag (1). 100–149: +1 Tag. Ab 150: +2 Tage. Gilt für jeden Patienten. (Beispiel Arzt +50, Helfer +30: Ø ca. 1,8 Tage Heilung pro Tag; schwer verwundet meist nach 6 Tagen fit.)
- **EP:** Arzt und Helfer bekommen je Tag mit mindestens einem Patienten 1 EP in Zweite Hilfe.
- **Einsatz:** Der **Arzt bleibt an Bord** (nicht im Einsatztrupp, solange zugewiesen), der Helfer darf mit.
- **Warten:** Knopf „1 Tag warten“ im Schiff (Aufträge laufen weiter ab, neue kommen).

**Schon gebaut (Hub, ohne andere Module):** `HubState.berths` (Plätze an Bord, Start `BERTHS_START` = 8, im Spielstand gespeichert), `HubState.wait_days(n)` und Knopf „1 Tag warten“ auf der Brücke (Aufträge laufen ab, neue kommen dazu). Die Heilung hängt sich später an dieselben Tage (Reisen, Einsatz, Warten).

**Wartet auf andere Module:** Krankenstation (braucht Verwundung in `Character`/`Campaign` und die Funktion „Tage vergehen“ vom Charakter-Modul, `MissionResult`-Felder vom Bodenkampf), Roster-Auswahl beim neuen Spiel/Schnellkampf und Anheuern (braucht den Roster-Speicher und `Campaign` mit Einsatz/Reserve vom Charakter-Modul), Einsatztrupp im Briefing (Bodenkampf).

**Roster und Crew (Abschnitt A, Teil Hub):**
- **Neues Spiel:** aus dem Roster **6 bis 8** Figuren wählen (6 Einsatztrupp, bis 2 Reserve gleich zu Beginn).
- **Anheuern** im Schiff auf der **Brücke, nur im Hafen** = einem der **neutralen Systeme** (2 je Sektor, darunter der Heimathafen), solange Plätze an Bord frei sind.
- **Entlassen** ist möglich. Der Fortschritt der Figur bleibt **im Spielstand** erhalten (Liste „im Hafen“); sie kann in diesem Spiel in einem Hafen wieder angeheuert werden. Der globale Roster bleibt unberührt.
- **Mockup** (Artifact „Schiff-Hub Mockup“, Reihe „Nach dem Spieltest“, Bildschirme 5–9): Startmenü mit „Roster“, Neues Spiel (Crew aus dem Roster wählen, 6–8), Brücke im Hafen (Anheuern aus dem Roster und „im Hafen“), Krankenstation, Briefing mit Einsatztrupp (Vorschlag für den Bodenkampf). **Vom Nutzer freigegeben** (15.10.2026).
- **Weniger als 6 einsatzbereit:** Einsatz trotzdem möglich (mit Warnung im Briefing), auch mit 1–5 Figuren.
- **Schnellkampf:** genau 6 Figuren aus dem Roster wählen (kurze Auswahl wie beim neuen Spiel), verbucht weiterhin nichts.
- **Einsatztrupp** (6 aus Crew + Reserve) wird **beim Briefing** gewählt: Gesperrte (kampfunfähig, schwer verwundet, Arzt) ausgegraut, Angeschlagene markiert. Das Briefing gehört zum Bodenkampf → Schnittstelle mit Bodenkampf und Charakter abstimmen.

## Aufträge vom Koordinator (16.10.2026)

Charakter (Roster, `CrewPicker`, `Campaign.squad()`) und Bodenkampf (Verwundung, Psi) sind in `main` (`fdb96d9`). Zuerst `main` holen. Grundlage: `docs/Planung_Roster_Verwundung.md`, Abschnitte D und E.
1. **Jetzt:** Startmenü-Punkt „Roster“ (`Campaign.ROSTER_SCENE`); „Neues Spiel“ → `CrewPicker` (1–8) → `Campaign.new_game(chars)`; Crewquartiere: `seats` aus `HubState.berths`, nach `crew_changed` Knopftext neu setzen, Editor/`create_member` dort entfernen; `user://roster.json` nicht in die Slots (Anbindungsliste in `charakter.md`).
2. **Schnellkampf:** Figuren kommen **aus dem globalen Roster** (Entscheidung 16.10.); keine eigene Auswahl im Hub – die Truppwahl macht der Bodenkampf im Briefing. Der Hub startet nur den Schnellkampf (`HubState.quick_battle`).
3. **Danach, wenn das Charakter-Modul geliefert hat:** Anheuern auf der Brücke nur im Hafen (Roster + Liste „im Hafen“), Krankenstation mit Arzt/Helfer und Tagesprobe (Werte wie in dieser Datei), Arzt-Zuweisung für die Sperre in der Truppwahl.

## Aufträge vom Koordinator (16.10.2026, nach Merge `675d17c`)

Charakter `d654883` (Verwundung, Hafen-Liste, Kandidaten) und dein Stand sind in `main`. `main` holen. Jetzt bauen (Details `docs/Planung_Roster_Verwundung.md`, Abschnitt F, und die Heilungswerte in dieser Datei):
1. Anheuern auf der Brücke nur im Hafen: Roster-Figuren und die Liste „im Hafen“ (`Campaign.harbor()`), über `Campaign.hire()`, nur bei freiem Platz.
2. Krankenstation: Patienten (`Campaign.patients()`), Arzt/Helfer zuweisen, Tagesprobe, `Campaign.pass_days(days, bonus)` bei Reisen, Einsatz und „1 Tag warten“; EP für Arzt/Helfer.
3. Arzt-Sperre: dem Bodenkampf die IDs für `Campaign.candidates(quick, blocked_ids)` bereitstellen (Schnittstelle mit ihm abstimmen).
4. Das Ausblenden von „Anheuern“ in `ui/hub_ui.gd` kann entfallen (der Knopf existiert nicht mehr).
- ~~Aufträge vom 16.10.2026 (Anheuern im Hafen, Krankenstation, Arzt-Sperre)~~ → in `main` seit `014eab8`. Nichts offen; `main` holen.

## Aufträge vom Koordinator (15.10.2026): Waffenkammer

Grundlage: `docs/Planung_Waffenkammer.md`. Raum „Waffenkammer“ im Schiff nutzbar machen (jederzeit), er öffnet den **Ausrüstungsdialog des Charakter-Moduls**. Keine eigene Ausrüstungs-Oberfläche bauen. Warten, bis das Charakter-Modul den Dialog geliefert hat; den Aufruf aus `charakter.md` übernehmen.

### Stand Waffenkammer (Hub-Chat, 15.10.2026)

- `main` (`7b4af1a`) geholt, ohne Konflikte.
- Entscheidung des Nutzers: Raum **jetzt aufteilen** in **Waffenkammer** (`&"armory"`, Rect 0–16 × 8–16, Regale, Werkbank) und **Hangar** (`&"hangar"`, 0–16 × 0–8, Landungsschiff, Platzhalter), Durchgang zwischen beiden. Gebaut in `view/ship_view.gd`.
- Waffenkammer steht noch auf „kommt noch“: **wartet auf den Ausrüstungsdialog des Charakter-Moduls** (noch nicht in `main`). Danach: `ready = true` und in `Hub.open_room(&"armory")` den Aufruf aus `charakter.md` einsetzen, Test im `--autotest-hub`.
- 15.10.2026: `main` (`0174ee5`, mit `ArmoryDialog`) geholt, ohne Konflikte. **Waffenkammer angebunden:** Raum nutzbar, öffnet `ArmoryDialog.open_for(Campaign.crew(), 0)` (angelegt in `ui/hub_ui.gd`), `done` → Schiff aktualisieren. Keine eigene Ausrüstungs-Oberfläche. Tests: `test_rules` OK, `test_hub` OK, `test_sim -- 10` OK (0 hängengeblieben), `--autotest-hub` durchgelaufen (Dialog öffnet, „Fertig“ schließt). **Bereit zum Zusammenführen.**

## Aufträge vom Koordinator (15.10.2026): Einstellung UI-Größe

Grundlage: `docs/Planung_UI_Groesse.md`. Einstellung „UI-Größe“ (z. B. 75 / 90 / 100 / 125 %) für das ganze Spiel: speichern, beim Start anwenden (Vorschlag: `get_window().content_scale_factor`), Auswahl im Startmenü. Funktion zum Lesen/Setzen bereitstellen und unter „Schnittstellen“ vermerken (der Bodenkampf nutzt sie evtl. im Kampfmenü). Stufen und Ort im Menü mit dem Nutzer bestätigen.

### Stand UI-Größe (Hub-Chat, 15.10.2026) – **bereit zum Zusammenführen**

- Entscheidungen des Nutzers: Stufen **75 / 90 / 100 / 125 %** (Standard 100 %); einstellbar im **Startmenü (Einstellungen)**, im **Schiff (Menü oben rechts, „UI-Größe …“)** und im **Kampfmenü** (baut der Bodenkampf mit der Funktion unten).
- **Schnittstelle (für alle Module):** `UiScale` (`ui/ui_scale.gd`):
  - `UiScale.get_factor() -> float` – gespeicherter Faktor (eine der `UiScale.STEPS`),
  - `UiScale.set_factor(f, get_tree())` – setzen, in `user://ui.cfg` speichern, sofort anwenden,
  - `UiScale.apply(get_tree())` – gespeicherten Faktor anwenden (Startmenü und Schiff tun das beim Laden; der Faktor bleibt am Fenster auch über Szenenwechsel),
  - `UiScale.picker(get_tree()) -> HBoxContainer` – fertige Knopfzeile „UI-Größe 75 % | 90 % | 100 % | 125 %“ zum Einbauen in einen Dialog (so im Startmenü und im Schiff; der Bodenkampf kann sie in sein Kampfmenü setzen).
  - Wirkung: `get_tree().root.content_scale_factor`; alle 2D-Oberflächen aller Szenen werden skaliert, 3D bleibt gleich. Eigener Speicherort `user://ui.cfg` (nicht `settings.cfg`, damit sich `Prefs` und `UiScale` beim Speichern nicht überschreiben).
- Tests: `test_rules` OK, `test_hub` OK (Stufen, Speichern/Anwenden, ungültige Stufe), `test_sim -- 10` OK (0 hängengeblieben), `--autotest-hub` durchgelaufen (UI-Größe im Schiff auf 75 % und zurück).

## Aufträge vom Koordinator (15.10.2026): Reise, Schiff, Credits

Grundlage: `docs/Planung_Reise_Schiff.md` (Entscheidungen des Nutzers). Das Hub-Modul baut alles allein: Reiseproben pro Reisetag (Pilot, Navigation, Computer, Reparatur nach Station, sonst Bester verfügbar) mit EP, Treibstoff, Hülle, Schiffsmaterial, Credits, Lohn und Beute nach Fraktion und Schwierigkeit, Kaufen im Raumhafen, Speichern und Anzeige. **Vorher:** Zahlenvorschlag (Tabelle) und Mockup der Anzeige dem Nutzer vorlegen und bestätigen lassen. Regeln danach in `docs/Skillsystem.md` nachtragen.

### Stand Reise, Schiff, Credits (Hub-Chat, 15.10.2026) – **bereit zum Zusammenführen**

- `main` (`2d378ab`) geholt, ohne Konflikte.
- Zahlen und Mockup vom Nutzer bestätigt (Artifact „Schiff-Hub Mockup“, Reihe „Reise, Schiff, Credits“, Bildschirme 10–14), mit seinen Änderungen: Lohn knapper (80/140/220), **Notkredit** für Treibstoff, **große Reparatur auch durch die Crew** unterwegs, **Krankenstation (Arzt und Helfer) würfelt keine Reiseprobe**. Regeln in `docs/Skillsystem.md` 8b.
- Neu: `core/voyage.gd` (Regeln), `HubState` mit `credits`, `fuel`, `hull`, `material`, `emergency` (im Spielstand; alte Spielstände bekommen die Startwerte), `last_travel` (Reisebericht), `stranded()`, `nearest_harbor()`, `can_travel()`, `crew_repair()`; Lohn und Beute in `HubState.finish_mission()` (Bericht `rep.payout`) – **keine Änderung am Bodenkampf nötig**.
- Anzeige: Statusleiste im Schiff (Credits, Treibstoff- und Hüllenbalken, Material, Warnungen), Sternenkarte (Treibstoff-Schätzung, Reiseposten, „Große Reparatur (1 Tag)“, Reiter „Raumhafen“/„Crew anheuern“ im Hafen), Reisebericht nach jeder Reise (vor dem Einsatz: „Weiter“ → Briefing), Lohn und Beute im Einsatzbericht. Veralteter Hinweis „Prototyp: Verletzte … wieder voll da“ im Einsatzbericht entfernt.
- Vom Hub-Chat festgelegt (nicht vom Nutzer): freie Posten nach höchster Wertesumme besetzt; bei Hülle 0 gehen Werft und Material auch auf Notkredit (sonst kann das Spiel im Hafen festsitzen); unbesetzter Posten = keine Probe.
- Tests: siehe Fertigmeldung im Chat.

## Aufträge vom Koordinator (15.10.2026): Musik

Entscheidungen des Nutzers: Musik im **Startmenü, Schiff, Bodenkampf und bei Sieg/Niederlage**. Quelle: vom Nutzer mit einem KI-Generator erzeugte **MP3-Dateien** (liegen beim Nutzer; Ablage z. B. `godot/audio/music/`, Zuordnung der Stücke mit dem Nutzer klären). Der **Hub baut den Musikspieler**:
- Autoload `Music` (Muster wie `Sfx` in `audio/sfx.gd`): Stück nach Name abspielen, weich überblenden, Schleife für Hintergrundstücke, kurze Stücke (Sieg/Niederlage) einmalig.
- Lautstärke **Musik** (und ggf. Effekte) in den Einstellungen (Startmenü und Schiffsmenü, wie UI-Größe), gespeichert.
- Startmenü und Schiff selbst anbinden.
- Schnittstelle (Aufrufe für den Bodenkampf) unter „Schnittstellen“ vermerken; Bodenkampf baut danach nur die Aufrufe.

### Stand Musik (Hub-Chat, 15.10.2026) – **bereit zum Zusammenführen**

- `main` (`a8e9d5e`) geholt, ohne Konflikte.
- Entscheidungen des Nutzers: MP3s legt er **selbst** ab (GitHub Desktop); **ein Ordner je Anlass**, teils mehrere Stücke (zufälliger Wechsel); Bodenkampf getrennt: **Briefing ruhig, Kampf spannend**; Sieg/Niederlage **in Schleife**, bis man weitergeht; Regler **Musik und Effekte**.
- Gebaut: Autoload `Music` (`audio/music.gd`, in `project.godot` nach `Sfx`), Ordner `audio/music/{start,ship,briefing,battle,victory,defeat}/` (mit `.gitkeep`, noch ohne Stücke), Regler in den Einstellungen des Startmenüs und im Schiff (Menüpunkt „UI-Größe …“ heißt jetzt „Einstellungen …“: UI-Größe, Musik, Effekte). Startmenü spielt `start`, Schiff `ship`. Die Effekte (`Sfx`) laufen über den Bus „SFX“ (setzt `Music` beim Start, `audio/sfx.gd` unverändert).
- **Schnittstelle für den Bodenkampf** (nur Aufrufe bauen):
  - Briefing öffnet / Runde 0: `Music.play(Music.BRIEFING)`
  - Kampf beginnt (Runde 1): `Music.play(Music.BATTLE)`
  - Ergebnis-Banner: `Music.play(Music.VICTORY)` bzw. `Music.play(Music.DEFEAT)` (auch Rückzug)
  - Zurück ins Schiff/Startmenü: nichts nötig (Schiff und Startmenü rufen selbst `play`). Nach `crew.tscn` läuft die letzte Musik weiter.
  - Gleicher Anlass zweimal = kein Neustart; leerer Ordner = Stille. Weitere: `Music.stop()`, `Music.volume_rows()` (Regler zum Einbauen, z. B. ins Kampfmenü).
- Stücke vom Nutzer abgelegt (Commit `abaea11`): start 2, ship 5, briefing 3, battle 3, victory 1, defeat 1 – alle ladbar (geprüft). Herkunft/Lizenz noch nicht in `godot/assets/LICENSES.md`.
- Tests: `test_rules` OK, `test_hub` OK, `--autotest-hub` durchgelaufen (Anlass start/ship, Busse, Lautstärke 30 % = −10,5 dB, 0 % = stumm). Wiedergabe mit erzeugten Testtönen geprüft (nicht eingecheckt): zwei Stücke → Wechsel nach Ende, ein Stück → Schleife, leerer Anlass → Stille.

## Aufträge vom Koordinator (15.10.2026): Editor für eigene Waffen und Rüstungen

Grundlage: `docs/Planung_Ausruestungs_Editor.md` (Entscheidungen des Nutzers). Editor im Startmenü, globale Speicherung, Baustein für die anderen Module (Abschnitt „Aufteilung“, Punkt 1). Bodenkampf und Charakter binden danach an. **Vorher:** offene Punkte klären und Mockup vom Nutzer bestätigen lassen.

### Stand Ausrüstungs-Editor (Hub-Chat, 15.10.2026) – **bereit zum Zusammenführen**

- `main` (`0737d29`) geholt; Konflikt nur in dieser Datei (Hinweis Munition), beide Teile behalten.
- Entscheidungen des Nutzers: **Grenzen** wie vorgeschlagen (Reichweite, Mindestabstand, Magazin, Munition ±50 %; Stufen ±1; Höchstergebnis ±10; Patzer ±2; Schaden ±0,2; Angriffsbonus, Druckwelle ±10; Nah/Fern wie Vorlage; Rüstung: Klasse wie Vorlage, Verteidigung ±5, Bewegung ±1); frei eingetragene tragen den Vermerk **„frei“**; **gelöschte getragene Ausrüstung → Standard** (Waffe 1 → Fäuste, Waffe 2 → leer, Rüstung → keine); **Gegner: an/aus + Fraktionen** (alle vorbelegt); eigene **Nahkampfwaffen ohne Modell**. Mockup „Schiff-Hub Mockup“ Bildschirme 15–17 bestätigt.
- Gebaut: Startmenü „Ausrüstung“ → `GearEditor` (`ui/gear_editor.gd`), Regeln und Speichern `Gear` (`core/gear.gd`).
- **Schnittstelle für Bodenkampf und Charakter:**
  - Gespeichert als Ressourcen-Dateien `user://gear/weapons/<id>.tres` (`WeaponData`) und `user://gear/armor/<id>.tres` (`ArmorData`). `Character.to_dict()`/`from_dict()` speichern sie unverändert über `resource_path`.
  - `Gear.weapons()`, `Gear.armors()`: alle eigenen. `Gear.enemy_weapons(faction_path)`, `Gear.enemy_armors(faction_path)`: für Gegner dieser Fraktion freigegeben (Pfad der `FactionData`). `Gear.is_custom(r)`, `Gear.is_free(r)` (Vermerk „frei“).
  - Gelöscht: Datei fehlt, `load()` des Pfads schlägt fehl. **Charakter:** dann `Gear.FALLBACK_WEAPON` (Fäuste) für Waffe 1, Waffe 2 leer, `Gear.FALLBACK_ARMOR` (keine); `Equipment.weapons()/armors()` um `Gear.weapons()/armors()` ergänzen.
  - **Bodenkampf:** `GameData.weapons()` um `Gear.weapons()` ergänzen; Gegner bekommen `Gear.enemy_weapons/armors(Fraktion)` laut Einstellung.
- ~~Offen: Munition im Editor~~ → erledigt mit „Munition (Teil Hub)“ (ohne Grenzen). Mit den Grenzen (±50 %) bleiben Magazin/Munition bei Vorlagen ohne Munition auf 0; einstellbar nur mit „frei“. Klären, wenn der Bodenkampf die Munition gebaut hat (`docs/Planung_Munition.md`).
- Tests: `test_rules` OK, `test_hub` OK (Grenzen, Speichern mit Metadaten, Bearbeiten ändert getragenen Eintrag, frei, Gegner nach Fraktion, Charakter speichert per Pfad, Löschen), `--autotest-hub` durchgelaufen (Editor). `test_sim` nicht gelaufen (Bodenkampf unverändert, Testregel).

## Hinweis vom Koordinator (15.10.2026): Munition

Neue Entscheidungen in `docs/Planung_Munition.md`: Feuerstoß mit *Schuss pro Angriff*, *Munitionsart* je Waffe, Schiffsvorrat je Munitionsart mit Kauf im Raumhafen. Der Bodenkampf baut zuerst die Felder in `WeaponData`; erst danach der Hub-Teil (Vorrat, Kauf, Abzug, Editor-Felder). Für den Ausrüstungs-Editor: die beiden neuen Felder vorsehen, sobald sie in `main` sind.

## Aufträge vom Koordinator (15.10.2026): Munition (Teil Hub)

Munition Teil Kampf ist in `main` (`928b0f9`); Schnittstelle in `docs/module/bodenkampf.md` unter „Schnittstellen“ → Munition. Grundlage `docs/Planung_Munition.md`.
1. Vorrat im Spielstand: `HubState.game.ammo = {"energie": n, "projektil": n, "raketen": n}`; nach dem Einsatz `ammo_used` aus dem `MissionResult` abziehen; Anzeige im Schiff; Kauf im Raumhafen (Preise mit dem Nutzer).
2. Ausrüstungs-Editor: Felder `shots` (Schuss pro Angriff) und `ammo_type` (Munitionsart) ergänzen; `ammo_total` ist jetzt die Obergrenze der Mitnahme. `core/gear.gd` führt `ob_bonus` als „Angriffsbonus“ – der Feuerstoß läuft jetzt über `shots`.

### Stand Munition, Teil Hub (Hub-Chat, 15.10.2026) – **bereit zum Zusammenführen**

- `main` (`36ca0fe`) geholt, ohne Konflikte.
- Entscheidungen des Nutzers: Startvorrat Energiezellen 200, Projektil 300, Raketen 6; Preise **teurer**: 2 / 2 / 50 Cr je Schuss (Pakete +30/+100, Raketen +1/+5), nur mit genug Credits (kein Notkredit); **Beute bei Sieg: wenig, zufällig** (eine Art, Energie/Projektil +10 bis +40, Raketen +1); Editor: Magazin, Munition gesamt, Schuss pro Angriff **ohne Grenzen** (kein Vermerk „frei“), Munitionsart wählbar; Anzeige ohne Mockup.
- Gebaut: `HubState.ammo` (im Spielstand, alte Stände bekommen den Startvorrat), Abzug in `HubState.finish_mission()` aus `Campaign.last_result.ammo_used` (nicht unter 0; `rep.ammo_used` im Einsatzbericht), Statusleiste „Munition“, Kasten „Munition“ im Raumhafen, Beute im Einsatzbericht. Editor: Felder `magazine`, `ammo_total`, `shots`, Munitionsart; `ob_bonus` heißt jetzt „Angriffsbonus (fest)“. Regeln in `docs/Skillsystem.md` 8b.
- **Schnittstelle:** unverändert wie vom Bodenkampf vorgegeben – `HubState.game.ammo = {"energie": n, "projektil": n, "raketen": n}` (`Battle.ammo_stock()` liest ihn), Rückgabe über `MissionResult.ammo_used`. Am Bodenkampf nichts geändert.
- Tests: `test_rules` OK, `test_hub` OK (Startvorrat, Kauf nur im Hafen/mit Credits, Abzug nicht unter 0, Einsatzende mit Verbrauch und Beute, Speichern, Editor-Felder), `--autotest-hub` durchgelaufen (Raumhafen, Statusleiste, Einsatz mit Beute, Editor). `test_sim` nicht gelaufen (Kampf unverändert).

## Hinweis vom Koordinator (16.10.2026): Vorlagen bleiben fest

Der in `docs/module/bodenkampf.md` notierte Wunsch, die mitgelieferten Waffen im Ausrüstungs-Editor editierbar zu machen, ist **zurückgenommen** (Entscheidung des Nutzers): Die Standardwaffen bleiben unverändert, sie sind die Vorlagen für neue Waffen. Nichts zu bauen.

## Hinweis vom Koordinator (16.10.2026): neue Modelle und Klänge im Editor

Siehe `docs/Planung_Waffenmodelle_Klaenge.md`. Der Bodenkampf liefert zuerst einen Modell-Katalog und eine Klangliste; danach bietet der Ausrüstungs-Editor alle Modelle und den Wert *Klang* an. Bis dahin nichts zu bauen.

## Aufträge vom Koordinator (16.10.2026): Enzyklopädie

Grundlage: `docs/Planung_Enzyklopaedie.md` (Entscheidungen des Nutzers). Du baust den gemeinsamen Dialog und bindest ihn im Startmenü und Schiff an (Abschnitt „Aufteilung“, Punkt 1). **Vorher Mockup.** Bodenkampf und Charakter binden danach an.

### Stand Enzyklopädie (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`61ae834`) geholt, ohne Konflikte.
- Mockup (Artifact „Schiff-Hub Mockup“, Bildschirme 18–21) vom Nutzer bestätigt. Entscheidungen: Kurzregeln **aus `docs/Skillsystem.md`** (Abschnitte 1, 4, 5.1, 5.3, 5.4, 7, 7.2, 8, 8a, 8b; zur Laufzeit aus `../docs/Skillsystem.md` neben dem Projektordner gelesen, also immer aktuell; im exportierten Spiel fehlen sie); Fertigkeiten **mit Kurzbeschreibung** (`core/skill_texts.gd`, Texte vom Hub-Chat, „Im Spiel noch ohne Wirkung“ wo zutreffend).
- Gebaut: `Encyclopedia` (`ui/encyclopedia.gd`, auf `Modal`): Bereiche Waffen (mitgelieferte + eigene, „frei“-Vermerk), Rüstungen, Angriffstabellen, Kritische Treffer, Patzer, Psi-Listen, Fertigkeiten, Kurzregeln; Suche über alle Bereiche; Verweise (z. B. Waffe → Tabelle, Kritische, Patzer; Fertigkeit Psi-Liste → Liste) anklickbar. Startmenü: neues **Burgermenü** oben rechts (Enzyklopädie, Einstellungen …). Schiff: Menüpunkt „Enzyklopädie“.
- **Schnittstelle für Bodenkampf und Charakter:**
  - `Encyclopedia.show_on(control, bereich, eintrag)` – legt den Dialog einmal unter `control` an (Name `Encyclopedia.NAME`) und öffnet ihn; `control` sollte das UiTheme haben (z. B. die oberste UI-Control der Szene).
  - Bereiche: `&"waffen"`, `&"ruestungen"`, `&"tabellen"`, `&"kritische"`, `&"patzer"`, `&"psi"`, `&"fertigkeiten"`, `&"regeln"`. Eintrag = angezeigter Name: Waffe `w.name`, Psi-Liste `PsiLists.LISTS[id].name` (z. B. „Angriff“), Fertigkeit wie in `Rules.SKILL_GROUPS`, Tabelle `AttackTableData.name`, Kritische `CritTableData.name`. Leer = erster Eintrag.
  - **Bodenkampf:** Burgermenü → `show_on(ui, &"waffen")`; „Tabellen“ → `show_on(ui, &"waffen", gewählte_waffe.name)`; `TablesDialog` kann danach entfallen.
  - **Charakter:** ⓘ bei Psi-Listen → `show_on(…, &"psi", PsiLists.LISTS[id].name)`; Zugang in Übersicht/Editor nach Absprache mit dem Nutzer.
- Tests: `test_rules` OK, `test_hub` OK (alle Bereiche gefüllt, Kurzregeln gefunden und sauber abgegrenzt, Beschreibung für jede Fertigkeit, Markdown-Umwandlung, Suche), `--autotest-hub` durchgelaufen (Burgermenü im Startmenü, Waffe, Psi-Liste, Kurzregel, Suche „deckung“ 5 Treffer, Menü im Schiff). `test_sim` nicht gelaufen (Kampf unverändert).
