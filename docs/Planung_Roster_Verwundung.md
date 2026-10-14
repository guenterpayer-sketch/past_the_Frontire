# Planung: Roster, Crew-Auswahl, Verwundung statt Tod

Stand: 15.10.2026. Entscheidungen des Nutzers aus dem Koordinations-Chat (nach dem ersten Spieltest). Grundlage für die Aufträge in `docs/module/charakter.md`, `hub.md`, `bodenkampf.md`. Was hier als **Vorschlag** markiert ist, darf das zuständige Modul ändern, muss es aber in seiner Moduldatei unter „Schnittstellen“ vermerken.

## A. Roster und Crew-Auswahl

**Entschieden:**
- **Ein globaler Roster für alle Spiele**: die 6 Startcharaktere plus alle selbst erstellten Figuren. Er gehört keinem Spielstand.
- Beim **neuen Spiel** stellt man die Crew aus dem Roster zusammen. Im Spiel entwickeln sich **Kopien** weiter; der Roster-Eintrag bleibt auf seinem Stand (kein Fortschritt zurück in den Roster).
- **Crewgröße:** 6 im Einsatz, dazu Reserve an Bord. Die Plätze an Bord hängen vom Schiff ab: **zu Beginn 8** (6 + 2 Reserve), später ausbaubar über den Hub.
- **Neue Figuren im laufenden Spiel nur aus dem Roster anheuern** (solange Platz an Bord ist). Neue Figuren erschafft man außerhalb eines Spiels im Roster.

**Offen (mit dem Nutzer klären, im jeweiligen Modul):**
- Wo der Roster im Startmenü erreichbar ist und wie die Auswahl beim neuen Spiel aussieht → Mockup (Hub + Charakter).
- Ob Figuren im Roster nachträglich bearbeitet oder gelöscht werden dürfen; ob die 6 Startcharaktere schreibgeschützt sind.
- Ob beim neuen Spiel Reserveplätze gleich mit belegt werden können (bis 8) oder nur die 6.
- Was mit dem bisherigen „Neues Crewmitglied“ in den Crewquartieren passiert (nach dieser Entscheidung: im Spiel kein Editor mehr, sondern „Anheuern aus dem Roster“).

**Vorschlag Zuständigkeit:**
- Charakter: Roster-Speicher (z. B. `user://roster.json`, getrennt von den Spielständen), Roster-Bildschirm mit Editor, Auswahl-Dialog, `Campaign` mit Einsatz/Reserve.
- Hub: Startmenü-Eintrag „Roster“, „Neues Spiel“ → Auswahl, Plätze an Bord (`HubState`), Anheuern im Schiff, Spielstände (Crew gehört zum Spielstand, Roster nicht).

## B. Verwundung statt Tod

**Entschieden:**
- **Kein Perma-Tod im Normalfall.** Ein Kritischer oder TP-Stand, der nach den Regeln tötet, macht die Figur **sterbend/kampfunfähig**, nicht tot.
- **Einzige Ausnahme:** Die **ganze Crew fällt** (Niederlage, weil keiner mehr kampffähig ist). Dann stirbt **jede sterbende Figur mit 10 %**; alle anderen überleben verwundet.
- **Schwere** = Zustand am Kampfende **und** Zuschlag für schwere Kritische (beides kombiniert).
- **Heilung in Spieltagen** in der Krankenstation des Schiffs (Reisen und Warten lassen Tage vergehen).
- **Einsatz vor der Heilung je nach Schwere:** leicht Verletzte dürfen mit (mit Malus), kampfunfähig und schwer Verwundete sind gesperrt, bis sie geheilt sind.
- **Wie viele Tage:** Der Hub-Chat schlägt Werte vor (anhand typischer Reise- und Auftragsdauer), der Nutzer entscheidet.

**Vorschlag Stufen** (Namen und Grenzen bestätigt das Modul mit dem Nutzer):

| Stufe | Bedingung am Kampfende | Einsatz bis zur Heilung |
|---|---|---|
| unverletzt | TP ≥ Hälfte, kein Kritischer C oder schwerer | ja |
| angeschlagen | TP unter Hälfte oder Kritischer A–B | ja, mit Malus |
| kampfunfähig | bewusstlos (TP ≤ 0) | nein |
| schwer verwundet | sterbend (wäre nach Regeln tot: TP ≤ −KON/5 oder tödlicher Kritischer) | nein |

Zuschlag: schwerster erlittener Kritischer (A–E) verlängert die Tage.

**Vorschlag Schnittstelle:**
- Bodenkampf: `Combatant.State` bekommt statt „tot“ einen Zustand „sterbend“ (kampfunfähig, Erste Hilfe möglich). `MissionResult` liefert je Figur zusätzlich `worst_crit` (\"\" oder A–E), `dying` (bool) und bei „ganze Crew gefallen“ das Ergebnis des 10-%-Wurfs (`died`).
- Charakter: `Character` speichert die Verwundung (`injury`: Stufe, Resttage; ggf. Malus) und ob die Figur tot ist; `Campaign.finish_mission()` wertet das `MissionResult` aus (Stufe und Tage nach der Tabelle oben). Tote Figuren verlassen die Crew (der Roster-Eintrag bleibt).
- Hub: Tage vergehen → Resttage sinken (`Campaign`-Funktion dafür vom Charakter-Modul), Krankenstation zeigt Verwundete und Resttage, Einsatz-Auswahl sperrt Gesperrte.

## C. Weitere Punkte aus dem Spieltest

- **Psi im Kampf** (Bodenkampf, mit Charakter): Eine im Editor erstellte Psi-Figur kann im Kampf keine Kraft wählen. Heute gibt es nur Psi-Schild (eigene Aktion) und Psi-Stoß (als Waffe eingetragen); die Psi-Listen (`core/psi_lists.gd`) sind nur Anzeige.
- **Aktive Figur im Bodenkampf schlecht erkennbar** (Bodenkampf): sichtbar besser hervorheben, erst als Mockup.

## D. Klärung Hub ⇄ Charakter (15.10.2026, Koordinator mit dem Nutzer)

Hub- und Charakter-Chat hatten widersprüchliche Entscheidungen in ihren Moduldateien. **Diese Klärung gilt und ersetzt die abweichenden Einträge**; beide Chats übernehmen sie in ihre Moduldatei.

| Thema | Entscheidung | Zuständig |
|---|---|---|
| Crew-Auswahl beim neuen Spiel | **`CrewPicker` aus dem Charakter-Modul** (schon gebaut). Der Hub ruft ihn auf (Startmenü „Neues Spiel“), baut **keine** eigene Auswahl; die entsprechenden Bildschirme im Hub-Mockup entfallen. | Charakter (UI), Hub (Aufruf) |
| Roster im Startmenü | Punkt „Roster“ → `Campaign.ROSTER_SCENE` | Hub (Aufruf), Charakter (Roster-Bildschirm) |
| Anzahl beim neuen Spiel | **1 bis 8** Figuren | Charakter |
| Anheuern | **nur im Hafen** (neutrale Systeme), auf der **Brücke**; nur bei freiem Platz. Die Crewquartiere bieten kein Anheuern mehr an. Daten/Funktion `Campaign.hire()` vom Charakter-Modul, Ort und Bedingung „im Hafen“ vom Hub. | Hub (UI, Hafen), Charakter (`Campaign`) |
| Entlassen | **Fortschritt bleibt im Spielstand**: entlassene Figuren warten „im Hafen“ und können in diesem Spiel mit ihrem Stand wieder angeheuert werden. Der globale Roster bleibt unberührt. Die Liste gehört zu `Campaign` (wird mit der Crew gespeichert). Entlassen-Knopf darf in den Crewquartieren bleiben. | Charakter (`Campaign`, Crewquartiere), Hub (Anzeige im Hafen) |
| Einsatztrupp (bis 6) | wird **im Briefing** gewählt (vor Runde 0), **letzter Trupp vorbelegt** (Gesperrte automatisch heraus, freie Plätze aus der Reserve aufgefüllt), ändern oder bestätigen. **Auch beim Schnellkampf** aus dem Startmenü. Gesperrte (kampfunfähig, schwer verwundet, Arzt der Krankenstation) ausgegraut, Angeschlagene markiert. Ergebnis → `Campaign.chosen_squad`. | **Bodenkampf** (Briefing), Charakter (`chosen_squad` merken und speichern, Sperr-Status je Figur), Hub (Arzt-Zuweisung) |

Weitere Hinweise:
- Der Charakter-Branch hat in `view/battle.gd` (Bodenkampf) eine Zeile geändert (`Campaign.squad()` statt ganzer Crew). Das bleibt so; der Bodenkampf baut die Truppwahl darauf auf.
- Heilungswerte und Krankenstation aus `hub.md` (2/5/10 Tage, Zuschlag A+0 … E+4, Arzt/Helfer mit Zweiter Hilfe, „1 Tag warten“) widersprechen nichts und gelten. Stufe und Tage rechnet das Charakter-Modul in `Campaign.finish_mission()` aus den `MissionResult`-Feldern des Bodenkampfs (`worst_crit`, `dying`, `stabilized`, `died`, Branch `c90cc1c`).

## E. Stand und nächste Schritte (16.10.2026, nach Zusammenführung aller drei Branches)

**In `main`:** Verwundung im Kampf mit `MissionResult`-Feldern (Bodenkampf), Psi im Kampf, aktive Figur, globaler Roster mit `CrewPicker` und `Campaign.squad()` (Charakter), Plätze an Bord und „1 Tag warten“ (Hub).

**Entscheidung Schnellkampf (Nutzer, 16.10.2026):** Die Figuren für den Schnellkampf aus dem Startmenü kommen **aus dem globalen Roster** (Kopien im Roster-Stand). Truppwahl (bis 6) im Briefing wie im Spiel; verbucht nichts.

**Noch offen / Aufträge:** in den Moduldateien unter „Aufträge vom Koordinator (16.10.2026)“. Reihenfolge:
1. Charakter: Klärung D umsetzen, Verwundung auswerten, Kandidatenliste für die Truppwahl (Crew oder Roster-Kopien) mit Sperr-Status.
2. Hub (parallel zu 1): Roster und „Neues Spiel“ anbinden; danach Anheuern im Hafen und Krankenstation, wenn das Charakter-Modul geliefert hat.
3. Bodenkampf (parallel zu 1): Truppwahl im Briefing (erst Mockup bestätigen lassen), mit der Kandidatenliste des Charakter-Moduls.

**Gefundene Lücke:** Die Charakterübersicht (`ui/crew/crew_overview.gd`, Ergebniszeile je Figur) kennt den Zustand „sterbend“ nicht und zeigt dann nichts an.

## F. Stand 16.10.2026 (nach Charakter `d654883` und Hub `479e767`)

- **Erledigt:** Klärung D, Verwundung im Charakter-Modul, Kandidatenliste für die Truppwahl, Roster im Startmenü, neues Spiel mit `CrewPicker`, Schnellkampf aus dem Roster.
- **Offen – Hub:** Anheuern im Hafen (`Campaign.hire()`, `Campaign.harbor()`), Krankenstation (`Campaign.patients()`, `Campaign.pass_days(days, bonus)` bei Reisen, Einsatz und Warten), Arzt/Helfer mit Tagesprobe und EP, Arzt-Sperre über `blocked_ids` an `Campaign.candidates()`. Der Knopf „Anheuern“ in den Crewquartieren existiert nicht mehr; das Ausblenden in `ui/hub_ui.gd` ist damit überflüssig (schadet nicht).
- **Offen – Bodenkampf:** Truppwahl im Briefing mit `Campaign.candidates(quick, blocked_ids)`, `suggested_squad()`, `set_squad()` bzw. `quick_squad` (Schnellkampf). Außerdem: `hub_report()` in `view/battle.gd` soll `Campaign.last_fallen` aufnehmen (Gefallene sind nach `finish_mission()` nicht mehr in `crew()`).
- **Charakter:** nichts offen; Schnittstellen nur nach Absprache ändern. Die Knopftexte der Charakterübersicht („Crew zurücksetzen“, „Speichern & nächste Mission“) nutzt der Hub zum Umbenennen/Ausblenden.

