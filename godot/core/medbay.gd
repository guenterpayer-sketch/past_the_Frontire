class_name Medbay
extends RefCounted
## Krankenstation im Schiff: bis zu MAX_STAFF Crewmitglieder (HubState.medics). Wer die höhere Zweite Hilfe hat, ist Arzt
## (voller Bonus, bleibt beim Einsatz an Bord), der andere Helfer (halber Bonus). Jeden Tag mit Patienten eine
## Zweite-Hilfe-Probe: W100 offen + Arzt + Helfer/2; ab 100 heilt ein Tag zusätzlich, ab 150 zwei. Arzt und Helfer
## bekommen je Behandlungstag 1 EP in Zweiter Hilfe. Die Heilung selbst rechnet Campaign.pass_days().

const SKILL := &"zweiteHilfe"
const MAX_STAFF := 2
const T_ONE := 100
const T_TWO := 150
const LOG_SIZE := 8


## Zugewiesenes Personal an Bord und nicht gesperrt, nach Zweiter Hilfe absteigend (Arzt zuerst)
static func staff(g: HubState) -> Array[Character]:
	var out: Array[Character] = []
	for c in Campaign.crew():
		if String(c.id) in g.medics and not c.is_locked():
			out.append(c)
	out.sort_custom(func(a: Character, b: Character) -> bool: return Rules.skill_total(a, SKILL) > Rules.skill_total(b, SKILL))
	return out.slice(0, MAX_STAFF)


static func doctor(g: HubState) -> Character:
	var s := staff(g)
	return s[0] if s.size() > 0 else null


static func helper(g: HubState) -> Character:
	var s := staff(g)
	return s[1] if s.size() > 1 else null


## Probenbonus: Arzt voll + Helfer halb + Ausbau der Krankenstation
static func bonus(g: HubState) -> int:
	var s := staff(g)
	var b := g.heal_bonus() if not s.is_empty() else 0
	if s.size() > 0:
		b += Rules.skill_total(s[0], SKILL)
	if s.size() > 1:
		b += Rules.skill_total(s[1], SKILL) / 2
	return b


## IDs, die für die Truppwahl gesperrt sind (der Arzt bleibt an Bord) – für Campaign.candidates(quick, blocked_ids)
static func blocked_ids(g: HubState) -> Array:
	var d := doctor(g)
	return [d.id] if d else []


## Zuweisen/abziehen; höchstens MAX_STAFF
static func toggle(g: HubState, c: Character) -> void:
	var id := String(c.id)
	if id in g.medics:
		g.medics.erase(id)
	elif g.medics.size() < MAX_STAFF:
		g.medics.append(id)


## Zusätzliche Heiltage aus einer Probe: 0, 1 oder 2
static func extra_days(total: int) -> int:
	return 2 if total >= T_TWO else (1 if total >= T_ONE else 0)


## n Tage vergehen: je Tag Probe (wenn Patienten und Personal da sind), EP fürs Personal, Heilung. Gibt die Geheilten zurück.
static func pass_days(g: HubState, n: int) -> Array[Character]:
	var healed: Array[Character] = []
	_clean(g)
	for i in n:
		var extra := 0
		var s := staff(g)
		if not Campaign.patients().is_empty() and not s.is_empty():
			var roll := Dice.open_d100()
			var b := bonus(g) + Galley.malus(g)
			var total: int = roll.total + b
			extra = extra_days(total)
			for c in s:
				Rules.ensure_skill(c, SKILL).xp += 1
			_log(g, "Tag %d: Zweite Hilfe %s %+d = %d → %s" % [g.day - n + i + 1, Dice.format_roll(roll), b, total,
				["normaler Heiltag", "+1 Tag Heilung", "+2 Tage Heilung"][extra]])
		var h := Campaign.pass_days(1, extra)
		for c in h:
			_log(g, "Tag %d: %s ist wieder einsatzbereit" % [g.day - n + i + 1, c.name])
		healed.append_array(h)
	return healed


## Personal, das nicht mehr an Bord ist (entlassen, gefallen), austragen
static func _clean(g: HubState) -> void:
	var ids := Campaign.crew().map(func(c: Character) -> String: return String(c.id))
	g.medics = g.medics.filter(func(id: String) -> bool: return id in ids)


static func _log(g: HubState, line: String) -> void:
	g.medlog.push_front(line)
	if g.medlog.size() > LOG_SIZE:
		g.medlog.resize(LOG_SIZE)
