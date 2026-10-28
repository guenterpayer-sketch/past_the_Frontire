extends SceneTree
## Probe (28.10.2026): das Schiff aus Kenney-Modular-Space-Teilen (Boden, Wände, Eckpfosten), eingerichtet mit
## Möbeln aus allen Packs. Schreibt `ship/kenney/rooms/<id>.tscn` und `ship/kenney/ship.tscn` (überschreibt immer).
## Ansehen im Spiel: in `hub.tscn` beim Knoten „Ship“ die Eigenschaft „Scene Path“ auf `res://ship/kenney/ship.tscn`.
## Aufruf: godot --headless --path godot --script res://tools/bake_ship_kenney.gd

const K := "res://assets/packs/kenney_space/"
const P := "res://assets/packs/"
const OUT := "res://ship/kenney/"
const CELL := 4.0
const INNER_WALL := 0.45
const LOW_WALL := 0.1

const DOORS := [Vector2(16, 6), Vector2(16, 10), Vector2(28, 6), Vector2(22, 8), Vector2(10, 8), Vector2(28, 14)]
const LIGHTS := {&"hangar": Color(1.0, 0.85, 0.6), &"armory": Color(1.0, 0.75, 0.55), &"quarters": Color(0.75, 0.85, 1.0),
	&"medbay": Color(0.7, 1.0, 0.9), &"bridge": Color(1.0, 0.9, 0.55), &"galley": Color(1.0, 0.8, 0.5)}
## Bodenzellen mit eigener Platte statt Kenney-Boden (Mittelpunkt der 4-m-Zelle -> Modell)
const FLOORS := {Vector2(6, 2): "molten/Hazard_Floor_1.glb", Vector2(10, 2): "molten/Hazard_Floor_1.glb",
	Vector2(6, 6): "molten/Hazard_Floor_1.glb", Vector2(10, 6): "molten/Hazard_Floor_1.glb"}

## Einrichtung: [Datei unter assets/packs/ (oder voller res://-Pfad), x, z, Drehung in Grad, Maßstab, Höhe (optional)]
const PROPS := [
	# Maschinenraum: Landungsschiff auf markierter Fläche, Generatoren, Batterien, Fässer
	["res://assets/ship/dropship_insurgent.glb", 8.0, 4.0, 90.0, 0.9],
	["molten/Generator_Pile_Chonky.glb", 14.2, 1.8, 0.0, 1.0],
	["molten/Generator_Pile_Small.glb", 12.0, 1.0, 0.0, 1.0],
	["molten/Battery_Orange.glb", 1.0, 0.6, 0.0, 1.0], ["molten/Battery_Orange.glb", 2.0, 0.6, 0.0, 1.0], ["molten/Battery_Grey.glb", 3.0, 0.6, 0.0, 1.0],
	["megakit/Props/Prop_Barrel_Large.gltf", 0.6, 6.6, 0.0, 1.0], ["megakit/Props/Prop_Barrel_Large.gltf", 0.6, 7.4, 30.0, 1.0],
	["essentials/Prop_Crate_Tarp_Large.gltf", 2.8, 7.0, 0.0, 1.0],
	["megakit/Props/Prop_Crate4.gltf", 14.6, 3.8, 10.0, 1.0],
	# Waffenkammer: Spinde, Regale, Werkbank mit Waffen, Munition
	["essentials/Prop_Locker.gltf", 0.4, 9.8, 90.0, 1.0], ["essentials/Prop_Locker.gltf", 0.4, 10.8, 90.0, 1.0], ["essentials/Prop_Locker.gltf", 0.4, 11.8, 90.0, 1.0],
	["essentials/Prop_Shelves_WideTall.gltf", 1.6, 15.6, 180.0, 1.0], ["essentials/Prop_Shelves_WideTall.gltf", 3.7, 15.6, 180.0, 1.0],
	["essentials/Prop_Shelves_WideShort.gltf", 5.8, 15.6, 180.0, 1.0],
	["essentials/Prop_Desk_Medium.gltf", 10.0, 15.3, 180.0, 1.0],
	["essentials/Gun_Rifle.gltf", 9.4, 15.3, 0.0, 1.0, 0.98], ["essentials/Gun_Sniper.gltf", 10.6, 15.3, 0.0, 1.0, 0.98],
	["essentials/Gun_Pistol.gltf", 10.9, 15.0, 30.0, 1.0, 0.98], ["essentials/Prop_Grenade.gltf", 9.0, 15.0, 0.0, 1.0, 0.94],
	["essentials/Prop_Chair.gltf", 10.0, 14.2, 0.0, 1.0],
	["res://assets/ship/props_laser.glb", 6.0, 12.0, 0.0, 0.8],
	["essentials/Prop_Ammo.gltf", 14.4, 15.4, 0.0, 1.0], ["essentials/Prop_Ammo.gltf", 15.2, 15.4, 0.0, 1.0],
	["essentials/Prop_Ammo_Closed.gltf", 14.8, 15.4, 0.0, 1.0, 0.28], ["essentials/Prop_Ammo_Small.gltf", 15.2, 14.5, 20.0, 1.0],
	["essentials/Prop_Crate.gltf", 13.6, 8.8, 0.0, 1.0],
	# Crewquartiere: drei Doppelstockbetten, Nachttische, Spinde, Schachecke
	["molten/Bunk_Double_Blue.glb", 18.0, 1.45, 0.0, 1.0], ["molten/Bunk_Double_Green.glb", 21.0, 1.45, 0.0, 1.0],
	["molten/Bunk_Double_Orange.glb", 24.0, 1.45, 0.0, 1.0],
	["molten/End_Table.glb", 19.5, 0.6, 0.0, 1.0], ["molten/Lava_Lamp.glb", 19.5, 0.6, 0.0, 1.0, 0.93],
	["molten/End_Table.glb", 22.5, 0.6, 0.0, 1.0], ["molten/Table_Light.glb", 22.5, 0.6, 0.0, 1.0, 0.93],
	["essentials/Prop_Locker.gltf", 27.6, 0.8, -90.0, 1.0], ["essentials/Prop_Locker.gltf", 27.6, 1.8, -90.0, 1.0], ["essentials/Prop_Locker.gltf", 27.6, 2.8, -90.0, 1.0],
	["molten/End_Table.glb", 24.5, 5.2, 0.0, 1.0], ["molten/3D_Chess_Board.glb", 24.5, 5.2, 0.0, 1.0, 0.93],
	["molten/Chair_1.glb", 23.5, 5.2, 90.0, 1.0], ["molten/Chair_1.glb", 25.5, 5.2, -90.0, 1.0],
	["molten/Plant_1.glb", 16.7, 3.4, 0.0, 1.0],
	# Krankenstation: Heilkammern mit Überwachung, Behandlungsliege, Arbeitsplatz, Regal
	["molten/Cryo_Tube_ON.glb", 18.2, 14.8, 0.0, 1.0], ["molten/BioMonitor_Green.glb", 19.8, 15.3, 0.0, 1.0],
	["molten/Cryo_Tube_ON.glb", 21.6, 14.8, 0.0, 1.0], ["molten/BioMonitor_Green.glb", 23.2, 15.3, 0.0, 1.0],
	["molten/Bunk_Single_Grey.glb", 25.6, 9.8, 0.0, 1.0],
	["essentials/Prop_Desk_Small.gltf", 27.3, 12.8, -90.0, 1.0], ["essentials/Prop_Chair.gltf", 26.2, 12.8, 90.0, 1.0],
	["essentials/Prop_HealthPack.gltf", 27.4, 12.3, 0.0, 1.0, 1.2], ["essentials/Prop_Syringe.gltf", 27.3, 13.3, 40.0, 1.0, 0.95],
	["essentials/Prop_Shelves_ThinTall.gltf", 27.6, 15.0, -90.0, 1.0],
	["essentials/Prop_HealthPack_Tube.gltf", 17.0, 9.0, 0.0, 1.0],
	# Brücke: Kommandopult in der Mitte, Kartentisch, Bildschirme, Konsolen an der Front
	["molten/Command_Console.glb", 35.0, 8.0, 0.0, 0.7],
	["res://assets/ship/props_teleporter_1.glb", 30.6, 8.0, 0.0, 1.3],
	["molten/Large_Monitor_Blue.glb", 33.0, 4.6, 0.0, 1.0], ["molten/Large_Monitor_Blue.glb", 37.0, 4.6, 0.0, 1.0],
	["megakit/Props/Prop_Computer.gltf", 39.5, 5.0, -90.0, 1.0], ["megakit/Props/Prop_Computer.gltf", 39.5, 11.0, -90.0, 1.0],
	# Kombüse: Esstische, Hydrokultur, Vorratsregal
	["molten/Cafeteria_Table.glb", 32.6, 14.0, 0.0, 1.0], ["molten/Cafeteria_Table.glb", 35.4, 14.0, 0.0, 1.0],
	["essentials/Prop_Mug.gltf", 32.3, 13.7, 0.0, 1.0, 0.93], ["essentials/Prop_Mug.gltf", 35.7, 14.4, 0.0, 1.0, 0.93],
	["molten/Hydroponics_Full.glb", 39.0, 14.0, 0.0, 1.0],
	["essentials/Prop_Shelves_WideShort.gltf", 30.0, 15.6, 180.0, 1.0],
	["molten/Space_Ketchup.glb", 29.6, 15.6, 0.0, 1.0, 1.21], ["molten/Space_Mayo_Naise.glb", 30.2, 15.6, 0.0, 1.0, 1.21],
	["essentials/Prop_Barrel1.gltf", 37.2, 12.6, 0.0, 1.0],
]

var _roots := {}
var _aabb_cache := {}


func _init() -> void:
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
	_build_corners()
	for p in PROPS:
		var pos := Vector3(p[1], 0, p[2])
		var r := ShipView.room_at(Vector2(pos.x, pos.z))
		var file: String = p[0] if String(p[0]).begins_with("res://") else P + p[0]
		var xf := _xf(file, pos, p[3], Vector3.ONE * p[4])
		if p.size() > 5:
			xf.origin.y += p[5]
		_add(r.id, "Einrichtung", file, xf)
	_build_lights()
	var ship := Node3D.new()
	ship.name = "Ship"
	for r in ShipView.ROOMS:
		var path: String = OUT + "rooms/" + String(r.id) + ".tscn"
		_save(_roots[r.id], path)
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		inst.name = String(r.id)
		var o: Vector2 = (r.rect as Rect2).position
		inst.position = Vector3(o.x, 0, o.y)
		ship.add_child(inst)
		inst.owner = ship
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


## Modell als Instanz in einen Teil der Raumszene setzen; xf in Schiffskoordinaten (ohne parent)
func _add(room_id: StringName, part: String, file: String, xf: Transform3D, parent: Node3D = null) -> Node3D:
	var root: Node3D = _roots[room_id]
	var n: Node3D = (load(file) as PackedScene).instantiate()
	if parent == null:
		parent = root.get_node(part)
		var o: Vector2 = (ShipView.room(room_id).rect as Rect2).position
		xf.origin -= Vector3(o.x, 0, o.y)
	parent.add_child(n, true)
	n.name = file.get_file().get_basename().replace(" ", "_")
	n.transform = xf
	n.owner = root
	return n


## Lage eines Modells, dessen Grundfläche mittig auf pos steht
func _xf(file: String, pos: Vector3, rot_deg: float, scale: Vector3) -> Transform3D:
	var a := _aabb(file)
	var basis := Basis(Vector3.UP, deg_to_rad(rot_deg)) * Basis.from_scale(scale)
	var anchor := Vector3(a.get_center().x, a.position.y, a.get_center().z)
	return Transform3D(basis, pos - basis * anchor)


func _build_floor() -> void:
	for r in ShipView.ROOMS:
		var rect: Rect2 = r.rect
		for i in int(rect.size.x / CELL):
			for j in int(rect.size.y / CELL):
				var c := Vector2(rect.position.x + (i + 0.5) * CELL, rect.position.y + (j + 0.5) * CELL)
				if FLOORS.has(c):
					var f: String = P + FLOORS[c]
					var xf := _xf(f, Vector3(c.x, 0, c.y), 0.0, Vector3.ONE)
					xf.origin.y -= _aabb(f).size.y - 0.01
					_add(r.id, "Boden", f, xf)
				else:
					_add(r.id, "Boden", K + "template-floor.glb", Transform3D(Basis(), Vector3(c.x, 0, c.y)))


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


## Drehung, bei der die Rückseite eines Kenney-Teils (lokal −z) in Richtung out zeigt
func _yaw(out: Vector3) -> float:
	return rad_to_deg(atan2(-out.x, -out.z))


## Kante zwischen a (Seite −axis) und b (Seite +axis). Zwischenwände gehören zum Raum a.
func _edge(mid: Vector2, a: Dictionary, b: Dictionary, axis: Vector3, k: int) -> void:
	if a.is_empty() and b.is_empty():
		return
	if not a.is_empty() and not b.is_empty() and a.id == b.id:
		return
	var pos := Vector3(mid.x, 0, mid.y)
	if not a.is_empty() and not b.is_empty():
		if mid in DOORS:
			return
		# halbhoch, halb so dick, mittig auf der Kante
		var basis := Basis(Vector3.UP, deg_to_rad(_yaw(-axis))) * Basis.from_scale(Vector3(1, INNER_WALL, 0.5))
		_add(a.id, "Waende", K + "template-wall.glb", Transform3D(basis, pos + basis * Vector3(0, 0, 0.5)))
		return
	# Außenwand: Teil steht außen vor der Kante, Innenseite zeigt in den Raum
	var r: Dictionary = b if a.is_empty() else a
	var out := axis if b.is_empty() else -axis
	# Wand mit dunklem Gitter nur an der Nordseite (sonst wirkt sie von schräg oben wie ein Möbelstück)
	var model := "template-wall-detail-a" if k % 3 == 1 and out.z < 0 else "template-wall"
	_cutaway(r, pos, _yaw(out), K + model + ".glb", out)


## Eckpfosten an allen nach außen gewölbten Ecken der Schiffskontur
func _build_corners() -> void:
	var b := ShipView.bounds()
	for i in int(b.size.x / CELL) + 1:
		for j in int(b.size.y / CELL) + 1:
			var cells := [[-1, -1], [0, -1], [-1, 0], [0, 0]]
			var inside := []
			for c in cells:
				if not _cell_room(i + c[0], j + c[1]).is_empty():
					inside.append(c)
			if inside.size() != 1:
				continue
			var c: Array = inside[0]
			var out := Vector3(-1 if c[0] == 0 else 1, 0, -1 if c[1] == 0 else 1)
			var r := _cell_room(i + c[0], j + c[1])
			# template-wall-corner liegt lokal bei x −1..0, z −1..0 (Richtung (−1, −1))
			_cutaway(r, Vector3(i * CELL, 0, j * CELL), rad_to_deg(atan2(-out.x, -out.z)) - 45.0, K + "template-wall-corner.glb", out.normalized())


## Außenteil mit Kindern „Voll“ und „Niedrig“ in der Gruppe „cutaway“
func _cutaway(r: Dictionary, pos: Vector3, yaw: float, file: String, out: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "Aussenwand"
	var o: Vector2 = (r.rect as Rect2).position
	holder.position = pos - Vector3(o.x, 0, o.y)
	holder.rotation_degrees.y = yaw
	var root: Node3D = _roots[r.id]
	root.get_node("Waende").add_child(holder, true)
	holder.owner = root
	holder.add_to_group(&"cutaway", true)
	holder.set_meta(&"cutaway_normal", out)
	var full := _add(r.id, "", file, Transform3D(), holder)
	full.name = "Voll"
	var low := _add(r.id, "", file, Transform3D(Basis.from_scale(Vector3(1, LOW_WALL, 1)), Vector3.ZERO), holder)
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


func _aabb(file: String) -> AABB:
	if _aabb_cache.has(file):
		return _aabb_cache[file]
	var root: Node3D = (load(file) as PackedScene).instantiate()
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
	_aabb_cache[file] = box
	return box
