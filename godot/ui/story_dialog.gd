class_name StoryDialog
extends Modal
## Szenenfenster der Story (Mockup 19.10.2026, Gestaltung wie Feindkontakt und Krankenstation):
## Titel, Zeile mit Art und Kette, oben Bild und Szenentext (scrollt, wenn lang) mit den Zielen der Kette,
## darunter WAHL: je Wahl eine Karte mit Beschreibung (Probe oder fehlende Bedingung) und Knopf.
## Wahl mit Probe: in der Karte „Wer würfelt?“ mit der Crew (Bester vorausgewählt), dann „Würfeln“.

signal finished(chain_id: String)

const NAME := "StoryDialog"
## Bilder der Szenen (Prompts in docs/Planung_Story.md, Abschnitt „Bilder“)
const ART_DIR := "res://art/story"
const KIND_NAMES := {"haupt": "Hauptstrang", "kette": "Kette"}
const STORY_COLOR := UiTheme.RETREAT
const IMAGE_SIZE := Vector2(300, 200)
## höchste Höhe des Szenentexts, darüber Scrollbalken
const TEXT_MAX := 200.0

var story: Story
var chain_id := ""
## gewählte Wahl mit Probe, wartet auf den Würfler
var _pending := -1
var _roller: Character
var _sub: Label


static func show_on(parent: Node, s: Story, id: String) -> StoryDialog:
	var d := parent.get_node_or_null(NAME) as StoryDialog
	if d == null:
		d = StoryDialog.new()
		d.name = NAME
		parent.add_child(d)
	d.show_chain(s, id)
	return d


## Abschnittsüberschrift wie in den Schiffsdialogen (KOCH, PATIENTEN …)
static func section(text: String) -> Label:
	return UiTheme.label(text.to_upper(), 13, UiTheme.MUTED)


## Fließtext: wächst mit dem Inhalt bis max_h, darüber Scrollbalken
static func text_block(text: String, size := 16, max_h := TEXT_MAX) -> RichTextLabel:
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.text = text
	t.scroll_active = true
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.add_theme_font_size_override("normal_font_size", size)
	t.add_theme_constant_override("line_separation", 3)
	t.custom_minimum_size.y = 24
	t.finished.connect(func() -> void: t.custom_minimum_size.y = clampf(t.get_content_height() + 4, 24, max_h))
	return t


## Karte wie beim Feindkontakt (PANEL2, Rahmen); gibt den Inhalt zurück
static func card() -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	return v


## Knopf mit goldener Schrift (Aktion), wie „Ausweichen versuchen“
static func action_button(text: String) -> Button:
	var b := UiTheme.button(text)
	b.add_theme_color_override("font_color", UiTheme.ACCENT)
	b.custom_minimum_size = Vector2(150, 34)
	return b


## Bildbereich: Bild der Szene oder Platzhalter
static func image_box(image: String) -> Control:
	var frame := PanelContainer.new()
	frame.custom_minimum_size = IMAGE_SIZE
	frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	frame.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 0))
	var path := ART_DIR.path_join(image + ".png")
	if image != "" and ResourceLoader.exists(path):
		var tex := TextureRect.new()
		tex.texture = load(path)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		frame.add_child(tex)
		return frame
	var l := UiTheme.label("Bild folgt", 13, UiTheme.MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	frame.add_child(l)
	return frame


func _ready() -> void:
	super._ready()
	max_size = Vector2(1100, 760)
	closable = false
	_sub = UiTheme.label("", 15, STORY_COLOR)
	var v := title_bar.get_parent()
	v.add_child(_sub)
	v.move_child(_sub, title_bar.get_index() + 1)


func show_chain(s: Story, id: String) -> void:
	story = s
	chain_id = id
	_pending = -1
	_render()


func _header(v: Dictionary) -> void:
	open(v.title)
	_sub.text = "%s · %s · Tag %d" % [KIND_NAMES.get(v.kind, v.kind), v.chain_title, story.today()]
	content.add_theme_constant_override("separation", 10)


func _render() -> void:
	var v := story.view(chain_id)
	if v.is_empty():
		_finish()
		return
	_header(v)
	content.add_child(_scene_row(v.text, v.image))
	content.add_child(section("Wahl"))
	for c in v.choices:
		content.add_child(_choice_card(c).get_parent())
	_footer_log()


func _scene_row(text: String, image: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.add_child(image_box(image))
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(text_block(text))
	var goals := _goal_rows()
	if goals != null:
		right.add_child(goals)
	row.add_child(right)
	return row


## ZIELE der Kette: Name, Stand, Frist (rot, wenn höchstens 2 Tage übrig)
func _goal_rows() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	for gid in story.state.goals:
		var g: Dictionary = story.state.goals[gid]
		if g.chain != chain_id or g.done:
			continue
		if v.get_child_count() == 0:
			var gap := Control.new()
			gap.custom_minimum_size.y = 4
			v.add_child(gap)
			v.add_child(section("Ziele"))
		var h := HBoxContainer.new()
		h.add_child(UiTheme.label(g.name, 14))
		if int(g.target) > 0:
			h.add_child(UiTheme.label("%d / %d" % [g.value, g.target], 14, UiTheme.MUTED))
		if int(g.due) > 0:
			var left := int(g.due) - story.today()
			h.add_child(UiTheme.label("· Frist Tag %d (in %d Tagen)" % [g.due, left], 14, UiTheme.BAD if left <= 2 else UiTheme.MUTED))
		v.add_child(h)
	return v if v.get_child_count() > 0 else null


## Karte einer Wahl: Titel, Beschreibung, Knopf rechts; bei laufender Probe die Würfler-Auswahl
func _choice_card(c: Dictionary) -> VBoxContainer:
	var v := card()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	v.add_child(h)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 2)
	h.add_child(left)
	var t := UiTheme.label(c.text, 15, UiTheme.TEXT if c.enabled else Color(UiTheme.MUTED, 0.7))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(t)
	var desc := ""
	if not c.enabled:
		desc = c.reason
	elif not c.check.is_empty():
		desc = "Probe %s (%s)" % [c.check.skill_name, c.check.diff_name.to_lower()]
	if desc != "":
		left.add_child(UiTheme.label(desc, 13, UiTheme.MUTED if c.enabled else UiTheme.BAD))
	var b := action_button("Probe ablegen" if not c.check.is_empty() else "Wählen")
	b.disabled = not c.enabled or (_pending >= 0 and _pending != c.index)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(_on_choice.bind(c))
	h.add_child(b)
	if c.index == _pending:
		b.hide()
		_roller_rows(v, c)
	return v


func _on_choice(c: Dictionary) -> void:
	if c.check.is_empty():
		_show_result(story.choose(chain_id, c.index))
		return
	_pending = c.index
	_roller = null
	_render()


## „Wer würfelt?“: Crew nach Gesamtbonus (Bester vorausgewählt), dann Würfeln oder Abbrechen
func _roller_rows(v: VBoxContainer, c: Dictionary) -> void:
	v.add_child(UiTheme.label("Wer würfelt?  %s, Gesamtbonus:" % c.check.skill_name, 13, UiTheme.CREW))
	var opts := story.roller_options(c.check.skill)
	if _roller == null and not opts.is_empty():
		_roller = opts[0].ch
	var group := ButtonGroup.new()
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	for o in opts:
		flow.add_child(_roller_button(o, group))
	v.add_child(flow)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	var back := UiTheme.button("Abbrechen")
	back.custom_minimum_size.y = 34
	back.pressed.connect(func() -> void:
		_pending = -1
		_render())
	row.add_child(back)
	var roll := action_button("Würfeln")
	roll.pressed.connect(func() -> void:
		var idx := _pending
		_pending = -1
		_show_result(story.choose(chain_id, idx, _roller)))
	row.add_child(roll)
	v.add_child(row)


## Würfler-Knopf: Buchstabenkästchen in der Figurenfarbe, Name, Bonus
func _roller_button(o: Dictionary, group: ButtonGroup) -> Button:
	var ch: Character = o.ch
	var b := UiTheme.button("", "", true)
	b.button_group = group
	b.button_pressed = ch == _roller
	b.custom_minimum_size = Vector2(190, 34)
	var h := HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 6
	h.offset_right = -8
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(h)
	var badge := UiTheme.badge(ch.letter if ch.letter != "" else ch.name.left(1), ch.color, 22)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(badge)
	var n := UiTheme.label(ch.name, 14)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(n)
	h.add_child(UiTheme.label("%+d" % o.total, 14, UiTheme.MUTED))
	for x in h.get_children():
		(x as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.pressed.connect(func() -> void: _roller = ch)
	return b


func _show_result(r: Dictionary) -> void:
	if not r.get("ok", false):
		_render()
		return
	var v := story.view(chain_id) if story.state.status(chain_id) == "aktiv" else {}
	UiTheme.clear(content)
	UiTheme.clear(footer)
	content.add_child(section("Ergebnis"))
	var box := card()
	if not r.check.is_empty():
		var good := String(r.check.result) in ["erfolg", "herausragend"]
		box.add_child(UiTheme.label("%s: Probe %s, %s" % [r.check.name, Rules.skill_name(r.check.skill), r.check.result_name], 16,
			UiTheme.GOOD if good else UiTheme.BAD))
		var line := "W100 %s %+d = %d" % [Dice.format_roll(r.check.roll), r.check.bonus, r.check.total]
		if int(r.check.xp) > 0:
			line += " · +%d EP auf %s" % [r.check.xp, Rules.skill_name(r.check.skill)]
		box.add_child(UiTheme.label(line, 13, UiTheme.MUTED))
	if r.text != "":
		box.add_child(text_block(r.text, 15))
	if not r.effects.is_empty():
		box.add_child(UiTheme.label(" · ".join(PackedStringArray(r.effects)), 13, UiTheme.MUTED))
	if not r.mission.is_empty():
		box.add_child(UiTheme.label("Einsatz: %s" % r.mission.get("title", ""), 15, UiTheme.ACCENT))
	if box.get_child_count() > 0:
		content.add_child(box.get_parent())
	else:
		box.get_parent().queue_free()
	var open_chain := not v.is_empty()
	_footer_log()
	var b := action_button("Weiter" if open_chain else "Schließen")
	b.custom_minimum_size = Vector2(0, 0)
	b.pressed.connect(_render if open_chain else _finish)
	footer.add_child(b)


func _footer_log() -> void:
	var b := UiTheme.button("Logbuch")
	b.pressed.connect(func() -> void: StoryLog.show_on(get_parent(), story))
	footer.add_child(b)


func _finish() -> void:
	close()
	finished.emit(chain_id)
