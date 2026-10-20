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
## Touch (Hub Auftrag 6): Finger, Zwei-Finger-Geste ("" offen, "zoom" oder "rotate"), Abstand und Winkel beim letzten Schritt
var _touches := {}
var _touch_moved := false
var _gesture := ""
var _pinch_dist := 0.0
var _pinch_angle := 0.0
var _pinch_d0 := 0.0
var _twist := 0.0
## Zwei-Finger-Geste: ab diesem Abstandsverhältnis (log) zoomen, ab diesem Winkel (rad) drehen; Drehschritt ab TWIST_STEP
const PINCH_START := 0.12
const TWIST_START := 0.26
const TWIST_STEP := 0.6
## nach dem Reisebericht ausführen (Einsatz beginnen), egal wie er geschlossen wird
var _after_travel := Callable()

@onready var ship: ShipView = $Ship
@onready var rig: CameraRig = $CameraRig
@onready var ui: HubUI = $UI/HubUI


func _ready() -> void:
	UiScale.apply(get_tree())
	Music.play(Music.SHIP)
	if HubState.game == null:
		HubState.new_game(randi() % 1000000)
	game = HubState.game
	game.abort_mission()
	if game.boarding_active():
		# Entern/Abwehr lässt sich nicht absagen: zurück in den Bodenkampf
		get_tree().change_scene_to_file.call_deferred(HubState.BATTLE_SCENE)
		return
	# Rückkehr aus dem Raumkampf: Ergebnis auswerten (Bericht nach dem Aufbau der Szene)
	var space_result := SpaceBattle.take_result()
	var space_next := ""
	var from_space := not space_result.is_empty() and not game.space_ctx.is_empty()
	if from_space:
		space_next = game.finish_space(space_result)
		Campaign.save()
	ui.action.connect(_on_action)
	ui.star_map.travel.connect(_travel)
	ui.star_map.wait_day.connect(wait_day)
	ui.medbay.wait_day.connect(wait_day)
	ui.galley.wait_day.connect(wait_day)
	ui.galley.changed.connect(_refresh)
	ui.armory.done.connect(_refresh)
	ui.port.hired.connect(func(_c: Character) -> void: _refresh())
	ui.port.changed.connect(_refresh)
	ui.star_map.start.connect(_start_mission)
	ui.engine.changed.connect(_refresh)
	ui.trade.changed.connect(_refresh)
	ui.craft.changed.connect(_refresh)
	ui.ship_arms.changed.connect(_refresh)
	ui.medbay.changed.connect(_refresh)
	ui.loot_taken.connect(func(r: Dictionary) -> void:
		_refresh()
		if int(r.taken) + int(r.scrapped) > 0:
			ui.show_toast("Beute: %d Stück ins Lager, %d als Schrott (+%d Cr)" % [r.taken, r.scrapped, r.scrap]))
	ui.star_map.port.connect(_open_port)
	ui.star_map.story_chain.connect(_show_story)
	ui.star_map.story_mission.connect(_start_story_mission)
	ui.star_map.logbook.connect(_show_logbook)
	ui.star_map.jump_gate.connect(_jump)
	ui.star_map.place_action.connect(_place_action)
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
	ui.contact_choice.connect(_on_contact)
	# jedes geschlossene Fenster: vorgemerkte Szene prüfen (Hub Auftrag 8)
	for c in ui.get_children():
		if c is Modal:
			var m := c as Modal
			m.visibility_changed.connect(func() -> void:
				if not m.visible:
					_story_to_front.call_deferred()
					_next_story())
	ui.report.visibility_changed.connect(func() -> void:
		if not ui.report.visible:
			_continue_journey.call_deferred())
	_refresh()
	if from_space:
		ui.space_report_closed.connect(func() -> void: _after_space(space_next), CONNECT_ONE_SHOT)
		ui.show_space_report(game.space_report)
		game.space_report = {}
	elif not game.space_report.is_empty():
		# Abwehr abgebrochen (Notfall)
		ui.show_space_report(game.space_report)
		game.space_report = {}
	elif not game.report.is_empty():
		SaveSlots.autosave(game)   # nach dem Bodenkampf (Hub Auftrag 8)
		ui.show_report(game.report)
		game.report = {}
	elif not game.loot_pending.is_empty():
		ui.show_loot(game)
	elif not game.contact.is_empty():
		_after_leg.call_deferred()
	var args := OS.get_cmdline_user_args()
	if "--autotest-hub" in args and not get_tree().root.has_node("HubAutotest"):
		var t: Node = load("res://tests/autotest_hub.gd").new()
		t.name = "HubAutotest"
		get_tree().root.add_child.call_deferred(t)
	if "--autotest-hub-touch" in args and not get_tree().root.has_node("TouchAutotest"):
		var tt: Node = load("res://tests/autotest_touch.gd").new()
		tt.name = "TouchAutotest"
		get_tree().root.add_child.call_deferred(tt)


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
	_next_story.call_deferred()


# ---------------------------------------------------------------- Story (Auftrag 1, 19.10.2026)

## Nächstes vorgemerktes Szenenfenster zeigen, sobald kein anderes Fenster mehr offen ist (Hub Auftrag 8).
## Geprüft wird erst im nächsten Bild: Beim Schließen eines Fensters öffnet ein verzögerter Aufruf oft gleich das
## nächste (Bericht → Reisebericht). Früher kam das Szenenfenster dazwischen und lag dann unter dem Reisebericht,
## der es per move_to_front verdeckte (Hänger nach Entern-Sieg auf der Reise).
var _story_wait := false


func _next_story() -> void:
	if _story_wait:
		return
	_story_wait = true
	await get_tree().process_frame
	_story_wait = false
	if not is_inside_tree():
		return
	if game.story_queue.is_empty() or not game.active.is_empty() or _story_blocked():
		return
	_show_story(game.story_queue.pop_front())


## Offenes Szenenfenster wieder nach oben holen, wenn sich ein anderes Fenster schließt (Hub Auftrag 8): so liegt nie
## ein anderes Fenster darüber, außer es wurde aus der Szene geöffnet (Logbuch, Enzyklopädie) und ist noch offen.
func _story_to_front() -> void:
	var d := ui.get_node_or_null(StoryDialog.NAME) as StoryDialog
	if d == null or not d.visible:
		return
	var lg := ui.get_node_or_null(StoryLog.NAME) as Control
	var enc := ui.get_node_or_null(Encyclopedia.NAME) as Control
	if (lg and lg.visible) or (enc and enc.visible):
		return
	d.move_to_front()


## Szenenfenster mit Esc / Android-Zurück schließen (Entscheidung des Nutzers 20.10.2026): die Szene bleibt offen und
## lässt sich auf der Brücke (Sternenkarte, Abschnitt STORY, „Fortsetzen“) wieder öffnen. true = war offen.
func _pause_story() -> bool:
	var d := ui.get_node_or_null(StoryDialog.NAME) as StoryDialog
	if d == null or not d.visible:
		return false
	for n in [StoryLog.NAME, Encyclopedia.NAME]:
		var o := ui.get_node_or_null(n) as Control
		if o and o.visible:
			return false   # erst Logbuch/Enzyklopädie schließen (close_dialogs)
	d.hide()
	ui.show_toast("Szene pausiert: auf der Brücke unter STORY „Fortsetzen“")
	_refresh()
	return true


## Liegt ein Fenster offen (außer der Sternenkarte, über der Szenen erscheinen dürfen)?
func _story_blocked() -> bool:
	return ui.any_dialog_open(true)


## Szenenfenster einer Kette (schon begonnen); danach Karte auffrischen und das nächste zeigen
func _show_story(chain: String) -> void:
	var d := StoryDialog.show_on(ui, game.story_engine(), chain)
	if not d.visible:
		_refresh()
		return
	d.move_to_front()
	if not d.finished.is_connected(_story_finished):
		d.finished.connect(_story_finished)


func _story_finished(_chain: String) -> void:
	Campaign.save()
	SaveSlots.autosave(game)   # nach jedem abgeschlossenen Story-Fenster (Hub Auftrag 8)
	_refresh()


## Story-Einsatz von der Brücke: Bodenkampf (Briefing mit Truppwahl) oder Raumkampf
func _start_story_mission() -> void:
	match game.start_story_mission():
		"ground":
			Campaign.save()
			Campaign.last_result = {}
			get_tree().change_scene_to_file(HubState.BATTLE_SCENE)
		"space":
			_go_space()


func _show_logbook() -> void:
	StoryLog.show_on(ui, game.story_engine())


# ---------------------------------------------------------------- Räume

func open_room(id: StringName) -> void:
	var r := ShipView.room(id)
	Sfx.play(&"klick")
	match id:
		&"bridge":
			ui.star_map.open(game)
		&"medbay":
			ui.medbay.show_medbay(game)
		&"galley":
			ui.galley.show_galley(game)
		&"hangar":
			# Auswahl: Schiffsausbau, Waffenslots und Posten, Systemschäden (Raumkampf, ShipArms)
			var n := ShipArms.damage_count(game)
			ui.show_choice(r.name, "Schiff ausbauen, Schiffswaffen ein- und ausbauen, Geschützposten verteilen oder Schäden reparieren.", [
				["Schiffsausbau", func() -> void: ui.engine.show_engine(game)],
				["Waffenslots und Posten", func() -> void: ui.ship_arms.show_slots(game)],
				["Systemschäden" + (" (%d)" % n if n > 0 else ""), func() -> void: ui.ship_arms.show_damage(game)]])
		&"armory":
			# Auswahl: Ausrüstungsdialog des Charakter-Moduls („Fertig“ speichert selbst) oder Werkstatt (Handwerk)
			ui.show_choice(r.name, "Ausrüstung der Crew wechseln oder in der Werkstatt bauen, zerlegen und reparieren.", [
				["Ausrüstung", func() -> void: ui.armory.open_for(Campaign.crew(), 0)],
				["Werkstatt", func() -> void: ui.craft.show_craft(game)]])
		&"quarters":
			ui.show_crew()
		_:
			ui.show_notice(r.name, "%s\n\nDieser Bereich kommt noch." % r.text)


## Raumhafen: eigenes Fenster über der Sternenkarte (Schiffshändler, Händler, Werft, Crew anheuern)
func _open_port(kind: StringName) -> void:
	Sfx.play(&"klick")
	var d: Modal = ui.port
	match kind:
		&"ship":
			ui.port.show_ship(game)
		&"trade":
			ui.trade.show_trade(game)
			d = ui.trade
		&"yard":
			ui.ship_arms.show_yard(game)
			d = ui.ship_arms
		&"hire":
			ui.port.show_hire(game)
	d.move_to_front()


## Sprung durch ein Tor (Auftrag 2): Gebühr, 1 Tag, neuer Sektor
func _jump(gate: Dictionary) -> void:
	if not game.jump(gate):
		_refresh()
		return
	Sfx.play(&"schritt")
	ui.star_map.selected = game.position
	ui.star_map.selected_gate = -1
	_after_days()
	ui.show_toast("Sprung nach %s" % game.sector.name)
	_training_toast()


## Funktion an einem Ort: Bergung am Wrack, Treibstoff schöpfen (je 1 Tag, Meldung wie Werkstatt-Einträge)
func _place_action(action: StringName, index: int) -> void:
	if action == &"visit":
		var chain := game.visit_place(index)
		if chain == "":
			ui.show_toast("%s angeflogen: nichts Besonderes." % String(Places.place(game, index).get("name", "Ort")))
			_refresh()
		else:
			_show_story(chain)
		return
	var e := Places.salvage(game, index) if action == &"salvage" else Places.skim(game, index)
	if e.is_empty():
		_refresh()
		return
	Sfx.play(&"wuerfel")
	e.label = "Bergung" if action == &"salvage" else "Treibstoff"
	_after_days()
	var crafts: Array = [e]
	crafts.append_array(game.last_crafts)
	ui.show_events(game.last_upgrade, crafts)


## Einen Tag warten (Brücke oder Krankenstation)
func wait_day() -> void:
	game.wait_days(1)
	_after_days()
	_training_toast()


## Trainingstag beim Warten oder bei der großen Reparatur melden (Reise und Einsatz zeigen es im Bericht)
func _training_toast() -> void:
	if game.last_training > 0:
		ui.show_toast("Training: +%d freie EP für alle an Bord" % game.last_training)
	if not game.last_upgrade.is_empty() or not game.last_crafts.is_empty():
		ui.show_events(game.last_upgrade, game.last_crafts)


## Nach vergangenen Tagen: offene Fenster neu zeichnen, Geheilte melden
func _after_days() -> void:
	_refresh()
	if ui.medbay.visible:
		ui.medbay.show_medbay(game)
	if ui.craft.visible:
		ui.craft.refresh()
	ui.galley.refresh()
	if not game.last_healed.is_empty():
		ui.show_toast("Wieder einsatzbereit: " + ", ".join(game.last_healed.map(func(c: Character) -> String: return c.name)))


func _travel(target: int) -> void:
	game.pending_offer = -1
	var days := game.travel_to(target)
	if days > 0:
		SaveSlots.autosave(game)   # nach der Reise (Hub Auftrag 8)
		Sfx.play(&"schritt")
		_after_travel = _after_leg
		ui.show_travel(game.last_travel)
	_after_days()


# ---------------------------------------------------------------- Raumkampf im Spiel (SpaceEvents)

## Nach einer Reiseetappe: Feindkontakt (Wahl bzw. Eskorte sofort Kampf) oder vorgemerkten Auftrag beginnen
func _after_leg() -> void:
	if not game.contact.is_empty():
		if game.contact.get("forced", false):
			game.fight_contact()
			_go_space()
		else:
			ui.show_contact(game)
		return
	if game.pending_offer < 0:
		return
	match game.begin_offer():
		"ground":
			get_tree().change_scene_to_file(HubState.BATTLE_SCENE)
		"space":
			_go_space()
		"escort":
			_refresh()
			_after_travel = _after_leg
			ui.show_travel(game.last_travel)


## Feindkontakt: kämpfen oder ausweichen (Probe Navigation; misslingt sie, Kampf)
func _on_contact(fight: bool) -> void:
	if fight:
		game.fight_contact()
		_go_space()
		return
	var r := game.dodge_contact()
	Sfx.play(&"wuerfel")
	ui.show_toast("Ausweichen: %s %d → %s" % [r.name, int(r.total), "ausgewichen" if r.dodged else "misslungen, Raumkampf"])
	if r.dodged:
		_continue_journey()
	else:
		_go_space.call_deferred()


func _go_space() -> void:
	Campaign.save()
	SpaceBattle.start(get_tree(), game.space_setup())


## Nach dem Bericht des Raumkampfs: Bodenkampf (Blockade, Entern, Abwehr) oder Reise fortsetzen
func _after_space(next: String) -> void:
	match next:
		"ground", "defend":
			get_tree().change_scene_to_file(HubState.BATTLE_SCENE)
		"board":
			game.start_boarding()
			get_tree().change_scene_to_file(HubState.BATTLE_SCENE)
		_:
			SaveSlots.autosave(game)   # nach dem Raumkampf (Hub Auftrag 8)
			_continue_journey()


## Unterbrochene Reise fortsetzen (Rest-Tage), danach ggf. den vorgemerkten Auftrag beginnen
func _continue_journey() -> void:
	if not game.active.is_empty() or not game.contact.is_empty():
		return
	if not game.travel_rest.is_empty() and not game.stranded():
		game.resume_travel()
		SaveSlots.autosave(game)   # nach der Reise (Hub Auftrag 8)
		_refresh()
		_after_days()
		_after_travel = _after_leg
		ui.show_travel(game.last_travel)
	elif game.pending_offer >= 0:
		_after_leg()
	_refresh()


## Zum Auftrag: hinfliegen (Reisebericht), dann in den Bodenkampf
func _start_mission(offer: Dictionary) -> void:
	var day0 := game.day
	if not game.start_mission(offer):
		_refresh()
		return
	Campaign.save()
	Campaign.last_result = {}
	var go := func() -> void:
		if not game.active.is_empty():
			get_tree().change_scene_to_file(HubState.BATTLE_SCENE)
		else:
			_after_leg()
	if game.day > day0:
		Sfx.play(&"schritt")
		_refresh()
		_after_travel = go
		ui.show_travel(game.last_travel)
		return
	go.call()


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
		&"rotate":
			rig.rotate_by(float(arg))
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
		&"encyclopedia":
			Encyclopedia.show_on(ui)
		&"logbook":
			_show_logbook()


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
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		_touch_input(e)
		return
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION:
		return  # vom Touch erzeugte Mausereignisse: die Touch-Behandlung übernimmt
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
				if not _pause_story():
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


## Tablet (Hub Auftrag 6, Vorbild Battle._touch_input): wischen = verschieben, antippen = Raum öffnen, zwei Finger =
## zoomen oder drehen. Die Geste entscheidet sich einmal je Berührung (was zuerst deutlich wird), damit sich beides nicht stört;
## Drehen in 90°-Schritten wie Q/E, die Ansicht folgt der Drehrichtung der Finger.
func _touch_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			if ui.covers(e.position):
				return
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_touch_moved = false
				_drag_accum = Vector2.ZERO
			else:
				_touch_moved = true
				_gesture = ""
				_twist = 0.0
				var st := _pinch_state()
				_pinch_dist = st.d
				_pinch_d0 = st.d
				_pinch_angle = st.a
		else:
			var was: bool = _touches.has(e.index)
			_touches.erase(e.index)
			if _touches.size() < 2:
				_gesture = ""
			if was and _touches.is_empty() and not _touch_moved:
				var id := _room_under(e.position)
				if id != &"":
					open_room(id)
	elif e is InputEventScreenDrag:
		if not _touches.has(e.index):
			return
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var st := _pinch_state()
			var da := wrapf(st.a - _pinch_angle, -PI, PI)
			_pinch_angle = st.a
			if _gesture == "":
				_twist += da
				if absf(log(st.d / maxf(_pinch_d0, 1.0))) > PINCH_START:
					_gesture = "zoom"
				elif absf(_twist) > TWIST_START:
					_gesture = "rotate"
			elif _gesture == "rotate":
				_twist += da
			if _gesture == "zoom":
				if _pinch_dist > 0:
					rig.zoom_at(st.c, st.d / _pinch_dist)
				rig.pan(e.relative / 2.0)
			elif _gesture == "rotate" and absf(_twist) > TWIST_STEP:
				rig.rotate_by(90 if _twist > 0 else -90)
				_twist = 0.0
			_pinch_dist = st.d
		else:
			if not _touch_moved:
				_drag_accum += e.relative
				if _drag_accum.length() < 10.0:
					return
				_touch_moved = true
			rig.pan(e.relative)


func _pinch_state() -> Dictionary:
	var ps: Array = _touches.values()
	var a: Vector2 = ps[0]
	var b: Vector2 = ps[1]
	return {"d": a.distance_to(b), "c": (a + b) / 2.0, "a": (b - a).angle()}
