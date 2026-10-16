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

- Bis 16.10.2026 alles in `main`, zuletzt **Anbindung Raumkampf Teil 1** (`bd2f56f`): `ShipArms` (`core/ship_arms.gd`, Übergangskatalog bis `ShipWeapons` da ist, Waffenslots, Schiffswaffen-Lager `HubState.ship_stock`, Geschützposten `gun_posts`, Systemschäden A–E mit Wirkung auf Reiseproben, Reparatur Crew/Werft, Handel „Schiff“, `ShipArms.setup(g, enemy, source, mission, return_scene)` als Eingang für `SpaceBattle.start()`), `ShipUpgrades` mit `shields`, `armor`, `reactor`, `slots`, `ShipArmsDialog` im Maschinenraum. Entscheidungen und Details im Archiv (Nachtrag am Ende).
- Neue Fertigmeldungen hier kurz eintragen (Commit, was neu, Schnittstellenänderungen). Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.

## Aufträge vom Koordinator

### Anbindung Raumkampf, Teil 2 (offen)

Erst beginnen, wenn der Code des Raumkampfs (`SpaceBattle`, `SpaceSetup`, `ShipWeapons`) in `main` ist. Schnittstelle: `docs/module/raumkampf.md` „Schnittstellen“. Zuständigkeit: Raumkampf eigene Dateien, Hub alles in Hub-Dateien.
- Vier Auslöser: Reiseereignis (Häufigkeit klären), eigene Auftragsart, Raumkampf vor einem Bodeneinsatz, Schnellkampf-Knopf im Startmenü (`SpaceSetup.quick()`).
- Auswertung über `SpaceBattle.take_result()`: Hülle, Systemschäden, Slots, Schiffsmunition, Treibstoff, Flucht (Auftrag bleibt offen), Kapitulation/Lösegeld, Beute ins Lager, Einsatzbericht. **Nicht** selbst `Campaign.finish_mission()` aufrufen (macht der Raumkampf).
- Entern → Bodenkampf in der Lagerhalle; **Notfall-Regel** ist noch nirgends festgelegt (mit dem Nutzer klären).
- Übergangskatalog in `ShipArms` entfernen bzw. nur noch `ShipWeapons` lesen, sobald es ihn gibt.

## Fertigmeldung Raumhafen in eigenen Fenstern (Hub-Chat, 16.10.2026)

Auslöser: Spieltest des Nutzers (Raumhafen-Spalte in der Sternenkarte schnitt rechts ab). Entscheidungen des Nutzers (Auswahl-Buttons, Mockup „Schiff-Hub Mockup“ Bildschirme 36–39 bestätigt):
- Im Hafen rechts in der Sternenkarte (= Navigation mit Aufträgen) **vier Knöpfe**, jeder öffnet ein eigenes Fenster: **Schiffshändler** (Treibstoff, Schiffsmaterial, **Proviant**, Schiffsmunition, Schiffswaffen; Proben Verhandeln + Gassenwissen), **Händler** (Ausrüstung der Crew, Lager, Werkstatt, Bodenmunition, Handwerksmaterial; Proben Handeln + Gassenwissen), **Werft** (große Reparatur, Ausbau gegen Credits, Systemschäden und Waffen reparieren, Schiffswaffen einbauen), **Crew anheuern**.
- **Maschinenraum nur noch Crew-Arbeit** (Crew-Ausbau, Crew-Reparatur, Geschützposten, Anzeige der Slots); alles gegen Credits nur in der Werft.
- **Proviant nach Verhandeln** (vorher Handeln).
- Gebaut: `PortDialog` (`ui/port_dialog.gd`: Schiffshändler, Crew anheuern), `TradeDialog` = Händler (`TradeDialog.skill_row()` statisch, auch im Schiffshändler), `ShipArmsDialog.show_yard()` = Werft, `EngineDialog` ohne Werft-Spalte, `StarMap` mit Signal `port(kind)` statt `trade`/`bought`/`hired` (Raumhafen-Reiter und Anheuern-Liste entfernt), `Galley.price` nach Verhandeln. Keine Schnittstellenänderung für andere Module.
- Tests: `test_rules` OK, `test_hub` OK, `test_sim -- 10` OK (0 hängengeblieben), `--autotest-hub` durchgelaufen (neue Screenshots `h1a1_schiffshaendler`, `h1f3_werft`; „Button nicht gefunden: Fertig“ kommt auch in `main` vor, nicht von dieser Änderung).
- Nachtrag (Wunsch des Nutzers, Mockup Bildschirm 40 bestätigt): **Werft mit drei Reitern** „Reparatur“ (Hülle, Systemschäden, beschädigte Schiffswaffen) | „Ausbau“ | „Waffenslots“; der zuletzt gewählte Reiter bleibt beim nächsten Öffnen. Tests: `test_rules`, `test_hub` OK, `--autotest-hub` durchgelaufen (Screenshots `h1f3_werft`, `h1f4_werft_ausbau`, `h1f5_werft_waffenslots`).
- Nachtrag (Wunsch des Nutzers): Startmenü-Block (Titel, Untertitel, Menü) nach links oben (`_menu.position` 60/40 statt 140/200), damit der Hinweis unter „Beenden“ bei 900 px Höhe nicht abgeschnitten wird. Screenshot `h10_start_mit_spielstand` geprüft.
