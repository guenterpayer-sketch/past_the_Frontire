class_name InitiativeBar
extends HBoxContainer
## Initiative-Reihenfolge als Leiste oben über der Karte. Klick: Kamera zur Figur; "einspringen" für Wartende.

signal focus_unit(u: Combatant)
signal jump(u: Combatant)


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func refresh(c: Combat, is_ai: Callable) -> void:
	UiTheme.clear(self)
	for i in c.order.size():
		var o: Combatant = c.order[i]
		var chip := PanelContainer.new()
		var now := i == c.turn_idx
		var bg := Color("3a3215") if now else Color(UiTheme.PANEL, 0.88)
		chip.add_theme_stylebox_override("panel", UiTheme.box(bg, UiTheme.ACCENT if now else UiTheme.LINE, 6, 3))
		if not o.is_ok():
			chip.modulate.a = 0.35
		elif i < c.turn_idx:
			chip.modulate.a = 0.55
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		chip.add_child(row)
		row.add_child(UiTheme.badge(o.letter, o.color, 20))
		var st := ("◎" if o.has_overwatch() else "") + ("▾" if o.crouched else "")
		var name_text := (o.name.split(" ")[0] if now else "") + st
		if name_text != "":
			row.add_child(UiTheme.label(name_text, 12, UiTheme.CREW if o.is_crew else UiTheme.ENEMY))
		if o.waiting:
			if c.jump_queue.has(o):
				row.add_child(UiTheme.label("⤴", 12, UiTheme.ACCENT))
			elif not is_ai.call(o):
				var b := UiTheme.button("einspringen", "Nach dem laufenden Zug einspringen")
				b.add_theme_font_size_override("font_size", 11)
				b.pressed.connect(jump.emit.bind(o))
				row.add_child(b)
			else:
				row.add_child(UiTheme.label("⏸", 12, UiTheme.ACCENT))
		row.add_child(UiTheme.label(str(o.init), 11, UiTheme.MUTED))
		chip.tooltip_text = "%s · Initiative %d (%s)%s" % [o.name, o.init, o.init_roll, " · wartet" if o.waiting else ""]
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				focus_unit.emit(o))
		add_child(chip)
