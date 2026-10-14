class_name PsiCombat
extends RefCounted
## Psi-Kräfte im Bodenkampf. Welche Kräfte eine Figur hat, ergibt sich aus ihren Rängen in den Psi-Listen
## (PsiLists, Rang = höchste Stufe). Kosten: Stufe PP.
## - Angriffskräfte (Probe Psi-Angriffe gegen Psi-VW) werden als WeaponData erzeugt und laufen über den
##   normalen Angriff (Aktivität frei wählbar, Vorschau, KI).
## - Unterstützende Kräfte (Probe Psi wirken, Mittel) sind eigene Aktionen mit 40 % Aktivität.
## Nicht im Kampf: Telekinese „Heranziehen“ und „Schweben“ (Entscheidung Nutzer, vorerst weggelassen).

const PSI_TABLE := "res://data/tables/attack_psi.tres"

## Angriffskräfte: [Liste, Stufe] → Werte der erzeugten Waffe
## effect: "" = Schaden nach Tabelle, stun = Lähmen, push = Stoßen, disarm = Entwaffnen, lance = Kritischer +1 Stufe,
## wave = alle Gegner in 2 Hex um den Psioniker
const ATTACKS := {
	"lAngriff/1": {"name": "Psi-Nadel", "inc": 5, "stages": 1, "ob": -20, "max": 120, "effect": ""},
	"lAngriff/2": {"name": "Psi-Stoß", "inc": 10, "stages": 3, "ob": 0, "max": 140, "effect": ""},
	"lAngriff/4": {"name": "Lähmen", "inc": 10, "stages": 2, "ob": 0, "max": 140, "effect": "stun"},
	"lAngriff/6": {"name": "Psi-Lanze", "inc": 15, "stages": 2, "ob": 0, "max": 150, "effect": "lance"},
	"lAngriff/8": {"name": "Druckwelle", "inc": 3, "stages": 1, "ob": -20, "max": 140, "effect": "wave"},
	"lTelekinese/3": {"name": "Stoßen", "inc": 10, "stages": 1, "ob": 0, "max": 140, "effect": "push"},
	"lTelekinese/5": {"name": "Entwaffnen", "inc": 10, "stages": 1, "ob": 0, "max": 140, "effect": "disarm"},
}

## Unterstützende Kräfte: target = self (nur selbst), touch (selbst oder Nachbarfeld, Verbündete),
## ally (Verbündeter in Sichtlinie), enemy (Gegner in Sichtlinie), area (alle Verbündeten in 2 Hex), foes (alle Gegner in 10 Hex)
const SUPPORT := {
	"lSchutz/1": {"name": "Abschirmen", "target": "self", "hint": "+10 Psi-VW, 3 Runden"},
	"lSchutz/2": {"name": "Psi-Schild", "target": "ally", "hint": "+20 VW und Psi-VW, 1–3 Runden"},
	"lSchutz/4": {"name": "Ablenkfeld", "target": "ally", "hint": "Fernangriffe dagegen −20, 2 Runden"},
	"lSchutz/6": {"name": "Schildkuppel", "target": "area", "hint": "Verbündete in 2 Hex +15 VW, 2 Runden"},
	"lSchutz/9": {"name": "Letzte Barriere", "target": "ally", "hint": "nächster Kritischer eine Stufe schwächer"},
	"lHeilung/1": {"name": "Blutung stillen", "target": "touch", "hint": "Blutung −3"},
	"lHeilung/3": {"name": "Wunden schließen", "target": "touch", "hint": "heilt 2W10 TP"},
	"lHeilung/5": {"name": "Schmerz dämpfen", "target": "touch", "hint": "Wundmalus zählt 5 Runden nicht"},
	"lHeilung/7": {"name": "Wieder auf die Beine", "target": "touch", "hint": "Bewusstlose steht mit 1 TP auf"},
	"lHeilung/10": {"name": "Am Leben halten", "target": "touch", "hint": "Sterbende wird stabilisiert"},
	"lWahrnehmung/1": {"name": "Gefahrensinn", "target": "self", "hint": "+10 Ausweichen bis zum nächsten Zug"},
	"lWahrnehmung/3": {"name": "Gedanken orten", "target": "foes", "hint": "Gegner in 10 Hex verlieren 3 Runden ihre Deckung"},
	"lWahrnehmung/5": {"name": "Vorahnung", "target": "ally", "hint": "+20 Ausweichen gegen den nächsten Angriff"},
	"lWahrnehmung/7": {"name": "Schwachstelle", "target": "enemy", "hint": "nächster Angriff eines Verbündeten +20"},
}

static var _weapons := {}


static func key(list: StringName, level: int) -> String:
	return "%s/%d" % [list, level]


static func level_of(k: String) -> int:
	return int(k.get_slice("/", 1))


static func list_of(k: String) -> StringName:
	return StringName(k.get_slice("/", 0))


## alle Kraft-Schlüssel, die die Figur mit ihren Rängen beherrscht (Angriff und Unterstützung), nach Liste und Stufe
static func known(ch) -> Array[String]:
	var out: Array[String] = []
	for list in PsiLists.LISTS:
		var r := Rules.skill_rank(ch, list)
		for p in PsiLists.LISTS[list].powers:
			var k := key(list, p[0])
			if p[0] <= r and (ATTACKS.has(k) or SUPPORT.has(k)):
				out.append(k)
	return out


static func is_attack(k: String) -> bool:
	return ATTACKS.has(k)


static func name_of(k: String) -> String:
	return ATTACKS[k].name if ATTACKS.has(k) else SUPPORT.get(k, {}).get("name", k)


## Waffe zu einer Angriffskraft (einmal erzeugt, danach geteilt)
static func weapon(k: String) -> WeaponData:
	if _weapons.has(k):
		return _weapons[k]
	var a: Dictionary = ATTACKS[k]
	var w := WeaponData.new()
	w.id = StringName("psi_" + k.replace("/", "_"))
	w.name = a.name
	w.skill = &"psiAngriff"
	w.table = load(PSI_TABLE)
	w.psi = true
	w.inc_m = a.inc
	w.stages = a.stages
	w.max_result = a.max
	w.fumble = 4
	w.ob_bonus = a.ob
	w.pp_cost = level_of(k)
	w.power = k
	w.power_effect = StringName(a.effect)
	w.two_handed = false
	_weapons[k] = w
	return w


## Angriffskräfte der Figur als Waffen
static func attack_weapons(ch) -> Array[WeaponData]:
	var out: Array[WeaponData] = []
	for k in known(ch):
		if is_attack(k):
			out.append(weapon(k))
	return out


## unterstützende Kräfte der Figur
static func support_powers(ch) -> Array[String]:
	var out: Array[String] = []
	for k in known(ch):
		if SUPPORT.has(k):
			out.append(k)
	return out
