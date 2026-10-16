# Past the Frontire – Godot-Version (Godot 4.7)

Rundenbasierter Bodenkampf im RMSS-Stil, 6 Crewmitglieder gegen eine zufällig zusammengestellte Gegnergruppe (3–9 Figuren) in einer zufällig erzeugten Lagerhalle (3D, isometrische Kamera).
Regeln wie in der HTML-Version (docs/Skillsystem.md): W100 aus zwei W10, offen nach oben und unten, Angriffstabellen, Kritische Treffer, Aktivitätssystem, Feuerbereitschaft, Blickrichtung, Deckung, Ducken, Abwarten, Erste Hilfe, Psi-Schild, Erfahrung nur für Benutztes.

## Starten (Windows 11, GitHub Desktop)

1. GitHub Desktop: *File → Clone repository* → `past_the_frontire`, Branch `claude/confident-edison-6mxzke`.
2. Godot 4.7 starten → *Importieren* → `godot/project.godot`.
3. **F5** startet das Spiel.

Neuer Stand: *Fetch origin* → *Pull origin*, dann F5. Fehlermeldungen bleiben sichtbar, wenn Godot über `Godot_v4.7.2-stable_win64_console.exe` gestartet wird.

## Spielablauf: Startmenü und Schiff (Hub)

F5 startet das **Startmenü** (`start.tscn`): Fortsetzen (zuletzt gespeicherter Spielstand), Neues Spiel (Slot wählen und benennen, dann die Crew aus dem Roster wählen: `CrewPicker` des Charakter-Moduls, 1–8 Figuren), Laden, Roster (`roster.tscn`, Charakter-Modul), Schnellkampf (einzelner Bodenkampf mit den Figuren des Rosters, Trupp im Briefing; nichts wird verbucht, danach zurück ins Startmenü), Einstellungen (Ton, Würfelanimation, **UI-Größe** 75/90/100/125 %), Beenden. Die UI-Größe (`ui/ui_scale.gd`, gespeichert in `user://ui.cfg`) skaliert alle Oberflächen im ganzen Spiel über `Window.content_scale_factor`; die 3D-Ansicht bleibt gleich. Auch im Schiff über das Menü oben rechts („UI-Größe …“).

Das **Schiff** (`hub.tscn`) ist die zentrale Szene zwischen den Einsätzen: ein 3D-Deck mit vier Räumen, Kamera wie im Bodenkampf (ziehen, WASD, Mausrad, Q/E). Raum anklicken (oder Knopf unten links):

| Raum | Was dort passiert |
|---|---|
| Brücke | **Sternenkarte** des Sektors: 10 zufällige Systeme, jedes von einer Fraktion kontrolliert (2 neutral, darunter der Heimathafen), Sprungrouten mit 1–3 Reisetagen. System anklicken zeigt Route, Ankunftstag und Aufträge. „Kurs setzen“ fliegt hin (Tage vergehen), „Hinfliegen & Briefing“ nimmt den gewählten Auftrag an und startet den Bodenkampf. **Hafen** (neutrale Systeme, wenn das Schiff dort liegt): Anheuern aus der Liste „im Hafen“ (entlassene Figuren mit Fortschritt) und aus dem Roster (Kopie mit Roster-Stand), nur bei freiem Platz an Bord (`Campaign.hire()`). Reiter **Raumhafen**: Tanken (immer, auch auf Notkredit), Werft (große Reparatur), Schiffsmaterial kaufen, Munition kaufen/verkaufen. **Handel …** (`ui/trade_dialog.gd`, `core/stock.gd`): Waffen, Rüstungen, Schilde, Medikits aus dem wechselnden Sortiment ins **Lager** kaufen, aus dem Lager verkaufen (50 %); beschädigte Stücke liegen einzeln mit Schaden im Lager (Schlüssel „Grundschlüssel|Schaden“), verkaufen sich je −10 um 25 % billiger und lassen sich in der **Werkstatt** gegen Credits ganz reparieren (10 % vom Kaufpreis je −10, nach Handeln). Nach einem Sieg zeigt der Einsatzbericht die **Beuteauswahl** (1 Stück je Crewmitglied im Einsatz, Rest als Schrott 15 %, Medikits ins Lager; offene Auswahl `HubState.loot_pending` im Spielstand). Beim Kurs: geschätzter Treibstoff und die **Reiseposten** (wer welche Reiseprobe würfelt); oben „Große Reparatur (1 Tag)“ durch die Crew. |
| Crewquartiere | Charakterübersicht des Charakter-Moduls (`CrewOverview`, nach einem Einsatz mit dessen Ergebnis): Ränge kaufen, Eigenschaften steigern, freie EP einzahlen, Charakterbögen, Entlassen; Plätze an Bord aus `HubState.berths`. „Crew zurücksetzen“ und „Anheuern“ gibt es im Schiff nicht (neues Spiel beginnen bzw. Anheuern im Hafen). „Speichern & zurück“. |
| Krankenstation | Patienten (`Campaign.patients()`) mit Stufe und Resttagen, Personal zuweisen (bis 2): wer die höhere **Zweite Hilfe** hat, ist **Arzt** (voller Bonus, bleibt beim Einsatz an Bord, in der Truppwahl gesperrt), der andere **Helfer** (halber Bonus). Jeden Tag mit Patienten eine Probe W100 offen + Arzt + Helfer/2: ab 100 heilt ein Tag zusätzlich, ab 150 zwei; Personal bekommt je Behandlungstag 1 EP in Zweiter Hilfe. Protokoll der letzten Tage, „1 Tag warten“ (`core/medbay.gd`, `ui/medbay_dialog.gd`). |
| Waffenkammer | Ausrüstung ändern (Waffe 1/2, Rüstung, Schild): öffnet den `ArmoryDialog` des Charakter-Moduls mit `open_for(Campaign.crew(), 0)`; „Fertig“ speichert. |
| Maschinenraum (früher Hangar) | **Schiffsausbau** (`core/ship_upgrades.gd`, `ui/engine_dialog.gd`): Plätze an Bord, Tank, Hülle, Antrieb, Systeme, Krankenstation, Trainingsraum je 3 Stufen; Werft im Hafen (Credits, sofort) oder Crew (Schiffsmaterial und Tage, Reparaturprobe am Ende, ein Ausbau zur Zeit). Regeln `docs/Skillsystem.md` 8b. |

Oben links Spielstand, Tag, Position und offene Aufträge, darunter **Credits, Treibstoff, Hülle, Material** und Warnungen (Treibstoff knapp, Tank leer, Hülle 0, Notkredit); oben rechts Speichern, Laden, Menü (Hauptmenü, Ton, Bedienung) und der Infokasten zum Raum unter der Maus.

**Aufträge und Zeit** (`core/hub_state.gd`): „1 Tag warten“ (Brücke oben oder Krankenstation) lässt einen Tag vergehen. Jeder vergangene Tag (Reisen, Einsatz, Warten) läuft über `HubState.advance_days()`: Probe der Krankenstation, Heilung über `Campaign.pass_days(1, Zusatztage)`, Meldung „wieder einsatzbereit“. immer 4 offene Aufträge, nur in Systemen mit Fraktion (höchstens 2 je System), Gegner = Fraktion des Systems, Laufzeit 4–10 Tage. Reisen kostet die Reisetage der kürzesten Route; abgelaufene Aufträge verschwinden, neue kommen dazu. Ein Auftrag lässt sich nur annehmen, wenn das Schiff vor Ablauf ankommt. Ein Einsatz dauert 1 Tag; danach ist der Auftrag erledigt (auch bei Niederlage).

**Enzyklopädie** (`ui/encyclopedia.gd`, Planung `docs/Planung_Enzyklopaedie.md`): Waffen (auch eigene) mit Werten und Angriffstabelle, Rüstungen, Angriffstabellen, Kritische Treffer, Patzer, Psi-Listen, Fertigkeiten (mit Kurzbeschreibung, `core/skill_texts.gd`), Kurzregeln (Abschnitte aus `docs/Skillsystem.md`, im Spiel formatiert); Suche über alle Bereiche, Verweise anklickbar. Im Startmenü und im Schiff über das Burgermenü oben rechts.

**Eigene Waffen und Rüstungen** (Startmenü „Ausrüstung“, `ui/gear_editor.gd`, Regeln `core/gear.gd`, Planung `docs/Planung_Ausruestungs_Editor.md`): neu aus einer Vorlage (mitgelieferte Waffe/Rüstung), Name, Fertigkeit, Angriffstabelle, Modell aus dem Katalog `WeaponModels` (Schusswaffen bzw. Nahkampfwaffen; setzt Länge, Griff, Hände und den vorgeschlagenen Klang), Klang aus `WeaponData.SOUNDS` (mit Anhören, „automatisch“ = aus den Werten), ein-/zweihändig frei; Zahlenwerte in Grenzen um die Vorlage (Reichweite, Mindestabstand, Magazin, Munition ±50 %, Stufen ±1, Höchstergebnis ±10, Patzer ±2, Schaden ±0,2, Angriffsbonus und Druckwelle ±10; Rüstung: Klasse wie Vorlage, Verteidigung ±5, Bewegung ±1) oder „Werte frei eintragen“ (Vermerk „frei“); „Auch für Gegner“ mit Fraktionen. Global gespeichert als `user://gear/weapons/*.tres` und `user://gear/armor/*.tres` (Spielstände und Roster speichern sie wie die mitgelieferten per Pfad).

**Musik** (`audio/music.gd`, Autoload `Music`): ein Ordner je Anlass unter `audio/music/` – `start` (Startmenü, Roster), `ship` (Schiff, Sternenkarte), `briefing` (Briefing und Aufstellung), `battle` (ab Runde 1), `victory`, `defeat`. MP3 oder OGG einfach in den Ordner legen; mehrere Stücke wechseln zufällig, ein einzelnes läuft in Schleife, Wechsel werden überblendet (1,5 s); leerer Ordner = Stille. Lautstärke **Musik** und **Effekte** (0–100 % in 10er-Schritten, Busse „Music“ und „SFX“, gespeichert in `user://audio.cfg`) in den Einstellungen im Startmenü und im Schiff (Menü „Einstellungen …“).

**Reise, Schiff, Credits** (`core/voyage.gd`, Regeln `docs/Skillsystem.md` 8b): je Reisetag Proben in Pilot, Navigation, Computer und Reparatur (Station, sonst die Besten; nicht die Krankenstation), erfolgreiche Proben sparen Treibstoff, die Reparaturprobe ändert die Hülle; nach jeder Reise ein **Reisebericht** (vor einem Einsatz führt „Weiter“ ins Briefing). Leerer Tank oder Hülle 0: nur Kurs zum nächsten Hafen. Lohn und Beute (Schiffsmaterial) bei Sieg nach Schwierigkeit und Fraktion, im Einsatzbericht. Werte im Spielstand (`HubState.credits`, `fuel`, `hull`, `material`, `emergency`, `ammo`). **Munition:** Schiffsvorrat je Art (`HubState.ammo`, Arten `Ammo.TYPES`), Anzeige in der Statusleiste, Kauf im Raumhafen, Verbrauch nach dem Einsatz abgezogen (`MissionResult.ammo_used`), bei Sieg etwas Munition als Beute.

**Nach dem Einsatz** geht es direkt zurück ins Schiff mit einem **Einsatzbericht** (Sieg/Niederlage, Zustand und Fertigkeits-EP je Figur). Verbucht wird wie im Charakter-Modul über `MissionResult` → `Campaign.finish_mission()` (Fertigkeits-EP, 3 freie EP + Missionsbelohnung bei Sieg); der Bericht wird aus demselben `MissionResult` erstellt. Ausgeben lassen sich die freien EP in den Crewquartieren. „Einsatz abbrechen“ (Menü im Kampf) bzw. „Zurück ins Schiff“ im Briefing beendet den Einsatz ohne Ergebnis, der Auftrag bleibt offen.

**Spielstände** (`core/save_slots.gd`): 3 benannte Slots in `user://saves/slot_N.json`, jeweils mit dem Spiel im Schiff (Tag, Sektor, Position, Aufträge) und dem Fortschritt der Crew. Gespeichert wird nur im Schiff und nur von Hand. Der globale Roster (`user://roster.json`) gehört zu keinem Spielstand und wird nicht in die Slots kopiert. Der laufende Fortschritt der Crew liegt weiter in `user://crew.json`; Laden überschreibt ihn mit dem Stand des Slots und lädt die Crew neu (`Campaign.reload()`); Speichern ruft vorher `Campaign.save()`.

## Bedienung

| Aktion | Maus / Tastatur | Handy / Tablet |
|---|---|---|
| Bewegen | Gangart wählen, blaues Feld anklicken | Feld antippen (Vorschau), nochmal antippen |
| Angreifen | Aktivität wählen (20–100 %), rot umrandeten Gegner anklicken | Gegner antippen, nochmal antippen |
| Vorschau | Maus über ein blaues Feld: grüner Ring + ◎ = von dort treffbar, roter Ring + ⚠ = wer dich dort trifft | erstes Antippen |
| Drehen | Rechtsklick auf ein Feld oder „Ausrichten“ | lange drücken |
| Kamera | Ziehen (links/Mitte), WASD/Pfeile, Mausrad = Zoom, Q/E = um 90° drehen | ein Finger ziehen, zwei Finger zoomen |
| Zug beenden | Enter oder Button | Button |
| Reichweite / Raster | R / G | Buttons |
| Abbrechen | Esc | – |

Die Karte nutzt den ganzen Bildschirm, die Bedienung schwebt darüber:
- oben links die Initiative-Leiste (Einspringen nach dem Abwarten),
- oben rechts Runde/Auftrag und Symbolknöpfe (Charakterbogen, Tabellen = Enzyklopädie des Hubs bei der gewählten Waffe bzw. Psi-Liste, KI für Crew, Ton, Würfel, Menü mit Neue Mission, Raster, Reichweite, UI-Größe, Enzyklopädie, Bedienung),
- darunter rechts die **Seitenleiste** (kompakte Kampf-UI, Variante C): Figurenkarte (TP/PP/Aktivität, AW/VW/INI, Bogen), dann Abschnitte Waffe (mit Psi-Angriffskräften), Gangart, Angriffsaktivität, Psi (Reiter je Liste) und Aktionen (Ducken, Abwarten, Feuerbereit, Nachladen, Erste Hilfe, Ausrichten) – Waffen mit Feuerstoß zeigen „×3“, mit Magazin „geladen/Magazin“ bzw. „ohne Munition“ (Munition: `core/ammo.gd`, Schiffsvorrat je Art, 3 Magazine je Waffe, Hinweise im Briefing), jeder per Klick auf die Überschrift ein-/ausklappbar (gespeichert), unten immer „Zug beenden“; in Runde 0 die Aufstellung; ist die KI am Zug, nur deren Figurenkarte. Der Knopf „›“ klappt die ganze Leiste ein (Enter beendet weiter den Zug),
- links neben der Leiste der Infokasten für das Feld bzw. die Figur unter der Maus (auf Touchgeräten mit „Ausführen“),
- unten links Würfel und Kampflog (eingeklappt eine Zeile, „Log ▴“ klappt den Verlauf auf).

Basisauflösung der Oberfläche ist 1600×900 (Fenster 1600×900); größere Bildschirme skalieren die Oberfläche mit.

## Ablauf eines Einsatzes

1. **Briefing** in zwei Spalten: links Auftrag, Gegnergruppe (Fraktion, Typen, Ausrüstung), Schwierigkeit, Hallengröße, Belohnung; rechts die **Truppwahl** (bis 6 Kacheln mit Rolle, TP/PP, Waffen, Rüstung, Zustand; Kachel anklicken = dazu/heraus). Vorbelegt ist der letzte Trupp ohne Gesperrte, aufgefüllt; Gesperrte (kampfunfähig, schwer verwundet, Arzt der Krankenstation) sind ausgegraut, Angeschlagene markiert; Warnung bei weniger als 6. Schnellkampf: Figuren aus dem Roster, die 6 Startfiguren vorbelegt. „Andere Mission“ würfelt neu (Schwierigkeit wählbar oder zufällig). Ein anderer Trupp baut Runde 0 mit derselben Karte neu auf; das Briefing lässt sich in Runde 0 wieder öffnen.
2. **Runde 0 – Aufstellung**: Figur anklicken (oder im Panel wählen), dann ein blaues Feld im Eingangsbereich (Spalten 1–4 links): dorthin stellen, mit einer anderen Figur der Crew wird getauscht. Blickrichtung per Rechtsklick / lange drücken / „drehen“. „Kampf beginnen“ (oder Enter) startet Runde 1.
3. **Kampf** bis alle Gegner oder alle Crewmitglieder ausgeschaltet sind. Psi-Figuren haben in der Seitenleiste einen Abschnitt Psi mit Reitern je Liste (Kräfte nach Rang; Angriffskräfte wie eine Waffe wählen, unterstützende Kräfte wirken sofort oder auf ein angeklicktes Ziel); Rechtsklick bzw. langes Tippen auf eine Figur öffnet ein Kontextmenü mit den Kräften, die auf sie passen (auf ein leeres Feld: drehen). Über der Figur am Zug schwebt ein Schild „Name · am Zug“ mit Pfeil in der Farbe der Figur, 60 % deckend (bei Gegnern mit rotem Rand), die Namensschilder der anderen (in der Farbe ihrer Figur) sind leicht abgedunkelt. Über jedem Namensschild zeigen farbige Symbole mit Zahl die Zustände (sterbend/stabilisiert/bewusstlos, Blutung, benommen, Wunden, entwaffnet, niedergeworfen, Psi-Schild, Psi-Verstärkung, Psi gegen die Figur, feuerbereit, abwarten; höchstens 5, sonst „+N“), dazu Effekte an der Figur (Bluttropfen, kreisende Sterne, roter/grüner Fleck bei Sterbenden, blaue Blase beim Psi-Schild, violetter Ring bei Verstärkung, Figur kippt bei Niedergeworfen; `view/status_icons.gd`, `status_row.gd`, `status_fx.gd`); in Runde 0 zeigt es „Name · aufstellen“. Am Ende zeigt ein Ergebnis-Banner über der Karte Sieg, Niederlage oder Rückzug mit Bilanz (Runden, ausgeschaltete Gegner, Ausfälle, freie EP); erst „Weiter“ (oder Enter) wechselt die Szene. Aus dem Schiff gestartet heißt „Neue Mission“ im Menü „Einsatz abbrechen / Rückzug“: vor Runde 1 nach Rückfrage zurück ins Schiff (Auftrag bleibt offen), ab Runde 1 nach Rückfrage Rückzug (zählt als Niederlage: Auftrag verloren, Zeit vergeht; EP aus dem Kampf bleiben). Schnellkampf aus dem Startmenü: kein Banner, nichts wird verbucht; eine Zeile im Kampflog, nach 2,5 s zurück ins Startmenü.
4. **Charakterübersicht = Aufleveln** (eigene Szene `crew.tscn`, das Charakter-Modul): Das Ergebnis des Kampfes ist dort schon verbucht und gespeichert. Reiter (oder Pfeiltasten) blättern durch die Crew. Je Figur: drehende 3D-Vorschau, Name, Kürzel, Farbe, Station und Aussehen änderbar, Psi-Kräfte der gelernten Listen. Keine Ranggrenze; neue Psi-Liste: erster Rang doppelt, höchstens eine neue Liste pro Levelphase (`Character.new_list`, nach jedem Einsatz geleert). Ränge kaufen (fehlende EP kommen aus den freien EP), Eigenschaften mit freien EP um +1 steigern, „zurücknehmen“ macht die Steigerungen der Figur rückgängig. Nicht ausgegebene freie EP bleiben gespart. „Neues Crewmitglied“ öffnet den Charakter-Editor (siehe unten). „Speichern & nächste Mission“.

## Roster und Crew

- **Globaler Roster** (`roster.tscn`, `ui/crew/roster_screen.gd`, Speicher `user://roster.json` über `core/global_roster.gd`): die 6 Startcharaktere (schreibgeschützt) und alle selbst erschaffenen Figuren, unabhängig von Spielständen. Eigene Figuren: „Name & Aussehen“ (Werte bleiben fest), „Kopieren“ (auch Startcharaktere), „Löschen“; „Charakterbogen“ (alle Figuren, auch Startcharaktere) zeigt den vollständigen Bogen; „+ Neue Figur erschaffen“ öffnet den Charakter-Editor.
- **Neues Spiel:** `CrewPicker` (`ui/crew/crew_picker.gd`) wählt 1 bis 8 Roster-Figuren (jede einmal), `Campaign.new_game(picked)` legt Kopien als Crew an. Der Roster bleibt unverändert.
- **Im Spiel:** „Entlassen“ in der Charakterübersicht; Entlassene warten mit ihrem Fortschritt „im Hafen“ (`Campaign.harbor()`) und können dort wieder angeheuert werden (`Campaign.hire()`, Oberfläche auf der Brücke im Hafen vom Hub).
- **Einsatz:** bis zu 6 Figuren (`Campaign.squad()`); Truppwahl im Briefing mit `Campaign.candidates()` (Sperr-Status) und `set_squad()`, der letzte Trupp wird gespeichert.
- **Verwundung** (`core/injury.gd`, Regeln `docs/Skillsystem.md` 8a): `Campaign.finish_mission()` setzt Stufe und Resttage, Tote verlassen die Crew (`Campaign.last_fallen`), `Campaign.pass_days()` heilt. Die Charakterübersicht zeigt Zustand und Resttage (✚ angeschlagen, ✖ gesperrt).

## Waffenkammer (Ausrüstung ändern)

**Übersicht der Psi-Listen** `PsiListView` (`ui/crew/psi_list_view.gd`, Mockup „Frontire Psi-Listen“): Reiter je Liste, je Kraft Stufe, Name, Art (Angriff, Unterstützung, nicht im Kampf), Ziel mit Reichweite aus dem Bodenkampf, Wirkung und PP; mit Figur ihr Rang je Liste und der Stand jeder Kraft (verfügbar, nächste, ab Rang N). Geöffnet aus der Charakterübersicht und dem Charakter-Editor über „Alle Psi-Listen ansehen“; das ⓘ an jeder Psi-Liste öffnet die Enzyklopädie an dieser Liste. Übersicht und Editor haben oben rechts ein Burgermenü ☰ mit „Enzyklopädie“. In der Fertigkeitstabelle steht unter jeder Psi-Liste, was der nächste Rang bringt (Übersicht) bzw. welche Kräfte die Liste bringt (Editor).

`ArmoryDialog` (`ui/crew/armory_dialog.gd`, Regeln `core/equipment.gd`, Mockup „Frontire Waffenkammer“): je Figur Waffe 1 (Pflicht), Waffe 2 (darf leer sein), Rüstung und Schild wählen, mit Werten (Fertigkeit, **Bonus der Figur**, Reichweite, Schadensfaktor, Besonderes; Rüstung mit Klasse, Schadensfaktor, Verteidigungs- und Bewegungsmalus; Schild mit Bonus). Bestand unbegrenzt, keine Waffe doppelt, Psi-Waffen nicht wählbar (Psi-Angriffe kommen aus den Listen), Schild nur mit einhändigen Waffen. Eigene Waffen und Rüstungen aus dem Ausrüstungs-Editor (`Gear`) stehen nach den mitgelieferten in den Listen, mit Vermerk „(frei)“, wenn ihre Werte ohne Grenzen eingetragen sind; wird getragene eigene Ausrüstung gelöscht, gilt beim nächsten Laden Waffe 1 → Fäuste, Waffe 2 leer, Rüstung → keine. **Am Lager des Schiffs** (`Stock`): Ausrüsten nimmt heraus, Ablegen legt zurück; angezeigt wird nur, was im Lager liegt, getragen wird oder immer verfügbar ist (Fäuste, keine Rüstung); der Schild ist ein Lagergegenstand; Medikits mit −/+ aus dem Lager (höchstens 3 je Figur, Verbrauch im Einsatz wird abgezogen); ohne Spielstand unbegrenzt. **Beschädigung** (`Character.wear`, aus dem Einsatz): neben dem Namen im Platz „beschädigt −10“ (orange) bzw. „unbrauchbar“ (rot); wird das Teil gewechselt, fällt der Abzug des Platzes vorläufig weg (beschädigte Stücke im Lager folgen, wenn der Hub das Lagerformat festlegt); „zurücknehmen“ stellt ihn wieder her. Munition nur Anzeige: „Besonderes“ zeigt Feuerstoß (Schuss pro Angriff und Bonus), Angriffsbonus, Munitionsart, Magazin und Mitnahme (3 Magazine, höchstens „Munition gesamt“); links steht die Mitnahme je Waffe. Der Hub öffnet den Dialog im Raum „Waffenkammer“: `open_for(Campaign.crew())`; „Fertig“ speichert.

## Charakter-Editor (neues Crewmitglied)

Im Charakter-Modul über „Neues Crewmitglied“. Regeln: `docs/Skillsystem.md`, Abschnitt 7a (Code: `core/creation.gd`).

- 7 Würfe 20–100, der niedrigste wird 90; „neu würfeln“ beliebig oft (verteilte Ränge verfallen dann).
- Würfe per Auswahlfeld auf die Eigenschaften legen (die Eigenschaft, die den Wurf hatte, bekommt den bisherigen).
- Fertigkeitspunkte = Eigenschaftssumme × 1,2; Rang kostet 10 + 2 × Rang; höchstens Rang 5, zwei Fertigkeiten bis 8; höchstens zwei Psi-Listen. Gesperrte „+“ zeigen den Grund als Tooltip.
- Neu: **Körperentwicklung** (+5 TP je Rang), **Psi-Punkte-Entwicklung** (+2 PP je Rang), **Psi-Listen** (`core/psi_lists.gd`, Kräfte werden angezeigt; im Kampf nutzbar außer Telekinese „Heranziehen“ und „Schweben“).
- Station (jede einmal, Jäger mehrfach), Aussehen, zwei Waffen, Rüstung, Schild frei wählbar.
- „Übernehmen“ als neues Mitglied (bis 6) oder als Ersatz für ein vorhandenes; wird sofort gespeichert.
- Noch nicht gebaut: die Variante zum Aufleveln.

## Module und Schnittstelle

Charakter-Modul und Kampfmodule sind getrennt; sie tauschen nur Daten aus:

```
Charakter-Modul (crew.tscn)  ──Kopien der Charaktere──▶  Kampfmodul (main.tscn = Bodenkampf, später Raumkampf)
        ▲                                                         │
        └──────────────── MissionResult (Ergebnis) ◀──────────────┘
```

- `core/character.gd` (**Character**): ein Crewmitglied mit allen dauerhaften Werten (Name, Rolle, Farbe, Eigenschaften, Fertigkeiten mit Rang und EP, freie EP, Waffen, Rüstung, Schild, Medikits, Aussehen). Gespeichert in `user://crew.json` (Version 3: vollständige Charaktere; ohne Speicherstand gilt die Startcrew aus `data/units/crew.tres`, ältere Speicherstände werden auf die Startcrew gelegt).
- `core/campaign.gd` (**Campaign**): der laufende Spielstand zwischen den Szenen (Crew, letztes Ergebnis).
- Kampf: `Combatant.from_character()` macht eine Kopie mit vollen TP, PP und voller Ausrüstung. Der Kampf ändert die Charaktere nicht.
- `core/mission_result.gd` (**MissionResult**): was ein Kampfmodul zurückgibt, je Figur:
  `xp` (benutzte Fertigkeiten → EP), `free_xp` (3 + Missionsbelohnung bei Sieg), `kills`,
  `status` (`state` ok/ko/sterbend/tot, `hp`, `max_hp`, `bleed`, `malus`), `worst_crit` (""/A–E), `dying` (sterbend, unversorgt), `stabilized` (sterbend, stabilisiert), `died` (nur durch den Todeswurf, wenn die ganze Crew fällt), `used` (`medkits`, `ammo` je Waffe).
  `Character.apply_result()` verbucht EP und freie EP, übernimmt die Beschädigung (`wear` → `Character.wear`, gespeichert, im nächsten Kampf wirksam, in Charakterübersicht und Roster als „Beschädigt: …“) und leert verlorene Plätze (`lost`: Waffe 1 → Fäuste, Waffe 2 leer, Rüstung → keine; nichts geht ins Lager). Zustand und Verbrauch werden gespeichert, aber noch nicht ausgewertet (Heilung, Tod und Nachschub sind noch nicht gebaut; jeder Einsatz beginnt heil und voll ausgerüstet).

Ein neues Kampfmodul braucht also nur `Campaign.crew()` als Eingabe und muss am Ende `Campaign.finish_mission(Ergebnis)` aufrufen und nach `Campaign.CREW_SCENE` wechseln – oder, wenn es aus dem Schiff gestartet wurde (`HubState.in_mission()`), `HubState.game.finish_mission(Bericht)` aufrufen und nach `HubState.HUB_SCENE` wechseln (Beispiel: `Battle.finish_mission()`/`hub_report()`).

Missionsgenerator (`core/mission.gd`): Punktebudget je Schwierigkeit (leicht 42, mittel 58, schwer 76), Gegnertypen gewichtet nach Fraktion (`data/missions/*.tres`, Bedrohungswert `threat` in `data/units/enemies/*.tres`), einzelne Gegner als Veteran (+1 Rang, +5 Eigenschaften) oder Neuling (−1, −5). Hallengröße nach Gegnerzahl. Gleicher Seed = gleiche Mission.

## Grafik: 3D-Modelle

Figuren, Waffen und Teile der Halle sind 3D-Modelle (frei lizenziert, siehe `assets/LICENSES.md`). Was kein Modell hat, wird weiter aus Grundkörpern gebaut.

| Was | Modell | Einstellen im Godot-Editor |
|---|---|---|
| Figuren (mit Animationen: stehen, gehen, laufen, zielen, schießen, Nahkampf, Psi, getroffen, fallen, Hocke, Erste Hilfe, nachladen) | Quaternius Modular Men/Women, Brecher = Mech | Figur in `data/units/…/*.tres` → Feld **Visual** → `data/visuals/characters/*.tres` (Modell, Größe, Animationen) |
| Waffen in der Hand | Quaternius Sci-Fi-Waffen (Gewehre, Pistole, Werfer); Vibroklinge und Psi leuchtende Grundformen | Waffe in `data/weapons/*.tres` → Gruppe **Darstellung** (Modell, Länge, Lage in der Hand) |
| Halle: Boden, Wände, Kisten, Fässer, Säulen, Regale | Quaternius Modular Sci-Fi / Cyberpunk | `data/visuals/warehouse.tres` (je Objektart ein Modell und wie es eingepasst wird) |
| Container, Barrieren, Galerie, Treppen, Leitern | Grundkörper (kein passendes Modell gefunden) | – |
| Schiff (Hub): Böden, Wände, Fenster, Konsolen, Schlafkapseln, Heilkammern, Regale, Kisten | Quaternius Modular Sci-Fi (`assets/ship/`) | `view/ship_view.gd`: Räume (`ROOMS`), Durchgänge (`DOORS`), Fenster (`WINDOWS`), Einrichtung (`PROPS`: Modell, Position, Drehung, Maßstab) |
| Landungsschiff im Hangar, Schiff im Startmenü | Quaternius Ultimate Spaceships (`assets/ship/dropship_insurgent.glb`, `ship_imperial.glb`) | `view/ship_view.gd` (`PROPS`), `view/start_screen.gd` |

**Eigene oder andere Modelle einsetzen:** `.glb` nach `godot/assets/…` kopieren, im Inspector in das passende Feld ziehen. Hallenobjekte werden automatisch in ihren Platz gestreckt bzw. wiederholt.
Für Figuren mit Quaternius-ähnlichem Skelett (Knochen `Hips`, `UpperArm.L` …) neue `CharacterVisual`-Datei anlegen und die Animationen übertragen:

```
godot --headless --path godot --script res://tools/bake_animations.gd
```

Das Werkzeug überträgt die 75 KayKit-Animationen (Auswahl von 18) auf jedes Modell mit „Bake From Kaykit“. Figuren mit eigenen Animationen (wie der Mech) bekommen stattdessen eine Namensliste („Anim Names“).

## Aufbau

| Ordner | Inhalt |
|---|---|
| `data/` | **Spieldaten als Ressourcen, im Godot-Editor bearbeitbar**: Waffen, Rüstungen, Angriffstabellen, Kritische Treffer, Patzer, Figuren (`units/crew/*.tres`, `units/enemies/*.tres` mit Bedrohungswert), Mannschaften (`units/crew.tres`, `units/enemies.tres` = feste Gruppe für Tests), Fraktionen für den Missionsgenerator (`missions/*.tres`: Gegnertypen mit Gewichten). `data/types/` enthält die Ressourcen-Klassen. |
| `core/` | Spiellogik ohne Grafik: `dice.gd` (W100 aus 2W10), `rules.gd` (Eigenschaften, Fertigkeiten, Proben, EP), `tables.gd`, `hex.gd`, `battle_map.gd` (Gelände, Sichtlinie, Deckung, Wege), `map_generator.gd` (Menge des Kleinzeugs: `SCATTER_DENSITY`), `mission.gd` (Missionsgenerator), `combatant.gd` (Figur im Kampf), `combat.gd` (Kampfablauf, meldet alles über Signale), `combat_ai.gd`, `character.gd` (Crewmitglied mit allen dauerhaften Werten), `creation.gd` (Regeln der Charaktererschaffung), `psi_lists.gd` (Psi-Listen), `roster.gd` (Crew speichern und laden), `campaign.gd` (Spielstand zwischen den Szenen), `mission_result.gd` (Einsatzergebnis), `prefs.gd`, `game_data.gd` |
| `view/` | Darstellung und Ablauf: `battle.gd` (Hauptszene, verbindet alles), `event_player.gd` (spielt die Kampf-Ereignisse nacheinander ab), `player_controller.gd` (Spielerseite: Modus, Vorschau, Tooltips), `map_view.gd` (Halle), `model_batch.gd` (Hallenmodelle einpassen und gesammelt zeichnen), `unit_view.gd` (Figur auf der Karte), `figure/` (Darstellung einer Figur: `model_figure.gd` mit 3D-Modell und Animationen, `procedural_figure.gd` aus Grundkörpern), `overlay.gd`, `fx.gd`, `camera_rig.gd` |
| `assets/` | 3D-Modelle (`characters/`, `weapons/`, `hall/`), übertragene Animationen (`characters/anims/`), Quelle der Animationen (`source/kaykit/`), Lizenzen |
| `tools/` | `bake_animations.gd` und `retarget.gd`: Animationen von einem Skelett auf ein anderes übertragen |
| `ui/` | Oberfläche: `battle_ui.gd` (schwebendes Layout), `top_menu.gd`, `icon_button.gd`, `info_box.gd`, `unit_card.gd`, `action_panel.gd`, `initiative_bar.gd`, `combat_log.gd`, `dice_panel.gd`, Dialoge (`briefing_dialog.gd`, `sheet_dialog.gd`, `modal.gd`), `crew/` (Charakter-Modul: `crew_screen.gd` = Szene `crew.tscn`, `crew_overview.gd` = Charakterübersicht/Aufleveln, `character_editor.gd` = neue Figur, `figure_preview.gd` = 3D-Vorschau, `roster_screen.gd` = Roster, `roster_edit_dialog.gd` = Name & Aussehen, `crew_picker.gd` = Crew-Auswahl beim neuen Spiel, `crew_widgets.gd` = Figurenkarte und Kurzwerte, `armory_dialog.gd` = Waffenkammer), `ui_theme.gd` |
| `audio/` | `sfx.gd` (Autoload `Sfx`): Soundeffekte werden synthetisch erzeugt, keine Audiodateien |
| Schiff (Hub) | `core/sector.gd` (Sternenkarte: Systeme, Fraktionen, Routen, kürzester Weg), `core/hub_state.gd` (Spiel im Schiff: Tag, Position, Aufträge, laufender Einsatz, Bericht, Schiffswerte; statisch in `HubState.game`, übersteht den Szenenwechsel), `core/voyage.gd` (Reiseproben, Treibstoff, Hülle, Credits, Raumhafen), `core/medbay.gd` (Krankenstation), `core/save_slots.gd` (Spielstände), `view/start_screen.gd` (Startmenü), `view/hub.gd` (Schiff: Räume, Kamera, Ablauf), `view/ship_view.gd` (3D-Deck), `ui/hub_ui.gd`, `ui/star_map.gd`, `ui/slots_dialog.gd` |
| `tests/` | Regeltests, Hub-Tests und KI-gegen-KI-Simulation |

Grundregel: `core/` kennt keine Grafik. `Combat` meldet Würfe, Schritte, Treffer usw. über Signale; `EventPlayer` spielt sie der Reihe nach ab (Würfel rollen → Schuss → Treffer → Log). Die KI plant in einem eigenen Thread, damit die Halle bedienbar bleibt.

Die Crew (vollständige Charaktere mit Rängen und EP, Eigenschaften, gesparten freien EP, Ausrüstung) liegt in `user://crew.json` (ältere Speicherstände werden weiter gelesen), Einstellungen in `user://settings.cfg` (unter Windows: `%APPDATA%\Godot\app_userdata\Past the Frontire`).

## Tests

```
godot --headless --path godot --script res://tests/test_rules.gd
godot --headless --path godot --script res://tests/test_hub.gd       # Sektor, Reisen, Aufträge, Spielstände
godot --headless --path godot --script res://tests/test_sim.gd -- 30
godot --headless --path godot --script res://tests/test_sim.gd -- 45 missionen   # Siege je Schwierigkeit
```

Selbsttests mit Screenshots (Ordner in `PTF_OUT`): `godot --path godot -- --autotest` (KI gegen KI, Truppwahl, Dialoge), `-- --autotest-player` (Bedienung mit simulierten Mausklicks) und `-- --autotest-psi` (Psi-Zeile, Kontextmenü) springen vom Startmenü direkt in den Bodenkampf; `-- --autotest-hub` spielt Startmenü → Schiff → Sternenkarte → Reise → Crewquartiere → Auftrag → Bodenkampf → Bericht durch (Spielstände dabei in `user://saves_test`). Figurengalerie (alle 12 Figuren in mehreren Haltungen): `godot --path godot --script res://tests/figure_gallery.gd`. `-- --no-shadows` schaltet Schatten aus (auf Handys automatisch).
