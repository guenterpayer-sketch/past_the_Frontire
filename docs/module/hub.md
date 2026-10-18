# Modul Hub (Startmenü, Schiff, Sternenkarte, Spielstände)

- **Branch:** `claude/happy-lamport-u4fvya`
- **Zuständig für:** `godot/start.tscn`, `godot/hub.tscn`, `godot/core/hub_state.gd`, `sector.gd`, `save_slots.gd`, `godot/view/hub.gd`, `ship_view.gd`, `start_screen.gd`, `godot/ui/hub_ui.gd`, `star_map.gd`, `slots_dialog.gd`, `godot/assets/ship/`.
> Erledigte Aufträge und alter Stand bis 16.10.2026: `docs/module/archiv/hub_bis_2026-10-16.md` (nur bei Bedarf lesen).


## Schnittstellen (laut Branch, Commit `7657fed`)

- Startet den Bodenkampf mit einer Mission von der Sternenkarte (`HubState.active_mission()`, `Mission.generate(…, faction_path)`), bekommt einen Einsatzbericht zurück (`HubState.game.finish_mission(…)`).
- Spielstände: 3 Slots, kopieren u. a. `user://crew.json`.
- **Lagerformat für beschädigte Stücke** (16.10.2026, `core/stock.gd`): Jedes beschädigte Stück liegt in `HubState.stock` unter einem eigenen Schlüssel **„Grundschlüssel|Schaden“**, z. B. `"res://data/weapons/sturmgewehr.tres|-20"` → Anzahl. Schaden −10/−20/−30 wie `Character.wear`/`Combatant.wear` (−30 = unbrauchbar). Gleicher Gegenstand mit gleichem Schaden wird gezählt (×2), jeder andere Schaden ist ein eigener Eintrag. Intakte Stücke behalten den Grundschlüssel (`Stock.key_of(r)`) wie bisher. Schild und Medikits sind nie beschädigt.
  - Bauen/Zerlegen: `Stock.damaged_key(key, damage)` (0 → Grundschlüssel, höchstens −30), `Stock.base_of(key)`, `Stock.damage_of(key)` (0 = intakt), `Stock.damage_steps(key)`, `Stock.damage_text(damage)` (" (−20)", " (−30, unbrauchbar)").
  - `Stock.count/take/add(g, key, n)` arbeiten unverändert mit diesen Schlüsseln; `Stock.items(g)` liefert zusätzlich `damage`; `Stock.name_of(key)` hängt den Schaden an („Sturmgewehr (−20)“); `Stock.price(key)` = Kaufpreis des intakten Stücks.
  - **Für die Waffenkammer (Charakter):** Anlegen eines beschädigten Stücks = `Stock.take(g, key)` und `ch.wear[platz] = Stock.damage_of(key)`; Ablegen = `Stock.add(g, Stock.damaged_key(Stock.key_of(r), int(ch.wear.get(platz, 0))))` und `ch.wear.erase(platz)`. Ein beschädigtes Stück lädt man über `load(Stock.base_of(key))`. `Equipment.in_stock`/`count` mit `Stock.key_of(r)` zählt nur intakte Stücke.
  - **Gute Stücke (+5) aus dem Handwerk** (16.10.2026, gilt so): im Lager unter **`"Grundschlüssel|+5"`** (`Stock.damaged_key(key, 5)`; jeder positive Wert ergibt `|+5`), an der Figur **`Character.wear[platz] = 5`** (`Stock.BONUS`; positiver Wert = Bonus: Waffe +5 auf Angriffe, Rüstung +5 auf die Verteidigung). `Stock.damage_of(key)` liefert dann `5`, `Stock.is_fine(key)` = true, `Stock.name_of` „Sturmgewehr (+5)“, `Stock.damage_text(5)` = " (+5)". Anlegen/Ablegen genau wie bei beschädigten Stücken (der `wear`-Wert des Platzes geht mit). **Der erste Schaden nimmt den Bonus:** +5 → 0 → −10 → … (Bodenkampf: `Combatant.add_wear` setzt einen positiven Wert auf 0). Beute ist nie +5. Verkauf: Verkaufspreis × 1,5 (`Stock.SELL_BONUS`); Werkstatt: nichts zu reparieren.
  - Preise: Verkauf `Stock.sell_price(key, g)` je −10 um 25 % weniger; Werkstatt im Raumhafen `Stock.repair_cost(g, key)` (10 % vom Kaufpreis je −10, nach Handeln), `Stock.can_repair/repair(g, key)` (ganz, nur Lager); Schrottwert `Stock.scrap_value(key)` (15 %, −30 = 0).

## Gültige Absprachen

- Standardwaffen und -rüstungen bleiben feste Vorlagen (im Ausrüstungs-Editor nicht editierbar, Entscheidung des Nutzers).

### Klärung Hub ⇄ Charakter (`docs/Planung_Roster_Verwundung.md`, Abschnitt D)

- **Neues Spiel:** Der Hub ruft den **`CrewPicker` des Charakter-Moduls** auf (1 bis 8 Figuren) und baut keine eigene Auswahl. Mockup-Bildschirm „6 Neues Spiel“ entfällt.
- **Roster im Startmenü:** Punkt „Roster“ → `Campaign.ROSTER_SCENE`.
- **Anheuern:** nur im Hafen (neutrale Systeme) auf der Brücke, bei freiem Platz; Funktion `Campaign.hire()` vom Charakter-Modul, Hafen-Bedingung und UI vom Hub.
- **Entlassen:** Liste „im Hafen“ gehört zu `Campaign` (mit der Crew gespeichert); der Hub zeigt sie im Hafen an. Entlassen-Knopf in den Crewquartieren (Charakter-Modul).
- **Einsatztrupp:** wählt der **Bodenkampf im Briefing** (auch beim Schnellkampf), Ergebnis `Campaign.chosen_squad`; der Hub liefert die Arzt-Zuweisung (Arzt gesperrt).
- **Offen:** Im Hub-Chat hatte der Nutzer für den Schnellkampf „6 aus dem Roster wählen“ entschieden; Abschnitt D sagt nur „Truppwahl im Briefing auch beim Schnellkampf“. Woher die Figuren beim Schnellkampf kommen (Roster oder Crew des Spielstands), ist damit noch nicht eindeutig.

## Stand

- Bis 16.10.2026 alles in `main`, zuletzt **Anbindung Raumkampf Teil 1** (`bd2f56f`): `ShipArms` (`core/ship_arms.gd`, Übergangskatalog bis `ShipWeapons` da ist, Waffenslots, Schiffswaffen-Lager `HubState.ship_stock`, Geschützposten `gun_posts`, Systemschäden A–E mit Wirkung auf Reiseproben, Reparatur Crew/Werft, Handel „Schiff“, `ShipArms.setup(g, enemy, source, mission, return_scene)` als Eingang für `SpaceBattle.start()`), `ShipUpgrades` mit `shields`, `armor`, `reactor`, `slots`, `ShipArmsDialog` im Maschinenraum. Danach (`6dd6178`): Raumhafen in eigenen Fenstern (Sternenkarte im Hafen: Schiffshändler, Händler, Werft mit Reitern Reparatur/Ausbau/Waffenslots, Crew anheuern; `PortDialog`, `ShipArmsDialog.show_yard()`), Maschinenraum nur Crew-Arbeit, Proviant nach Verhandeln. Danach (`0bb6c64`): Startmenü-Block links oben, ein Farbschema für alle Probenergebnisse (`HubUI.result_color`), Erfahrung je Figur eine Zeile (`HubUI.xp_list`, auch EP aus Handwerk/Ausbau; `Crafting.work_day`/`ShipUpgrades.work_day` liefern Einträge `{text, result, name, skill, xp}`). Entscheidungen und Details im Archiv (Nachträge am Ende).
- Danach (`5772000`, mit Raumkampf `f0334fd` in `main`): Übergangskatalog entfernt, `ShipArms` liest nur `ShipWeapons`/`SpaceSetup`; Waffenslots 0–5 (+`backbord2`/`steuerbord2`, `ShipUpgrades.max_level(id)`), Posten `technik_2`/`technik_3`, selbst entern (`HubState.book_board`, `board_pending`, `start_boarding()`, `board_loot` nur bei Sieg), Startmenü-Knopf „Schnellkampf im All“. Details im Archiv.
- Danach (`2876f93`): **Raumkampf im Spiel (Teil 2)** – `SpaceEvents` (`core/space_events.gd`), Feindkontakt auf der Reise (5 %/20 % je Tag nach Gebiet, kämpfen oder ausweichen per Navigation), Auftragsarten Boden (25 % mit Blockade)/Abfangen/Eskorte, `HubState.finish_space(result)` als Auswertung, Notfall = Plünderung + Treiben („festgesetzt“), Abwehr beim Entern. Details und Entscheidungen im Archiv. Szenenwechsel Schiff → `space.tscn` → Schiff im laufenden Spiel vom Nutzer getestet (17.10.2026): funktioniert.
- Neue Fertigmeldungen hier kurz eintragen (Commit, was neu, Schnittstellenänderungen). Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.

- Danach (`4b16e4e`): Crew-Reparatur des Schiffs als Arbeit wie Handwerk (`ShipArms.start_fix/finish_fix`, Arbeit in `HubState.jobs`, eine Arbeit je Figur für Handwerk und Reparatur, Figur im Maschinenraum wählbar); `HubState.ship_fix()` entfällt.
- Danach: Ausbau `armor` heißt jetzt **„Schiffspanzerung“** (Wahl des Nutzers 18.10.2026; vorher „Panzerung“ wie die Fertigkeit). Nur der Name in `ShipUpgrades.AREAS` und in der Doku; ID `armor` und Schnittstelle `levels.armor` unverändert. Dateien des Raumkampfs nicht geändert (dort wird der Ausbau-Name nicht angezeigt).
- Danach: **abgewehrtes Entern = Sieg** (Entscheidungen des Nutzers 18.10.2026). `finish_space` merkt bei `boarding` Auftragsart, Auftrag, `board_ship` und `board_loot` in `active` vor; `finish_mission` bucht bei gewonnener Abwehr `board_loot` und die Beuteauswahl aus dem Bodenkampf (`set_loot`, auch nach selbst Entern) und führt den Auftrag weiter (`_defend_won`: Abfangen Lohn, Eskorte `travel_rest.won`, Blockade `blockade_done` + `pending_offer` → Bodeneinsatz gleich danach über die Truppwahl, ohne Tag). Verloren/abgebrochen = Notfall, Auftrag weg. Berichte: „Sieg (Entern abgewehrt)“, Raumkampf-Bericht „Gegner entern“ statt „Niederlage – Entern“. Keine Dateien des Raumkampfs geändert.
- Danach: **Hüllenreparatur als Arbeit** (Knopf „Große Reparatur“ in der Sternenkarte, `HubState.crew_repair()` und `Voyage.crew_repair` entfallen): `ShipArms.HULL_TARGET`, `hull_day`, `stop_fix`, Zeile „Hülle“ im Maschinenraum mit „Beenden“; `Crafting.work_day(g, traveling)` pausiert sie an Reisetagen. **Schwer Verwundete arbeiten nicht**: `Crafting.can_work`/`status_text`, Auswahl ausgegraut mit Grund (Werkstatt, Medikits, Reparatur), laufende Arbeit pausiert; Schiffsreparatur sperrt nur noch schwer Verwundete; `Voyage.repairer` (Probe Crew-Ausbau) ebenso. Dazu: Händler und Schiffshändler laufen bei langer Liste nicht mehr rechts über (Namen brechen um; Screenshot des Nutzers).

## Aufträge vom Koordinator

- Keine offenen Aufträge. Nächste Aufgabe kommt vom Nutzer.
