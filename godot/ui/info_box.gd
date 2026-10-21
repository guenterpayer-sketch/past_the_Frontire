class_name InfoBox
extends PanelContainer
## Fester Infokasten oben rechts für das Feld oder die Figur unter der Maus (statt Tooltip auf der Karte).
## Auf Touchgeräten mit Knopf "Ausführen" (statt ein zweites Mal antippen).

signal confirm

var _text: RichTextLabel
var _confirm: Button


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.93), UiTheme.LINE, 10, 12))
	custom_minimum_size.x = 380
	# Klicks gehen durch auf die Karte, damit ein Gegner unter dem Kasten angreifbar bleibt; nur der Knopf „Ausführen“ fängt sie
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	add_child(v)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", 14)
	_text.add_theme_font_size_override("bold_font_size", 14)
	v.add_child(_text)
	_confirm = UiTheme.button("Ausführen")
	_confirm.custom_minimum_size.y = 48
	_confirm.add_theme_color_override("font_color", UiTheme.ACCENT)
	_confirm.pressed.connect(confirm.emit)
	v.add_child(_confirm)
	hide()


## bbcode leer = ausblenden; with_confirm = Knopf "Ausführen" zeigen (Touch)
func show_info(bbcode: String, with_confirm := false) -> void:
	if bbcode == "":
		hide()
		return
	_text.text = bbcode
	_confirm.visible = with_confirm
	show()
	reset_size()


func text() -> String:
	return _text.get_parsed_text()
