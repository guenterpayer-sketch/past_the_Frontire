class_name Hub
extends Node3D
## Schiff (Hub): zentrale Szene zwischen den Einsätzen. Zeigt das 3D-Deck (ShipView), verbindet die Räume
## mit den Modulen (Brücke → Sternenkarte → Bodenkampf, Crewquartiere → Charakterübersicht) und verwaltet
## Speichern/Laden. Der Spielstand liegt in HubState.game.

var game: HubState
var _hover: StringName = &""
var _mouse_drag := false
var _drag_moved := false
var _drag_accum := Vector2.ZERO
## nach dem Reisebericht ausführen (Einsatz beginnen), egal wie er geschlossen wird
var _after_travel := Callable()

@onready var ship: ShipView = $Ship
@onready var rig: CameraRig = $CameraRig
@onready var ui: HubUI = $UI/HubUI


func _ready() -> void:
	UiScale.apply(get_tree())
	if HubState.game == null:
		HubState.new_game(randi() % 1000000)
	game = HubState.game
	game.abort_mission()
	ui.action.connect(_on_action)
	ui.star_map.travel.connect(_travel)
	ui.star_map.wait_day.connect(wait_day)
	ui.medbay.wait_day.connect(wait_day)
	ui.armory.done.connect(_refresh)
	ui.star_map.hired.connect(func(_c: Character) -> void: _refresh())
	ui.star_map.start.connect(_start_mission)
	ui.star_map.bought.connect(_refresh)
	ui.star_map.crew_repair.connect(crew_repair)
	ui.travel_report.visibility_changed.connect(func() -> void:
		if not ui.travel_report.visible and _after_travel.is_valid():
			var next := _after_travel
			_after_travel = Callable()
			next.call())
	ui.star_map.closed.connect(_refresh)
	ui.crew.next_battle.connect(func() -> void:
		Campaign.save()
		ui.crew.hide()
		_refresh())
	ui.crew.crew_changed.connect(func() -> void: ui.relabel_crew.call_deferred())
	ui.slots.saved.connect(func(_s: int) -> void: _refresh())
	ui.slots.loaded.connect(func(s: int) -> void:
		if SaveSlots.load_slot(s):
			get_tree().reload_current_scene())
	var b := ShipView.bounds()
	rig.bounds = Rect2(b.position - Vector2(4, 4), b.size + Vector2(8, 8))
	rig.focus(Vector3(b.get_center().x, 0, b.get_center().y))
	rig.camera.size = 34.0
	rig.rotated.connect(func() -> void: ship.update_cutaway(rig.view_dir()))
	ship.update_cutaway.call_deferred(rig.view_dir())
	_refresh()
	if not game.report.is_empty():
		ui.show_report(game.report)
		game.report = {}
	var args := OS.get_cmdline_user_args()
	if "--autotest-hub" in args and not get_tree().root.has_node("HubAutotest"):
		var t: Node = load("res://tests/autotest_hub.gd").new()
		t.name = "HubAutotest"
		get_tree().root.add_child.call_deferred(t)


func _process(_d: float) -> void:
	var pts := {}
	for r in ShipView.ROOMS:
		pts[r.id] = rig.camera.unproject_position(ShipView.room_center(r.id) + Vector3(0, 2.6, 0))
	ui.place_tags(pts)


func _refresh() -> void:
	ui.set_status(game)
	ship.set_highlight(_hover)
	if ui.star_map.visible:
		ui.star_map.refresh()


# ---------------------------------------------------------------- Räume

func open_room(id: StringName) -> void:
	var r := ShipView.room(id)
	Sfx.play(&"klick")
	match id:
		&"bridge":
			ui.star_map.open(game)
		&"medbay":
			ui.medbay.show_medbay(game)
		&"armory":
			# Ausrüstungsdialog des Charakter-Moduls; „Fertig“ speichert selbst (Campaign.save())
			ui.armory.open_for(Campaign.crew(), 0)
		&"quarters":
			ui.show_crew()
		_:
			ui.show_notice(r.name, "%s\n\nDieser Bereich kommt noch." % r.text)


## Einen Tag warten (Brücke oder Krankenstation)
func wait_day() -> void:
	game.wait_days(1)
	_after_days()


## Nach vergangenen Tagen: offene Fenster neu zeichnen, Geheilte melden
func _after_days() -> void:
	_refresh()
	if ui.medbay.visible:
		ui.medbay.show_medbay(game)
	if not game.last_healed.is_empty():
		ui.show_toast("Wieder einsatzbereit: " + ", ".join(game.last_healed.map(func(c: Character) -> String: return c.name)))


func _travel(target: int) -> void:
	var days := game.travel_to(target)
	if days > 0:
		Sfx.play(&"schritt")
		ui.show_travel(game.last_travel)
	_after_days()


## Große Reparatur durch die Crew (1 Tag, 1 Material)
func crew_repair() -> void:
	var r := game.crew_repair()
	if r.is_empty():
		return
	Sfx.play(&"klick")
	_after_days()
	ui.show_notice("Große Reparatur", "%s: Reparatur %s %+d = %d → %s\nHülle %+d (jetzt %d / %d) · 1 Material verbraucht · +%d EP" % [
		r.name, Dice.format_roll(r.roll), r.bonus, r.total, r.result_name, r.hull, game.hull, Voyage.HULL_MAX, r.xp])
	ui.notice.move_to_front()


## Zum Auftrag: hinfliegen (Reisebericht), dann in den Bodenkampf
func _start_mission(offer: Dictionary) -> void:
	var day0 := game.day
	if not game.start_mission(offer):
		_refresh()
		return
	Campaign.save()
	Campaign.last_result = {}
	if game.day > day0:
		Sfx.play(&"schritt")
		_refresh()
		_after_travel = func() -> void: get_tree().change_scene_to_file(HubState.BATTLE_SCENE)
		ui.show_travel(game.last_travel)
		return
	get_tree().change_scene_to_file(HubState.BATTLE_SCENE)


func _set_hover(id: StringName) -> void:
	if id == _hover:
		return
	_hover = id
	ship.set_highlight(_hover)
	ui.show_room_info(ShipView.room(id) if id != &"" else {}, game)


func _on_action(name: StringName, arg: Variant) -> void:
	match name:
		&"room":
			open_room(arg)
		&"hover_room":
			_set_hover(arg)
		&"save":
			ui.slots.show_slots(&"save", true)
		&"load":
			ui.slots.show_slots(&"load", true)
		&"main_menu":
			get_tree().change_scene_to_file(HubState.START_SCENE)
		&"sound":
			Sfx.toggle()
		&"ui_scale":
			ui.show_ui_scale()
		&"help":
			ui.show_help()


# ---------------------------------------------------------------- Eingabe (Kamera wie im Bodenkampf)

func _room_under(p: Vector2) -> StringName:
	if ui.covers(p):
		return &""
	var hit: Variant = rig.ray_plane(p, 0.0)
	if hit == null:
		return &""
	var r := ShipView.room_at(Vector2(hit.x, hit.z))
	return r.id if not r.is_empty() else &""


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		if _mouse_drag and (e.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE)):
			_drag_accum += e.relative
			if _drag_moved or _drag_accum.length() > 6.0:
				_drag_moved = true
				rig.pan(e.relative)
		if not ui.any_dialog_open():
			_set_hover(_room_under(e.position))
	elif e is InputEventMouseButton:
		if ui.covers(e.position):
			return
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if e.pressed:
					rig.zoom_at(e.position, 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				if e.pressed:
					rig.zoom_at(e.position, 1 / 1.12)
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE:
				if e.pressed:
					_mouse_drag = true
					_drag_moved = false
					_drag_accum = Vector2.ZERO
				else:
					var was_drag := _drag_moved
					_mouse_drag = false
					_drag_moved = false
					if not was_drag and e.button_index == MOUSE_BUTTON_LEFT:
						var id := _room_under(e.position)
						if id != &"":
							open_room(id)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_ESCAPE:
				ui.close_dialogs()
			KEY_Q:
				rig.rotate_by(-90)
			KEY_E:
				rig.rotate_by(90)
			KEY_A, KEY_LEFT:
				rig.pan(Vector2(80, 0))
			KEY_D, KEY_RIGHT:
				rig.pan(Vector2(-80, 0))
			KEY_W, KEY_UP:
				rig.pan(Vector2(0, 80))
			KEY_S, KEY_DOWN:
				rig.pan(Vector2(0, -80))
