class_name MapGenerator
extends RefCounted
## Kartengenerator. Die Basis baut die Lagerhalle (Galerie, Treppen, Leitern, Hochregale, Container, Kisten,
## Fässer, Barrieren, Säulen); die anderen Kartentypen sind Unterklassen in core/maps/ (MapTypes).
## Jede Karte wird geprüft: alle begehbaren Felder müssen vom Eingang aus erreichbar sein.

const CONTAINER_COLORS := ["#9a4a3a", "#3f6f9a", "#4f7f4a", "#b07a2a", "#6a5a8a", "#8a8a8a"]
const T := BattleMap.Tile
## Generatoren der weiteren Kartentypen
const GENERATORS := {
	&"bar": "res://core/maps/bar_generator.gd",
	&"strasse": "res://core/maps/street_generator.gd",
	&"tempel": "res://core/maps/temple_generator.gd",
	&"buero": "res://core/maps/office_generator.gd",
	&"schiff": "res://core/maps/ship_generator.gd",
}
## Bodenarten (frei für Objekte)
const FLOORS := [&"boden", &"gehweg"]

var m: BattleMap
var rng := RandomNumberGenerator.new()
var size: Dictionary
var _obj := 0
## Startlage (Mission.LAGEN): standard, hinterhalt, zange, verteilt, verteidigung (Crew rechts, Gegner links)
var lage: StringName = &"standard"
## auch erhöhte Felder müssen erreichbar sein (neue Kartentypen; die Halle prüft nur den Boden)
var check_all := false


## Karte zum Einsatz: Typ, Größe, Form und Startlage aus der Mission (Mission.map_type, size_id, square, lage)
## (eigene Karte aus dem Karteneditor, wenn gewählt oder mit CustomMaps.CHANCE aus dem Pool)
static func for_mission(seed_value: int, mission: Mission) -> BattleMap:
	var own := CustomMaps.for_mission(seed_value, mission)
	if own:
		return own
	return generate(seed_value, mission.size_id, mission.map_type, mission.square, mission.lage)


static func generate(seed_value: int, size_id: String, map_type: StringName = &"halle", square := false, start_lage: StringName = &"standard") -> BattleMap:
	var sz: Dictionary = BattleMap.SIZES[1]
	for s in BattleMap.SIZES:
		if s.id == size_id:
			sz = s
	sz = sz.duplicate()
	if square:
		sz.cols = sz.sq
		sz.rows = sz.sq
		sz.square = true
	for attempt in 60:
		var s := seed_value + attempt * 7919
		var gen: MapGenerator = load(GENERATORS[map_type]).new() if GENERATORS.has(map_type) else MapGenerator.new()
		gen.lage = start_lage
		var map := gen._try(s, sz)
		if map:
			map.map_seed = s
			map.size_info = sz
			map.map_type = map_type if GENERATORS.has(map_type) else &"halle"
			map.floor_name = MapTypes.info(map.map_type).floor_name
			return map
	push_error("Keine begehbare Karte gefunden (%s)" % map_type)
	return null


func _ri(a: int, b: int) -> int:
	return rng.randi_range(a, b)


func _next_obj() -> int:
	_obj += 1
	return _obj


func _free(t: T) -> bool:
	return t != null and t.terrain in FLOORS and not t.reserved and t.col > 0 and t.col < m.cols - 1


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
	m = BattleMap.new(sz.cols, sz.rows)
	_layout(sz.cols, sz.rows)
	_group_walls(sz.cols, sz.rows)
	return _finish(sz.cols, sz.rows)


## Grundriss der Lagerhalle (Unterklassen überschreiben das)
func _layout(cols: int, rows: int) -> void:
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


## 1. Galerie an der Rückwand (Reihen 1–2), bei mittel/groß auch an der rechten Wand; Aufstieg nur über Leitern
## (Entscheidung Nutzer 15.10.2026: keine Treppen in der Halle; Gelände „treppe“ und seine Darstellung bleiben
## erhalten, z. B. für Rampen in anderen Karten).
func _build_gallery(cols: int, rows: int, mid: int) -> void:
	var gal := _next_obj()
	for col in range(1, cols - 1):
		for row in [1, 2]:
			_put(m.at_offset(col, row), &"galerie", 3, gal)
	var climb_at: Array = [int(cols * 0.2), int(cols * 0.5), int(cols * 0.75)] if size.id == "gross" else [int(cols * 0.3), int(cols * 0.65)]
	for c in climb_at:
		_put(m.at_offset(c, 3), &"leiter", 0)
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
		if _free(m.at_offset(cols - 4, sr)):
			_put(m.at_offset(cols - 4, sr), &"leiter", 0)
	var lr := _ri(5, rows / 2 - 1)
	if _free(m.at_offset(cols - 4, lr)):
		_put(m.at_offset(cols - 4, lr), &"leiter", 0)
	# rechtes Rolltor schließen, dort steht jetzt die Galerie
	for row in range(mid - 1, mid + 1):
		m.at_offset(cols - 1, row).terrain = &"wand"


## 2. Hochregale: parallele Reihen mit Gängen, je eine Leiter am Ende
func _build_shelves(cols: int, rows: int) -> void:
	var count: int = {"klein": 1, "mittel": 1, "gross": 3 if rng.randf() < 0.5 else 2}[size.id]
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
	var count: int = {"klein": 1, "mittel": 3 if rng.randf() < 0.5 else 2, "gross": 4}[size.id]
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
## SCATTER_DENSITY regelt die Menge (1.0 = so voll wie in der ersten Fassung; 0.5 → 0.3 am 15.10.2026, Spieltest: rund −40 %).
const SCATTER_DENSITY := 0.3

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


## Erreichbarkeit prüfen und Startfelder festlegen (je Lage, Mockup „Frontire Aufstellungen“ 18.10.2026):
## standard: Crew links (Spalten 1 bis DEPLOY_COLS), Gegner rechts (letzte 5 Spalten, erhöhte Felder zuerst);
## hinterhalt: Crew mittig, Gegner abwechselnd links und rechts mit Abstand; zange: 2 von 3 Gegnern rechts, 1 an
## einer Flanke; verteilt: Gegner einzeln über die rechten zwei Drittel; verteidigung: Crew rechts (auch erhöht),
## Gegner links; ueberfall (19.10.2026): Gegner in der Mitte, Crew frei auf allen Feldern mit Abstand
## (mindestens UEBERFALL_GAP Felder weiter von der Mitte als der äußerste Gegner), Startplätze zuerst links.
## enemy_start ist so sortiert, dass die ersten n Felder die Lage ergeben. Die Lage steht danach in BattleMap.lage.
const UEBERFALL_GAP := 4

func _finish(cols: int, rows: int) -> BattleMap:
	var mid_row := (rows - 1) / 2.0
	var mid_col := (cols - 1) / 2.0
	var center := Hex.from_offset(cols / 2, rows / 2)
	var to_center := func(t: T) -> int: return Hex.distance(t.pos, center)
	var ring := 0   # Überfall: Abstand des äußersten der Mission.MAX_ENEMIES Gegnerfelder zur Mitte
	if lage == &"ueberfall":
		var near: Array[T] = []
		for t in m.list:
			if m.walkable(t):
				near.append(t)
		if near.size() < Mission.MAX_ENEMIES:
			return null
		near.sort_custom(func(a: T, b: T) -> bool: return to_center.call(a) < to_center.call(b))
		ring = to_center.call(near[Mission.MAX_ENEMIES - 1])
	var by_row := func(a: T, b: T) -> bool:
		var da := absf(a.row - mid_row)
		var db := absf(b.row - mid_row)
		return da < db if da != db else a.col < b.col
	var in_cols := func(t: T, c0: int, c1: int) -> bool: return t.col >= c0 and t.col <= c1
	# Crew-Bereich
	var crew: Array[T] = []
	for t in m.list:
		if not m.walkable(t):
			continue
		match lage:
			&"verteidigung":
				if in_cols.call(t, cols - 1 - BattleMap.DEPLOY_COLS - 1, cols - 2):
					crew.append(t)
			&"hinterhalt":
				if t.h == 0 and absf(t.col - mid_col) <= 3.0 and absf(t.row - mid_row) <= 4.0:
					crew.append(t)
			&"ueberfall":
				if to_center.call(t) >= ring + UEBERFALL_GAP:
					crew.append(t)
			_:
				if t.h == 0 and in_cols.call(t, 1, BattleMap.DEPLOY_COLS):
					crew.append(t)
	if crew.size() < Campaign.HARD_SQUAD:
		return null
	if lage == &"hinterhalt":
		crew.sort_custom(func(a: T, b: T) -> bool:
			return absf(a.col - mid_col) + absf(a.row - mid_row) < absf(b.col - mid_col) + absf(b.row - mid_row))
	elif lage == &"ueberfall":
		crew.sort_custom(func(a: T, b: T) -> bool:
			return a.col < b.col if a.col != b.col else absf(a.row - mid_row) < absf(b.row - mid_row))
	else:
		crew.sort_custom(by_row)
	var reach := m.reachable(crew[0].pos, INF)
	for t in m.list:
		if m.walkable(t) and (t.h == 0 or check_all) and not reach.all.has(t.pos):
			return null
	crew = crew.filter(func(t: T) -> bool: return reach.all.has(t.pos))
	var ok := func(t: T) -> bool: return m.walkable(t) and reach.all.has(t.pos) and not crew.has(t)
	# Gegner
	var enemy: Array[T] = []
	match lage:
		&"verteidigung":
			enemy = _side(func(t: T) -> bool: return in_cols.call(t, 1, 5) and ok.call(t))
		&"ueberfall":
			for t in m.list:
				if ok.call(t) and to_center.call(t) < ring + UEBERFALL_GAP:
					enemy.append(t)
			_shuffle(enemy)
			enemy.sort_custom(func(a: T, b: T) -> bool: return to_center.call(a) < to_center.call(b))
		&"hinterhalt":
			var gap := mini(6, cols / 4)
			var far := func(t: T) -> bool:
				for c in crew:
					if Hex.distance(c.pos, t.pos) < gap:
						return false
				return true
			var left := _side(func(t: T) -> bool: return in_cols.call(t, 1, 5) and ok.call(t) and far.call(t))
			var right := _side(func(t: T) -> bool: return in_cols.call(t, cols - 6, cols - 2) and ok.call(t) and far.call(t))
			enemy = _mix([left, right], [1, 1])
		&"zange":
			var right := _side(func(t: T) -> bool: return in_cols.call(t, cols - 6, cols - 2) and ok.call(t))
			var top := rng.randf() < 0.5
			var flank := _side(func(t: T) -> bool:
				return in_cols.call(t, int(mid_col) - 3, int(mid_col) + 4) and ok.call(t) \
					and (t.row <= 4 if top else t.row >= rows - 5))
			enemy = _mix([right, flank], [2, 1])
		&"verteilt":
			var pool: Array[T] = []
			for t in m.list:
				if t.col >= cols / 3 and t.col < cols - 1 and ok.call(t):
					pool.append(t)
			_shuffle(pool)
			for t in pool:
				if enemy.all(func(o: T) -> bool: return Hex.distance(o.pos, t.pos) >= 3):
					enemy.append(t)
			for t in pool:
				if not enemy.has(t):
					enemy.append(t)
		_:
			enemy = _side(func(t: T) -> bool: return in_cols.call(t, cols - 6, cols - 2) and ok.call(t))
	if crew.size() < Campaign.HARD_SQUAD or enemy.size() < Mission.MAX_ENEMIES:
		return null
	m.crew_start = crew
	m.enemy_start = enemy
	m.lage = lage
	return m


## Felder einer Seite, gemischt: zwei erhöhte zuerst (Schützen oben), dann Boden, dann übrige erhöhte
func _side(pick: Callable) -> Array[T]:
	var high: Array[T] = []
	var low: Array[T] = []
	for t in m.list:
		if pick.call(t):
			(high if t.h > 0 else low).append(t)
	_shuffle(high)
	_shuffle(low)
	var out: Array[T] = []
	out.append_array(high.slice(0, 2))
	out.append_array(low)
	out.append_array(high.slice(2))
	return out


## Listen im Verhältnis weights abwechselnd zusammenführen (z. B. 2 rechts, 1 Flanke, 2 rechts, …)
func _mix(lists: Array, weights: Array) -> Array[T]:
	var out: Array[T] = []
	var idx := []
	for l in lists:
		idx.append(0)
	var any := true
	while any:
		any = false
		for i in lists.size():
			for k in weights[i]:
				if idx[i] < lists[i].size():
					out.append(lists[i][idx[i]])
					idx[i] += 1
					any = true
	return out


# ---------------------------------------------------------------- Bausteine für die Kartentypen

## Rechteck aus Feldern anlegen (alle Felder der Karte zuerst als Boden)
func _ground(cols: int, rows: int, terrain: StringName = &"boden") -> void:
	for row in rows:
		for col in cols:
			m.add_floor(col, row, terrain)


## Außenwand rundum, Eingang links in der Mitte (n Felder hoch)
func _border(cols: int, rows: int, door := 4) -> void:
	for col in cols:
		m.at_offset(col, 0).terrain = &"wand"
		m.at_offset(col, rows - 1).terrain = &"wand"
	for row in rows:
		m.at_offset(0, row).terrain = &"wand"
		m.at_offset(cols - 1, row).terrain = &"wand"
	var mid := rows / 2
	for row in range(mid - door / 2, mid - door / 2 + door):
		m.at_offset(0, row).terrain = &"boden"


## Feld setzen (ohne Prüfung); obj > 0 verbindet Felder zu einem Objekt
func _cell(col: int, row: int, terrain: StringName, h := 0, obj := 0) -> T:
	var t := m.at_offset(col, row)
	if t == null:
		return null
	_put(t, terrain, h, obj)
	return t


## Rechteck mit einem Gelände füllen
func _rect(c0: int, r0: int, w: int, h: int, terrain: StringName, hh := 0, obj := -1) -> Array[T]:
	var o := _next_obj() if obj < 0 else obj
	var out: Array[T] = []
	for r in range(r0, r0 + h):
		for c in range(c0, c0 + w):
			var t := _cell(c, r, terrain, hh, o)
			if t:
				out.append(t)
	return out


## Wand von (c, r0) bis (c, r1) senkrecht bzw. (c0..c1, r) waagerecht; gaps = Durchgänge (Startfeld, Breite)
func _vwall(c: int, r0: int, r1: int, gaps: Array = [], terrain: StringName = &"innenwand") -> void:
	for r in range(r0, r1 + 1):
		if not _in_gap(r, gaps):
			_cell(c, r, terrain)


func _hwall(r: int, c0: int, c1: int, gaps: Array = [], terrain: StringName = &"innenwand") -> void:
	for c in range(c0, c1 + 1):
		if not _in_gap(c, gaps):
			_cell(c, r, terrain)


func _in_gap(i: int, gaps: Array) -> bool:
	for g in gaps:
		if i >= g[0] and i < g[0] + g[1]:
			return true
	return false


## n Objekte w×h an freie Stellen im Bereich (c0, r0)–(c1, r1) setzen, mit freiem Rand drumherum
func _place(terrain: StringName, w: int, h: int, n: int, c0: int, r0: int, c1: int, r1: int, hh := 0) -> int:
	var placed := 0
	var tries := 0
	while placed < n and tries < n * 40 + 20:
		tries += 1
		var c := _ri(c0, maxi(c0, c1 - w + 1))
		var r := _ri(r0, maxi(r0, r1 - h + 1))
		var ok := true
		for y in range(r - 1, r + h + 1):
			for x in range(c - 1, c + w + 1):
				var t := m.at_offset(x, y)
				var inside := x >= c and x < c + w and y >= r and y < r + h
				if inside and not _free(t):
					ok = false
				elif not inside and t and t.reserved and not t.terrain in [&"wand", &"innenwand", &"gebaeude"]:
					ok = false
		if not ok:
			continue
		_rect(c, r, w, h, terrain, hh)
		placed += 1
	return placed
