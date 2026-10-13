class_name UnitView
extends Node3D
## Darstellung einer Figur: Modell aus Grundkörpern (vorne = −z), Teamring, Namensschild,
## Zustände (geduckt, bewusstlos, tot, Feuerbereitschaft). Durch Hindernisse hindurch als Umriss sichtbar.

const STEP_TIME := 0.12

var unit: Combatant
var _model: Node3D
var _body: Node3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _label: Label3D
var _icon: Label3D
var _fov: MeshInstance3D
var _mat: StandardMaterial3D        # alle Körperteile in einem Mesh mit Vertexfarben
var _glow_mat: StandardMaterial3D   # leuchtende Teile (Visier, Klinge, Psi-Kugel)
var _st: SurfaceTool
var _st_glow: SurfaceTool
var _ghost: StandardMaterial3D
var _pulse := 0.0
var current := false


func setup(u: Combatant) -> void:
	unit = u
	name = "Unit_%s" % u.id
	_ghost = StandardMaterial3D.new()
	_ghost.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ghost.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost.no_depth_test = true
	_ghost.albedo_color = Color(u.color, 0.22)
	_ghost.render_priority = -1
	_model = Node3D.new()
	add_child(_model)
	_body = Node3D.new()
	_model.add_child(_body)
	_mat = StandardMaterial3D.new()
	_mat.vertex_color_use_as_albedo = true
	_mat.roughness = 0.6
	_mat.metallic = 0.2
	_mat.next_pass = _ghost
	_glow_mat = _glow(Color.WHITE, 1.5)
	_glow_mat.vertex_color_use_as_albedo = true
	_st = SurfaceTool.new()
	_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_st_glow = SurfaceTool.new()
	_st_glow.begin(Mesh.PRIMITIVE_TRIANGLES)
	_build_model(u)
	_finish_mesh(_st, _mat)
	_finish_mesh(_st_glow, _glow_mat)
	_build_ring(u)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = true
	_label.pixel_size = 0.0011
	_label.font_size = 26
	_label.outline_size = 8
	_label.position = Vector3(0, 2.3, 0)
	_label.modulate = u.color.lightened(0.35)
	_label.render_priority = 2
	add_child(_label)
	_icon = Label3D.new()
	_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icon.no_depth_test = true
	_icon.fixed_size = true
	_icon.pixel_size = 0.0011
	_icon.font_size = 30
	_icon.outline_size = 8
	_icon.position = Vector3(0, 2.75, 0)
	_icon.render_priority = 2
	add_child(_icon)
	set_facing(u.facing, false)
	sync()


func _process(delta: float) -> void:
	if current and _ring.visible:
		_pulse += delta * 4.0
		_ring_mat.emission_energy_multiplier = 1.6 + sin(_pulse) * 0.9


## Zustand aus dem Modell übernehmen (nicht die Position, die wird animiert)
func sync() -> void:
	var u := unit
	_label.text = "%s  %d/%d" % [u.letter, maxi(u.hp, 0), u.max_hp]
	var icons := ""
	if u.has_overwatch():
		icons += "◎"
	if u.waiting:
		icons += "⏸"
	if u.psi_shield > 0:
		icons += "✦"
	if u.bleed > 0:
		icons += "•"
	_icon.text = icons
	_icon.modulate = Color(1, 0.85, 0.3)
	_ring.visible = not u.is_dead()
	_label.visible = not u.is_dead()
	var lying := not u.is_ok()
	_model.rotation.x = deg_to_rad(-85.0) if lying else 0.0
	_model.position.y = 0.25 if lying else 0.0
	_body.scale = Vector3(1, 0.7, 1) if u.crouched and not lying else Vector3.ONE
	_body.position.y = 0.0
	var dim := 0.0 if u.is_ok() else (0.35 if u.state == Combatant.State.KO else 0.65)
	_mat.albedo_color = Color.WHITE.darkened(dim)
	_ghost.albedo_color.a = 0.0 if u.is_dead() else 0.22
	_fov.visible = current and u.is_ok()
	if not current:
		_ring_mat.emission_energy_multiplier = 1.4


func set_current(v: bool) -> void:
	current = v
	sync()


func set_facing(dir: int, animate := true) -> void:
	var d := Hex.dir_vector(dir)
	var target := atan2(-d.x, -d.y)
	if animate:
		var tw := create_tween()
		tw.tween_property(_model, "rotation:y", _closest_angle(_model.rotation.y, target), 0.12)
	else:
		_model.rotation.y = target
	_fov.rotation.y = target


## einen Schritt zum Zielpunkt gehen
func step_to(p: Vector3) -> void:
	var d := p - position
	if Vector2(d.x, d.z).length() > 0.01:
		var target := atan2(-d.x, -d.z)
		_model.rotation.y = _closest_angle(_model.rotation.y, target)
		create_tween().tween_property(_model, "rotation:y", target, 0.06)
	var tw := create_tween()
	tw.tween_property(self, "position", p, STEP_TIME)
	await tw.finished


func play_hit() -> void:
	var tw := create_tween()
	tw.tween_property(_body, "position:z", 0.12, 0.05)
	tw.tween_property(_body, "position:z", 0.0, 0.12)


func play_down() -> void:
	var tw := create_tween()
	tw.tween_property(_model, "rotation:x", deg_to_rad(-85.0), 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_model, "position:y", 0.25, 0.45)
	await tw.finished
	sync()


static func _closest_angle(from: float, to: float) -> float:
	return from + wrapf(to - from, -PI, PI)


# ---------------------------------------------------------------- Modell

func _build_model(u: Combatant) -> void:
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
	_build_weapon(u.weapons[0], dark)
	if u.shield:
		_part(_box(Vector3(0.08, 0.7, 0.5)), Vector3(-0.48, 1.05, -0.15), Color(0.5, 0.55, 0.62))


func _build_weapon(w: WeaponData, dark: Color) -> void:
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


func _build_ring(u: Combatant) -> void:
	var torus := TorusMesh.new()
	torus.inner_radius = 0.46
	torus.outer_radius = 0.54
	torus.rings = 32
	torus.ring_segments = 6
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position.y = 0.04
	_ring.scale = Vector3(1, 0.3, 1)
	_ring_mat = _glow(u.color, 1.4)
	_ring.material_override = _ring_mat
	add_child(_ring)
	# Sichtfeld (180° nach vorne) für die Figur am Zug
	_fov = MeshInstance3D.new()
	_fov.mesh = _half_disc(1.8)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(1, 1, 1, 0.1)
	_fov.material_override = m
	_fov.position.y = 0.03
	_fov.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fov)


func _half_disc(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 16
	for i in n:
		var a0 := PI * i / n
		var a1 := PI * (i + 1) / n
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(cos(a1) * radius, 0, -sin(a1) * radius))
		st.add_vertex(Vector3(cos(a0) * radius, 0, -sin(a0) * radius))
	return st.commit()


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## Körperteil in das gemeinsame Mesh der Figur einfügen (Farbe als Vertexfarbe)
func _part(mesh: Mesh, pos: Vector3, c: Color, glow := false) -> void:
	var arrays: Array = mesh.get_mesh_arrays()
	var n: int = arrays[Mesh.ARRAY_VERTEX].size()
	var colors := PackedColorArray()
	colors.resize(n)
	colors.fill(c)
	arrays[Mesh.ARRAY_COLOR] = colors
	var tmp := ArrayMesh.new()
	tmp.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	(_st_glow if glow else _st).append_from(tmp, 0, Transform3D(Basis(), pos))


func _finish_mesh(st: SurfaceTool, m: Material) -> void:
	var mesh := st.commit()
	if mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	_body.add_child(mi)


func _glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m
