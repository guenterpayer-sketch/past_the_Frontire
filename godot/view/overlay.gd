class_name Overlay
extends Node3D
## Markierungen auf der Karte: erreichbare Felder, Weg, Zielfeld-Vorschau (wen treffe ich / wer trifft mich),
## angreifbare Gegner, Ziele für Erste Hilfe/Psi, Reichweite der Waffe, Feld unter der Maus.

const REACH_COLOR := Color(0.25, 0.55, 1.0, 0.28)
const PATH_COLOR := Color(0.55, 0.8, 1.0, 0.9)
const HIT_COLOR := Color(0.45, 0.95, 0.5, 0.85)
const THREAT_COLOR := Color(1.0, 0.4, 0.35, 0.85)
const RANGE_COLORS := [Color(0.4, 0.9, 0.45), Color(0.95, 0.85, 0.3), Color(1.0, 0.6, 0.25), Color(1.0, 0.35, 0.3)]

var map_view: MapView
var _reach: MultiMeshInstance3D
var _range: MultiMeshInstance3D
var _lines: MeshInstance3D
var _hover: MeshInstance3D
var _rings: Node3D
var _disc: CylinderMesh
var _line_mat: StandardMaterial3D


func _ready() -> void:
	_disc = CylinderMesh.new()
	_disc.top_radius = Hex.RADIUS_M * 0.86
	_disc.bottom_radius = _disc.top_radius
	_disc.height = 0.03
	_disc.radial_segments = 6
	_disc.rings = 1
	_reach = _multi(_disc, REACH_COLOR)
	var dot := SphereMesh.new()
	dot.radius = 0.12
	dot.height = 0.08
	dot.radial_segments = 8
	dot.rings = 2
	_range = _multi(dot, Color.WHITE)
	_lines = MeshInstance3D.new()
	_line_mat = _flat(Color.WHITE)
	_line_mat.vertex_color_use_as_albedo = true
	_line_mat.no_depth_test = true
	_lines.material_override = _line_mat
	_lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_lines)
	_hover = MeshInstance3D.new()
	_hover.mesh = _disc
	_hover.material_override = _flat(Color(1, 1, 1, 0.35))
	_hover.visible = false
	add_child(_hover)
	_rings = Node3D.new()
	add_child(_rings)


## state: reach (Reach), path (Array[Vector2i]), preview {hit: {Combatant: %}, threat: {...}},
## range {Vector2i: Stufe}, targets / helpers (Array[Combatant]), hover (Vector2i oder null), units {Combatant: UnitView}
func show_state(state: Dictionary) -> void:
	_fill_tiles(_reach, state.get("reach_tiles", []), [])
	var rng: Dictionary = state.get("range", {})
	var colors: Array = []
	for p in rng:
		colors.append(RANGE_COLORS[clampi(rng[p] - 1, 0, 3)])
	_fill_tiles(_range, rng.keys(), colors, 0.08)
	var hv: Variant = state.get("hover")
	_hover.visible = hv != null
	if hv != null:
		_hover.position = map_view.tile_top(hv) + Vector3(0, 0.05, 0)
	_draw_lines(state)
	for c in _rings.get_children():
		c.queue_free()
	var views: Dictionary = state.get("views", {})
	for u in state.get("targets", []):
		_ring(views[u].position, Color(1, 0.3, 0.25))
	for u in state.get("helpers", []):
		_ring(views[u].position, Color(0.4, 1.0, 0.5))
	# Vorschau: wen treffe ich vom Zielfeld (grün), wer trifft mich dort (rot), jeweils mit Chance
	var preview: Dictionary = state.get("preview", {})
	var hit: Dictionary = preview.get("hit", {})
	var threat: Dictionary = preview.get("threat", {})
	for u in hit:
		_ring(views[u].position, HIT_COLOR, 0.85)
		_tag(views[u].position + Vector3(0, 3.0, 0), "◎ %d %%" % hit[u], HIT_COLOR)
	for u in threat:
		_ring(views[u].position, THREAT_COLOR, 1.0)
		_tag(views[u].position + Vector3(0, 3.0 if not hit.has(u) else 3.45, 0), "⚠ %d %%" % threat[u], THREAT_COLOR)


func clear() -> void:
	show_state({})


func _draw_lines(state: Dictionary) -> void:
	var im := ImmediateMesh.new()
	var path: Array = state.get("path", [])
	var preview: Dictionary = state.get("preview", {})
	var views: Dictionary = state.get("views", {})
	if path.size() < 2 and preview.is_empty():
		_lines.mesh = null
		return
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(1, path.size()):
		var a := map_view.tile_top(path[i - 1]) + Vector3(0, 0.12, 0)
		var b := map_view.tile_top(path[i]) + Vector3(0, 0.12, 0)
		_seg(im, a, b, PATH_COLOR)
	if not path.is_empty() and not preview.is_empty():
		var from := map_view.tile_top(path[-1]) + Vector3(0, 1.3, 0)
		for u in preview.get("hit", {}):
			_seg(im, from, views[u].position + Vector3(0, 1.1, 0), HIT_COLOR)
		for u in preview.get("threat", {}):
			_seg(im, views[u].position + Vector3(0, 1.4, 0), from + Vector3(0, 0.2, 0), THREAT_COLOR)
	im.surface_end()
	_lines.mesh = im


func _seg(im: ImmediateMesh, a: Vector3, b: Vector3, c: Color) -> void:
	im.surface_set_color(c)
	im.surface_add_vertex(a)
	im.surface_set_color(c)
	im.surface_add_vertex(b)


func _tag(at: Vector3, text: String, c: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0011
	l.font_size = 26
	l.outline_size = 8
	l.modulate = Color(c, 1.0)
	l.render_priority = 4
	l.position = at
	_rings.add_child(l)


func _ring(at: Vector3, c: Color, radius := 0.65) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.05
	torus.outer_radius = radius + 0.05
	torus.rings = 32
	torus.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = torus
	mi.scale = Vector3(1, 0.25, 1)
	mi.position = at + Vector3(0, 0.06, 0)
	var m := _flat(c)
	m.no_depth_test = true
	mi.material_override = m
	_rings.add_child(mi)


func _fill_tiles(mmi: MultiMeshInstance3D, tiles: Array, colors: Array, lift := 0.04) -> void:
	var mm := mmi.multimesh
	mm.instance_count = tiles.size()
	for i in tiles.size():
		mm.set_instance_transform(i, Transform3D(Basis(), map_view.tile_top(tiles[i]) + Vector3(0, lift, 0)))
		if not colors.is_empty():
			mm.set_instance_color(i, colors[i])
	mmi.visible = tiles.size() > 0


func _multi(mesh: Mesh, c: Color) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := _flat(c)
	m.vertex_color_use_as_albedo = c == Color.WHITE
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m
