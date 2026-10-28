class_name MapView
extends Node3D
## Baut die Karte als 3D-Szene aus einer BattleMap (Lagerhalle und weitere Kartentypen, MapTypes). Das Hexraster
## ist nur Spielmechanik (einblendbar), Objekte werden als ganze Körper gezeichnet. Außenwände zur Kamera hin
## werden niedrig geschnitten; Innenwände sind niedriger (INNER_H), damit man in die Räume sieht.

const L := BattleMap.LEVEL_M
const WALL_H := 7.5
const WALL_LOW := 0.9
const INNER_H := 2.4
const MAX_LAMPS := 12
const BUILDING_H := 3.6
## Sichtbare Höhe (m) der Objekte der neuen Kartentypen; true = ganzes Objekt (Gruppe) als ein Modell
const PROP_H := {&"theke": 1.15, &"tisch": 0.8, &"sofa": 0.9, &"schrank": 2.4, &"server": 2.2, &"auto": 2.0,
	&"laterne": 5.0, &"tonne": 1.3, &"steinsaeule": 6.0, &"bruch": 1.5, &"geroell": 0.9, &"altar": 1.2,
	&"statue": 3.0, &"schreibtisch": 0.78, &"konsole": 1.1, &"tank": 3.2}
const PROP_GROUP := [&"theke", &"schrank", &"server", &"auto", &"sofa"]
## Grundkörperfarben, wenn kein Modell da ist
const PROP_COLOR := {&"theke": Color(0.45, 0.28, 0.18), &"tisch": Color(0.5, 0.34, 0.2), &"sofa": Color(0.5, 0.18, 0.28),
	&"schrank": Color(0.42, 0.3, 0.2), &"server": Color(0.15, 0.17, 0.2), &"auto": Color(0.6, 0.2, 0.18),
	&"laterne": Color(0.25, 0.27, 0.3), &"tonne": Color(0.2, 0.4, 0.25), &"steinsaeule": Color(0.6, 0.55, 0.45),
	&"bruch": Color(0.58, 0.52, 0.42), &"geroell": Color(0.5, 0.45, 0.38), &"altar": Color(0.62, 0.56, 0.45),
	&"statue": Color(0.55, 0.52, 0.48), &"schreibtisch": Color(0.55, 0.45, 0.32), &"konsole": Color(0.3, 0.36, 0.45),
	&"tank": Color(0.45, 0.5, 0.56)}

var map: BattleMap
## Modelle für die Halle (leere Einträge: Grundkörper)
var theme: HallTheme
var _models := ModelBatch.new()
var _grid: MeshInstance3D
var _walls: Array = []   # [{full: Node3D, low: Node3D, normal: Vector3}]
var _mats := {}
var _rng := RandomNumberGenerator.new()
## Statische Geometrie wird je Material zu wenigen Meshes zusammengefasst (wenige Zeichenaufrufe)
var _batches := {}
var _groups := {}
var _box_meshes := {}
## Kartentyp (MapTypes.info) und Modelle der Typen (Pfad → VisualSlot)
var _type: Dictionary = {}
var _hall := true
## Hallenstil je Karte (Nutzer 28.10.2026): -1 = alte Wände und alter Boden, sonst Nummer des Wandpaars aus
## MapTypes "hall_walls" (dann MegaKit-Boden); Einrichtung bleibt gemischt
var _wall_style := -1
static var _slots := {}


func build(m: BattleMap) -> void:
	for c in get_children():
		c.queue_free()
	_walls.clear()
	map = m
	_type = MapTypes.info(m.map_type)
	_hall = m.map_type == &"halle"
	_rng.seed = m.map_seed
	_wall_style = -1
	var styles: Array = _type.get("hall_walls", _type.get("facades", []))
	if not styles.is_empty():   # eigener Zufall, damit die übrige Karte gleich bleibt
		var wr := RandomNumberGenerator.new()
		wr.seed = hash([m.map_seed, "wandstil"])
		_wall_style = wr.randi_range(0, styles.size()) - 1
	_groups.clear()
	_build_floor()
	_build_objects()
	if _type.has("deco"):
		_deco()
	_commit()
	_models.build(_group)
	_build_grid()
	_build_lights()


## Oberseite eines Feldes in der Welt
func tile_top(p: Vector2i) -> Vector3:
	var w := Hex.to_world(p)
	var t := map.tile(p)
	return Vector3(w.x, (t.h if t else 0) * L, w.y)


func center() -> Vector3:
	return Vector3(map.cols * Hex.SIZE_M / 2.0, 0, map.rows * Hex.ROW_M / 2.0)


func set_grid_visible(v: bool) -> void:
	_grid.visible = v


## Wände auf der Kameraseite niedrig zeigen, damit man in die Halle sieht
func update_cutaway(view_dir: Vector3) -> void:
	for w in _walls:
		var low: bool = w.normal.dot(view_dir) > 0.2
		w.full.visible = not low
		w.low.visible = low


# ---------------------------------------------------------------- Boden, Raster, Licht

func _build_floor() -> void:
	var sx := map.cols * Hex.SIZE_M + 1.5
	var sz := map.rows * Hex.ROW_M + 1.3
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(sx + 6.0, sz + 6.0)
	floor_mi.mesh = pm
	floor_mi.position = Vector3(sx / 2.0 - 0.75, 0.0 if _hall else -0.04, sz / 2.0 - 0.65)
	var fm := StandardMaterial3D.new()
	var nt := NoiseTexture2D.new()
	var noise := FastNoiseLite.new()
	noise.frequency = 0.015
	noise.fractal_octaves = 4
	nt.noise = noise
	nt.seamless = true
	nt.width = 512
	nt.height = 512
	var grad := Gradient.new()
	grad.set_color(0, Color(0.8, 0.8, 0.82))
	grad.set_color(1, Color(1, 1, 1))
	nt.color_ramp = grad
	fm.albedo_texture = nt
	fm.albedo_color = Color(0.37, 0.38, 0.41) if _hall else (_type.bg as Color).lightened(0.06)
	fm.roughness = 0.92
	fm.uv1_scale = Vector3(pm.size.x / 10.0, pm.size.y / 10.0, 1)
	floor_mi.material_override = fm
	add_child(floor_mi)
	if not _hall:
		_type_floor()
		return
	if _type.has("floors") and _wall_style >= 0:
		_pack_floor()
	elif theme and theme.floor_tile:
		_floor_tiles(sx, sz)
	# Fahrspuren und Markierungen
	var lane := Color(0.85, 0.68, 0.15)
	var mid_z := (map.rows / 2) * Hex.ROW_M
	_box(Vector3(sx / 2.0, 0.004, mid_z - 2.4), Vector3(sx - 4.0, 0.01, 0.12), lane)
	_box(Vector3(sx / 2.0, 0.004, mid_z + 2.4), Vector3(sx - 4.0, 0.01, 0.12), lane)
	for i in range(3, int(sx) - 3, 6):
		_box(Vector3(i, 0.004, mid_z), Vector3(2.0, 0.01, 0.1), Color(0.75, 0.75, 0.78))


## Bodenplatten über die ganze Halle (die Fläche darunter bleibt als Rand sichtbar)
func _floor_tiles(sx: float, sz: float) -> void:
	var slot := theme.floor_tile
	var a := _models.aabb(slot)
	var tx := a.size.x
	var tz := a.size.z
	var nx := ceili(sx / tx)
	var nz := ceili(sz / tz)
	for ix in nx:
		for iz in nz:
			var c := Vector3(-0.75 + (ix + 0.5) * tx, -a.size.y, -0.65 + (iz + 0.5) * tz)
			_models.add(slot, _models.fit_box(slot, c, a.size))


## Neue Kartentypen: Boden je Feld als flache Sechseckplatte (Farbe je Typ, Gehweg heller, leichte Streuung)
func _type_floor() -> void:
	if _type.has("floors"):
		_pack_floor()
		return
	var base: Color = _type.floor
	for t in map.list:
		if t.terrain == &"leer" or t.terrain == &"gebaeude" or t.terrain == &"podest":
			continue
		var c: Color = _type.get("gehweg", base) if t.terrain == &"gehweg" else base
		var k := (hash(t.pos) % 5) * 0.012
		_hex_slab(Vector3(Hex.to_world(t.pos).x, 0.0 if t.terrain != &"gehweg" else 0.08, Hex.to_world(t.pos).y),
			0.05 if t.terrain != &"gehweg" else 0.13, c.darkened(k))
		if t.terrain == &"gehweg" and _type.has("sidewalk") and _wall_style >= 0:
			# Gehwegplatte je Feld (1,5 × 1,3 m, lückenlos in der Reihe)
			var sw: Array = _type.sidewalk
			var slot := _slot(sw[_rng.randi() % sw.size()], VisualSlot.Fit.STRETCH)
			var a := _models.aabb(slot)
			var w := Hex.to_world(t.pos)
			var basis := Basis.from_scale(Vector3(Hex.SIZE_M / maxf(a.size.x, 0.01), 1.0, Hex.ROW_M / maxf(a.size.z, 0.01)))
			_models.add(slot, Transform3D(basis, Vector3(w.x, 0.083, w.y) - basis * Vector3(a.get_center().x, a.end.y, a.get_center().z)))


## Bodenplatten aus einem Pack (MapTypes "floors"): Quadratraster ("floor_step", sonst 2 m) unter dem Hexraster,
## Modell je Zone (Anteil der Kartenbreite) zufällig, Warnstreifen ("floor_hazard") vor der Luftschleuse links
func _pack_floor() -> void:
	var step: float = _type.get("floor_step", 2.0)
	var w := map.cols * Hex.SIZE_M
	var d := map.rows * Hex.ROW_M
	var x := -0.75
	while x < w:
		var z := -0.65
		while z < d:
			var c := Vector2(x + step / 2.0, z + step / 2.0)
			var t := map.tile(Hex.from_world(c))
			if t and t.terrain != &"leer":
				var path: String = _type.floor_hazard if _type.has("floor_hazard") and c.x < 4.0 and absf(c.y - d / 2.0) < 2.2 else ""
				if path == "":
					for zone in _type.floors:
						if c.x / w < zone[0]:
							path = zone[1][_rng.randi() % zone[1].size()]
							break
				_flat(_slot(path, VisualSlot.Fit.STRETCH), Vector3(c.x, 0.003, c.y), step)
			z += step
		x += step


## Flaches Modell (Bodenplatte) auf size × size strecken, Oberseite auf top
func _flat(slot: VisualSlot, top: Vector3, size: float) -> void:
	var a := _models.aabb(slot)
	var basis := Basis.from_scale(Vector3(size / maxf(a.size.x, 0.01), 1.0, size / maxf(a.size.z, 0.01)))
	var anchor := Vector3(a.get_center().x, a.end.y, a.get_center().z)
	_models.add(slot, Transform3D(basis, top - basis * anchor))


## Innenwände als gerade Pack-Wände? Schiff immer, Typen mit Stilwahl nur bei Pack-Stil
func _kit_inner() -> bool:
	if not _type.has("wall_panels"):
		return false
	return _wall_style >= 0 or not (_type.has("hall_walls") or _type.has("facades"))


## Gerade Wände (MapTypes "wall_panels", Nutzer 28.10.2026) statt Sechseckblöcken: Reihen von Wandfeldern in einer
## Zeile oder einer Spalte werden je eine gerade Wand durch die Feldmitten, übrige Nachbarn (Bug, Heck-Stufen,
## Anschlüsse an Reihenenden) schräge Stücke von Feldmitte zu Feldmitte; an Enden und Knicken ein Pfosten.
## Die Felder bleiben gesperrt wie bisher, nur die Grafik ist schlanker (WALL_THICK).
func _straight_walls(ts: Array) -> void:
	var tiles := {}
	for t in ts:
		tiles[t.pos] = t
	var run_of := {}   # pos → [Laufnummer, ist Ende]
	var runs: Array = []
	# waagerecht: gleiche Zeile, aufeinanderfolgende Spalten
	var by_row := {}
	for t in ts:
		if not by_row.has(t.row):
			by_row[t.row] = []
		by_row[t.row].append(t)
	for r in by_row:
		var row: Array = by_row[r]
		row.sort_custom(func(x, y) -> bool: return x.col < y.col)
		var i := 0
		while i < row.size():
			var j := i
			while j + 1 < row.size() and row[j + 1].col == row[j].col + 1:
				j += 1
			if j > i:
				_add_run(runs, run_of, row.slice(i, j + 1))
			i = j + 1
	# senkrecht: gleiche Spalte (Versatz), aufeinanderfolgende Zeilen, mindestens 3
	var by_col := {}
	for t in ts:
		if run_of.has(t.pos):
			continue
		if not by_col.has(t.col):
			by_col[t.col] = []
		by_col[t.col].append(t)
	for c in by_col:
		var col: Array = by_col[c]
		col.sort_custom(func(x, y) -> bool: return x.row < y.row)
		var i := 0
		while i < col.size():
			var j := i
			while j + 1 < col.size() and col[j + 1].row == col[j].row + 1:
				j += 1
			if j - i >= 2:
				_add_run(runs, run_of, col.slice(i, j + 1))
			i = j + 1
	for run in runs:
		var first: Vector2 = Hex.to_world(run[0].pos)
		var last: Vector2 = Hex.to_world(run[-1].pos)
		if run[0].row != run[-1].row:   # senkrecht: gerade Linie auf mittlerem x
			var mx := 0.0
			for t in run:
				mx += Hex.to_world(t.pos).x
			mx /= run.size()
			first = Vector2(mx, first.y)
			last = Vector2(mx, last.y)
		_wall_segment(first, last)
	# schräge Stücke: zwischen Nachbarn, die nicht in derselben Reihe liegen; Reihen nur über ihre Enden
	var posts := {}
	for t in ts:
		var rt: Array = run_of.get(t.pos, [-1, true])
		for n in Hex.neighbors(t.pos):
			if not tiles.has(n) or str(n) < str(t.pos):
				continue
			var rn: Array = run_of.get(n, [-2, true])
			if rt[0] == rn[0] or not rt[1] or not rn[1]:
				continue
			_wall_segment(_wall_point(t, run_of, runs), _wall_point(tiles[n], run_of, runs))
			posts[t.pos] = true
			posts[n] = true
	for t in ts:
		if not run_of.has(t.pos) or run_of[t.pos][1]:
			posts[t.pos] = true
	for p in posts:
		var w := _wall_point(tiles[p], run_of, runs)
		_box(Vector3(w.x, INNER_H / 2.0 + 0.01, w.y), Vector3(WALL_THICK + 0.08, INNER_H + 0.02, WALL_THICK + 0.08), _type.get("inner", Color(0.4, 0.45, 0.5)))


const WALL_THICK := 0.4


func _add_run(runs: Array, run_of: Dictionary, run: Array) -> void:
	for k in run.size():
		run_of[run[k].pos] = [runs.size(), k == 0 or k == run.size() - 1]
	runs.append(run)


## Mittelpunkt eines Wandfelds auf seiner Wandlinie (senkrechte Reihen: mittleres x)
func _wall_point(t: BattleMap.Tile, run_of: Dictionary, runs: Array) -> Vector2:
	var w := Hex.to_world(t.pos)
	if run_of.has(t.pos):
		var run: Array = runs[run_of[t.pos][0]]
		if run[0].row != run[-1].row:
			var mx := 0.0
			for r in run:
				mx += Hex.to_world(r.pos).x
			w.x = mx / run.size()
	return w


## Gerade Wand von a nach b (Welt x/z) aus Wandplatten, je Stück höchstens etwa 3 m
func _wall_segment(a: Vector2, b: Vector2) -> void:
	var paths: Array = _type.wall_panels
	if paths.is_empty():   # Wandteil des Wandpaars der Karte
		paths = [_type.hall_walls[_wall_style][0]]
	var length := a.distance_to(b)
	if length < 0.05:
		return
	var dir := (b - a) / length
	var n := maxi(1, roundi(length / 3.0))
	var piece := length / n
	var rot := atan2(-dir.y, dir.x)   # Modell-x entlang der Wand
	for i in n:
		var slot := _slot(paths[_rng.randi() % paths.size()], VisualSlot.Fit.STRETCH)
		var ab := _models.aabb(slot)
		var m := a + dir * piece * (i + 0.5)
		var basis := Basis(Vector3.UP, rot) * Basis.from_scale(Vector3((piece + 0.02) / ab.size.x, INNER_H / ab.size.y, WALL_THICK / ab.size.z))
		if ab.size.z > ab.size.x:   # Modell liegt längs z (MegaKit): z entlang der Wand, eigene Dicke
			basis = Basis(Vector3.UP, atan2(dir.x, dir.y)) * Basis.from_scale(Vector3(1.0, INNER_H / ab.size.y, (piece + 0.02) / ab.size.z))
		var anchor := Vector3(ab.get_center().x, ab.position.y, ab.get_center().z)
		_models.add(slot, Transform3D(basis, Vector3(m.x, 0.0, m.y) - basis * anchor))


## Neues Modell statt des alten (MapTypes "alt", je Objekt mit "alt_chance"): Modellpfade oder leer
func _alt_paths(terrain: StringName) -> Array:
	var alt: Dictionary = _type.get("alt", {})
	if alt.has(terrain) and _rng.randf() < float(_type.get("alt_chance", 1.0)):
		return alt[terrain]
	return []


## Wenig Deko (nur Grafik, MapTypes "deco"): kleine Modelle an Bodenfeldern neben Wänden, zur Wand gerückt
func _deco() -> void:
	var spots: Array = []
	for t in map.list:
		if t.terrain != &"boden" or t.reserved:
			continue
		for n in Hex.neighbors(t.pos):
			var nt := map.tile(n)
			if nt and nt.terrain == &"innenwand":
				spots.append([t, n])
				break
	var paths: Array = _type.deco
	for i in mini(10, spots.size() / 12):
		var sp: Array = spots[_rng.randi() % spots.size()]
		var a := Hex.to_world(sp[0].pos)
		var p := a + (Hex.to_world(sp[1]) - a).normalized() * 0.42
		_fit_uniform(_slot(paths[_rng.randi() % paths.size()]), Vector3(p.x, 0.0, p.y), Vector3(0.5, 0.8, 0.5), _rng.randf() * TAU)


func _build_grid() -> void:
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var cs := Hex.corners(Hex.RADIUS_M * 0.98)
	for t in map.list:
		if not map.walkable(t):
			continue
		var c := tile_top(t.pos) + Vector3(0, 0.03, 0)
		for i in 6:
			var a: Vector2 = cs[i]
			var b: Vector2 = cs[(i + 1) % 6]
			im.surface_add_vertex(c + Vector3(a.x, 0, a.y))
			im.surface_add_vertex(c + Vector3(b.x, 0, b.y))
	im.surface_end()
	_grid = MeshInstance3D.new()
	_grid.mesh = im
	_grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.13)
	_grid.material_override = m
	add_child(_grid)


func _build_lights() -> void:
	if not _hall:
		_type_lights()
		return
	var nx := clampi(map.cols / 12, 2, 4)
	var nz := clampi(map.rows / 14, 1, 2)
	for ix in nx:
		for iz in nz:
			var p := Vector3((ix + 0.5) * map.cols * Hex.SIZE_M / nx, 8.0, (iz + 0.5) * map.rows * Hex.ROW_M / nz)
			var lamp := OmniLight3D.new()
			lamp.position = p
			lamp.omni_range = 16.0
			lamp.light_energy = 1.1
			lamp.light_color = Color(1.0, 0.92, 0.78)
			add_child(lamp)


## Licht der neuen Kartentypen: Lampen im Raster (Farben im Wechsel) oder an den Laternen (Straße)
func _type_lights() -> void:
	var colors: Array = _type.lamps
	var spots: Array = []
	if _type.has("lamps_at"):
		for t in map.list:
			if t.terrain == _type.lamps_at:
				spots.append(Vector3(Hex.to_world(t.pos).x, _type.lamp_h, Hex.to_world(t.pos).y))
	else:
		var nx := clampi(map.cols / 9, 2, 4)
		var nz := clampi(map.rows / 9, 2, 3)
		for ix in nx:
			for iz in nz:
				spots.append(Vector3((ix + 0.5) * map.cols * Hex.SIZE_M / nx, _type.lamp_h, (iz + 0.5) * map.rows * Hex.ROW_M / nz))
	while spots.size() > MAX_LAMPS:   # höchstens MAX_LAMPS Lichter (Leistung), gleichmäßig ausgedünnt
		spots = spots.filter(func(_p: Vector3) -> bool: return true).slice(0, spots.size(), 2)
	for i in spots.size():
		var lamp := OmniLight3D.new()
		lamp.position = spots[i]
		lamp.omni_range = _type.lamp_range
		lamp.light_energy = _type.lamp_energy
		lamp.light_color = colors[i % colors.size()]
		add_child(lamp)


# ---------------------------------------------------------------- Objekte

func _build_objects() -> void:
	var groups := {}
	for t in map.list:
		if t.terrain == &"boden":
			continue
		var key: Variant = t.obj if t.obj > 0 else t.pos
		if not groups.has(key):
			groups[key] = []
		groups[key].append(t)
	for key in groups:
		var ts: Array = groups[key]
		match ts[0].terrain:
			&"container":
				_container(ts)
			&"regal":
				_shelf(ts)
			&"galerie":
				_gallery(ts)
			&"kiste":
				_crates(ts)
			&"barriere":
				_barrier(ts)
			&"fass":
				_barrels(ts[0])
			&"saeule":
				_pillar(ts[0])
			&"wand":
				_wall(ts)
			&"treppe":
				_stairs(ts[0])
			&"leiter":
				_ladder(ts[0])
			&"innenwand":
				if not _kit_inner():   # sonst gerade Wände über alle Wandfelder, nach der Schleife
					for t in ts:
						_hex_slab(tile_top(t.pos) + Vector3(0, INNER_H, 0), INNER_H, _type.get("inner", Color(0.3, 0.33, 0.38)))
			&"gebaeude":
				if _type.has("facades") and _wall_style >= 0:
					continue   # Häuser mit Fassaden nach der Schleife
				for t in ts:
					_hex_slab(tile_top(t.pos) + Vector3(0, BUILDING_H, 0), BUILDING_H, _type.get("wall", Color(0.3, 0.3, 0.3)).darkened((hash(t.col / 4) % 4) * 0.06))
			&"podest":
				for t in ts:
					_hex_slab(tile_top(t.pos), t.h * L, _type.get("podest", Color(0.4, 0.4, 0.42)))
			&"boden", &"gehweg", &"leer":
				pass
			_:
				if PROP_H.has(ts[0].terrain):
					_prop(ts)
	if _kit_inner():
		_straight_walls(map.list.filter(func(t: BattleMap.Tile) -> bool: return t.terrain == &"innenwand"))
	if _type.has("facades") and _wall_style >= 0:
		_buildings(map.list.filter(func(t: BattleMap.Tile) -> bool: return t.terrain == &"gebaeude"))


## Umriss einer Feldgruppe: Mitte und Größe (x, z) eines achsenparallelen Quaders
func _bounds(ts: Array) -> Dictionary:
	var minx := INF
	var maxx := -INF
	var minz := INF
	var maxz := -INF
	var parity := {}
	for t in ts:
		var w := Hex.to_world(t.pos)
		minx = minf(minx, w.x)
		maxx = maxf(maxx, w.x)
		minz = minf(minz, w.y)
		maxz = maxf(maxz, w.y)
		parity[t.row & 1] = true
	var sx := maxx - minx + Hex.SIZE_M - (0.75 if parity.size() == 2 else 0.0)
	var sz := maxz - minz + 1.3
	return {"c": Vector3((minx + maxx) / 2.0, 0, (minz + maxz) / 2.0), "sx": sx, "sz": sz}


func _container(ts: Array) -> void:
	var b := _bounds(ts)
	var h: int = ts[0].h
	var alt := _alt_paths(&"container")
	if not alt.is_empty():
		_fit_uniform(_slot(alt[_rng.randi() % alt.size()]), b.c, Vector3(b.sx - 0.1, h * L, b.sz - 0.1), _rng.randi_range(0, 3) * PI / 2.0)
		return
	var color: Color = ts[0].color
	var sx: float = b.sx - 0.1
	var sz: float = b.sz - 0.1
	for level in range(0, h, 2):
		var c: Color = color if level == 0 else color.lightened(0.12).lerp(Color(0.5, 0.55, 0.6), 0.3)
		var y := level * L + L
		_box(b.c + Vector3(0, y, 0), Vector3(sx, 2 * L - 0.04, sz), c, "", 0.0, _mat(c, 0.55, 0.35))
		var long_x := sx > sz
		var length := sx if long_x else sz
		var n := int(length / 0.45)
		for i in n:
			var off := -length / 2.0 + 0.25 + i * (length - 0.5) / maxf(1.0, n - 1.0)
			for side in [-1.0, 1.0]:
				var p: Vector3 = b.c + Vector3(0, y, 0)
				if long_x:
					p += Vector3(off, 0, side * (sz / 2.0 + 0.02))
				else:
					p += Vector3(side * (sx / 2.0 + 0.02), 0, off)
				_box(p, Vector3(0.06, 2 * L - 0.3, 0.06), c.darkened(0.25))
		for px in [-1.0, 1.0]:
			for pz in [-1.0, 1.0]:
				_box(b.c + Vector3(px * (sx / 2.0 - 0.06), y, pz * (sz / 2.0 - 0.06)), Vector3(0.16, 2 * L, 0.16), c.darkened(0.4))


func _shelf(ts: Array) -> void:
	var b := _bounds(ts)
	var top: float = ts[0].h * L
	var alt := _alt_paths(&"regal")
	if not alt.is_empty():
		# Rohrlager: Lagen von Rohrhaltern übereinander, Deckplatte oben (begehbar)
		var slot := _slot(alt[_rng.randi() % alt.size()], VisualSlot.Fit.STRETCH, 4.0)
		var layers := maxi(1, roundi(top / 1.0))
		for i in layers:
			_models.fill_repeat(slot, b.c + Vector3(0, i * top / layers, 0), Vector3(b.sx - 0.1, top / layers - 0.05, b.sz - 0.1))
		_box(b.c + Vector3(0, top - 0.04, 0), Vector3(b.sx - 0.1, 0.08, b.sz - 0.1), Color(0.4, 0.42, 0.46))
		return
	if theme and theme.shelf:
		_models.fill_repeat(theme.shelf, b.c, Vector3(b.sx - 0.1, top, b.sz - 0.1))
		# Deckplatte oben (begehbar)
		_box(b.c + Vector3(0, top - 0.04, 0), Vector3(b.sx - 0.1, 0.08, b.sz - 0.1), Color(0.4, 0.42, 0.46))
		return
	var sx: float = b.sx - 0.2
	var sz: float = b.sz - 0.2
	var steel := Color(0.3, 0.42, 0.62)
	var long_x := sx > sz
	var length := sx if long_x else sz
	var posts := int(length / 1.5) + 1
	for i in posts:
		var off := -length / 2.0 + i * length / maxf(1.0, posts - 1.0)
		for side in [-1.0, 1.0]:
			var p: Vector3 = b.c + (Vector3(off, top / 2.0, side * sz / 2.0) if long_x else Vector3(side * sx / 2.0, top / 2.0, off))
			_box(p, Vector3(0.1, top, 0.1), steel)
	for lv in [0.15, L, 2 * L, top - 0.06]:
		_box(b.c + Vector3(0, lv, 0), Vector3(sx, 0.08, sz), Color(0.55, 0.36, 0.2) if lv < top - 0.1 else Color(0.4, 0.42, 0.46))
	# Kartons auf den Böden
	var cols := [Color(0.72, 0.56, 0.36), Color(0.62, 0.48, 0.3), Color(0.45, 0.5, 0.58), Color(0.7, 0.66, 0.6)]
	for lv in [0.2, L + 0.05, 2 * L + 0.05]:
		var n := int(length / 0.75)
		for i in n:
			if _rng.randf() < 0.18:
				continue
			var off := -length / 2.0 + 0.4 + i * (length - 0.8) / maxf(1.0, n - 1.0)
			var hh := _rng.randf_range(0.6, 1.25)
			var p: Vector3 = b.c + (Vector3(off, lv + hh / 2.0, 0) if long_x else Vector3(0, lv + hh / 2.0, off))
			var s := Vector3(0.65, hh, minf(sz, sx) - 0.25) if long_x else Vector3(minf(sz, sx) - 0.25, hh, 0.65)
			_box(p, s, cols[_rng.randi() % cols.size()])


func _gallery(ts: Array) -> void:
	var deck := Color(0.42, 0.46, 0.52)
	for t in ts:
		var top := tile_top(t.pos)
		_hex_slab(top, 0.3, deck)
	var b := _bounds(ts)
	var top_y: float = ts[0].h * L
	# Stützen und Unterzug an der offenen Seite
	var long_x: bool = b.sx > b.sz
	var length: float = b.sx if long_x else b.sz
	for i in int(length / 3.0) + 1:
		var off: float = -length / 2.0 + 0.5 + i * 3.0
		if off > length / 2.0:
			break
		for side in [-1.0, 1.0]:
			var p: Vector3 = b.c + (Vector3(off, top_y / 2.0, side * (b.sz / 2.0 - 0.3)) if long_x else Vector3(side * (b.sx / 2.0 - 0.3), top_y / 2.0, off))
			_box(p, Vector3(0.22, top_y, 0.22), Color(0.26, 0.29, 0.34))
	# Geländer an allen Kanten zu tieferen Feldern (außer Treppenanschluss und Leiter; nur Grafik, sperrt den Weg nicht)
	var rail := Color(0.85, 0.68, 0.15)
	for t in ts:
		for n in Hex.neighbors(t.pos):
			var nt := map.tile(n)
			if nt == null or nt.terrain in [&"wand", &"galerie", &"leiter"] or nt.h >= t.h - 1:
				continue
			var a := Hex.to_world(t.pos)
			var c := Hex.to_world(n)
			var mid := (a + c) / 2.0
			var dir := (c - a).normalized()
			var rot := atan2(-dir.y, dir.x) + PI / 2.0
			_box(Vector3(mid.x, top_y + 0.45, mid.y), Vector3(Hex.RADIUS_M + 0.04, 0.06, 0.06), rail, "", rot)
			_box(Vector3(mid.x, top_y + 0.9, mid.y), Vector3(Hex.RADIUS_M + 0.04, 0.07, 0.07), rail, "", rot)
			_box(Vector3(mid.x, top_y + 0.45, mid.y), Vector3(0.05, 0.9, 0.05), Color(0.3, 0.3, 0.32))


func _crates(ts: Array) -> void:
	var alt := _alt_paths(&"kiste")
	if not alt.is_empty():
		for t in ts:
			var top := tile_top(t.pos)
			_fit_uniform(_slot(alt[_rng.randi() % alt.size()]), Vector3(top.x, 0, top.z), Vector3(1.3, top.y, 1.15), _rng.randi_range(0, 3) * PI / 2.0)
		return
	if theme and theme.crate:
		for t in ts:
			var top := tile_top(t.pos)
			_models.add(theme.crate, _models.fit_box(theme.crate, Vector3(top.x, 0, top.z), Vector3(1.3, top.y, 1.15), deg_to_rad(_rng.randi_range(0, 3) * 90.0)))
		return
	var wood := Color(0.66, 0.48, 0.27)
	for t in ts:
		var top := tile_top(t.pos)
		var h := top.y
		var c := wood.darkened([0.0, 0.08, 0.16][_rng.randi() % 3])
		_box(Vector3(top.x, h / 2.0, top.z), Vector3(1.3, h - 0.02, 1.15), c)
		for y in [0.08, h / 2.0, h - 0.08]:
			_box(Vector3(top.x, y, top.z), Vector3(1.34, 0.1, 1.19), c.darkened(0.3))


func _barrier(ts: Array) -> void:
	var b := _bounds(ts)
	var hgt: float = ts[0].obj_h * L
	var alt := _alt_paths(&"barriere")
	if not alt.is_empty():
		_kit_barrier(b, hgt, alt[_rng.randi() % alt.size()])
		return
	var concrete := Color(0.62, 0.62, 0.6)
	var long_x: bool = b.sx > b.sz
	var thick := 0.6
	var base := Vector3(b.sx - 0.2, hgt * 0.45, thick) if long_x else Vector3(thick, hgt * 0.45, b.sz - 0.2)
	_box(b.c + Vector3(0, hgt * 0.225, 0), base, concrete)
	var top := Vector3(base.x if long_x else 0.3, hgt * 0.55, 0.3 if long_x else base.z)
	_box(b.c + Vector3(0, hgt * 0.725, 0), top, concrete.lightened(0.05))
	_box(b.c + Vector3(0, hgt * 0.8, 0), Vector3(top.x + 0.02, 0.12, top.z + 0.02), Color(0.85, 0.3, 0.2))


## Barriere aus zwei kurzen Wandplatten (Pack, flach) Rücken an Rücken, dazwischen ein Block, oben eine Kappe
func _kit_barrier(b: Dictionary, hgt: float, path: String) -> void:
	var slot := _slot(path, VisualSlot.Fit.STRETCH)
	var a := _models.aabb(slot)
	var along_x: bool = b.sx > b.sz
	var length: float = (b.sx if along_x else b.sz) - 0.2
	var thick := 0.5
	for side in [-1.0, 1.0]:
		var r := (0.0 if side > 0 else PI) + (PI / 2.0 if along_x else 0.0)
		var basis := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(1.0, hgt / maxf(a.size.y, 0.01), length / a.size.z))
		var p: Vector3 = b.c + (Vector3(0, 0, side * thick / 2.0) if along_x else Vector3(side * thick / 2.0, 0, 0))
		_models.add(slot, Transform3D(basis, p - basis * Vector3(-2.0, 0.0, a.get_center().z)))
	var core := Vector3(length, hgt - 0.02, thick - 0.04) if along_x else Vector3(thick - 0.04, hgt - 0.02, length)
	_box(b.c + Vector3(0, hgt / 2.0, 0), core, Color(0.3, 0.32, 0.36))
	_box(b.c + Vector3(0, hgt, 0), Vector3(core.x + 0.06, 0.06, core.z + 0.06), Color(0.55, 0.57, 0.6))


func _barrels(t: BattleMap.Tile) -> void:
	var top := tile_top(t.pos)
	var hgt := t.obj_h * L
	var alt := _alt_paths(&"fass")
	if not alt.is_empty():
		for off in [Vector2(-0.3, -0.15), Vector2(0.3, 0.2)]:
			_fit_uniform(_slot(alt[_rng.randi() % alt.size()]), top + Vector3(off.x, 0, off.y), Vector3(0.6, hgt * 0.95, 0.6), _rng.randf() * TAU)
		return
	if theme and theme.barrel:
		for off in [Vector2(-0.3, -0.15), Vector2(0.3, 0.2)]:
			_models.add(theme.barrel, _models.fit_box(theme.barrel, top + Vector3(off.x, 0, off.y), Vector3(0.6, hgt * 0.95, 0.6), _rng.randf() * TAU))
		return
	var colors := [Color(0.2, 0.38, 0.62), Color(0.78, 0.6, 0.15), Color(0.55, 0.2, 0.18)]
	var c: Color = colors[_rng.randi() % colors.size()]
	for off in [Vector2(-0.3, -0.2), Vector2(0.32, -0.15), Vector2(0.0, 0.32)]:
		var cm := CylinderMesh.new()
		cm.top_radius = 0.3
		cm.bottom_radius = 0.3
		cm.height = hgt
		cm.radial_segments = 16
		_append(cm, Transform3D(Basis(), top + Vector3(off.x, hgt / 2.0, off.y)), _mat(c, 0.5, 0.4), "")


func _pillar(t: BattleMap.Tile) -> void:
	var top := tile_top(t.pos)
	var alt := _alt_paths(&"saeule")
	if not alt.is_empty():
		var slot := _slot(alt[_rng.randi() % alt.size()], VisualSlot.Fit.STRETCH)
		_models.add(slot, _models.fit_box(slot, top, Vector3(0.8, WALL_H, 0.8)))
		return
	if theme and theme.pillar:
		_models.add(theme.pillar, _models.fit_box(theme.pillar, top, Vector3(0.7, WALL_H, 0.7)))
		return
	_box(top + Vector3(0, WALL_H / 2.0, 0), Vector3(0.5, WALL_H, 0.5), Color(0.36, 0.4, 0.46))
	_box(top + Vector3(0, 0.5, 0), Vector3(0.56, 1.0, 0.56), Color(0.85, 0.7, 0.15))


func _wall(ts: Array) -> void:
	var b := _bounds(ts)
	var t0: BattleMap.Tile = ts[0]
	var normal := Vector3.ZERO
	if t0.row == 0:
		normal = Vector3(0, 0, -1)
	elif t0.row == map.rows - 1:
		normal = Vector3(0, 0, 1)
	elif t0.col == 0:
		normal = Vector3(-1, 0, 0)
	else:
		normal = Vector3(1, 0, 0)
	var size := Vector3(b.sx, WALL_H, b.sz)
	var low_done := false
	var c: Color = _type.get("wall", Color(0.24, 0.27, 0.32))
	var gid := "wall_%d" % _walls.size()
	var full := _group(gid + "_full")
	if _type.has("hall_walls") and _wall_style >= 0:
		_kit_wall(b.c, size, normal, gid)
		low_done = true
	elif theme and theme.wall and _hall:
		_models.fill_repeat(theme.wall, b.c, Vector3(size.x, WALL_H, size.z), gid + "_full")
	else:
		_box(b.c + Vector3(0, WALL_H / 2.0, 0), size, c, gid + "_full", 0.0, _mat(c, 0.85, 0.1))
	# senkrechte Paneele
	var long_x := size.x > size.z
	var length := size.x if long_x else size.z
	for i in (0 if (theme and theme.wall and _hall) or low_done else int(length / 3.0)):
		var off := -length / 2.0 + 1.5 + i * 3.0
		var p: Vector3 = b.c + (Vector3(off, WALL_H / 2.0, -normal.z * (size.z / 2.0 + 0.03)) if long_x else Vector3(-normal.x * (size.x / 2.0 + 0.03), WALL_H / 2.0, off))
		_box(p, Vector3(0.12, WALL_H, 0.12), c.lightened(0.08), gid + "_full")
	var low := _group(gid + "_low")
	if not low_done:
		_box(b.c + Vector3(0, WALL_LOW / 2.0, 0), Vector3(size.x, WALL_LOW, size.z), c, gid + "_low")
		_box(b.c + Vector3(0, WALL_LOW, 0), Vector3(size.x + 0.02, 0.06, size.z + 0.02), Color(0.85, 0.68, 0.15), gid + "_low")
	low.visible = false
	_walls.append({"full": full, "low": low, "normal": normal})


## Außenwand aus Pack-Teilen (MapTypes "hall_walls": Paare Wandteil unten + Abschluss oben, gleicher Ursprung):
## Stücke von etwa 4 m entlang der Wand, Paar je Karte (_wall_style), beide zusammen auf WALL_H gestreckt, Schmuckseite zur Halle;
## niedriger Schnitt ("hall_walls_low") als kurze Wand auf WALL_LOW
func _kit_wall(center: Vector3, size: Vector3, normal: Vector3, gid: String) -> void:
	var along_x := size.x > size.z
	var length := size.x if along_x else size.z
	var n := maxi(1, roundi(length / 4.0))
	var piece := length / n
	var inward := Vector2(-normal.x, -normal.z)
	var r := atan2(inward.y, -inward.x)   # Modell −x (Schmuckseite) zur Halle
	var pairs: Array = _type.hall_walls
	var lows: Array = _type.get("hall_walls_low", [])
	for i in n:
		var off := -length / 2.0 + piece * (i + 0.5)
		var p := center + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off))
		var pair: Array = pairs[_wall_style]
		var lower := _slot(pair[0], VisualSlot.Fit.STRETCH)
		var a := _models.aabb(lower)
		var k := WALL_H / (a.size.y + 2.0)   # Wandteil + 2 m Abschluss = WALL_H
		var basis := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(1.0, k, (piece + 0.02) / a.size.z))
		var anchor := Vector3(-2.0, 0.0, a.get_center().z)   # Rasterlinie der Teile (x = −2)
		var xf := Transform3D(basis, p - basis * anchor)
		_models.add(lower, xf, gid + "_full")
		_models.add(_slot(pair[1], VisualSlot.Fit.STRETCH), xf, gid + "_full")
		if not lows.is_empty():
			var ls := _slot(lows[_wall_style % lows.size()], VisualSlot.Fit.STRETCH)
			var la := _models.aabb(ls)
			var lb := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(1.0, WALL_LOW / maxf(la.size.y, 0.01), (piece + 0.02) / la.size.z))
			_models.add(ls, Transform3D(lb, p - lb * Vector3(-2.0, 0.0, la.get_center().z)), gid + "_low")


## Häuser mit geraden Fassaden (Straße, MapTypes "facades", Nutzer 28.10.2026): Häuserfelder zeilenweise zu Läufen,
## gleiche Läufe in aufeinanderfolgenden Zeilen zu Rechtecken; je Rechteck zufällig Hochhaus (zwei Wandlagen und
## Abschluss, Schnitt zur Kamera wie die Hallenwand) oder Hütte (eine Wandlage), Fassaden nach außen, Dach oben.
func _buildings(ts: Array) -> void:
	var by_row := {}
	for t in ts:
		if not by_row.has(t.row):
			by_row[t.row] = []
		by_row[t.row].append(t.col)
	var rows: Array = by_row.keys()
	rows.sort()
	var open := {}    # "c0|c1" → Rechteck {c0, c1, r0, r1}
	var rects: Array = []
	for r in rows:
		var cols: Array = by_row[r]
		cols.sort()
		var runs: Array = []
		var i := 0
		while i < cols.size():
			var j := i
			while j + 1 < cols.size() and cols[j + 1] == cols[j] + 1:
				j += 1
			runs.append([cols[i], cols[j]])
			i = j + 1
		var next := {}
		for run in runs:
			var key := "%d|%d" % run
			if open.has(key) and open[key].r1 == r - 1:
				open[key].r1 = r
				next[key] = open[key]
			else:
				var rect := {"c0": run[0], "c1": run[1], "r0": r, "r1": r}
				rects.append(rect)
				next[key] = rect
		open = next
	var mid_z := map.rows * Hex.ROW_M / 2.0
	for rect in rects:
		var x0 := 0.0
		var x1 := 0.0
		for r in range(rect.r0, rect.r1 + 1):
			x0 += Hex.to_world(Hex.from_offset(rect.c0, r)).x - Hex.SIZE_M / 2.0
			x1 += Hex.to_world(Hex.from_offset(rect.c1, r)).x + Hex.SIZE_M / 2.0
		var n: int = rect.r1 - rect.r0 + 1
		x0 /= n
		x1 /= n
		var z0 := Hex.to_world(Hex.from_offset(rect.c0, rect.r0)).y - Hex.ROW_M / 2.0
		var z1 := Hex.to_world(Hex.from_offset(rect.c0, rect.r1)).y + Hex.ROW_M / 2.0
		var tall := _rng.randf() < 0.5 and x1 - x0 > 3.0
		_house(Vector2(x0, z0), Vector2(x1, z1), tall, Vector3(0, 0, -1) if (z0 + z1) / 2.0 < mid_z else Vector3(0, 0, 1))


## Ein Haus im Rechteck a–b (Welt x/z): Fassaden aus dem Wandpaar der Karte, Dach; Hochhaus mit Schnitt (normal = Kartenrand)
func _house(a: Vector2, b: Vector2, tall: bool, normal: Vector3) -> void:
	var pair: Array = _type.facades[_wall_style]
	var levels := 2 if tall else 1
	var gid := "house_%d" % _walls.size()
	var full := gid + "_full" if tall else ""
	var c := (a + b) / 2.0
	var sides := [[Vector2(c.x, a.y), Vector2(0, -1), b.x - a.x], [Vector2(c.x, b.y), Vector2(0, 1), b.x - a.x],
		[Vector2(a.x, c.y), Vector2(-1, 0), b.y - a.y], [Vector2(b.x, c.y), Vector2(1, 0), b.y - a.y]]
	var lower := _slot(pair[0], VisualSlot.Fit.STRETCH)
	var la := _models.aabb(lower)
	var top_slot := _slot(pair[1], VisualSlot.Fit.STRETCH)
	var height := la.size.y * levels + (2.0 if tall else 0.0)
	for sd in sides:
		var out: Vector2 = sd[1]
		var length: float = sd[2]
		var n := maxi(1, roundi(length / 4.0))
		var piece := length / n
		var r := atan2(out.y, -out.x)   # Schmuckseite (Modell −x) nach außen
		var along_x := absf(out.y) > 0.5
		for i in n:
			var off := -length / 2.0 + piece * (i + 0.5)
			var p: Vector2 = sd[0] + (Vector2(off, 0) if along_x else Vector2(0, off)) - out * (la.end.x + 2.0)
			for lv in levels:
				var basis := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(1.0, 1.0, (piece + 0.02) / la.size.z))
				var xf := Transform3D(basis, Vector3(p.x, lv * la.size.y, p.y) - basis * Vector3(-2.0, 0.0, la.get_center().z))
				_models.add(lower, xf, full)
				if tall and lv == levels - 1:
					_models.add(top_slot, xf, full)
	var roof: Color = _type.get("roof", Color(0.22, 0.22, 0.25))
	_box(Vector3(c.x, height - 0.1, c.y), Vector3(b.x - a.x - 0.1, 0.2, b.y - a.y - 0.1), roof, full)
	if not tall:
		return
	# niedriger Schnitt zur Kamera: kurze Wand rundum, Dach darauf
	var lows: Array = _type.get("facades_low", [])
	var low := gid + "_low"
	if not lows.is_empty():
		var ls := _slot(lows[_wall_style % lows.size()], VisualSlot.Fit.STRETCH)
		var lw := _models.aabb(ls)
		for sd in sides:
			var out: Vector2 = sd[1]
			var r := atan2(out.y, -out.x)
			var lb := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(1.0, WALL_LOW / maxf(lw.size.y, 0.01), sd[2] / lw.size.z))
			_models.add(ls, Transform3D(lb, Vector3(sd[0].x, 0.0, sd[0].y) - lb * Vector3(-2.0, 0.0, lw.get_center().z)), low)
	_box(Vector3(c.x, WALL_LOW - 0.05, c.y), Vector3(b.x - a.x - 0.1, 0.1, b.y - a.y - 0.1), roof, low)
	_group(low).visible = false
	_walls.append({"full": _group(full), "low": _group(low), "normal": normal})


## Treppe als echte Stufen (vorher ein Block, sah aus wie ein Container; Spieltest 15.10.2026).
## Jedes Feld trägt 5 Stufen à L/5, die Mitte liegt auf Feldhöhe; Laufrichtung zum höheren Nachbarn,
## auf die Achse (x oder z) gerundet, damit nebeneinanderliegende Treppenfelder eine Flucht bilden.
func _stairs(t: BattleMap.Tile) -> void:
	var top := tile_top(t.pos)
	var up := Vector2.ZERO
	for n in Hex.neighbors(t.pos):
		var nt := map.tile(n)
		if nt and map.walkable(nt) and nt.h > t.h:
			up += (Hex.to_world(n) - Hex.to_world(t.pos)).normalized()
	var along_x := absf(up.x) > absf(up.y)
	var sgn := signf(up.x if along_x else up.y)
	if up == Vector2.ZERO:
		sgn = -1.0
	var depth := 1.5 if along_x else 1.3      # Ausdehnung des Felds in Laufrichtung
	var width := 1.3 if along_x else 1.5
	var n := 5
	var rise := L / n
	var metal := Color(0.56, 0.6, 0.66)
	var riser := Color(0.32, 0.35, 0.4)
	var yellow := Color(0.9, 0.72, 0.15)
	for i in n:
		var h := top.y + (i - 2) * rise
		if h <= 0.0:
			continue
		var off := (-depth / 2.0 + (i + 0.5) * depth / n) * sgn   # vorn (unten) → hinten (oben)
		var c := top + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off))
		var size := Vector3(depth / n, h, width) if along_x else Vector3(width, h, depth / n)
		_box(Vector3(c.x, h / 2.0, c.z), size, riser, "", 0.0, _mat(riser, 0.8, 0.2))
		# Trittfläche hell, gelbe Kante vorn
		var tread := Vector3(depth / n, 0.05, width) if along_x else Vector3(width, 0.05, depth / n)
		_box(Vector3(c.x, h - 0.02, c.z), tread, metal, "", 0.0, _mat(metal, 0.5, 0.5))
		var edge := -depth / n / 2.0 * sgn + 0.04 * sgn
		var ep := c + (Vector3(edge, 0, 0) if along_x else Vector3(0, 0, edge))
		_box(Vector3(ep.x, h + 0.005, ep.z), Vector3(0.06, 0.03, width) if along_x else Vector3(width, 0.03, 0.06), yellow)


## Leiter an der Kante zum höchsten Nachbarfeld
func _ladder(t: BattleMap.Tile) -> void:
	var best: BattleMap.Tile = null
	for n in Hex.neighbors(t.pos):
		var nt := map.tile(n)
		if nt and map.walkable(nt) and nt.h > t.h and (best == null or nt.h > best.h):
			best = nt
	if best == null:
		return
	var a := Hex.to_world(t.pos)
	var c := Hex.to_world(best.pos)
	var dir := (c - a).normalized()
	var p := a + dir * 0.62
	var hgt := best.h * L
	var yellow := Color(0.9, 0.75, 0.15)
	var rot := atan2(-dir.y, dir.x) + PI / 2.0
	var basis := Basis(Vector3.UP, rot)
	var origin := Vector3(p.x, 0, p.y)
	for side in [-0.25, 0.25]:
		_box(origin + basis * Vector3(side, hgt / 2.0 + 0.1, 0), Vector3(0.06, hgt + 0.2, 0.06), yellow, "", rot)
	var y := 0.3
	while y < hgt:
		_box(origin + basis * Vector3(0, y, 0), Vector3(0.5, 0.04, 0.04), yellow, "", rot)
		y += 0.32


## Objekt eines neuen Kartentyps: Modell(e) aus MapTypes (zufällig je Objekt), sonst Grundkörper.
## Gruppen (Theke, Regal, Fahrzeug …) als ein Modell entlang der langen Seite, sonst je Feld.
func _prop(ts: Array) -> void:
	var terrain: StringName = ts[0].terrain
	var hgt: float = PROP_H[terrain]
	var paths: Array = _type.get("props", {}).get(terrain, [])
	var alt := _alt_paths(terrain)
	if not alt.is_empty():
		paths = alt
	var color: Color = PROP_COLOR.get(terrain, Color(0.5, 0.5, 0.5))
	if terrain == &"schreibtisch":
		_desks(ts)
		return
	if terrain in PROP_GROUP and ts.size() > 1 and (alt.is_empty() or terrain in [&"auto", &"sofa"]):
		var b := _bounds(ts)
		var base: Vector3 = b.c + Vector3(0, ts[0].h * L, 0)
		var size := Vector3(b.sx - 0.15, hgt, b.sz - 0.15)
		if paths.is_empty():
			_box(base + Vector3(0, hgt / 2.0, 0), size, color)
		elif terrain in [&"theke", &"schrank", &"server"] and alt.is_empty():
			_models.fill_repeat(_slot(paths[_rng.randi() % paths.size()], VisualSlot.Fit.STRETCH, 1.5), base, size)
		else:
			_fit_uniform(_slot(paths[_rng.randi() % paths.size()]), base, size)
		return
	for t in ts:
		var top := tile_top(t.pos)
		var size := Vector3(1.25, hgt, 1.1)
		if paths.is_empty():
			_box(top + Vector3(0, hgt / 2.0, 0), size if terrain != &"laterne" else Vector3(0.25, hgt, 0.25), color)
			continue
		var slot := _slot(paths[_rng.randi() % paths.size()])
		_fit_uniform(slot, top, size, _rng.randi_range(0, 5) * PI / 3.0)
	if terrain == &"tisch" and _type.get("props", {}).has(&"hocker"):
		_stools(ts[0])


## Schreibtische (Büro): je Gruppe alte Platte (Grundkörper) oder Pack-Tische ("alt" schreibtisch, je Reihe einer),
## Bildschirme je Feld alt oder neu, bei neuen ein Stuhl davor (nur Grafik). Besprechungstisch (Gruppe ab 6 Feldern):
## Teppich darunter ("meeting_carpet"), mit alt_chance ein großer Tisch aus dem Pack mit Stühlen an den langen Seiten.
func _desks(ts: Array) -> void:
	var b := _bounds(ts)
	var top := 0.78
	var wood: Color = PROP_COLOR[&"schreibtisch"]
	var props: Dictionary = _type.get("props", {})
	var alts: Dictionary = _type.get("alt", {})
	var chairs: Array = alts.get(&"stuhl", [])
	if ts.size() >= 6 and _type.has("meeting_carpet"):
		var cs := _slot(_type.meeting_carpet, VisualSlot.Fit.STRETCH)
		var nx := ceili((b.sx + 1.5) / 2.0)
		var nz := ceili((b.sz + 1.5) / 2.0)
		for ix in nx:
			for iz in nz:
				var c := Vector2(b.c.x - nx + 1.0 + ix * 2.0, b.c.z - nz + 1.0 + iz * 2.0)
				var t := map.tile(Hex.from_world(c))
				if t and (t.terrain == &"boden" or t.terrain == &"schreibtisch"):
					_flat(cs, Vector3(c.x, 0.006, c.y), 2.0)
		var big := _alt_paths(&"besprechung")
		if not big.is_empty():
			_fit_uniform(_slot(big[_rng.randi() % big.size()]), b.c, Vector3(b.sx - 0.1, top, b.sz - 0.1))
			if not chairs.is_empty():
				var chair := _slot(chairs[_rng.randi() % chairs.size()])
				var long_x: bool = b.sx > b.sz
				var length: float = maxf(b.sx, b.sz)
				for i in int(length / 1.2):
					var off: float = -length / 2.0 + 0.6 + i * 1.2
					for side in [-1.0, 1.0]:
						var p: Vector3 = b.c + (Vector3(off, 0, side * (b.sz / 2.0 + 0.25)) if long_x else Vector3(side * (b.sx / 2.0 + 0.25), 0, off))
						var rot: float = (PI if side > 0 else 0.0) + (0.0 if long_x else PI / 2.0)
						_fit_uniform(chair, p, Vector3(0.5, 0.95, 0.5), rot)
			return
	var desks := _alt_paths(&"schreibtisch")
	if desks.is_empty():
		_box(b.c + Vector3(0, top - 0.03, 0), Vector3(b.sx - 0.2, 0.06, b.sz - 0.2), wood)
		_box(b.c + Vector3(0, (top - 0.06) / 2.0, 0), Vector3(b.sx - 0.5, top - 0.06, b.sz - 0.5), wood.darkened(0.35))
	else:
		var rows := maxi(1, roundi(b.sz / Hex.ROW_M))
		for i in rows:
			var c: Vector3 = b.c + Vector3(0, 0, -b.sz / 2.0 + (i + 0.5) * b.sz / rows)
			_fit_uniform(_slot(desks[_rng.randi() % desks.size()]), c, Vector3(b.sx - 0.15, top, b.sz / rows - 0.05), PI if i % 2 else 0.0)
	var screens := _alt_paths(&"computer")   # je Gruppe alte oder neue Bildschirme, neue mit Stuhl
	var chair_slot: VisualSlot = _slot(chairs[_rng.randi() % chairs.size()]) if not screens.is_empty() and not chairs.is_empty() else null
	for t in ts:
		var p := tile_top(t.pos)
		var side := -1.0 if t.row % 2 else 1.0
		if not screens.is_empty():
			_fit_uniform(_slot(screens[_rng.randi() % screens.size()]), Vector3(p.x, top, p.z - side * 0.15), Vector3(0.55, 0.55, 0.4), PI if t.row % 2 else 0.0)
			if chair_slot:
				_fit_uniform(chair_slot, Vector3(p.x, 0.0, p.z + side * 0.62), Vector3(0.5, 0.95, 0.5), 0.0 if t.row % 2 else PI)
		elif props.has(&"computer"):
			_fit_uniform(_slot(props[&"computer"][0]), Vector3(p.x, top, p.z), Vector3(0.6, 0.5, 0.45), PI if t.row % 2 else 0.0)
		elif map.map_type == &"schiff":
			_box(Vector3(p.x, top + 0.2, p.z), Vector3(0.5, 0.35, 0.06), Color(0.2, 0.6, 0.9))


## Hocker an freie Nachbarfelder eines Bartischs (nur Grafik)
func _stools(t: BattleMap.Tile) -> void:
	var slot := _slot(_type.props[&"hocker"][0])
	var k := 0
	for n in Hex.neighbors(t.pos):
		var nt := map.tile(n)
		if nt == null or nt.terrain != &"boden" or k >= 2 or _rng.randf() < 0.5:
			continue
		var a := Hex.to_world(t.pos)
		var c := Hex.to_world(n)
		var p := a.lerp(c, 0.55)
		_fit_uniform(slot, Vector3(p.x, 0, p.y), Vector3(0.45, 0.7, 0.45))
		k += 1


## Modell gleichmäßig in einen Quader einpassen (Seitenverhältnis bleibt), lange Seite an die lange Seite
func _fit_uniform(slot: VisualSlot, center_bottom: Vector3, size: Vector3, rot := 0.0) -> void:
	var a := _models.aabb(slot)
	var model_long_x := a.size.x >= a.size.z
	var box_long_x := size.x >= size.z
	var r := rot + (0.0 if model_long_x == box_long_x or absf(size.x - size.z) < 0.3 else PI / 2.0)
	var turned := absf(sin(r)) > 0.5
	var mx := a.size.z if turned else a.size.x
	var mz := a.size.x if turned else a.size.z
	var k := minf(size.y / maxf(a.size.y, 0.001), minf(size.x / maxf(mx, 0.001), size.z / maxf(mz, 0.001)) * 1.15)
	var basis := Basis(Vector3.UP, r) * Basis.from_scale(Vector3(k, k, k))
	var anchor := Vector3(a.get_center().x, a.position.y, a.get_center().z)
	_models.add(slot, Transform3D(basis, center_bottom - basis * anchor))


static func _slot(path: String, fit := VisualSlot.Fit.HEIGHT, repeat_m := 2.0) -> VisualSlot:
	var key := "%s|%d|%.1f" % [path, fit, repeat_m]
	if not _slots.has(key):
		var s := VisualSlot.new()
		s.model = load(path)
		s.fit = fit
		s.repeat_m = repeat_m
		_slots[key] = s
	return _slots[key]


# ---------------------------------------------------------------- Bausteine

func _box(p: Vector3, s: Vector3, c: Color, group := "", rot_y := 0.0, mat: Material = null) -> void:
	var key := "%.3f|%.3f|%.3f" % [s.x, s.y, s.z]
	if not _box_meshes.has(key):
		var bm := BoxMesh.new()
		bm.size = s
		_box_meshes[key] = bm
	_append(_box_meshes[key], Transform3D(Basis(Vector3.UP, rot_y), p), mat if mat else _mat(c), group)


func _append(mesh: Mesh, xf: Transform3D, m: Material, group: String) -> void:
	var key := "%s|%d" % [group, m.get_instance_id()]
	if not _batches.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_batches[key] = {"st": st, "mat": m, "group": group}
	_batches[key].st.append_from(mesh, 0, xf)


func _commit() -> void:
	for key in _batches:
		var b: Dictionary = _batches[key]
		var mi := MeshInstance3D.new()
		mi.mesh = b.st.commit()
		mi.material_override = b.mat
		_group(b.group).add_child(mi)
	_batches.clear()


func _group(name: String) -> Node3D:
	if name == "":
		return self
	if not _groups.has(name):
		var n := Node3D.new()
		n.name = name
		add_child(n)
		_groups[name] = n
	return _groups[name]


## Sechseckige Platte unter der Feldoberseite
func _hex_slab(top: Vector3, thickness: float, c: Color) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = Hex.RADIUS_M + 0.02
	cm.bottom_radius = Hex.RADIUS_M + 0.02
	cm.height = thickness
	cm.radial_segments = 6
	cm.rings = 1
	_append(cm, Transform3D(Basis(), top - Vector3(0, thickness / 2.0, 0)), _mat(c, 0.75, 0.3), "")


func _mat(c: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [c.to_html(), rough, metal]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]

