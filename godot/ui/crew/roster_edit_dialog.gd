class_name RosterEditDialog
extends Modal
## Roster: Name, Kürzel, Farbe und Aussehen einer eigenen Figur ändern (Werte bleiben fest).

signal saved(ch: Character)

var _ch: Character
var _preview: FigurePreview


func _ready() -> void:
	super()
	max_size = Vector2(760, 470)


func edit(ch: Character, title := "Name & Aussehen") -> void:
	_ch = ch.duplicate_character()
	open(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	content.add_child(row)
	_preview = FigurePreview.new()
	row.add_child(_preview)
	var g := GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 10)
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(g)
	g.add_child(UiTheme.label("Name", 13, UiTheme.MUTED))
	var name_edit := LineEdit.new()
	name_edit.text = _ch.name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.add_child(name_edit)
	g.add_child(UiTheme.label("Kürzel", 13, UiTheme.MUTED))
	var letter := LineEdit.new()
	letter.text = _ch.letter
	letter.max_length = 1
	letter.custom_minimum_size.x = 40
	letter.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	g.add_child(letter)
	g.add_child(UiTheme.label("Farbe", 13, UiTheme.MUTED))
	var col := ColorPickerButton.new()
	col.color = _ch.color
	col.edit_alpha = false
	col.custom_minimum_size = Vector2(60, 28)
	col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.popup_closed.connect(func() -> void:
		_ch.color = col.color
		_preview.show_character(_ch))
	g.add_child(col)
	g.add_child(UiTheme.label("Aussehen", 13, UiTheme.MUTED))
	var visuals := FigurePreview.visual_choices()
	var vis := OptionButton.new()
	for i in visuals.size():
		vis.add_item(FigurePreview.visual_name(visuals[i]), i)
	vis.select(maxi(0, visuals.find(_ch.visual)))
	vis.item_selected.connect(func(i: int) -> void:
		_ch.visual = visuals[i]
		_preview.show_character(_ch))
	g.add_child(vis)
	var hint := UiTheme.label("Eigenschaften und Fertigkeiten bleiben fest.", 12, UiTheme.MUTED)
	content.add_child(hint)
	_preview.show_character(_ch)
	add_close("Abbrechen")
	var ok := UiTheme.button("Speichern")
	ok.add_theme_color_override("font_color", UiTheme.ACCENT)
	ok.pressed.connect(func() -> void:
		if name_edit.text.strip_edges() != "":
			_ch.name = name_edit.text.strip_edges()
		if letter.text != "":
			_ch.letter = letter.text.to_upper()
		hide()
		saved.emit(_ch))
	footer.add_child(ok)
