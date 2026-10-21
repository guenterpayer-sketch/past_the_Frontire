extends Node
## Selbsttest der Touch-Bedienung im Schiff und auf der Sternenkarte (Hub Auftrag 6) mit nachgestellten Touch-Ereignissen,
## Screenshots nach PTF_OUT:
##   godot --path godot res://hub.tscn -- --autotest-hub-touch
## Zeigt die Drehknöpfe auch ohne Touchscreen (HubUI).

var out := ""


func _ready() -> void:
	out = OS.get_environment("PTF_OUT")
	if out == "":
		out = "user://"
	Story.auto_start = false
	_run.call_deferred()


func _touch(i: int, p: Vector2, on: bool, dbl := false) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = p
	e.pressed = on
	e.double_tap = dbl
	return e


func _drag(i: int, p: Vector2, rel: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.position = p
	e.relative = rel
	return e


func _run() -> void:
	await _frames(30)
	var hub := get_tree().current_scene as Hub
	var rig := hub.rig
	await _shot("t1_schiff_touch")
	var c := Vector2(700, 450)
	# Zoom: zwei Finger auseinander, ohne zu drehen
	var s0 := rig.camera.size
	var y0 := rig.yaw
	hub._touch_input(_touch(0, c - Vector2(50, 0), true))
	hub._touch_input(_touch(1, c + Vector2(50, 0), true))
	for k in 10:
		hub._touch_input(_drag(1, c + Vector2(60 + k * 10, 0), Vector2(10, 0)))
	hub._touch_input(_touch(1, c, false))
	hub._touch_input(_touch(0, c, false))
	print("Touch Zoom: Größe %.1f → %.1f, Drehung %.0f → %.0f" % [s0, rig.camera.size, y0, rig.yaw])
	# Drehen: zweiter Finger im Uhrzeigersinn um den ersten, ohne Abstand zu ändern
	s0 = rig.camera.size
	hub._touch_input(_touch(0, c, true))
	hub._touch_input(_touch(1, c + Vector2(100, 0), true))
	for k in 12:
		var a := (k + 1) * 0.1
		hub._touch_input(_drag(1, c + Vector2(cos(a), sin(a)) * 100, Vector2.ZERO))
	hub._touch_input(_touch(1, c, false))
	hub._touch_input(_touch(0, c, false))
	print("Touch Drehen: Größe %.1f → %.1f, Drehung %.0f → %.0f" % [s0, rig.camera.size, y0, rig.yaw])
	await _frames(30)
	await _shot("t2_schiff_gedreht")
	# Drehknopf
	var y1 := rig.yaw
	hub._on_action(&"rotate", -90)
	print("Drehknopf: Drehung %.0f → %.0f" % [y1, rig.yaw])
	# Sternenkarte: zoomen, antippen, doppelt antippen
	var g := HubState.game
	var sm := hub.ui.star_map
	sm.open(g)
	await _frames(5)
	sm._touch_input(_touch(0, c - Vector2(50, 0), true))
	sm._touch_input(_touch(1, c + Vector2(50, 0), true))
	for k in 10:
		sm._touch_input(_drag(1, c + Vector2(60 + k * 10, 0), Vector2(10, 0)))
	sm._touch_input(_touch(1, c, false))
	sm._touch_input(_touch(0, c, false))
	print("Karte Zoom: Faktor %.2f, Versatz %s" % [sm._view_k, sm._view_off])
	await _frames(5)
	await _shot("t3_karte_zoom")
	var sys := (g.position + 1) % g.sector.systems.size()
	var p: Vector2 = sm._view_off + sm._to_screen(g.sector.systems[sys].pos) * sm._view_k
	sm._touch_input(_touch(0, p, true))
	sm._touch_input(_touch(0, p, false))
	print("Karte antippen: gewählt %d (erwartet %d)" % [sm.selected, sys])
	sm._touch_input(_touch(0, p, true, true))
	sm._touch_input(_touch(0, p, false))
	print("Karte doppelt antippen: Systemansicht %d, Faktor %.2f" % [sm.zoom, sm._view_k])
	await _frames(5)
	await _shot("t4_system")
	print("AUTOTEST FERTIG")
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
