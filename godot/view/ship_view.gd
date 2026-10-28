class_name ShipView
extends Node3D
## Das eigene Schiff als 3D-Deck (Hub). Aussehen (Boden, Wände, Einrichtung, Licht) kommt aus den
## im Editor gestaltbaren Szenen unter `ship/`; hier bleiben Raumgrenzen, Hervorhebung, Sterne und
## der Blick ins Innere (Außenwände zur Kamera hin werden niedrig gezeigt).

## Räume (Meter: x entlang des Schiffs, z quer). ready = schon nutzbar, sonst „kommt noch“.
const ROOMS := [
	{"id": &"hangar", "name": "Maschinenraum", "rect": Rect2(0, 0, 16, 8), "ready": true,
		"text": "Schiffsausbau: Plätze, Tank, Hülle, Antrieb, Systeme, Krankenstation, Training (Werft oder Crew)."},
	{"id": &"armory", "name": "Waffenkammer", "rect": Rect2(0, 8, 16, 8), "ready": true,
		"text": "Ausrüstung ändern: Waffen, Rüstung, Schild (Dialog des Charakter-Moduls)."},
	{"id": &"quarters", "name": "Crewquartiere", "rect": Rect2(16, 0, 12, 8), "ready": true,
		"text": "Crew ansehen: Ränge kaufen, Eigenschaften steigern, freie EP einzahlen, Charakterbögen."},
	{"id": &"medbay", "name": "Krankenstation", "rect": Rect2(16, 8, 12, 8), "ready": true,
		"text": "Verwundete und Resttage, Arzt und Helfer zuweisen (Zweite Hilfe), „1 Tag warten“."},
	{"id": &"bridge", "name": "Brücke", "rect": Rect2(28, 4, 12, 8), "ready": true,
		"text": "Sternenkarte des Sektors, offene Aufträge, Kurs setzen. Später: Raumkampf."},
	{"id": &"galley", "name": "Kombüse", "rect": Rect2(28, 12, 12, 4), "ready": true,
		"text": "Proviant und Kochen: Koch einstellen, Vorrat, Verbrauch je Tag, letzte Kochproben."},
]

## Gestaltung im Editor: je Raum `ship/rooms/<id>.tscn`, zusammengesetzt in `ship/ship.tscn`
const SCENE := "res://ship/ship.tscn"
## Andere Fassung zum Vergleichen (im Inspektor von hub.tscn umstellbar, nicht committen)
@export_file("*.tscn") var scene_path := SCENE

var _walls: Array[Dictionary] = []     # {full, low, normal}
var _highlights := {}                    # Raum-ID -> MeshInstance3D


func _ready() -> void:
	build()


func build() -> void:
	for c in get_children():
		c.queue_free()
	_walls.clear()
	_highlights.clear()
	var interior: Node3D = (load(scene_path) as PackedScene).instantiate()
	add_child(interior)
	_collect_cutaway(interior)
	_build_highlights()
	_build_stars()


## Raum an einer Stelle des Decks (x, z in Metern) oder {}
static func room_at(p: Vector2) -> Dictionary:
	for r in ROOMS:
		if (r.rect as Rect2).has_point(p):
			return r
	return {}


static func room(id: StringName) -> Dictionary:
	for r in ROOMS:
		if r.id == id:
			return r
	return {}


## Mittelpunkt eines Raums (Boden)
static func room_center(id: StringName) -> Vector3:
	var r: Rect2 = room(id).rect
	var c := r.get_center()
	return Vector3(c.x, 0, c.y)


static func bounds() -> Rect2:
	var b: Rect2 = ROOMS[0].rect
	for r in ROOMS:
		b = b.merge(r.rect)
	return b


func set_highlight(hover: StringName, selected: StringName = &"") -> void:
	for id in _highlights:
		var m: MeshInstance3D = _highlights[id]
		m.visible = id == hover or id == selected
		(m.material_override as StandardMaterial3D).albedo_color = Color(UiTheme.ACCENT, 0.22 if id == hover else 0.12)


## Außenwände zwischen Kamera und Raum niedrig zeigen
func update_cutaway(view_dir: Vector3) -> void:
	for w in _walls:
		var low: bool = (w.normal as Vector3).dot(view_dir) > 0.2
		w.full.visible = not low
		w.low.visible = low


# ---------------------------------------------------------------- Aufbau

## Außenwände aus der Szene: Knoten der Gruppe „cutaway“ mit Kindern „Voll“ und „Niedrig“.
## Richtung nach außen: Meta „cutaway_normal“ oder die Seite der Kante, auf der kein Raum liegt.
func _collect_cutaway(interior: Node) -> void:
	for n in interior.find_children("*", "Node3D", true, false):
		if not n.is_in_group(&"cutaway"):
			continue
		var full := n.get_node_or_null("Voll") as Node3D
		var low := n.get_node_or_null("Niedrig") as Node3D
		if full == null or low == null:
			continue
		var normal: Vector3 = n.get_meta(&"cutaway_normal", Vector3.ZERO)
		if normal == Vector3.ZERO:
			var p := (n as Node3D).global_position
			for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
				var q: Vector3 = p + d * 1.0
				if room_at(Vector2(q.x, q.z)).is_empty():
					normal = d
					break
		if normal == Vector3.ZERO:
			continue
		low.visible = false
		_walls.append({"full": full, "low": low, "normal": normal})


func _build_highlights() -> void:
	for r in ROOMS:
		var rect: Rect2 = r.rect
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = rect.size - Vector2(0.6, 0.6)
		m.mesh = pm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(UiTheme.ACCENT, 0.2)
		mat.no_depth_test = true
		m.material_override = mat
		m.position = Vector3(rect.get_center().x, 0.06, rect.get_center().y)
		m.visible = false
		add_child(m)
		_highlights[r.id] = m


## Sterne unter dem Deck (Weltraum im Hintergrund)
func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 6
	sm.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.65, 0.8)
	sm.material = mat
	mm.mesh = sm
	mm.instance_count = 700
	var c := bounds().get_center()
	for i in mm.instance_count:
		var p := Vector3(c.x + rng.randf_range(-140, 140), rng.randf_range(-60, -25), c.y + rng.randf_range(-140, 140))
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * rng.randf_range(0.4, 1.6)), p))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
