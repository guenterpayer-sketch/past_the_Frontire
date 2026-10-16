# Modul Hub (Startmenü, Schiff, Sternenkarte, Spielstände)

- **Branch:** `claude/happy-lamport-u4fvya`
- **Zuständig für:** `godot/start.tscn`, `godot/hub.tscn`, `godot/core/hub_state.gd`, `sector.gd`, `save_slots.gd`, `godot/view/hub.gd`, `ship_view.gd`, `start_screen.gd`, `godot/ui/hub_ui.gd`, `star_map.gd`, `slots_dialog.gd`, `godot/assets/ship/`.

## Schnittstellen (laut Branch, Commit `7657fed`)

- Startet den Bodenkampf mit einer Mission von der Sternenkarte (`HubState.active_mission()`, `Mission.generate(…, faction_path)`), bekommt einen Einsatzbericht zurück (`HubState.game.finish_mission(…)`).
- Spielstände: 3 Slots, kopieren u. a. `user://crew.json`.
- **Lagerformat für beschädigte Stücke** (16.10.2026, `core/stock.gd`): Jedes beschädigte Stück liegt in `HubState.stock` unter einem eigenen Schlüssel **„Grundschlüssel|Schaden“**, z. B. `"res://data/weapons/sturmgewehr.tres|-20"` → Anzahl. Schaden −10/−20/−30 wie `Character.wear`/`Combatant.wear` (−30 = unbrauchbar). Gleicher Gegenstand mit gleichem Schaden wird gezählt (×2), jeder andere Schaden ist ein eigener Eintrag. Intakte Stücke behalten den Grundschlüssel (`Stock.key_of(r)`) wie bisher. Schild und Medikits sind nie beschädigt.
  - Bauen/Zerlegen: `Stock.damaged_key(key, damage)` (0 → Grundschlüssel, höchstens −30), `Stock.base_of(key)`, `Stock.damage_of(key)` (0 = intakt), `Stock.damage_steps(key)`, `Stock.damage_text(damage)` (" (−20)", " (−30, unbrauchbar)").
  - `Stock.count/take/add(g, key, n)` arbeiten unverändert mit diesen Schlüsseln; `Stock.items(g)` liefert zusätzlich `damage`; `Stock.name_of(key)` hängt den Schaden an („Sturmgewehr (−20)“); `Stock.price(key)` = Kaufpreis des intakten Stücks.
  - **Für die Waffenkammer (Charakter):** Anlegen eines beschädigten Stücks = `Stock.take(g, key)` und `ch.wear[platz] = Stock.damage_of(key)`; Ablegen = `Stock.add(g, Stock.damaged_key(Stock.key_of(r), int(ch.wear.get(platz, 0))))` und `ch.wear.erase(platz)`. Ein beschädigtes Stück lädt man über `load(Stock.base_of(key))`. `Equipment.in_stock`/`count` mit `Stock.key_of(r)` zählt nur intakte Stücke.
  - **Gute Stücke (+5) aus dem Handwerk** (16.10.2026, gilt so): im Lager unter **`"Grundschlüssel|+5"`** (`Stock.damaged_key(key, 5)`; jeder positive Wert ergibt `|+5`), an der Figur **`Character.wear[platz] = 5`** (`Stock.BONUS`; positiver Wert = Bonus: Waffe +5 auf Angriffe, Rüstung +5 auf die Verteidigung). `Stock.damage_of(key)` liefert dann `5`, `Stock.is_fine(key)` = true, `Stock.name_of` „Sturmgewehr (+5)“, `Stock.damage_text(5)` = " (+5)". Anlegen/Ablegen genau wie bei beschädigten Stücken (der `wear`-Wert des Platzes geht mit). **Der erste Schaden nimmt den Bonus:** +5 → 0 → −10 → … (Bodenkampf: `Combatant.add_wear` setzt einen positiven Wert auf 0). Beute ist nie +5. Verkauf: Verkaufspreis × 1,5 (`Stock.SELL_BONUS`); Werkstatt: nichts zu reparieren.
  - Preise: Verkauf `Stock.sell_price(key, g)` je −10 um 25 % weniger; Werkstatt im Raumhafen `Stock.repair_cost(g, key)` (10 % vom Kaufpreis je −10, nach Handeln), `Stock.can_repair/repair(g, key)` (ganz, nur Lager); Schrottwert `Stock.scrap_value(key)` (15 %, −30 = 0).

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

## Aufträge vom Koordinator (16.10.2026): Modelle und Klänge im Editor

Teil Bodenkampf ist in `main` (`9896e43`), Schnittstelle in `docs/module/bodenkampf.md` unter „Schnittstellen“. Im Ausrüstungs-Editor:
1. `WeaponModels.all()` statt `Gear.models()` anbieten; `WeaponModels.apply(waffe, eintrag)` setzt Modell, Länge, Griff, Zweihändigkeit.
2. Klangauswahl `WeaponData.SOUNDS` für `sound_id`; der Eintrag `"sound"` im Katalog als Vorschlag.
Hinweis: Der in `bodenkampf.md` erneut genannte Wunsch „mitgelieferte Waffen editierbar“ ist vom Nutzer **zurückgenommen** (siehe Hinweis vom 16.10.2026 oben) – nicht bauen.

### Stand Modelle und Klänge im Editor (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`c1cecda`) geholt, ohne Konflikte.
- Editor: Modell aus `WeaponModels.all()` (Schusswaffen-Vorlagen nur Schusswaffen-Modelle, Nahkampf-Vorlagen nur Nahkampf-Modelle, dazu „ohne“); Auswahl ruft `WeaponModels.apply()` und übernimmt den vorgeschlagenen Klang (`"sound"`). Neue Zeile **Klang**: „automatisch (…)“ = `sound_id` leer, sonst ein Eintrag aus `WeaponData.SOUNDS`; Knopf ▶ spielt den Klang (`Sfx.play(w.sound())`). `Gear.models()` entfernt, neu `Gear.auto_sound(w)`.
- **Geänderte frühere Entscheidung:** eigene Nahkampfwaffen hatten „ohne Modell“ (damals gab es keine Nahkampfmodelle). Jetzt sind die Nahkampfmodelle des Katalogs wählbar, „ohne“ bleibt möglich.
- Tests: `test_rules` OK, `test_hub` OK (Katalog nach Art, Modell/Klang übernehmen und speichern, automatischer Klang), `--autotest-hub` durchgelaufen (Editor mit Revolver A, Klang Revolver). Den Klang selbst habe ich nicht gehört.

## Aufträge vom Koordinator (16.10.2026): freie EP alle 5 Tage

Entscheidungen des Nutzers: **alle 5 Spieltage** (Tag 5, 10, 15 …) bekommt **die ganze Crew an Bord** (auch Verletzte und Arzt) **3 freie EP**, damit auch Mitglieder ohne Einsätze steigern können. Zählung nach Spieltag (Neue ab dem nächsten 5er-Tag). Anzeige als **Zeile im Reisebericht** (z. B. „Training: +3 freie EP für alle“); beim „1 Tag warten“ bzw. Einsatz entsprechend sichtbar machen. Umsetzung in `HubState.advance_days()`; freie EP über das `Character`-Feld des Charakter-Moduls (keine Schnittstellenänderung erwartet, sonst abstimmen). Regel in `docs/Skillsystem.md` 8 nachtragen.

### Stand freie EP alle 5 Tage (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`cde5661`) geholt, ohne Konflikte.
- `HubState.advance_days()`: für jeden Tag 5, 10, 15 … im vergangenen Zeitraum bekommt jede Figur in `Campaign.crew()` `TRAINING_XP` (3) auf `Character.free_xp` (Feld des Charakter-Moduls, keine Schnittstellenänderung). `HubState.last_training` = vergebene EP je Figur beim letzten Tageswechsel; `HubState.training_days(von, bis)`.
- Anzeige: Zeile „Training: +3 freie EP für alle an Bord“ im **Reisebericht** und im **Einsatzbericht** (`rep.training`), Meldung oben beim **„1 Tag warten“** und bei der **großen Reparatur**. Regel in `docs/Skillsystem.md` 8.
- Tests: `test_rules` OK, `test_hub` OK (Zählung, ganze Crew inkl. Verwundete, zwei Trainingstage auf einmal, Reise- und Einsatzbericht), `--autotest-hub` durchgelaufen (Meldung bei der Crew-Reparatur an Tag 5 gesehen).

## Aufträge vom Koordinator (16.10.2026): Schiffsausbau, Lager, Handwerk

Grundlage: `docs/Planung_Ausbau_Lager_Handwerk.md` (Entscheidungen des Nutzers). Deine Schritte: **1. Schiffsausbau** (sofort), **2. Lager + Kauf/Verkauf** (Schnittstelle für Charakter und Bodenkampf unter „Schnittstellen“), danach **Beuteauswahl im Einsatzbericht** (wenn Bodenkampf geliefert hat) und **5. Handwerk**. Jeweils vorher Zahlen und Mockup mit dem Nutzer klären. Einzeln fertig melden (kleine Schritte).

### Stand Schritt 2 Lager und Handel (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- Entscheidungen des Nutzers: Preise wie Mockup (Bildschirme 24–25), Verkauf 50 %; **zufälliges Sortiment** (Hälfte der Waffen/Rüstungen je Hafen, alle 10 Tage neu, Medikits immer); eigene Ausrüstung kostet wie die Vorlage, „frei“ doppelt; neuer Reiter **„Handel …“** im Hafen. Regeln in `docs/Skillsystem.md` 8b.
- Gebaut: `Stock` (`core/stock.gd`), `TradeDialog` (`ui/trade_dialog.gd`), `HubState.stock` und `shop` im Spielstand, Munition verkaufen (`Voyage.sell_ammo`).
- **Schnittstelle Lager (für Charakter und Bodenkampf):**
  - Schlüssel eines Gegenstands: `Stock.key_of(res)` = `resource_path` der `WeaponData`/`ArmorData` (auch eigene aus `user://gear/`), Medikits: `Stock.MEDKIT`.
  - `Stock.count(HubState.game, key)`, `Stock.take(HubState.game, key, n := 1) -> bool` (Ausrüsten nimmt heraus), `Stock.add(HubState.game, key, n := 1)` (Ablegen legt zurück), `Stock.items(g)` (Liste fürs Anzeigen), `Stock.name_of(key)`.
  - Ohne Spiel (`HubState.game == null`, z. B. Schnellkampf aus dem Startmenü): `take()` gelingt immer, `count()` sehr groß – der Bestand ist dort unbegrenzt.
  - Lager zu Beginn leer; was die Crew trägt, zählt nicht. **Charakter:** Waffenkammer am Lager (Ausrüsten/Ablegen, Medikits). **Bodenkampf:** Beute nach dem Kampf über `Stock.add()` (Auswahl im Einsatzbericht baut der Hub, wenn `MissionResult` die Beute liefert).
- Tests: `test_rules` OK, `test_hub` OK (Preise, Sortiment halb/10 Tage, Kauf/Verkauf, Herausnehmen/Zurücklegen, ohne Spiel unbegrenzt, Munition verkaufen, eigene Ausrüstung, Spielstand), `--autotest-hub` durchgelaufen (Handel: Kauf und Verkauf, Screenshot).

### Stand Schritt 1 Schiffsausbau (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`0329915`) geholt, ohne Konflikte.
- Entscheidungen des Nutzers: Zahlen aus dem Mockup (Artifact „Schiff-Hub Mockup“, Bildschirme 22–23), Kosten **teurer**: Werft 600 / 1200 / 2200 Cr, Crew 3 / 6 / 9 Material bei 3 / 5 / 8 Tagen; **Hangar wird Maschinenraum**; **ein** Crew-Ausbau zur Zeit; Werkstatt-Ausbau erst mit dem Handwerk. Regeln in `docs/Skillsystem.md` 8b.
- Gebaut: `ShipUpgrades` (`core/ship_upgrades.gd`), `EngineDialog` (`ui/engine_dialog.gd`), Raum `&"hangar"` heißt „Maschinenraum“ und ist nutzbar. `HubState.upgrades`, `project`, `last_upgrade` (im Spielstand), Werte über `HubState.tank_max()`, `hull_max()`, `fuel_per_day()`, `travel_bonus()`, `heal_bonus()`, `training_xp()`; `Voyage.check(c, skill, extra)` mit Zusatzbonus; `Medbay.bonus()` mit Krankenstations-Ausbau. Meldungen des Crew-Ausbaus im Reise- und Einsatzbericht und beim Warten.
- **Für andere Module:** keine Schnittstellenänderung; `HubState.berths` steigt mit dem Ausbau (Crewquartiere zeigen ihn über `seats`).
- Tests: `test_rules` OK, `test_hub` OK (Stufe 0 = alte Werte, Werft nur im Hafen/mit Credits, Wirkungen aller Bereiche, Crew-Ausbau mit Material, Tagen, Probe und Sperre, Spielstand), `--autotest-hub` durchgelaufen (Maschinenraum: Werft-Kauf, Crew-Ausbau, Screenshot).

## Aufträge vom Koordinator (16.10.2026): Handelsfertigkeiten im Raumhafen

Entscheidungen des Nutzers. Die Fertigkeiten gibt es (`core/rules.gd`, Gruppe „Handel & Soziales“):
- **Handeln** (`handeln`): beeinflusst die Preise für alles, was Beute sein kann (Waffen, Rüstungen, Munition, Medikits …), Kauf und Verkauf.
- **Gassenwissen** (`gassenwissen`): erweitert das Sortiment des Hafens.
- **Verhandeln** (`verhandeln`): beeinflusst die Preise für alles, was das Schiff betrifft (Treibstoff, Werft/Reparatur, Schiffsmaterial, Schiffsausbau in der Werft).

Regeln: Wer würfelt, wird im Handelsdialog **ausgewählt**. Probe **pro Tag im Hafen** (Ergebnis gilt bis zum nächsten Tag; Warten kann ein neues bringen). **EP** wie bei den Reiseproben. Misserfolg = Normalpreis/-sortiment; **nur ein Patzer** verschlechtert (schlechtere Preise bzw. kleineres Sortiment). Zahlen (Rabatt je Ergebnisstufe, Sortimentsgröße) vorher dem Nutzer vorschlagen. Regeln in `docs/Skillsystem.md` 8b nachtragen. Kann parallel zu Schritt 3/4 der anderen Module gebaut werden.

### Stand Handelsfertigkeiten (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`2b40a18`) geholt, ohne Konflikte.
- Entscheidungen des Nutzers (Abweichung vom Auftrag): Staffel Patzer +20 %, **Fehlschlag +5 % (schlechter)**, Teilerfolg normal, Erfolg −10 %, Herausragend −20 % – gleich für Handeln und Verhandeln; Verkauf 30/45/50/60/70 %; Gassenwissen 30/50/60/75/90 %. **Ohne Probe gilt Fehlschlag** (sonst lässt man das Würfeln). Mockup Bildschirm 26. Regeln in `docs/Skillsystem.md` 8b.
- Gebaut: `TradeSkills` (`core/trade_skills.gd`), Proben im Handelsdialog (Figur wählen, „Würfeln“, Ergebnis), `HubState.trade_rolls` im Spielstand; alle Preise über Faktoren (`Stock.buy_price`, `sell_price(key, g)`, `Voyage.fuel_price/material_price/yard_cost/ammo_price/ammo_sell`, `ShipUpgrades.yard_cost`); Sortiment nach Gassenwissen (größer ergänzt nur).
- Keine Schnittstellenänderung für andere Module; `Stock.sell_price(key)` ohne Spiel = 50 %.
- Tests: `test_rules` OK, `test_hub` OK (alle fünf Stufen für Preise, Verkauf und Sortiment, ohne Probe = Fehlschlag, eine Probe pro Tag, EP, Verhandeln, Spielstand), `--autotest-hub` durchgelaufen (Probe Gassenwissen, Kauf/Verkauf mit +5 %, Screenshot).

### Auftrag (16.10.2026): Schild als Handelsgut

Charakter hat den Schild zum Lagergegenstand gemacht (Schlüssel `Equipment.SHIELD = "schild"`). `Stock.name_of`, `Stock.price`/`PRICES` und Sortiment (`goods`/`shop`) kennen den Schlüssel noch nicht. Aufnehmen, **Kaufpreis 150 Credits** (Entscheidung des Nutzers), Verkauf wie üblich über `TradeSkills`. Test in `test_hub` ergänzen.

#### Stand Schild als Handelsgut (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `Stock`: Schlüssel `Equipment.SHIELD` mit Name „Schild“, Kaufpreis **150 Cr** (`PRICES`), Teil von `goods()` und damit des zufälligen Sortiments (Anteil nach Gassenwissen, wie Waffen/Rüstungen). Verkauf und Kauf nach Handeln (`TradeSkills`), z. B. Verkauf 75 Cr bei Teilerfolg.
- Test: `_test_stock` prüft Preis, Name, Handelsgut, Preise nach Handeln, Kauf aus dem Sortiment und Verkauf.
- Doku: Preistabelle `docs/Skillsystem.md` 8b, `godot/README.md`.

### Auftrag (16.10.2026): Beuteauswahl, beschädigte Stücke im Lager, Reparatur

Bodenkampf meldet jetzt im `MissionResult` `loot` = [{key (`Stock.key_of`), name, damage 0/−10…−30}] plus Medikits [{key: `Stock.MEDKIT`, name, count}], je Figur `wear` {Platz "w0"/"w1"/"armor": Abzug} und `lost` [Platz]. Regeln: `docs/Skillsystem.md`, „Beute, Beschädigung und Verlust“. Entscheidungen des Nutzers:
- **Beuteauswahl im Einsatzbericht:** bis zu **N = 1 Stück je Crewmitglied im Einsatz**; Medikits zählen nicht (gehen alle ins Lager). Schild ist nie Beute.
- **Beschädigte Stücke liegen einzeln mit Schaden im Lager** (z. B. „Sturmgewehr (−20)“ als eigener Eintrag). Das Format im `Stock` legst du fest und vermerkst es in den Schnittstellen – Charakter wartet darauf (Waffenkammer wählt/legt beschädigte Stücke ab).
- **Reparatur**, alle drei Wege: (1) Crew mit Probe (Waffen/Rüstung herstellen) – gehört zum Handwerk (Schritt 5), hier nur vormerken; (2) **Werkstatt im Raumhafen** gegen Credits, sofort; (3) **beschädigt billiger verkaufen** (Preis sinkt je −10). Zahlen (Werkstattpreis, Abschlag) vorher mit dem Nutzer klären; Werkstattpreis über `TradeSkills` (Verhandeln) oder Handeln – mit dem Nutzer klären.
- Erst Mockup (Beuteauswahl), dann bauen.
- **Ergänzung (16.10.2026, Übergangslösung im Charakter-Modul):** Bis dein Lagerformat für beschädigte Stücke steht, geht ein beschädigtes Teil beim Wechsel in der Waffenkammer **heil** ins Lager (Ablegen/Anlegen repariert kostenlos; vom Nutzer so akzeptiert). Lagerformat deshalb vorrangig festlegen und in den Schnittstellen vermerken, damit Charakter den Teil „Danach“ bauen kann. Der Abzug je Teil steht in `Character.wear` {"w0"/"w1"/"armor": Abzug}.
- (16.10.2026) Nutzer bestätigt die Werte: Verkauf −25 % je −10, Werkstatt 10 % vom Kaufpreis je −10, Schrottwert 15 % (−30 = 0).

#### Stand Beuteauswahl, beschädigte Stücke, Reparatur (Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`9b0a333`) geholt, ohne Konflikte. Lagerformat zuerst festgelegt und gepusht (`f3fd11d`), Schnittstelle oben unter „Schnittstellen“.
- Entscheidungen des Nutzers (Mockup „Schiff-Hub Mockup“, Bildschirme 27–28, bestätigt): Werkstatt **10 % vom Kaufpreis je −10**, nach **Handeln**, nur ganz, **nur Lager**; Verkauf beschädigt **−25 % je −10**; Beute: **alle im Einsatz zählen**, nicht Mitgenommenes wird **als Schrott verkauft: 15 % vom Kaufpreis, −30 = 0 Cr** (Auslegung „15 % auch bei −10/−20“ im Mockup bestätigt). Regeln in `docs/Skillsystem.md`, „Beute, Beschädigung und Verlust“.
- Gebaut: `Stock` (Schlüssel mit Schaden, `sell_price`, `repair_cost/can_repair/repair`, `scrap_value`), `HubState.set_loot/loot_default/take_loot`, `loot_pending` im Spielstand; `finish_mission` legt Medikits ins Lager (`payout.medkits`) und öffnet die Auswahl; offene Auswahl wird vor neuer Beute mit Vorauswahl übernommen. Einsatzbericht mit Abschnitt „Beute auswählen“ (übernommen beim Schließen; nach dem Laden mit offener Beute eigener Dialog). Handelsdialog: Knopf „Reparieren … Cr“ bei beschädigten Stücken.
- Crew-Reparatur mit Probe: vorgemerkt für das Handwerk (Schritt 5).
- Tests: `test_rules` OK, `test_hub` OK (neu `_test_loot`: Format, Namen, Verkauf/Schrott/Werkstatt-Preise, Reparatur, nur im Hafen, Auswahl mit Platzgrenze, Spielstand, `finish_mission`), `test_sim -- 10` OK. `--autotest-hub` erweitert (Werkstatt, Beuteauswahl), aber **nicht ausgeführt** (Entscheidung des Nutzers: Grafik prüft er selbst); Hub-Szene lädt headless ohne Fehler.

#### Zwischenaufgabe des Nutzers (16.10.2026): Charakterbogen im Roster

- Im Roster (`ui/crew/roster_screen.gd`, **Datei des Charakter-Moduls**) neuer Knopf **„Charakterbogen“** in der Detailansicht: öffnet den `SheetDialog` für die gewählte Figur (nur diese, die Reiterzeile des Bogens passt nicht für den ganzen Roster); Esc schließt ihn. Bitte vom Charakter-Modul übernehmen.
- Tests: `test_rules` OK, `test_hub` OK, Knopf und Bogen headless geprüft; `--autotest-hub` um einen Screenshot `h0b2_roster_bogen` erweitert (nicht ausgeführt).


### Auftrag (16.10.2026): Handwerk (Schritt 5)

Grundlage: `docs/Planung_Ausbau_Lager_Handwerk.md`, Abschnitt „Handwerk – Entscheidungen des Nutzers (16.10.2026)“ (Material, Zerlegen, Bauen mit +5 bei Herausragend, Reparatur durch die Crew, Dauer, eine Arbeit je Handwerker, Werkstatt-Ausbau, Orte).
- **Erst** die offenen Punkte dort mit dem Nutzer klären (Werkstattstufen, Freischalten, Preis eines +5-Stücks), **dann Mockup**, dann bauen.
- **Schnittstelle +5 zuerst festlegen und vermerken:** Vorschlag Koordinator: Lagerschlüssel `"Grundschlüssel|+5"` (über `Stock.damaged_key` erweitert), an der Figur `Character.wear[platz] = 5` (positiver Wert = Bonus). Bodenkampf und Charakter warten darauf (siehe deren Moduldateien).
- Handwerksmaterial im Spielstand (`HubState`), Kauf im Raumhafen (1 = 10 Cr nach Handeln).

#### Stand Handwerk (Schritt 5, Hub-Chat, 16.10.2026) – **bereit zum Zusammenführen**

- `main` (`de18ce8`) geholt, ohne Konflikte. Schnittstelle +5 vorab gepusht (`8fdc92b`, oben unter „Schnittstellen“).
- Entscheidungen des Nutzers: Werkstatt-Ausbau „je Stufe eins“ (1: +10, 2: Dauer −50 %, 3: +20) mit Freischalten nach Kaufpreis (0: bis 200, 1: bis 400, 2: alles); +5-Stück Verkauf +50 %; Medikits mit dem Ausbau Krankenstation; Mockup „Schiff-Hub Mockup“ Bildschirme 29–31 bestätigt (Probe „mittel“, Material bei Bauen/Reparieren aufgerundet, beim Zerlegen abgerundet, Munition 30/30/1 je Auftrag); Zugang über eine Auswahl beim Raum Waffenkammer („Ausrüstung“ / „Werkstatt“), ohne Eingriff in den `ArmoryDialog`.
- Gebaut: `Crafting` (`core/crafting.gd`), `CraftDialog` (`ui/craft_dialog.gd`), Medikits in `MedbayDialog`, Handwerksmaterial im Raumhafen (`StarMap`), Bereich `&"workshop"` in `ShipUpgrades` (8 Bereiche), `HubState.craft_material`, `jobs`, `last_crafts` (Spielstand), Meldungen beim Warten und in Reise-/Einsatzbericht. Handwerker, der nicht mehr an Bord ist: Arbeit abgebrochen, Material und Stück zurück. Schild ist nicht baubar.
- Test-Hilfe: `Voyage.fixed_result` (fester Probenausgang, nur Tests). `core/skill_texts.gd`: Handwerksfertigkeiten nicht mehr „ohne Wirkung“.
- Tests: `test_rules` OK, `test_hub` OK (neu `_test_crafting`: Zahlen aus dem Mockup, Freischalten, Stufen, alle Ergebnisse für Bauen/Reparieren, Zerlegen, Munition, Medikit, Material kaufen/verkaufen, Spielstand, Abbruch), `test_sim -- 10` OK. Hub-Szene lädt headless ohne Fehler. `--autotest-hub` erweitert (Auswahl beim Raum Waffenkammer, Werkstatt Bauen/Reparieren).
- Nachtrag (Entscheidung des Nutzers): **Schwierigkeit nach Kaufpreis** beim Bauen und Reparieren von Waffen/Rüstungen: bis 200 Cr mittel, bis 400 schwer, bis 600 sehr schwer, darüber extrem (`Crafting.difficulty`); Zerlegen, Munition, Medikits mittel. `Voyage.check(c, skill, extra, diff_id)` hat dafür einen optionalen Parameter (Standard „mittel“). Werkstatt zeigt „+35 (schwer)“. Tests `test_rules`, `test_hub` OK.


### Auftrag (16.10.2026): Rückzug, Proviant, Kochen

Grundlage: `docs/Planung_Rueckzug_Proviant_Kochen.md` (Entscheidungen des Nutzers).
- **Rückzug:** eigener Ausgang im Einsatzbericht, Auftrag bleibt offen (bis Ablaufdatum). Wartet auf `MissionResult.retreated` vom Bodenkampf.
- **Proviant:** neue Ressource, Kauf 5 Cr im Raumhafen, 1 je Crewmitglied an Bord und Tag, im Raumhafen kein Verbrauch, ohne Proviant −10 auf alle Proben.
- **Kochen:** eine Probe je Tag außerhalb des Hafens, Koch wählbar, EP; Verbrauch Patzer +25 / Fehl 0 / Teil −10 / Erfolg −20 / Herausragend −30 %; Herausragend in den 5 Tagen → Training +1 freie EP.
- Offene Punkte aus der Planung erst mit dem Nutzer klären, dann Mockup, dann bauen. „Kochen“ in `core/skill_texts.gd` nicht mehr als „ohne Wirkung“.
- (16.10.2026) `MissionResult.retreated` ist in `main` – der Rückzug-Teil kann beginnen.
- (16.10.2026) **Hinweis:** Dieser Auftrag (Rückzug, Proviant, Kochen) wird ausnahmsweise vom **Charakter-Chat** gebaut (Entscheidung des Nutzers). Hub-Chat: nicht parallel daran arbeiten.
- (16.10.2026) **Gebaut vom Charakter-Chat** (Entscheidung des Nutzers), Branch `claude/elegant-gauss-hq5bus`, **bereit zum Zusammenführen**. Mockup „Frontire Kombüse und Proviant“ vom Nutzer bestätigt. Entscheidungen des Nutzers zu den offenen Punkten: **fester Koch, würfelt automatisch** jeden Tag außerhalb des Hafens (wie der Arzt); **ohne Koch = Fehlschlag**; Verbrauch **kaufmännisch gerundet, mindestens 1**; **Startvorrat 60**; −10 **nur auf Proben im Schiff** (nicht Bodenkampf); **neuer Raum „Kombüse“** (12 × 4 m neben der Brücke, Tür zur Krankenstation); Koch darf zugleich Arzt/Helfer/Handwerker sein (gesperrt Verwundete kochen nicht); Mangel: Rest aufbrauchen, dann −10, keine weiteren Folgen.
  - Neu: `core/galley.gd` (`Galley`: `need`, `malus`, `price/can_buy/buy`, `fill_amount`, `pass_day`, `training_bonus`, `bonus_pending`, `cook/set_cook`), `ui/galley_dialog.gd` (`GalleyDialog`: Koch wählen, Vorrat, Verbrauchstabelle, letzte Kochproben, Trainingshinweis, „1 Tag warten“). `HubState`: `provisions`, `cook`, `cooklog`, `last_cook` (im Spielstand; alte Spielstände bekommen 60 und keinen Koch); `advance_days(n, traveling)` – Reisetage zählen nie als Hafen, Training mit Kochbonus je Trainingstag.
  - Malus `Galley.malus(g)` in `Voyage.travel_day`, `Voyage.crew_repair`, `TradeSkills.roll`, `Crafting` (Arbeitsprobe), `ShipUpgrades` (Crew-Ausbau), `Medbay.pass_days`, Kochprobe.
  - Anzeige: Statusleiste „Proviant 48 · 6 je Tag“ bzw. „im Hafen kein Verbrauch“, Warnungen „knapp“ (< 3 Tage) und „leer“; Kauf auf der Sternenkarte, Reiter „Raumhafen“ (+10, +30, „bis 10 Tage“); Reisebericht mit Spalte „Kochen“, „Proviant x → y“, Koch-EP, Zeile „Proviant aufgebraucht an Tag …“; Einsatzbericht mit Proviant und Kochproben. `skill_texts.gd`: Kochen nicht mehr „ohne Wirkung“.
  - **Rückzug:** `HubState.finish_mission` liest `retreated` (aus dem Bericht oder `Campaign.last_result`, ohne Änderung am Bodenkampf): `rep.outcome = &"rueckzug"`, `rep.retreated`, `rep.expires`; kein Lohn, keine Beute; der Auftrag bleibt in `offers` mit `retry = true` (im Spielstand) und zählt nicht in `missions_done`. Einsatzbericht: Titel „Rückzug“, Hinweis in Violett (`UiTheme.RETREAT`); Sternenkarte: „erneuter Versuch“ am Auftrag.
  - Tests: `test_hub` neu `_test_galley` (Verbrauchsstufen, Hafen, ohne Koch, Koch mit EP, Trainingsbonus, Mangel/Malus, Koch nicht an Bord, Kauf, Reise auch mit Hafen als Ziel, Spielstand) und `_test_retreat`; `test_rules` OK; `test_sim -- 10` OK; `--autotest-hub` ohne Skriptfehler, neue Screenshots `h1h_kombuese`, `h9c_bericht_rueckzug`.
  - Hinweis: Der Ergebnis-Banner im Bodenkampf zeigt bei Rückzug weiter „Niederlage“ (Datei des Bodenkampfs, nicht geändert).

## Aufträge vom Koordinator (16.10.2026): Anbindung Raumkampf

Grundlage: `docs/Planung_Raumkampf.md`, `docs/Raumkampf.md`, Zuständigkeit in `docs/module/raumkampf.md` Auftrag 2 (Entscheidung Koordinator im Auftrag des Nutzers). **Noch nicht beginnen**, bis der Raumkampf-Chat die Schnittstelle (`SpaceSetup`, Ergebnis, Einstiegsfunktion) in `docs/module/raumkampf.md` unter „Schnittstellen“ festgelegt hat und sie in `main` ist.
- Der Hub baut: die vier Auslöser (Reiseereignis, eigene Auftragsart, Raumkampf vor einem Bodeneinsatz, Schnellkampf-Knopf im Startmenü), `SpaceSetup` aus `HubState`, Auswertung des Ergebnisses (Hülle auf `HubState.hull`, bleibende Systemschäden, Schiffsmunition, Flucht mit Treibstoff und offenem Auftrag, Kapitulation/Lösegeld, Beute, Einsatzbericht, Entern → Bodenkampf in der Lagerhalle, Notfall), neue `HubState`-Felder (Waffenslots, Schiffsmunition, Systemschäden, Posten „Station“ an Bord), `ShipUpgrades` „Schilde“ und „Panzerung“ (Stufe 0–3), Handel mit Schiffswaffen und Schiffsmunition im Hafen, Reparatur der Systemschäden (Schiffsmaterial + `rsReparatur` oder Werft).
- Keine Dateien des Raumkampfs ändern; fehlt etwas an der Schnittstelle, in `docs/module/raumkampf.md` vermerken lassen (über den Nutzer).
- Offene Punkte (Preise, Reiseereignis-Häufigkeit, Posten-Bedienung) erst mit dem Nutzer klären, größere UI erst als Mockup.
- (16.10.2026) **Schnittstelle in `main`** (`docs/module/raumkampf.md` „Schnittstellen“, Raumkampf `8a0597f`): Einstieg `SpaceBattle.start(tree, setup)`, Rückweg über `setup.return_scene` (Raumkampf ruft selbst `Campaign.finish_mission(result)`), Ergebnis `SpaceBattle.take_result()`, Schnellkampf `SpaceSetup.quick()`, Startwerte `SpaceSetup.START_SLOTS`/`START_AMMO`, Waffenkatalog `ShipWeapons`. `ShipUpgrades` neu: `shields`, `armor`, `reactor`, `slots`. **Der Hub kann beginnen.** Der Code des Raumkampfs ist noch nicht in `main`; bis dahin gegen die Beschreibung bauen bzw. mit dem Nutzer abstimmen, ob der Hub zuerst die Teile ohne Aufruf des Raumkampfs baut (Felder, Ausbau, Handel, Reparatur). Zahlenwerte legt der Raumkampf später per Simulation fest.
