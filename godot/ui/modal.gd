class_name Modal
extends Control
## Modales Fenster über dem Spiel: abgedunkelter Hintergrund, Panel mit Titel, Inhalt und Fußleiste.

signal closed

var content: VBoxContainer
var footer: HBoxContainer
var _title: Label
var _panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL, UiTheme.LINE, 10, 16))
	add_child(_panel)
	var v := VBoxContainer.new()
	_panel.add_child(v)
	_title = UiTheme.label("", 20, UiTheme.ACCENT)
	v.add_child(_title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	footer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(footer)
	resized.connect(_layout)
	_layout()
	hide()


func _layout() -> void:
	var s := size
	var w := minf(s.x - 24.0, 1180.0)
	var h := minf(s.y - 24.0, 860.0)
	_panel.offset_left = (s.x - w) / 2.0 - 0.0
	_panel.anchor_left = 0
	_panel.anchor_right = 0
	_panel.anchor_top = 0
	_panel.anchor_bottom = 0
	_panel.position = Vector2((s.x - w) / 2.0, (s.y - h) / 2.0)
	_panel.size = Vector2(w, h)


func open(title: String) -> void:
	_title.text = title
	UiTheme.clear(content)
	UiTheme.clear(footer)
	show()
	_layout()


func add_close(text := "Schließen") -> Button:
	var b := UiTheme.button(text)
	b.pressed.connect(close)
	footer.add_child(b)
	return b


func close() -> void:
	hide()
	closed.emit()


## RichTextLabel für BBCode-Inhalte (Tabellen)
static func rich(bbcode: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_font_size_override("normal_font_size", 13)
	r.add_theme_font_size_override("bold_font_size", 13)
	r.add_theme_constant_override("table_h_separation", 10)
	r.add_theme_constant_override("table_v_separation", 2)
	r.text = bbcode
	return r
