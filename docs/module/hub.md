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

