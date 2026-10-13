class_name MapGenerator
extends RefCounted
## Lagerhallen-Generator: Galerie, Treppen, Leitern, Hochregale, Container, Kisten, Fässer, Barrieren, Säulen.
## Jede Halle wird geprüft: alle Bodenfelder müssen vom Eingang aus erreichbar sein.

const CONTAINER_COLORS := ["#9a4a3a", "#3f6f9a", "#4f7f4a", "#b07a2a", "#6a5a8a", "#8a8a8a"]
const T := BattleMap.Tile

var m: BattleMap
var rng := RandomNumberGenerator.new()
var size: Dictionary
var _obj := 0


static func generate(seed_value: int, size_id: String) -> BattleMap:
	var sz: Dictionary = BattleMap.SIZES[1]
	for s in BattleMap.SIZES:
		if s.id == size_id:
			sz = s
	for attempt in 60:
		var s := seed_value + attempt * 7919
		var map := MapGenerator.new()._try(s, sz)
		if map:
			map.map_seed = s
			map.size_info = sz
			return map
	push_error("Keine begehbare Halle gefunden")
	return null


func _ri(a: int, b: int) -> int:
	return rng.randi_range(a, b)


func _next_obj() -> int:
	_obj += 1
	return _obj


func _free(t: T) -> bool:
	return t != null and t.terrain == &"boden" and not t.reserved and t.col > 0 and t.col < m.cols - 1


func _put(t: T, terrain: StringName, h: int, obj := 0, color := Color()) -> void:
	t.terrain = terrain
	t.h = h
	t.reserved = true
	t.obj = obj
	t.color = color


## Felder ab (c0, r0): waagerecht (gleiche Reihe) oder senkrecht (gleiche Spalte, Zickzack im Hexraster)
func _line_tiles(c0: int, r0: int, length: int, vertical: bool, width := 1) -> Array[T]:
	var out: Array[T] = []
	for w in width:
		for k in length:
			out.append(m.at_offset(c0 + w, r0 + k) if vertical else m.at_offset(c0 + k, r0 + w))
	return out


func _all_free(ts: Array[T]) -> bool:
	for t in ts:
		if not _free(t):
			return false
	return true


## Ring um ein Objekt frei (Container sollen nicht aneinanderkleben)
func _ring_free(ts: Array[T]) -> bool:
	for t in ts:
		for n in Hex.neighbors(t.pos):
			var x := m.tile(n)
			if x and not ts.has(x) and x.terrain != &"boden" and x.terrain != &"wand":
				return false
	return true


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


func _try(seed_value: int, sz: Dictionary) -> BattleMap:
	rng.seed = seed_value
	size = sz
	var cols: int = sz.cols
	var rows: int = sz.rows
	m = BattleMap.new(cols, rows)
	for row in rows:
		for col in cols:
			var edge := row == 0 or row == rows - 1 or col == 0 or col == cols - 1
			m.add_floor(col, row, &"wand" if edge else &"boden")
	# Rolltore links (Eingang der Crew) und rechts
	var mid := rows / 2
	for row in range(mid - 2, mid + 2):
		m.at_offset(0, row).terrain = &"boden"
	for row in range(mid - 1, mid + 1):
		m.at_offset(cols - 1, row).terrain = &"boden"

	_build_gallery(cols, rows, mid)
	_build_shelves(cols, rows)
	_build_containers(cols, rows)
	_build_scatter(cols, rows)
	_group_walls(cols, rows)
	return _finish(cols, rows, mid)


## 1. Galerie an der Rückwand (Reihen 1–2), bei mittel/groß auch an der rechten Wand; Treppen und Leitern
func _build_gallery(cols: int, rows: int, mid: int) -> void:
	var gal := _next_obj()
	for col in range(1, cols - 1):
		for row in [1, 2]:
			_put(m.at_offset(col, row), &"galerie", 3, gal)
	var stairs_at: Array = [int(cols * 0.2), int(cols * 0.5), int(cols * 0.75)] if size.id == "gross" else [int(cols * 0.3), int(cols * 0.65)]
	for c in stairs_at:
		for dc in [0, 1]:
			_put(m.at_offset(c + dc, 3), &"treppe", 2)
			_put(m.at_offset(c + dc, 4), &"treppe", 1)
	for c in [_ri(5, cols / 2 - 2), _ri(cols / 2 + 2, cols - 4)]:
		var t := m.at_offset(c, 3)
		if _free(t):
			_put(t, &"leiter", 0)
	if size.id == "klein":
		return
	var gal_r := _next_obj()
	for row in range(3, rows - 1):
		for col in [cols - 3, cols - 2]:
			_put(m.at_offset(col, row), &"galerie", 3, gal_r)
	for sr in [_ri(5, rows / 2 - 1), _ri(rows / 2 + 1, rows - 4)]:
		var st: Array[T] = [m.at_offset(cols - 4, sr), m.at_offset(cols - 4, sr + 1), m.at_offset(cols - 5, sr), m.at_offset(cols - 5, sr + 1)]
		if _all_free(st):
			_put(st[0], &"treppe", 2)
			_put(st[1], &"treppe", 2)
			_put(st[2], &"treppe", 1)
			_put(st[3], &"treppe", 1)
	var lr := _ri(5, rows / 2 - 1)
	if _free(m.at_offset(cols - 4, lr)):
		_put(m.at_offset(cols - 4, lr), &"leiter", 0)
	# rechtes Rolltor schließen, dort steht jetzt die Galerie
	for row in range(mid - 1, mid + 1):
		m.at_offset(cols - 1, row).terrain = &"wand"


## 2. Hochregale: parallele Reihen mit Gängen, je eine Leiter am Ende
func _build_shelves(cols: int, rows: int) -> void:
	var count: int = {"klein": 1, "mittel": 2, "gross": 4}[size.id]
	var left_half := rng.randf() < 0.5
	var sx0: int = 6 if left_half else cols / 2 + 1
	var sx1: int = cols / 2 - 1 if left_half else cols - 7
	var vertical := rng.randf() < 0.5
	for i in count:
		var length := _ri(4, 7)
		var ts: Array[T]
		if vertical:
			var c := sx0 + 1 + i * 3
			if c > sx1:
				break
			ts = _line_tiles(c, _ri(5, maxi(5, rows - 3 - length)), length, true)
		else:
			var r := _ri(5, 6) + i * 3
			var l := mini(length, sx1 - sx0)
			if r >= rows - 3 or l < 3:
				break
			ts = _line_tiles(_ri(sx0, sx1 - l), r, l, false)
		if not _all_free(ts):
			continue
		var so := _next_obj()
		for t in ts:
			_put(t, &"regal", 3, so)
		var first: T = ts[0]
		var last: T = ts[-1]
		var lad: T
		if vertical:
			lad = m.at_offset(first.col, first.row - 1 if rng.randf() < 0.5 else last.row + 1)
		else:
			lad = m.at_offset(first.col - 1 if rng.randf() < 0.5 else last.col + 1, first.row)
		if _free(lad):
			_put(lad, &"leiter", 0)


## 3. Container (3 Felder lang, 1–2 breit), teils doppelt gestapelt; Aufstieg über Leiter oder Kiste
func _build_containers(cols: int, rows: int) -> void:
	var count: int = {"klein": 2, "mittel": 4, "gross": 7}[size.id]
	var placed := 0
	var tries := 0
	while placed < count and tries < 200:
		tries += 1
		var wide := rng.randf() < 0.4
		var vertical := rng.randf() < 0.5
		var c0 := _ri(5, cols - 9)
		var r0 := _ri(4, rows - 5)
		var ts := _line_tiles(c0, r0, 3, vertical, 2 if wide else 1)
		var ok := _ring_free(ts)
		for t in ts:
			if not _free(t) or t.col <= 3:
				ok = false
		if not ok:
			continue
		var h := 4 if rng.randf() < 0.25 else 2
		var color := Color(CONTAINER_COLORS[_ri(0, CONTAINER_COLORS.size() - 1)])
		var co := _next_obj()
		for t in ts:
			_put(t, &"container", h, co, color)
		var end_t: T
		if vertical:
			end_t = m.at_offset(c0, r0 - 1 if rng.randf() < 0.5 else r0 + 3)
		else:
			end_t = m.at_offset(c0 - 1 if rng.randf() < 0.5 else c0 + 3, r0)
		if _free(end_t):
			if h == 4 or rng.randf() < 0.5:
				_put(end_t, &"leiter", 0)
			else:
				_put(end_t, &"kiste", 1, _next_obj())
		placed += 1


## 4. Kleinzeug: Kistenstapel, Fässer, Betonbarrieren (eher quer zur Schussrichtung), Säulen.
## SCATTER_DENSITY regelt die Menge (1.0 = so voll wie in der ersten Fassung).
const SCATTER_DENSITY := 0.5

func _build_scatter(cols: int, rows: int) -> void:
	var area := cols * rows * SCATTER_DENSITY
	_scatter(&"kiste", 1, roundi(area / 40.0), 1, 1, cols, rows)
	_scatter(&"kiste", 1, roundi(area / 80.0), 2, 3, cols, rows)
	_scatter(&"fass", 0, roundi(area / 80.0), 1, 2, cols, rows)
	_scatter(&"barriere", 0, roundi(area / 90.0), 3, 4, cols, rows)
	for c in range(9, cols - 5, 10):
		for r in range(7, rows - 2, 8):
			var t := m.at_offset(c, r)
			if _free(t):
				_put(t, &"saeule", 0)


func _scatter(terrain: StringName, h: int, count: int, min_len: int, max_len: int, cols: int, rows: int) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 20:
		tries += 1
		var length := _ri(min_len, max_len)
		var ts := _line_tiles(_ri(2, cols - 3), _ri(4, rows - 1 - length), length, rng.randf() < 0.65)
		if not _all_free(ts):
			continue
		var so := 0 if terrain == &"fass" else _next_obj()
		for t in ts:
			_put(t, terrain, h, so)
		placed += 1


## Wände: zusammenhängende Wandstücke je Seite bilden ein Objekt
func _group_walls(cols: int, rows: int) -> void:
	var sides: Array = [[], [], [], []]
	for c in cols:
		sides[0].append(m.at_offset(c, 0))
		sides[1].append(m.at_offset(c, rows - 1))
	for r in range(1, rows - 1):
		sides[2].append(m.at_offset(0, r))
		sides[3].append(m.at_offset(cols - 1, r))
	for side in sides:
		var id := 0
		for t in side:
			if t.terrain == &"wand":
				if id == 0:
					id = _next_obj()
				t.obj = id
			else:
				id = 0


## Erreichbarkeit prüfen und Startfelder festlegen
func _finish(cols: int, rows: int, mid: int) -> BattleMap:
	var start := m.at_offset(1, mid)
	if not m.walkable(start):
		return null
	var reach := m.reachable(start.pos, INF)
	for t in m.list:
		if m.walkable(t) and t.h == 0 and not reach.all.has(t.pos):
			return null
	var mid_row := (rows - 1) / 2.0
	var crew: Array[T] = []
	for t in m.list:
		if t.col >= 1 and t.col <= BattleMap.DEPLOY_COLS and m.walkable(t) and t.h == 0:
			crew.append(t)
	crew.sort_custom(func(a: T, b: T) -> bool:
		var da := absf(a.row - mid_row)
		var db := absf(b.row - mid_row)
		return da < db if da != db else a.col < b.col)
	var high: Array[T] = []
	var low: Array[T] = []
	for t in m.list:
		if t.col >= cols - 5 and t.col < cols - 1 and m.walkable(t) and reach.all.has(t.pos):
			(high if t.h > 0 else low).append(t)
	_shuffle(high)
	_shuffle(low)
	var enemy: Array[T] = []
	enemy.append_array(high.slice(0, 2))
	enemy.append_array(low)
	enemy.append_array(high.slice(2))
	if crew.size() < 6 or enemy.size() < Mission.MAX_ENEMIES:
		return null
	m.crew_start = crew
	m.enemy_start = enemy
	return m
