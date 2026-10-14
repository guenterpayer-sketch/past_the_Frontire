class_name Creation
extends RefCounted
## Regeln der Charaktererschaffung (docs/Skillsystem.md, 7a): 7 Würfe 20–100, der niedrigste wird 90,
## frei auf die Eigenschaften verteilen; Fertigkeitspunkte = Eigenschaftssumme × 1,2;
## Ranggrenze 5, zwei Fertigkeiten bis 8; höchstens zwei Psi-Listen.

const ROLLS := 7
const LOWEST_TO := 90
const POINTS_FACTOR := 1.2
const RANK_CAP := 5
const RANK_CAP_HIGH := 8
const HIGH_SKILLS := 2
const MAX_LISTS := 2
const STATIONS := ["", "Steuer", "Navigation", "Geschütze", "Schilde", "Technik", "Computer", "Jäger"]
## Stationen, die mehrere Figuren haben dürfen
const SHARED_STATIONS := ["", "Jäger"]


## Ein Wurf 20–100 (W100, unter 20 neu)
static func roll_value() -> int:
	var v := Dice.d100()
	while v < 20:
		v = Dice.d100()
	return v


## 7 Würfe, der niedrigste durch 90 ersetzt, absteigend sortiert
static func roll_pool() -> Array[int]:
	var pool: Array[int] = []
	for i in ROLLS:
		pool.append(roll_value())
	pool[pool.find(pool.min())] = LOWEST_TO
	pool.sort()
	pool.reverse()
	return pool


static func attr_sum(ch) -> int:
	var s := 0
	for a in Rules.ATTRIBUTES:
		s += int(ch.attrs[a.id])
	return s


static func budget(ch) -> int:
	return floori(attr_sum(ch) * POINTS_FACTOR)


## Kosten aller Ränge einer Fertigkeit bis Rang r
static func ranks_cost(r: int) -> int:
	var s := 0
	for i in r:
		s += Rules.rank_cost(i)
	return s


static func spent(ch) -> int:
	var s := 0
	for id in ch.skills:
		s += ranks_cost(int(ch.skills[id].rank))
	return s


static func points_left(ch) -> int:
	return budget(ch) - spent(ch)


## Darf die Fertigkeit bei der Erschaffung um einen Rang steigen? Gibt "" oder den Grund zurück.
static func raise_block(ch, id: StringName) -> String:
	var r := Rules.skill_rank(ch, id)
	if points_left(ch) < Rules.rank_cost(r):
		return "zu wenig Fertigkeitspunkte"
	if PsiLists.is_list(id) and r == 0 and PsiLists.learned(ch).size() >= MAX_LISTS:
		return "höchstens %d Psi-Listen bei der Erschaffung" % MAX_LISTS
	if r + 1 > RANK_CAP_HIGH:
		return "höchstens Rang %d" % RANK_CAP_HIGH
	if r + 1 > RANK_CAP:
		var high := 0
		for k in ch.skills:
			if k != id and int(ch.skills[k].rank) > RANK_CAP:
				high += 1
		if high >= HIGH_SKILLS:
			return "nur %d Fertigkeiten über Rang %d" % [HIGH_SKILLS, RANK_CAP]
	return ""


static func raise(ch, id: StringName) -> bool:
	if raise_block(ch, id) != "":
		return false
	Rules.ensure_skill(ch, id).rank += 1
	return true


static func lower(ch, id: StringName) -> bool:
	var r := Rules.skill_rank(ch, id)
	if r <= 0:
		return false
	if r == 1:
		ch.skills.erase(id)
	else:
		ch.skills[id].rank = r - 1
	return true


## Station frei? (Jäger und keine Station mehrfach)
static func station_free(crew: Array, station: String, except: Object = null) -> bool:
	if station in SHARED_STATIONS:
		return true
	return not crew.any(func(c) -> bool: return c != except and c.station == station)
