class_name Mission
extends RefCounted
## Missionsgenerator: würfelt Auftrag, Gegnergruppe (Fraktion aus res://data/missions), Schwierigkeit,
## Hallengröße und Belohnung. Die Gegner werden über ein Punktebudget (UnitData.threat) zusammengestellt;
## einzelne Gegner können Veteranen (+1 Rang, +5 Eigenschaften) oder Neulinge (−1 Rang, −5) sein.
## Ziel ist bisher immer: alle Gegner ausschalten.

const FACTION_DIR := "res://data/missions"
const MAX_ENEMIES := 9
const MIN_ENEMIES := 3

const DIFFICULTIES := {
	"leicht": {"name": "leicht", "budget": 42, "reward": 2},
	"mittel": {"name": "mittel", "budget": 58, "reward": 3},
	"schwer": {"name": "schwer", "budget": 76, "reward": 5},
}

## Aufträge: Titel und Einsatzbeschreibung (%s = Fraktion)
const JOBS := [
	["Lagerhalle räumen", "Der Hafenmeister will seine Halle zurück. Dort haben sich %s eingenistet."],
	["Fracht zurückholen", "Eine gestohlene Ladung liegt in einer Lagerhalle, bewacht von %s."],
	["Hinterhalt im Depot", "Ein Informant hat euch in eine Halle bestellt. Statt ihm warten %s."],
	["Säuberung", "Ein Auftraggeber zahlt dafür, dass %s aus seinem Depot verschwinden."],
	["Rettungsauftrag", "Ein Frachterpilot hat sich in einer Halle verschanzt. Draußen: %s."],
]

var map_seed := 0
var title := ""
var text := ""
var faction: FactionData
var difficulty := "mittel"
var size_id := "mittel"
var enemies: Array[UnitData] = []
var reward_xp := 0


## faction_path: feste Fraktion (z. B. die des Systems auf der Sternenkarte), leer = zufällig
static func generate(seed_value: int, difficulty_id := "", faction_path := "") -> Mission:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var m := Mission.new()
	m.map_seed = seed_value
	if difficulty_id == "":
		difficulty_id = ["leicht", "mittel", "mittel", "mittel", "schwer"][rng.randi_range(0, 4)]
	m.difficulty = difficulty_id
	var diff: Dictionary = DIFFICULTIES[difficulty_id]
	m.reward_xp = diff.reward
	var factions := all_factions()
	m.faction = factions[rng.randi_range(0, factions.size() - 1)]
	if faction_path != "" and ResourceLoader.exists(faction_path):
		m.faction = load(faction_path)
	m.enemies = _compose(rng, m.faction, diff.budget)
	var job: Array = JOBS[rng.randi_range(0, JOBS.size() - 1)]
	m.title = job[0]
	m.text = job[1] % m.faction.name
	var n := m.enemies.size()
	if n <= 4:
		m.size_id = "klein"
	elif n <= 6:
		m.size_id = "klein" if rng.randf() < 0.2 else "mittel"
	else:
		m.size_id = "mittel" if rng.randf() < 0.4 else "gross"
	return m


static func all_factions() -> Array[FactionData]:
	var out: Array[FactionData] = []
	for f in ResourceLoader.list_directory(FACTION_DIR):
		if f.ends_with(".tres"):
			out.append(load(FACTION_DIR.path_join(f)))
	return out


## Gegner aus dem Budget: gewichtet würfeln, bis kein Typ mehr ins Restbudget passt
static func _compose(rng: RandomNumberGenerator, f: FactionData, budget: int) -> Array[UnitData]:
	var picked: Array[UnitData] = []
	var count := {}
	var left := budget
	while picked.size() < MAX_ENEMIES:
		var pool: Array[int] = []
		var total := 0
		for i in f.units.size():
			var d: UnitData = f.units[i]
			if d.threat <= left and count.get(d.id, 0) < f.max_same:
				pool.append(i)
				total += f.weights[i] if i < f.weights.size() else 1
		if pool.is_empty():
			break
		var r := rng.randi_range(1, total)
		var choice := pool[0]
		for i in pool:
			r -= f.weights[i] if i < f.weights.size() else 1
			if r <= 0:
				choice = i
				break
		var base: UnitData = f.units[choice]
		count[base.id] = count.get(base.id, 0) + 1
		left -= base.threat
		picked.append(base)
	# Mindestanzahl: billigsten Typ auffüllen
	while picked.size() < MIN_ENEMIES:
		var cheapest: UnitData = f.units[0]
		for d in f.units:
			if d.threat < cheapest.threat:
				cheapest = d
		picked.append(cheapest)
	picked.sort_custom(func(a: UnitData, b: UnitData) -> bool:
		return a.threat > b.threat if a.threat != b.threat else String(a.id) < String(b.id))
	return _individualize(rng, picked)


## Jede Figur bekommt eine eigene Kopie: eindeutige Kennung, Buchstabe mit Nummer, Abweichungen in den Werten
static func _individualize(rng: RandomNumberGenerator, picked: Array[UnitData]) -> Array[UnitData]:
	var letters := {}
	for d in picked:
		letters[d.letter] = letters.get(d.letter, 0) + 1
	var seen := {}
	var out: Array[UnitData] = []
	for i in picked.size():
		var base: UnitData = picked[i]
		var d: UnitData = base.duplicate()
		d.attrs = base.attrs.duplicate()
		d.skills = base.skills.duplicate()
		seen[base.letter] = seen.get(base.letter, 0) + 1
		d.id = StringName("%s_%d" % [base.id, i + 1])
		if letters[base.letter] > 1:
			d.letter = "%s%d" % [base.letter, seen[base.letter]]
		var roll := rng.randf()
		var shift := 0
		if roll < 0.2:
			shift = 1
			d.role = "%s, Veteran" % base.role
		elif roll < 0.35:
			shift = -1
			d.role = "%s, Neuling" % base.role
		for a in d.attrs:
			d.attrs[a] = clampi(d.attrs[a] + shift * 5 + rng.randi_range(-3, 3), 1, 100)
		for s in d.skills:
			d.skills[s] = maxi(0, int(d.skills[s]) + shift)
		out.append(d)
	return out


func difficulty_name() -> String:
	return DIFFICULTIES[difficulty].name


## Zusammenfassung der Gegner, z. B. "3× Plünderer, 1× Hexer"
func enemy_summary() -> String:
	var n := {}
	var order: Array[String] = []
	for d in enemies:
		if not n.has(d.name):
			order.append(d.name)
		n[d.name] = n.get(d.name, 0) + 1
	return ", ".join(order.map(func(k: String) -> String: return "%d× %s" % [n[k], k]))
