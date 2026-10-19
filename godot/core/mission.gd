class_name Mission
extends RefCounted
## Missionsgenerator: würfelt Auftrag, Gegnergruppe (Fraktion aus res://data/missions), Schwierigkeit,
## Hallengröße und Belohnung. Die Gegner werden über ein Punktebudget (UnitData.threat) zusammengestellt;
## einzelne Gegner können Veteranen (+1 Rang, +5 Eigenschaften) oder Neulinge (−1 Rang, −5) sein.
## Ziel ist bisher immer: alle Gegner ausschalten.

const FACTION_DIR := "res://data/missions"
const MAX_ENEMIES := 9
const MIN_ENEMIES := 3

## nur für Messungen (test_sim budget=N): Budget je Schwierigkeit überschreiben
static var budget_override := {}

const DIFFICULTIES := {
	"leicht": {"name": "leicht", "budget": 42, "reward": 2},
	"mittel": {"name": "mittel", "budget": 58, "reward": 3},
	"schwer": {"name": "schwer", "budget": 88, "reward": 5},   # 76 → 88 mit bis zu 8 Figuren (Simulation 18.10.2026)
}

## Aufträge je Kartentyp: Titel, Einsatzbeschreibung (%s = Fraktion) und Startlage (LAGEN), je 6, Entern 5 (Index aus dem Missionszufall)
const JOBS := {
	&"halle": [
		["Lagerhalle räumen", "Der Hafenmeister will seine Halle zurück. Dort haben sich %s eingenistet.", &"standard"],
		["Fracht zurückholen", "Eine gestohlene Ladung liegt in einer Lagerhalle, bewacht von %s.", &"verteilt"],
		["Hinterhalt im Depot", "Ein Informant hat euch in eine Halle bestellt. Statt ihm warten %s.", &"hinterhalt"],
		["Säuberung", "Ein Auftraggeber zahlt dafür, dass %s aus seinem Depot verschwinden.", &"standard"],
		["Rettungsauftrag", "Ein Frachterpilot hat sich in einer Halle verschanzt. Draußen: %s.", &"verteidigung"],
		["Nächtlicher Besuch", "In einer Lagerhalle feiern %s ihren letzten Coup. Mit euch rechnet dort niemand.", &"ueberfall"],
	],
	&"bar": [
		["Schulden eintreiben", "Der Wirt zahlt nicht mehr an seine Beschützer, seit %s die Bar übernommen haben.", &"standard"],
		["Treffen geplatzt", "Euer Kontaktmann wartet in einer Hafenbar. An den Tischen sitzen %s.", &"hinterhalt"],
		["Kneipenschlägerei", "In einer Bar am Raumhafen haben %s das Kommando übernommen. Der Besitzer will sie raus.", &"verteilt"],
		["Zeugen schützen", "Eine Zeugin hat sich im Hinterzimmer einer Bar versteckt. Vorne warten %s.", &"verteidigung"],
		["Letzte Runde", "Ein Auftraggeber will, dass %s ihre Stammkneipe verlieren.", &"zange"],
		["Sperrstunde", "Nach Feierabend sitzen %s noch in einer Bar beisammen. Die Hintertür ist offen.", &"ueberfall"],
	],
	&"strasse": [
		["Straßensperre", "%s haben eine Straße im Hafenviertel abgeriegelt. Der Konvoi muss durch.", &"standard"],
		["Hinterhalt im Viertel", "Auf dem Weg zum Treffpunkt stellen sich euch %s in den Weg.", &"hinterhalt"],
		["Revierkampf", "%s beanspruchen eine Straße im Hafenviertel. Die Anwohner zahlen für Ruhe.", &"zange"],
		["Lieferung abfangen", "Ein Lieferwagen mit Ware steht in einer Seitenstraße, bewacht von %s.", &"verteilt"],
		["Flucht decken", "Ein Informant muss durch eine Straße voller %s zum Schiff.", &"verteidigung"],
		["Kalte Ecke", "%s treffen sich nachts an einer Kreuzung im Hafenviertel. Ihr seid schon da.", &"ueberfall"],
	],
	&"tempel": [
		["Ruinen sichern", "In einem alten Tempel graben %s nach Artefakten. Ein Sammler will sie zuerst.", &"verteilt"],
		["Verlorene Expedition", "Eine Forschergruppe ist in einer Tempelruine verschwunden. Dort lagern jetzt %s.", &"hinterhalt"],
		["Heiliger Boden", "%s halten in einem verlassenen Tempel ihre Treffen ab. Jemand will das beenden.", &"zange"],
		["Altar räumen", "Auf dem Altar eines alten Tempels liegt eine Datenkapsel. Bewacht von %s.", &"standard"],
		["Grabräuber", "%s plündern eine Tempelruine. Der Auftraggeber zahlt für jedes gerettete Stück.", &"verteilt"],
		["Stille Ruine", "%s haben ihr Lager in einer Tempelruine aufgeschlagen und fühlen sich sicher.", &"ueberfall"],
	],
	&"buero": [
		["Daten stehlen", "Im Serverraum eines Bürogebäudes liegen Daten, die ein Auftraggeber will. Dort sitzen %s.", &"verteilt"],
		["Feindliche Übernahme", "%s haben ein Büro besetzt. Die Eigentümer wollen es zurück.", &"standard"],
		["Geisel befreien", "Eine Angestellte wird in einem Bürotrakt festgehalten, bewacht von %s.", &"zange"],
		["Aktenvernichtung", "Belastende Akten liegen in einem Büro. %s sollen sie nicht bekommen.", &"verteidigung"],
		["Nachtschicht", "In einem leeren Bürogebäude treffen sich %s. Ein Konkurrent will das stören.", &"hinterhalt"],
		["Feierabend", "In einem Bürogebäude zählen %s ihre Beute. Niemand hält Wache.", &"ueberfall"],
	],
	&"schiff": [
		["Entern", "Ihr seid an Bord des gegnerischen Schiffs. Die Besatzung (%s) verteidigt sich.", &"standard"],
		["Entern", "Die Luftschleuse ist offen. Drinnen warten %s.", &"standard"],
		["Entern", "Das Schiff ist gestellt. Jetzt muss die Besatzung (%s) aufgeben oder fallen.", &"standard"],
		["Entern", "Ihr kämpft euch durch die Gänge. An Bord: %s.", &"standard"],
		["Entern", "Brücke und Laderaum müssen genommen werden. Gegner: %s.", &"standard"],
	],
}
const DEFEND_TEXT := "%s entern euer Schiff! Sie kommen durch die Luftschleuse."

## Startlagen (Entscheidungen des Nutzers 18.10.2026): Name und Satz fürs Briefing. Aufträge mit Standard bekommen
## mit LAGE_CHANCE eine der anderen (gleich verteilt); feste Lagen bleiben. Abwehr an Bord = Verteidigung.
const LAGEN := {
	&"standard": ["Standard", "Crew am Eingang links, Gegner rechts"],
	&"hinterhalt": ["Hinterhalt", "die Crew steht mitten im Raum, Gegner auf beiden Seiten"],
	&"zange": ["Zange", "Gegner vorn und an der Flanke"],
	&"verteilt": ["Verteilte Gegner", "Wachen über die ganze Karte verteilt"],
	&"verteidigung": ["Verteidigung", "die Crew hält die rechte Seite, Gegner kommen von links"],
	# Crew überrascht die Gegner (Entscheidung des Nutzers 19.10.2026)
	&"ueberfall": ["Überfall", "die Gegner stehen ahnungslos in der Mitte und handeln in Runde 1 nicht; die Crew stellt sich frei auf"],
}
const LAGE_CHANCE := 0.3
const OTHER_LAGEN := [&"hinterhalt", &"zange", &"verteilt", &"verteidigung", &"ueberfall"]

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
## eigene Karte (CustomMaps): id und Name; im Schnellkampf fest gewählt oder beim Kartenbau aus dem Pool gesetzt
var custom_map := ""
var custom_name := ""
var boarding := ""
var job_index := 0
## Startlage (LAGEN); _lage_roll/_lage_pick: einmal gewürfelt, damit set_map_type() dieselbe Lage ergibt
var lage: StringName = &"standard"
var _lage_roll := 1.0
var _lage_pick := 0


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
	# zufällige Fraktion ohne Story-Fraktionen (die kommen nur über Story-Einsätze mit faction_path)
	var factions := all_factions().filter(func(f: FactionData) -> bool: return f.kind != &"story")
	m.faction = factions[rng.randi_range(0, factions.size() - 1)]
	if faction_path != "" and ResourceLoader.exists(faction_path):
		m.faction = load(faction_path)
	var budget := int(budget_override.get(difficulty_id, diff.budget))
	budget = roundi(budget * (1.0 + float(m.faction.trait_mods.get("budget_pct", 0)) / 100.0))
	m.enemies = _compose(rng, m.faction, budget)
	m.job_index = rng.randi_range(0, 5)   # 6 Aufträge je Bodentyp (Entern: 5, siehe _set_texts)
	var r2 := RandomNumberGenerator.new()
	r2.seed = seed_value + 2
	m.map_type = MapTypes.GROUND[r2.randi_range(0, MapTypes.GROUND.size() - 1)]
	m.square = r2.randf() < 0.5
	m._lage_roll = r2.randf()
	m._lage_pick = r2.randi_range(0, OTHER_LAGEN.size() - 1)
	# bevorzugte Kartentypen der Fraktion (eigener Zufall, damit der Rest gleich bleibt)
	var r3 := RandomNumberGenerator.new()
	r3.seed = seed_value + 3
	if not m.faction.maps.is_empty() and r3.randf() < FactionData.MAP_CHANCE:
		m.map_type = m.faction.maps[r3.randi_range(0, m.faction.maps.size() - 1)]
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
	var jobs: Array = JOBS.get(map_type, JOBS[&"halle"])
	var job: Array = jobs[job_index % jobs.size()]
	title = "Abwehr an Bord" if boarding == "defend" else job[0]
	text = (DEFEND_TEXT if boarding == "defend" else job[1]) % faction.name
	lage = job[2]
	if boarding == "defend":
		lage = &"verteidigung"
	elif boarding == "" and lage == &"standard" and _lage_roll < LAGE_CHANCE:
		lage = OTHER_LAGEN[_lage_pick]


## Zeile fürs Briefing: „Hinterhalt – die Crew steht mitten im Raum, …“
func lage_text() -> String:
	var l: Array = LAGEN.get(lage, LAGEN[&"standard"])
	return "%s – %s" % [l[0], l[1]]


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


## Fraktionen eines Sektors (bis Hub Auftrag 2): je Oberart eine, zufällig (ohne Story-Fraktionen)
static func sector_factions(rng: RandomNumberGenerator) -> Array[FactionData]:
	var by_kind := {}
	for f in all_factions():
		if f.kind != &"story":
			if not by_kind.has(f.kind):
				by_kind[f.kind] = []
			by_kind[f.kind].append(f)
	var kinds := by_kind.keys()
	kinds.sort()
	var out: Array[FactionData] = []
	for k in kinds:
		out.append(by_kind[k][rng.randi_range(0, by_kind[k].size() - 1)])
	return out


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
	return _individualize(rng, picked, f)


## Jede Figur bekommt eine eigene Kopie: eindeutige Kennung, Buchstabe mit Nummer, Abweichungen in den Werten
## f: Fraktion (Waffentausch, Medikits, Eigenheit)
static func _individualize(rng: RandomNumberGenerator, picked: Array[UnitData], f: FactionData = null) -> Array[UnitData]:
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
		if f:
			_apply_faction(d, f)
		out.append(d)
	return out


## Waffentausch (der Rang der alten Fertigkeit gilt auch für die neue), Medikits, Eigenheit
static func _apply_faction(d: UnitData, f: FactionData) -> void:
	var ws: Array[WeaponData] = []
	for w in d.weapons:
		var to: Variant = f.weapon_swap.get(String(w.id), null)
		var nw: WeaponData = (load(to) if to is String else to) if to != null else w
		if nw == null:
			nw = w
		if nw.skill != w.skill:
			d.skills[nw.skill] = maxi(int(d.skills.get(nw.skill, 0)), int(d.skills.get(w.skill, 0)))
		ws.append(nw)
	d.weapons = ws
	d.medkits = maxi(d.medkits, int(f.trait_mods.get("medkits", 0)))
	if f.trait_name != "":
		d.faction_trait = f.trait_mods.duplicate()
		d.faction_trait.name = f.trait_name


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
