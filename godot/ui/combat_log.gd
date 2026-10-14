class_name CombatLog
extends PanelContainer
## Kampflog mit farbigen Einträgen. Eingeklappt sind nur die letzten Zeilen zu sehen, aufgeklappt der ganze Verlauf.

signal toggled(expanded: bool)

const COLORS := {
	&"round": "#ffd34d", &"hit": "#ffb38a", &"miss": "#8291ad", &"crit": "#ffd54f", &"death": "#ff6b6b",
	&"heal": "#8fe39b", &"fumble": "#ff8a8a", &"dmg": "#ff9e9e",
}
const MAX_LINES := 400
const RECENT := 2
const EXPANDED_H := 380.0

var expanded := false
var _text: RichTextLabel
var _recent: RichTextLabel     # eingeklappt: nur die letzten Einträge
var _recent_lines: Array[String] = []
var _toggle: Button
var _lines := 0


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 10))
	custom_minimum_size.x = 360
	mouse_filter = Control.MOUSE_FILTER_STOP
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	var head := HBoxContainer.new()
	var title := UiTheme.label("KAMPFLOG", 12, UiTheme.MUTED)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_toggle = UiTheme.button("")
	_toggle.add_theme_font_size_override("font_size", 12)
	_toggle.custom_minimum_size = Vector2(110, 30)
	_toggle.pressed.connect(func() -> void: set_expanded(not expanded))
	head.add_child(_toggle)
	box.add_child(head)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.selection_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 13)
	_text.add_theme_font_size_override("bold_font_size", 13)
	box.add_child(_text)
	_recent = RichTextLabel.new()
	_recent.bbcode_enabled = true
	_recent.fit_content = true
	_recent.scroll_active = false
	_recent.add_theme_font_size_override("normal_font_size", 13)
	_recent.add_theme_font_size_override("bold_font_size", 13)
	box.add_child(_recent)
	set_expanded(false)


func set_expanded(on: bool) -> void:
	expanded = on
	_toggle.text = "zuklappen ▾" if on else "aufklappen ▴"
	_text.custom_minimum_size.y = EXPANDED_H
	_text.visible = on
	_recent.visible = not on
	reset_size()
	toggled.emit(on)


func add(text: String, kind: StringName = &"") -> void:
	var t := text.replace("[", "[lb]")
	if COLORS.has(kind):
		t = "[color=%s]%s[/color]" % [COLORS[kind], t]
	if kind == &"round" or kind == &"death":
		t = "[b]%s[/b]" % t
	_text.append_text(t + "\n")
	_recent_lines.append(t)
	if _recent_lines.size() > RECENT:
		_recent_lines.pop_front()
	_recent.text = "\n".join(_recent_lines)
	_lines += 1
	if _lines > MAX_LINES:
		_text.remove_paragraph(0)
		_lines -= 1


func clear() -> void:
	_text.clear()
	_recent_lines.clear()
	_recent.text = ""
	_lines = 0
