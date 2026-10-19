class_name Sector
extends RefCounted
## Sternenkarte eines Spielstands: zufällig erzeugte Systeme mit kontrollierender Fraktion
## und Sprungrouten mit Reisetagen. Gleicher Seed = gleicher Sektor.

const SYSTEM_COUNT := 10
## Kartenfläche in Kartenkoordinaten (die Sternenkarte skaliert auf ihre Größe)
const AREA := Vector2(1000, 700)
const MARGIN := 70.0
const MIN_DIST := 170.0
## Kartenabstand pro Reisetag
const DIST_PER_DAY := 140.0
const MAX_DAYS := 3
const NEUTRAL := 2

const SYLLABLES := ["Ka", "Vor", "Tel", "Lun", "Mar", "Rix", "Sol", "Dra", "Ves", "Nor", "Ix", "Al", "Tar", "Qua",
	"Zen", "Ori", "Bel", "Cyr", "Hal", "Mo", "Ser", "Ul", "Den", "Pha"]
const SUFFIXES := ["", "", "", " Prime", " II", " III", " IV", " Tor", " Reach"]

var map_seed := 0
var name := ""
## je System: {name, pos: Vector2, faction: Pfad der FactionData oder "" (neutral)}
var systems: Array[Dictionary] = []
## je Route: {a, b, days}
var routes: Array[Dictionary] = []
## Heimathafen (neutral, Startpunkt)
var home := 0


static func generate(seed_value: int) -> Sector:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var s := Sector.new()
	s.map_seed = seed_value
	s.name = "Sektor " + _word(rng)
	var used := {}
	var tries := 0
	while s.systems.size() < SYSTEM_COUNT and tries < 5000:
		tries += 1
		var p := Vector2(rng.randf_range(MARGIN, AREA.x - MARGIN), rng.randf_range(MARGIN, AREA.y - MARGIN))
		var ok := true
		for o in s.systems:
			if o.pos.distance_to(p) < MIN_DIST:
				ok = false
				break
		if not ok:
			continue
		var n: String = _word(rng) + SUFFIXES[rng.randi_range(0, SUFFIXES.size() - 1)]
		while used.has(n):
			n = _word(rng)
		used[n] = true
		s.systems.append({"name": n, "pos": p, "faction": ""})
	s._connect()
	s._assign_factions(rng)
	return s


static func _word(rng: RandomNumberGenerator) -> String:
	var a: String = SYLLABLES[rng.randi_range(0, SYLLABLES.size() - 1)]
	var b: String = SYLLABLES[rng.randi_range(0, SYLLABLES.size() - 1)]
	return a + b.to_lower()


## Routen: jedes System zu seinen zwei nächsten Nachbarn, dann Teilnetze verbinden (kürzeste Brücke)
func _connect() -> void:
	var seen := {}
	for i in systems.size():
		var order := range(systems.size())
		order.erase(i)
		order.sort_custom(func(a: int, b: int) -> bool: return _dist(i, a) < _dist(i, b))
		for j in order.slice(0, 2):
			_add_route(i, j, seen)
	while true:
		var comp := _components()
		if comp.size() <= 1:
			break
		var best := [-1, -1]
		var best_d := INF
		for i in comp[0]:
			for c in comp.slice(1):
				for j in c:
					if _dist(i, j) < best_d:
						best_d = _dist(i, j)
						best = [i, j]
		_add_route(best[0], best[1], seen)


func _add_route(a: int, b: int, seen: Dictionary) -> void:
	var key := "%d-%d" % [mini(a, b), maxi(a, b)]
	if seen.has(key):
		return
	seen[key] = true
	routes.append({"a": a, "b": b, "days": clampi(roundi(_dist(a, b) / DIST_PER_DAY), 1, MAX_DAYS)})


func _dist(a: int, b: int) -> float:
	return (systems[a].pos as Vector2).distance_to(systems[b].pos)


func _components() -> Array:
	var comp_of := {}
	var out := []
	for i in systems.size():
		if comp_of.has(i):
			continue
		var c := [i]
		comp_of[i] = true
		var k := 0
		while k < c.size():
			for n in neighbors(c[k]):
				if not comp_of.has(n[0]):
					comp_of[n[0]] = true
					c.append(n[0])
			k += 1
		out.append(c)
	return out


## Fraktionen: je Fraktion ein Kernsystem, die übrigen Systeme gehören zum nächsten Kern;
## der Heimathafen und weitere NEUTRAL Systeme sind neutral
func _assign_factions(rng: RandomNumberGenerator) -> void:
	var factions := Mission.sector_factions(rng)   # je Oberart eine (Bodenkampf Auftrag 1, bis Hub Auftrag 2)
	var order := range(systems.size())
	_shuffle(order, rng)
	home = order[0]
	var cores := {}
	for k in mini(factions.size(), order.size() - 1):
		cores[order[k + 1]] = factions[k].resource_path
	var neutral := [home]
	for k in range(cores.size() + 1, mini(cores.size() + 1 + NEUTRAL - 1, order.size())):
		neutral.append(order[k])
	for i in systems.size():
		if i in neutral or cores.is_empty():
			continue
		var best: int = cores.keys()[0]
		for c in cores:
			if _dist(i, c) < _dist(i, best):
				best = c
		systems[i].faction = cores[best]


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## Nachbarn eines Systems: [[System, Reisetage], ...]
func neighbors(i: int) -> Array:
	var out := []
	for r in routes:
		if r.a == i:
			out.append([r.b, r.days])
		elif r.b == i:
			out.append([r.a, r.days])
	return out


## Kürzester Weg (Reisetage): {days, path: [Systeme vom Start bis zum Ziel]}; days = -1, wenn unerreichbar
func route(from: int, to: int) -> Dictionary:
	var dist := {from: 0}
	var prev := {}
	var open := [from]
	while not open.is_empty():
		var best := 0
		for k in open.size():
			if dist[open[k]] < dist[open[best]]:
				best = k
		var cur: int = open[best]
		open.remove_at(best)
		if cur == to:
			break
		for n in neighbors(cur):
			var d: int = dist[cur] + n[1]
			if not dist.has(n[0]) or d < dist[n[0]]:
				dist[n[0]] = d
				prev[n[0]] = cur
				if not n[0] in open:
					open.append(n[0])
	if not dist.has(to):
		return {"days": -1, "path": []}
	var path := [to]
	while path[0] != from:
		path.push_front(prev[path[0]])
	return {"days": dist[to], "path": path}


func faction_of(i: int) -> FactionData:
	var p: String = systems[i].faction
	return load(p) if p != "" and ResourceLoader.exists(p) else null


func to_dict() -> Dictionary:
	var sys := []
	for s in systems:
		sys.append({"name": s.name, "x": s.pos.x, "y": s.pos.y, "faction": s.faction})
	return {"seed": map_seed, "name": name, "home": home, "systems": sys, "routes": routes.duplicate(true)}


static func from_dict(d: Dictionary) -> Sector:
	var s := Sector.new()
	s.map_seed = int(d.get("seed", 0))
	s.name = d.get("name", "")
	s.home = int(d.get("home", 0))
	for e in d.get("systems", []):
		s.systems.append({"name": e.name, "pos": Vector2(e.x, e.y), "faction": e.get("faction", "")})
	for r in d.get("routes", []):
		s.routes.append({"a": int(r.a), "b": int(r.b), "days": int(r.days)})
	return s
