class_name UnitView
extends Node3D
## Eine Figur auf der Karte: Darstellung (3D-Modell oder Grundkörper, siehe Figure), Teamring,
## Sichtfeld der Figur am Zug, Namensschild mit Trefferpunkten, Zustandssymbole (StatusRow) und -effekte (StatusFx).

const STEP_TIME := 0.16

var unit: Combatant
var figure: Figure
var current := false
var dimmed := false             # eine andere Figur ist am Zug: Namensschild leicht abgedunkelt
const DIM_ALPHA := 0.7          # vorher 0.4: Trefferpunkte der Gegner waren kaum lesbar (Spieltest 15.10.2026)
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _label: Label3D
var _status: StatusRow
var _fx: StatusFx
var _fov: MeshInstance3D
var _pulse := 0.0
var _step_id := 0


func setup(u: Combatant) -> void:
	unit = u
	name = "Unit_%s" % u.id
	figure = ModelFigure.new() if u.visual and u.visual.model else ProceduralFigure.new()
	add_child(figure)
	figure.setup(u)
	_build_ring(u)
	_label = _make_label(26, u.color.lightened(0.5))   # Farbe der Figur, stark aufgehellt (lesbar auch bei Dunkelrot)
	_label.position = Vector3(0, figure.head_height() + 0.45, 0)
	# Elite gold, Boss rot umrandet (Balancing 24.10.2026)
	if u.elite == &"boss":
		_label.outline_modulate = Color(0.85, 0.2, 0.1, 1)
		_label.outline_size = 16
	elif u.elite != &"":
		_label.outline_modulate = Color(UiTheme.ACCENT, 1)
		_label.outline_size = 14
	_status = StatusRow.new()
	add_child(_status)
	_fx = StatusFx.new()
	add_child(_fx)
	_fx.setup(figure.head_height())
	set_facing(u.facing, false)
	_apply_pose()
	sync()


func _process(delta: float) -> void:
	if current and _ring.visible:
		_pulse += delta * 4.0
		_ring_mat.emission_energy_multiplier = 1.6 + sin(_pulse) * 0.9


## Anzeige aus dem Spielzustand übernehmen (nicht Position und Umfallen, das wird animiert)
func sync() -> void:
	var u := unit
	_label.text = "%s  %d/%d" % [u.letter, maxi(u.hp, 0), u.max_hp]
	_ring.visible = not u.is_dead()
	# die Figur am Zug zeigt statt des Namensschilds das ActiveTag der Oberfläche
	_label.visible = not u.is_dead() and not current
	_label.modulate.a = DIM_ALPHA if dimmed and not current else 1.0
	# Symbole über dem Namensschild; bei der Figur am Zug (Schild ausgeblendet) knapp unter dem Schild „am Zug“
	if current:
		_status.position = tag_point() - position
		_status.lift = -20.0
	else:
		_status.position = _label.position
		_status.lift = 34.0
	_status.visible = not u.is_dead()
	if _status.visible:
		_status.show_for(u, _label.modulate.a)
	_fx.sync(u)
	# niedergeworfen: Figur kippt zur Seite
	var tilt := 0.5 if u.prone and u.is_ok() else 0.0
	if not is_equal_approx(figure.rotation.z, tilt):
		create_tween().tween_property(figure, "rotation:z", tilt, 0.25)
	_fov.visible = current and u.is_ok()
	figure.set_ghost(not u.is_dead())
	if not current:
		_ring_mat.emission_energy_multiplier = 1.4
	var down := figure.pose == Figure.Pose.KO or figure.pose == Figure.Pose.DEAD
	if u.is_ok() and down:
		figure.stand_up()
	elif u.is_ok():
		_apply_pose()
	elif u.is_down() and not down:
		figure.fall(false)  # bewusstlos oder sterbend; der Tod wird über play_down abgespielt


func _apply_pose() -> void:
	var u := unit
	if u.is_dead():
		figure.set_pose(Figure.Pose.DEAD)
	elif u.is_down():
		figure.set_pose(Figure.Pose.KO)
	elif u.crouched:
		figure.set_pose(Figure.Pose.CROUCH)
	elif u.has_overwatch():
		figure.set_pose(Figure.Pose.AIM)
	else:
		figure.set_pose(Figure.Pose.STAND)


## v: diese Figur ist am Zug; dim: eine andere ist am Zug (Schild abdunkeln)
func set_current(v: bool, dim := false) -> void:
	current = v
	dimmed = dim and not v
	sync()


## Punkt über dem Kopf (Weltkoordinaten) für das Schild „am Zug“
func tag_point() -> Vector3:
	return position + Vector3(0, figure.head_height() + 0.35, 0)


func set_facing(dir: int, animate := true) -> void:
	var d := Hex.dir_vector(dir)
	var target := atan2(-d.x, -d.y)
	if animate:
		create_tween().tween_property(figure, "rotation:y", _closest_angle(figure.rotation.y, target), 0.15)
	else:
		figure.rotation.y = target
	_fov.rotation.y = target


## einen Schritt zum Zielpunkt gehen; bleibt nach dem letzten Schritt stehen
func step_to(p: Vector3, gait: StringName = &"gehen") -> void:
	_step_id += 1
	var my_id := _step_id
	figure.set_moving(gait)
	var d := p - position
	if Vector2(d.x, d.z).length() > 0.01:
		var target := atan2(-d.x, -d.z)
		figure.rotation.y = _closest_angle(figure.rotation.y, target)
		create_tween().tween_property(figure, "rotation:y", target, 0.08)
	var tw := create_tween()
	tw.tween_property(self, "position", p, STEP_TIME if gait == &"gehen" else STEP_TIME * 0.7)
	await tw.finished
	# kurz warten: kommt noch ein Schritt, läuft die Figur weiter
	get_tree().create_timer(0.08).timeout.connect(func() -> void:
		if my_id == _step_id:
			figure.set_moving(&"")
			_apply_pose())


func act(action: StringName, weapon: WeaponData = null) -> void:
	await figure.act(action, weapon)


func play_hit() -> void:
	figure.play_hit()


func play_down(dead: bool) -> void:
	await figure.fall(dead)
	sync()


func muzzle() -> Vector3:
	return figure.muzzle()


static func _closest_angle(from: float, to: float) -> float:
	return from + wrapf(to - from, -PI, PI)


func _make_label(size: int, color: Color) -> Label3D:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.fixed_size = true
	l.pixel_size = 0.0011
	l.font_size = size
	l.outline_size = 10
	l.outline_modulate = Color(0, 0, 0, 0.9)
	l.modulate = color
	l.render_priority = 2
	add_child(l)
	return l


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
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = u.color
	_ring_mat.emission_enabled = true
	_ring_mat.emission = u.color
	_ring_mat.emission_energy_multiplier = 1.4
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
