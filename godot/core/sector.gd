class_name Sector
extends RefCounted
## Ein Sektor: zufällig erzeugte Systeme mit kontrollierender Fraktion, Orten je System und Sprungrouten mit
## Reisetagen; dazu Sprungtore in andere Sektoren. Gleicher Seed = gleicher Sektor. Umbau Auftrag 2 (Entscheidungen
## des Nutzers 19.10.2026, Mockup Bildschirme 45–47): 15–20 Systeme, je drei nächste Nachbarn, 3 neutrale Häfen,
## 2–4 Orte je System (Places), drei Sektoren je Spiel über Sprungtore verbunden (galaxy()).

const SYSTEM_MIN := 15
const SYSTEM_MAX := 20
## Kartenfläche in Kartenkoordinaten (die Sternenkarte skaliert auf ihre Größe)
const AREA := Vector2(1400, 950)
const MARGIN := 80.0
const MIN_DIST := 165.0
## Kartenabstand pro Reisetag
const DIST_PER_DAY := 170.0
const MAX_DAYS := 3
## Routen je System zu den nächsten Nachbarn
const NEIGHBORS := 3
const NEUTRAL := 3
## Sektoren je Spiel und ihre Verbindungen (je Paar ein Tor in beiden Sektoren)
const SECTOR_COUNT := 3
const LINKS := [[0, 1], [1, 2], [2, 0]]
## Torgebühr (Credits, Grundpreis vor Verhandeln) und Anteil der Tore, die Papiere des Betreibers verlangen
const GATE_FEE := [300, 600]
const PAPERS_CHANCE := 0.5

const SYLLABLES := ["Ka", "Vor", "Tel", "Lun", "Mar", "Rix", "Sol", "Dra", "Ves", "Nor", "Ix", "Al", "Tar", "Qua",
	"Zen", "Ori", "Bel", "Cyr", "Hal", "Mo", "Ser", "Ul", "Den", "Pha"]
const SUFFIXES := ["", "", "", " Prime", " II", " III", " IV", " Tor", " Reach"]

var map_seed := 0
var name := ""
## je System: {name, pos: Vector2, faction: Pfad der FactionData oder "" (neutral), places: [{kind, name, done}]}
var systems: Array[Dictionary] = []
## Sprungtore: {system (Ankersystem), to_sector, to_system, fee, operator (Pfad der FactionData oder ""), papers, dir}
var gates: Array[Dictionary] = []
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
	var count := rng.randi_range(SYSTEM_MIN, SYSTEM_MAX)
	while s.systems.size() < count and tries < 20000:
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
		s.systems.append({"name": n, "pos": p, "faction": "", "places": []})
	s._connect()
	s._assign_factions(rng)
	for i in s.systems.size():
		s.systems[i].places = Places.generate(s.systems[i].name, s.is_neutral(i), rng)
	return s


## Drei Sektoren, über Sprungtore verbunden (LINKS); Sektor 0 ist der Startsektor
static func galaxy(seed_value: int) -> Array[Sector]:
	var out: Array[Sector] = []
	for k in SECTOR_COUNT:
		out.append(generate(seed_value + k * 7919))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 31
	for l in LINKS:
		var a: Sector = out[l[0]]
		var b: Sector = out[l[1]]
		var da := Vector2.RIGHT.rotated(rng.randf() * TAU)
		var sa := a._edge_system(da)
		var sb := b._edge_system(-da)
		var fee := rng.randi_range(GATE_FEE[0] / 50, GATE_FEE[1] / 50) * 50
		var papers := rng.randf() < PAPERS_CHANCE
		a.gates.append({"system": sa, "to_sector": l[1], "to_system": sb, "fee": fee, "operator": a.systems[sa].faction,
			"papers": papers and a.systems[sa].faction != "", "dir": da})
		b.gates.append({"system": sb, "to_sector": l[0], "to_system": sa, "fee": fee, "operator": b.systems[sb].faction,
			"papers": papers and b.systems[sb].faction != "", "dir": -da})
	return out


## System am Rand in Richtung dir (noch ohne Tor); der Heimathafen bleibt frei
func _edge_system(dir: Vector2) -> int:
	var center := AREA / 2.0
	var best := -1
	var best_v := -INF
	for i in systems.size():
		if i == home or gates.any(func(g: Dictionary) -> bool: return int(g.system) == i):
			continue
		var v := ((systems[i].pos as Vector2) - center).dot(dir)
		if v > best_v:
			best_v = v
			best = i
	return best


func is_neutral(i: int) -> bool:
	return String(systems[i].faction) == ""


## Tore an einem System
func gates_at(i: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in gates:
		if int(g.system) == i:
			out.append(g)
	return out


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
		for j in order.slice(0, NEIGHBORS):
			if not _crosses(i, j):
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


## Führt die Strecke a–b dicht an einem anderen System vorbei? (sonst sähe es aus, als liefe sie hindurch)
func _crosses(a: int, b: int) -> bool:
	var pa: Vector2 = systems[a].pos
	var pb: Vector2 = systems[b].pos
	for k in systems.size():
		if k == a or k == b:
			continue
		var q := Geometry2D.get_closest_point_to_segment(systems[k].pos, pa, pb)
		if q.distance_to(systems[k].pos) < MIN_DIST * 0.3:
			return true
	return false


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
	# je Oberart eine zufällige Fraktion (Bodenkampf Auftrag 1); jeder Sektor hat eigenen Seed, also eigene Fraktionen
	var factions := Mission.sector_factions(rng)
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
		sys.append({"name": s.name, "x": s.pos.x, "y": s.pos.y, "faction": s.faction, "places": s.places.duplicate(true)})
	var gs := []
	for g in gates:
		var e: Dictionary = g.duplicate()
		e.dir = [g.dir.x, g.dir.y]
		gs.append(e)
	return {"seed": map_seed, "name": name, "home": home, "systems": sys, "routes": routes.duplicate(true), "gates": gs}


static func from_dict(d: Dictionary) -> Sector:
	var s := Sector.new()
	s.map_seed = int(d.get("seed", 0))
	s.name = d.get("name", "")
	s.home = int(d.get("home", 0))
	for e in d.get("systems", []):
		var pl: Array = []
		for p in e.get("places", []):
			pl.append({"kind": String(p.kind), "name": String(p.name), "done": bool(p.get("done", false))})
		s.systems.append({"name": e.name, "pos": Vector2(e.x, e.y), "faction": e.get("faction", ""), "places": pl})
	for r in d.get("routes", []):
		s.routes.append({"a": int(r.a), "b": int(r.b), "days": int(r.days)})
	for g in d.get("gates", []):
		var dir: Array = g.get("dir", [1, 0])
		s.gates.append({"system": int(g.system), "to_sector": int(g.to_sector), "to_system": int(g.to_system), "fee": int(g.fee),
			"operator": String(g.get("operator", "")), "papers": bool(g.get("papers", false)), "dir": Vector2(dir[0], dir[1])})
	return s
