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

### Klärung Hub ⇄ Charakter (`docs/archiv/Planung_Roster_Verwundung.md`, Abschnitt D)

- **Neues Spiel:** Der Hub ruft den **`CrewPicker` des Charakter-Moduls** auf (1 bis 8 Figuren) und baut keine eigene Auswahl. Mockup-Bildschirm „6 Neues Spiel“ entfällt.
- **Roster im Startmenü:** Punkt „Roster“ → `Campaign.ROSTER_SCENE`.
- **Anheuern:** nur im Hafen (neutrale Systeme) auf der Brücke, bei freiem Platz; Funktion `Campaign.hire()` vom Charakter-Modul, Hafen-Bedingung und UI vom Hub.
- **Entlassen:** Liste „im Hafen“ gehört zu `Campaign` (mit der Crew gespeichert); der Hub zeigt sie im Hafen an. Entlassen-Knopf in den Crewquartieren (Charakter-Modul).
- **Einsatztrupp:** wählt der **Bodenkampf im Briefing** (auch beim Schnellkampf), Ergebnis `Campaign.chosen_squad`; der Hub liefert die Arzt-Zuweisung (Arzt gesperrt).
- **Offen:** Im Hub-Chat hatte der Nutzer für den Schnellkampf „6 aus dem Roster wählen“ entschieden; Abschnitt D sagt nur „Truppwahl im Briefing auch beim Schnellkampf“. Woher die Figuren beim Schnellkampf kommen (Roster oder Crew des Spielstands), ist damit noch nicht eindeutig.

## Stand

- Alles in `main` (20.10.2026, Auftrag 9 mit Version 0.4), keine offenen Aufträge. Verlauf: `docs/module/archiv/hub_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
  1. **Ursache nachgestellt:** Nach einem gewonnenen Kampf auf der Reise liefen beim Schließen des Einsatzberichts zwei verzögerte Aufrufe: zuerst `_next_story` (kein Fenster offen → Szenenfenster auf), danach `_continue_journey` (Reisebericht, `move_to_front`). Das Szenenfenster lag damit unter dem Reisebericht und war nicht antippbar (Screenshot im Selbsttest bestätigt). **Abhilfe:** `_next_story` prüft erst im nächsten Bild; gesperrt, solange irgendein Fenster offen ist (`HubUI.any_dialog_open(true)`, prüft jetzt alle `Modal`-Kinder; die Sternenkarte zählt nicht, über ihr dürfen Szenen erscheinen); jedes sich schließende Fenster stößt die Prüfung neu an. **Nicht nachgestellt:** Laut Nutzer lag das Szenenfenster oben und nichts reagierte (auch nicht die Zurück-Taste). Ein Nachspielen mit echten Touch-Ereignissen (Entern gewonnen → Banner → Bericht mit Beuteauswahl → Szenenfenster → Wahl antippen) löste den Knopf aus; die Ursache am Tablet ist offen. Zusätzlich (Wahl des Nutzers): offenes Szenenfenster holt sich nach jedem geschlossenen Fenster wieder nach oben (außer Logbuch/Enzyklopädie aus der Szene); Esc/Android-Zurück pausiert die Szene, wieder öffnen über Sternenkarte → STORY „Fortsetzen“ (laufende Ketten aus `Story.open_chains()`). Selbsttest des Hubs heißt jetzt `--autotest-hub-touch` (`--autotest-touch` gehört dem Bodenkampf; beide Selbsttests sprangen sonst beim Bodenkampf an).
  2. **Auto-Spielstand** (`SaveSlots.AUTO` = 0, Datei `auto.json`): überschrieben nach Bodenkampf (Bericht), Raumkampf (wenn kein Bodenkampf folgt), jeder Reise (auch Fortsetzung) und jedem abgeschlossenen Story-Fenster (`SaveSlots.autosave(g)`). Slot und Name des Spiels bleiben; Laden führt danach im eigenen Slot weiter (`from_slot`). Spielstandliste beim Laden oben „A · Automatisch · Name“ mit Version. `SaveSlots.latest()` liefert jetzt −1 für keinen und kennt den Auto-Spielstand („Fortsetzen … (automatisch)“; bei gleicher Zeit gewinnt der Slot des Nutzers).
- Danach: **Auftrag 9, Handel an Stationen** (Entscheidung des Nutzers 20.10.2026). Neue Prüfung `HubState.at_market()` (Hafen oder Station im System des Schiffs), `station_name()`, `market_title()`. Umgestellt von `is_harbor` auf `at_market`: `Stock.can_buy/can_sell/can_repair`, `ShipArms.can_buy/can_sell/can_buy_ammo/can_sell_ammo`, `TradeSkills.can_roll`, `Galley.can_buy`, `Crafting.can_buy_material/can_sell_material`, `Voyage.buy_fuel/can_buy_material/can_buy_ammo/can_sell_ammo`. Nur im Hafen bleiben Werft (`Voyage.can_yard_repair`, `ShipArms` Ein-/Ausbau und Werft-Reparatur, `ShipUpgrades.can_yard`), Anheuern und Papiere. Preise an Stationen außerhalb eines Hafens ×1,2 wie bisher (`TradeSkills.station_factor`). Fenstertitel „<Station>: Händler“ bzw. „…: Schiffshändler“ statt „Raumhafen …“. Fraktionsruf wirkt noch nicht auf den Handel.
- Danach (`efa8a0b`, Fehler aus Auftrag 8, Screenshot des Nutzers): „Parameter data.tree is null“ in `_next_story`. Ursache: „Weiter“ im Reisebericht vor einem Einsatz wechselt per `change_scene_to_file` die Szene (der Hub ist sofort aus dem Baum), danach ruft der allgemeine Fenster-Handler noch `_next_story` → `get_tree()` = null. Abhilfe: `_next_story` und `_story_to_front` prüfen `is_inside_tree()` vor dem Warten. Nachgestellt und geprüft (ohne Abhilfe genau der Fehler, mit Abhilfe sauberer Wechsel in den Bodenkampf).
- Danach: **Auftrag 10, Elite/Boss, Schwierigkeitsgrad** (Entscheidungen des Nutzers 24.10.2026). Neue Klasse **`Elite`** (`core/elite.gd`): `Elite.roll(seed)` ≈ 13 % (fest je Seed, gemeinsam für Aufträge und Feindkontakt), Stufe als Text `""`/`"elite"`/`"boss"`, `Elite.label()` („★ Elite“/„★ Boss“), `Elite.boss_name(seed)`, Schwierigkeitsgrad `Elite.LEVELS` (leicht 0,8 / normal 1,0 / schwer 1,25).
  - Aufträge (`offers[].elite`, im Spielstand): Elite-Wurf beim Erstellen; Bodenaufträge ohne Blockade mit 10 % als **Kopfgeld** (`offers[].bounty` = Name, Stufe `boss`, Titel „Kopfgeld: <Name> beseitigen“, Wahl des Nutzers: Hub-Auftragsart). Anzeige „★ ELITE“/„★ BOSS“ in der Auftragskarte. Feindkontakt (`contact.elite`; bei Eskorte die Stufe des Auftrags) mit Zeile „★ Elite …“, Ausweichen bleibt.
  - Raum: `space_setup()` gibt `enemy.elite`, `enemy.boss`, `enemy.boss_name` und `difficulty_factor` weiter (Abfangen, Blockade, Feindkontakt, Eskorte, Story über `mission.elite`/`boss_name`). Entern/Abwehr übernehmen die Stufe des Raumkampfs für den Bodenkampf.
  - Boden: `HubState.mission_of` erzeugt über `Elite.generate(seed, diff, faction, factor)` – nimmt `Mission.generate` einen 4. Parameter an, geht der Faktor dorthin, sonst in ein Feld `difficulty_factor`, falls vorhanden; `Elite.apply(m, stufe)` setzt `Mission.elite`, **sobald der Bodenkampf das Feld hat**. **An den Bodenkampf:** `Mission.elite: StringName` und Schwierigkeitsfaktor als 4. Parameter von `Mission.generate` (oder Feld `difficulty_factor`) einbauen; der Hub ruft beides schon (heute ohne Wirkung am Boden). Kopfgeld-Aufträge haben heute noch normale Gegner.
  - Schwierigkeitsgrad: Wahl beim neuen Spiel (Slot-Dialog, Standard normal), im Spielstand (`difficulty_level`), im Schiff unter Burgermenü → Einstellungen änderbar (Wahl des Nutzers).
  - Elite-Beute: `MissionResult.loot`-Einträge mit `elite: true` kommen wie andere Beute in die Auswahl („★ Elite“) und ins Lager, verkaufbar; Elite-Ausrüstung (`/elite/` im Pfad oder Feld `elite`) nie im Sortiment (`Stock.is_elite`). Kommt sie als Standardwaffe mit `elite: true`, geht die Elite-Eigenschaft im Lager verloren – **an den Bodenkampf:** Elite-Ausrüstung als eigene Einträge liefern.
  - **An den Story-Chat:** Boss am Kettenende über `mission.elite = "boss"` (und `boss_name` für den Raum) im Story-Einsatz setzen; der Hub reicht es weiter.

## Aufträge vom Koordinator

### Auftrag 10 (24.10.2026): Elite und Boss in Aufträgen und Feindkontakt – erst nach Schnittstelle Boden

Gemeinsame Elite-Regeln stehen in `docs/module/bodenkampf.md` und `docs/module/raumkampf.md` (Abschnitt „Elite-Gegner“). Ergänzt vom Nutzer am 24.10.2026:
- **Boss-Kampf:** Boss + 2 Leibwächter + Fußvolk (Form „Anführer“ aus dem Bodenkampf-Vorschlag), Siegquote wie Elite (70–75 %). Kommt vor (a) am Ende jeder Story-Kette (je nach Kette am Boden **oder** im Raum mit Boss-Schiff) und (b) bei Hub-Aufträgen, deren Ziel eine Person ist (z. B. „Beseitigt den Gangsterboss“).
- **Beute bei Elite und Boss:** selten (nicht bei jedem Kampf), dann höchstens 2–3 Stück der besseren Ausrüstung, gern stark beschädigt. Boden: Waffen/Rüstungen. Raum: ab und zu eine beschädigte Schiffswaffe.
- **Elite-Wurf** beim Hub (beim Erstellen von Auftrag/Feindkontakt, ca. 13 %), Anzeige „Elite“ bzw. „Boss“ im Angebot.

1. Raum ist fertig: `setup.enemy.elite: bool`, `setup.enemy.boss: bool`, `setup.enemy.boss_name: String` (Boss gilt als Elite; Raumkampf, in `main`). `board_loot` hat jetzt höchstens eine Waffe. Boden folgt (Bodenkampf schlägt `elite`/`form` vor).
2. Beim Erstellen von Auftrag und Feindkontakt Elite würfeln (ca. 13 %, eine gemeinsame Funktion), „★ Elite“ im Angebot/Kontakt zeigen (Ausweichen möglich), an Boden/Raum weitergeben.
3. Aufträge mit einer Person als Ziel („Gangsterboss beseitigen“ u. ä.) erzeugen einen Boss-Kampf (Boss + 2 Leibwächter + Fußvolk) und zeigen „Boss“.
4. Elite-/Boss-Beute aus dem Ergebnis ins Lager übernehmen (wie bisher Beute).
5. **Erst anfangen, wenn der Koordinator die Boden-Schnittstelle einträgt.**

### Auftrag 10 – Ergänzung (24.10.2026): Schnittstelle Boden steht, jetzt bauen

**Schnittstellen bestätigt (Koordinator mit Nutzer, 24.10.2026):**
- Mission-Feld `elite: StringName` = `""` | `&"elite"` | `&"boss"` (Form Trupp/Kern/Boss wählt der Bodenkampf). Raum: `setup.enemy.elite`/`boss`/`boss_name` (schon in `main`).
- Spieleinstellung **„Schwierigkeitsgrad“** leicht ×0,8 / normal ×1,0 / schwer ×1,25, gilt für **Boden und Raum** (Nutzer). Hub speichert sie und gibt sie an `Mission.generate` und an den Raumkampf (`setup.difficulty_factor: float`, fehlend = 1.0) weiter.
- Elite-Beute: `MissionResult.loot`-Einträge mit `elite: true`. Im Handel **verkaufen ja, kaufen nein** (Nutzer).
- Elite-/Boss-Anzahl auf „schwer“ klärt der Nutzer direkt mit dem Bodenkampf.

Zusätzlich zu den Punkten oben: Einstellung „Schwierigkeitsgrad“ im Menü (Einstellungen) und im Spielstand, Weitergabe an Boden und Raum; Elite-Beute im Lager (`elite: true`), verkaufbar, nicht im Sortiment. Punkt 5 (warten) entfällt.

### Auftrag 10 – Ergänzung Story (24.10.2026)

Story ist in `main` (`c5863dd`): `Story.pending_mission()` liefert `elite: "boss"` und `boss_name`. Weitergeben: Boden `Mission.elite = &"boss"` in `_story_ground`, Raum `setup.enemy.boss`/`boss_name` über `space_ctx`; „Boss“ in der Story-Karte zeigen. Details: `docs/Planung_Story.md`, „Boss am Ende einer Kette“.
