class_name TopMenu
extends PanelContainer
## Oben rechts: Runde, Auftrag und Symbolknöpfe (Charakterbogen, Tabellen, KI für Crew, Ton, Würfel, Menü).
## Meldet Bedienung über action(name, arg) wie die übrige Oberfläche.

signal action(name: StringName, arg: Variant)

const MENU := [[&"new", "Neue Mission"], [&"grid", "Hexraster ein/aus (G)"], [&"range", "Reichweite zeigen (R)"], [&"help", "Bedienung"]]

var round_label: Label
var mission_label: Label
var toggles := {}
var _popup: PopupMenu


func _ready() -> void:
	add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	add_child(row)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size.x = 150
	round_label = UiTheme.label("Runde 0", 16, UiTheme.ACCENT)
	mission_label = UiTheme.label("", 12, UiTheme.MUTED)
	mission_label.clip_text = true
	mission_label.custom_minimum_size.x = 150
	mission_label.mouse_filter = Control.MOUSE_FILTER_PASS
	col.add_child(round_label)
	col.add_child(mission_label)
	row.add_child(col)
	for spec in [[&"sheet", &"person", "Charakterbogen", false], [&"tables", &"table", "Tabellen", false],
			[&"auto", &"chip", "KI für Crew (zuschauen)", true], [&"sound", &"speaker", "Ton an/aus", true],
			[&"dice", &"dice", "Würfelanimation an/aus (2 W10: rot = Zehner, weiß = Einer)", true]]:
		var b := IconButton.new(spec[1], spec[2], spec[3])
		b.pressed.connect(func() -> void: action.emit(spec[0], b.button_pressed))
		row.add_child(b)
		if spec[3]:
			toggles[spec[0]] = b
	# Menü als MenuButton (Godot setzt das Aufklappmenü selbst richtig), Symbol: drei Striche
	var menu := MenuButton.new()
	menu.tooltip_text = "Menü: Neue Mission, Raster, Reichweite, Bedienung"
	menu.custom_minimum_size = Vector2(44, 44)
	menu.focus_mode = Control.FOCUS_NONE
	menu.flat = false
	var popup := menu.get_popup()
	_popup = popup
	for i in MENU.size():
		popup.add_item(MENU[i][1], i)
	popup.add_theme_font_size_override("font_size", 15)
	popup.id_pressed.connect(func(id: int) -> void: action.emit(MENU[id][0], null))
	menu.draw.connect(func() -> void:
		var o := menu.size / 2.0
		for y in [-6.0, 0.0, 6.0]:
			menu.draw_line(o + Vector2(-8, y), o + Vector2(8, y), UiTheme.TEXT, 2.0, true))
	row.add_child(menu)


## Text eines Menüeintrags ändern (z. B. „Neue Mission“ im Einsatz aus dem Schiff)
func set_menu_text(id: StringName, text: String) -> void:
	for i in MENU.size():
		if MENU[i][0] == id:
			_popup.set_item_text(_popup.get_item_index(i), text)


func set_round(text: String) -> void:
	round_label.text = text


func set_mission(short: String, full: String) -> void:
	mission_label.text = short
	mission_label.tooltip_text = full


func set_toggle(name: StringName, on: bool, tip := "") -> void:
	var b: Button = toggles[name]
	b.set_pressed_no_signal(on)
	if tip != "":
		b.tooltip_text = tip
	b.queue_redraw()
