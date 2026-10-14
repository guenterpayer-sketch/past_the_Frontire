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
