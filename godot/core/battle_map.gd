class_name BattleMap
extends RefCounted
## Gelände, Sichtlinie, Deckung, Wegfindung. Maßstab: 1 Hexfeld = 1,5 m, 1 Höhenstufe = 1,5 m.

const HEX_M := 1.5
const LEVEL_M := 1.5
## walk: begehbar; obj: Höhe eines Hindernisses über dem Feld (in Höhenstufen)
const TERRAIN := {
	&"boden": {"name": "Hallenboden", "walk": true, "cost": 1},
	&"kiste": {"name": "Kistenstapel", "walk": true, "cost": 1},
	&"container": {"name": "Container", "walk": true, "cost": 1},
	&"regal": {"name": "Hochregal", "walk": true, "cost": 2},
	&"galerie": {"name": "Galerie (Laufsteg)", "walk": true, "cost": 1},
	&"treppe": {"name": "Treppe", "walk": true, "cost": 1},
	&"leiter": {"name": "Leiter", "walk": true, "cost": 1, "ladder": true},
	&"fass": {"name": "Fässer", "walk": false, "obj": 0.8},
	&"barriere": {"name": "Betonbarriere", "walk": false, "obj": 0.8},
	&"saeule": {"name": "Stahlsäule", "walk": false, "obj": 5.0},
	&"wand": {"name": "Hallenwand", "walk": false, "obj": 5.0},
}
const EYE := 1.1   # Augenhöhe einer Figur (Höhenstufen)
const AIM := 0.8   # Zielhöhe
const FULL := 1.8  # ab dieser Höhe über dem Ziel: volle Deckung
const HALF := 0.8  # ab dieser Höhe: halbe Deckung
const COVER_BONUS := [0, 40, 70]
const SIZES := [
	{"id": "klein", "name": "klein", "cols": 20, "rows": 16},
	{"id": "mittel", "name": "mittel", "cols": 30, "rows": 23},
	{"id": "gross", "name": "groß", "cols": 40, "rows": 31},
]


## Ein Hexfeld
class Tile:
	extends RefCounted
	var pos: Vector2i
	var col: int
	var row: int
	var h := 0
	var terrain: StringName = &"boden":
		set(v):
			terrain = v
			_info = TERRAIN[v]
			obj_h = _info.get("obj", 0.0)
	var obj_h := 0.0        # Höhe eines Hindernisses über dem Feld
	var _info: Dictionary = TERRAIN[&"boden"]
	var obj := 0            # Objekt-Kennung: Felder eines Containers, Regals usw. gehören zusammen
	var color := Color()    # Farbe des Containers
	var reserved := false   # beim Erzeugen belegt

	func info() -> Dictionary:
		return _info


## Ergebnis einer Wegsuche: dest = mögliche Ziele, all = alle besuchten Felder (für Wege)
class Reach:
	extends RefCounted
	var dest := {}  # Vector2i -> {"cost", "prev", "tile"}
	var all := {}

	func has(p: Vector2i) -> bool:
		return dest.has(p)

	func cost(p: Vector2i) -> float:
		return all[p].cost if all.has(p) else INF

	func path_to(p: Vector2i) -> Array[Vector2i]:
		var path: Array[Vector2i] = []
		var k: Variant = p
		while k != null and all.has(k):
			path.push_front(k)
			k = all[k].prev
		return path


var cols := 0
var rows := 0
var tiles := {}            # Vector2i -> Tile
var list: Array[Tile] = []
var crew_start: Array[Tile] = []
var enemy_start: Array[Tile] = []
var map_seed := 0
var size_info := {}
var _los_cache := {}
var _peek_cache := {}


func _init(c := 0, r := 0) -> void:
	cols = c
	rows = r


func tile(p: Vector2i) -> Tile:
	return tiles.get(p)


func at_offset(col: int, row: int) -> Tile:
	return tiles.get(Hex.from_offset(col, row))


func add(t: Tile) -> void:
	tiles[t.pos] = t
	list.append(t)


func add_floor(col: int, row: int, terrain: StringName = &"boden", h := 0) -> Tile:
	var t := Tile.new()
	t.pos = Hex.from_offset(col, row)
	t.col = col
	t.row = row
	t.terrain = terrain
	t.h = h
	add(t)
	return t


func clear_cache() -> void:
	_los_cache.clear()
	_peek_cache.clear()


func block_top(t: Tile) -> float:
	return t.h + t.obj_h


func walkable(t: Tile) -> bool:
	return t != null and t.info().walk


## Bewegungskosten von Feld a in das Nachbarfeld b
func step_cost(a: Tile, b: Tile) -> float:
	var info := b.info()
	if not info.walk:
		return INF
	var dh := b.h - a.h
	if dh == 0 or dh == -1:
		return info.cost
	if dh == 1:
		return info.cost + 1          # hochsteigen
	if a.info().get("ladder", false) or info.get("ladder", false):
		return info.cost + absi(dh)   # Leiter
	if dh == -2:
		return info.cost + 1          # herunterspringen (3 m)
	return INF


## Dijkstra. blocked(tile): nicht betretbar; pass_only(tile): durchqueren ja, stehen bleiben nein
func reachable(start: Vector2i, mp: float, blocked := Callable(), pass_only := Callable()) -> Reach:
	var res := Reach.new()
	res.all[start] = {"cost": 0.0, "prev": null, "tile": tile(start)}
	var open: Array = [[0.0, start]]
	while not open.is_empty():
		var bi := 0
		for i in range(1, open.size()):
			if open[i][0] < open[bi][0]:
				bi = i
		var cur: Array = open[bi]
		open.remove_at(bi)
		var cp: Vector2i = cur[1]
		if cur[0] > res.all[cp].cost:
			continue
		var ct := tile(cp)
		for n in Hex.neighbors(cp):
			var nt := tile(n)
			if nt == null or (blocked.is_valid() and blocked.call(nt)):
				continue
			var c: float = cur[0] + step_cost(ct, nt)
			if c > mp:
				continue
			if not res.all.has(n) or c < res.all[n].cost:
				res.all[n] = {"cost": c, "prev": cp, "tile": nt}
				open.append([c, n])
	for k in res.all:
		if res.all[k].cost > 0 and pass_only.is_valid() and pass_only.call(res.all[k].tile):
			continue
		res.dest[k] = res.all[k]
	return res


## Wer neben voller Deckung steht, kann seitlich herausschauen ("um die Ecke schießen")
func peek_tiles(t: Tile) -> Array[Tile]:
	if _peek_cache.has(t):
		return _peek_cache[t]
	var out: Array[Tile] = [t]
	var ns: Array[Tile] = []
	var high := false
	for n in Hex.neighbors(t.pos):
		var nt := tile(n)
		if nt == null:
			continue
		ns.append(nt)
		if block_top(nt) - t.h >= FULL:
			high = true
	if high:
		for nt in ns:
			if walkable(nt) and nt.h == t.h:
				out.append(nt)
	_peek_cache[t] = out
	return out


## Sichtlinie zwischen zwei Feldern (statisch, daher zwischengespeichert)
func line_of_sight(a: Tile, b: Tile) -> bool:
	var key := Vector4i(a.pos.x, a.pos.y, b.pos.x, b.pos.y)
	if _los_cache.has(key):
		return _los_cache[key]
	var vis := _clear(a, b)
	if not vis:
		for x in peek_tiles(a):
			for y in peek_tiles(b):
				if (x != a or y != b) and _clear(x, y):
					vis = true
					break
			if vis:
				break
	_los_cache[key] = vis
	return vis


func _clear(x: Tile, y: Tile) -> bool:
	return _line(x, y, 1) or _line(x, y, -1)


## Feld Nummer i auf der Linie a→b mit n Schritten (wie Hex.line, ohne Array)
static func _line_point(a: Vector2i, b: Vector2i, i: int, n: int, nudge: int) -> Vector2i:
	var f := float(i) / n
	var e := 1e-6 * nudge
	return Hex.round_axial(a.x + e + (b.x - a.x) * f, a.y + e + (b.y - a.y) * f)


func _line(x: Tile, y: Tile, nudge: int) -> bool:
	var n := Hex.distance(x.pos, y.pos)
	var h0 := x.h + EYE
	var h1 := y.h + AIM
	for i in range(1, n):
		var t: Tile = tiles.get(_line_point(x.pos, y.pos, i, n, nudge))
		if t == null:
			continue
		var top := block_top(t)
		if top <= h0 + (h1 - h0) * (float(i) / n):
			continue
		# niedrige Deckung direkt neben Schütze oder Ziel: darüber schießt man hinweg –
		# aber nur, wenn das Auge des Schützen über der Oberkante liegt
		if i == 1 and top - x.h < FULL and x.h + EYE >= top:
			continue
		if i == n - 1 and top - y.h < FULL and x.h + EYE >= top:
			continue
		return false
	return true


## Deckung des Ziels gegen einen Angreifer: Hindernis in einem der beiden Felder vor dem Ziel
## (das zweite nur ab 4 Feldern Abstand). Wer mindestens 2 Stufen über der Deckung steht, senkt sie um eine Stufe.
## Ergebnis: {} oder {level, label, bonus}
func cover(target: Tile, attacker: Tile) -> Dictionary:
	var dist := Hex.distance(target.pos, attacker.pos)
	if dist <= 1:
		return {}
	var best := {}
	for nudge in [1, -1]:
		# Geländer der Galerie: halbe Deckung an der Kante gegen tiefer stehende Schützen
		var edge := tile(_line_point(target.pos, attacker.pos, 1, dist, nudge))
		if target.terrain == &"galerie" and edge and edge.h < target.h and attacker.h < target.h + 2 and best.get("level", 0) < 1:
			best = {"level": 1, "label": "Geländer", "bonus": COVER_BONUS[1]}
		for i in range(1, (2 if dist >= 4 else 1) + 1):
			var n := tile(_line_point(target.pos, attacker.pos, i, dist, nudge))
			if n == null:
				continue
			var top := block_top(n)
			var diff := top - target.h
			if diff < HALF:
				continue
			var level := 2 if diff >= FULL else 1
			if attacker.h >= top + 2:
				level -= 1
			if level > 0 and level > best.get("level", 0):
				best = {"level": level, "label": n.info().name, "bonus": COVER_BONUS[level]}
	return best
