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

- Alle Aufträge bis 16.10.2026 erledigt und in `main`. Verlauf im Archiv (siehe oben), Zusammenführungen in `docs/Zusammenfuehrung.md`.
- Neue Fertigmeldungen hier kurz eintragen (Commit, was neu, Schnittstellenänderungen). Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.

## Aufträge vom Koordinator

### Anbindung Raumkampf (16.10.2026)

Grundlage: `docs/Planung_Raumkampf.md`, `docs/Raumkampf.md`, Zuständigkeit in `docs/module/raumkampf.md` Auftrag 2 (Entscheidung Koordinator im Auftrag des Nutzers). **Noch nicht beginnen**, bis der Raumkampf-Chat die Schnittstelle (`SpaceSetup`, Ergebnis, Einstiegsfunktion) in `docs/module/raumkampf.md` unter „Schnittstellen“ festgelegt hat und sie in `main` ist.
- Der Hub baut: die vier Auslöser (Reiseereignis, eigene Auftragsart, Raumkampf vor einem Bodeneinsatz, Schnellkampf-Knopf im Startmenü), `SpaceSetup` aus `HubState`, Auswertung des Ergebnisses (Hülle auf `HubState.hull`, bleibende Systemschäden, Schiffsmunition, Flucht mit Treibstoff und offenem Auftrag, Kapitulation/Lösegeld, Beute, Einsatzbericht, Entern → Bodenkampf in der Lagerhalle, Notfall), neue `HubState`-Felder (Waffenslots, Schiffsmunition, Systemschäden, Posten „Station“ an Bord), `ShipUpgrades` „Schilde“ und „Panzerung“ (Stufe 0–3), Handel mit Schiffswaffen und Schiffsmunition im Hafen, Reparatur der Systemschäden (Schiffsmaterial + `rsReparatur` oder Werft).
- Keine Dateien des Raumkampfs ändern; fehlt etwas an der Schnittstelle, in `docs/module/raumkampf.md` vermerken lassen (über den Nutzer).
- Offene Punkte (Preise, Reiseereignis-Häufigkeit, Posten-Bedienung) erst mit dem Nutzer klären, größere UI erst als Mockup.
- (16.10.2026) **Schnittstelle in `main`** (`docs/module/raumkampf.md` „Schnittstellen“, Raumkampf `8a0597f`): Einstieg `SpaceBattle.start(tree, setup)`, Rückweg über `setup.return_scene` (Raumkampf ruft selbst `Campaign.finish_mission(result)`), Ergebnis `SpaceBattle.take_result()`, Schnellkampf `SpaceSetup.quick()`, Startwerte `SpaceSetup.START_SLOTS`/`START_AMMO`, Waffenkatalog `ShipWeapons`. `ShipUpgrades` neu: `shields`, `armor`, `reactor`, `slots`. **Der Hub kann beginnen.** Der Code des Raumkampfs ist noch nicht in `main`; bis dahin gegen die Beschreibung bauen bzw. mit dem Nutzer abstimmen, ob der Hub zuerst die Teile ohne Aufruf des Raumkampfs baut (Felder, Ausbau, Handel, Reparatur). Zahlenwerte legt der Raumkampf später per Simulation fest.
