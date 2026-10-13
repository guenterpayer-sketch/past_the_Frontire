class_name UiTheme
extends RefCounted
## Farben und Theme der Oberfläche (dunkel, wie die HTML-Version).

const BG := Color("0b0f1a")
const PANEL := Color("131a2a")
const PANEL2 := Color("1a2337")
const LINE := Color("2a3550")
const TEXT := Color("dfe6f3")
const MUTED := Color("8291ad")
const ACCENT := Color("ffd34d")
const CREW := Color("5db7ff")
const ENEMY := Color("ff5d5d")
const GOOD := Color("6fdc6f")
const BAD := Color("ff6b6b")


static func box(bg: Color, border := LINE, radius := 6, margin := 8, width := 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func _btn_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := box(bg, border, 6, 6)
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14
	t.set_stylebox("panel", "PanelContainer", box(Color(PANEL, 0.96), LINE, 8, 10))
	t.set_stylebox("panel", "Panel", box(Color(PANEL, 0.96), LINE, 8, 10))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	for cls in ["Button", "OptionButton"]:
		t.set_stylebox("normal", cls, _btn_box(PANEL2, LINE))
		t.set_stylebox("hover", cls, _btn_box(PANEL2.lightened(0.08), MUTED))
		t.set_stylebox("pressed", cls, _btn_box(Color("3a3215"), ACCENT))
		t.set_stylebox("hover_pressed", cls, _btn_box(Color("3a3215"), ACCENT))
		t.set_stylebox("disabled", cls, _btn_box(Color(PANEL2, 0.5), Color(LINE, 0.5)))
		t.set_stylebox("focus", cls, StyleBoxEmpty.new())
		t.set_color("font_color", cls, TEXT)
		t.set_color("font_hover_color", cls, Color.WHITE)
		t.set_color("font_pressed_color", cls, ACCENT)
		t.set_color("font_hover_pressed_color", cls, ACCENT)
		t.set_color("font_disabled_color", cls, Color(MUTED, 0.6))
	t.set_stylebox("panel", "PopupMenu", box(PANEL2, LINE, 6, 6))
	t.set_stylebox("panel", "TooltipPanel", box(Color(PANEL, 0.97), LINE, 6, 8))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_stylebox("background", "ProgressBar", box(Color(BG, 0.8), LINE, 4, 0))
	t.set_stylebox("fill", "ProgressBar", box(GOOD, GOOD, 4, 0, 0))
	t.set_color("font_color", "ProgressBar", Color.WHITE)
	t.set_constant("separation", "VBoxContainer", 6)
	t.set_constant("separation", "HBoxContainer", 6)
	t.set_constant("h_separation", "GridContainer", 4)
	t.set_constant("v_separation", "GridContainer", 4)
	return t


static func label(text: String, size := 14, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, tip := "", toggled := false) -> Button:
	var b := Button.new()
	b.text = text
	b.tooltip_text = tip
	b.toggle_mode = toggled
	b.focus_mode = Control.FOCUS_NONE
	return b


## kleines farbiges Kästchen mit Buchstaben (Figur)
static func badge(letter: String, color: Color, size := 22) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := box(color, color.darkened(0.3), 5, 0)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = Vector2(size, size)
	var l := label(letter, int(size * 0.6), Color(0.07, 0.07, 0.09))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()
