class_name SpaceMapView
extends Node3D
## Hexkarte des Raumkampfs: Felder als feine Linien, Asteroiden, Sterne im Hintergrund, Wegvorschau und Zielmarken.

const SCALE := 2.0
const GRID := Color(0.35, 0.5, 0.75, 0.22)
const PATH := Color(1.0, 0.83, 0.3, 0.9)

var _grid: MeshInstance3D
var _preview: MeshInstance3D
var _marks: Node3D
var _ghosts: Node3D


static func world(p: Vector2i, y := 0.0) -> Vector3:
	var w := Hex.to_world(p) * SCALE
	return Vector3(w.x, y, w.y)


static func cell_at(p: Vector3) -> Vector2i:
	return Hex.from_world(Vector2(p.x, p.z) / SCALE)


func build(c: SpaceCombat) -> void:
	for ch in get_children():
		ch.queue_free()
	_grid = MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat(GRID))
	var corners := Hex.corners(Hex.RADIUS_M * SCALE * 0.97)
	for cell in c.cells:
		var m := world(cell)
		for i in 6:
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % 6]
			im.surface_add_vertex(m + Vector3(a.x, 0, a.y))
			im.surface_add_vertex(m + Vector3(b.x, 0, b.y))
	im.surface_end()
	_grid.mesh = im
	add_child(_grid)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for cell in c.rocks:
		var rock := MeshInstance3D.new()
		var sm := SphereMesh.new()
		var r := rng.randf_range(0.9, 1.4)
		sm.radius = r
		sm.height = r * rng.randf_range(1.2, 1.7)
		sm.radial_segments = 9
		sm.rings = 5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.36, 0.31, 0.26).lerp(Color(0.22, 0.2, 0.19), rng.randf())
		mat.roughness = 1.0
		sm.material = mat
		rock.mesh = sm
		rock.position = world(cell, 0.2)
		rock.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		add_child(rock)
	_add_stars(c)
	_preview = MeshInstance3D.new()
	add_child(_preview)
	_marks = Node3D.new()
	add_child(_marks)
	_ghosts = Node3D.new()
	add_child(_ghosts)


func _add_stars(c: SpaceCombat) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var q := QuadMesh.new()
	q.size = Vector2(0.18, 0.18)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.85, 0.9, 1.0)
	q.material = mat
	mm.mesh = q
	mm.instance_count = 500
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mid := world(Hex.from_offset(SpaceCombat.MAP_W / 2, SpaceCombat.MAP_H / 2))
	for i in mm.instance_count:
		var p := mid + Vector3(rng.randf_range(-90, 90), rng.randf_range(-40, -8), rng.randf_range(-70, 70))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.5, 2.0)), p))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	add_child(mi)


static func _line_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	m.vertex_color_use_as_albedo = false
	return m


## Wegvorschau: Felder nacheinander ab `from`, Endausrichtung als Pfeil
func show_path(from: Vector2i, path: Array[Vector2i], facing: int, blocked: bool) -> void:
	var im := ImmediateMesh.new()
	var col := Color(1, 0.4, 0.35, 0.9) if blocked else PATH
	im.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat(col))
	var prev := world(from, 0.15)
	for p in path:
		var w := world(p, 0.15)
		im.surface_add_vertex(prev)
		im.surface_add_vertex(w)
		prev = w
	var end := world(path[-1] if not path.is_empty() else from, 0.15)
	var d := Hex.dir_vector(facing) * SCALE * 0.9
	var tip := end + Vector3(d.x, 0, d.y)
	im.surface_add_vertex(end)
	im.surface_add_vertex(tip)
	var side := Vector3(-d.y, 0, d.x) * 0.35
	im.surface_add_vertex(tip)
	im.surface_add_vertex(tip - Vector3(d.x, 0, d.y) * 0.4 + side)
	im.surface_add_vertex(tip)
	im.surface_add_vertex(tip - Vector3(d.x, 0, d.y) * 0.4 - side)
	im.surface_end()
	_preview.mesh = im


func clear_path() -> void:
	_preview.mesh = null
	for ch in _ghosts.get_children():
		ch.queue_free()


## Geschätzte Gegnerpositionen als Schatten mit Pfeil (nur Schätzung der KI)
func show_ghosts(pred: Dictionary) -> void:
	for ch in _ghosts.get_children():
		ch.queue_free()
	var col := Color(1.0, 0.36, 0.36, 0.55)
	for id in pred:
		var p: Vector2i = pred[id].pos
		var ring := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = SCALE * 0.55
		t.outer_radius = SCALE * 0.65
		t.material = _line_mat(col)
		ring.mesh = t
		ring.position = world(p, 0.1)
		_ghosts.add_child(ring)
		var im := ImmediateMesh.new()
		im.surface_begin(Mesh.PRIMITIVE_LINES, _line_mat(col))
		var d := Hex.dir_vector(int(pred[id].facing)) * SCALE * 0.9
		im.surface_add_vertex(world(p, 0.12))
		im.surface_add_vertex(world(p, 0.12) + Vector3(d.x, 0, d.y))
		im.surface_end()
		var arrow := MeshInstance3D.new()
		arrow.mesh = im
		_ghosts.add_child(arrow)


## Feld-Markierungen (z. B. mögliche Ziele)
func mark(cells: Array, col: Color) -> void:
	for ch in _marks.get_children():
		ch.queue_free()
	for cell in cells:
		var ring := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = SCALE * 0.95
		t.outer_radius = SCALE * 1.05
		var m := _line_mat(col)
		t.material = m
		ring.mesh = t
		ring.position = world(cell, 0.05)
		_marks.add_child(ring)
