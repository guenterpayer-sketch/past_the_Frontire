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

- **Vorschlag mit Simulation (24.10.2026, Balancing, noch nicht gebaut):** Prototyp KI gegen KI, Squad aus `spielstaende/24-10-2026` (Stärke 1,43 = Mittel aus Ø TP und Ø bestem Angriffswert, je geteilt durch die Startcrew), 20–30 Kämpfe je Fall; Startcrew unverändert (Mehrstärke 0).
  - Mitwachsen (Wahl des Nutzers: zwischen A und B): Mehrstärke m = Stärke − 1 (0…1); Gegner Körper +round(7·m), Waffenfertigkeit +round(2·m), Budget ×(1 + m), höchstens 9 Gegner. Squad: Körper +3, Waffe +1, Budget leicht 60/mittel 83/schwer 126. Ergebnis Squad (heute → neu): leicht 5 → 27 % TP-Verlust, mittel 14 → 49 % (1,3 kampfunfähig), schwer 37 → 50 % (Siege 27/30). Zum Vergleich A (ohne Waffe): mittel 39 %, schwer 43 %; B (Waffe +2): mittel 48 %, schwer 53 %; Unterschied A/Mitte/B auf „mittel“ im Rahmen der Streuung (±8–10 Punkte). Kämpfe länger (mittel 7 → 18 Runden).
  - Elite auf „mittel“ (Ziel 70–75 % Siege, Squad): ganzer Trupp Waffen +12, Körper +2 → 73 %; Elite-Kern (jeder 3. Gegner) Waffen +30, Körper +5 → 70 %; Anführer Waffe +40, Körper +10 mit 2 Begleitern Waffen +20, Körper +3 → 73 %. Bessere Rüstung (Klasse +1) zu stark. Gegen die Startcrew (ganzer Trupp +10/+2): leicht 90 %, mittel 60 %.
  - Offen beim Nutzer/Koordinator: Elite in allen drei Formen, im Auftrag markiert, auch in Story-Missionen; Kennzeichnung im Angebot (Hub) und im Kampf. Vorschlag Schnittstelle: Elite aus dem Auftrags-Seed (ca. 13 %, gemeinsame Funktion für Boden und Raum), Mitwachsen erst im Briefing nach Truppwahl (keine Hub-Schnittstelle nötig). Neuling/Veteran bleiben wie sie sind (Nutzer).

- **Vorschlag Elite/Boss fertig abgestimmt (24.10.2026, noch nicht gebaut):** Simulation wie oben (Mitwachsen „zwischen A und B“, „mittel“, 30 Kämpfe, Squad des Nutzers, Ziel 70–75 % Siege). Rüstung bleibt in ihrer Klasse und bekommt nur einen Verteidigungsbonus (Nutzer 24.10.2026).
  - Ohne Rüstungsbonus: Trupp Waffen +12/Körper +2 → 73 %; Kern (jeder 3.) +30/Körper +5 → 70 %; Anführer +40/Körper +10, 2 Begleiter +20/Körper +3 → 73 %.
  - Mit Rüstungsbonus: Trupp VW +10/Körper +2 ohne Waffenbonus → 90 %, mit Waffen +6 → 83 %; Kern VW +15/Waffen +20/Körper +4 → 80 %; **Anführer VW +15/Waffe +25/Körper +8, Begleiter VW +10/Waffen +10/Körper +3 → 73 %**. Rüstungsbonus wirkt schwächer als Waffenbonus und verlängert die Kämpfe (20–27 Runden). Für Trupp und Kern mit Rüstungsbonus ist der Waffenbonus noch nachzusimulieren (Schätzung: Trupp VW +10 mit Waffen +10…12, Kern VW +10 mit Waffen +28…30).
  - Boss-Kampf = Form „Anführer“ (Boss + 2 Leibwächter + Fußvolk), Werte wie Anführer.
  - Schnittstelle (Vorschlag): `Mission.elite: StringName` (`""`, `&"trupp"`, `&"kern"`, `&"boss"`); der Hub setzt nur `elite = &"elite"`-Wunsch (ja/nein), der Bodenkampf würfelt trupp/kern aus dem Auftrags-Seed; Story und Hub-Personenziele setzen `&"boss"` fest. Beute: bei Elite/Boss mit 25 % 2–3 Elite-Stücke (aus den Waffen/Rüstungen der Elite-Gegner), stark beschädigt (−20/−30), als normale Einträge in `MissionResult.loot` mit Kennzeichen `elite: true`.

- **Elite-Stufen des Nutzers simuliert (24.10.2026, noch nicht gebaut):** Werte je Gegner [Rüstungsbonus VW, Körper-Ränge, Waffenbonus]: Elite Basis [+5, +2, +10], Leutnant [+5, +4, +10], Hauptmann (Leibwächter) [+10, +5, +10], Boss [+15, +7…8, +20]; Rüstungsklasse bleibt, Bonus über eigene Elite-Ausrüstung. Mitwachsen „zwischen A und B“, Squad des Nutzers, 30 Kämpfe. Siege (Ziel 70–75 %), Ø TP-Verlust:
  - „mittel“: Elite-Trupp (alle Basis) 73 %, 70 %; Kern mit Rest normal 90 %, 54 %; Kern mit Rest Basis 73 %, 71 %; Boss (Körper +7) + 2 Hauptleute 80 %, 64 %; Boss (Körper +8) 77 %, 64 %. Zum Vergleich ohne Elite: 97 %, 49 %.
  - „schwer“: Elite-Trupp 57 %, Kern mit Rest Basis 60 %, Boss (+8) 63 % (ohne Elite 90 %).
  - Kämpfe 21–23 Runden. Beute: eigene Elite-Einträge, 10–15 % der Elite-/Boss-Kämpfe (Nutzer).

- **Elite auf „schwer“ über die Gegnerzahl (24.10.2026, simuliert, noch nicht gebaut):** Entscheidungen des Nutzers: Kern = jeder 3. Leutnant, Rest Elite Basis; Boss-Körper wächst mit der Crew (4 + 9 × Mehrstärke, höchstens 10; Startcrew +4, Squad des Nutzers +8). Squad auf „schwer“ (sonst 9 Gegner), 30 Kämpfe: höchstens 8 Gegner → Elite-Trupp 67 %, Kern 63 %, Boss 77 % Siege (TP-Verlust 63–64 %); höchstens 7 Gegner → 90 %, 83 %, 87 % (54 %). Startcrew auf „mittel“ (ohne Mitwachsen, 6 Gegner): Elite-Trupp 57 %, Boss 47 % Siege, TP-Verlust 78–79 % (normaler Kampf Startcrew ca. 70 %).

- **Zusammensetzung je Stufe, Entwurf simuliert (24.10.2026, noch nicht gebaut):** Wunsch des Nutzers: Stufen unterscheiden sich in Anzahl und Stärke, je Stufe 4 Aufstellungen mit ähnlicher Schwierigkeit. Klassen nach Punkten: schwach ≤ 9 (Plünderer, Funke), mittel 10–11, stark ≥ 12 (Seherin, Handagent, Hexer, Brecher). Fehlt einer Fraktion eine Klasse, ersetzt der nächste Typ (schwächer als Veteran, stärker als Neuling). 16 Kämpfe je Fall, TP-Verlust Startcrew / Squad des Nutzers (mit Körper +3, Waffe +1):
  - leicht: L1 5 schwach (2 Neulinge) 28/13 %; L2 3 schwach + 1 mittel 24/9 %; L3 1 schwach + 2 mittel + 1 stark 33/10 %; L4 2 mittel (Veteranen) + 1 stark (Veteran) 24/9 %. Alle Siege 15–16/16.
  - mittel: M1 5 schwach + 2 mittel 60/24 % (Startcrew 11/16 Siege); M2 3 schwach + 2 mittel + 1 stark (Veteran) 68/23 % (11/16); M3 2 schwach + 3 mittel + 1 stark 67/24 % (10/16); M4 3 mittel (Veteranen) + 2 stark 52/22 % (14/16).
  - schwer: S1 4 schwach + 4 mittel + 1 stark 89/54 % (Startcrew 5/16, Squad 14/16); S2 2 schwach + 3 mittel + 2 stark (Veteranen) 79/48 % (9/16, 16/16); S3 2 mittel + 1 stark + 3 stark (Veteranen) 88/42 % (6/16, 16/16); S4 5 stark (Veteranen) 83/47 % (6/16, 13/16).
  - Befund: Anzahl wirkt stärker als Stärke der Typen. Ersatztypen häufig (viele Fraktionen ohne starke Typen). Für den Squad fehlt der Teil „mehr Gegner“ des Mitwachsens (feste Aufstellungen), er liegt hier unter dem Vorschlag von oben (mittel 22–24 % statt 49 %).

- **Entscheidungen des Nutzers zu Gegnern (24.10.2026, noch nicht gebaut, Gesamtpaket erst nach Simulation und Freigabe):**
  - Anzahl: leicht 5–7, mittel 6–9, schwer 8–12 Gegner. Weiter Budget-System, Grundbudget höher (Vorschlag leicht ~60, mittel ~80, schwer ~105, je Stufe Mindest-/Höchstzahl); Stufen kosten Punkte (Vorschlag Neuling −2, Veteran +3, Elite eigene Preise). Mission kann die Gegner vorgeben (Story, Boss).
  - Mitwachsen: nur TP (Körper-Ränge) und Fertigkeits-Ränge der Gegner, nicht Waffen/Rüstungen (deren Boni nur bei Elite). Alle Gegner Grundwert Körper +1 (+5 TP).
  - Elite-Stufen [Rüstungs-VW, Körper, Waffe]: Basis [+5, +2, +10], Leutnant [+5, +4, +10], Hauptmann [+10, +5, +10], Boss [+15, 4 + 9 × Mehrstärke höchstens 10, +20]; Elite-Boni fest (wachsen nicht mit). Kern = jeder 3. Leutnant, Rest Basis. Schwer: Elite/Boss höchstens 8 Gegner (alte Zählung). Eigene Elite-Ausrüstung als Einträge; Beute 10–15 % der Elite-/Boss-Kämpfe.
  - Gegnertypen: neue Standardwaffe Scharfschützengewehr (Werte wie Waffe des Nutzers: 50 m × 3 Stufen, min. 5 m, Schaden ×1,3, +10, Magazin 5, Patzer 4). Schatten = Scharfschütze-Meuchler (Scharfschützengewehr + Vibroklinge, Gewehre ~7, keine Rüstung); neuer Psi-Meuchler (Laserpistole, Psi-Angriff Rang 3, Ausw. ~50, keine Rüstung, ~12 Pkt.). Sicherheitsagent Gewehre +1; Sturmläufer mittlere Rüstung, Gewehre +2, Einhand +1; Hexer leichte Rüstung, Psi-Angriff +1; Plünderer mittlere Rüstung. Jede Fraktion mindestens ein starker Typ (offen: welche neuen Typen).

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
- **Elite-Wurf (Nutzer 24.10.2026):** Der Hub entscheidet schon beim Erstellen des Auftrags bzw. Feindkontakts (ca. 13 %), zeigt „Elite“ im Angebot und gibt nur „Elite ja/nein“ an den Kampf weiter. Boden wählt die Form selbst. Story kann Elite für eigene Missionen fest setzen.
- **Ablauf:** Bodenkampf und Raumkampf legen dieselbe Auswahl (Häufigkeit, Kennzeichen „Elite“ im Angebot/Kontakt) fest; Wer das Angebot erzeugt (Hub), bekommt die Kennzeichnung über den Koordinator. Erst Vorschlag mit Simulation an den Nutzer, dann bauen.

### Entscheidungen des Nutzers zum Balancing (24.10.2026)

1. **Gegner bekommen Ränge in Körper** (mehr TP), damit der TP-Abstand zur Crew kleiner wird.
2. **(a) Gegner wachsen moderat mit:** Die Mission kennt die Stärke der eingesetzten Crew (mehr/stärkere Gegner), aber nur so weit, dass Fortschritt spürbar bleibt. Schnittstelle Hub → `Mission.generate` vorschlagen; den Hub-Teil gibt der Koordinator weiter.
3. **Elite-Gegner** nach den gemeinsamen Regeln oben.
4. Nicht gewählt: Erschaffung/Körper der Crew ändern, Stufe „sehr schwer“. Steigerung bleibt wie sie ist.
5. **Ablauf:** erst Vorschlag mit Simulation (Siegquoten und TP-Verlust mit der Crew aus `spielstaende/24-10-2026/` und mit der Startcrew), an den Nutzer melden, erst nach Zustimmung bauen.

- **Freigabe (24.10.2026):** Vorschlag noch **nicht** freigegeben. Der Nutzer hat weitere Gedanken zum Elite-Status (nur Bodenkampf); erst danach bauen.

### Auftrag (24.10.2026): Elite und Boss fertig abstimmen

Gemeinsame Elite-Regeln stehen in `docs/module/bodenkampf.md` und `docs/module/raumkampf.md` (Abschnitt „Elite-Gegner“). Ergänzt vom Nutzer am 24.10.2026:
- **Boss-Kampf:** Boss + 2 Leibwächter + Fußvolk (Form „Anführer“ aus dem Bodenkampf-Vorschlag), Siegquote wie Elite (70–75 %). Kommt vor (a) am Ende jeder Story-Kette (je nach Kette am Boden **oder** im Raum mit Boss-Schiff) und (b) bei Hub-Aufträgen, deren Ziel eine Person ist (z. B. „Beseitigt den Gangsterboss“).
- **Beute bei Elite und Boss:** selten (nicht bei jedem Kampf), dann höchstens 2–3 Stück der besseren Ausrüstung, gern stark beschädigt. Boden: Waffen/Rüstungen. Raum: ab und zu eine beschädigte Schiffswaffe.
- **Elite-Wurf** beim Hub (beim Erstellen von Auftrag/Feindkontakt, ca. 13 %), Anzeige „Elite“ bzw. „Boss“ im Angebot.

1. **Bessere Rüstung für Elite mit dem Nutzer klären** (seine Bitte): Sie war gewünscht, ist im Vorschlag weggefallen, weil sie den Kampf stark verschoben hat. Zahlen zeigen, Nutzer entscheidet.
2. Form „Anführer“ als Boss-Kampf festlegen, die Story und der Hub können sie anfordern.
3. **Schnittstelle vorschlagen** (Hub → Mission): z. B. `elite: bool` und `form: StringName` (`""`, `&"trupp"`, `&"kern"`, `&"boss"`), dazu Beute im `MissionResult`. Dem Koordinator melden; erst nach Freigabe des Nutzers bauen.
