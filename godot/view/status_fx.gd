class_name StatusFx
extends Node3D
## Effekte an der Figur für Zustände (Entwurf: Artifact „Statuseffekte Bodenkampf“, 15.10.2026):
## Blutung = fallende Tropfen und Lache, benommen = kreisende Sterne, sterbend = rot pulsierender Fleck
## (stabilisiert: grün, ruhig), Psi-Schild = blaue Blase, Psi-Verstärkung = violetter Schimmerring.

var _head := 1.8
var _drops: CPUParticles3D
var _pool: MeshInstance3D
var _stars: Node3D
var _floor: MeshInstance3D
var _floor_mat: StandardMaterial3D
var _bubble: MeshInstance3D
var _bubble_mat: StandardMaterial3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _dying := false
var _t := 0.0


func setup(head: float) -> void:
	_head = head
	# Blutung: Tropfen fallen vom Oberkörper
	_drops = CPUParticles3D.new()
	_drops.emitting = false
	_drops.amount = 8
	_drops.lifetime = 0.7
	_drops.position.y = head * 0.6
	_drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_drops.emission_sphere_radius = 0.14
	_drops.direction = Vector3.DOWN
	_drops.spread = 15.0
	_drops.initial_velocity_min = 0.1
	_drops.initial_velocity_max = 0.4
	_drops.gravity = Vector3(0, -6, 0)
	var dm := SphereMesh.new()
	dm.radius = 0.028
	dm.height = 0.07
	dm.material = _flat(Color("e0453a"))
	_drops.mesh = dm
	add_child(_drops)
	_pool = _disc(0.26, _flat(Color(0.75, 0.12, 0.1, 0.55)), 0.025)
	# benommen: drei Sterne kreisen über dem Kopf
	_stars = Node3D.new()
	_stars.position.y = head + 0.12
	add_child(_stars)
	for i in 3:
		var s := Sprite3D.new()
		s.texture = StatusIcons.texture(&"star")
		s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		s.pixel_size = 0.13 / StatusIcons.SIZE
		s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var a := TAU * i / 3.0
		s.position = Vector3(cos(a) * 0.3, 0, sin(a) * 0.3)
		_stars.add_child(s)
	# sterbend / stabilisiert: Fleck am Boden
	_floor_mat = _flat(Color(1, 0.35, 0.3, 0.4))
	_floor = _disc(0.6, _floor_mat, 0.02)
	# Psi-Schild: durchscheinende Blase
	var sp := SphereMesh.new()
	sp.radius = 0.55
	sp.height = head + 0.45
	_bubble_mat = _flat(Color(0.44, 0.72, 1.0, 0.16))
	_bubble_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sp.material = _bubble_mat
	_bubble = MeshInstance3D.new()
	_bubble.mesh = sp
	_bubble.position.y = (head + 0.45) / 2.0
	_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bubble)
	# Psi-Verstärkung: violetter Ring außerhalb des Teamrings
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 0.65
	torus.rings = 32
	torus.ring_segments = 6
	_ring_mat = _flat(Color(0.7, 0.55, 1.0, 0.6))
	torus.material = _ring_mat
	_ring = MeshInstance3D.new()
	_ring.mesh = torus
	_ring.position.y = 0.05
	_ring.scale = Vector3(1, 0.3, 1)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	for n in [_pool, _stars, _floor, _bubble, _ring]:
		n.visible = false


## Effekte aus dem Zustand der Figur übernehmen
func sync(u: Combatant) -> void:
	var alive := not u.is_dead()
	_drops.emitting = alive and u.bleed > 0
	_drops.amount = clampi(4 + u.bleed * 2, 4, 16)
	_pool.visible = alive and u.bleed > 0
	_stars.visible = u.is_ok() and u.stun > 0
	_dying = u.state == Combatant.State.DYING and not u.stabilized
	_floor.visible = u.state == Combatant.State.DYING
	_floor_mat.albedo_color = Color(1, 0.3, 0.25, 0.4) if _dying else Color(0.37, 0.83, 0.54, 0.35)
	_bubble.visible = alive and u.psi_shield > 0
	_ring.visible = u.is_ok() and StatusIcons.has_buff(u)


func _process(delta: float) -> void:
	_t += delta
	if _stars.visible:
		_stars.rotation.y += delta * 2.6
	if _floor.visible and _dying:
		_floor_mat.albedo_color.a = 0.2 + 0.35 * (0.5 + 0.5 * sin(_t * 5.5))
	if _bubble.visible:
		_bubble_mat.albedo_color.a = 0.12 + 0.07 * sin(_t * 2.8)
	if _ring.visible:
		_ring_mat.albedo_color.a = 0.4 + 0.25 * sin(_t * 2.8)


func _flat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = c
	return m


func _disc(r: float, mat: StandardMaterial3D, y: float) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = 0.004
	c.radial_segments = 24
	c.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position.y = y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi
