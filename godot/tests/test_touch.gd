extends SceneTree
## Tests der Touch-Grundlagen (TouchInput, Modal): Wischen in Listen, Tippen bleibt Klick, Klick neben ein Fenster.
## godot --headless --path godot --script res://tests/test_touch.gd

var fails := 0
var clicks := 0
var vp: SubViewport  ## eigene Fläche 800×600 (das Hauptfenster ist ohne Grafik nur 64×64)


func check(cond: bool, what: String) -> void:
	if not cond:
		fails += 1
		printerr("FEHLER: ", what)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(800, 600)
	root.add_child(vp)
	if not root.has_node("TouchInput"):
		var ti: Node = load("res://ui/touch_input.gd").new()
		ti.name = "TouchInput"
		root.add_child(ti)
	await process_frame
	await _test_swipe()
	await _test_modal_outside()
	print("OK" if fails == 0 else "FEHLER: %d" % fails)
	quit(1 if fails else 0)


func _mouse_button(pos: Vector2, pressed: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	e.position = pos
	e.global_position = pos
	vp.push_input(e)


func _mouse_move(pos: Vector2, rel: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	e.position = pos
	e.global_position = pos
	e.relative = rel
	vp.push_input(e)


func _test_swipe() -> void:
	var sc := ScrollContainer.new()
	sc.position = Vector2(50, 50)
	sc.size = Vector2(300, 200)
	vp.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var first: Button
	for i in 20:
		var b := Button.new()
		b.text = "Zeile %d" % i
		b.custom_minimum_size = Vector2(0, 40)
		b.pressed.connect(func() -> void: clicks += 1)
		v.add_child(b)
		if i == 0:
			first = b
	await process_frame
	await process_frame
	var p := first.get_global_rect().get_center()
	# Tippen: Klick, kein Scrollen
	_mouse_button(p, true)
	_mouse_button(p, false)
	await process_frame
	check(clicks == 1, "Tippen auf einen Listenknopf löst ihn aus (Klicks %d)" % clicks)
	check(sc.scroll_vertical == 0, "Tippen scrollt nicht")
	# Wischen nach oben: scrollt, Knopf löst nicht aus
	_mouse_button(p, true)
	var q := p
	for i in 10:
		q += Vector2(0, -12)
		_mouse_move(q, Vector2(0, -12))
	_mouse_button(q, false)
	await process_frame
	check(sc.scroll_vertical >= 100, "Wischen scrollt die Liste (%d)" % sc.scroll_vertical)
	check(clicks == 1, "Wischen löst den Knopf nicht aus (Klicks %d)" % clicks)
	# danach geht Tippen wieder
	var b2: Button = v.get_child(5)
	var p2 := b2.get_global_rect().get_center()
	_mouse_button(p2, true)
	_mouse_button(p2, false)
	await process_frame
	check(clicks == 2, "nach dem Wischen klickt Tippen wieder (Klicks %d)" % clicks)
	sc.queue_free()
	await process_frame


func _test_modal_outside() -> void:
	var m := Modal.new()
	vp.add_child(m)
	m.max_size = Vector2(300, 200)
	m.open("Test")
	await process_frame
	_mouse_button(Vector2(5, 5), true)
	_mouse_button(Vector2(5, 5), false)
	await process_frame
	check(m.visible, "Klick neben ein Fenster schließt es nicht")
	m.queue_free()
