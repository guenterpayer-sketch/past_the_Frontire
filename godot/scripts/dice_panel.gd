extends PanelContainer
## Würfelanzeige: zwei W10 (rot = Zehner, weiß = Einer) rollen, Nachwürfe darunter.
## Bleibt stehen, bis man draufklickt oder der nächste Wurf kommt.

const TUMBLE := 0.5
const TUMBLE_NEXT := 0.38

var title: Label
var rows: VBoxContainer
var sum_label: Label
var rng := RandomNumberGenerator.new()
var roll_id := 0


## Ein W10 von vorne: Drachenform mit zwei schattierten unteren Flächen
class Die extends Control:
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
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.92)
	sb.border_color = Color(0.17, 0.21, 0.31)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(10)
	add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(box)
	title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.51, 0.57, 0.68))
	box.add_child(title)
	rows = VBoxContainer.new()
	box.add_child(rows)
	sum_label = Label.new()
	sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sum_label.add_theme_font_size_override("font_size", 15)
	box.add_child(sum_label)
	tooltip_text = "Klicken zum Ausblenden"
	visible = false
	gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			visible = false)


func show_roll(roll: Dictionary, label_text: String) -> void:
	roll_id += 1
	var my_id := roll_id
	visible = true
	title.text = label_text
	for c in rows.get_children():
		c.queue_free()
	sum_label.text = ""
	var dice: Array = roll.dice
	for i in dice.size():
		var p: Dictionary = dice[i]
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		var sign_l := Label.new()
		sign_l.custom_minimum_size.x = 14
		sign_l.text = "" if i == 0 else ("−" if roll.rolls[i] < 0 else "+")
		var dt := Die.new(true)
		var d1 := Die.new(false)
		var val := Label.new()
		val.custom_minimum_size.x = 64
		row.add_child(sign_l)
		row.add_child(_slot(dt))
		row.add_child(_slot(d1))
		row.add_child(val)
		rows.add_child(row)
		# Rollen: Ziffern wechseln, Würfel wackeln
		var end_ms := Time.get_ticks_msec() + int((TUMBLE if i == 0 else TUMBLE_NEXT) * 1000.0)
		while Time.get_ticks_msec() < end_ms:
			dt.text = "%02d" % (rng.randi_range(0, 9) * 10)
			d1.text = str(rng.randi_range(0, 9))
			dt.rotation = rng.randf_range(-0.7, 0.7)
			d1.rotation = rng.randf_range(-0.7, 0.7)
			dt.queue_redraw()
			d1.queue_redraw()
			await get_tree().create_timer(0.05).timeout
			if my_id != roll_id:
				return
		dt.rotation = 0.0
		d1.rotation = 0.0
		dt.text = "%02d" % (p.t * 10)
		d1.text = str(p.o)
		dt.queue_redraw()
		d1.queue_redraw()
		val.text = "= %d" % p.v
		if p.v >= 96:
			val.add_theme_color_override("font_color", Color(0.48, 0.89, 0.55))
		elif p.v <= 5 and i == 0:
			val.add_theme_color_override("font_color", Color(1, 0.48, 0.48))
		await get_tree().create_timer(0.15).timeout
	if roll.fumble:
		sum_label.text = "Patzer!"
		sum_label.add_theme_color_override("font_color", Color(1, 0.42, 0.42))
	elif dice.size() > 1:
		sum_label.text = "Offener Wurf: %d" % roll.total
		sum_label.add_theme_color_override("font_color", Color(0.48, 0.89, 0.55) if roll.total > roll.first else Color(1, 0.42, 0.42))
	else:
		sum_label.text = "Wurf: %d" % roll.total
		sum_label.remove_theme_color_override("font_color")


## Halter, damit der Container die Drehung des Würfels nicht zurücksetzt
func _slot(d: Control) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(46, 52)
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.add_child(d)
	return s
