class_name SpaceShipBox
extends PanelContainer
## Kasten links oben für das eigene Schiff (Entscheidung des Nutzers): per Klick zwischen Schema (Umriss mit
## Schildbögen und Systemen) und Zahlen (Hülle, Schild je Seite, Systemschäden) umschalten.

const W := 230.0
const SYSTEMS := ["antrieb", "sensoren", "schilde", "reaktor", "lebenserhaltung"]
const SYS_SHORT := {"antrieb": "Antr.", "sensoren": "Sens.", "schilde": "Schild", "reaktor": "Reakt.",
	"lebenserhaltung": "Leben"}

var combat: SpaceCombat
var numbers := false
var _title: Label
var _canvas: Control
var _text: RichTextLabel
var _hint: Label


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.92), UiTheme.LINE, 8, 8))
	custom_minimum_size.x = W
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Klick: zwischen Schema und Zahlen umschalten"
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	_title = UiTheme.label("", 13, UiTheme.MUTED)
	v.add_child(_title)
	_canvas = Control.new()
	_canvas.custom_minimum_size = Vector2(W - 16, 170)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_schema)
	v.add_child(_canvas)
	_text = Modal.rich("")
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_text)
	_hint = UiTheme.label("", 11, UiTheme.MUTED)
	v.add_child(_hint)
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			toggle())


func toggle() -> void:
	numbers = not numbers
	Sfx.play(&"klick")
	refresh()


func refresh() -> void:
	if combat == null:
		return
	var s := combat.own
	_title.text = "%s · Hülle %d/%d" % [s.name.to_upper(), s.hull, s.hull_max]
	_canvas.visible = not numbers
	_text.visible = numbers
	_hint.text = "⇄ Klick: %s" % ("Schema" if numbers else "Zahlen")
	if numbers:
		var t := "Hülle [b]%d / %d[/b]\n" % [s.hull, s.hull_max]
		for i in 6:
			t += "Schild %s: %d / %d\n" % [SpaceShip.SIDE_NAMES[i], s.shields[i], s.shield_max]
		t += "Energie je Runde: %d\n" % combat.reactor_energy()
		var dmg := ""
		for sys in s.damage:
			dmg += "[color=#ff6b6b]%s (%s)[/color]\n" % [combat.system_name(String(sys)), s.damage[sys]]
		t += dmg if dmg != "" else "[color=#6fdc6f]keine Systemschäden[/color]"
		_text.text = t
	else:
		_canvas.queue_redraw()


func _draw_schema() -> void:
	if combat == null:
		return
	var s := combat.own
	var c := _canvas.size / 2.0 + Vector2(0, 4)
	var r := 70.0
	# Schildbögen: Seite i liegt in Bildrichtung „oben = Bug“, gegen den Uhrzeigersinn = links
	for i in 6:
		var v := float(s.shields[i]) / maxf(1.0, s.shield_max)
		var col := UiTheme.CREW if v > 0.6 else (UiTheme.ACCENT if v > 0.3 else UiTheme.BAD)
		if v <= 0.0:
			col = Color(UiTheme.LINE, 0.8)
		col.a = 0.35 + 0.65 * v if v > 0.0 else 0.8
		var center := -90.0 - 60.0 * i
		_canvas.draw_arc(c, r, deg_to_rad(center - 25), deg_to_rad(center + 25), 16, col, 6.0, true)
		var lp := c + Vector2.from_angle(deg_to_rad(center)) * (r + 12) - Vector2(6, -5)
		_canvas.draw_string(get_theme_default_font(), lp, str(s.shields[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11,
			UiTheme.MUTED)
	var hull := PackedVector2Array([c + Vector2(0, -48), c + Vector2(26, -14), c + Vector2(26, 30),
		c + Vector2(14, 44), c + Vector2(-14, 44), c + Vector2(-26, 30), c + Vector2(-26, -14)])
	_canvas.draw_colored_polygon(hull, UiTheme.PANEL2)
	hull.append(hull[0])
	_canvas.draw_polyline(hull, UiTheme.CREW, 1.5, true)
	var pos := [Vector2(0, -26), Vector2(-12, -4), Vector2(12, -4), Vector2(-10, 22), Vector2(10, 22)]
	for i in SYSTEMS.size():
		var lv := s.dmg_level(SYSTEMS[i])
		var col := UiTheme.GOOD if lv == 0 else (UiTheme.ACCENT if lv <= 2 else UiTheme.BAD)
		_canvas.draw_circle(c + pos[i], 4.5, col)
	var bar := Rect2(c + Vector2(-50, 58), Vector2(100, 6))
	_canvas.draw_rect(bar, UiTheme.PANEL2)
	var pct := float(s.hull) / maxf(1.0, s.hull_max)
	_canvas.draw_rect(Rect2(bar.position, Vector2(bar.size.x * pct, bar.size.y)),
		UiTheme.GOOD if pct > 0.5 else (UiTheme.ACCENT if pct > 0.25 else UiTheme.BAD))
