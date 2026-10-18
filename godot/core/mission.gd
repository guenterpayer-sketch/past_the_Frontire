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

## Aufträge je Kartentyp: Titel und Einsatzbeschreibung (%s = Fraktion), je 5 (Index aus dem Missionszufall)
const JOBS := {
	&"halle": [
		["Lagerhalle räumen", "Der Hafenmeister will seine Halle zurück. Dort haben sich %s eingenistet."],
		["Fracht zurückholen", "Eine gestohlene Ladung liegt in einer Lagerhalle, bewacht von %s."],
		["Hinterhalt im Depot", "Ein Informant hat euch in eine Halle bestellt. Statt ihm warten %s."],
		["Säuberung", "Ein Auftraggeber zahlt dafür, dass %s aus seinem Depot verschwinden."],
		["Rettungsauftrag", "Ein Frachterpilot hat sich in einer Halle verschanzt. Draußen: %s."],
	],
	&"bar": [
		["Schulden eintreiben", "Der Wirt zahlt nicht mehr an seine Beschützer, seit %s die Bar übernommen haben."],
		["Treffen geplatzt", "Euer Kontaktmann wartet in einer Hafenbar. An den Tischen sitzen %s."],
		["Kneipenschlägerei", "In einer Bar am Raumhafen haben %s das Kommando übernommen. Der Besitzer will sie raus."],
		["Zeugen schützen", "Eine Zeugin hat sich im Hinterzimmer einer Bar versteckt. Vorne warten %s."],
		["Letzte Runde", "Ein Auftraggeber will, dass %s ihre Stammkneipe verlieren."],
	],
	&"strasse": [
		["Straßensperre", "%s haben eine Straße im Hafenviertel abgeriegelt. Der Konvoi muss durch."],
		["Hinterhalt im Viertel", "Auf dem Weg zum Treffpunkt stellen sich euch %s in den Weg."],
		["Revierkampf", "%s beanspruchen eine Straße im Hafenviertel. Die Anwohner zahlen für Ruhe."],
		["Lieferung abfangen", "Ein Lieferwagen mit Ware steht in einer Seitenstraße, bewacht von %s."],
		["Flucht decken", "Ein Informant muss durch eine Straße voller %s zum Schiff."],
	],
	&"tempel": [
		["Ruinen sichern", "In einem alten Tempel graben %s nach Artefakten. Ein Sammler will sie zuerst."],
		["Verlorene Expedition", "Eine Forschergruppe ist in einer Tempelruine verschwunden. Dort lagern jetzt %s."],
		["Heiliger Boden", "%s halten in einem verlassenen Tempel ihre Treffen ab. Jemand will das beenden."],
		["Altar räumen", "Auf dem Altar eines alten Tempels liegt eine Datenkapsel. Bewacht von %s."],
		["Grabräuber", "%s plündern eine Tempelruine. Der Auftraggeber zahlt für jedes gerettete Stück."],
	],
	&"buero": [
		["Daten stehlen", "Im Serverraum eines Bürogebäudes liegen Daten, die ein Auftraggeber will. Dort sitzen %s."],
		["Feindliche Übernahme", "%s haben ein Büro besetzt. Die Eigentümer wollen es zurück."],
		["Geisel befreien", "Eine Angestellte wird in einem Bürotrakt festgehalten, bewacht von %s."],
		["Aktenvernichtung", "Belastende Akten liegen in einem Büro. %s sollen sie nicht bekommen."],
		["Nachtschicht", "In einem leeren Bürogebäude treffen sich %s. Ein Konkurrent will das stören."],
	],
	&"schiff": [
		["Entern", "Ihr seid an Bord des gegnerischen Schiffs. Die Besatzung (%s) verteidigt sich."],
		["Entern", "Die Luftschleuse ist offen. Drinnen warten %s."],
		["Entern", "Das Schiff ist gestellt. Jetzt muss die Besatzung (%s) aufgeben oder fallen."],
		["Entern", "Ihr kämpft euch durch die Gänge. An Bord: %s."],
		["Entern", "Brücke und Laderaum müssen genommen werden. Gegner: %s."],
	],
}
const DEFEND_TEXT := "%s entern euer Schiff! Sie kommen durch die Luftschleuse."

var map_seed := 0
var title := ""
var text := ""
var faction: FactionData
var difficulty := "mittel"
var size_id := "mittel"
var enemies: Array[UnitData] = []
var reward_xp := 0
## Kartentyp (MapTypes), quadratische Form, Entern: "" / "board" (selbst entern) / "defend" (Abwehr an Bord).
## Typ und Form werden mit eigenem Zufall (seed + 2) gewürfelt, damit der Rest der Mission gleich bleibt.
var map_type: StringName = &"halle"
var square := false
var boarding := ""
var job_index := 0


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
	m.job_index = rng.randi_range(0, 4)
	var r2 := RandomNumberGenerator.new()
	r2.seed = seed_value + 2
	m.map_type = MapTypes.GROUND[r2.randi_range(0, MapTypes.GROUND.size() - 1)]
	m.square = r2.randf() < 0.5
	m._set_texts()
	var n := m.enemies.size()
	if n <= 4:
		m.size_id = "klein"
	elif n <= 6:
		m.size_id = "klein" if rng.randf() < 0.2 else "mittel"
	else:
		m.size_id = "mittel" if rng.randf() < 0.4 else "gross"
	_custom_gear(m, seed_value)
	return m


## Kartentyp festlegen (Schnellkampf-Auswahl, Entern) und Auftragstext dazu wählen
func set_map_type(t: StringName, board := "") -> void:
	map_type = t
	boarding = board
	_set_texts()


func _set_texts() -> void:
	var job: Array = JOBS.get(map_type, JOBS[&"halle"])[job_index]
	title = "Abwehr an Bord" if boarding == "defend" else job[0]
	text = (DEFEND_TEXT if boarding == "defend" else job[1]) % faction.name


## Eigene Ausrüstung aus dem Editor (Gear) für Gegner, wenn für diese Fraktion freigegeben
## (Entscheidung des Nutzers 15.10.2026): je Gegner mit CUSTOM_CHANCE Waffe 1 durch eine eigene Waffe
## derselben Fertigkeit ersetzen, ebenso die Rüstung durch eine eigene derselben Klasse.
## Eigener Zufall (seed + 1), damit sich die übrige Mission mit oder ohne eigene Ausrüstung nicht ändert.
const CUSTOM_CHANCE := 1.0 / 3.0

static func _custom_gear(m: Mission, seed_value: int) -> void:
	var path := m.faction.resource_path
	var ws := Gear.enemy_weapons(path)
	var ars := Gear.enemy_armors(path)
	if ws.is_empty() and ars.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 1
	for i in m.enemies.size():
		var d: UnitData = m.enemies[i]
		var copy: UnitData = null
		if not d.weapons.is_empty() and rng.randf() < CUSTOM_CHANCE:
			var fit := ws.filter(func(w: WeaponData) -> bool: return w.skill == d.weapons[0].skill)
			if not fit.is_empty():
				copy = d.duplicate()
				copy.weapons = d.weapons.duplicate()
				copy.weapons[0] = fit[rng.randi_range(0, fit.size() - 1)]
		if d.armor and rng.randf() < CUSTOM_CHANCE:
			var fit_a := ars.filter(func(a: ArmorData) -> bool: return a.cls == d.armor.cls)
			if not fit_a.is_empty():
				if copy == null:
					copy = d.duplicate()
				copy.armor = fit_a[rng.randi_range(0, fit_a.size() - 1)]
		if copy:
			m.enemies[i] = copy


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
