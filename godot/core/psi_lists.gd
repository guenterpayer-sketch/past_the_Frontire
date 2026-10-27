class_name PsiLists
extends RefCounted
## Psi-Listen (docs/Skillsystem.md, 6.1): jede Liste ist eine Fertigkeit, Rang = höchste verfügbare Stufe,
## eine Kraft kostet Stufe PP. Im Bodenkampf sind alle Kräfte außer Telekinese „Heranziehen“ und „Schweben“
## nutzbar (core/psi_combat.gd); Art, Ziel und Reichweite liefern kind()/target() aus den Kampfwerten.

## Liste → {name, probe, powers: [[Stufe, Name, Wirkung], …]}; Wirkung wie im Bodenkampf, Ziel steht in target()
const LISTS := {
	&"lSchutz": {"name": "Schutz", "probe": "Psi wirken", "powers": [
		[1, "Abschirmen", "+10 Psi-VW für 3 Runden"],
		[2, "Psi-Schild", "+20 VW und +20 Psi-VW für 1–3 Runden"],
		[4, "Ablenkfeld", "Fernangriffe dagegen −20 für 2 Runden"],
		[6, "Schildkuppel", "+15 VW für 2 Runden"],
		[9, "Letzte Barriere", "der nächste Kritische zählt eine Stufe schwächer"]]},
	&"lHeilung": {"name": "Heilung", "probe": "Psi wirken, Berührung", "powers": [
		[1, "Blutung stillen", "Blutung −3"],
		[3, "Wunden schließen", "heilt 2W10 TP"],
		[5, "Schmerz dämpfen", "Wundmalus zählt 5 Runden nicht"],
		[7, "Wieder auf die Beine", "Bewusstlose steht mit 1 TP auf (erst ab Erfolg)"],
		[10, "Am Leben halten", "Sterbende wird stabilisiert (erst ab Erfolg)"]]},
	&"lAngriff": {"name": "Angriff", "probe": "Psi-Angriffe gegen Psi-VW", "powers": [
		[1, "Psi-Nadel", "Schaden nach Tabelle Psi, Angriff −20"],
		[2, "Psi-Stoß", "Schaden nach Tabelle Psi"],
		[4, "Lähmen", "kein Schaden, Ziel 1–2 Runden betäubt"],
		[6, "Psi-Lanze", "Schaden nach Tabelle Psi, Kritische eine Stufe stärker"],
		[8, "Druckwelle", "Schaden nach Tabelle Psi, Angriff −20"]]},
	&"lWahrnehmung": {"name": "Wahrnehmung", "probe": "Psi wirken", "powers": [
		[1, "Gefahrensinn", "+10 Ausweichen bis zum nächsten Zug"],
		[3, "Gedanken orten", "verlieren 3 Runden lang ihre Deckung"],
		[5, "Vorahnung", "+20 Ausweichen gegen den nächsten Angriff"],
		[7, "Schwachstelle", "nächster Angriff eines Verbündeten auf ihn +20"]]},
	&"lTelekinese": {"name": "Telekinese", "probe": "gemischt", "powers": [
		[1, "Heranziehen", "Gegenstand holen (Psi wirken)"],
		[3, "Stoßen", "1 Hex zurück, bei starkem Treffer niedergeworfen"],
		[5, "Entwaffnen", "kann im nächsten Zug nicht angreifen"],
		[8, "Schweben", "eine Höhenstufe ohne Treppe überwinden (Psi wirken)"]]},
	&"lStaerkung": {"name": "Stärkung", "probe": "Psi wirken", "powers": [
		[1, "Fokus", "+5 Angriff für 5 Runden"],
		[2, "Wachheit", "+5 Initiative bis Kampfende"],
		[3, "Leichter Schritt", "+1 Gratis-Feld je Runde für 5 Runden"],
		[4, "Klarer Kopf", "Betäubung 1 Runde kürzer; 5 Runden lang Malus aus „angeschlagen“ nur −5"],
		[5, "Kraftfluss", "+5 auf die Boni von STÄ und GEW für 5 Runden"],
		[6, "Zielsicherheit", "+10 Angriff für 5 Runden"],
		[7, "Zähigkeit", "+10 TP als Puffer bis Kampfende"],
		[8, "Beschleunigung", "110 % Aktivität je Runde für 3 Runden"],
		[10, "Gemeinsamer Wille", "+5 Angriff und +5 Initiative bis Kampfende, Wundmalus halbiert"]]},
}

## Art einer Kraft
const ATTACK := "angriff"
const SUPPORT := "unterstuetzung"
const OFF := "aus"   # nicht im Kampf
const KIND_NAMES := {ATTACK: "Angriff", SUPPORT: "Unterstützung", OFF: "nicht im Kampf"}
## Ziel unterstützender Kräfte (PsiCombat.SUPPORT target) und der Kräfte außerhalb des Kampfs
const TARGETS := {"self": "selbst", "touch": "selbst oder Nachbar", "ally": "Verbündeter in Sicht",
	"enemy": "Gegner in Sicht", "area": "Verbündete in 2 Hex", "foes": "Gegner in 10 Hex"}
const OFF_TARGETS := {"lTelekinese/1": "Gegenstand bis 5 Hex", "lTelekinese/8": "selbst"}


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


## Kraft der Liste auf genau dieser Stufe oder []
static func power_at(id: StringName, level: int) -> Array:
	for p in LISTS[id].powers:
		if p[0] == level:
			return p
	return []


## erste Kraft über dem aktuellen Rang der Figur oder []
static func next_power(ch, id: StringName) -> Array:
	var r := Rules.skill_rank(ch, id)
	for p in LISTS[id].powers:
		if p[0] > r:
			return p
	return []


## ATTACK, SUPPORT oder OFF (nicht im Kampf)
static func kind(id: StringName, level: int) -> String:
	var k := PsiCombat.key(id, level)
	if PsiCombat.is_attack(k):
		return ATTACK
	return SUPPORT if PsiCombat.SUPPORT.has(k) else OFF


## Ziel und Reichweite wie im Bodenkampf (Angriffe: Reichweite der erzeugten Waffe)
static func target(id: StringName, level: int) -> String:
	var k := PsiCombat.key(id, level)
	if PsiCombat.is_attack(k):
		if PsiCombat.ATTACKS[k].effect == "wave":
			return "alle Gegner in 2 Hex"
		return "Gegner, bis %d m" % PsiCombat.weapon(k).max_range_m()
	if PsiCombat.SUPPORT.has(k):
		return TARGETS.get(PsiCombat.SUPPORT[k].target, "")
	return OFF_TARGETS.get(k, "")
