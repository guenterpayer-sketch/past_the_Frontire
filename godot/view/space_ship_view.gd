class_name SpaceShipView
extends Node3D
## Ein Schiff auf der Karte: 3D-Modell (passend skaliert), Schildring mit 6 Segmenten und Hüllenbalken darüber
## (Entscheidung des Nutzers: immer sichtbar, für alle Schiffe).

const MODELS := ["res://assets/ship/ship_imperial.glb", "res://assets/ship/dropship_insurgent.glb"]
## Länge des Modells in Metern je Klasse (Jäger, leicht, mittel, schwer)
const LENGTH := [1.9, 2.8, 3.4, 4.0]

var ship: SpaceShip
var _body: Node3D
var _ring: MeshInstance3D
var _bar: Label3D
var _name: Label3D
var _sel: MeshInstance3D


func setup(s: SpaceShip) -> void:
	ship = s
	_body = Node3D.new()
	add_child(_body)
	var path: String = MODELS[0] if s.side == &"crew" else MODELS[1]
	var model: Node3D = null
	if ResourceLoader.exists(path):
		model = (load(path) as PackedScene).instantiate()
	if model == null:
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(1.0, 0.4, 1.6)
		mi.mesh = pm
		model = mi
	_body.add_child(model)
	_fit(model, LENGTH[s.cls])
	if s.side == &"enemy":
		_tint(model, UiTheme.ENEMY)
	_ring = MeshInstance3D.new()
	_ring.position.y = 0.1
	add_child(_ring)
	_bar = Label3D.new()
	_bar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bar.font_size = 22
	_bar.pixel_size = 0.012
	_bar.outline_size = 8
	_bar.position = Vector3(0, 2.3, 0)
	_bar.no_depth_test = true
	add_child(_bar)
	_name = Label3D.new()
	_name.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name.font_size = 40
	_name.pixel_size = 0.014
	_name.outline_size = 8
	_name.position = Vector3(0, 1.8, 0)
	_name.no_depth_test = true
	_name.modulate = UiTheme.CREW if s.side == &"crew" else UiTheme.ENEMY
	_name.text = s.name
	add_child(_name)
	_sel = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 1.85
	t.outer_radius = 1.95
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = UiTheme.ACCENT
	t.material = m
	_sel.mesh = t
	_sel.visible = false
	add_child(_sel)
	refresh()
	place()


## Modell auf die gewünschte Länge bringen und mittig setzen (Bug zeigt nach −Z)
func _fit(model: Node3D, length: float) -> void:
	var box := _aabb(model, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		return
	var long := maxf(box.size.x, box.size.z)
	var k := length / maxf(long, 0.001)
	model.scale = Vector3.ONE * k
	model.position = -box.get_center() * k
	if box.size.x > box.size.z:
		model.rotation_degrees.y = 90.0
		model.position = Vector3(box.get_center().z, -box.get_center().y, -box.get_center().x) * k


func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _aabb(c, t)
		if b.size == Vector3.ZERO:
			continue
		out = b if first else out.merge(b)
		first = false
	return out


func _tint(n: Node, col: Color) -> void:
	if n is GeometryInstance3D:
		var m := StandardMaterial3D.new()
		m.albedo_color = col.darkened(0.35)
		m.metallic = 0.4
		m.roughness = 0.5
		(n as GeometryInstance3D).material_overlay = null
		(n as GeometryInstance3D).material_override = m
	for c in n.get_children():
		_tint(c, col)


func place() -> void:
	position = SpaceMapView.world(ship.pos, 0.6)
	_body.rotation.y = facing_yaw(ship.facing)


## Drehung um y, damit −Z in Richtung der Hexseite zeigt
static func facing_yaw(f: int) -> float:
	var d := Hex.dir_vector(f)
	return atan2(-d.x, -d.y) + PI   # Modelle zeigen mit dem Bug nach +Z (Rückmeldung des Nutzers)


func select(on: bool) -> void:
	_sel.visible = on


## Schildring und Hüllenbalken neu zeichnen
func refresh() -> void:
	visible = ship.is_present()
	_set_wreck(ship.wreck)
	var im := ImmediateMesh.new()
	var r: float = LENGTH[ship.cls] * 0.75 + 0.5
	if ship.shield_max > 0 and not ship.wreck:
		for i in 6:
			var v := float(ship.shields[i]) / ship.shield_max
			if v <= 0.0:
				continue
			var col := UiTheme.CREW if v > 0.6 else (UiTheme.ACCENT if v > 0.3 else UiTheme.BAD)
			col.a = 0.35 + 0.6 * v
			var m := StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = col
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, m)
			# Seite i (relativ zum Bug) liegt in Hexrichtung facing + i
			var center := rad_to_deg(atan2(Hex.dir_vector(ship.facing + i).y, Hex.dir_vector(ship.facing + i).x))
			for k in 9:
				var a := deg_to_rad(center - 26.0 + 52.0 * k / 8.0)
				var dir := Vector3(cos(a), 0, sin(a))
				im.surface_add_vertex(dir * (r - 0.12))
				im.surface_add_vertex(dir * (r + 0.12))
			im.surface_end()
	_ring.mesh = im if im.get_surface_count() > 0 else null
	var pct := float(ship.hull) / maxf(1.0, ship.hull_max)
	var n := 10
	var full := roundi(pct * n)
	_bar.text = "█".repeat(full) + "░".repeat(n - full)
	_bar.modulate = UiTheme.GOOD if pct > 0.5 else (UiTheme.ACCENT if pct > 0.25 else UiTheme.BAD)
	var warn := ""
	for sys in ship.damage:
		if Tables.SEVERITIES.find(String(ship.damage[sys])) >= 2:
			warn = " ⚠"
	_name.text = ship.name + (" (Wrack)" if ship.wreck else warn)


var _wreck_shown := false


## Wrack: grau, leicht gekippt
func _set_wreck(on: bool) -> void:
	if on == _wreck_shown:
		return
	_wreck_shown = on
	if on:
		_tint(_body, Color(0.45, 0.45, 0.45))
		_body.rotation.z = deg_to_rad(12.0)
