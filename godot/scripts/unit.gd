extends Node3D
## Eine Spielfigur: einfaches Modell aus Grundkörpern, Namensschild, Klick-Kollision.

var unit_name := ""
var team := "crew"
var color := Color.WHITE
var hp := 30
var max_hp := 30
var ob := 60         # Angriffswert (Gesamtbonus der Waffenfertigkeit)
var db := 15         # Verteidigung (Ausweichen, Rüstung)
var armor := 1       # Rüstungsklasse 0–3
var weapon := "sturmgewehr"
var tile := Vector2i.ZERO
var h := 0
var dead := false

var model: Node3D
var label: Label3D
var ring: MeshInstance3D


func build(n: String, t: String, c: Color) -> void:
	unit_name = n
	team = t
	color = c
	model = Node3D.new()
	add_child(model)
	var armor_c := c.darkened(0.45)
	var dark := Color(0.16, 0.17, 0.2)
	# Beine, Rumpf, Arme, Kopf mit Visier, Waffe (vorne = −z)
	_part(_box(Vector3(0.18, 0.8, 0.22)), Vector3(-0.13, 0.4, 0), armor_c)
	_part(_box(Vector3(0.18, 0.8, 0.22)), Vector3(0.13, 0.4, 0), armor_c)
	_part(_box(Vector3(0.56, 0.62, 0.34)), Vector3(0, 1.1, 0), c)
	_part(_box(Vector3(0.6, 0.14, 0.38)), Vector3(0, 1.36, 0), c.darkened(0.2))
	_part(_box(Vector3(0.14, 0.52, 0.14)), Vector3(-0.36, 1.08, -0.08), c.darkened(0.15))
	_part(_box(Vector3(0.14, 0.52, 0.14)), Vector3(0.36, 1.08, -0.12), c.darkened(0.15))
	var head := SphereMesh.new()
	head.radius = 0.17
	head.height = 0.34
	_part(head, Vector3(0, 1.6, 0), dark)
	var visor := _part(_box(Vector3(0.24, 0.07, 0.06)), Vector3(0, 1.62, -0.15), c.lightened(0.3))
	_glow(visor, c.lightened(0.3), 1.5)
	_part(_box(Vector3(0.08, 0.11, 0.8)), Vector3(0.2, 1.18, -0.5), dark)
	_part(_box(Vector3(0.07, 0.16, 0.12)), Vector3(0.2, 1.08, -0.3), dark)
	# Leuchtender Teamring am Boden
	var torus := TorusMesh.new()
	torus.inner_radius = 0.44
	torus.outer_radius = 0.52
	ring = MeshInstance3D.new()
	ring.mesh = torus
	ring.position.y = 0.04
	ring.scale = Vector3(1, 0.3, 1)
	add_child(ring)
	_glow(ring, c, 2.0)
	# Namensschild
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(0, 2.25, 0)
	label.font_size = 40
	label.pixel_size = 0.012
	label.outline_size = 10
	label.modulate = c.lightened(0.35)
	add_child(label)
	# Kollision nur für Mausklicks (Ebene 2), nicht für Sichtlinien
	var body := StaticBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 0
	body.set_meta("unit", self)
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.9
	cs.shape = shape
	cs.position.y = 0.95
	body.add_child(cs)
	add_child(body)
	update_label()


func update_label() -> void:
	label.text = "%s\n%d/%d TP" % [unit_name, maxi(hp, 0), max_hp] if not dead else "%s\ntot" % unit_name


func face(target: Vector3) -> void:
	var p := target
	p.y = global_position.y
	if p.distance_to(global_position) > 0.05:
		model.look_at(p, Vector3.UP)


func die() -> void:
	dead = true
	update_label()
	ring.visible = false
	var tw := create_tween()
	tw.tween_property(model, "rotation:x", deg_to_rad(-88.0), 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(model, "position:y", 0.2, 0.5)


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _part(mesh: Mesh, pos: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.metallic = 0.2
	mi.material_override = m
	model.add_child(mi)
	return mi


func _glow(mi: MeshInstance3D, c: Color, energy: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	mi.material_override = m
