class_name ModelBatch
extends RefCounted
## Setzt viele Kopien von Modellen (VisualSlot) in die Halle und zeichnet jede Kopie desselben Teils
## mit einem MultiMesh (wenige Zeichenaufrufe, auch bei Hunderten Bodenplatten).

var _parts := {}       # VisualSlot -> Array[[Mesh, Transform3D]]
var _aabbs := {}       # VisualSlot -> AABB
var _instances := {}   # "Gruppe" -> {VisualSlot: Array[Transform3D]}


## Umriss des Modells (im eigenen Raum)
func aabb(slot: VisualSlot) -> AABB:
	_load(slot)
	return _aabbs[slot]


## Transformation, die das Modell in einen Quader setzt (Mitte unten, Größe in Weltachsen)
func fit_box(slot: VisualSlot, center_bottom: Vector3, size: Vector3, rot_y := 0.0) -> Transform3D:
	var a := aabb(slot)
	var rot := deg_to_rad(slot.rotation_y_deg) + rot_y
	var local := Vector3(size.z, size.y, size.x) if absf(sin(rot)) > 0.5 else size
	var s: Vector3
	if slot.fit == VisualSlot.Fit.HEIGHT:
		var k := size.y / maxf(a.size.y, 0.001)
		s = Vector3(k, k, k)
	else:
		s = Vector3(local.x / maxf(a.size.x, 0.001), local.y / maxf(a.size.y, 0.001), local.z / maxf(a.size.z, 0.001))
	var basis := Basis(Vector3.UP, rot) * Basis.from_scale(s)
	var anchor := Vector3(a.get_center().x, a.position.y, a.get_center().z)
	return Transform3D(basis, center_bottom - basis * anchor)


## Quader entlang seiner längeren Seite mit Modellstücken füllen (Regale, Wände)
func fill_repeat(slot: VisualSlot, center_bottom: Vector3, size: Vector3, group := "") -> void:
	var along_x := size.x >= size.z
	var length := size.x if along_x else size.z
	var n := maxi(1, roundi(length / maxf(slot.repeat_m, 0.1)))
	var piece := length / n
	for i in n:
		var off := -length / 2.0 + piece * (i + 0.5)
		var c := center_bottom + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off))
		var s := Vector3(piece, size.y, size.z) if along_x else Vector3(size.x, size.y, piece)
		add(slot, fit_box(slot, c, s, 0.0 if along_x else PI / 2.0), group)


func add(slot: VisualSlot, xf: Transform3D, group := "") -> void:
	_load(slot)
	if not _instances.has(group):
		_instances[group] = {}
	if not _instances[group].has(slot):
		_instances[group][slot] = []
	_instances[group][slot].append(xf)


## MultiMeshes erzeugen; parent_of(Gruppe) liefert den Elternknoten
func build(parent_of: Callable) -> void:
	for group in _instances:
		var parent: Node3D = parent_of.call(group)
		for slot in _instances[group]:
			var xfs: Array = _instances[group][slot]
			for part in _parts[slot]:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = part[0]
				mm.instance_count = xfs.size()
				for i in xfs.size():
					mm.set_instance_transform(i, xfs[i] * part[1])
				var mmi := MultiMeshInstance3D.new()
				mmi.multimesh = mm
				parent.add_child(mmi)
	_instances.clear()


func _load(slot: VisualSlot) -> void:
	if _parts.has(slot):
		return
	var root: Node3D = slot.model.instantiate()
	var parts: Array = []
	var box := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D()
		var n: Node = mi
		while n != root and n != null:
			if n is Node3D:
				xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		# Materialien, die am Knoten statt am Mesh hängen, auf eine Kopie des Meshes übertragen
		var overrides := false
		for s in mesh.get_surface_count():
			if (mi as MeshInstance3D).get_surface_override_material(s):
				overrides = true
		if overrides:
			mesh = mesh.duplicate()
			for s in mesh.get_surface_count():
				var m: Material = (mi as MeshInstance3D).get_surface_override_material(s)
				if m:
					mesh.surface_set_material(s, m)
		parts.append([mesh, xf])
		var a: AABB = xf * mesh.get_aabb()
		box = a if first else box.merge(a)
		first = false
	root.free()
	_parts[slot] = parts
	_aabbs[slot] = box
