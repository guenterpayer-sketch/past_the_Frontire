class_name StoryLog
extends Modal
## Logbuch der Story (Mockup 19.10.2026, Gestaltung wie die Enzyklopädie): links die Bereiche mit Anzahl,
## rechts Überschrift und Karten (Aufträge, Hinweise, Ziele mit Balken und Frist, Verlauf); lange Listen scrollen.

const NAME := "StoryLog"
const TABS := ["Aufträge", "Hinweise", "Ziele", "Verlauf"]
const EMPTY := ["Keine offenen Aufträge.", "Noch keine Hinweise.", "Noch keine Ziele.", "Noch nichts geschehen."]

var story: Story
var tab := 0
var _side: VBoxContainer
var _list: VBoxContainer
var _intro: Label


static func show_on(parent: Node, s: Story, tab_index := 0) -> StoryLog:
	var d := parent.get_node_or_null(NAME) as StoryLog
	if d == null:
		d = StoryLog.new()
		d.name = NAME
		parent.add_child(d)
	d.show_log(s, tab_index)
	return d


func _ready() -> void:
	super._ready()
	max_size = Vector2(1180, 760)


func show_log(s: Story, tab_index := 0) -> void:
	story = s
	tab = tab_index
	open("Logbuch")
	_intro = UiTheme.label("Tag %d. Story-Aufträge haben kein Zeitlimit, Fristen gelten nur für Ziele. Hinweise sammeln sich hier." % story.today(), 13, UiTheme.MUTED)
	_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_intro)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(row)
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = 230
	row.add_child(_side)
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.x = 1
	row.add_child(sep)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_list)
	add_close()
	_fill()


func _counts() -> Array[int]:
	var goals := 0
	for g in story.state.goals.values():
		if not g.done:
			goals += 1
	return [story.open_chains().size(), story.state.entries("hinweis").size(), goals, story.state.entries("verlauf").size()]


func _fill() -> void:
	UiTheme.clear(_side)
	UiTheme.clear(_list)
	var counts := _counts()
	_side.add_child(StoryDialog.section("Logbuch"))
	var group := ButtonGroup.new()
	for i in TABS.size():
		var b := UiTheme.button("%s   (%d)" % [TABS[i], counts[i]], "", true)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 34
		b.add_theme_font_size_override("font_size", 14)
		b.button_group = group
		b.button_pressed = i == tab
		b.pressed.connect(func() -> void:
			tab = i
			_fill())
		_side.add_child(b)
	var head := UiTheme.label(TABS[tab], 22)
	_list.add_child(head)
	match tab:
		0: _chains()
		1: _entries("hinweis")
		2: _goals()
		3: _entries("verlauf")
	if _list.get_child_count() == 1:
		_list.add_child(UiTheme.label(EMPTY[tab], 14, UiTheme.MUTED))


## Karte: Titel, Unterzeile (grau), Text; gibt den Inhalt zurück
func _card(title: String, sub: String, text := "", title_color := UiTheme.TEXT) -> VBoxContainer:
	var v := StoryDialog.card()
	var t := UiTheme.label(title, 15, title_color)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	if sub != "":
		v.add_child(UiTheme.label(sub, 13, UiTheme.MUTED))
	if text != "":
		var l := UiTheme.label(text, 14)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	_list.add_child(v.get_parent())
	return v


func _chains() -> void:
	for c in story.open_chains():
		var kind: String = StoryDialog.KIND_NAMES.get(c.kind, c.kind)
		var status: String = {"aktiv": "läuft", "wartet": "Einsatz offen"}.get(c.status, _where(c))
		var v := _card(c.title, "%s · %s · ohne Zeitlimit" % [kind, status], _summary(c.chain), StoryDialog.STORY_COLOR)
		if c.reason != "":
			v.add_child(UiTheme.label(c.reason, 13, UiTheme.BAD))


## wo ein bekannter Schritt wartet (Kontakt, Story-Ort, Auftragsliste, unterwegs)
func _where(c: Dictionary) -> String:
	var at := story.place_label(c.place)
	match String(c.trigger):
		"kontakt":
			return "Kontakt im Raumhafen" + (": " + at if at != "" else "")
		"ort":
			return "Story-Ort" + (": " + at if at != "" else " auf der Sternenkarte")
		"auftrag":
			return "Auftrag auf der Brücke"
		"reise":
			return "meldet sich unterwegs"
	return "bekannt"


## Beschreibung eines Auftrags: letzter Hinweis der Kette, sonst die aktuelle Szene
func _summary(id: String) -> String:
	var hints := story.state.entries("hinweis").filter(func(e: Dictionary) -> bool: return e.chain == id)
	if not hints.is_empty():
		return hints[-1].text
	var sc := story.scene_of(id, story.current_scene_id(id))
	if not sc.is_empty():
		return "Aktuell: %s" % story.text_of(sc.get("title", ""))
	return ""


func _entries(kind: String) -> void:
	var list := story.state.entries(kind)
	list.reverse()
	for e in list:
		var c := story.chain_of(String(e.chain))
		_card(e.text, "Tag %d · %s" % [e.day, story.text_of(c.get("title", e.chain))])


## je Ziel eine Karte: Name, Stand, Balken, Frist (rot, wenn höchstens 2 Tage übrig)
func _goals() -> void:
	for gid in story.state.goals:
		var g: Dictionary = story.state.goals[gid]
		var c := story.chain_of(String(g.chain))
		var v := _card(g.name + ("  ✓ erreicht" if g.done else ""), story.text_of(c.get("title", g.chain)), "", UiTheme.GOOD if g.done else UiTheme.TEXT)
		if int(g.target) > 0:
			var h := HBoxContainer.new()
			var bar := ProgressBar.new()
			bar.max_value = g.target
			bar.value = mini(int(g.value), int(g.target))
			bar.show_percentage = false
			bar.custom_minimum_size.y = 8
			bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(bar)
			h.add_child(UiTheme.label("%d / %d" % [g.value, g.target], 14, UiTheme.MUTED))
			v.add_child(h)
		if int(g.due) > 0:
			var left := int(g.due) - story.today()
			v.add_child(UiTheme.label("Frist: Tag %d (in %d Tagen)" % [g.due, left], 13, UiTheme.BAD if left <= 2 else UiTheme.MUTED))
