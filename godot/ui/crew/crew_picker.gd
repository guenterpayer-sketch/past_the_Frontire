class_name CrewPicker
extends Modal
## Neues Spiel: Crew aus dem globalen Roster wählen (1 bis seats Figuren, jede höchstens einmal).
## „Neue Figur“ erschafft eine Figur direkt in den Roster. picked liefert die Roster-Einträge;
## der Aufrufer legt das Spiel mit Campaign.new_game(picked) an.

signal picked(chars: Array[Character])

var seats := Campaign.START_SEATS
var editor: CharacterEditor
var _entries: Array[Character] = []
var _chosen: Array[StringName] = []
var _grid: HFlowContainer
var _side: VBoxContainer
var _start: Button


func _ready() -> void:
	super()
	editor = CharacterEditor.new()
	add_child(editor)
	editor.saved.connect(func(ch: Character, _r: Character) -> void:
		var c := GlobalRoster.add(ch)
		_entries = GlobalRoster.entries()
		if _chosen.size() < seats:
			_chosen.append(c.id)
		_render())


## Auswahl öffnen; subtitle z. B. „Spielstand Frontire · Slot 2“; vorgewählt sind die Startcharaktere
func open_pick(subtitle := "", seat_count := Campaign.START_SEATS) -> void:
	seats = seat_count
	_entries = GlobalRoster.entries()
	_chosen = []
	for c in _entries:
		if GlobalRoster.is_protected(c) and _chosen.size() < mini(seats, Campaign.MAX_SQUAD):
			_chosen.append(c.id)
	open("Neues Spiel – Crew wählen")
	var intro := UiTheme.label("%sWähle 1 bis %d Figuren aus dem Roster. Bis zu %d gehen in einen Einsatz, der Rest ist Reserve. Im Spiel entwickeln sich Kopien weiter." % [
		(subtitle + ". ") if subtitle != "" else "", seats, Campaign.MAX_SQUAD], 13, UiTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 18)
	content.add_child(cols)
	_grid = HFlowContainer.new()
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	cols.add_child(_grid)
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = 330
	cols.add_child(_side)
	add_close("Zurück")
	_start = UiTheme.button("Spiel starten")
	_start.add_theme_color_override("font_color", UiTheme.ACCENT)
	_start.pressed.connect(func() -> void:
		var out: Array[Character] = []
		for id in _chosen:
			for c in _entries:
				if c.id == id:
					out.append(c)
		hide()
		picked.emit(out))
	footer.add_child(_start)
	_render()


func _toggle(id: StringName) -> void:
	if id in _chosen:
		_chosen.erase(id)
	elif _chosen.size() < seats:
		_chosen.append(id)
	_render()


func _render() -> void:
	UiTheme.clear(_grid)
	UiTheme.clear(_side)
	for c in _entries:
		var on := c.id in _chosen
		var b := CrewWidgets.card(c, ("✓ gewählt · " if on else "") + c.role, true)
		b.button_pressed = on
		b.disabled = not on and _chosen.size() >= seats
		b.pressed.connect(_toggle.bind(c.id))
		_grid.add_child(b)
	var nb := UiTheme.button("+ Neue Figur (Roster)", "Neue Figur erschaffen; sie kommt in den Roster und gleich in die Auswahl")
	nb.custom_minimum_size = Vector2(210, 52)
	nb.add_theme_color_override("font_color", UiTheme.ACCENT)
	nb.pressed.connect(func() -> void:
		editor.open_for_roster()
		editor.move_to_front())
	_grid.add_child(nb)

	_side.add_child(UiTheme.label("Plätze an Bord", 13, UiTheme.MUTED))
	_side.add_child(UiTheme.label("%d / %d" % [_chosen.size(), seats], 22, UiTheme.ACCENT))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 4)
	for i in seats:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(28, 10)
		r.color = UiTheme.GOOD if i < mini(_chosen.size(), Campaign.MAX_SQUAD) else (UiTheme.CREW if i < _chosen.size() else UiTheme.PANEL2)
		bar.add_child(r)
	_side.add_child(bar)
	for id in _chosen:
		for c in _entries:
			if c.id == id:
				var row := HBoxContainer.new()
				row.add_child(UiTheme.badge(c.letter, c.color, 24))
				var l := UiTheme.label(c.name, 13)
				l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row.add_child(l)
				var x := UiTheme.button("entfernen")
				x.add_theme_font_size_override("font_size", 12)
				x.pressed.connect(_toggle.bind(c.id))
				row.add_child(x)
				_side.add_child(row)
	var note := UiTheme.label("Jede Roster-Figur höchstens einmal. Welche %d in einen Einsatz gehen, wird vor jedem Einsatz gewählt." % Campaign.MAX_SQUAD, 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(note)
	_start.disabled = _chosen.is_empty()
