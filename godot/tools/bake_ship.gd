extends SceneTree
## Schreibt das Schiff (Hub) einmalig als bearbeitbare Szenen: je Raum `ship/rooms/<id>.tscn`
## (Boden, Wände, Einrichtung, Licht) und `ship/ship.tscn`, das alle Räume zusammensetzt.
## Startpunkt war der frühere Aufbau per Code in `view/ship_view.gd` (Stand 28.10.2026).
## Aufruf: godot --headless --path godot --script res://tools/bake_ship.gd [-- --force]
## Ohne --force bleiben vorhandene Raumszenen unberührt (dort gestaltet der Nutzer im Editor).

const DIR := "res://assets/ship/"
const OUT := "res://ship/"
const CELL := 4.0
const TILE := 2.0
const INNER_WALL := 0.45
const LOW_WALL := 0.1

const DOORS := [Vector2(16, 6), Vector2(16, 10), Vector2(28, 6), Vector2(22, 8), Vector2(10, 8), Vector2(28, 14)]
const WINDOWS := {Vector2(40, 6): "threewindows_wall_sidea", Vector2(40, 10): "threewindows_wall_sidea",
	Vector2(30, 4): "longwindow_wall_sidea", Vector2(34, 4): "longwindow_wall_sidea", Vector2(38, 4): "smallwindows_wall_sidea",
	Vector2(30, 16): "longwindow_wall_sidea", Vector2(38, 16): "smallwindows_wall_sidea",
	Vector2(18, 0): "smallwindows_wall_sidea", Vector2(26, 0): "smallwindows_wall_sidea"}
const WALL_VARIANTS := ["wall_1", "wall_2", "wall_3", "wall_4", "wall_5", "wall_empty"]
const LIGHTS := {&"hangar": Color(1.0, 0.85, 0.6), &"armory": Color(1.0, 0.75, 0.55), &"quarters": Color(0.75, 0.85, 1.0),
	&"medbay": Color(0.7, 1.0, 0.9), &"bridge": Color(1.0, 0.9, 0.55), &"galley": Color(1.0, 0.8, 0.5)}

## Einrichtung: [Modell, x, z, Drehung in Grad, Maßstab] (Schiffskoordinaten)
const PROPS := [
	["props_teleporter_1", 33.0, 8.0, 0.0, 1.3],
	["props_computer", 38.6, 5.6, -90.0, 1.0], ["props_computer", 38.6, 8.0, -90.0, 1.0], ["props_computer", 38.6, 10.4, -90.0, 1.0],
	["props_computersmall", 30.0, 4.8, 0.0, 1.0], ["props_computersmall", 30.0, 11.2, 180.0, 1.0],
	["column_slim", 28.6, 4.6, 0.0, 0.5], ["column_slim", 28.6, 11.4, 0.0, 0.5],
	["props_capsule", 17.4, 1.2, 0.0, 1.0], ["props_capsule", 19.2, 1.2, 0.0, 1.0], ["props_capsule", 21.0, 1.2, 0.0, 1.0],
	["props_capsule", 23.6, 1.2, 0.0, 1.0], ["props_capsule", 25.4, 1.2, 0.0, 1.0], ["props_capsule", 27.0, 1.2, 0.0, 1.0],
	["props_chest", 18.0, 6.6, 0.0, 1.0], ["props_shelf", 26.0, 7.0, 180.0, 1.0],
	["props_base", 19.5, 13.0, 0.0, 1.0], ["props_pod", 19.5, 13.0, 0.0, 0.8],
	["props_base", 24.5, 13.0, 0.0, 1.0], ["props_pod", 24.5, 13.0, 0.0, 0.8],
	["props_vessel_tall", 17.0, 9.2, 0.0, 1.0], ["props_vessel", 17.6, 9.2, 0.0, 1.0], ["props_vessel_tall", 18.2, 9.2, 0.0, 1.0],
	["props_computersmall", 27.0, 10.0, -90.0, 1.0],
	["dropship_insurgent", 7.0, 4.0, 90.0, 0.9],
	["props_crate", 1.2, 1.2, 0.0, 1.0], ["props_crate", 2.2, 1.2, 15.0, 1.0], ["props_crate", 1.4, 2.2, -10.0, 1.0],
	["props_containerfull", 14.6, 1.2, 0.0, 1.0],
	["props_shelf_tall", 3.0, 15.0, 180.0, 1.0], ["props_shelf_tall", 6.0, 15.0, 180.0, 1.0], ["props_shelf_tall", 14.4, 15.0, 180.0, 1.0],
	["props_laser", 11.0, 12.0, -90.0, 0.8],
	["props_cratelong", 1.2, 10.0, 90.0, 1.0], ["props_chest", 14.6, 10.0, 90.0, 1.0],
	["props_shelf", 31.0, 15.2, 180.0, 1.0], ["props_vessel_tall", 33.4, 15.2, 0.0, 1.0], ["props_vessel", 34.1, 15.2, 0.0, 1.0],
	["props_crate", 36.0, 13.0, 10.0, 1.0], ["props_chest", 37.6, 15.0, 0.0, 1.0], ["props_computersmall", 39.2, 14.0, -90.0, 1.0],
]

var _roots := {}          # Raum-ID -> Node3D (Wurzel der Raumszene)
var _aabb_cache := {}


func _init() -> void:
	var force := "--force" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "rooms"))
	for r in ShipView.ROOMS:
		var root := Node3D.new()
		root.name = String(r.id).capitalize().replace(" ", "")
		for part in ["Boden", "Waende", "Einrichtung", "Licht"]:
			var n := Node3D.new()
			n.name = part
			root.add_child(n)
			n.owner = root
		_roots[r.id] = root
	_build_floor()
	_build_walls()
	for p in PROPS:
		var pos := Vector3(p[1], 0, p[2])
		var r := ShipView.room_at(Vector2(pos.x, pos.z))
		_add(r.id, "Einrichtung", p[0], _xf(p[0], pos, p[3], Vector3.ONE * p[4]))
	_build_lights()
	var ship := Node3D.new()
	ship.name = "Ship"
	for r in ShipView.ROOMS:
		var path: String = OUT + "rooms/" + String(r.id) + ".tscn"
		if force or not FileAccess.file_exists(path):
			_save(_roots[r.id], path)
		else:
			print("unverändert (schon vorhanden): ", path)
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		inst.name = String(r.id)
		var o: Vector2 = (r.rect as Rect2).position
		inst.position = Vector3(o.x, 0, o.y)
		ship.add_child(inst)
		inst.owner = ship
	if force or not FileAccess.file_exists(OUT + "ship.tscn"):
		_save(ship, OUT + "ship.tscn")
	for n in _roots.values():
		(n as Node).free()
	ship.free()
	quit()


func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, path)
	print(("gespeichert: " if err == OK else "FEHLER %d: " % err), path)


## Modell als Instanz in einen Teil (Boden, Waende …) der Raumszene setzen; xf in Schiffskoordinaten
func _add(room_id: StringName, part: String, model: String, xf: Transform3D, parent: Node3D = null) -> Node3D:
	var root: Node3D = _roots[room_id]
	var n: Node3D = (load(DIR + model + ".glb") as PackedScene).instantiate()
	if parent == null:
		parent = root.get_node(part)
		var o: Vector2 = (ShipView.room(room_id).rect as Rect2).position
		xf.origin -= Vector3(o.x, 0, o.y)
	parent.add_child(n, true)
	n.name = model
	n.transform = xf
	n.owner = root
	return n


## Lage eines Modells, dessen Grundfläche mittig auf pos steht
func _xf(model: String, pos: Vector3, rot_deg: float, scale: Vector3) -> Transform3D:
	var a := _aabb(model)
	var basis := Basis(Vector3.UP, deg_to_rad(rot_deg)) * Basis.from_scale(scale)
	var anchor := Vector3(a.get_center().x, a.position.y, a.get_center().z)
	return Transform3D(basis, pos - basis * anchor)


func _build_floor() -> void:
	for r in ShipView.ROOMS:
		var rect: Rect2 = r.rect
		var nx := int(rect.size.x / TILE)
		var nz := int(rect.size.y / TILE)
		for i in nx:
			for j in nz:
				var c := Vector3(rect.position.x + (i + 0.5) * TILE, 0, rect.position.y + (j + 0.5) * TILE)
				var m := "floortile_basic" if (i + j) % 2 == 0 else "floortile_basic2"
				if r.id == &"hangar" and i > 0 and j > 0 and i < nx - 1 and j < nz - 1:
					m = "floortile_empty"
				var xf := _xf(m, c, 0.0, Vector3.ONE)
				xf.origin.y -= _aabb(m).size.y
				_add(r.id, "Boden", m, xf)


func _build_walls() -> void:
	var b := ShipView.bounds()
	var cols := int(b.size.x / CELL)
	var rows := int(b.size.y / CELL)
	var k := 0
	for i in cols + 1:
		for j in rows:
			_edge(Vector2(i * CELL, (j + 0.5) * CELL), _cell_room(i - 1, j), _cell_room(i, j), Vector3(1, 0, 0), k)
			k += 1
	for j in rows + 1:
		for i in cols:
			_edge(Vector2((i + 0.5) * CELL, j * CELL), _cell_room(i, j - 1), _cell_room(i, j), Vector3(0, 0, 1), k)
			k += 1


func _cell_room(i: int, j: int) -> Dictionary:
	return ShipView.room_at(Vector2((i + 0.5) * CELL, (j + 0.5) * CELL))


## Kante zwischen a (Seite −axis) und b (Seite +axis). Zwischenwände gehören zum Raum a.
func _edge(mid: Vector2, a: Dictionary, b: Dictionary, axis: Vector3, k: int) -> void:
	if a.is_empty() and b.is_empty():
		return
	if not a.is_empty() and not b.is_empty() and a.id == b.id:
		return
	var rot := 0.0 if axis.z != 0 else 90.0
	var pos := Vector3(mid.x, 0, mid.y)
	if not a.is_empty() and not b.is_empty():
		if mid in DOORS:
			var along := Vector3(axis.z, 0, axis.x)
			_add(a.id, "Waende", "column_slim", _xf("column_slim", pos - along * 2.0, 0.0, Vector3.ONE * 0.45))
			_add(a.id, "Waende", "column_slim", _xf("column_slim", pos + along * 2.0, 0.0, Vector3.ONE * 0.45))
			return
		var m: String = WALL_VARIANTS[k % WALL_VARIANTS.size()]
		var xf := _xf(m, pos, rot, Vector3.ONE)
		xf.basis = xf.basis * Basis.from_scale(Vector3(1, INNER_WALL, 1))
		_add(a.id, "Waende", m, xf)
		return
	# Außenwand: Knoten auf der Kantenmitte (Gruppe „cutaway“) mit „Voll“ und „Niedrig“
	var r: Dictionary = b if a.is_empty() else a
	var face := rot + (180.0 if b.is_empty() else 0.0)
	var holder := Node3D.new()
	holder.name = "Aussenwand"
	var o: Vector2 = (r.rect as Rect2).position
	holder.position = pos - Vector3(o.x, 0, o.y)
	holder.rotation_degrees.y = face
	var root: Node3D = _roots[r.id]
	root.get_node("Waende").add_child(holder, true)
	holder.owner = root
	holder.add_to_group(&"cutaway", true)
	var model: String = WINDOWS.get(mid, WALL_VARIANTS[k % WALL_VARIANTS.size()])
	var a1 := _aabb(model)
	var full := _add(r.id, "", model, Transform3D(Basis(), -Vector3(a1.get_center().x, a1.position.y, a1.get_center().z)), holder)
	full.name = "Voll"
	var a2 := _aabb("wall_empty")
	var low := _add(r.id, "", "wall_empty", Transform3D(Basis.from_scale(Vector3(1, LOW_WALL, 1)),
		-Vector3(a2.get_center().x, a2.position.y, a2.get_center().z)), holder)
	low.name = "Niedrig"
	low.visible = false


func _build_lights() -> void:
	for r in ShipView.ROOMS:
		var rect: Rect2 = r.rect
		var l := OmniLight3D.new()
		l.name = "Raumlicht"
		l.position = Vector3(rect.size.x / 2.0, 3.2, rect.size.y / 2.0)
		l.light_color = LIGHTS[r.id]
		l.light_energy = 0.9
		l.omni_range = maxf(rect.size.x, rect.size.y) * 0.8
		var root: Node3D = _roots[r.id]
		root.get_node("Licht").add_child(l)
		l.owner = root


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
