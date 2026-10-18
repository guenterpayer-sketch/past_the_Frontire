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
static var _slots := {}


func build(m: BattleMap) -> void:
	for c in get_children():
		c.queue_free()
	_walls.clear()
	map = m
	_type = MapTypes.info(m.map_type)
	_hall = m.map_type == &"halle"
	_rng.seed = m.map_seed
	_groups.clear()
	_build_floor()
	_build_objects()
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
	if theme and theme.floor_tile:
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
	var base: Color = _type.floor
	for t in map.list:
		if t.terrain == &"leer" or t.terrain == &"gebaeude" or t.terrain == &"podest":
			continue
		var c: Color = _type.get("gehweg", base) if t.terrain == &"gehweg" else base
		var k := (hash(t.pos) % 5) * 0.012
		_hex_slab(Vector3(Hex.to_world(t.pos).x, 0.0 if t.terrain != &"gehweg" else 0.08, Hex.to_world(t.pos).y),
			0.05 if t.terrain != &"gehweg" else 0.13, c.darkened(k))


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
				for t in ts:
					_hex_slab(tile_top(t.pos) + Vector3(0, INNER_H, 0), INNER_H, _type.get("inner", Color(0.3, 0.33, 0.38)))
			&"gebaeude":
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
	var concrete := Color(0.62, 0.62, 0.6)
	var long_x: bool = b.sx > b.sz
	var thick := 0.6
	var base := Vector3(b.sx - 0.2, hgt * 0.45, thick) if long_x else Vector3(thick, hgt * 0.45, b.sz - 0.2)
	_box(b.c + Vector3(0, hgt * 0.225, 0), base, concrete)
	var top := Vector3(base.x if long_x else 0.3, hgt * 0.55, 0.3 if long_x else base.z)
	_box(b.c + Vector3(0, hgt * 0.725, 0), top, concrete.lightened(0.05))
	_box(b.c + Vector3(0, hgt * 0.8, 0), Vector3(top.x + 0.02, 0.12, top.z + 0.02), Color(0.85, 0.3, 0.2))


func _barrels(t: BattleMap.Tile) -> void:
	var top := tile_top(t.pos)
	var hgt := t.obj_h * L
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
	var c: Color = _type.get("wall", Color(0.24, 0.27, 0.32))
	var gid := "wall_%d" % _walls.size()
	var full := _group(gid + "_full")
	if theme and theme.wall and _hall:
		_models.fill_repeat(theme.wall, b.c, Vector3(size.x, WALL_H, size.z), gid + "_full")
	else:
		_box(b.c + Vector3(0, WALL_H / 2.0, 0), size, c, gid + "_full", 0.0, _mat(c, 0.85, 0.1))
	# senkrechte Paneele
	var long_x := size.x > size.z
	var length := size.x if long_x else size.z
	for i in (0 if theme and theme.wall and _hall else int(length / 3.0)):
		var off := -length / 2.0 + 1.5 + i * 3.0
		var p: Vector3 = b.c + (Vector3(off, WALL_H / 2.0, -normal.z * (size.z / 2.0 + 0.03)) if long_x else Vector3(-normal.x * (size.x / 2.0 + 0.03), WALL_H / 2.0, off))
		_box(p, Vector3(0.12, WALL_H, 0.12), c.lightened(0.08), gid + "_full")
	var low := _group(gid + "_low")
	_box(b.c + Vector3(0, WALL_LOW / 2.0, 0), Vector3(size.x, WALL_LOW, size.z), c, gid + "_low")
	_box(b.c + Vector3(0, WALL_LOW, 0), Vector3(size.x + 0.02, 0.06, size.z + 0.02), Color(0.85, 0.68, 0.15), gid + "_low")
	low.visible = false
	_walls.append({"full": full, "low": low, "normal": normal})


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
	var color: Color = PROP_COLOR.get(terrain, Color(0.5, 0.5, 0.5))
	if terrain == &"schreibtisch":
		_desks(ts)
		return
	if terrain in PROP_GROUP and ts.size() > 1:
		var b := _bounds(ts)
		var base: Vector3 = b.c + Vector3(0, ts[0].h * L, 0)
		var size := Vector3(b.sx - 0.15, hgt, b.sz - 0.15)
		if paths.is_empty():
			_box(base + Vector3(0, hgt / 2.0, 0), size, color)
		elif terrain in [&"theke", &"schrank", &"server"]:
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


## Schreibtische: Platte als Grundkörper, je Feld ein Bildschirm und ein Stuhl daneben (Büro)
func _desks(ts: Array) -> void:
	var b := _bounds(ts)
	var top := 0.78
	var wood: Color = PROP_COLOR[&"schreibtisch"]
	_box(b.c + Vector3(0, top - 0.03, 0), Vector3(b.sx - 0.2, 0.06, b.sz - 0.2), wood)
	_box(b.c + Vector3(0, (top - 0.06) / 2.0, 0), Vector3(b.sx - 0.5, top - 0.06, b.sz - 0.5), wood.darkened(0.35))
	var props: Dictionary = _type.get("props", {})
	for t in ts:
		var p := tile_top(t.pos)
		if props.has(&"computer"):
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

