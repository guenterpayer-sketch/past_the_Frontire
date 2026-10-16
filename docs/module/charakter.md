# Modul Charakter (Charakter-Modul und Charakter-Editor)

- **Branch:** `claude/elegant-gauss-hq5bus`
- **Zuständig für:** `godot/core/character.gd`, `roster.gd`, `global_roster.gd`, `campaign.gd`, `mission_result.gd` (Format), `injury.gd`, `creation.gd`, `psi_lists.gd`, `rules.gd` (Steigerung), `godot/crew.tscn`, `godot/roster.tscn`, `godot/ui/crew/`, `godot/ui/sheet_dialog.gd`, `godot/data/units/crew*`.

## Schnittstellen

**Figur und Speicher**
- `Character`: Crewmitglied mit allen dauerhaften Werten (inkl. `station`, `roster_id` = Herkunft im Roster, `new_list`, `injury` + `injury_days`). Methoden: `apply_result(r)`, `heal(days)`, `is_locked()`, `injury_text()`, `to_dict()/from_dict()`.
- `Roster`: Crew des Spielstands in `user://crew.json` (Version 3, dazu `harbor` und `squad`): `load_crew()`, `load_extra()`, `save_crew(crew, harbor, squad_ids)`, `start_crew()`, `build_crew()` (Kopien für den Kampf), `reset()`. `build_team()/build_units()` nur für Vorlagen (Gegner, Tests).
- `GlobalRoster` (`user://roster.json`, gehört **keinem** Spielstand): `entries()`, `own()`, `find(id)`, `is_protected(ch)` (Startcharaktere), `add(ch)`, `update(ch)` (nur Name/Kürzel/Farbe/Aussehen), `remove(id)`, `copy(ch, name)`, `unique_id(name)`.

**Laufendes Spiel (`Campaign`)**
- `crew()`, `save()`, `reload()` (nach dem Laden eines Spielstands), `reset()`, `add_member(ch, replace)` (alt).
- `new_game(picked)` – Crew aus Roster-Kopien (1 bis 8).
- `hire(entry)` – Anheuern: eine Figur „im Hafen“ kommt mit Fortschritt zurück, sonst Kopie mit Roster-Stand; `null`, wenn schon an Bord. Ort (Hafen) und Platzprüfung macht der Hub.
- `fire(ch)` – Entlassen: Figur wartet mit Fortschritt „im Hafen“ (`harbor()`), Roster bleibt unberührt.
- `is_aboard(roster_id)`, `harbor()`, `patients()`.
- `finish_mission(result)` – verbucht EP, freie EP und **Verwundung**; Tote (`died`) verlassen die Crew, stehen in `last_fallen`.
- `pass_days(days, bonus_days = 0)` – Heilung (Hub ruft es je Tag mit dem Ergebnis der Zweite-Hilfe-Probe auf); gibt die Geheilten zurück.
- `candidates(quick = false, blocked_ids = [])` – Kandidaten für die Truppwahl: `[{ch, locked, reason, marked, note}]`; im Spiel die Crew, gesperrt = kampfunfähig/schwer verwundet/Arzt (`blocked_ids` vom Hub), markiert = angeschlagen; `quick = true`: Kopien aus dem globalen Roster.
- `suggested_squad(cands)` – Vorbelegung: letzter Trupp ohne Gesperrte, aufgefüllt aus der Reserve.
- `set_squad(chars)` – Ergebnis der Truppwahl (gespeichert); Schnellkampf stattdessen `quick_squad = chars` (nicht gespeichert, wird nach dem Kampf geleert).
- `squad()` – Figuren für den Kampf (`quick_squad`, sonst `chosen_squad`, sonst die ersten 6 nicht gesperrten).
- Konstanten: `START_SEATS = 8`, `MAX_SQUAD = 6`, `CREW_SCENE`, `BATTLE_SCENE`, `ROSTER_SCENE`.

**Verwundung (`Injury`, Regeln `docs/Skillsystem.md` 8a)**
- Stufen `""` (unverletzt), `angeschlagen` (darf mit, Malus −10), `kampfunfaehig`, `schwer` (beide gesperrt); `from_result(r)`, `combine(...)`, `is_locked(stage)`, `name(stage)`, `DAYS`, `CRIT_DAYS`, `LIGHT_MALUS`.
- `Combatant.from_character()` setzt bei „angeschlagen“ `malus = −10` (Datei des Bodenkampfs, nur diese Funktion).

**Ergebnis aus dem Kampf (`MissionResult`)** – Format siehe Kopf von `core/mission_result.gd` (Felder `status.state` ok/ko/sterbend/tot, `worst_crit`, `dying`, `stabilized`, `died` vom Bodenkampf).

**Oberfläche**
- `CrewOverview.show_crew(crew, result)` (Aufleveln, 3D-Vorschau, Zustand und Resttage, „Entlassen“), `current()`, `seats`, Signale `next_battle`, `reset_crew`, `open_sheet`, `crew_changed`; `create_member` bleibt nur für alte Verbindungen (wird nicht gesendet). Knopftexte „Crew zurücksetzen“ und „Speichern & nächste Mission“ bleiben (der Hub sucht danach).
- `roster.tscn` (`RosterScreen`, „Zurück“ → `res://start.tscn`), `CrewPicker.open_pick(subtitle, seats)` + Signal `picked(chars)`, `CharacterEditor.open_for_roster()`, `FigurePreview`, `CrewWidgets`.
- `ui/modal.gd`: `closable`, `title_bar` (Titelzeile; Knöpfe rechts anhängen). `CrewWidgets.burger(host)`: Burgermenü mit „Enzyklopädie“ (`Encyclopedia.show_on(host)`), `CrewWidgets.close_encyclopedia(host)` für Esc.

**Übersicht Psi-Listen (neu, 15.10.2026)** – gemeinsamer Baustein, auch für den Bodenkampf
- `PsiListView` (`ui/crew/psi_list_view.gd`, erbt `Modal`): einmal anlegen und einhängen, dann
  ```
  var psi := PsiListView.new()
  add_child(psi)
  psi.open_for(figur, &"lSchutz")   # figur: Character oder Combatant (gelesen: name, skills, attrs, max_pp) oder null = nur die Listen;
                                    # Liste leer = erste gelernte Liste
  ```
  Schließen per Klick daneben oder `close()`; Esc muss der Aufrufer weiterreichen (wie bei jedem `Modal`).
- Texte für Zeilen: `PsiListView.next_hint(ch, list)` („Rang 5: keine neue Kraft · Rang 6: Psi-Lanze (…)“), `PsiListView.preview_hint(ch, list)` (Editor), `PsiListView.chip(text, color)`.
- Daten in `PsiLists`: `LISTS` (Wirkungstexte wie im Bodenkampf, ohne Ziel), `kind(list, stufe)` → `ATTACK`/`SUPPORT`/`OFF`, `target(list, stufe)` (Ziel, bei Angriffen Reichweite aus `PsiCombat.weapon(k).max_range_m()`), `next_power(ch, list)`, `power_at(list, stufe)`.
- Geändert in `core/psi_lists.gd`: die Wirkungstexte enthalten kein Ziel mehr (steht in `target()`). Die Seitenleiste des Bodenkampfs zeigt `p[2]` im Tooltip der Angriffskräfte; dort steht jetzt z. B. „Psi-Nadel: Schaden nach Tabelle Psi, Angriff −20“.

**Waffenkammer (neu, 15.10.2026)**
- `ArmoryDialog` (`ui/crew/armory_dialog.gd`, erbt `Modal`): **Aufruf für den Hub** im Raum „Waffenkammer“:
  ```
  var armory := ArmoryDialog.new()   # einmal anlegen, z. B. neben crew/editor in hub_ui
  add_child(armory)
  armory.open_for(Campaign.crew(), index_der_gewählten_figur := 0)
  armory.done.connect(...)           # nach „Fertig“; Campaign.save() ist dann schon erfolgt
  ```
  Schließen per Klick daneben/Esc wie jedes `Modal` (dann **ohne** Speichern der Datei; die Änderungen bleiben aber an den `Character`-Objekten im Speicher – der nächste `Campaign.save()` schreibt sie).
- `Equipment` (`core/equipment.gd`): `weapons()` (ohne Psi, dazu eigene aus `Gear.weapons()`), `armors()` (dazu `Gear.armors()`), `label(r)` (Name, „(frei)“ bei `Gear.is_free`), `weapon(ch, slot)`, `weapon_block/set_weapon(ch, slot, w)` (Platz 1 = `null` → Waffe 2 leer), `blocks_shield(w)`, `shield_block/set_shield(ch, on, g)`, `shield_bonus(ch)`, `damage_taken(armor)`. Lager (`g = HubState.game`, null = unbegrenzt): `set_weapon(ch, slot, w, g)`, `set_armor(ch, a, g)`, `set_medkits(ch, n, g)` (0 … `MAX_MEDKITS` = 3), `restore(ch, snap, g)`, `in_stock(g, r)`, `listed(g, r, worn)`, `is_free_item(r)`, `SHIELD` (Lager-Schlüssel des Schilds).
- Regeln (Nutzer 15.10.2026): Waffe 1 Pflicht, Waffe 2 darf leer sein; keine Waffe doppelt; Psi-Waffen nicht wählbar; Schild nur mit einhändigen Waffen (Fäuste zählen nicht als zweihändig); eine zweihändige Waffe legt den Schild ab.
- **In Dateien des Bodenkampfs geändert (auf Anweisung des Nutzers):** `data/weapons/vibroklinge.tres` → `two_handed = false` (einhändig; wirkt auch auf die Haltung des 3D-Modells), `data/weapons/laserkarabiner.tres` → Fertigkeit `gewehre` statt `pistolen`. Folge: Ikko und Rhea (Laserkarabiner, keine Ränge in Gewehre) treffen damit deutlich schlechter (Pistolen +65/+40 → Gewehre −15); Nutzer: „so lassen“, umrüsten in der Waffenkammer.

**Regeln in `Rules`** (wirken auf alle Figuren, auch Gegner): Gruppen „Entwicklung“ und „Psi-Listen“; TP = 15 + KON/3 + 5 × Körperentwicklung; PP = MEN/10 + MEN-Bonus/2 + 2 × Psi-Punkte-Entwicklung; neue Psi-Liste: erster Rang doppelt, eine pro Levelphase (`next_rank_cost`, `rank_block`).

**In Dateien anderer Module geändert:** `view/battle.gd` (eine Zeile: Kampf mit `Campaign.squad()`), `core/combatant.gd` (`from_character`: Malus für Angeschlagene).

## Stand (15.10.2026)

- (16.10.2026) **Beschädigung und Verlust, Teil „Danach“** gebaut (Lagerformat des Hubs `"Grundschlüssel|Schaden"`): Die Übergangslösung ist weg. `Equipment.set_weapon/set_armor(…, damage)` nehmen das Stück mit diesem Schaden aus dem Lager und setzen `ch.wear[platz]`; das abgelegte Stück geht mit seinem Abzug zurück (`Stock.damaged_key`); `restore`/`snapshot` rechnen mit Schaden. Neu: `Equipment.stock_key(r, damage)`, `in_stock(g, r, damage)`, `stock_damages(g, r)`; Fäuste/keine Rüstung gibt es nur intakt, ohne Spiel nur intakte Stücke. Waffenkammer: je Teil eine Zeile pro Schadensstufe („Sturmgewehr (−20)“, orange bzw. rot bei unbrauchbar, eigene Lagerzahl), Bonus bzw. Verteidigung abzüglich Schaden (auch im Platz links). Tests in `_test_char_wear`; Autotest-Hub legt für `h1d_waffenkammer` zwei beschädigte Stücke ins Lager.
- (16.10.2026) **Beschädigung und Verlust übernehmen (Teil „Jetzt“)** gebaut: `Character.wear` {"w0"/"w1"/"armor": Abzug} wird gespeichert (`to_dict/from_dict`; bei gelöschter eigener Ausrüstung fällt der Abzug des Platzes weg) und in `apply_result` aus dem `MissionResult` übernommen; `lost` leert die Plätze über `Character.lose(slot)` (Waffe 1 → Fäuste, Waffe 2 leer, Rüstung → keine, ohne Lager). Anzeige: Waffenkammer neben dem Namen im Platz („beschädigt −10“ / „unbrauchbar“), Charakterübersicht Zeile „Beschädigt: …“, Roster-Kurzwerte Zeile „Beschädigt“. Helfer `Equipment.wear_text/wear_summary/gear_at/snapshot`. **Vorläufig** (bis Teil „Danach“): Wechselt ein Teil in der Waffenkammer, fällt der Abzug des Platzes weg und das Stück geht ohne Schaden ins Lager; „zurücknehmen“ stellt den Abzug wieder her. Tests `_test_char_wear`; Autotest-Hub setzt für den Screenshot `h1d_waffenkammer` Schaden bei der ersten Figur.
- (16.10.2026) **Waffenkammer am Lager (Schritt 3)** gebaut. Entscheidungen des Nutzers: nicht Vorrätiges wird **ausgeblendet** (angezeigt: im Lager, getragen, immer verfügbar; Spalte „Lager“); **Fäuste und „keine Rüstung“ immer verfügbar** (`Stock.EXCLUDE`); **Schild wird Lagergegenstand** (Schlüssel `Equipment.SHIELD = "schild"`); **Medikits höchstens 3 je Figur, Verbrauch im Einsatz wird abgezogen** (`Character.apply_result`). „zurücknehmen“ tauscht mit dem Lager zurück (`Equipment.restore`, scheitert mit Hinweis, wenn ein Teil inzwischen fehlt). Ohne Spiel (`HubState.game == null`) unbegrenzt. Tests `_test_armory_stock`.
- **Auftrag an Hub (aus der Entscheidung „Schild = Lagergegenstand“):** Der Schild hat keinen Ressourcenpfad; Schlüssel ist `Equipment.SHIELD` (`"schild"`). `Stock.name_of()`, `price()`, `goods()`/Sortiment und Handel kennen ihn noch nicht – bitte als Handelsgut aufnehmen (Name „Schild“, Preis nach Absprache mit dem Nutzer). Bis dahin kommt ein Schild nur ins Lager, wenn eine Figur ihn ablegt.
- (16.10.2026) Enzyklopädie angebunden, Entscheidungen des Nutzers: **Burgermenü ☰ oben rechts** in Charakterübersicht und Charakter-Editor (Eintrag „Enzyklopädie“, `CrewWidgets.burger(host)`); **ⓘ an jeder Psi-Liste öffnet die Enzyklopädie** an dieser Liste; **„Alle Psi-Listen ansehen“ öffnet weiter `PsiListView`** (Stand der Figur, auch im Kampf genutzt); **Hinweiszeilen** unter den Psi-Listen bleiben. Esc schließt die Enzyklopädie zuerst. Geändert in `ui/modal.gd`: neue `title_bar` (Titelzeile als HBox, Titel links; Platz für Knöpfe rechts), sonst gleich.
- Eigene Rüstungen/Waffen und Munitionsanzeige in der Waffenkammer: `Equipment.weapons()/armors()` liefern auch `Gear`-Einträge (Vermerk „(frei)“); `Character.from_dict()`: gelöschte eigene Ausrüstung → Waffe 1 `Gear.FALLBACK_WEAPON`, Waffe 2 leer, Rüstung `Gear.FALLBACK_ARMOR` (prüft `user://`-Dateien mit `FileAccess`, weil Gelöschtes im Cache liegen kann). Anzeige „Besonderes“ und Vorrat nach `shots`, `ammo_type`, `ammo_total`, `Ammo.carry()`. Tests `_test_own_gear`.
- Übersicht Psi-Listen gebaut nach Mockup „Frontire Psi-Listen“ (vom Nutzer bestätigt; Reichweite aus dem Bodenkampf): `PsiListView`, eingebaut in Charakterübersicht/Aufleveln und Charakter-Editor; Kommentar und Wirkungstexte in `core/psi_lists.gd` an den Bodenkampf angeglichen; Tests `_test_psi_view`, Screenshots `04f`/`04g` im Autotest. Einbau im Bodenkampf: Aufruf oben unter „Schnittstellen“.
- Waffenkammer gebaut nach Mockup „Frontire Waffenkammer“ (vom Nutzer bestätigt): `ArmoryDialog` + `Equipment`, Tests in `test_rules.gd` (`_test_equipment`). Der Hub muss nur noch den Raum „Waffenkammer“ anbinden (Aufruf oben).
- Davor (16.10.): Klärung D, Verwundung, Kandidaten für die Truppwahl – in `main`.

## Aufträge vom Koordinator

- (16.10.2026) Klärung D, Verwundung auswerten, Kandidaten für die Truppwahl → erledigt (siehe Stand).

## Aufträge vom Koordinator (16.10.2026, nach Merge `4e282e1`)

In `main`, nichts offen. `main` holen (Hub `479e767` ist drin). Schnittstellen und Knopftexte der Charakterübersicht nur nach Ankündigung ändern (Hub benennt/blendet über die Texte um). Auf Fragen von Hub (Krankenstation, Anheuern) und Bodenkampf (Truppwahl) antworten; nächste Aufgabe kommt vom Nutzer.

## Aufträge vom Koordinator (15.10.2026): Waffenkammer

Grundlage: `docs/Planung_Waffenkammer.md`. Du baust den **Ausrüstungsdialog** (Waffe 1/2, Rüstung, Schild ändern; Medikits/Munition nur anzeigen; Werte aus `WeaponData`/`ArmorData` inkl. Bonus der Figur in der Waffenfertigkeit). Bestand unbegrenzt, Änderung gilt für die Figur im Spielstand. **Erst Mockup**, vom Nutzer bestätigen lassen, dann bauen. Der Hub öffnet den Dialog aus dem Raum „Waffenkammer“ – Aufruf (Funktion/Signal) in den Schnittstellen vermerken.
- (15.10.2026) Waffenkammer: Ausrüstungsdialog → gebaut (siehe Stand); Aufruf für den Hub unter „Schnittstellen“.

## Aufträge vom Koordinator (15.10.2026): Übersicht Psi-Listen

Nutzer: Es fehlt eine Übersicht, was die Psi-Listen und ihre Kräfte bewirken. Daten liegen in `core/psi_lists.gd` (`PsiLists.LISTS`, je Kraft Stufe, Name, Wirkung; Regeln `docs/Skillsystem.md` 6.1).
1. **Gemeinsamer Baustein (nur du baust ihn):** eine Anzeige der Listen mit Kräften je Stufe (Name, Stufe = PP-Kosten, Wirkung, Probe; bei einer Figur: welche Stufen schon verfügbar sind). Als Funktion/Widget, das auch der Bodenkampf einbauen kann. Schnittstelle unter „Schnittstellen“ vermerken.
2. Einbauen in **Charakterübersicht/Aufleveln** (was bringt der nächste Rang) und **Charakter-Editor** (bei der Wahl der Listen).
3. Kommentar oben in `core/psi_lists.gd` („im Kampf bisher nur Psi-Schild und Psi-Stoß“) ist veraltet; Wirkungstexte mit dem Stand im Bodenkampf abgleichen (z. B. „Am Leben halten“ stabilisiert, siehe 6.1).
Vorher **Mockup** zeigen und vom Nutzer bestätigen lassen.
- (15.10.2026) Übersicht Psi-Listen → gebaut (siehe Stand); Aufruf für den Bodenkampf unter „Schnittstellen“.

## Aufträge vom Koordinator (15.10.2026): eigene Rüstungen

Der Hub baut einen Editor für eigene Waffen und Rüstungen (`docs/Planung_Ausruestungs_Editor.md`). **Warten, bis sein Baustein in `main` ist.** Dann: `Equipment.armors()` liefert auch eigene Rüstungen, die Waffenkammer zeigt eigene Ausrüstung; Verhalten, wenn getragene Ausrüstung gelöscht wird, mit dem Nutzer klären (Abschnitt „Aufteilung“, Punkt 3).
- **Baustein des Hubs ist in `main` (`52efbe2`):** `Equipment.weapons()/armors()` um `Gear.weapons()/armors()` ergänzen; gelöschte Datei: Waffe 1 → `Gear.FALLBACK_WEAPON` (Fäuste), Waffe 2 leer, Rüstung → `Gear.FALLBACK_ARMOR` (keine) – vom Nutzer so entschieden; Vermerk „frei“ über `Gear.is_free(r)`. Details `docs/module/hub.md`. Jetzt `main` holen und anbinden.

## Aufträge vom Koordinator (15.10.2026): Anzeige Munition in der Waffenkammer

Munition Teil Kampf ist in `main` (`928b0f9`), siehe `docs/module/bodenkampf.md` → Munition. `ui/crew/armory_dialog.gd` zeigt „Feuerstoß“ noch aus `ob_bonus` (beim MG jetzt leer) und „Munition gesamt“ als 3 Magazine. Anpassen an `shots`, `ammo_type`, `ammo_total` (Obergrenze der Mitnahme). Zusammen mit dem Auftrag „eigene Rüstungen“ erledigen.
- (15.10.2026) Eigene Rüstungen und Anzeige Munition → gebaut (siehe Stand).
- **Hinweis an Bodenkampf (Entscheidung des Nutzers 15.10.2026):** Laserpistole, Laserkarabiner, Sturmgewehr und MG haben `magazine = 0` (= keine Munition nötig), obwohl `ammo_type` gesetzt ist; nur der Raketenwerfer hat ein Magazin. Nutzer: Diese Waffen sollen Magazine bekommen, **der Bodenkampf trägt sie ein**. Die Waffenkammer zeigt die Mitnahme dann ohne Änderung an.

## Hinweis vom Koordinator (16.10.2026): Enzyklopädie

Der Hub baut eine Enzyklopädie (`docs/Planung_Enzyklopaedie.md`). **Warten, bis sie in `main` ist**; dann deinen Teil aus Abschnitt „Aufteilung“ umsetzen.
- **Enzyklopädie ist in `main` (`04091c2`):** `Encyclopedia.show_on(control, &"psi", name)` für das ⓘ bei den Psi-Listen (Eintrag = Name der Liste, z. B. „Angriff“); Zugang in Übersicht/Editor mit dem Nutzer klären. Details `docs/module/hub.md`. Jetzt `main` holen und anbinden.
- (16.10.2026) Angebunden → siehe Stand.

## Hinweis vom Koordinator (16.10.2026): Waffenkammer am Lager

Geplant (`docs/Planung_Ausbau_Lager_Handwerk.md`, Schritt 3): Der Hub baut ein Lager mit Stückzahlen. **Warten, bis seine Schnittstelle in `main` ist.** Dann: Ausrüsten nimmt aus dem Lager, Ablegen legt zurück, Medikits aus dem Lager.
- **Lager des Hubs ist in `main` (`81991c8`):** `Stock.key_of(res)` (= `resource_path`), `Stock.MEDKIT`, `Stock.count/take/add(HubState.game, key, n)`, `Stock.items(g)`, `Stock.name_of(key)`; ohne Spiel (Schnellkampf) unbegrenzt. Details `docs/module/hub.md`. Jetzt `main` holen und die Waffenkammer anbinden (Schritt 3).
- (16.10.2026) Angebunden → siehe Stand; Auftrag an Hub zum Schild.

### Auftrag (16.10.2026): Beschädigung und Verlust übernehmen

Bodenkampf meldet je Figur im `MissionResult` `wear` {Platz "w0"/"w1"/"armor": Abzug; −10 je Schaden, ab −30 unbrauchbar} und `lost` [Platz] (Niederlage ohne Rückzug). Regeln: `docs/Skillsystem.md`, „Beute, Beschädigung und Verlust“. Schild ist davon ausgenommen (Entscheidung des Nutzers).
- **Jetzt:** `Character.wear` speichern (der Kampf liest es schon über `ch.get("wear")`), in `apply_result` übernehmen; verlorene Plätze leeren (Waffe 1 → Fäuste, Waffe 2 → leer, Rüstung → keine) **ohne** `Equipment.set_weapon/set_armor` (die legen das alte Teil ins Lager zurück – das verlorene käme wieder). Beschädigung in Charakterübersicht und Waffenkammer anzeigen.
- (16.10.2026) „Jetzt“ → gebaut (siehe Stand).
- **Hinweis an Koordinator (Entscheidung des Nutzers 16.10.2026):** Die Übergangslösung bleibt vorerst: Wird ein beschädigtes Teil in der Waffenkammer gewechselt, fällt sein Abzug weg und es geht **heil** ins Lager (kostenlose Reparatur durch Ablegen und neu Anlegen möglich). Erst mit dem Teil „Danach“ (Lagerformat des Hubs für beschädigte Stücke) behoben; bitte bei Hub-Auftrag und Reparatur berücksichtigen.
- **Danach (wartet auf Hub):** Beschädigte Stücke liegen einzeln mit Schaden im Lager; das `Stock`-Format legt der Hub fest. Dann Waffenkammer: beschädigte Stücke wählbar, beim Ablegen mit Schaden zurück ins Lager (`wear` des Platzes geht mit).
- (16.10.2026) „Danach“ → gebaut (siehe Stand); Übergangslösung entfällt.
- **Lagerformat des Hubs ist in `main` (16.10.2026):** Teil „Danach“ kann beginnen. Format und Aufrufe für die Waffenkammer stehen in `docs/module/hub.md` unter den Schnittstellen („Lagerformat für beschädigte Stücke“): Schlüssel `"Grundschlüssel|Schaden"`, `Stock.damaged_key/base_of/damage_of`, Anlegen = `Stock.take` + `ch.wear[platz]`, Ablegen = `Stock.add(g, Stock.damaged_key(...))`. Damit entfällt die Übergangslösung (beschädigt geht nicht mehr heil ins Lager).

### Auftrag (16.10.2026): Reiter „Lager“ in der Waffenkammer

Wunsch des Nutzers: Die Waffenkammer zeigt bisher nur die Plätze der Figur; es fehlt ein Inventar. Entscheidungen:
- **Eigener Reiter „Lager“** im `ArmoryDialog` (Umschalten zwischen Ausrüstung der Figur und Lagerliste).
- **Inhalt:** das ganze Schiffslager (`Stock.items(HubState.game)`) – Waffen, Rüstungen, Schilde, Medikits mit Stückzahl, auch was die Figur gerade nicht nutzen kann; **beschädigte Stücke einzeln** („Sturmgewehr (−20)“, `Stock.name_of/damage_of`); **Munition je Art** (`HubState.ammo`); **Material** (Schiffsmaterial, später Handwerksmaterial – nur anzeigen).
- **Aktionen:** ansehen und **direkt ausrüsten** (Stück wählen → der aktuellen Figur an den passenden Platz anlegen, gleiche Regeln wie über die Plätze, altes Teil zurück ins Lager). Verkaufen/Verschrotten und Zerlegen **nicht jetzt** – wird mit dem Handwerk geklärt.
- **Erst Mockup** (größere UI-Änderung), vom Nutzer bestätigen lassen, dann bauen. Ohne Spiel (`HubState.game == null`) Reiter ausblenden oder „unbegrenzt“ anzeigen – mit dem Nutzer klären.
