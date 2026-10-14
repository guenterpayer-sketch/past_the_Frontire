class_name StarMap
extends Control
## Brücke: Sternenkarte des Sektors (Systeme in Fraktionsfarbe, Sprungrouten mit Reisetagen, Aufträge)
## und rechts das gewählte System mit Route, Ankunftstag und seinen Aufträgen.
## Meldet travel(System) und start(Auftrag); das Schiff (Hub) führt beides aus.

signal travel(system: int)
## im Schiff einen Tag warten
signal wait_day
## im Hafen angeheuert (Crew hat sich geändert)
signal hired(ch: Character)
signal start(offer: Dictionary)
signal closed

const PANEL_W := 420.0
const PICK_R := 28.0

var game: HubState
var selected := -1
var selected_offer := -1      # Auftrags-ID
var _missions := {}           # Auftrags-ID -> Mission (Vorschau)
var _canvas: Control
var _side: VBoxContainer
var _status: Label
var _hover := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_canvas = Control.new()
	_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_canvas.offset_right = -PANEL_W - 24
	_canvas.draw.connect(_draw_map)
	_canvas.gui_input.connect(_map_input)
	_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_canvas)
	# oben links: zurück + Status
	var top := HBoxContainer.new()
	top.position = Vector2(14, 14)
	top.add_theme_constant_override("separation", 10)
	add_child(top)
	var back := UiTheme.button("◀ Zurück ins Schiff")
	back.custom_minimum_size.y = 44
	back.pressed.connect(close)
	top.add_child(back)
	var sp := PanelContainer.new()
	sp.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 10))
	_status = UiTheme.label("", 15)
	sp.add_child(_status)
	top.add_child(sp)
	var wait := UiTheme.button("1 Tag warten", "Tage vergehen auch beim Warten: Aufträge laufen ab, neue kommen dazu")
	wait.custom_minimum_size.y = 44
	wait.pressed.connect(func() -> void: wait_day.emit())
	top.add_child(wait)
	# unten links: Legende
	var leg := PanelContainer.new()
	leg.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 8))
	leg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	leg.position = Vector2(14, 0)
	leg.name = "Legend"
	add_child(leg)
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 14)
	leg.add_child(lrow)
	for f in Mission.all_factions():
		lrow.add_child(UiTheme.label("● " + f.name, 13, f.color))
	lrow.add_child(UiTheme.label("◆ Auftrag", 13, UiTheme.ACCENT))
	lrow.add_child(UiTheme.label("◆ eigenes Schiff", 13, UiTheme.CREW))
	lrow.add_child(UiTheme.label("T = Reisetage je Sprung", 13, UiTheme.MUTED))
	# rechts: gewähltes System
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.97), UiTheme.LINE, 10, 16))
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -PANEL_W - 14
	panel.offset_right = -14
	panel.offset_top = 14
	panel.offset_bottom = -14
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_side = VBoxContainer.new()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.add_theme_constant_override("separation", 10)
	scroll.add_child(_side)
	hide()


func _process(_d: float) -> void:
	var leg: Control = get_node("Legend")
	leg.position.y = size.y - leg.size.y - 14


func open(g: HubState) -> void:
	game = g
	_missions.clear()
	if selected < 0 or selected >= g.sector.systems.size():
		selected = g.position
		var here := g.offers_at(g.position)
		if here.is_empty() and not g.offers.is_empty():
			selected = g.offers[0].system
	show()
	refresh()


func close() -> void:
	hide()
	closed.emit()


func refresh() -> void:
	if game == null:
		return
	var sys: Dictionary = game.sector.systems[game.position]
	_status.text = "Tag %d · Position: %s · %s" % [game.day, sys.name, game.sector.name]
	_render_side()
	_canvas.queue_redraw()


func select(system: int, offer_id := -1) -> void:
	selected = system
	selected_offer = offer_id
	if selected_offer < 0:
		var here := game.offers_at(system)
		if not here.is_empty():
			selected_offer = here[0].id
	refresh()


func mission(offer: Dictionary) -> Mission:
	if not _missions.has(offer.id):
		_missions[offer.id] = game.mission_of(offer)
	return _missions[offer.id]


# ---------------------------------------------------------------- Karte

## Kartenkoordinaten -> Bildschirm (Fläche links vom Panel)
func _to_screen(p: Vector2) -> Vector2:
	var area := Rect2(Vector2(30, 80), _canvas.size - Vector2(60, 150))
	var k := minf(area.size.x / Sector.AREA.x, area.size.y / Sector.AREA.y)
	var off := area.position + (area.size - Sector.AREA * k) / 2.0
	return off + p * k


func system_screen_pos(i: int) -> Vector2:
	return _canvas.global_position + _to_screen(game.sector.systems[i].pos)


func _draw_map() -> void:
	if game == null:
		return
	var s := game.sector
	var font := get_theme_default_font()
	var path: Array = s.route(game.position, selected).path if selected >= 0 else []
	var on_path := {}
	for k in range(path.size() - 1):
		on_path["%d-%d" % [mini(path[k], path[k + 1]), maxi(path[k], path[k + 1])]] = true
	for r in s.routes:
		var a := _to_screen(s.systems[r.a].pos)
		var b := _to_screen(s.systems[r.b].pos)
		var hot: bool = on_path.has("%d-%d" % [mini(r.a, r.b), maxi(r.a, r.b)])
		if hot:
			_canvas.draw_dashed_line(a, b, UiTheme.ACCENT, 3.0, 10.0)
		else:
			_canvas.draw_line(a, b, UiTheme.LINE, 2.0, true)
		var m := (a + b) / 2.0 + Vector2(0, -6)
		_canvas.draw_string(font, m - Vector2(12, 0), "%d T" % r.days, HORIZONTAL_ALIGNMENT_CENTER, 24, 13,
			UiTheme.ACCENT if hot else UiTheme.MUTED)
	for i in s.systems.size():
		var p := _to_screen(s.systems[i].pos)
		var f := s.faction_of(i)
		var col: Color = f.color if f else UiTheme.MUTED
		var r := 20.0 if i == selected else 15.0
		_canvas.draw_circle(p, r, UiTheme.PANEL)
		_canvas.draw_arc(p, r, 0, TAU, 32, col, 4.0 if i == selected else 3.0, true)
		if i == selected:
			_canvas.draw_arc(p, 32, 0, TAU, 40, UiTheme.ACCENT, 2.0, true)
		elif i == _hover:
			_canvas.draw_arc(p, 26, 0, TAU, 40, UiTheme.MUTED, 1.5, true)
		if i == game.position:
			_diamond(p, 9.0, UiTheme.CREW)
		var n := game.offers_at(i).size()
		for k in n:
			_diamond(p + Vector2(22 + k * 14, -22), 7.0, UiTheme.ACCENT)
		_canvas.draw_string(font, p + Vector2(-80, r + 20), s.systems[i].name, HORIZONTAL_ALIGNMENT_CENTER, 160, 14,
			UiTheme.ACCENT if i == selected else UiTheme.TEXT)


func _diamond(c: Vector2, r: float, col: Color) -> void:
	_canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), col)


func _system_at(p: Vector2) -> int:
	var best := -1
	var best_d := PICK_R
	for i in game.sector.systems.size():
		var d := _to_screen(game.sector.systems[i].pos).distance_to(p)
		if d < best_d:
			best_d = d
			best = i
	return best


func _map_input(e: InputEvent) -> void:
	if game == null:
		return
	if e is InputEventMouseMotion:
		var h := _system_at(e.position)
		if h != _hover:
			_hover = h
			_canvas.queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _system_at(e.position)
		if i >= 0:
			Sfx.play(&"klick")
			select(i)


# ---------------------------------------------------------------- Panel rechts

func _render_side() -> void:
	UiTheme.clear(_side)
	if selected < 0:
		return
	var s := game.sector
	var sys: Dictionary = s.systems[selected]
	_side.add_child(UiTheme.label(sys.name, 28, UiTheme.ACCENT))
	var f := s.faction_of(selected)
	_side.add_child(UiTheme.label("kontrolliert von: %s" % f.name if f else "neutral – Hafen, keine Aufträge", 14, f.color if f else UiTheme.MUTED))
	var r := s.route(game.position, selected)
	var route_text := "Hier liegt das Schiff."
	if selected != game.position:
		route_text = "Route: %s · %d %s · Ankunft Tag %d" % [" → ".join(r.path.map(func(k: int) -> String: return s.systems[k].name)),
			r.days, "Tag" if r.days == 1 else "Tage", game.day + r.days]
	var rl := UiTheme.label(route_text, 14, UiTheme.MUTED)
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(rl)
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.y = 1
	_side.add_child(sep)
	var here := game.offers_at(selected)
	if f:
		_side.add_child(UiTheme.label("AUFTRÄGE HIER", 13, UiTheme.MUTED))
		if here.is_empty():
			_side.add_child(UiTheme.label("zurzeit keine", 14, UiTheme.MUTED))
		for o in here:
			_side.add_child(_offer_card(o))
	else:
		_render_harbor()
	var others := game.offers.filter(func(o: Dictionary) -> bool: return o.system != selected)
	if not others.is_empty():
		_side.add_child(UiTheme.label("WEITERE AUFTRÄGE", 13, UiTheme.MUTED))
		for o in others:
			var m := mission(o)
			var b := UiTheme.button("%s · %s, %s, noch %d %s" % [s.systems[o.system].name, m.faction.name.split(" ")[0],
				o.difficulty, o.expires - game.day, "Tag" if o.expires - game.day == 1 else "Tage"])
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.add_theme_font_size_override("font_size", 13)
			b.pressed.connect(select.bind(o.system, o.id))
			_side.add_child(b)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_side.add_child(row)
	var go := UiTheme.button("Kurs setzen (%d %s)" % [r.days, "Tag" if r.days == 1 else "Tage"] if selected != game.position else "Schiff ist hier",
		"Zum System fliegen, ohne einen Auftrag anzunehmen")
	go.disabled = selected == game.position or r.days < 0
	go.custom_minimum_size.y = 48
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(func() -> void: travel.emit(selected))
	row.add_child(go)
	var offer := _selected_offer()
	var brief := UiTheme.button("Briefing" if selected == game.position else "Hinfliegen & Briefing",
		"Auftrag annehmen: hinfliegen (Tage vergehen), dann Einsatzbesprechung und Bodenkampf")
	brief.disabled = offer.is_empty() or not game.reachable(offer)
	brief.custom_minimum_size.y = 48
	brief.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brief.add_theme_color_override("font_color", UiTheme.ACCENT)
	brief.pressed.connect(func() -> void: start.emit(offer))
	row.add_child(brief)


## Hafen (neutrales System): Anheuern aus der Liste „im Hafen“ (mit Fortschritt) und aus dem Roster, nur bei freiem Platz
func _render_harbor() -> void:
	if selected != game.position:
		var l := UiTheme.label("Hafen: Anheuern ist möglich, wenn das Schiff hier liegt.", 14, UiTheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(l)
		return
	var free := game.free_berths()
	var head := HBoxContainer.new()
	var t := UiTheme.label("HAFEN: CREW", 13, UiTheme.MUTED)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiTheme.label("Plätze an Bord %d / %d" % [Campaign.crew().size(), game.berths], 14, UiTheme.GOOD if free > 0 else UiTheme.BAD))
	_side.add_child(head)
	var waiting := Campaign.harbor()
	_side.add_child(UiTheme.label("Im Hafen (entlassen, mit Fortschritt)", 13, UiTheme.MUTED))
	if waiting.is_empty():
		_side.add_child(UiTheme.label("niemand", 14, UiTheme.MUTED))
	for c in waiting:
		_side.add_child(_hire_row(c, "wartet mit Fortschritt" + ((" · " + c.injury_text()) if c.injury != "" else ""), free))
	_side.add_child(UiTheme.label("Aus dem Roster (Stand des Rosters)", 13, UiTheme.MUTED))
	var any := false
	for r in GlobalRoster.entries():
		var rid: StringName = r.roster_id if r.roster_id != &"" else r.id
		if Campaign.is_aboard(rid) or waiting.any(func(h: Character) -> bool: return h.roster_id == rid):
			continue
		any = true
		_side.add_child(_hire_row(r, r.role, free))
	if not any:
		_side.add_child(UiTheme.label("alle Roster-Figuren sind an Bord oder im Hafen", 14, UiTheme.MUTED))


func _hire_row(c: Character, note: String, free: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(UiTheme.badge(c.letter, c.color, 30))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiTheme.label(c.name, 15))
	v.add_child(UiTheme.label(note, 12, UiTheme.MUTED))
	row.add_child(v)
	var b := UiTheme.button("Anheuern", "kein Platz an Bord frei" if free <= 0 else "")
	b.disabled = free <= 0
	b.add_theme_color_override("font_color", UiTheme.ACCENT)
	b.pressed.connect(func() -> void:
		var h := Campaign.hire(c)
		if h:
			Sfx.play(&"klick")
			hired.emit(h)
		refresh())
	row.add_child(b)
	return row


func _selected_offer() -> Dictionary:
	for o in game.offers_at(selected):
		if o.id == selected_offer:
			return o
	return {}


func _offer_card(o: Dictionary) -> Control:
	var m := mission(o)
	var sel: bool = o.id == selected_offer
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.box(Color("3a3215") if sel else UiTheme.PANEL2, UiTheme.ACCENT if sel else UiTheme.LINE, 8, 12))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			Sfx.play(&"klick")
			select(selected, o.id))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UiTheme.label(m.title, 16)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiTheme.label(m.difficulty_name(), 15, {"leicht": UiTheme.GOOD, "mittel": UiTheme.ACCENT, "schwer": UiTheme.BAD}[m.difficulty]))
	v.add_child(head)
	var g := UiTheme.label("Gegner: %s" % m.enemy_summary(), 13)
	g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(g)
	var arr := game.arrival_day(o.system)
	var left: int = o.expires - game.day
	var exp_text := "läuft ab: Tag %d (noch %d %s) · Belohnung: +%d freie EP je Figur" % [o.expires, left, "Tag" if left == 1 else "Tage", m.reward_xp]
	var col := UiTheme.MUTED
	if arr > o.expires:
		exp_text = "läuft ab: Tag %d – bei Ankunft (Tag %d) schon weg" % [o.expires, arr]
		col = UiTheme.BAD
	var el := UiTheme.label(exp_text, 13, col)
	el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(el)
	for c in [head, t, g, el]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card
