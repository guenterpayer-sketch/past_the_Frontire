class_name ShipView
extends Node3D
## Das eigene Schiff als 3D-Deck (Hub): Räume aus Modellen des Sci-Fi-Baukastens (assets/ship),
## Wände im 4-m-Raster. Außenwände zur Kamera hin werden niedrig gezeigt (Blick ins Innere),
## Zwischenwände sind halbhoch mit Durchgängen. Räume lassen sich hervorheben (Maus, Auswahl).

const DIR := "res://assets/ship/"
const CELL := 4.0
const TILE := 2.0
const INNER_WALL := 0.45     # Höhe der Zwischenwände (Anteil)
const LOW_WALL := 0.1        # Außenwand zur Kamera hin

## Räume (Meter: x entlang des Schiffs, z quer). ready = schon nutzbar, sonst „kommt noch“.
const ROOMS := [
	{"id": &"hangar", "name": "Hangar", "rect": Rect2(0, 0, 16, 8), "ready": false,
		"text": "Landungsschiff.", "light": Color(1.0, 0.85, 0.6)},
	{"id": &"armory", "name": "Waffenkammer", "rect": Rect2(0, 8, 16, 8), "ready": true,
		"text": "Ausrüstung ändern: Waffen, Rüstung, Schild (Dialog des Charakter-Moduls).", "light": Color(1.0, 0.75, 0.55)},
	{"id": &"quarters", "name": "Crewquartiere", "rect": Rect2(16, 0, 12, 8), "ready": true,
		"text": "Crew ansehen: Ränge kaufen, Eigenschaften steigern, freie EP einzahlen, Charakterbögen.", "light": Color(0.75, 0.85, 1.0)},
	{"id": &"medbay", "name": "Krankenstation", "rect": Rect2(16, 8, 12, 8), "ready": true,
		"text": "Verwundete und Resttage, Arzt und Helfer zuweisen (Zweite Hilfe), „1 Tag warten“.", "light": Color(0.7, 1.0, 0.9)},
	{"id": &"bridge", "name": "Brücke", "rect": Rect2(28, 4, 12, 8), "ready": true,
		"text": "Sternenkarte des Sektors, offene Aufträge, Kurs setzen. Später: Raumkampf.", "light": Color(1.0, 0.9, 0.55)},
]

## Durchgänge in Zwischenwänden: Mittelpunkt der 4-m-Kante
const DOORS := [Vector2(16, 6), Vector2(16, 10), Vector2(28, 6), Vector2(22, 8), Vector2(10, 8)]
## Außenwände mit Fenstern (Mittelpunkt der Kante -> Modell)
const WINDOWS := {Vector2(40, 6): "threewindows_wall_sidea", Vector2(40, 10): "threewindows_wall_sidea",
	Vector2(30, 4): "longwindow_wall_sidea", Vector2(34, 4): "longwindow_wall_sidea", Vector2(38, 4): "smallwindows_wall_sidea",
	Vector2(30, 12): "longwindow_wall_sidea", Vector2(34, 12): "longwindow_wall_sidea", Vector2(38, 12): "smallwindows_wall_sidea",
	Vector2(18, 0): "smallwindows_wall_sidea", Vector2(26, 0): "smallwindows_wall_sidea"}
const WALL_VARIANTS := ["wall_1", "wall_2", "wall_3", "wall_4", "wall_5", "wall_empty"]

## Einrichtung: [Modell, x, z, Drehung in Grad, Maßstab]
const PROPS := [
	# Brücke: Kartentisch in der Mitte, Konsolen an der Front
	["props_teleporter_1", 33.0, 8.0, 0.0, 1.3],
	["props_computer", 38.6, 5.6, -90.0, 1.0], ["props_computer", 38.6, 8.0, -90.0, 1.0], ["props_computer", 38.6, 10.4, -90.0, 1.0],
	["props_computersmall", 30.0, 4.8, 0.0, 1.0], ["props_computersmall", 30.0, 11.2, 180.0, 1.0],
	["column_slim", 28.6, 4.6, 0.0, 0.5], ["column_slim", 28.6, 11.4, 0.0, 0.5],
	# Crewquartiere: sechs Schlafkapseln, Spinde
	["props_capsule", 17.4, 1.2, 0.0, 1.0], ["props_capsule", 19.2, 1.2, 0.0, 1.0], ["props_capsule", 21.0, 1.2, 0.0, 1.0],
	["props_capsule", 23.6, 1.2, 0.0, 1.0], ["props_capsule", 25.4, 1.2, 0.0, 1.0], ["props_capsule", 27.0, 1.2, 0.0, 1.0],
	["props_chest", 18.0, 6.6, 0.0, 1.0], ["props_shelf", 26.0, 7.0, 180.0, 1.0],
	# Krankenstation: Heilkammern, Behälter, Konsole
	["props_base", 19.5, 13.0, 0.0, 1.0], ["props_pod", 19.5, 13.0, 0.0, 0.8],
	["props_base", 24.5, 13.0, 0.0, 1.0], ["props_pod", 24.5, 13.0, 0.0, 0.8],
	["props_vessel_tall", 17.0, 9.2, 0.0, 1.0], ["props_vessel", 17.6, 9.2, 0.0, 1.0], ["props_vessel_tall", 18.2, 9.2, 0.0, 1.0],
	["props_computersmall", 27.0, 10.0, -90.0, 1.0],
	# Hangar: Landungsschiff, Kisten
	["dropship_insurgent", 7.0, 4.0, 90.0, 0.9],
	["props_crate", 1.2, 1.2, 0.0, 1.0], ["props_crate", 2.2, 1.2, 15.0, 1.0], ["props_crate", 1.4, 2.2, -10.0, 1.0],
	["props_containerfull", 14.6, 1.2, 0.0, 1.0],
	# Waffenkammer: Waffenregale, Werkbank, Kisten
	["props_shelf_tall", 3.0, 15.0, 180.0, 1.0], ["props_shelf_tall", 6.0, 15.0, 180.0, 1.0], ["props_shelf_tall", 14.4, 15.0, 180.0, 1.0],
	["props_laser", 11.0, 12.0, -90.0, 0.8],
	["props_cratelong", 1.2, 10.0, 90.0, 1.0], ["props_chest", 14.6, 10.0, 90.0, 1.0],
]

var _walls: Array[Dictionary] = []     # {full, low, normal}
var _highlights := {}                    # Raum-ID -> MeshInstance3D
var _aabb_cache := {}


func _ready() -> void:
	build()


func build() -> void:
	for c in get_children():
		c.queue_free()
	_walls.clear()
	_highlights.clear()
	_build_floor()
	_build_walls()
	for p in PROPS:
		_place(p[0], Vector3(p[1], 0, p[2]), p[3], p[4])
	_build_lights()
	_build_highlights()
	_build_stars()


## Raum an einer Stelle des Decks (x, z in Metern) oder {}
static func room_at(p: Vector2) -> Dictionary:
	for r in ROOMS:
		if (r.rect as Rect2).has_point(p):
			return r
	return {}


static func room(id: StringName) -> Dictionary:
	for r in ROOMS:
		if r.id == id:
			return r
	return {}


## Mittelpunkt eines Raums (Boden)
static func room_center(id: StringName) -> Vector3:
	var r: Rect2 = room(id).rect
	var c := r.get_center()
	return Vector3(c.x, 0, c.y)


static func bounds() -> Rect2:
	var b: Rect2 = ROOMS[0].rect
	for r in ROOMS:
		b = b.merge(r.rect)
	return b


func set_highlight(hover: StringName, selected: StringName = &"") -> void:
	for id in _highlights:
		var m: MeshInstance3D = _highlights[id]
		m.visible = id == hover or id == selected
		(m.material_override as StandardMaterial3D).albedo_color = Color(UiTheme.ACCENT, 0.22 if id == hover else 0.12)


## Außenwände zwischen Kamera und Raum niedrig zeigen
func update_cutaway(view_dir: Vector3) -> void:
	for w in _walls:
		var low: bool = (w.normal as Vector3).dot(view_dir) > 0.2
		w.full.visible = not low
		w.low.visible = low


# ---------------------------------------------------------------- Aufbau

func _build_floor() -> void:
	for r in ROOMS:
		var rect: Rect2 = r.rect
		var nx := int(rect.size.x / TILE)
		var nz := int(rect.size.y / TILE)
		for i in nx:
			for j in nz:
				var c := Vector3(rect.position.x + (i + 0.5) * TILE, 0, rect.position.y + (j + 0.5) * TILE)
				var m := "floortile_basic" if (i + j) % 2 == 0 else "floortile_basic2"
				if r.id == &"hangar" and i > 0 and j > 0 and i < nx - 1 and j < nz - 1:
					m = "floortile_empty"
				var n := _place(m, c, 0.0, 1.0)
				n.position.y -= _aabb(m).size.y


## Wände auf allen Rasterkanten zwischen verschiedenen Räumen bzw. zwischen Raum und außen
func _build_walls() -> void:
	var b := bounds()
	var cols := int(b.size.x / CELL)
	var rows := int(b.size.y / CELL)
	var k := 0
	for i in cols + 1:
		for j in rows:
			# senkrechte Kante x = i*CELL zwischen Zelle (i-1, j) und (i, j)
			var mid := Vector2(i * CELL, (j + 0.5) * CELL)
			_edge(mid, _cell_room(i - 1, j), _cell_room(i, j), Vector3(1, 0, 0), k)
			k += 1
	for j in rows + 1:
		for i in cols:
			var mid := Vector2((i + 0.5) * CELL, j * CELL)
			_edge(mid, _cell_room(i, j - 1), _cell_room(i, j), Vector3(0, 0, 1), k)
			k += 1


func _cell_room(i: int, j: int) -> Dictionary:
	return room_at(Vector2((i + 0.5) * CELL, (j + 0.5) * CELL))


## Kante zwischen a (Seite −axis) und b (Seite +axis)
func _edge(mid: Vector2, a: Dictionary, b: Dictionary, axis: Vector3, k: int) -> void:
	if a.is_empty() and b.is_empty():
		return
	if not a.is_empty() and not b.is_empty() and a.id == b.id:
		return
	var rot := 0.0 if axis.z != 0 else 90.0
	var pos := Vector3(mid.x, 0, mid.y)
	if not a.is_empty() and not b.is_empty():
		# Zwischenwand, halbhoch; Durchgang bleibt offen
		if mid in DOORS:
			_place("column_slim", pos - _along(axis) * 2.0, 0.0, 0.45)
			_place("column_slim", pos + _along(axis) * 2.0, 0.0, 0.45)
			return
		var w := _place(WALL_VARIANTS[k % WALL_VARIANTS.size()], pos, rot, 1.0)
		w.scale.y *= INNER_WALL
		return
	# Außenwand: Innenseite zeigt in den Raum
	var inside_pos := b.is_empty()  # Raum liegt auf der −axis-Seite
	var normal := axis if inside_pos else -axis
	var model: String = WINDOWS.get(mid, WALL_VARIANTS[k % WALL_VARIANTS.size()])
	var face := rot + (180.0 if inside_pos else 0.0)
	var full := _place(model, pos, face, 1.0)
	var low := _place("wall_empty", pos, face, 1.0)
	low.scale.y *= LOW_WALL
	low.visible = false
	_walls.append({"full": full, "low": low, "normal": normal})


func _along(axis: Vector3) -> Vector3:
	return Vector3(axis.z, 0, axis.x)


func _build_lights() -> void:
	for r in ROOMS:
		var l := OmniLight3D.new()
		var c: Vector2 = (r.rect as Rect2).get_center()
		l.position = Vector3(c.x, 3.2, c.y)
		l.light_color = r.light
		l.light_energy = 0.9
		l.omni_range = maxf(r.rect.size.x, r.rect.size.y) * 0.8
		add_child(l)


func _build_highlights() -> void:
	for r in ROOMS:
		var rect: Rect2 = r.rect
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = rect.size - Vector2(0.6, 0.6)
		m.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(UiTheme.ACCENT, 0.2)
		mat.no_depth_test = true
		m.material_override = mat
		m.position = Vector3(rect.get_center().x, 0.06, rect.get_center().y)
		m.visible = false
		add_child(m)
		_highlights[r.id] = m


## Sterne unter dem Deck (Weltraum im Hintergrund)
func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.65, 0.8)
	sm.material = mat
	mm.mesh = sm
	mm.instance_count = 700
	var c := bounds().get_center()
	for i in mm.instance_count:
		var p := Vector3(c.x + rng.randf_range(-140, 140), rng.randf_range(-60, -25), c.y + rng.randf_range(-140, 140))
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.4, 1.6)), p))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


## Modell so setzen, dass seine Grundfläche mittig auf pos steht
func _place(model: String, pos: Vector3, rot_deg: float, scale_k: float) -> Node3D:
	var scene: PackedScene = load(DIR + model + ".glb")
	var n: Node3D = scene.instantiate()
	var a := _aabb(model)
	var basis := Basis(Vector3.UP, deg_to_rad(rot_deg)) * Basis.from_scale(Vector3.ONE * scale_k)
	var anchor := Vector3(a.get_center().x, a.position.y, a.get_center().z)
	n.transform = Transform3D(basis, pos - basis * anchor)
	add_child(n)
	return n


func _aabb(model: String) -> AABB:
	if _aabb_cache.has(model):
		return _aabb_cache[model]
	var root: Node3D = (load(DIR + model + ".glb") as PackedScene).instantiate()
	var box := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D()
		var n: Node = mi
		while n != root and n != null:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		if (mi as MeshInstance3D).mesh == null:
			continue
		var bb: AABB = xf * (mi as MeshInstance3D).mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	root.free()
	_aabb_cache[model] = box
	return box
