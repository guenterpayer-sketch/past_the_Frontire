class_name Mission
extends RefCounted
## Missionsgenerator: würfelt Auftrag, Gegnergruppe (Fraktion aus res://data/missions), Schwierigkeit,
## Hallengröße und Belohnung. Die Gegner werden über ein Punktebudget (UnitData.threat) zusammengestellt, mit Mindest-
## und Höchstzahl je Schwierigkeit; einzelne Gegner können Veteranen (+1 Rang, +5 Eigenschaften, Preis +3) oder
## Neulinge (−1 Rang, −5, Preis −2) sein (Balancing 24.10.2026, Simulation mit der Crew des Nutzers).
## Ziel ist bisher immer: alle Gegner ausschalten.

const FACTION_DIR := "res://data/missions"
const MAX_ENEMIES := 12
const MIN_ENEMIES := 3
## so viele Gegner-Startfelder muss jede Karte mindestens haben; weitere Gegner stellt der Kampf daneben (Combat._place_enemies)
const MIN_START_FIELDS := 9
## Neuling/Veteran: Wahrscheinlichkeit und Aufschlag auf den Punktpreis
const VETERAN_CHANCE := 0.2
const NEWBIE_CHANCE := 0.15
const TIER_COST := {1: 3, -1: -2}
## Mitwachsen (Balancing 24.10.2026): Gegner bekommen je Mehrstärke des eingesetzten Trupps (0…1, gegen die Startcrew)
## Körper-Ränge (TP) und Ränge in ihren Waffenfertigkeiten; Waffen und Rüstungen bleiben gleich
const GROW_KOERPER := 7
const GROW_RANKS := 2
static var _ref_strength := {}
## Elite-Stufen: zusätzliche Körper-Ränge, Waffe aus data/weapons/elite (+10 „elite“, +20 „boss“), Rüstung gleicher
## Klasse aus data/armor/elite mit VW-Bonus, Preis im Budget (Beimischung); Boss-Körper wächst mit dem Trupp (grow)
const ELITE := {
	&"basis": {"name": "Elite", "koerper": 2, "weapon": "elite", "armor": 5, "cost": 6},
	&"leutnant": {"name": "Leutnant", "koerper": 4, "weapon": "elite", "armor": 5, "cost": 9},
	&"hauptmann": {"name": "Hauptmann", "koerper": 5, "weapon": "elite", "armor": 10, "cost": 12},
	&"boss": {"name": "Boss", "koerper": 0, "weapon": "boss", "armor": 15, "cost": 0},
}
## Boss: Körper 4 + 9 × Mehrstärke, höchstens 10 (Mission.grow)
const BOSS_KOERPER := [4, 9, 10]
## Gegnerzahl reiner Elite- und Boss-Begegnungen je Schwierigkeit (Nutzer 24.10.2026)
const ELITE_COUNT := {"leicht": 6, "mittel": 7, "schwer": 8}
## Elite-Basis-Beimischung in normalen Begegnungen: Wahrscheinlichkeit für mindestens 1 und für 2
const ELITE_MIX := {"leicht": [0.0, 0.0], "mittel": [0.25, 0.0], "schwer": [0.6, 0.2]}

## nur für Messungen (test_sim budget=N): Budget je Schwierigkeit überschreiben
static var budget_override := {}

const DIFFICULTIES := {
	"leicht": {"name": "leicht", "budget": 55, "reward": 2, "min": 5, "max": 7},
	"mittel": {"name": "mittel", "budget": 75, "reward": 3, "min": 6, "max": 9},
	"schwer": {"name": "schwer", "budget": 100, "reward": 5, "min": 8, "max": 12},
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
## Elite-Auftrag (Hub würfelt beim Erstellen, Story kann setzen): "" | &"elite" | &"boss"; Form wählt der Bodenkampf
## Setzen (auch nachträglich, Elite.apply des Hubs) stellt die Gegner als Elite-/Boss-Begegnung neu zusammen
var elite: StringName = &"":
	set(v):
		elite = v
		_apply_elite()
var elite_form: StringName = &""   # trupp | kern | boss (Anzeige)
var _seed := 0
var _normal_enemies: Array[UnitData] = []
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
## diff_factor: Spieleinstellung „Schwierigkeitsgrad“ des Hubs (Elite.LEVELS: 0,8 / 1,0 / 1,25), multipliziert das Budget;
## elite_kind: "" | &"elite" | &"boss" (wie das Feld elite, das der Hub auch nachträglich setzen kann)
static func generate(seed_value: int, difficulty_id := "", faction_path := "", diff_factor := 1.0, elite_kind: StringName = &"") -> Mission:
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
	budget = roundi(budget * (1.0 + float(m.faction.trait_mods.get("budget_pct", 0)) / 100.0) * diff_factor)
	# Elite-Beimischung: eigener Zufall (seed + 4), damit Fraktion, Karte und Texte gleich bleiben
	var r4 := RandomNumberGenerator.new()
	r4.seed = seed_value + 4
	var mix: Array = ELITE_MIX[difficulty_id]
	var roll := r4.randf()
	var n_elite := 2 if roll < mix[1] else (1 if roll < mix[0] else 0)
	m.enemies = _compose(rng, m.faction, budget, diff.min, diff.max, n_elite)
	m._seed = seed_value
	m._normal_enemies = m.enemies
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
	m.size_id = _size_for(m.enemies.size(), rng.randf())
	_custom_gear(m, seed_value)
	if elite_kind != &"":
		m.elite = elite_kind
	return m


## Hallengröße nach Gegnerzahl
static func _size_for(n: int, r: float) -> String:
	if n <= 5:
		return "klein" if r < 0.5 else "mittel"
	if n <= 8:
		return "mittel" if r < 0.7 else "gross"
	return "mittel" if r < 0.3 else "gross"


## Gegner zur Elite-Stufe passend neu zusammenstellen (fest aus dem Seed, eigener Zufall seed + 5);
## "" stellt die normale Begegnung wieder her. Form: Boss bei &"boss", sonst Trupp oder Kern (50/50)
func _apply_elite() -> void:
	if faction == null or _normal_enemies.is_empty():
		return
	if elite == &"":
		elite_form = &""
		enemies = _normal_enemies
		return
	var r5 := RandomNumberGenerator.new()
	r5.seed = _seed + 5
	elite_form = &"boss" if elite == &"boss" else (&"trupp" if r5.randf() < 0.5 else &"kern")
	enemies = _elite_group(r5, faction, elite_form, ELITE_COUNT.get(difficulty, 7))
	size_id = _size_for(enemies.size(), r5.randf())
	_custom_gear(self, _seed)


## Ø TP und Ø bester Angriffswert (über alle Waffen und Psi-Angriffe) einer Gruppe
static func strength(units: Array[Combatant]) -> Dictionary:
	var tp := 0.0
	var aw := 0.0
	for u in units:
		tp += u.max_hp
		var best := 0
		for w in u.weapons:
			best = maxi(best, Rules.skill_total(u, w.skill) + w.ob_bonus + Ammo.burst_bonus(w.shots))
		aw += best
	var n := maxi(1, units.size())
	return {"tp": tp / n, "aw": aw / n}


## Mehrstärke des Trupps gegenüber der Startcrew: Mittel aus TP- und Angriffsverhältnis minus 1, begrenzt auf 0…1
static func extra_strength(crew: Array[Combatant]) -> float:
	if _ref_strength.is_empty():
		_ref_strength = strength(Roster.build_team(GameData.crew(), &"crew"))
	var s := strength(crew)
	return clampf((s.tp / maxf(1.0, _ref_strength.tp) + s.aw / maxf(1.0, _ref_strength.aw)) / 2.0 - 1.0, 0.0, 1.0)


## Gegner an den eingesetzten Trupp anpassen; liefert [Körper-Ränge, Fertigkeits-Ränge] für die Anzeige
static func grow(enemies: Array[Combatant], crew: Array[Combatant]) -> Array[int]:
	var m := extra_strength(crew)
	var k := roundi(GROW_KOERPER * m)
	var r := roundi(GROW_RANKS * m)
	for e in enemies:
		if e.elite == &"boss":
			var bk := mini(BOSS_KOERPER[2], BOSS_KOERPER[0] + roundi(BOSS_KOERPER[1] * m))
			e.skills[&"koerper"] = {"rank": Rules.skill_rank(e, &"koerper") + bk, "xp": 0}
			e.max_hp += Rules.HP_PER_RANK * bk
			e.hp = e.max_hp
		if k > 0:
			e.skills[&"koerper"] = {"rank": Rules.skill_rank(e, &"koerper") + k, "xp": 0}
			e.max_hp += Rules.HP_PER_RANK * k
			e.hp = e.max_hp
		if r > 0:
			for w in e.weapons:
				if w.skill != &"" and w.power == "":
					e.skills[w.skill] = {"rank": Rules.skill_rank(e, w.skill) + r, "xp": 0}
	return [k, r]


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
		if d.elite != &"":
			continue   # Elite-Gegner behalten ihre Elite-Ausrüstung
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
## Gegner aus dem Budget: je Gegner Typ (gewichtet) und Stufe (Neuling/normal/Veteran mit Aufschlag) würfeln, bis kein
## Typ mehr ins Restbudget passt oder die Höchstzahl erreicht ist; unter der Mindestzahl billigster Typ als Neuling
static func _compose(rng: RandomNumberGenerator, f: FactionData, budget: int, lo := MIN_ENEMIES, hi := MAX_ENEMIES, n_elite := 0) -> Array[UnitData]:
	var picked: Array[UnitData] = []
	var tiers := {}
	var elites := {}
	var count := {}
	var left := budget
	var max_same := maxi(f.max_same, 4)
	while picked.size() < hi:
		var tier := _roll_tier(rng)
		var add: int = TIER_COST.get(tier, 0)
		var is_elite := picked.size() < n_elite   # die ersten n_elite Gegner sind Elite Basis (Preis aus dem Budget)
		if is_elite:
			tier = 0
			add = ELITE.basis.cost
		var pool: Array[int] = []
		var total := 0
		for i in f.units.size():
			var d: UnitData = f.units[i]
			if d.threat + add <= left and count.get(d.id, 0) < max_same:
				pool.append(i)
				total += f.weights[i] if i < f.weights.size() else 1
		var base: UnitData
		if pool.is_empty():
			if picked.size() >= lo:
				break
			base = _cheapest(f)
			tier = -1
			add = TIER_COST[-1]
		else:
			var r := rng.randi_range(1, total)
			var choice := pool[0]
			for i in pool:
				r -= f.weights[i] if i < f.weights.size() else 1
				if r <= 0:
					choice = i
					break
			base = f.units[choice]
		count[base.id] = count.get(base.id, 0) + 1
		left -= base.threat + add
		tiers[picked.size()] = tier
		if is_elite:
			elites[picked.size()] = true
		picked.append(base)
	# nach Stärke sortieren, Stufe mitnehmen
	var order: Array = range(picked.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var da := picked[a]
		var db := picked[b]
		return da.threat > db.threat if da.threat != db.threat else (String(da.id) < String(db.id) if da.id != db.id else a < b))
	var sorted: Array[UnitData] = []
	var shifts: Array[int] = []
	var marks: Array[StringName] = []
	for i in order:
		sorted.append(picked[i])
		shifts.append(tiers[i])
		marks.append(&"basis" if elites.has(i) else &"")
	var out := _individualize(rng, sorted, f, shifts)
	for i in out.size():
		if marks[i] != &"":
			_make_elite(out[i], marks[i])
	return out


## reine Elite-/Boss-Begegnung mit n Gegnern: Trupp = alle Elite Basis, Kern = jeder 3. Leutnant und Rest Basis,
## Boss = 1 Boss, 2 Hauptleute, Rest normal (mit Neuling/Veteran)
static func _elite_group(rng: RandomNumberGenerator, f: FactionData, form: StringName, n: int) -> Array[UnitData]:
	var picked: Array[UnitData] = []
	var shifts: Array[int] = []
	var marks: Array[StringName] = []
	for i in n:
		var total := 0
		for j in f.units.size():
			total += f.weights[j] if j < f.weights.size() else 1
		var r := rng.randi_range(1, total)
		var choice := 0
		for j in f.units.size():
			r -= f.weights[j] if j < f.weights.size() else 1
			if r <= 0:
				choice = j
				break
		picked.append(f.units[choice])
		var mark: StringName = &""
		match form:
			&"trupp":
				mark = &"basis"
			&"kern":
				mark = &"leutnant" if i % 3 == 0 else &"basis"
			&"boss":
				mark = &"boss" if i == 0 else (&"hauptmann" if i <= 2 else &"")
		marks.append(mark)
		shifts.append(_roll_tier(rng) if mark == &"" else 0)
	var out := _individualize(rng, picked, f, shifts)
	for i in out.size():
		if marks[i] != &"":
			_make_elite(out[i], marks[i])
	return out


## Gegner zur Elite-Stufe machen: Körper, Elite-Waffen und -Rüstung, Rolle mit Stufe
static func _make_elite(d: UnitData, mark: StringName) -> void:
	var e: Dictionary = ELITE[mark]
	d.elite = mark
	d.skills["koerper"] = int(d.skills.get("koerper", 0)) + int(e.koerper)
	d.role = "%s, %s" % [d.role, e.name]
	var ws: Array[WeaponData] = []
	for w in d.weapons:
		var p := "res://data/weapons/elite/%s_%s.tres" % [w.id, e.weapon]
		ws.append(load(p) if ResourceLoader.exists(p) else w)
	d.weapons = ws
	if d.armor:
		var ap := "res://data/armor/elite/%s_vw%d.tres" % [d.armor.id, e.armor]
		if ResourceLoader.exists(ap):
			d.armor = load(ap)


## Stufe eines normalen Gegners: +1 Veteran, −1 Neuling, 0 normal
static func _roll_tier(rng: RandomNumberGenerator) -> int:
	var roll := rng.randf()
	if roll < VETERAN_CHANCE:
		return 1
	if roll < VETERAN_CHANCE + NEWBIE_CHANCE:
		return -1
	return 0


static func _cheapest(f: FactionData) -> UnitData:
	var cheapest: UnitData = f.units[0]
	for d in f.units:
		if d.threat < cheapest.threat:
			cheapest = d
	return cheapest


## Jede Figur bekommt eine eigene Kopie: eindeutige Kennung, Buchstabe mit Nummer, Abweichungen in den Werten
## f: Fraktion (Waffentausch, Medikits, Eigenheit)
## shifts: Stufe je Figur (+1 Veteran, −1 Neuling); leer = hier würfeln
static func _individualize(rng: RandomNumberGenerator, picked: Array[UnitData], f: FactionData = null, shifts: Array[int] = []) -> Array[UnitData]:
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
		var shift: int = shifts[i] if i < shifts.size() else _roll_tier(rng)
		if shift == 1:
			d.role = "%s, Veteran" % base.role
		elif shift == -1:
			d.role = "%s, Neuling" % base.role
		for a in d.attrs:
			d.attrs[a] = clampi(d.attrs[a] + shift * 5 + rng.randi_range(-3, 3), 1, 100)
		for s in d.skills:
			if s != "koerper":   # Grundwert Körper (TP) gilt für alle Stufen
				d.skills[s] = maxi(0, int(d.skills[s]) + shift)
		if f:
			_apply_faction(d, f)
		if d.shield and d.weapons.any(func(w: WeaponData) -> bool: return w.two_handed):
			d.shield = false   # Waffentausch auf eine zweihändige Waffe (z. B. Energiehammer): kein Schild
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
