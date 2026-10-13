class_name DicePanel
extends PanelContainer
## Würfelanzeige: zwei W10 (rot = Zehner, weiß = Einer) rollen, Nachwürfe darunter.
## Bleibt stehen, bis man draufklickt oder der nächste Wurf kommt.

const TUMBLE := 0.5
const TUMBLE_NEXT := 0.38

var _title: Label
var _rows: VBoxContainer
var _sum: Label
var _rng := RandomNumberGenerator.new()
var _roll_id := 0


## Ein W10 von vorne: Drachenform mit zwei schattierten unteren Flächen
class Die:
	extends Control
	var text := "0"
	var tens := false

	func _init(is_tens: bool) -> void:
		tens = is_tens
		size = Vector2(46, 52)
		pivot_offset = size / 2.0
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var base := Color(0.84, 0.2, 0.21) if tens else Color(0.94, 0.95, 0.97)
		var top := Vector2(w * 0.5, 0)
		var left := Vector2(0, h * 0.6)
		var right := Vector2(w, h * 0.6)
		var bottom := Vector2(w * 0.5, h)
		var mid := Vector2(w * 0.5, h * 0.8)
		draw_colored_polygon(PackedVector2Array([top, right, bottom, left]), base)
		draw_colored_polygon(PackedVector2Array([left, mid, bottom]), base.darkened(0.22))
		draw_colored_polygon(PackedVector2Array([right, mid, bottom]), base.darkened(0.38))
		draw_polyline(PackedVector2Array([top, right, bottom, left, top]), base.darkened(0.55), 1.5, true)
		var font := get_theme_default_font()
		var fs := 17
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var col := Color.WHITE if tens else Color(0.1, 0.12, 0.18)
		draw_string(font, Vector2((w - ts.x) / 2.0, h * 0.52 + fs * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.94), UiTheme.LINE, 10, 10))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)
	_title = UiTheme.label("", 13, UiTheme.MUTED)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_rows = VBoxContainer.new()
	box.add_child(_rows)
	_sum = UiTheme.label("", 15)
	_sum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_sum)
	tooltip_text = "Klicken zum Ausblenden"
	visible = false
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			visible = false)


func show_roll(roll: Dictionary, label_text: String) -> void:
	_roll_id += 1
	var my_id := _roll_id
	visible = true
	_title.text = label_text
	UiTheme.clear(_rows)
	_sum.text = ""
	var dice: Array = roll.dice
	for i in dice.size():
		var p: Dictionary = dice[i]
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		var sign_l := UiTheme.label("" if i == 0 else ("−" if roll.rolls[i] < 0 else "+"), 18, UiTheme.MUTED)
		sign_l.custom_minimum_size.x = 14
		var dt := Die.new(true)
		var d1 := Die.new(false)
		var val := UiTheme.label("", 15)
		val.custom_minimum_size.x = 64
		row.add_child(sign_l)
		row.add_child(_slot(dt))
		row.add_child(_slot(d1))
		row.add_child(val)
		_rows.add_child(row)
		# Rollen: Ziffern wechseln, Würfel wackeln
		var end_ms := Time.get_ticks_msec() + int((TUMBLE if i == 0 else TUMBLE_NEXT) * 1000.0)
		while Time.get_ticks_msec() < end_ms:
			dt.text = "%02d" % (_rng.randi_range(0, 9) * 10)
			d1.text = str(_rng.randi_range(0, 9))
			dt.rotation = _rng.randf_range(-0.7, 0.7)
			d1.rotation = _rng.randf_range(-0.7, 0.7)
			dt.queue_redraw()
			d1.queue_redraw()
			await get_tree().create_timer(0.05).timeout
			if my_id != _roll_id:
				return
		dt.rotation = 0.0
		d1.rotation = 0.0
		dt.text = "%02d" % (p.t * 10)
		d1.text = str(p.o)
		dt.queue_redraw()
		d1.queue_redraw()
		val.text = "= %d" % p.v
		if p.v >= 96:
			val.add_theme_color_override("font_color", UiTheme.GOOD)
		elif p.v <= 5 and i == 0:
			val.add_theme_color_override("font_color", UiTheme.BAD)
		await get_tree().create_timer(0.15).timeout
	if roll.fumble:
		_sum.text = "Patzer!"
		_sum.add_theme_color_override("font_color", UiTheme.BAD)
	elif dice.size() > 1:
		_sum.text = "Offener Wurf: %d" % roll.total
		_sum.add_theme_color_override("font_color", UiTheme.GOOD if roll.total > roll.first else UiTheme.BAD)
	else:
		_sum.text = "Wurf: %d" % roll.total
		_sum.add_theme_color_override("font_color", UiTheme.TEXT)


## Halter, damit der Container die Drehung des Würfels nicht zurücksetzt
func _slot(d: Control) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(46, 52)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(d)
	return s
