extends Node
## Autoload "TouchInput": Bedienung auf Touch-Geräten, zentral für alle Szenen (Auftrag Export 1, 19.10.2026).
## - Wischen in Listen: Ziehen auf einem Element in einem ScrollContainer (Knopf, Text, Karte) scrollt die Liste;
##   ein kurzer Tipp bleibt ein Klick. Wirkt auch am PC mit gedrückter linker Maustaste.
## - Android-Zurück-Taste wirkt wie Esc (dafür application/config/quit_on_go_back=false).

## ab dieser Strecke (Pixel) wird aus dem Tippen ein Wischen
const DRAG_START := 10.0

var _scroll: ScrollContainer  ## Liste, in der gerade gedrückt wird
var _from := Vector2.ZERO  ## Scrollstand beim Drücken
var _accum := Vector2.ZERO
var _dragging := false


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		for pressed in [true, false]:
			var k := InputEventKey.new()
			k.keycode = KEY_ESCAPE
			k.physical_keycode = KEY_ESCAPE
			k.pressed = pressed
			Input.parse_input_event(k)


## Jedes Control in einer Liste bekommt den Wisch-Handler (auch später erzeugte)
func _on_node_added(n: Node) -> void:
	if not n is Control or n is ScrollBar:
		return
	var sc := _scroll_parent(n)
	if sc and not n.gui_input.is_connected(_on_gui_input):
		n.gui_input.connect(_on_gui_input.bind(n, sc))


## nächster ScrollContainer über n (n selbst zählt mit)
func _scroll_parent(n: Node) -> ScrollContainer:
	var p := n
	while p:
		if p is ScrollContainer:
			return p
		p = p.get_parent()
	return null


## Elemente, die Ziehen selbst brauchen
func _keeps_drag(c: Control) -> bool:
	return c is LineEdit or c is TextEdit or c is Slider or c is ScrollBar \
		or (c is RichTextLabel and (c as RichTextLabel).scroll_active)


## Nur das Element werten, bei dem das Ereignis endet (STOP); der ScrollContainer selbst nur ohne Touchscreen,
## mit Touchscreen zieht er auf freien Flächen schon von selbst.
func _handles(c: Control, sc: ScrollContainer) -> bool:
	if c == sc:
		return not DisplayServer.is_touchscreen_available()
	return c.mouse_filter == Control.MOUSE_FILTER_STOP and not _keeps_drag(c)


func _on_gui_input(e: InputEvent, c: Control, sc: ScrollContainer) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			if _handles(c, sc) and _can_scroll(sc):
				_scroll = sc
				_from = Vector2(sc.scroll_horizontal, sc.scroll_vertical)
				_accum = Vector2.ZERO
				_dragging = false
			return
		if _scroll == sc and _handles(c, sc):
			if _dragging:
				e.position = Vector2(-100000, -100000)  # Loslassen „außerhalb“: der Knopf löst nicht aus
			_scroll = null
			_dragging = false
	elif e is InputEventMouseMotion and _scroll == sc and (e.button_mask & MOUSE_BUTTON_MASK_LEFT):
		if not _handles(c, sc):
			return
		_accum += e.relative
		if not _dragging:
			if _accum.length() < DRAG_START:
				return
			_dragging = true
			# Knopf gilt nicht mehr als gedrückt: diese Bewegung „außerhalb“ an ihn weitergeben
			e.position = Vector2(-100000, -100000)
		else:
			c.accept_event()
		if sc.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			sc.scroll_vertical = int(_from.y - _accum.y)
		if sc.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
			sc.scroll_horizontal = int(_from.x - _accum.x)


## hat die Liste überhaupt etwas zu scrollen?
func _can_scroll(sc: ScrollContainer) -> bool:
	var v := sc.get_v_scroll_bar()
	var h := sc.get_h_scroll_bar()
	return (v and v.max_value > v.page) or (h and h.max_value > h.page)
