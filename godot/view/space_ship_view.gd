class_name SpaceShipView
extends Node3D
## Ein Schiff auf der Karte: 3D-Modell (passend skaliert), Schildring mit 6 Segmenten und Hüllenbalken darüber
## (Entscheidung des Nutzers: immer sichtbar, für alle Schiffe).

const OWN_MODEL := "res://assets/ship/ship_imperial.glb"
## Gegnermodelle je Klasse (Quaternius Ultimate Spaceships, rote Pack-Textur; Entscheidung des Nutzers 28.10.2026:
## keine Einfärbung mehr, je Fraktion ein festes Modell je Klasse, Elite/Boss in Lila)
const ENEMY_DIR := "res://assets/ship/space/"
const ENEMY_MODELS := [["striker", "spitfire", "dispatcher"], ["bob", "pancake", "challenger"],
	["insurgent", "executioner"], ["omen", "zenith"]]
## Feste Flotte je Seite (Jäger, leicht, mittel, schwer); fehlende Seiten wählen über eine Prüfsumme
const FLEETS := {
	"piraten": ["spitfire", "bob", "insurgent", "zenith"], "schmuggler": ["dispatcher", "pancake", "insurgent", "omen"],
	"aasgeier": ["striker", "bob", "executioner", "zenith"], "schwarze_flagge": ["spitfire", "challenger", "insurgent", "omen"],
	"konzern": ["dispatcher", "challenger", "executioner", "omen"], "semidrug": ["striker", "challenger", "executioner", "zenith"],
	"militaer": ["striker", "pancake", "executioner", "omen"], "rote_sonne": ["spitfire", "pancake", "insurgent", "zenith"],
	"eisenwoelfe": ["dispatcher", "bob", "executioner", "omen"], "kinder_der_glut": ["spitfire", "bob", "executioner", "omen"],
	"neuntes_haus": ["dispatcher", "challenger", "insurgent", "zenith"], "drohnen": ["striker", "pancake", "executioner", "zenith"],
	"leeres_licht": ["dispatcher", "pancake", "executioner", "zenith"],
}
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
	var key := enemy_model(s.faction, s.cls) if s.side == &"enemy" else ""
	var path: String = OWN_MODEL if key == "" else ENEMY_DIR + key + ".glb"
	var model: Node3D = null
	if ResourceLoader.exists(path):
		model = (load(path) as PackedScene).instantiate()
		if s.elite and ResourceLoader.exists(ENEMY_DIR + key + "_lila.png"):
			_retexture(model, load(ENEMY_DIR + key + "_lila.png"))
	if model == null:
		var mi := MeshInstance3D.new()
		var pm := PrismMesh.new()
		pm.size = Vector3(1.0, 0.4, 1.6)
		mi.mesh = pm
		model = mi
	_body.add_child(model)
	_fit(model, LENGTH[s.cls])
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
	_name.modulate = UiTheme.CREW if s.side == &"crew" else (UiTheme.ACCENT if s.elite else UiTheme.ENEMY)
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


## Modell auf die gewünschte Größe bringen und mittig setzen (Bug zeigt nach −Z; die Quaternius-Schiffe liegen
## alle entlang Z, breite Schiffe werden nicht gedreht)
func _fit(model: Node3D, length: float) -> void:
	var box := _aabb(model, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		return
	var long := maxf(box.size.x, box.size.z)
	var k := length / maxf(long, 0.001)
	model.scale = Vector3.ONE * k
	model.position = -box.get_center() * k


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


## Modell eines Gegners: je Fraktion und Klasse fest (gleiche Fraktion = gleiche „Flotte“)
static func enemy_model(faction: String, cls: int) -> String:
	cls = clampi(cls, 0, ENEMY_MODELS.size() - 1)
	if FLEETS.has(faction):
		return String(FLEETS[faction][cls])
	var pool: Array = ENEMY_MODELS[cls]
	return String(pool[absi(hash("%s:%d" % [faction, cls])) % pool.size()])


## Abdunkeln ohne Einfärben: Farbtextur bleibt, nur mit einem Grauton multipliziert
func _darken(n: Node, col: Color) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			var m := mi.get_surface_override_material(si)
			if m == null:
				m = mi.mesh.surface_get_material(si)
			if m is StandardMaterial3D:
				var d := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				d.albedo_color = col
				mi.set_surface_override_material(si, d)
	for c in n.get_children():
		_darken(c, col)


## Andere Pack-Farbe (z. B. Lila für Elite): Material behalten, nur die Farbtextur tauschen
func _retexture(n: Node, tex: Texture2D) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var mi := n as MeshInstance3D
		for si in mi.mesh.get_surface_count():
			var m := mi.mesh.surface_get_material(si)
			if m is StandardMaterial3D:
				var d := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				d.albedo_texture = tex
				mi.set_surface_override_material(si, d)
	for c in n.get_children():
		_retexture(c, tex)


func place() -> void:
	position = SpaceMapView.world(ship.pos, 0.6)
	_body.rotation.y = facing_yaw(ship.facing)


## Drehung um y, damit −Z in Richtung der Hexseite zeigt
static func facing_yaw(f: int) -> float:
	var d := Hex.dir_vector(f)
	return atan2(-d.x, -d.y) + PI   # Modelle zeigen mit dem Bug nach +Z (Rückmeldung des Nutzers)


func select(on: bool) -> void:
	_sel.visible = on


## Voller Zustand sichtbar: eigenes Schiff oder Gegner mit gültigem Scan
func _clear() -> bool:
	return ship.side == &"crew" or ship.scan_live


## Schildring und Hüllenbalken neu zeichnen (Gegner ohne Scan nur grob)
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
			if not _clear():
				v = 0.7  # Gegner ohne Scan: nur Schild da / nicht da
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
	if _clear():
		var n := 10
		var full := roundi(pct * n)
		_bar.text = "█".repeat(full) + "░".repeat(n - full)
		_bar.modulate = UiTheme.GOOD if pct > 0.5 else (UiTheme.ACCENT if pct > 0.25 else UiTheme.BAD)
	else:
		var stage := ship.hull_stage()
		var parts := PackedStringArray()
		for i in 3:
			parts.append("███" if i <= stage else "░░░")
		_bar.text = " ".join(parts)
		_bar.modulate = [UiTheme.BAD, UiTheme.ACCENT, UiTheme.GOOD][stage]
	var warn := ""
	var seen := ship.seen_damage()
	for sys in seen:
		if Tables.SEVERITIES.find(String(seen[sys])) >= 2:
			warn = " ⚠"
	_name.text = ("★★ Boss: " if ship.boss else ("★ " if ship.elite else "")) + ship.name + (" (Wrack)" if ship.wreck else warn)


var _wreck_shown := false


## Wrack: abgedunkelt (Textur bleibt sichtbar), leicht gekippt
func _set_wreck(on: bool) -> void:
	if on == _wreck_shown:
		return
	_wreck_shown = on
	if on:
		_darken(_body, Color(0.4, 0.4, 0.42))
		_body.rotation.z = deg_to_rad(12.0)
