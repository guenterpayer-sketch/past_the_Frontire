class_name ContextMenu
extends PanelContainer
## Kontextmenü am Ziel (Rechtsklick / langes Tippen auf eine Figur): passende Psi-Kräfte.
## Einträge kommen aus PlayerController.context_powers(); gewählt wird über das Signal chosen.

signal chosen(entry: Dictionary)

var _box: VBoxContainer


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.97), Color("b07ae8"), 10, 10))
	custom_minimum_size.x = 320
	mouse_filter = Control.MOUSE_FILTER_STOP
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	hide()


## title: z. B. „Vela · verbündet, 2 Hex“; at: Bildschirmpunkt (Oberflächenkoordinaten)
func open_at(title: String, sub: String, entries: Array, at: Vector2) -> void:
	UiTheme.clear(_box)
	_box.add_child(UiTheme.label(title, 14))
	_box.add_child(UiTheme.label(sub, 12, UiTheme.MUTED))
	for e in entries:
		var b := UiTheme.button(e.text)
		b.disabled = not e.enabled
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 44
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(func() -> void:
			hide()
			chosen.emit(e))
		_box.add_child(b)
	var close := UiTheme.button("Schließen (Esc)")
	close.flat = true
	close.add_theme_font_size_override("font_size", 12)
	close.pressed.connect(hide)
	_box.add_child(close)
	show()
	reset_size()
	var vp := get_parent_control().size if get_parent_control() else get_viewport_rect().size
	position = Vector2(clampf(at.x + 16, 8, vp.x - size.x - 8), clampf(at.y - 20, 8, vp.y - size.y - 8))
