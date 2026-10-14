class_name RosterScreen
extends Control
## Roster (eigene Szene roster.tscn, im Startmenü erreichbar): alle Figuren ansehen, neue erschaffen,
## eigene bearbeiten (Name, Kürzel, Farbe, Aussehen), kopieren, löschen. Startcharaktere sind schreibgeschützt.

## Szene, in die „Zurück“ führt (Startmenü des Hubs)
const BACK_SCENE := "res://start.tscn"

var editor: CharacterEditor
var edit_dialog: RosterEditDialog
var _entries: Array[Character] = []
var _sel := 0
var _left: VBoxContainer
var _right: VBoxContainer
var _preview: FigurePreview


func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	add_child(m)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 16)
	m.add_child(cols)
	var lp := PanelContainer.new()
	lp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(lp)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	lp.add_child(scroll)
	_left = VBoxContainer.new()
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.add_theme_constant_override("separation", 8)
	scroll.add_child(_left)
	var rp := PanelContainer.new()
	rp.custom_minimum_size.x = 440
	cols.add_child(rp)
	_right = VBoxContainer.new()
	_right.add_theme_constant_override("separation", 10)
	rp.add_child(_right)
	_preview = FigurePreview.new()
	_preview.custom_minimum_size = Vector2(400, 300)
	editor = CharacterEditor.new()
	add_child(editor)
	editor.saved.connect(func(ch: Character, _r: Character) -> void:
		GlobalRoster.add(ch)
		_refresh(ch.id))
	edit_dialog = RosterEditDialog.new()
	add_child(edit_dialog)
	edit_dialog.saved.connect(func(ch: Character) -> void:
		GlobalRoster.update(ch)
		_refresh(ch.id))
	_refresh()


func _refresh(select_id: StringName = &"") -> void:
	_entries = GlobalRoster.entries()
	if select_id != &"":
		for i in _entries.size():
			if _entries[i].id == select_id:
				_sel = i
	_sel = clampi(_sel, 0, _entries.size() - 1)
	_render()


func current() -> Character:
	return _entries[_sel] if not _entries.is_empty() else null


func _render() -> void:
	if _preview.get_parent():
		_preview.get_parent().remove_child(_preview)
	UiTheme.clear(_left)
	UiTheme.clear(_right)
	var head := HBoxContainer.new()
	var t := UiTheme.label("Roster", 24, UiTheme.ACCENT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiTheme.label("%d Figuren · gehört keinem Spielstand" % _entries.size(), 13, UiTheme.MUTED))
	_left.add_child(head)
	var intro := UiTheme.label("Hier entstehen neue Figuren. Spiele bekommen Kopien; ihr Fortschritt fließt nicht in den Roster zurück.", 13, UiTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_left.add_child(intro)
	for own in [false, true]:
		_left.add_child(UiTheme.label("Eigene Figuren" if own else "Startcharaktere", 13, UiTheme.MUTED))
		var g := HFlowContainer.new()
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 8)
		for i in _entries.size():
			var ch := _entries[i]
			var prot := GlobalRoster.is_protected(ch)
			if prot == own:
				continue
			var b := CrewWidgets.card(ch, ch.role + (" · geschützt" if prot else ""), true)
			b.button_pressed = i == _sel
			b.pressed.connect(func() -> void:
				_sel = i
				_render())
			g.add_child(b)
		if own:
			var nb := UiTheme.button("+ Neue Figur erschaffen", "Neue Figur nach den Regeln der Erschaffung (docs/Skillsystem.md 7a)")
			nb.custom_minimum_size = Vector2(210, 52)
			nb.add_theme_color_override("font_color", UiTheme.ACCENT)
			nb.pressed.connect(func() -> void:
				editor.open_for_roster()
				editor.move_to_front())
			g.add_child(nb)
		_left.add_child(g)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_left.add_child(spacer)
	var back := UiTheme.button("Zurück zum Startmenü")
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	back.pressed.connect(func() -> void: get_tree().change_scene_to_file(BACK_SCENE))
	_left.add_child(back)
	_render_details()


func _render_details() -> void:
	var ch := current()
	if ch == null:
		return
	var prot := GlobalRoster.is_protected(ch)
	_right.add_child(_preview)
	_preview.show_character(ch)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(UiTheme.badge(ch.letter, ch.color, 34))
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", 0)
	nv.add_child(UiTheme.label(ch.name, 18, UiTheme.CREW))
	nv.add_child(UiTheme.label("%s · %s" % [ch.role, "Startcharakter" if prot else "eigene Figur"], 12, UiTheme.MUTED))
	h.add_child(nv)
	_right.add_child(h)
	_right.add_child(CrewWidgets.summary(ch))
	var row := HBoxContainer.new()
	var edit := UiTheme.button("Name & Aussehen", "Startcharaktere sind schreibgeschützt" if prot else "Name, Kürzel, Farbe und Aussehen ändern")
	edit.disabled = prot
	edit.pressed.connect(func() -> void:
		edit_dialog.edit(ch)
		edit_dialog.move_to_front())
	row.add_child(edit)
	var cp := UiTheme.button("Kopieren", "Exakte Kopie unter neuem Namen; danach Name und Aussehen änderbar")
	cp.pressed.connect(func() -> void:
		var c := GlobalRoster.copy(ch, "%s (Kopie)" % ch.name)
		_refresh(c.id)
		edit_dialog.edit(c, "Kopie: Name & Aussehen")
		edit_dialog.move_to_front())
	row.add_child(cp)
	var del := UiTheme.button("Löschen", "Startcharaktere sind schreibgeschützt" if prot else "Figur aus dem Roster löschen (laufende Spiele behalten ihre Kopie)")
	del.disabled = prot
	del.add_theme_color_override("font_color", UiTheme.BAD)
	del.pressed.connect(_confirm_delete.bind(ch))
	row.add_child(del)
	_right.add_child(row)
	var note := UiTheme.label("Startcharakter: schreibgeschützt. Zum Abwandeln „Kopieren“." if prot else "Werte bleiben fest; änderbar sind Name, Kürzel, Farbe und Aussehen.", 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(note)


func _confirm_delete(ch: Character) -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "„%s“ aus dem Roster löschen?\nLaufende Spiele behalten ihre Kopie." % ch.name
	d.ok_button_text = "Löschen"
	d.cancel_button_text = "Abbrechen"
	add_child(d)
	d.confirmed.connect(func() -> void:
		GlobalRoster.remove(ch.id)
		_refresh())
	d.popup_centered()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		editor.close()
		edit_dialog.close()


func _exit_tree() -> void:
	if _preview and not _preview.is_inside_tree():
		_preview.free()
