class_name ActiveTag
extends Control
## Schild über der Figur, die am Zug ist (bzw. in Runde 0 aufgestellt wird): „Name · am Zug“ in der Farbe
## der Figur, Fläche 60 % deckend (Entscheidung 15.10.2026), mit wippendem Pfeil darüber. Folgt der Figur auf dem Bildschirm; Battle setzt die Position jedes Bild.

const ARROW := 14.0
const ALPHA := 0.6     # Deckkraft der Fläche, damit die Umgebung dahinter sichtbar bleibt

var _panel: PanelContainer
var _label: Label
var _t := 0.0
var _color := UiTheme.ACCENT
var _key := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = UiTheme.label("", 16, UiTheme.BG)
	_label.add_theme_font_override("font", _bold())
	_panel.add_child(_label)
	hide()


func _bold() -> Font:
	var f := SystemFont.new()
	f.font_weight = 700
	f.fallbacks = [get_theme_default_font()]
	return f


## p: Bildschirmpunkt über dem Kopf der Figur; color: Farbe der Figur; enemy: roter Rand für Gegner
func show_at(p: Vector2, text: String, color: Color, enemy := false) -> void:
	var key := "%s|%s|%s" % [text, color.to_html(), enemy]
	if _key != key:
		_key = key
		_label.text = text
		_color = Color(color, ALPHA)
		var fg := UiTheme.BG if color.get_luminance() > 0.45 else UiTheme.TEXT
		_label.add_theme_color_override("font_color", fg)
		_label.add_theme_color_override("font_outline_color", Color(color.darkened(0.6), 0.8) if fg == UiTheme.TEXT else Color(1, 1, 1, 0.35))
		_label.add_theme_constant_override("outline_size", 3)
		_panel.add_theme_stylebox_override("panel", UiTheme.box(_color, UiTheme.ENEMY if enemy else Color(color.darkened(0.35), 0.9), 7, 10, 2 if enemy else 1))
		_panel.reset_size()
	var s := _panel.get_combined_minimum_size()
	_panel.size = s
	size = s + Vector2(0, ARROW + 6)
	position = (p - Vector2(s.x / 2.0, size.y)).round()
	_panel.position = Vector2(0, ARROW + 6)
	show()
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _draw() -> void:
	# Pfeil über dem Schild, wippt leicht
	var cx := size.x / 2.0
	var y := 2.0 + sin(_t * 5.0) * 3.0
	var pts := PackedVector2Array([Vector2(cx - 11, y), Vector2(cx + 11, y), Vector2(cx, y + ARROW)])
	draw_colored_polygon(pts, Color(_color, 0.9))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), UiTheme.BG, 2.0, true)
