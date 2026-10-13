class_name ProceduralFigure
extends Figure
## Figur aus Grundkörpern (wenn kein 3D-Modell hinterlegt ist). Alle Teile in einem Mesh mit Vertexfarben.

var _body: Node3D
var _mat: StandardMaterial3D
var _ghost: StandardMaterial3D
var _st: SurfaceTool
var _st_glow: SurfaceTool


func setup(u: Combatant) -> void:
	super(u)
	_ghost = StandardMaterial3D.new()
	_ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.set("depth_test", 1)  # umgekehrter Tiefentest: nur sichtbar, wo die Figur verdeckt ist
	_ghost.albedo_color = Color(u.color, 0.22)
	_ghost.render_priority = -1
	_body = Node3D.new()
	add_child(_body)
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 0.6
	_mat.metallic = 0.2
	_mat.next_pass = _ghost
	var glow := _glow_mat()
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_glow = SurfaceTool.new()
	_st_glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	_build(u)
	_finish(_st, _mat)
	_finish(_st_glow, glow)


func set_pose(p: Pose) -> void:
	super(p)
	var lying := p == Pose.KO or p == Pose.DEAD
	rotation.x = deg_to_rad(-85.0) if lying else 0.0
	position.y = 0.25 if lying else 0.0
	_body.scale = Vector3(1, 0.7, 1) if p == Pose.CROUCH else Vector3.ONE
	_mat.albedo_color = Color.WHITE.darkened(0.65 if p == Pose.DEAD else (0.35 if p == Pose.KO else 0.0))


func play_hit() -> void:
	var tw := create_tween()
	tw.tween_property(_body, "position:z", 0.12, 0.05)
	tw.tween_property(_body, "position:z", 0.0, 0.12)


func fall(dead: bool) -> void:
	var tw := create_tween()
	tw.tween_property(self, "rotation:x", deg_to_rad(-85.0), 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "position:y", 0.25, 0.45)
	await tw.finished
	set_pose(Pose.DEAD if dead else Pose.KO)


func stand_up() -> void:
	set_pose(Pose.STAND)


func set_ghost(on: bool) -> void:
	_ghost.albedo_color.a = 0.22 if on else 0.0


func _build(u: Combatant) -> void:
	var c := u.color
	var armor_c := c.darkened(0.5) if u.armor.cls >= 2 else c.darkened(0.35)
	var dark := Color(0.15, 0.16, 0.19)
	var bulk := 1.0 + u.armor.cls * 0.06
	_part(_box(Vector3(0.18, 0.8, 0.22)), Vector3(-0.13, 0.4, 0), armor_c)
	_part(_box(Vector3(0.18, 0.8, 0.22)), Vector3(0.13, 0.4, 0), armor_c)
	_part(_box(Vector3(0.56 * bulk, 0.62, 0.34 * bulk)), Vector3(0, 1.1, 0), c)
	_part(_box(Vector3(0.62 * bulk, 0.14, 0.4 * bulk)), Vector3(0, 1.36, 0), c.darkened(0.2))
	_part(_box(Vector3(0.14, 0.52, 0.14)), Vector3(-0.37 * bulk, 1.08, -0.08), c.darkened(0.15))
	_part(_box(Vector3(0.14, 0.52, 0.14)), Vector3(0.37 * bulk, 1.08, -0.12), c.darkened(0.15))
	var head := SphereMesh.new()
	head.radius = 0.17
	head.height = 0.34
	head.radial_segments = 12
	head.rings = 6
	_part(head, Vector3(0, 1.6, 0), dark)
	_part(_box(Vector3(0.24, 0.07, 0.06)), Vector3(0, 1.62, -0.15), c.lightened(0.3), true)
	var w := u.weapons[0]
	if w.psi:
		var orb := SphereMesh.new()
		orb.radius = 0.1
		orb.height = 0.2
		orb.radial_segments = 10
		orb.rings = 5
		_part(orb, Vector3(0.38, 1.2, -0.35), Color(0.75, 0.5, 1.0), true)
	elif w.melee:
		_part(_box(Vector3(0.05, 0.05, 0.9)), Vector3(0.38, 1.05, -0.55), Color(0.6, 0.85, 1.0), true)
	elif not w.splash.is_empty():
		_part(_box(Vector3(0.18, 0.18, 1.1)), Vector3(0.28, 1.45, -0.2), Color(0.3, 0.33, 0.28))
	else:
		var length := 0.95 if w.ob_bonus > 0 else (0.8 if w.inc_m >= 15 else 0.45)
		_part(_box(Vector3(0.08, 0.12, length)), Vector3(0.2, 1.18, -0.2 - length / 2.0), dark)
		_part(_box(Vector3(0.07, 0.16, 0.12)), Vector3(0.2, 1.08, -0.3), dark)
	if u.shield:
		_part(_box(Vector3(0.08, 0.7, 0.5)), Vector3(-0.48, 1.05, -0.15), Color(0.5, 0.55, 0.62))


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## Körperteil in das gemeinsame Mesh einfügen (Farbe als Vertexfarbe)
func _part(mesh: Mesh, pos: Vector3, c: Color, glow := false) -> void:
	var arrays: Array = mesh.get_mesh_arrays()
	var colors := PackedColorArray()
	colors.resize(arrays[Mesh.ARRAY_VERTEX].size())
	colors.fill(c)
	arrays[Mesh.ARRAY_COLOR] = colors
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	(_st_glow if glow else _st).append_from(tmp, 0, Transform3D(Basis(), pos))


func _finish(st: SurfaceTool, m: Material) -> void:
	var mesh := st.commit()
	if mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	_body.add_child(mi)


func _glow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.emission_enabled = true
	m.emission = Color.WHITE
	m.emission_energy_multiplier = 1.5
	return m
