class_name FigurePreview
extends SubViewportContainer
## 3D-Vorschau einer Figur (Modell aus Character.visual mit Waffe), dreht sich langsam.

const TURN_SPEED := 0.35

var _viewport: SubViewport
var _pivot: Node3D
var _key := ""
var _pending: Character


func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(200, 270)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(_viewport)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101624")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.78)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	_viewport.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	sun.light_energy = 1.1
	_viewport.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 32
	cam.position = Vector3(0, 1.15, 4.6)
	cam.rotation_degrees.x = -5
	_viewport.add_child(cam)
	_pivot = Node3D.new()
	_viewport.add_child(_pivot)


func _process(delta: float) -> void:
	if _pending:
		var ch := _pending
		_pending = null
		_build(ch)
	if is_visible_in_tree():
		_pivot.rotate_y(delta * TURN_SPEED)


## Figur anzeigen; baut das Modell nur neu, wenn sich Aussehen, Waffe, Schild oder Farbe geändert haben
## (aufgebaut wird im nächsten Frame, wenn die Vorschau sicher im Baum ist)
func show_character(ch: Character) -> void:
	_pending = ch


func _build(ch: Character) -> void:
	var key := "%s|%s|%s|%s" % [ch.visual.resource_path if ch.visual else "", ch.weapons[0].resource_path if not ch.weapons.is_empty() else "", ch.shield, ch.color.to_html()]
	if key == _key:
		return
	_key = key
	for c in _pivot.get_children():
		c.queue_free()
	if ch.weapons.is_empty():
		return
	var u := Combatant.from_character(ch, &"crew")
	var f: Figure = ModelFigure.new() if u.visual and u.visual.model else ProceduralFigure.new()
	_pivot.add_child(f)
	f.setup(u)
	f.rotation.y = PI   # Vorderseite (−z) zur Kamera


## Alle Aussehen-Vorlagen (data/visuals/characters), nach Dateiname sortiert
static func visual_choices() -> Array[CharacterVisual]:
	var out: Array[CharacterVisual] = []
	var dir := "res://data/visuals/characters"
	var files := Array(ResourceLoader.list_directory(dir))
	files.sort()
	for f in files:
		if f.ends_with(".tres"):
			out.append(load(dir.path_join(f)))
	return out


static func visual_name(v: CharacterVisual) -> String:
	return v.resource_path.get_file().get_basename().replace("_", " ") if v else "Grundkörper"
