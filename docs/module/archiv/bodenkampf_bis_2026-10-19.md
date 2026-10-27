
## Erledigt (in `main` `dc2eb6d`)

- **Fertig (19.10.2026): Auftrag 1 Fraktions-Oberarten** (Entscheidungen des Nutzers: 2 je Oberart, Unterschied über Truppen, neue Gegnertypen, Eigenheit und Ausrüstung, Kartentypen bevorzugt; Namen und Eigenheiten wie in `docs/Skillsystem.md` 7.4). Neu: `FactionData.kind`/`trait_name`/`trait_text`/`trait_mods`/`weapon_swap`/`maps`, `UnitData.faction_trait`, `Combatant.faction_trait`/`trait_val()`; 6 Fraktionen (`semidrug`, `eisenwoelfe`, `schwarze_flagge`, `aasgeier`, `neuntes_haus`, `kinder_der_glut`), 5 Gegnertypen (`sicherheitsagent`, `sturmlaeufer`, `enterer`, `schatten`, `seherin`). Per Simulation abgestimmt (Crew-Siege „mittel“, je 24 Kämpfe, 71–92 %).
  - **An den Hub:** `Mission.sector_factions(rng)` (je Oberart eine) ersetzt in `core/sector.gd` `all_factions()` als Übergang, weil 10 Fraktionen sonst alle 10 Systeme belegen; `tests/test_hub.gd` entsprechend angepasst. Die Verteilung je Sektor (15–20 Systeme) entscheidet der Hub in seinem Auftrag 2 (Nutzer 19.10.2026). Legende der Sternenkarte (`ui/star_map.gd`) zeigt nur die Fraktionen des Sektors. **`MissionResult.loot_extra`** (Aasgeier 1): bitte in `HubState.set_loot` die Beuteplätze um diesen Wert erhöhen (`slots` = Figuren + `loot_extra`); bis dahin wirkt „1 Beute mehr“ nicht. `Voyage.PAY_FACTOR`/`LOOT_BONUS` kennen nur die alten IDs.
  - **An den Raumkampf:** neue Fraktions-IDs ohne Raumkampf-Seite (`data/ships/seiten/`): `semidrug`, `eisenwoelfe`, `schwarze_flagge`, `aasgeier`, `neuntes_haus`, `kinder_der_glut`. `SpaceTemplates.faction()` fällt dort auf `piraten` zurück; Entern gegen diese Fraktionen kämpft trotzdem gegen die richtige Bodenfraktion (`HubState.board_faction_path`).

## Erledigt (in `main` `1e02e7d`)

- **Fertig (19.10.2026): Auftrag 2 Entern-Briefing ohne Absagen.** Beim Entern (selbst entern und Abwehr, `Mission.boarding != ""`) zeigt das Briefing **„Ausrüstung“** (öffnet `ArmoryDialog.open_for(Campaign.crew())`, Charakter-Modul nur aufgerufen; nach „Fertig“ Runde 0 neu mit derselben Karte und dem neu ausgerüsteten Trupp, Briefing wieder offen) statt „Zurück ins Schiff“. Im Kampf heißt der Menüpunkt beim Entern nur „Rückzug“; in Runde 0 erscheint „Entern lässt sich nicht abbrechen“, `Battle.return_to_ship()` tut beim Entern nichts (Entscheidung des Nutzers: Runde 0 gesperrt). Rückzug ab Runde 1 unverändert. Keine Hub-Dateien geändert. Neu: Signal `BriefingDialog.equip`, `BattleUI.armory`.
- **Fertig (19.10.2026): Auftrag 3 Story-Fraktionen.** Oberart Story (`kind = &"story"`), vier Fraktionen (Wacht als zwei Fraktionen, Entscheidung des Nutzers): `stille_hand` (Die Stille Hand), `wacht_klingen` (Klingen der Wacht), `wacht_hirten` (Hirten der Wacht), `abteilung_9` (Abteilung 9); neue Gegnertypen `handagent` (D), `psi_soldat` (M). Eigenheiten in `docs/Skillsystem.md` 7.4. Story-Fraktionen kommen **nie** zufällig (`Mission.generate` ohne Fraktion schließt sie aus) und nicht in `Mission.sector_factions`; Story-Einsätze geben die Fraktion als Pfad mit (`Mission.generate(seed, diff, "res://data/missions/<id>.tres")`). **An Story-Chat und Raumkampf:** diese IDs; Semidrug Inc. heißt `semidrug`, Vantar `konzern`. Raumkampf-Seiten für die Story-Fraktionen gibt es noch nicht.

## Erledigt (in `main`, Merge von `c1a2dcb`)

- **Fertig (19.10.2026): Auftrag 4 Fehlermeldung beim Briefing.** Ursache war der Test `_test_boarding_briefing` in `tests/test_rules.gd`, nicht das Spiel: Er hängte das Briefing in `_init` an die Wurzel und rief `_ready()` von Hand auf; beim Start der Hauptschleife lief `_ready` ein zweites Mal (doppelte Verbindung von `resized`). Jetzt wird das Briefing nicht in den Baum gehängt, `_ready` läuft einmal, danach `free()`. `ui/modal.gd` unverändert. Die Meldung ist weg; übrig sind nur die bekannten Meldungen beim Beenden (Speicher noch belegt).

## Erledigt (in `main`, Merge von `e635702`)

- **Auftrag 5 (19.10.2026): Farbe der Eisenwölfe.** Meldung des Hubs: Die Eisenwölfe haben die Kartenfarbe Grau (0,6/0,62/0,66) und sind auf der Sternenkarte kaum von neutralen Häfen (`UiTheme.MUTED`) zu unterscheiden. Bitte eine Farbe wählen, die sich von allen anderen Fraktionsfarben und von `MUTED` abhebt, und dem Nutzer zeigen.
  - **Fertig (19.10.2026):** Eisenwölfe Magenta `Color(0.92, 0.35, 0.72)` (vorher Grau, Abstand im RGB-Raum zu `UiTheme.MUTED` 0,11, jetzt mindestens 0,36 zu jeder Farbe). Auf Wunsch des Nutzers zusätzlich: Kinder der Glut Gold `Color(1, 0.8, 0.15)` (vorher Orange wie Rote Sonne), Abteilung 9 Kobaltblau `Color(0.3, 0.4, 1)` (vorher Hellblau wie Konzern), Neuntes Haus Violett `Color(0.6, 0.25, 0.85)` (vorher Graulila, Abstand zu `MUTED` 0,14). Nur `data/missions/*.tres`, keine Schnittstellenänderung.

## Erledigt (in `main`, Merge von `204d874`)

- **Auftrag 6 (19.10.2026): Karte per Touch drehen** (Wunsch des Nutzers nach Tests am Tablet, `docs/module/export.md` Punkt 6). Heute nur Q/E. Entscheidung des Nutzers: **Zwei-Finger-Drehen und dazu Drehknöpfe ⟲ ⟳**, die nur auf Touch-Geräten erscheinen (`DisplayServer.is_touchscreen_available()`). Dazu `_touch_input` in `view/battle.gd` erweitern; Zoom und Drehen dürfen sich nicht stören. Gilt auch für den Karteneditor (3D-Ansicht), falls dort einfach möglich. Am PC ändert sich nichts. `ui/modal.gd`, `ui/ui_theme.gd` und `ui/ui_scale.gd` nicht anfassen (Export Auftrag 1).
  - **Fertig (19.10.2026):** Zwei-Finger-Drehen in `Battle._touch_input`/`_pinch`: Jede Zwei-Finger-Geste entscheidet sich zuerst für Drehen (ab 25° Fingerdrehung) oder Zoom (ab 12 % Abstandsänderung) und bleibt bis zum Loslassen dabei; gedreht wird in 90°-Schritten wie Q/E (erster Schritt bei 25°, danach je weitere 90°), Finger im Uhrzeigersinn = Karte im Uhrzeigersinn. Drehknöpfe ⟲ ⟳ (`IconButton` `rot_l`/`rot_r`) links in der Leiste oben rechts (`TopMenu`) und im Karteneditor neben „3D“ (nur in der 3D-Ansicht), nur wenn `TopMenu.touch_ui()` (`DisplayServer.is_touchscreen_available()` oder Startoption `--touch`). Im Karteneditor nur die Knöpfe, kein Zwei-Finger-Drehen: Dort malt der erste Finger über die Maus-Emulation, eine Drehgeste würde mitmalen. Test `--autotest-touch` (`tests/autotest.gd`). Am PC ohne Touchscreen unverändert. `modal.gd`, `ui_theme.gd`, `ui_scale.gd` nicht angefasst.

## Früherer Stand (archiviert 19.10.2026)

## Stand

- Alle Aufträge bis 18.10.2026 erledigt und in `main`, zuletzt `bb89c03`: Kartentypen Bar, Straße, Tempel, Büro, Raumschiff-Inneres (`core/map_types.gd`, `core/maps/`, Entern/Abwehr im Raumschiff über `HubState.mission_of()`), Startlagen je Auftrag (Standard, Hinterhalt, Zange, Verteilte Gegner, Verteidigung), Steuerung Tab/F/Leertaste. Danach (`e931e13`): Truppgröße nach Schwierigkeit (schwer bis 8, `Campaign.max_squad`, Budget schwer 88). Danach (`16ac931`): Wände sperren Sicht und Druckwelle immer. Danach (`7f95a11`): **Karteneditor** (`map_editor.tscn`, `view/map_editor.gd`, `core/custom_maps.gd`, Startmenü „Karteneditor“, Draufsicht/3D, eigene Karten in `user://maps/`, je Karte an/aus, Pool-Chance 30 %; Schnittstellen `Mission.custom_map`, `CustomMaps.for_mission`). Danach (`514a72b`): Startausrichtung zum Gegner in allen Lagen, neue Lage „Überfall“ (Gegner in der Mitte, schauen weg, handeln in Runde 1 nicht). Details im Archiv. Verlauf im Archiv (siehe oben), Zusammenführungen in `docs/Zusammenfuehrung.md`.
- Neue Fertigmeldungen hier kurz eintragen (Commit, was neu, Schnittstellenänderungen). Erledigtes verschiebt der Koordinator nach jeder Zusammenführung ins Archiv.



## Balancing, Elite, Boss (24.10.2026, erledigt mit `86cf0e8`)

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

### Freigabe Balancing-Paket (24.10.2026)

**Schnittstellen bestätigt (Koordinator mit Nutzer, 24.10.2026):**
- Mission-Feld `elite: StringName` = `""` | `&"elite"` | `&"boss"` (Form Trupp/Kern/Boss wählt der Bodenkampf). Raum: `setup.enemy.elite`/`boss`/`boss_name` (schon in `main`).
- Spieleinstellung **„Schwierigkeitsgrad“** leicht ×0,8 / normal ×1,0 / schwer ×1,25, gilt für **Boden und Raum** (Nutzer). Hub speichert sie und gibt sie an `Mission.generate` und an den Raumkampf (`setup.difficulty_factor: float`, fehlend = 1.0) weiter.
- Elite-Beute: `MissionResult.loot`-Einträge mit `elite: true`. Im Handel **verkaufen ja, kaufen nein** (Nutzer).
- Elite-/Boss-Anzahl auf „schwer“ klärt der Nutzer direkt mit dem Bodenkampf.

Bodenkampf-Teil in Schritten bauen (Nutzer hat das Paket mit dir abgestimmt). Jeden Schritt mit Tests melden.
  - **Schritt 1 gebaut (`68a7e6a`):** Gegnertypen, neue Typen, Scharfschützengewehr, Preise, Körper 1.
  - **Schritt 2 gebaut:** Budget 55/75/100, Anzahl 5–7/6–9/8–12, Neuling/Veteran mit Preis, `Mission.MAX_ENEMIES` 12, `MIN_START_FIELDS` 9 (Karten, eigene Karten, Editor), Ersatzaufstellung `Combat._place_enemies`, Schwierigkeitsfaktor als 4. Parameter von `Mission.generate` (wie vom Hub erwartet).
  - **Schritt 3 gebaut:** Mitwachsen `Mission.grow(enemies, crew)` / `Mission.extra_strength(crew)` in `Battle.new_battle` (Körper +round(7·m), Waffenfertigkeiten +round(2·m)), Hinweis im Kampflog.
  - **Schritt 4 gebaut:** Elite/Boss wie in der README (Elite-Ausrüstung `data/weapons/elite`, `data/armor/elite`; `Mission.generate(…, elite)`, `Mission.elite`/`elite_form`; Beimischung `ELITE_MIX`; Elite-Beute 12 %, `loot[].elite`; Kennzeichnung Briefing und Namensschild). Schnittstellen für den Hub: `Mission.generate(seed, diff, faction_path, diff_factor, elite)`; das Feld `Mission.elite` ist ein Setter (auch nachträglich über `Elite.apply`, Gegner fest aus dem Seed neu); Elite-Stücke im Lager über Metadaten `elite` (verkaufen ja, kaufen nein – Hub); Preis der neuen Waffe/Elite-Stücke fehlt in `Stock.PRICES` (Hub/Charakter).

### Hub-Seite fertig (24.10.2026, `44c0514`)

Der Hub ruft `Mission.generate` mit dem Schwierigkeitsfaktor als 4. Parameter (sonst Feld `difficulty_factor`) und setzt `Mission.elite`, sobald es das Feld gibt. Neue Klasse `Elite` (`core/elite.gd`: `roll`, `label`, `boss_name`, `LEVELS`, `generate`, `apply`). Kopfgeld-Aufträge (10 % der Bodenaufträge) haben Stufe `boss`. Elite-Ausrüstung bitte als eigene Einträge liefern (`/elite/` im Pfad oder Feld `elite`), Hub erkennt sie über `Stock.is_elite`.

- **Fertig (24.10.2026, Balancing-Paket Boden):** Schritte 1–4 gebaut, main eingemischt, an die Hub-Schnittstelle angepasst (`Mission.generate(…, diff_factor, elite)`, Setter `Mission.elite`). Prüfung mit dem echten Code, Squad des Nutzers, 30 Kämpfe: normal leicht 30/30 (25 % TP-Verlust), mittel 30/30 (42 %), schwer 19/30 (75 %); Elite leicht 27/30 (49 %), mittel 23/30 (67 %), schwer 15/30 (80 %); Boss leicht 30/30 (41 %), mittel 27/30 (56 %), schwer 20/30 (67 %). Offen für andere Module: Preise für Scharfschützengewehr und Elite-Stücke in `Stock.PRICES` (Hub/Charakter).



### Auftrag (24.10.2026): Schild als Beute (erledigt, `7462c15`)

Wunsch des Nutzers: Gegner mit Schild können ihn nach dem Kampf fallen lassen (wie andere Beute, Häufigkeit sinnvoll wählen). Im `MissionResult.loot` mit dem Schlüssel `Equipment.SHIELD` liefern; der Hub nimmt ihn ins Lager (Hub Auftrag 11). Tests nach CLAUDE.md, Fertigmeldung.

- **Fertig (24.10.2026):** Schildträger = Gegner nur mit einhändigen Waffen (Nutzer): Klingentänzer, Handagent, Hexer, Seherin, Psi-Meuchler (`shield = true`; bei Waffentausch auf zweihändig entfällt er, `Mission._individualize`). Beute: 30 % je besiegtem Schildträger (`Combat.SHIELD_LOOT_CHANCE`), `loot`-Eintrag `{key: Equipment.SHIELD, name: "Schild", count: 1}` ohne `damage`. Test `_test_shield_loot`.



### Auftrag (27.10.2026): Psi-Liste „Stärkung“ im Kampf (erledigt, `2ff16dd`)

Neue Liste, vom Nutzer beschlossen: Regeln in `docs/Skillsystem.md` 6.1, Abschnitt „Stärkung“ (9 Kräfte, Stufen 1–8 und 10). Anfrage des Charakter-Moduls: `docs/module/charakter.md`, „Anfragen an andere Module“.
1. Kräfte in `core/psi_combat.gd` (`SUPPORT`, Schlüssel `lStaerkung/<Stufe>`) und ihre Wirkung (`Combatant.buffs`) einbauen.
2. Prüfen und, wenn zu aufwendig, **dem Nutzer zurückmelden statt still ändern**: Aktivität über 100 % (Stufe 8), TP-Puffer (Stufe 7), Bonus auf Eigenschaften (Stufe 5).
3. Balancing mit `test_sim` (Zahlen sind ein Entwurf). Tests nach CLAUDE.md, Fertigmeldung mit den Schlüsseln, damit das Charakter-Modul die Liste danach lernbar macht.

- **Gebaut (27.10.2026):** Schlüssel `lStaerkung/1` Fokus, `/2` Wachheit, `/3` Leichter Schritt, `/4` Klarer Kopf, `/5` Kraftfluss, `/6` Zielsicherheit, `/7` Zähigkeit, `/8` Beschleunigung, `/10` Gemeinsamer Wille (Ziele self/self/ally/ally/ally/ally/ally/ally/area). Alle drei Prüfpunkte gebaut, keiner zu aufwendig: 110 % Aktivität (`_begin_turn`, Ausweichen höchstens 100 %), TP-Puffer (`Combat._hurt` an allen Schadensstellen), STÄ/GEW-Bonus (`Rules.attr_bonus_of` in `skill_total`, `initiative_bonus`, `free_hexes`). KI-Regel in `CombatAI._psi_step`. Test `_test_staerkung`. Charakter-Modul kann die Liste jetzt in `PsiLists.LISTS` eintragen (Stufen 1–8, 10); `PsiCombat.known` findet die Schlüssel dann von selbst. Balancing (KI gegen KI, „mittel“, 30 Kämpfe, Psi-Figur mit allen 9 Kräften): Squad des Nutzers ohne/mit 29/30 bzw. 28/30 Siege, TP-Verlust 43/44 % (ca. 2 Stärkungen je Kampf); Startcrew 10/30 → 15/30 Siege, 89 → 86 %. Zahlen des Entwurfs bleiben; die Wirkung ist spürbar, aber nicht übermächtig.



### Auftrag (27.10.2026): Mockup Comic-Shader – nichts bauen (vom Nutzer verworfen 27.10.2026; Probe A Nachbearbeitung, B Material-Shader gezeigt, nichts committet)

Wunsch des Nutzers: bessere Grafik, **kostenlos**, in Godot bleiben. Idee: Comic-Look per Shader passend zu den Story-Bildern (`docs/Story_Bilder.md`: Graphic Novel, klare Linien, Schraffur, kräftige Schatten).
1. Probe auf einer Kampfszene (eigene Testszene oder Testcode, **nicht** in den Spielcode übernehmen): Konturen, Cel-Shading (wenige harte Lichtstufen), optional Schraffur in Schatten.
2. Screenshots nebeneinander: jetziger Stand / Comic-Look, je mit Renderer „Compatibility“ (jetzt) und, wenn möglich, „Forward+“ bzw. „Mobile“. Bilder ins Repo (z. B. `docs/mockups/comic/`) oder als Artifact.
3. Kurz einschätzen (Wissen/Annahme getrennt): Aufwand für Boden, Hub-Schiff und Raumkampf, Leistung am Tablet (nur Annahme ohne Gerät), was mit den Quaternius-Modellen gut/schlecht aussieht.
4. Ergebnis an den Nutzer, Entscheidung abwarten.

