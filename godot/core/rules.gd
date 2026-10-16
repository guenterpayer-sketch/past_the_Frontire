class_name Rules
extends RefCounted
## Skillsystem: Eigenschaften, Fertigkeiten, Proben, Erfahrung, abgeleitete Werte.
## Regeln siehe docs/Skillsystem.md. Eine "Figur" ist hier alles mit attrs, skills, is_crew und xp_log.

const ATTRIBUTES := [
	{"id": "STA", "short": "STÄ", "name": "Stärke"},
	{"id": "GEW", "short": "GEW", "name": "Gewandtheit"},
	{"id": "KOO", "short": "KOO", "name": "Koordination"},
	{"id": "KON", "short": "KON", "name": "Konstitution"},
	{"id": "INT", "short": "INT", "name": "Intelligenz"},
	{"id": "EMP", "short": "EMP", "name": "Empathie"},
	{"id": "MEN", "short": "MEN", "name": "Mentale Stärke"},
]

## Gruppe → [Fertigkeit, Name, Eigenschaft 1, Eigenschaft 2]
const SKILL_GROUPS := [
	{"id": "kampf", "name": "Fähigkeiten Kampf", "skills": [
		["waffenlos", "Waffenloser Kampf", "STA", "GEW"],
		["einhand", "Einhand-Waffen", "STA", "GEW"],
		["zweihand", "Zweihand-Waffen", "STA", "KON"],
		["pistolen", "Pistolen", "KOO", "GEW"],
		["gewehre", "Gewehre", "KOO", "MEN"],
		["schnellfeuer", "Schnellfeuerwaffen", "KOO", "STA"],
		["raketenwerfer", "Raketenwerfer", "KOO", "INT"],
		["geschuetze", "Geschütze", "KOO", "INT"],
		["kampfsinn", "Kampfsinn", "INT", "GEW"],
		["ausweichen", "Ausweichen", "GEW", "KOO"],
		["schild", "Schild", "STA", "KOO"],
		["psiAngriff", "Psi-Angriffe", "MEN", "EMP"],
		["psiVerteidigung", "Psi-Verteidigung", "MEN", "INT"]]},
	{"id": "allgemein", "name": "Fähigkeiten", "skills": [
		["ersteHilfe", "Erste Hilfe", "INT", "KOO"],
		["zweiteHilfe", "Zweite Hilfe", "INT", "EMP"],
		["psiWirken", "Psi wirken", "MEN", "EMP"],
		["waffenReparatur", "Waffen-Reparatur", "INT", "KOO"]]},
	{"id": "rsTechnik", "name": "Raumschiff-Technik", "skills": [
		["rsReparatur", "Reparatur", "INT", "KOO"],
		["navigation", "Navigation", "INT", "MEN"],
		["pilot", "Pilot", "GEW", "KOO"],
		["computer", "Computer", "INT", "MEN"]]},
	{"id": "rsKampf", "name": "Raumschiff-Kampf", "skills": [
		["strahlGeschuetze", "Strahl-Geschütze", "KOO", "INT"],
		["ballistikGeschuetze", "Ballistische Geschütze", "KOO", "INT"],
		["raketen", "Raketen-Geschütze", "INT", "KOO"],   # ID bleibt „raketen“ (Umbenennung 16.10.2026)
		["schutzschild", "Schutzschild", "INT", "MEN"],
		["panzerung", "Panzerung", "INT", "KON"],
		["notReparatur", "Not-Reparatur", "KOO", "MEN"]]},
	{"id": "sozial", "name": "Handel & Soziales", "skills": [
		["handeln", "Handeln", "EMP", "INT"],
		["gassenwissen", "Gassenwissen", "EMP", "INT"],
		["verhandeln", "Verhandeln", "EMP", "MEN"]]},
	{"id": "handwerk", "name": "Handwerk", "skills": [
		["hwRuestung", "Rüstung", "KOO", "INT"],
		["hwWaffen", "Waffen", "KOO", "INT"],
		["kochen", "Kochen", "EMP", "KOO"],
		["medikamente", "Medikamente herstellen", "INT", "KOO"]]},
	# nur die Ränge zählen (TP bzw. PP), die Eigenschaften spielen keine Rolle
	{"id": "entwicklung", "name": "Entwicklung", "skills": [
		["koerper", "Körperentwicklung", "KON", "STA"],
		["psiPunkte", "Psi-Punkte-Entwicklung", "MEN", "EMP"]]},
	# Psi-Listen (PsiLists): Rang = höchste verfügbare Stufe
	{"id": "psiListen", "name": "Psi-Listen", "skills": [
		["lSchutz", "Liste Schutz", "MEN", "EMP"],
		["lHeilung", "Liste Heilung", "MEN", "EMP"],
		["lAngriff", "Liste Angriff", "MEN", "EMP"],
		["lWahrnehmung", "Liste Wahrnehmung", "MEN", "EMP"],
		["lTelekinese", "Liste Telekinese", "MEN", "EMP"]]},
]

## TP je Rang Körperentwicklung, PP je Rang Psi-Punkte-Entwicklung
const HP_PER_RANK := 5
const PP_PER_RANK := 2
const PSI_SKILLS: Array[StringName] = [&"psiAngriff", &"psiVerteidigung", &"psiWirken", &"psiPunkte",
	&"lSchutz", &"lHeilung", &"lAngriff", &"lWahrnehmung", &"lTelekinese"]

const DIFFICULTY := {
	"routine": {"name": "Routine", "mod": 30, "xp": 0},
	"leicht": {"name": "Leicht", "mod": 20, "xp": 1},
	"einfach": {"name": "Einfach", "mod": 10, "xp": 1},
	"mittel": {"name": "Mittel", "mod": 0, "xp": 2},
	"schwer": {"name": "Schwer", "mod": -10, "xp": 3},
	"sehrSchwer": {"name": "Sehr schwer", "mod": -20, "xp": 4},
	"extrem": {"name": "Extrem schwer", "mod": -30, "xp": 5},
	"wahnsinnig": {"name": "Wahnsinnig", "mod": -50, "xp": 7},
	"absurd": {"name": "Absurd", "mod": -70, "xp": 10},
}

static var _skills := {}


## Fertigkeit nach Kennung: {id, name, attrs: [a1, a2], group}
static func skill(id: StringName) -> Dictionary:
	if _skills.is_empty():
		for g in SKILL_GROUPS:
			for s in g.skills:
				_skills[StringName(s[0])] = {"id": StringName(s[0]), "name": s[1], "attrs": [s[2], s[3]], "group": g.id}
	return _skills.get(id, {})


static func skill_name(id: StringName) -> String:
	return skill(id).get("name", String(id))


static func attr_bonus(v: int) -> int:
	if v <= 5:
		return -15
	if v <= 15:
		return -10
	if v <= 30:
		return -5
	if v <= 70:
		return 0
	if v <= 80:
		return 5
	if v <= 90:
		return 10
	if v <= 95:
		return 15
	if v <= 98:
		return 20
	return 25 if v == 99 else 30


static func rank_bonus(r: int) -> int:
	if r <= 0:
		return -25
	if r <= 10:
		return 5 * r
	if r <= 20:
		return 50 + 2 * (r - 10)
	if r <= 30:
		return 70 + (r - 20)
	return 80 + (r - 30) / 2


static func skill_rank(ch, id: StringName) -> int:
	var s: Dictionary = ch.skills.get(id, {})
	return s.get("rank", 0)


static func skill_total(ch, id: StringName) -> int:
	var a: Array = skill(id).attrs
	return rank_bonus(skill_rank(ch, id)) + attr_bonus(ch.attrs[a[0]]) + attr_bonus(ch.attrs[a[1]])


static func rank_cost(rank: int) -> int:
	return 10 + 2 * rank


static func ensure_skill(ch, id: StringName) -> Dictionary:
	if not ch.skills.has(id):
		ch.skills[id] = {"rank": 0, "xp": 0}
	return ch.skills[id]


## Erfahrung nur für benutzte Fertigkeiten; pro Kampf gesammelt in xp_log
static func award_xp(ch, id: StringName, amount: int) -> void:
	if amount <= 0 or not ch.is_crew:
		return
	ensure_skill(ch, id).xp += amount
	ch.xp_log[id] = ch.xp_log.get(id, 0) + amount


## Kosten des nächsten Rangs dieser Figur; der erste Rang einer neuen Psi-Liste kostet doppelt
static func next_rank_cost(ch, id: StringName) -> int:
	var r := skill_rank(ch, id)
	return rank_cost(r) * (2 if r == 0 and is_psi_list(id) else 1)


static func is_psi_list(id: StringName) -> bool:
	return skill(id).get("group", "") == "psiListen"


## Warum kein Rang gekauft werden darf (unabhängig von EP), sonst "":
## pro Levelphase höchstens eine neue Psi-Liste (Character.new_list)
static func rank_block(ch, id: StringName) -> String:
	if is_psi_list(id) and skill_rank(ch, id) == 0 and "new_list" in ch and ch.new_list != &"" and ch.new_list != id:
		return "In dieser Levelphase wurde schon eine neue Psi-Liste begonnen"
	return ""


static func can_rank_up(ch, id: StringName) -> bool:
	var s := ensure_skill(ch, id)
	return s.xp >= next_rank_cost(ch, id) and rank_block(ch, id) == ""


static func rank_up(ch, id: StringName) -> bool:
	if rank_block(ch, id) != "":
		return false
	var s := ensure_skill(ch, id)
	var cost := next_rank_cost(ch, id)
	if s.xp < cost:
		return false
	if s.rank == 0 and is_psi_list(id) and "new_list" in ch:
		ch.new_list = id
	s.xp -= cost
	s.rank += 1
	return true


## Rangsteigerung, bei der fehlende EP aus dem freien Pool der Figur kommen: {ok, from_pool}
static func rank_up_cost(ch, id: StringName) -> Dictionary:
	var s := ensure_skill(ch, id)
	var missing := maxi(0, next_rank_cost(ch, id) - s.xp)
	return {"ok": missing <= ch.free_xp and rank_block(ch, id) == "", "from_pool": missing}


static func rank_up_with_pool(ch, id: StringName) -> bool:
	var c := rank_up_cost(ch, id)
	if not c.ok:
		return false
	ch.free_xp -= c.from_pool
	ensure_skill(ch, id).xp += c.from_pool
	return rank_up(ch, id)


## freie EP auf das Konto einer Fertigkeit einzahlen (höchstens so viele, wie da sind); gibt die Menge zurück
static func deposit_xp(ch, id: StringName, amount: int) -> int:
	var n := mini(amount, ch.free_xp)
	if n <= 0:
		return 0
	ch.free_xp -= n
	ensure_skill(ch, id).xp += n
	return n


## Fertigkeiten, in die eine Eigenschaft einfließt (Namen)
static func skills_using(attr: String) -> PackedStringArray:
	var out := PackedStringArray()
	for g in SKILL_GROUPS:
		for sk in g.skills:
			if sk[2] == attr or sk[3] == attr:
				out.append(sk[1])
	return out


static func attr_short(attr: String) -> String:
	for a in ATTRIBUTES:
		if a.id == attr:
			return a.short
	return attr


## Eigenschaft um 1 steigern, bezahlt aus dem freien Pool: 2 + Wert/10 EP (50 → 7 EP, 90 → 11 EP), höchstens 100
const ATTR_MAX := 100

static func attr_cost(v: int) -> int:
	return 2 + v / 10


static func can_raise_attr(ch, attr: String) -> bool:
	var v: int = ch.attrs[attr]
	return v < ATTR_MAX and ch.free_xp >= attr_cost(v)


static func raise_attr(ch, attr: String) -> bool:
	if not can_raise_attr(ch, attr):
		return false
	ch.free_xp -= attr_cost(ch.attrs[attr])
	ch.attrs[attr] += 1
	return true


## nächster Wert, ab dem der Eigenschaftsbonus steigt (oder -1)
static func next_bonus_step(v: int) -> int:
	var b := attr_bonus(v)
	for n in range(v + 1, ATTR_MAX + 1):
		if attr_bonus(n) > b:
			return n
	return -1


static func maneuver_result(total: int) -> Dictionary:
	if total <= -26:
		return {"id": &"patzer", "name": "Patzer"}
	if total <= 75:
		return {"id": &"fehlschlag", "name": "Fehlschlag"}
	if total <= 100:
		return {"id": &"teilerfolg", "name": "Teilerfolg"}
	if total <= 175:
		return {"id": &"erfolg", "name": "Erfolg"}
	return {"id": &"herausragend", "name": "Herausragender Erfolg"}


static func is_success(result: Dictionary) -> bool:
	return result.id == &"erfolg" or result.id == &"herausragend"


## Probe: offener W100 + Gesamtbonus + Schwierigkeit + Modifikatoren ({label, val})
static func maneuver(ch, skill_id: StringName, diff_id: String, extra_mods: Array = []) -> Dictionary:
	var diff: Dictionary = DIFFICULTY[diff_id]
	var roll := Dice.open_d100()
	var mods: Array = [{"label": skill_name(skill_id), "val": skill_total(ch, skill_id)}, {"label": diff.name, "val": diff.mod}]
	mods.append_array(extra_mods)
	var total: int = roll.total
	for m in mods:
		total += m.val
	var result := maneuver_result(total)
	var xp := 0
	if is_success(result):
		xp = diff.xp
	elif result.id != &"patzer":
		xp = diff.xp / 2
	award_xp(ch, skill_id, xp)
	return {"roll": roll, "mods": mods, "total": total, "result": result, "xp": xp}


static func max_hp(ch) -> int:
	return 15 + ch.attrs.KON / 3 + HP_PER_RANK * skill_rank(ch, &"koerper")


static func death_at(ch) -> int:
	return -(ch.attrs.KON / 5)


static func has_psi(ch) -> bool:
	return PSI_SKILLS.any(func(id: StringName) -> bool: return skill_rank(ch, id) > 0)


## PP = MEN/10 + MEN-Bonus/2 + 2 je Rang Psi-Punkte-Entwicklung (mindestens 0), nur mit Psi
static func max_pp(ch) -> int:
	if not has_psi(ch):
		return 0
	return maxi(0, ch.attrs.MEN / 10 + attr_bonus(ch.attrs.MEN) / 2 + PP_PER_RANK * skill_rank(ch, &"psiPunkte"))


static func initiative_bonus(ch) -> int:
	return attr_bonus(ch.attrs.GEW) + floori(skill_total(ch, &"kampfsinn") / 5.0)


## Gratis-Hexfelder pro Zug aus der Gewandtheit (abzüglich Rüstung)
static func free_hexes(ch) -> int:
	return maxi(0, floori(attr_bonus(ch.attrs.GEW) / 5.0) + ch.armor.move)
