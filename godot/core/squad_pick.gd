class_name SquadPick
extends RefCounted
## Truppwahl im Briefing (Bodenkampf): Kandidaten und Vorbelegung.
## Kandidat = {ch: Character, blocked: String ("" = frei, sonst Grund), hurt: String ("" = unverletzt, sonst Hinweis)}.
## Vorläufig: ganze Crew aus Campaign.crew() ohne Sperren. Den Sperr-Status (kampfunfähig, schwer verwundet,
## Arzt der Krankenstation) und „angeschlagen“ liefert später das Charakter-Modul (Schnittstelle in docs/module/bodenkampf.md).


## quick = Schnellkampf aus dem Startmenü: Kopien aller Figuren des globalen Rosters (verbucht nichts)
static func candidates(quick: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ch in (GlobalRoster.entries() if quick else Campaign.crew()):
		out.append({"ch": ch, "blocked": "", "hurt": ""})
	return out


## Vorbelegung: der letzte Trupp ohne Gesperrte, freie Plätze in Listenreihenfolge aufgefüllt (höchstens MAX_SQUAD).
## Leerer letzter Trupp = die ersten freien Figuren (Schnellkampf: die Startfiguren, sie stehen vorn im Roster).
static func preselect(cands: Array[Dictionary], last: Array[Character]) -> Array[Character]:
	var free: Array[Character] = []
	for c in cands:
		if c.blocked == "":
			free.append(c.ch)
	var out: Array[Character] = []
	for ch in last:
		if ch in free and not ch in out and out.size() < Campaign.MAX_SQUAD:
			out.append(ch)
	for ch in free:
		if out.size() >= Campaign.MAX_SQUAD:
			break
		if not ch in out:
			out.append(ch)
	# Reihenfolge wie in der Liste (bestimmt auch die Reihenfolge in der Aufstellung)
	var sorted: Array[Character] = []
	for ch in free:
		if ch in out:
			sorted.append(ch)
	return sorted
