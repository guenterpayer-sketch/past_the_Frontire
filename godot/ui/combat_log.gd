class_name CombatLog
extends PanelContainer
## Kampflog mit farbigen Einträgen.

const COLORS := {
	&"round": "#ffd34d", &"hit": "#ffb38a", &"miss": "#8291ad", &"crit": "#ffd54f", &"death": "#ff6b6b",
	&"heal": "#8fe39b", &"fumble": "#ff8a8a", &"dmg": "#ff9e9e",
}
const MAX_LINES := 400

var _text: RichTextLabel
var _lines := 0


func _ready() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	box.add_child(UiTheme.label("KAMPFLOG", 12, UiTheme.MUTED))
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_following = true
	_text.selection_enabled = true
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.add_theme_font_size_override("normal_font_size", 12)
	_text.add_theme_font_size_override("bold_font_size", 12)
	box.add_child(_text)


func add(text: String, kind: StringName = &"") -> void:
	var t := text.replace("[", "[lb]")
	if COLORS.has(kind):
		t = "[color=%s]%s[/color]" % [COLORS[kind], t]
	if kind == &"round" or kind == &"death":
		t = "[b]%s[/b]" % t
	_text.append_text(t + "\n")
	_lines += 1
	if _lines > MAX_LINES:
		_text.remove_paragraph(0)
		_lines -= 1


func clear() -> void:
	_text.clear()
	_lines = 0
