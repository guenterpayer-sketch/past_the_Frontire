class_name PsiLists
extends RefCounted
## Psi-Listen (docs/Skillsystem.md, 6.1): jede Liste ist eine Fertigkeit, Rang = höchste verfügbare Stufe,
## eine Kraft kostet Stufe PP. Im Kampf sind bisher nur Psi-Schild und Psi-Stoß umgesetzt (noch ohne Bindung an Listen).

## Liste → {name, probe, powers: [[Stufe, Name, Wirkung], …]}
const LISTS := {
	&"lSchutz": {"name": "Schutz", "probe": "Psi wirken", "powers": [
		[1, "Abschirmen", "selbst: +10 Psi-VW für 3 Runden"],
		[2, "Psi-Schild", "ein Ziel in Sicht: +20 VW und +20 Psi-VW für 1–3 Runden"],
		[4, "Ablenkfeld", "ein Ziel: Fernangriffe dagegen −20 für 2 Runden"],
		[6, "Schildkuppel", "alle Verbündeten in 2 Hex: +15 VW für 2 Runden"],
		[9, "Letzte Barriere", "ein Ziel: nächster Kritischer eine Stufe schwächer"]]},
	&"lHeilung": {"name": "Heilung", "probe": "Psi wirken, Berührung", "powers": [
		[1, "Blutung stillen", "Blutung −3"],
		[3, "Wunden schließen", "heilt 2W10 TP"],
		[5, "Schmerz dämpfen", "Wundmalus zählt 5 Runden nicht"],
		[7, "Wieder auf die Beine", "Bewusstloser steht mit 1 TP auf"],
		[10, "Am Leben halten", "in dieser Runde Gestorbener ist stattdessen bewusstlos"]]},
	&"lAngriff": {"name": "Angriff", "probe": "Psi-Angriffe gegen Psi-VW", "powers": [
		[1, "Psi-Nadel", "wie Psi-Stoß, 5 m, Angriff −20"],
		[2, "Psi-Stoß", "Tabelle Psi, 10 m"],
		[4, "Lähmen", "kein Schaden, Ziel 1–2 Runden betäubt"],
		[6, "Psi-Lanze", "30 m, Kritische eine Stufe stärker"],
		[8, "Druckwelle", "alle Gegner in 2 Hex, Angriff −20"]]},
	&"lWahrnehmung": {"name": "Wahrnehmung", "probe": "Psi wirken", "powers": [
		[1, "Gefahrensinn", "selbst: +10 Ausweichreserve bis zum nächsten Zug"],
		[3, "Gedanken orten", "Gegner in 10 Hex 3 Runden sichtbar, auch hinter Deckung"],
		[5, "Vorahnung", "Verbündeter: +20 Ausweichen gegen den nächsten Angriff"],
		[7, "Schwachstelle", "Gegner markiert: nächster Angriff eines Verbündeten +20"]]},
	&"lTelekinese": {"name": "Telekinese", "probe": "gemischt", "powers": [
		[1, "Heranziehen", "Gegenstand aus bis zu 5 Hex holen (Psi wirken)"],
		[3, "Stoßen", "Ziel 1 Hex zurück, bei starkem Treffer niedergeworfen (Psi-Angriffe)"],
		[5, "Entwaffnen", "Ziel kann im nächsten Zug nicht angreifen (Psi-Angriffe)"],
		[8, "Schweben", "selbst: eine Höhenstufe ohne Treppe überwinden (Psi wirken)"]]},
}


static func is_list(id: StringName) -> bool:
	return LISTS.has(id)


## Listen, in denen die Figur mindestens Rang 1 hat
static func learned(ch) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in LISTS:
		if Rules.skill_rank(ch, id) > 0:
			out.append(id)
	return out


## Kräfte, die mit dem aktuellen Rang verfügbar sind
static func powers(ch, id: StringName) -> Array:
	var r := Rules.skill_rank(ch, id)
	return LISTS[id].powers.filter(func(p: Array) -> bool: return p[0] <= r)
