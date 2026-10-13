class_name Battle
extends Node3D
## Hauptszene: verbindet Kampflogik (Combat, CombatAI), Darstellung (MapView, UnitView, Overlay, Fx),
## Ablauf der Ereignisse (EventPlayer), Bedienung (PlayerController) und Oberfläche (BattleUI).

const AI_DELAY := 0.22
const LONG_PRESS := 0.55

var combat: Combat
var ai := CombatAI.new()
var player: PlayerController
var views := {}                  # Combatant -> UnitView
var auto_crew := false
var show_grid := true

var _hover: Variant = null       # Feld unter der Maus (Vector2i) oder null
var _hover_unit: Combatant = null
var _ai_thread: Thread
var _ai_wait := 0.0
var _dirty := true
var _end_shown := false
# Touch
var _touches := {}
var _pinch_dist := 0.0
var _touch_moved := false
var _touch_start_ms := 0
var _long_fired := false
var _tap_key := ""
var _touch_used := false
var _mouse_drag := false
var _drag_moved := false
var _drag_accum := Vector2.ZERO

@onready var map_view: MapView = $World/MapView
@onready var overlay: Overlay = $World/Overlay
@onready var fx: Fx = $World/Fx
@onready var units_root: Node3D = $World/Units
@onready var rig: CameraRig = $CameraRig
@onready var events: EventPlayer = $EventPlayer
@onready var ui: BattleUI = $UI/BattleUI


func _ready() -> void:
	Dice.randomize()
	if OS.has_feature("mobile") or "--no-shadows" in OS.get_cmdline_user_args():
		$Sun.shadow_enabled = false
	overlay.map_view = map_view
	events.map_view = map_view
	events.fx = fx
	events.camera = rig
	events.dice_panel = ui.dice_panel
	events.combat_log = ui.combat_log
	events.dice_enabled = Prefs.get_bool("dice", true)
	events.idle_changed.connect(func(_idle: bool) -> void: _dirty = true)
	show_grid = Prefs.get_bool("grid", true)
	ui.action.connect(_on_action)
	ui.set_toggle(&"sound", Sfx.enabled, "Ton: %s" % ("an" if Sfx.enabled else "aus"))
	ui.set_toggle(&"dice", events.dice_enabled, "Würfel: %s" % ("an" if events.dice_enabled else "aus"))
	rig.rotated.connect(func() -> void: map_view.update_cutaway(rig.view_dir()))
	new_battle(randi() % 1000000)
	var args := OS.get_cmdline_user_args()
	if "--autotest" in args or "--autotest-player" in args:
		var t: Node = load("res://tests/autotest.gd").new()
		t.battle = self
		add_child(t)


func new_battle(seed_value: int, size_id := "") -> void:
	if size_id == "":
		size_id = BattleMap.SIZES[randi() % BattleMap.SIZES.size()].id
	_wait_ai()
	events.clear()
	ui.combat_log.clear()
	ui.end_dialog.hide()
	_end_shown = false
	var map := MapGenerator.generate(seed_value, size_id)
	var progress := Roster.load_progress()
	combat = Combat.new(map, Roster.build_team(GameData.crew(), &"crew", progress), Roster.build_team(GameData.enemies(), &"enemy"))
	ai = CombatAI.new()
	player = PlayerController.new(combat)
	map_view.theme = GameData.hall_theme()
	map_view.build(map)
	map_view.set_grid_visible(show_grid)
	for c in units_root.get_children():
		c.queue_free()
	views.clear()
	for u in combat.units:
		var v := UnitView.new()
		units_root.add_child(v)
		v.setup(u)
		v.position = map_view.tile_top(u.pos)
		views[u] = v
	events.views = views
	events.bind(combat)
	combat.ended.connect(func(_r: StringName) -> void: _dirty = true)
	var c := map_view.center()
	rig.bounds = Rect2(-2, -2, c.x * 2 + 4, c.z * 2 + 4)
	rig.focus(map_view.tile_top(map.crew_start[0].pos).lerp(c, 0.35))
	map_view.update_cutaway(rig.view_dir())
	var sz: Dictionary = map.size_info
	ui.hall_label.text = "Lagerhalle %s, ca. %d×%d m · Karte %d" % [sz.name, roundi(sz.cols * Hex.SIZE_M), roundi(sz.rows * Hex.ROW_M), map.map_seed]
	ui.combat_log.add("Karte %d (%s): 6 Crewmitglieder gegen 6 Söldner der Roten Sonne in einer Lagerhalle." % [map.map_seed, sz.name], &"round")
	combat.start()
	_dirty = true


func is_ai(u: Combatant) -> bool:
	return u != null and (not u.is_crew or auto_crew)


func player_turn() -> bool:
	var u := combat.current
	return u != null and not is_ai(u) and combat.result == &"" and events.is_idle() and u.is_ok() and _ai_thread == null


func _process(delta: float) -> void:
	rig.right_inset = ui.panel_width()
	_tick_ai(delta)
	if _dirty and events.is_idle():
		_dirty = false
		_refresh()
	if combat.result != &"" and events.is_idle() and not _end_shown:
		_end_shown = true
		get_tree().create_timer(0.8).timeout.connect(func() -> void: ui.end_dialog.show_end(combat))
	if _touches.size() == 1 and not _touch_moved and not _long_fired and Time.get_ticks_msec() - _touch_start_ms > LONG_PRESS * 1000:
		_long_fired = true
		var p: Vector2 = _touches.values()[0]
		_face_at(p)


## KI-Züge: Planung in einem eigenen Thread (die Halle bleibt bedienbar), Ausführung im Hauptthread
func _tick_ai(delta: float) -> void:
	if _ai_thread:
		if not _ai_thread.is_alive():
			var step: Dictionary = _ai_thread.wait_to_finish()
			_ai_thread = null
			var u := combat.current
			if u and is_ai(u) and combat.result == &"":
				if step.type == &"end" or not ai.execute(combat, u, step):
					combat.end_turn()
			_dirty = true
		return
	if combat.result != &"" or not events.is_idle():
		_ai_wait = 0.0
		return
	var u := combat.current
	if u == null:
		return
	if not u.is_ok():
		combat.end_turn()
		return
	if not is_ai(u):
		return
	_ai_wait += delta
	if _ai_wait < AI_DELAY:
		return
	_ai_wait = 0.0
	_ai_thread = Thread.new()
	_ai_thread.start(ai.plan_step.bind(combat, u))


func _wait_ai() -> void:
	if _ai_thread:
		_ai_thread.wait_to_finish()
		_ai_thread = null


func _exit_tree() -> void:
	_wait_ai()


# ---------------------------------------------------------------- Anzeige

func _refresh() -> void:
	var u := combat.current
	var pt := player_turn()
	ui.round_label.text = "Runde %d" % combat.round_no
	ui.initiative.refresh(combat, is_ai)
	ui.unit_panel.refresh(combat, player, u, pt, show_grid)
	_update_overlay()


func _update_overlay() -> void:
	var u := combat.current
	if not player_turn() or u == null:
		overlay.show_state({"hover": _hover if _hover != null and events.is_idle() else null})
		return
	var st := player.view_state(u, _hover, _hover_unit)
	st.views = views
	overlay.show_state(st)


func _update_hover(screen_pos: Vector2) -> void:
	var hit := _pick(screen_pos)
	if hit.tile != _hover or hit.unit != _hover_unit:
		_hover = hit.tile
		_hover_unit = hit.unit
		_update_overlay()
	var tip := ""
	if events.is_idle() and not ui.covers(screen_pos):
		tip = player.tooltip(combat.current, player_turn(), _hover, _hover_unit)
	ui.show_tip(tip, screen_pos, _touch_used)


## Feld und Figur unter einem Bildschirmpunkt: Figuren nach Bildschirmabstand,
## Felder über Ebenen je Höhenstufe (von oben nach unten)
func _pick(screen_pos: Vector2) -> Dictionary:
	if ui.covers(screen_pos):
		return {"tile": null, "unit": null}
	var best_u: Combatant = null
	var best_d := 1e9
	var vh := get_viewport().get_visible_rect().size.y
	var radius := 0.6 / rig.camera.size * vh
	for u in views:
		if u.is_dead():
			continue
		var v: UnitView = views[u]
		for y in [0.4, 1.0, 1.6]:
			var sp := rig.camera.unproject_position(v.position + Vector3(0, y, 0))
			var d := sp.distance_to(screen_pos)
			if d < radius and d < best_d:
				best_d = d
				best_u = u
	# Felder je Höhenstufe von oben nach unten; erreichbare Felder haben Vorrang (verdeckt hinter Kisten o. Ä.)
	var tile: Variant = null
	var reach: BattleMap.Reach = player.reach(combat.current) if player_turn() else null
	for h in range(6, -1, -1):
		var p: Variant = rig.ray_plane(screen_pos, h * BattleMap.LEVEL_M)
		if p == null:
			continue
		var t := combat.map.tile(Hex.from_world(Vector2(p.x, p.z)))
		if t and t.h == h:
			if reach and reach.has(t.pos) and t.pos != combat.current.pos:
				tile = t.pos
				break
			if tile == null:
				tile = t.pos
				if reach == null:
					break
	if best_u:
		tile = best_u.pos
	return {"tile": tile, "unit": best_u}


# ---------------------------------------------------------------- Eingabe

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
		_update_hover(e.position)
	elif e is InputEventMouseButton:
		_mouse_button(e)
	elif e is InputEventKey and e.pressed and not e.echo:
		_key(e)


func _mouse_button(e: InputEventMouseButton) -> void:
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
					_click(e.position)
		MOUSE_BUTTON_RIGHT:
			if e.pressed:
				_face_at(e.position)


func _click(p: Vector2) -> void:
	if not player_turn():
		return
	var hit := _pick(p)
	player.click(combat.current, hit.tile, hit.unit)
	ui.hide_tip()
	_dirty = true


func _face_at(p: Vector2) -> void:
	if not player_turn():
		return
	var hit := _pick(p)
	if hit.tile != null:
		player.face_toward(combat.current, hit.tile)
		_dirty = true


func _key(e: InputEventKey) -> void:
	match e.keycode:
		KEY_ESCAPE:
			if not ui.close_dialogs():
				player.mode = PlayerController.Mode.MOVE
		KEY_ENTER, KEY_KP_ENTER:
			if player_turn():
				combat.end_turn()
		KEY_R:
			player.show_range = not player.show_range
		KEY_G:
			_toggle_grid()
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
		KEY_PLUS, KEY_KP_ADD, KEY_EQUAL:
			rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 1.2)
		KEY_MINUS, KEY_KP_SUBTRACT:
			rig.zoom_at(get_viewport().get_visible_rect().size / 2.0, 1 / 1.2)
	_dirty = true


## Handy/Tablet: ziehen = verschieben, zwei Finger = zoomen, Antippen = Vorschau, nochmal = ausführen, lange drücken = drehen
func _touch_input(e: InputEvent) -> void:
	_touch_used = true
	if e is InputEventScreenTouch:
		if e.pressed:
			if ui.covers(e.position):
				return
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_touch_moved = false
				_drag_accum = Vector2.ZERO
				_long_fired = false
				_touch_start_ms = Time.get_ticks_msec()
			else:
				_touch_moved = true
				_pinch_dist = _pinch_state().d
		else:
			var was: bool = _touches.has(e.index)
			_touches.erase(e.index)
			if was and _touches.is_empty() and not _touch_moved and not _long_fired:
				_tap(e.position)
	elif e is InputEventScreenDrag:
		if not _touches.has(e.index):
			return
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var st := _pinch_state()
			if _pinch_dist > 0:
				rig.zoom_at(st.c, st.d / _pinch_dist)
			_pinch_dist = st.d
			rig.pan(e.relative / 2.0)
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
	return {"d": a.distance_to(b), "c": (a + b) / 2.0}


func _tap(p: Vector2) -> void:
	_update_hover(p)
	var key := ""
	if _hover_unit:
		key = "u:%s" % _hover_unit.id
	elif _hover != null:
		key = str(_hover)
	if key != "" and key == _tap_key:
		_tap_key = ""
		_click(p)
	else:
		_tap_key = key


# ---------------------------------------------------------------- Aktionen aus der Oberfläche

func _on_action(name: StringName, arg: Variant) -> void:
	var u := combat.current
	match name:
		&"sheet":
			var target: Combatant = arg if arg is Combatant else (u if u and u.is_crew else combat.crew()[0])
			ui.sheet.show_sheet(combat.crew(), target)
		&"tables":
			ui.tables.show_tables(player.weapon_of(u) if u else null)
		&"auto":
			auto_crew = arg
		&"sound":
			Sfx.toggle()
			ui.set_toggle(&"sound", Sfx.enabled, "Ton: %s" % ("an" if Sfx.enabled else "aus"))
		&"dice":
			events.dice_enabled = not events.dice_enabled
			Prefs.set_bool("dice", events.dice_enabled)
			ui.set_toggle(&"dice", events.dice_enabled, "Würfel: %s" % ("an" if events.dice_enabled else "aus"))
			if not events.dice_enabled:
				ui.dice_panel.hide()
		&"new":
			new_battle(randi() % 1000000)
		&"next_battle":
			Roster.save_progress(combat.crew())
			new_battle(randi() % 1000000)
		&"reset_crew":
			Roster.reset()
			new_battle(randi() % 1000000)
		&"focus":
			rig.focus(views[arg].position, false)
		&"jump":
			if not is_ai(arg):
				combat.request_jump(arg)
		&"grid":
			_toggle_grid()
		&"refresh":
			pass
		_:
			if player_turn():
				_panel_action(u, name, arg)
	_dirty = true


func _panel_action(u: Combatant, name: StringName, arg: Variant) -> void:
	match name:
		&"weapon":
			player.select_weapon(u, arg)
		&"gait":
			player.gait = arg
			player.mode = PlayerController.Mode.MOVE
		&"pct":
			player.pct = arg
		&"overwatch":
			combat.do_overwatch(u, player.weapon_of(u))
		&"reload":
			combat.do_reload(u, arg)
		&"aid":
			player.toggle_mode(PlayerController.Mode.AID)
		&"psi":
			player.toggle_mode(PlayerController.Mode.PSI)
		&"face":
			player.toggle_mode(PlayerController.Mode.FACE)
		&"crouch":
			combat.do_crouch(u)
		&"wait":
			combat.do_wait(u)
		&"range":
			player.show_range = not player.show_range
		&"end":
			combat.end_turn()
	Sfx.play(&"klick")


func _toggle_grid() -> void:
	show_grid = not show_grid
	Prefs.set_bool("grid", show_grid)
	map_view.set_grid_visible(show_grid)
