class_name SlotsDialog
extends Modal
## Spielstände: SaveSlots.COUNT Slots mit Name, Tag, System, Einsätzen und Speicherzeit.
## Modus &"save" (im Schiff), &"load" (Startmenü oder Schiff) oder &"new" (Neues Spiel: Slot wählen und benennen).

signal saved(slot: int)
signal loaded(slot: int)
signal new_game(slot: int, name: String)

var mode := &"load"
## im Schiff zwischen Speichern und Laden umschalten
var can_switch := false


func _ready() -> void:
	max_size = Vector2(760, 620)
	super._ready()


func show_slots(m: StringName, switchable := false) -> void:
	mode = m
	can_switch = switchable
	open({&"save": "Spielstand speichern", &"load": "Spielstand laden", &"new": "Neues Spiel – Slot wählen"}[mode])
	if can_switch:
		var tabs := HBoxContainer.new()
		tabs.add_theme_constant_override("separation", 6)
		for t in [[&"save", "Speichern"], [&"load", "Laden"]]:
			var b := UiTheme.button(t[1], "", true)
			b.button_pressed = mode == t[0]
			b.pressed.connect(show_slots.bind(t[0], true))
			tabs.add_child(b)
		content.add_child(tabs)
	for s in range(1, SaveSlots.COUNT + 1):
		content.add_child(_slot_row(s))
	var note := UiTheme.label("Gespeichert wird nur im Schiff, nicht während eines Einsatzes." if mode != &"new"
		else "Ein neues Spiel beginnt mit einem neuen Sektor und der Crew auf Anfang; der Slot wird sofort belegt.", 13, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)
	add_close()


func _slot_row(s: int) -> Control:
	var info := SaveSlots.info(s)
	var empty := info.is_empty()
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	card.add_child(row)
	var num := UiTheme.label(str(s), 28, UiTheme.ACCENT if not empty else UiTheme.MUTED)
	num.custom_minimum_size.x = 28
	row.add_child(num)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 2)
	row.add_child(v)
	var name_edit: LineEdit = null
	if mode == &"load":
		if empty:
			v.add_child(UiTheme.label("leer", 15, UiTheme.MUTED))
		else:
			_describe(v, info)
	else:
		if not empty:
			_describe(v, info)
		name_edit = LineEdit.new()
		name_edit.placeholder_text = "Name des Spielstands"
		name_edit.text = info.get("name", "") if not empty else (HubState.game.slot_name if mode == &"save" and HubState.game else "")
		if name_edit.text == "":
			name_edit.text = "Spielstand %d" % s
		name_edit.custom_minimum_size.y = 34
		v.add_child(name_edit)
	var b: Button
	match mode:
		&"load":
			b = UiTheme.button("Laden")
			b.disabled = empty
			b.pressed.connect(func() -> void:
				hide()
				loaded.emit(s))
		&"save":
			b = UiTheme.button("Hier speichern" if empty else "Überschreiben")
			b.pressed.connect(func() -> void:
				if empty:
					_save(s, name_edit.text)
				else:
					_confirm("Spielstand %d „%s“ überschreiben?" % [s, info.name], _save.bind(s, name_edit)))
		&"new":
			b = UiTheme.button("Hier beginnen")
			b.pressed.connect(func() -> void:
				if empty:
					_new(s, name_edit.text)
				else:
					_confirm("Spielstand %d „%s“ wird durch das neue Spiel ersetzt. Fortfahren?" % [s, info.name], _new.bind(s, name_edit)))
	b.custom_minimum_size = Vector2(150, 44)
	b.add_theme_color_override("font_color", UiTheme.ACCENT)
	row.add_child(b)
	return card


func _describe(v: VBoxContainer, info: Dictionary) -> void:
	v.add_child(UiTheme.label(info.name if info.name != "" else "(ohne Namen)", 16))
	v.add_child(UiTheme.label("Tag %d · %s · %d %s" % [info.day, info.system, info.missions, "Einsatz" if info.missions == 1 else "Einsätze"], 13))
	v.add_child(UiTheme.label("gespeichert %s" % Time.get_datetime_string_from_unix_time(info.saved_at + _tz_bias(), true), 12, UiTheme.MUTED))


func _tz_bias() -> int:
	return int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func _save(s: int, name_v: Variant) -> void:
	var n := _name_of(name_v, s)
	if HubState.game and SaveSlots.save(s, n, HubState.game):
		Sfx.play(&"klick")
		saved.emit(s)
	show_slots(mode, can_switch)


func _new(s: int, name_v: Variant) -> void:
	hide()
	new_game.emit(s, _name_of(name_v, s))


func _name_of(v: Variant, s: int) -> String:
	var n: String = (v as LineEdit).text if v is LineEdit else String(v)
	n = n.strip_edges()
	return n if n != "" else "Spielstand %d" % s


func _confirm(text: String, then: Callable) -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = text
	d.ok_button_text = "Ja"
	d.cancel_button_text = "Abbrechen"
	add_child(d)
	d.confirmed.connect(then)
	d.popup_centered()
