class_name SpaceView
extends Node3D
## Hauptszene des Raumkampfs (space.tscn): baut Karte und Schiffe, spielt die Ereignisse des Regelkerns ab
## (SpaceCombat meldet über Signale, hier nacheinander mit kurzen Animationen) und verbindet die Oberfläche.
## Ohne SpaceBattle.setup (z. B. Szene direkt im Editor mit F6 gestartet) läuft ein Schnellkampf.
## Selbsttest mit Screenshots: godot --path godot res://space.tscn -- --autotest-space (Ordner in PTF_OUT)

const LOG_KIND := {&"bad": &"fumble", &"kill": &"death"}

var combat: SpaceCombat
var ship_views := {}               # Schiffs-ID → SpaceShipView
## Bewegungsplan der Crew in der Phase Bewegen (L/R/F)
var plan: Array = []
## geschätzte Gegnerpositionen dieser Runde (Schatten in der Phase Bewegen)
var predicted := {}
var _events: Array = []
var busy := false
var autotest := false

@onready var map_view: SpaceMapView = $World/MapView
@onready var ships_node: Node3D = $World/Ships
@onready var rig: CameraRig = $CameraRig
@onready var ui: SpaceUI = $UI/SpaceUI


func _ready() -> void:
	autotest = "--autotest-space" in OS.get_cmdline_user_args()
	if SpaceBattle.setup.is_empty():
		SpaceBattle.setup = SpaceBattle.prepare(SpaceSetup.quick())
	combat = SpaceCombat.new(SpaceBattle.setup)
	combat.logged.connect(func(t: String, k: StringName) -> void: _events.append([&"log", t, k]))
	combat.ship_moved.connect(func(s: SpaceShip, p: Array[Vector2i]) -> void: _events.append([&"move", s, p]))
	combat.ship_fired.connect(func(s: SpaceShip, t: SpaceShip, slot: String, r: Dictionary) -> void:
		_events.append([&"fire", s, t, slot, r]))
	combat.ship_changed.connect(func(s: SpaceShip) -> void: _events.append([&"changed", s]))
	combat.ship_destroyed.connect(func(s: SpaceShip) -> void: _events.append([&"destroyed", s]))
	map_view.build(combat)
	for s in combat.ships:
		var v := SpaceShipView.new()
		ships_node.add_child(v)
		v.setup(s)
		ship_views[s.id] = v
	var mid := SpaceMapView.world(Hex.from_offset(SpaceCombat.MAP_W / 2, SpaceCombat.MAP_H / 2))
	rig.yaw = 0.0
	rig.rotation_degrees.y = 0.0
	rig.focus(mid)
	rig.camera.size = 44.0
	var lo := SpaceMapView.world(Hex.from_offset(0, 0))
	var hi := SpaceMapView.world(Hex.from_offset(SpaceCombat.MAP_W - 1, SpaceCombat.MAP_H - 1))
	rig.bounds = Rect2(Vector2(lo.x, lo.z), Vector2(hi.x - lo.x, hi.z - lo.z))
	ui.setup(self)
	Music.play(Music.BRIEFING)
	if autotest:
		_run_autotest.call_deferred()
	else:
		ui.open_briefing()


## Briefing bestätigt: Posten übernehmen, Kampf beginnt
func begin(posts: Dictionary) -> void:
	busy = true
	combat.posts = posts.duplicate()
	Music.play(Music.BATTLE)
	combat.start()
	await play_events()
	busy = false
	_phase_ready()


## Neue Phase: Standardbefehle vorbereiten, Oberfläche auffrischen
func _phase_ready() -> void:
	if combat.result != &"":
		_show_result()
		return
	if combat.phase == SpaceCombat.Phase.MOVE:
		predicted = combat.predict_enemies()
		plan = []
		for i in combat.own.speed:
			plan.append("F")
		update_plan_preview()
	else:
		map_view.clear_path()
	ui.refresh()


## Befehle der Oberfläche ausführen
func execute(orders: Dictionary) -> void:
	if busy or combat.result != &"":
		return
	busy = true
	ui.set_busy(true)
	map_view.clear_path()
	combat.set_orders(orders)
	combat.resolve()
	await play_events()
	busy = false
	ui.set_busy(false)
	_phase_ready()


func surrender() -> void:
	if combat.surrender():
		await play_events()
		_phase_ready()


func update_plan_preview() -> void:
	var pv := combat.plan_path(combat.own, plan)
	map_view.show_path(combat.own.pos, pv.path, pv.facing, pv.blocked)
	map_view.show_ghosts(predicted)


## Enterversuch (Pilotenprobe); bei Erfolg endet der Kampf, sonst geht er weiter
func board() -> void:
	var t := combat.boardable()
	if t == null or busy:
		return
	busy = true
	combat.board(t)
	await play_events()
	busy = false
	_phase_ready()


func decline_board() -> void:
	combat.decline_board()
	await play_events()
	_phase_ready()


## Ereignisse des Regelkerns nacheinander abspielen
func play_events() -> void:
	while not _events.is_empty():
		var e: Array = _events.pop_front()
		match e[0]:
			&"log":
				ui.log_line(e[1], LOG_KIND.get(e[2], e[2]))
			&"move":
				await _animate_move(e[1], e[2])
			&"fire":
				await _animate_fire(e[1], e[2], e[4])
			&"changed":
				ship_views[e[1].id].refresh()
				ui.refresh_ships()
			&"destroyed":
				Sfx.play(&"tod")
				rig.shake(1.0, 0.3)
				ship_views[e[1].id].refresh()
	for v in ship_views.values():
		v.refresh()


func _speed() -> float:
	return 0.0 if autotest else 1.0


func _animate_move(s: SpaceShip, path: Array[Vector2i]) -> void:
	var v: SpaceShipView = ship_views[s.id]
	var body_yaw := SpaceShipView.facing_yaw(s.facing)
	if path.is_empty() or _speed() == 0.0:
		v.place()
		return
	var tw := create_tween()
	for p in path:
		tw.tween_property(v, "position", SpaceMapView.world(p, 0.6), 0.22 * _speed())
	tw.parallel().tween_property(v._body, "rotation:y", body_yaw, 0.3 * _speed())
	await tw.finished
	v.place()


func _animate_fire(s: SpaceShip, t: SpaceShip, r: Dictionary) -> void:
	if _speed() == 0.0:
		return
	var a := SpaceMapView.world(s.pos, 0.8)
	var b := SpaceMapView.world(t.pos, 0.8)
	if not r.hit:
		b += Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
	var line := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = UiTheme.CREW if s.side == &"crew" else UiTheme.ENEMY
	im.surface_begin(Mesh.PRIMITIVE_LINES, m)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_end()
	line.mesh = im
	add_child(line)
	Sfx.play(&"treffer" if r.hit and not r.intercepted else &"daneben")
	if r.hit and String(r.severity) != "":
		Sfx.play(&"krit", 0.1)
	await get_tree().create_timer(0.28 * _speed()).timeout
	line.queue_free()


func _show_result() -> void:
	Music.play(Music.VICTORY if combat.result == &"sieg" else Music.DEFEAT)
	ui.show_result(combat.to_result())


## Ergebnis bestätigt: zurück (SpaceBattle verbucht und wechselt die Szene)
func leave(result: Dictionary) -> void:
	SpaceBattle.finish(get_tree(), result)


## Klick auf ein Feld der Karte
func clicked_cell(cell: Vector2i) -> void:
	var s := combat.ship_at(cell)
	if s:
		ui.ship_clicked(s)


## Maus über der Karte: Tooltip für Gegnerschiffe (über Bedienelementen nicht)
func _input(e: InputEvent) -> void:
	if not (e is InputEventMouseMotion) or e.button_mask != 0:
		return
	var s: SpaceShip = null
	if get_viewport().gui_get_hovered_control() == null:
		var p: Variant = rig.ray_plane(e.position, 0.6)
		if p != null:
			s = combat.ship_at(SpaceMapView.cell_at(p))
	ui.hover_ship(s, e.position)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		match e.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				rig.zoom_at(e.position, 1.1)
			MOUSE_BUTTON_WHEEL_DOWN:
				rig.zoom_at(e.position, 1.0 / 1.1)
			MOUSE_BUTTON_LEFT:
				var p: Variant = rig.ray_plane(e.position, 0.6)
				if p != null:
					clicked_cell(SpaceMapView.cell_at(p))
	elif e is InputEventMouseMotion and (e.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)):
		rig.pan(e.relative)
		ui.hover_ship(null, e.position)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_Q:
				rig.rotate_by(-60.0)
			KEY_E:
				rig.rotate_by(60.0)


# ---------------------------------------------------------------- Selbsttest

func _shot(name: String) -> void:
	var out := OS.get_environment("PTF_OUT")
	if out == "":
		return
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(out)
	get_viewport().get_texture().get_image().save_png(out.path_join("space_%s.png" % name))


func _run_autotest() -> void:
	await get_tree().process_frame
	ui.open_briefing()
	await get_tree().create_timer(0.3).timeout
	await _shot("1_briefing")
	ui.briefing.close_and_start()
	await get_tree().create_timer(0.2).timeout
	await _shot("2_schilde")
	var shots := {SpaceCombat.Phase.MOVE: "3_bewegen", SpaceCombat.Phase.FIRE: "4_schiessen",
		SpaceCombat.Phase.TECH: "5_technik"}
	var guard := 0
	while combat.result == &"" and guard < 400:
		guard += 1
		while busy:
			await get_tree().process_frame
		var ph := combat.phase
		await execute(ui.collect_orders())
		if combat.round_no == 1 and shots.has(combat.phase) and combat.phase != ph:
			await _shot(shots[combat.phase])
		if guard == 9:
			ui.ship_box.toggle()
			await _shot("6_zahlen")
			await _autotest_tip()
	await get_tree().create_timer(0.3).timeout
	await _shot("7_ergebnis")
	print("Raumkampf-Selbsttest: %s nach %d Runden" % [combat.result, combat.round_no])
	get_tree().quit()


## Tooltip über einem Gegner: erst ohne Scan, dann gescannt (Scan für den Screenshot direkt gesetzt)
func _autotest_tip() -> void:
	var foes := combat.active_enemies()
	if foes.is_empty():
		return
	var e: SpaceShip = foes[0]
	var at := get_viewport().get_camera_3d().unproject_position(ship_views[e.id].global_position)
	ui.hover_ship(e, at)
	await _shot("8_gegner_grob")
	e.scan_until = combat.round_no + SpaceCombat.SCAN_ROUNDS
	e.scan_live = true
	ship_views[e.id].refresh()
	ui.hover_ship(null, at)
	ui.hover_ship(e, at)
	await _shot("9_gegner_scan")
	ui.hover_ship(null, at)
