class_name StartScreen
extends Node3D
## Startmenü: Fortsetzen (zuletzt gespeicherter Slot), Neues Spiel, Laden, Schnellkampf (Bodenkampf ohne Schiff), Schnellkampf im All,
## Einstellungen, Beenden. Im Hintergrund dreht sich das Schiff der Crew.
## --autotest / --autotest-player / --autotest-psi / --autotest-maps springen direkt in den Bodenkampf, --autotest-hub ins Schiff.

const SHIP_MODEL := "res://assets/ship/ship_imperial.glb"

var slots: SlotsDialog
var picker: CrewPicker
var _pending_slot := 0
var _pending_name := ""
var settings: Modal
var gear: GearEditor
var _ship: Node3D
var _menu: VBoxContainer


func _ready() -> void:
	UiScale.apply(get_tree())
	HubState.quick_battle = false
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args or "--autotest-player" in args or "--autotest-psi" in args or "--autotest-maps" in args:
		HubState.game = null
		get_tree().change_scene_to_file.call_deferred(HubState.BATTLE_SCENE)
		return
	if "--autotest-hub" in args and not get_tree().root.has_node("HubAutotest"):
		var t: Node = load("res://tests/autotest_hub.gd").new()
		t.name = "HubAutotest"
		get_tree().root.add_child.call_deferred(t)
	_build_scene()
	Music.play(Music.START)
	_build_ui()


func _process(delta: float) -> void:
	if _ship:
		_ship.rotation.y += delta * 0.12


func _build_scene() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = UiTheme.BG
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.55, 0.7)
	env.environment.ambient_light_energy = 0.5
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -40, 0)
	sun.light_energy = 1.3
	add_child(sun)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-10, 150, 0)
	rim.light_energy = 0.6
	rim.light_color = Color(0.5, 0.7, 1.0)
	add_child(rim)
	var cam := Camera3D.new()
	cam.position = Vector3(-9, 7, 24)
	cam.fov = 40
	add_child(cam)
	cam.look_at(Vector3(-9, 0, 0))
	_ship = Node3D.new()
	_ship.position = Vector3(-2, -1.5, -7)
	add_child(_ship)
	if ResourceLoader.exists(SHIP_MODEL):
		var m: Node3D = (load(SHIP_MODEL) as PackedScene).instantiate()
		m.scale = Vector3.ONE * 0.9
		_ship.add_child(m)
	_ship.rotation_degrees = Vector3(8, 60, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 160:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = rng.randf_range(0.03, 0.09)
		sm.height = sm.radius * 2
		sm.radial_segments = 6
		sm.rings = 3
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.8, 0.85, 1.0, rng.randf_range(0.4, 1.0))
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.material = mat
		s.mesh = sm
		s.position = Vector3(rng.randf_range(-60, 40), rng.randf_range(-25, 30), rng.randf_range(-40, -15))
		add_child(s)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.theme = UiTheme.build()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 10)
	_menu.position = Vector2(60, 40)
	_menu.custom_minimum_size.x = 460
	root.add_child(_menu)
	var title := UiTheme.label("PAST THE FRONTIRE", 64, UiTheme.ACCENT)
	_menu.add_child(title)
	_menu.add_child(UiTheme.label("Rundenbasiertes Weltraum-Rollenspiel", 16, UiTheme.MUTED))
	var gap := Control.new()
	gap.custom_minimum_size.y = 26
	_menu.add_child(gap)
	var last := SaveSlots.latest()
	if last > 0:
		var i := SaveSlots.info(last)
		var cont := _item("Fortsetzen   ·   %s, Tag %d" % [i.name, i.day], true)
		cont.pressed.connect(func() -> void: _load(last))
	_item("Neues Spiel").pressed.connect(func() -> void: slots.show_slots(&"new"))
	var load_b := _item("Laden")
	load_b.disabled = last == 0
	load_b.pressed.connect(func() -> void: slots.show_slots(&"load"))
	var roster := _item("Roster")
	roster.tooltip_text = "Alle Figuren (Startcharaktere und selbst erschaffene), unabhängig von den Spielständen"
	roster.pressed.connect(func() -> void: get_tree().change_scene_to_file(Campaign.ROSTER_SCENE))
	var gear_b := _item("Ausrüstung")
	gear_b.tooltip_text = "Eigene Waffen und Rüstungen erstellen, bearbeiten, löschen (für alle Spielstände)"
	gear_b.pressed.connect(func() -> void: gear.show_editor())
	var quick := _item("Schnellkampf (Bodenkampf ohne Schiff)")
	quick.tooltip_text = "Einzelner Bodenkampf mit zufälliger Mission und Figuren aus dem Roster (Trupp im Briefing wählen). Nichts wird verbucht, danach zurück ins Startmenü."
	quick.pressed.connect(start_quick_battle)
	var space := _item("Schnellkampf im All (Raumkampf ohne Schiff)")
	space.tooltip_text = "Einzelner Raumkampf mit festen Testwerten (Startschiff gegen Piraten, Crew aus dem Roster). Nichts wird verbucht, danach zurück ins Startmenü."
	space.pressed.connect(start_space_quick)
	_item("Einstellungen").pressed.connect(_show_settings)
	var quit := _item("Beenden")
	quit.add_theme_color_override("font_color", UiTheme.MUTED)
	quit.pressed.connect(func() -> void: get_tree().quit())
	if last > 0:
		_menu.add_child(UiTheme.label("„Fortsetzen“ lädt den zuletzt gespeicherten Spielstand.", 13, UiTheme.MUTED))
	# Burgermenü oben rechts: Enzyklopädie, Einstellungen
	var burger := MenuButton.new()
	burger.text = "☰"
	burger.tooltip_text = "Menü"
	burger.flat = false
	burger.add_theme_font_size_override("font_size", 22)
	burger.custom_minimum_size = Vector2(48, 44)
	burger.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	burger.position = Vector2(-64, 16)
	root.add_child(burger)
	var pop := burger.get_popup()
	pop.add_item("Enzyklopädie", 0)
	pop.add_item("Einstellungen …", 1)
	pop.id_pressed.connect(func(id: int) -> void:
		if id == 0:
			Encyclopedia.show_on(root)
		else:
			_show_settings())
	slots = SlotsDialog.new()
	root.add_child(slots)
	gear = GearEditor.new()
	root.add_child(gear)
	slots.loaded.connect(_load)
	slots.new_game.connect(_new_game)
	picker = CrewPicker.new()
	root.add_child(picker)
	picker.picked.connect(_crew_picked)
	settings = Modal.new()
	root.add_child(settings)
	settings.max_size = Vector2(620, 340)


func _item(text: String, primary := false) -> Button:
	var b := UiTheme.button(text)
	b.custom_minimum_size = Vector2(460, 54)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 20)
	if primary:
		b.add_theme_stylebox_override("normal", UiTheme.box(Color("3a3215"), UiTheme.ACCENT, 6, 14))
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
	else:
		b.add_theme_stylebox_override("normal", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 6, 14))
	b.add_theme_stylebox_override("hover", UiTheme.box(UiTheme.PANEL2.lightened(0.08), UiTheme.MUTED, 6, 14))
	_menu.add_child(b)
	return b


func _load(slot: int) -> void:
	if SaveSlots.load_slot(slot):
		get_tree().change_scene_to_file(HubState.HUB_SCENE)


## Neues Spiel: nach Slot und Name die Crew aus dem Roster wählen (CrewPicker des Charakter-Moduls)
func _new_game(slot: int, name: String) -> void:
	_pending_slot = slot
	_pending_name = name
	picker.open_pick("Spielstand %s · Slot %d" % [name, slot], HubState.BERTHS_START)


func _crew_picked(chars: Array[Character]) -> void:
	start_new_game(_pending_slot, _pending_name, chars)


## Neues Spiel mit gewählter Crew beginnen, sofort speichern und ins Schiff
func start_new_game(slot: int, name: String, chars: Array[Character]) -> void:
	Campaign.new_game(chars)
	var g := HubState.new_game(randi() % 1000000, name, slot)
	SaveSlots.save(slot, name, g)
	get_tree().change_scene_to_file(HubState.HUB_SCENE)


## Schnellkampf: Figuren aus dem globalen Roster (Truppwahl im Briefing des Bodenkampfs), nichts wird verbucht.
## Die Crew-Arbeitskopie (user://crew.json) wird dabei durch die Roster-Figuren ersetzt; Spielstände bleiben unberührt.
func start_quick_battle() -> void:
	HubState.game = null
	HubState.quick_battle = true
	Campaign.new_game(GlobalRoster.entries())
	get_tree().change_scene_to_file(HubState.BATTLE_SCENE)


## Schnellkampf im All: feste Testwerte des Raumkampfs (SpaceSetup.quick), nichts wird verbucht, zurück ins Startmenü
func start_space_quick() -> void:
	HubState.game = null
	SpaceBattle.start(get_tree(), SpaceSetup.quick())


func _show_settings() -> void:
	settings.open("Einstellungen")
	for spec in [["Ton", Sfx.enabled, func(on: bool) -> void:
			if on != Sfx.enabled:
				Sfx.toggle()],
			["Würfelanimation im Kampf", Prefs.get_bool("dice", true), func(on: bool) -> void: Prefs.set_bool("dice", on)]]:
		var c := CheckButton.new()
		c.text = spec[0]
		c.button_pressed = spec[1]
		c.toggled.connect(spec[2])
		settings.content.add_child(c)
	settings.content.add_child(UiScale.picker(get_tree()))
	settings.content.add_child(Music.volume_rows())
	settings.add_close()
