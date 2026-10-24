# Modul Bodenkampf

- **Branch:** `claude/confident-edison-6mxzke`
- **Zuständig für:** `godot/main.tscn`, `godot/view/` (außer Hub-Szenen), `godot/core/combat*.gd`, `combatant.gd`, `battle_map.gd`, `map_generator.gd`, `mission.gd`, `tables.gd`, `dice.gd`, `hex.gd`, `godot/ui/` des Kampfes (`battle_ui.gd`, `action_panel.gd`, `unit_card.gd`, `top_menu.gd`, `info_box.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, `briefing_dialog.gd`), `godot/data/` für Waffen, Rüstungen, Tabellen, Gegner, Fraktionen.
> Erledigte Aufträge und alter Stand bis 16.10.2026: `docs/module/archiv/bodenkampf_bis_2026-10-16.md` (nur bei Bedarf lesen).


## Schnittstellen

- **Eingang:** im Briefing gewählter Trupp als Kopien (`Roster.build_crew(Battle.squad)`), optional eine fertige `Mission` (aus der Sternenkarte des Hubs).
- **Truppwahl (seit 16.10.2026, Auftrag Truppwahl):** Kandidaten `Campaign.candidates(HubState.quick_battle, HubState.blocked_ids())` (Charakter/Hub), Vorbelegung `Campaign.suggested_squad()`; Ergebnis beim Schließen des Briefings → `Campaign.set_squad()` (im Spiel, gespeichert) bzw. `Campaign.quick_squad` (Schnellkampf). Schnellkampf: Kandidaten einmal je Szene geholt, Auswahl bleibt bei „Andere Mission“ erhalten. `Campaign.chosen_squad`/`squad()` liest der Bodenkampf nicht mehr direkt. Neu in `Battle`: `candidates`, `squad`, `_pick_squad()`, `_on_squad()` (anderer Trupp → Runde 0 mit derselben Karte neu); `BriefingDialog.show_mission(m, cands, selected)`, Signal `accepted(squad)`, `quick`, `selection()`, `toggle()`. `hub_report()` nimmt `Campaign.last_fallen` auf.
- **Munition (seit 15.10.2026, mit dem Hub abzustimmen):** Eingang Schiffsvorrat `HubState.game.ammo = {Art: Schuss}` (Arten `Ammo.TYPES`: `energie`, `projektil`, `raketen`; `Battle.ammo_stock()` liest ihn, fehlt er oder Schnellkampf → alles voll). Ausgang `MissionResult` neu `ammo_used = {Art: Schuss}` (ganze Crew); der Hub zieht ihn vom Vorrat ab. Neue Waffenwerte (Ausrüstungs-Editor): `WeaponData.shots` (Schuss pro Angriff, Feuerstoß), `ammo_type`; `ammo_total` = Obergrenze der Mitnahme (0 = nur 3 Magazine). Regeln in `core/ammo.gd` (`carry`, `plan`, `apply`, `used`, `burst_bonus`). MG: `ob_bonus` 15 → `shots` 3 (gleicher Bonus).
- **Waffenmodelle und Klänge (seit 16.10.2026):** Katalog `WeaponModels` (`all()`, `find()`, `apply()`), Klangliste `WeaponData.SOUNDS`, Waffenwert `sound_id`; Klangdateien in `audio/sfx/`.
- **Ausgang:** `MissionResult.from_combat()` → `Campaign.finish_mission()` → Szene `crew.tscn`. `ui/end_dialog.gd` und `Roster.load_progress()/save_progress()` gibt es nicht mehr.
- **Rückzug (seit 16.10.2026):** `MissionResult.retreated: bool` – true nur, wenn sich die Crew zurückgezogen hat (`Combat.retreated`); `outcome` bleibt dabei `&"niederlage"`. Bei Sieg und Niederlage ohne Rückzug false.
- **Seit 16.10.2026 (Verwundung statt Tod, Auftrag 3) – Änderung am `MissionResult` (Datei des Charakter-Moduls, vom Bodenkampf erweitert):**
  - `status.state` kann jetzt `"ok"`, `"ko"`, **`"sterbend"`** oder `"tot"` sein (vorher `"ok"/"ko"/"tot"`; `"tot"` kommt nur noch durch den Todeswurf vor). **Achtung Charakter-Modul:** `crew_overview.gd` kennt `"sterbend"` noch nicht (zeigt dann nichts an).
  - Neu je Figur: `worst_crit` (`""` oder `"A"`–`"E"`, schwerster erlittener Kritischer), `dying` (bool: am Ende sterbend und nicht stabilisiert), `stabilized` (bool: sterbend, per Erster Hilfe stabilisiert → laut Nutzer „kampfunfähig“ statt „schwer verwundet“), `died` (bool: tot durch den Todeswurf).
  - `Combatant`: `State { OK, KO, DYING, DEAD }`, `stabilized`, `worst_crit`, `is_down()`; `Combat.DEATH_CHANCE = 10`.
- **Seit 16.10.2026 (Psi im Kampf, Auftrag 2) – Schnittstelle zum Charakter-Modul:** Der Kampf liest die Psi-Kräfte nur aus den **Listen-Rängen** des `Character` (`PsiLists.LISTS`, Rang = höchste Stufe; `core/psi_combat.gd` legt die Kampfwirkung je `"Liste/Stufe"` fest). **Waffen mit `psi = true` (alte Psi-Stoß-Waffe) werden im Kampf ignoriert** → **Auftrag an Charakter:** alte Spielstände umwandeln (Psi-Stoß-Waffe → Listen-Ränge; Entscheidung des Nutzers: „Charakter-Modul regelt“). Startcrew-Daten geändert (Datei des Charakter-Moduls, Entscheidung des Nutzers): `data/units/crew/nyx.tres` ohne Psi-Stoß-Waffe, dafür `lAngriff` 4 und `lSchutz` 4; Gegner `hexer.tres`: `lAngriff` 4, `lSchutz` 2. `tests/test_rules.gd` `_test_leveling` nutzt jetzt `lWahrnehmung` als neue Liste (Nyx hat Schutz). Texte in `PsiLists`/`Skillsystem.md` für „Am Leben halten“ (stabilisiert Sterbende) und „Gedanken orten“ (hebt Deckung auf) sollte das Charakter-Modul angleichen.
  - Neu: `WeaponData.power`, `power_effect` (Laufzeit-Felder für Psi-Angriffskräfte); `Combatant.powers`, `buffs`, `disarmed`; `Combat.power_targets()`, `can_power()`, `do_power()`; `PlayerController.choose_power()`, `context_powers()`; `ui/context_menu.gd`. `Combat.psi_shield_targets()`/`do_psi_shield()` entfernt (Psi-Schild ist jetzt `lSchutz/2`).

## Stand

- Alles in `main` (19.10.2026), keine offenen Aufträge. Verlauf: `docs/module/archiv/bodenkampf_bis_2026-10-19.md`; Funktionen: `godot/README.md`.
- **Fertig (21.10.2026, Klick auf verdeckten Gegner):** Ein Klick auf einen Gegner unter dem Infokasten oben rechts griff nicht an. Der Kasten fing alle Klicks ab (`MOUSE_FILTER_STOP`) und zählte in `BattleUI.covers()` als Sperre. Jetzt lässt er Klicks zur Karte durch, nur der Knopf „Ausführen“ fängt sie; `covers()` zählt ihn nicht mehr. Geprüft: temporärer Klick-Test auf einen verdeckten Gegner löste einen Angriff aus (Test danach entfernt). Seitenleiste, Menü und Würfel bleiben Sperren. Keine Schnittstellenänderung.
- **Fertig (23.10.2026, Seitenleiste abgeschnitten):** Der Knopf „Reparieren <Waffe> · <Figur> …“ war bis 347 px breit, die Leiste (290 px, an der linken Kante platziert) wuchs dadurch rechts aus dem Bild. Jetzt Reparieren-Knöpfe je eine volle Zeile unter den übrigen Aktionen, gekürzt mit vollem Text im Tooltip (`ActionPanel`); zusätzlich bleibt die rechte Kante fest am Rand, breiterer Inhalt lässt die Leiste nach links wachsen (`BattleUI._process`). Geprüft im Spiel mit temporärem Test: Leiste mit Reparatur-Knopf 290 px, rechte Kante 1586 von 1600; mit künstlich 400 px Inhalt 420 px breit, rechte Kante weiter 1586, Infokasten rückt nach links.

- **Bericht (24.10.2026, Balancing – Ursache finden, nur Analyse):** Spielstand `spielstaende/24-10-2026` (Tag 60, 6 Einsätze), Simulation KI gegen KI mit der Squad des Nutzers (Rino, Vella, Mireaf, Bum Gun, Ilmu, Lucky), 20 Kämpfe je Fall, gleiche Missionen.
  - Ergebnis „schwer“: Squad jetzt 18/20 Siege, TP-Verlust 37 %, 1,0 kampfunfähig je Kampf; dieselbe Squad mit den Rängen beim Erschaffen 17/20, 50 %, 1,5; Startcrew 3/15, 93 %, 5,1. „mittel“: Squad 20/20, TP-Verlust 14 %; Startcrew 11/15, 58 %.
  - Ursache 1 (größter Abstand): Figuren beim Erschaffen. Eigenschaften kaum höher (Summe 455–579, Startcrew 477–500), aber Körper 3–5 (+5 TP je Rang, `Rules.max_hp`), Kampffertigkeiten auf Rang 8, Ausweichen bis 8; TP jetzt 58–75 gegen Gegner 33–45 (Körper 0). 3 von 6 tragen schwere Rüstung (Kl. 3), Gegner meist Kl. 0–1.
  - Ursache 2: Gegner wachsen nicht mit. `Mission.generate` kennt die Crew nicht, Budget fest (42/58/88), Gegnerwerte fest, höchstens 9 Gegner (schwer Ø 8,4, schon fast am Deckel).
  - Ursache 3: Steigerung. In 6 Einsätzen +5 bis +7 Ränge (z. B. Rino Zweihand 8→15, Kampfsinn bei allen +5…+7); Kampf-EP Ø 24 (mittel) bzw. 42 (schwer) je Figur und Kampf, Kampfsinn +1 je Runde.
  - Eigene Ausrüstung: alle 7 Waffen und 2 Rüstungen in den Editor-Regeln, das Scharfschützengewehr mit „Werte frei“ (erlaubt, vermerkt). Wirkung klein: mit Standardausrüstung „schwer“ TP-Verlust 46 % statt 37 %.
  - Verletzungen kommen vor (Medlog Tag 53/60: Rino, Lucky, Ilmu, Vella), heilen aber schnell (Arzt Zweite Hilfe +85).
  - Nicht geprüft: Raumkampf (Modul Raumkampf). Annahme: Ein Mensch spielt besser als die KI, im Spiel ist es also eher leichter als in der Simulation.
  - Wege (Entscheidung des Nutzers offen): (a) Gegner mitwachsen lassen (Crewstärke an `Mission.generate`, Veteranen-Gegner), (b) Körper/Erschaffung anpassen (Regeln, Charakter-Modul), (c) neue Stufe „sehr schwer“ mit Elite-Gegnern und mehr als 9 Gegnern.

## Aufträge vom Koordinator

### Auftrag (24.10.2026): Balancing – Ursache finden

Analyse, **nichts bauen**. Anlass (Nutzer 24.10.2026): Die Crew ist inzwischen so stark, dass Kämpfe keine Herausforderung mehr sind. Betrifft Boden- **und** Raumkampf. Anzeichen laut Nutzer: Gegner fallen zu schnell, keine Verletzungen oder Verluste, zu wenige Gegner. Entscheidung des Nutzers: erst die Ursache finden, dann Wege vorschlagen.

1. Spielstand des Nutzers lesen: `spielstaende/24-10-2026/` (`slot_1.json`, `auto.json`, `crew.json`, `roster.json`; Tag 60, 6 Einsätze, 10 Figuren). Eigene Ausrüstung: `spielstaende/24-10-2026/gear/` (7 Waffen, 2 Rüstungen).
2. Bodenkampf prüfen: Gegnerwerte, Anzahl und Zusammensetzung je Schwierigkeit/Ort gegen die Werte der Crew (Fertigkeiten, Rüstung, Waffen). Die eigene Ausrüstung des Nutzers mit den Standardwaffen und -rüstungen vergleichen und melden, ob sie außerhalb der Regeln liegt (`docs/Skillsystem.md`). Simulation mit der Crew des Nutzers, wenn machbar (`test_sim.gd`).
3. Ergebnis als Bericht an den Nutzer: Ursachen mit Zahlen (was ist Wissen, was Annahme), dazu 2–3 Wege zum Ausgleich mit Vor- und Nachteilen. Bericht kurz in die Moduldatei unter „Stand“ eintragen. Kein Code ändern, bis der Nutzer entschieden hat.

### Elite-Gegner – gemeinsame Regeln Boden und Raum (Nutzer 24.10.2026)

- **Häufigkeit:** etwa jeder 7.–8. Kampf (Zufall, ca. 13 %), gleich für Boden und Raum.
- **Stärke:** nach **Ziel-Siegquote**: per Simulation mit der Crew so einstellen, dass der Nutzer etwa 70–75 % der Elite-Kämpfe gewinnt. Nicht an den Durchschnitt der Crew angleichen (Sorge des Nutzers: zu schwer).
- **Woher die Stärke kommt:** bessere Ausrüstung mit höheren Boni (Boden: Waffen/Rüstung; Raum: stärkere Schiffswaffen/Schilde), dazu Werte nach Bedarf.
- **Erkennbar:** schon vorher im Auftrag/Feindkontakt („Elite“, ausweichen möglich) und im Kampf markiert (Zeichen/Farbe am Gegner bzw. Schiff).
- Keine Extra-Belohnung festgelegt (Nutzer hat sie nicht gewählt).
- **Ablauf:** Bodenkampf und Raumkampf legen dieselbe Auswahl (Häufigkeit, Kennzeichen „Elite“ im Angebot/Kontakt) fest; Wer das Angebot erzeugt (Hub), bekommt die Kennzeichnung über den Koordinator. Erst Vorschlag mit Simulation an den Nutzer, dann bauen.

### Entscheidungen des Nutzers zum Balancing (24.10.2026)

1. **Gegner bekommen Ränge in Körper** (mehr TP), damit der TP-Abstand zur Crew kleiner wird.
2. **(a) Gegner wachsen moderat mit:** Die Mission kennt die Stärke der eingesetzten Crew (mehr/stärkere Gegner), aber nur so weit, dass Fortschritt spürbar bleibt. Schnittstelle Hub → `Mission.generate` vorschlagen; den Hub-Teil gibt der Koordinator weiter.
3. **Elite-Gegner** nach den gemeinsamen Regeln oben.
4. Nicht gewählt: Erschaffung/Körper der Crew ändern, Stufe „sehr schwer“. Steigerung bleibt wie sie ist.
5. **Ablauf:** erst Vorschlag mit Simulation (Siegquoten und TP-Verlust mit der Crew aus `spielstaende/24-10-2026/` und mit der Startcrew), an den Nutzer melden, erst nach Zustimmung bauen.
