class_name StarMap
extends Control
## Brücke: Sternenkarte des Sektors (Systeme in Fraktionsfarbe, Sprungrouten mit Reisetagen, Aufträge)
## und rechts das gewählte System mit Route, Ankunftstag und seinen Aufträgen.
## Meldet travel(System) und start(Auftrag); das Schiff (Hub) führt beides aus.

signal travel(system: int)
## im Schiff einen Tag warten
signal wait_day
signal start(offer: Dictionary)
## Raumhafen: eigenes Fenster öffnen (&"ship" Schiffshändler, &"trade" Händler, &"yard" Werft, &"hire" Crew anheuern)
signal port(kind: StringName)
## Story: Kette wurde begonnen (Auftrag angenommen, Kontakt angesprochen) → Szenenfenster; Story-Einsatz starten; Logbuch
signal story_chain(chain: String)
signal story_mission
signal logbook
## Sektoren (Auftrag 2): Sprung durch ein Tor; Funktion an einem Ort (&"salvage" Bergung, &"skim" Treibstoff schöpfen)
signal jump_gate(gate: Dictionary)
signal place_action(action: StringName, index: int)
signal closed

const PANEL_W := 420.0
const PICK_R := 28.0

var game: HubState
var _legend_factions: HBoxContainer   # Fraktionen des Sektors in der Legende (beim Öffnen gefüllt)
var selected := -1
var selected_offer := -1      # Auftrags-ID
var _missions := {}           # Auftrags-ID -> Mission (Vorschau)
var _canvas: Control
var _side: VBoxContainer
var _status: Label
var _hover := -1
## Systemansicht (Doppelklick auf ein System): System, gewählter Ort; gewähltes Tor in der Sektorkarte (Index in gates)
var zoom := -1
## Touch (Hub Auftrag 6): Ansicht der Karte bzw. Systemansicht, verschoben und vergrößert (1 = alles; am PC immer 1)
const VIEW_MAX := 3.0
var _view_k := 1.0
var _view_off := Vector2.ZERO
var _touches := {}
var _touch_moved := false
var _drag_accum := Vector2.ZERO
var _pinch_dist := 0.0
var selected_place := -1
var selected_gate := -1
var _to_map: Button
var _sectors: Modal


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
	var lb := UiTheme.button("Logbuch", "Story: Aufträge, Hinweise, Ziele und Verlauf")
	lb.custom_minimum_size.y = 44
	lb.pressed.connect(func() -> void: logbook.emit())
	top.add_child(lb)
	var sb := UiTheme.button("Sektoren", "Alle Sektoren und ihre Sprungtore")
	sb.custom_minimum_size.y = 44
	sb.pressed.connect(_show_sectors)
	top.add_child(sb)
	_to_map = UiTheme.button("Zur Sektorkarte", "Zurück aus der Systemansicht")
	_to_map.custom_minimum_size.y = 44
	_to_map.add_theme_color_override("font_color", UiTheme.ACCENT)
	_to_map.pressed.connect(func() -> void: set_zoom(-1))
	top.add_child(_to_map)
	# unten links: Legende
	var leg := PanelContainer.new()
	leg.add_theme_stylebox_override("panel", UiTheme.box(Color(UiTheme.PANEL, 0.9), UiTheme.LINE, 10, 8))
	leg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	leg.position = Vector2(14, 0)
	leg.name = "Legend"
	add_child(leg)
	var lv := VBoxContainer.new()
	lv.add_theme_constant_override("separation", 2)
	leg.add_child(lv)
	# oben die Fraktionen des aktuellen Sektors (in refresh gefüllt, Bodenkampf Auftrag 1), unten die Zeichen
	_legend_factions = HBoxContainer.new()
	_legend_factions.add_theme_constant_override("separation", 14)
	lv.add_child(_legend_factions)
	var lrow := HBoxContainer.new()
	lrow.add_theme_constant_override("separation", 14)
	lv.add_child(lrow)
	lrow.add_child(UiTheme.label("◆ Auftrag", 13, UiTheme.ACCENT))
	lrow.add_child(UiTheme.label("◆ eigenes Schiff", 13, UiTheme.CREW))
	lrow.add_child(UiTheme.label("○ Story-Ort", 13, StoryDialog.STORY_COLOR))
	lrow.add_child(UiTheme.label("⬡ Sprungtor", 13, UiTheme.TEXT))
	lrow.add_child(UiTheme.label("· Orte (Doppelklick)", 13, UiTheme.MUTED))
	lrow.add_child(UiTheme.label("T = Reisetage", 13, UiTheme.MUTED))
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
	_sectors = Modal.new()
	add_child(_sectors)
	hide()


func _process(_d: float) -> void:
	var leg: Control = get_node("Legend")
	leg.position.y = size.y - leg.size.y - 14


func open(g: HubState) -> void:
	game = g
	_missions.clear()
	zoom = -1
	_reset_view()
	selected_gate = -1
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
	_status.text = "Tag %d · Position: %s · %s (%d von %d bekannt)\n%d Cr · Treibstoff %d/%d · Hülle %d/%d · Material %d" % [game.day, sys.name,
		game.sector.name, game.known_sectors.size(), game.sectors.size(), game.credits, game.fuel, game.tank_max(), game.hull, game.hull_max(), game.material]
	if selected >= game.sector.systems.size():
		selected = game.position
	_to_map.visible = zoom >= 0
	_fill_legend()
	_render_side()
	_canvas.queue_redraw()


## Legende: nur die Fraktionen des aktuellen Sektors (es gibt mehr Fraktionen als Plätze; ändert sich beim Sprung)
func _fill_legend() -> void:
	UiTheme.clear(_legend_factions)
	var shown := {}
	for sys in game.sector.systems:
		var p := String(sys.faction)
		if p != "" and not shown.has(p) and ResourceLoader.exists(p):
			shown[p] = true
			var f: FactionData = load(p)
			_legend_factions.add_child(UiTheme.label("● " + f.name, 13, f.color))


func select(system: int, offer_id := -1) -> void:
	selected = system
	selected_gate = -1
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
	return _canvas.global_position + _view_off + _to_screen(game.sector.systems[i].pos) * _view_k


func _draw_map() -> void:
	if game == null:
		return
	_canvas.draw_set_transform(_view_off, 0.0, Vector2(_view_k, _view_k))
	if zoom >= 0:
		_draw_system(zoom)
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
		if _story_places().has(i):
			_canvas.draw_arc(p + Vector2(-24, -22), 7.0, 0, TAU, 20, StoryDialog.STORY_COLOR, 3.0, true)
		_canvas.draw_string(font, p + Vector2(-80, r + 20), s.systems[i].name, HORIZONTAL_ALIGNMENT_CENTER, 160, 14,
			UiTheme.ACCENT if i == selected else UiTheme.TEXT)
		# Orte als kleine Punkte
		var pl: Array = s.systems[i].get("places", [])
		for k in pl.size():
			var a := 2.4 + k * 0.55
			_canvas.draw_circle(p + Vector2(cos(a), sin(a)) * (r + 9), 3.0, col)
	# Sprungtore am Rand
	for gi in s.gates.size():
		var gp := _gate_pos(gi)
		var sp := _to_screen(s.systems[int(s.gates[gi].system)].pos)
		_canvas.draw_dashed_line(sp, gp, UiTheme.MUTED, 2.0, 5.0)
		_hex(gp, 18.0, UiTheme.TEXT, 4.0 if gi == selected_gate else 2.5)
		if gi == selected_gate:
			_canvas.draw_arc(gp, 30, 0, TAU, 40, UiTheme.ACCENT, 2.0, true)
		var gt: Dictionary = s.gates[gi]
		var label := "Tor → %s" % _sector_name(int(gt.to_sector))
		var right: bool = gp.x < _canvas.size.x - 200.0
		_canvas.draw_string(font, gp + (Vector2(26, 5) if right else Vector2(-206, 5)), label,
			HORIZONTAL_ALIGNMENT_LEFT if right else HORIZONTAL_ALIGNMENT_RIGHT, 180, 13, UiTheme.TEXT)


func _hex(c: Vector2, r: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	for k in 7:
		pts.append(c + Vector2.RIGHT.rotated(PI / 3.0 * k + PI / 6.0) * r)
	_canvas.draw_colored_polygon(pts.slice(0, 6), UiTheme.PANEL)
	_canvas.draw_polyline(pts, col, w, true)


## Bildschirmposition eines Tors: vom Ankersystem ein Stück nach außen
func _gate_pos(gi: int) -> Vector2:
	var gt: Dictionary = game.sector.gates[gi]
	var p := _to_screen(game.sector.systems[int(gt.system)].pos) + (gt.dir as Vector2).normalized() * 62.0
	return p.clamp(Vector2(30, 110), _canvas.size - Vector2(30, 90))


func _sector_name(k: int) -> String:
	return game.sectors[k].name if k in game.known_sectors else "unbekannter Sektor"


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
	if e is InputEventScreenTouch or e is InputEventScreenDrag:
		_touch_input(e)
		return
	if e is InputEventMouse and e.device == InputEvent.DEVICE_ID_EMULATION:
		return  # vom Touch erzeugte Mausereignisse: die Touch-Behandlung übernimmt
	if e is InputEventMouseMotion:
		var h := _system_at(_unview(e.position))
		if h != _hover:
			_hover = h
			_canvas.queue_redraw()
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		_click(_unview(e.position), e.double_click)


## Klick oder Antippen (p in Kartenkoordinaten der Fläche): Ort, Tor oder System wählen; doppelt = Systemansicht
func _click(p: Vector2, double: bool) -> void:
	if zoom >= 0:
		var pi := _place_at(p)
		if pi >= 0:
			Sfx.play(&"klick")
			selected_place = pi
			selected_offer = -1
			refresh()
		return
	var gi := _gate_at(p)
	if gi >= 0:
		Sfx.play(&"klick")
		selected_gate = gi
		refresh()
		return
	var i := _system_at(p)
	if i >= 0:
		Sfx.play(&"klick")
		if double:
			select(i)
			set_zoom(i)
		else:
			select(i)


## Bildschirm (Fläche) → Kartenkoordinaten bei verschobener/vergrößerter Ansicht
func _unview(p: Vector2) -> Vector2:
	return (p - _view_off) / _view_k


func _reset_view() -> void:
	_view_k = 1.0
	_view_off = Vector2.ZERO
	_touches.clear()
	if _canvas:
		_canvas.clip_contents = false


## Ansicht verschieben/vergrößern; nie kleiner als alles, der Rand bleibt im Bild
func _set_view(k: float, off: Vector2) -> void:
	_view_k = clampf(k, 1.0, VIEW_MAX)
	var sz := _canvas.size
	_view_off = off.clamp(sz * (1.0 - _view_k), Vector2.ZERO)
	_canvas.clip_contents = _view_k > 1.0
	_canvas.queue_redraw()


## Tablet (Hub Auftrag 6): wischen = verschieben, zwei Finger = zoomen, antippen = wählen, doppelt antippen = Systemansicht
func _touch_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_touch_moved = false
				_drag_accum = Vector2.ZERO
				if e.double_tap:
					_click(_unview(e.position), true)
					_touch_moved = true
			else:
				_touch_moved = true
				_pinch_dist = _pinch().d
		else:
			var was: bool = _touches.has(e.index)
			_touches.erase(e.index)
			if was and _touches.is_empty() and not _touch_moved:
				_click(_unview(e.position), false)
	elif e is InputEventScreenDrag:
		if not _touches.has(e.index):
			return
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var st := _pinch()
			if _pinch_dist > 0:
				var f: float = st.d / _pinch_dist
				var k := clampf(_view_k * f, 1.0, VIEW_MAX)
				# Punkt unter der Fingermitte bleibt stehen
				_set_view(k, st.c - (st.c - _view_off) * (k / _view_k) + e.relative / 2.0)
			_pinch_dist = st.d
		else:
			if not _touch_moved:
				_drag_accum += e.relative
				if _drag_accum.length() < 10.0:
					return
				_touch_moved = true
			_set_view(_view_k, _view_off + e.relative)


func _pinch() -> Dictionary:
	var ps: Array = _touches.values()
	var a: Vector2 = ps[0]
	var b: Vector2 = ps[1]
	return {"d": a.distance_to(b), "c": (a + b) / 2.0}


func _gate_at(p: Vector2) -> int:
	for gi in game.sector.gates.size():
		if _gate_pos(gi).distance_to(p) < 24.0:
			return gi
	return -1


## Systemansicht öffnen (system) oder schließen (-1)
func set_zoom(system: int) -> void:
	zoom = system
	_reset_view()
	selected_place = 0 if system >= 0 else -1
	if system >= 0:
		selected = system
		var here := game.offers_at(system)
		if not here.is_empty():
			selected_place = maxi(0, int(here[0].get("place", 0)))
	refresh()


# ---------------------------------------------------------------- Panel rechts

func _render_side() -> void:
	UiTheme.clear(_side)
	if zoom >= 0:
		_render_place()
		return
	if selected_gate >= 0 and selected_gate < game.sector.gates.size():
		_render_gate(game.sector.gates[selected_gate])
		return
	if selected < 0:
		return
	_render_story()
	var s := game.sector
	var sys: Dictionary = s.systems[selected]
	_side.add_child(UiTheme.label(sys.name, 28, UiTheme.ACCENT))
	var f := s.faction_of(selected)
	_side.add_child(UiTheme.label("kontrolliert von: %s" % f.name if f else "neutral – Hafen, keine Aufträge", 14, f.color if f else UiTheme.MUTED))
	var danger := UiTheme.label("Feindkontakt auf der Reise: %d %% je Tag (%s)" % [roundi(SpaceEvents.contact_chance(game, selected) * 100),
		SpaceTemplates.faction_name(SpaceEvents.faction_id(game, selected))], 13, UiTheme.MUTED)
	danger.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(danger)
	var r := s.route(game.position, selected)
	var route_text := "Hier liegt das Schiff."
	if selected != game.position:
		route_text = "Route: %s · %d %s · Ankunft Tag %d" % [" → ".join(r.path.map(func(k: int) -> String: return s.systems[k].name)),
			r.days, "Tag" if r.days == 1 else "Tage", game.day + r.days]
	var rl := UiTheme.label(route_text, 14, UiTheme.MUTED)
	rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(rl)
	if selected != game.position and r.days > 0:
		_render_route(r.days)
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.y = 1
	_side.add_child(sep)
	var places := _story_places()
	if places.has(selected):
		var sl := UiTheme.label("Story-Ort: %s" % places[selected], 14, StoryDialog.STORY_COLOR)
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(sl)
	var here := game.offers_at(selected)
	if f:
		_side.add_child(UiTheme.label("AUFTRÄGE HIER", 13, UiTheme.MUTED))
		if here.is_empty():
			_side.add_child(UiTheme.label("zurzeit keine", 14, UiTheme.MUTED))
		for o in here:
			_side.add_child(_offer_card(o))
	elif selected == game.position:
		_side.add_child(UiTheme.label("RAUMHAFEN", 13, UiTheme.MUTED))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		_side.add_child(grid)
		for spec in [[&"ship", "Schiffshändler", "Treibstoff, Schiffsmaterial, Proviant, Schiffsmunition, Schiffswaffen (nach Verhandeln)"],
				[&"trade", "Händler", "Ausrüstung der Crew, Munition, Handwerksmaterial, Lager und Werkstatt (nach Handeln)"],
				[&"yard", "Werft", "Große Reparatur, Ausbau, Systemschäden, Schiffswaffen einbauen"],
				[&"hire", "Crew anheuern", "Entlassene im Hafen und Figuren aus dem Roster"]]:
			var b := UiTheme.button(String(spec[1]), String(spec[2]))
			b.custom_minimum_size = Vector2(0, 48)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
			var kind: StringName = spec[0]
			b.pressed.connect(func() -> void: port.emit(kind))
			grid.add_child(b)
		var credits := UiTheme.label("Credits: %d Cr" % game.credits, 16, UiTheme.BAD if game.credits < 0 else UiTheme.ACCENT)
		_side.add_child(credits)
		var contacts := game.story_engine().contacts()
		if not contacts.is_empty():
			_side.add_child(UiTheme.label("KONTAKTE", 13, UiTheme.MUTED))
			for c in contacts:
				var chain: String = c.chain
				_side.add_child(_story_card(String(c.title), "Kontakt im Raumhafen", "Ansprechen", func() -> void: _begin_story(chain)))
		_render_papers()
	else:
		var l := UiTheme.label("Hafen: Schiffshändler, Händler, Werft und Anheuern, wenn das Schiff hier liegt.", 14, UiTheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(l)
	var others := game.offers.filter(func(o: Dictionary) -> bool: return o.system != selected)
	if not others.is_empty():
		_side.add_child(UiTheme.label("WEITERE AUFTRÄGE", 13, UiTheme.MUTED))
		for o in others:
			var m := mission(o)
			var b := UiTheme.button("%s · %s, %s, noch %d %s%s" % [s.systems[o.system].name, m.faction.name.split(" ")[0],
				o.difficulty, o.expires - game.day, "Tag" if o.expires - game.day == 1 else "Tage", " · erneuter Versuch" if o.get("retry", false) else ""])
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
	go.disabled = selected == game.position or r.days < 0 or not game.can_travel(selected)
	go.custom_minimum_size.y = 48
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(func() -> void: travel.emit(selected))
	row.add_child(go)
	var offer := _selected_offer()
	var what := "Briefing"
	if not offer.is_empty():
		what = {"abfangen": "Raumkampf", "eskorte": "Eskorte"}.get(HubState.offer_kind(offer), "Blockade" if offer.get("blockade", false) else "Briefing")
	var brief := UiTheme.button(what if selected == game.position else "Hinfliegen & " + what,
		"Auftrag annehmen: hinfliegen (Tage vergehen), dann Einsatzbesprechung und Bodenkampf")
	brief.disabled = offer.is_empty() or not game.reachable(offer)
	brief.custom_minimum_size.y = 48
	brief.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brief.add_theme_color_override("font_color", UiTheme.ACCENT)
	brief.pressed.connect(func() -> void: start.emit(offer))
	row.add_child(brief)


## Kurs: Treibstoff (Schätzung, höchstens), Reiseposten, Warnungen
func _render_route(days: int) -> void:
	var est := Voyage.estimate_fuel(game, days)
	var fl := UiTheme.label("Treibstoff: ca. %d (höchstens %d) · Tank %d" % [est, game.fuel_per_day() * days, game.fuel], 14,
		UiTheme.BAD if game.fuel <= 0 else (Color("ff8a3d") if est > game.fuel else UiTheme.TEXT))
	fl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(fl)
	if not game.can_travel(selected):
		var why := "Tank leer" if game.fuel <= 0 else "Hülle 0"
		var port := game.nearest_harbor()
		var w := UiTheme.label("%s: nur Kurs zum nächsten Hafen (%s)." % [why, game.sector.systems[port].name if port >= 0 else "–"], 14, UiTheme.BAD)
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(w)
	elif game.fuel <= 0:
		_side.add_child(UiTheme.label("Notsprit: kein Verbrauch bis zum Hafen.", 14, Color("ff8a3d")))
	elif est > game.fuel:
		var w := UiTheme.label("Der Tank reicht vielleicht nicht. Läuft er leer, endet die Reise trotzdem am Ziel (Notsprit), danach nur Kurs zum Hafen.", 13, Color("ff8a3d"))
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(w)
	_side.add_child(UiTheme.label("REISEPOSTEN (je Reisetag eine Probe)", 13, UiTheme.MUTED))
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 12)
	for e in Voyage.assign(game):
		g.add_child(UiTheme.label(e.post.name, 14, UiTheme.MUTED))
		if e.ch == null:
			g.add_child(UiTheme.label("unbesetzt", 14, UiTheme.BAD))
			g.add_child(UiTheme.label("", 14))
			continue
		var n := HBoxContainer.new()
		n.add_theme_constant_override("separation", 6)
		n.add_child(UiTheme.label(e.ch.name, 14))
		n.add_child(UiTheme.label(e.post.station if e.own else "Bester verfügbar", 12, UiTheme.MUTED if e.own else Color("ff8a3d")))
		g.add_child(n)
		g.add_child(UiTheme.label(Dice.fmt(Rules.skill_total(e.ch, e.post.skill)), 14))
	_side.add_child(g)
	var out := Campaign.crew().filter(func(c: Character) -> bool: return String(c.id) in game.medics and not c.is_locked())
	if not out.is_empty():
		var l := UiTheme.label("Nicht eingeteilt: %s – Krankenstation" % ", ".join(out.map(func(c: Character) -> String: return c.name)), 13, UiTheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(l)


## Raumhafen: Tanken (immer, auch auf Notkredit), Werft (große Reparatur), Schiffsmaterial
func _selected_offer() -> Dictionary:
	for o in game.offers_at(selected):
		if o.id == selected_offer:
			return o
	return {}


## Art des Auftrags: Kennzeichen und Farbe (Mockup Bildschirm 41)
func _kind_tag(o: Dictionary) -> Array:
	match HubState.offer_kind(o):
		"abfangen":
			return ["ABFANGEN (RAUMKAMPF)", UiTheme.CREW]
		"eskorte":
			return ["ESKORTE (RAUMKAMPF UNTERWEGS)", UiTheme.RETREAT]
	return ["BODEN + BLOCKADE", Color("ff8a3d")] if o.get("blockade", false) else ["BODEN", UiTheme.MUTED]


func _kind_text(o: Dictionary, m: Mission) -> String:
	var foe := SpaceTemplates.faction_name(SpaceEvents.faction_id(game, o.system))
	match HubState.offer_kind(o):
		"abfangen":
			return "Raumkampf gegen %s · Lohn %d Cr + Kampfbeute" % [foe, SpaceEvents.offer_pay(game, o)]
		"eskorte":
			return "Frachter nach %s (%d Reisetage) · unterwegs sicher ein Raumkampf · Lohn bei Ankunft %d Cr" % [
				game.sector.systems[int(o.target)].name, game.sector.route(int(o.system), int(o.target)).days, SpaceEvents.offer_pay(game, o)]
	var t := "Gegner: %s" % m.enemy_summary()
	if o.get("blockade", false):
		t = "Erst Raumkampf gegen %s, dann Bodenkampf. Flucht im All: Auftrag bleibt offen · Niederlage: Notfall. %s" % [foe, t]
	return t


# ---------------------------------------------------------------- Story (Auftrag 1, 19.10.2026)

## Story-Orte im aktuellen Sektor {System: Titel} für Karte und Seitenleiste
func _story_places() -> Dictionary:
	var out := {}
	for m in game.story_markers():
		out[int(m.system)] = String(m.title)
	return out


## Liegt an Ort k im System ein Story-Ort?
func _story_at(system: int, k: int) -> bool:
	return not game.story_engine().at_place(game.cur_sector, system, k).is_empty()


## Abschnitt STORY oben rechts: offener Story-Einsatz und Story-Aufträge (ohne Ablauf)
func _render_story() -> void:
	var st := game.story_engine()
	var m := game.story_mission()
	var list := st.offers()
	# laufende Szenen (z. B. mit Esc/Zurück geschlossen, Hub Auftrag 8): wieder öffnen
	var running := st.open_chains().filter(func(c: Dictionary) -> bool: return c.status == "aktiv")
	if m.is_empty() and list.is_empty() and running.is_empty():
		return
	_side.add_child(UiTheme.label("STORY", 13, UiTheme.MUTED))
	if not m.is_empty():
		var kind := String(m.get("kind", "boden"))
		var what := "Bodenkampf" if kind == "boden" else ("Raumkampf, dann Bodenkampf" if kind == "blockade" else "Raumkampf")
		_side.add_child(_story_card(String(m.get("title", "Einsatz")), "Einsatz: %s · %s · hier, wo das Schiff liegt · kein Ablauf, kein Lohn"
			% [what, String(m.get("difficulty", "mittel"))], "Einsatz starten", func() -> void: story_mission.emit()))
	for o in list:
		var chain: String = o.chain
		_side.add_child(_story_card(String(o.title), "%s · ohne Ablauf" % StoryDialog.KIND_NAMES.get(o.kind, o.kind), "Annehmen",
			func() -> void: _begin_story(chain)))
	for c in running:
		var rid: String = c.chain
		_side.add_child(_story_card(String(c.title), "%s · Szene läuft" % StoryDialog.KIND_NAMES.get(c.kind, c.kind), "Fortsetzen",
			func() -> void:
				Sfx.play(&"klick")
				story_chain.emit(rid)))


func _begin_story(chain: String) -> void:
	Sfx.play(&"klick")
	game.story_engine().start(chain)
	story_chain.emit(chain)


## Karte wie die Auswahl beim Feindkontakt (docs/Layout.md): Titel, graue Beschreibung, Knopf mit goldener Schrift
func _story_card(title: String, text: String, action: String, act: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 12))
	var v := VBoxContainer.new()
	p.add_child(v)
	var t := UiTheme.label(title, 16, StoryDialog.STORY_COLOR)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var l := UiTheme.label(text, 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	var b := UiTheme.button(action)
	b.add_theme_color_override("font_color", UiTheme.ACCENT)
	b.pressed.connect(act)
	v.add_child(b)
	return p


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
	var tag := _kind_tag(o)
	var lv := String(o.get("elite", ""))
	var tl := UiTheme.label(tag[0] + (("  ·  " + Elite.label(lv).to_upper()) if lv != "" else ""), 14, tag[1])
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if lv != "":
		tl.tooltip_text = "Stärkere Gegner mit besserer Ausrüstung (Ziel etwa 70–75 % Siege); selten Elite-Beute." if lv == Elite.ELITE \
			else "Boss-Kampf: Zielperson mit zwei Leibwächtern und Fußvolk; selten Elite-Beute."
	v.add_child(tl)
	var t := UiTheme.label(game.offer_title(o) + ("  · erneuter Versuch" if o.get("retry", false) else ""), 16)
	if o.get("retry", false):
		t.tooltip_text = "Nach einem Rückzug weiter offen bis zum Ablaufdatum"
		t.mouse_filter = Control.MOUSE_FILTER_PASS
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiTheme.label(m.difficulty_name(), 15, {"leicht": UiTheme.GOOD, "mittel": UiTheme.ACCENT, "schwer": UiTheme.BAD}[m.difficulty]))
	v.add_child(head)
	var opl: Array = game.sector.systems[int(o.system)].get("places", [])
	var opi := int(o.get("place", -1))
	if opi >= 0 and opi < opl.size():
		var pl := UiTheme.label("Ort: %s (%s)" % [opl[opi].name, Places.kind_name(opl[opi].kind)], 13, UiTheme.MUTED)
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(pl)
	var g := UiTheme.label(_kind_text(o, m), 13)
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
	for c in [head, t, g, el, tl]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return card


# ---------------------------------------------------------------- Systemansicht, Orte, Tore, Sektoren (Auftrag 2)

const ORBIT0 := 110.0
const ORBIT_STEP := 76.0
const PLACE_COLORS := {"station": UiTheme.ACCENT, "planet": UiTheme.GOOD, "mond": UiTheme.MUTED, "wrack": UiTheme.MUTED,
	"gas": UiTheme.CREW, "nebel": UiTheme.CREW}


func _places(system: int) -> Array:
	return game.sector.systems[system].get("places", [])


func _place_pos(k: int) -> Vector2:
	var c := _canvas.size / 2.0 + Vector2(0, 20)
	var a := -0.6 + k * 2.2
	return c + Vector2(cos(a), sin(a)) * (ORBIT0 + k * ORBIT_STEP)


func _place_at(p: Vector2) -> int:
	for k in _places(zoom).size():
		if _place_pos(k).distance_to(p) < 30.0:
			return k
	return -1


## Systemansicht: Stern, Umlaufbahnen, Orte mit Aufträgen; Story-Ort und Schiff
func _draw_system(system: int) -> void:
	var font := get_theme_default_font()
	var c := _canvas.size / 2.0 + Vector2(0, 20)
	var pl := _places(system)
	for k in pl.size():
		_canvas.draw_arc(c, ORBIT0 + k * ORBIT_STEP, 0, TAU, 96, UiTheme.LINE, 2.0, true)
	var f := game.sector.faction_of(system)
	_canvas.draw_circle(c, 46, UiTheme.PANEL2)
	_canvas.draw_arc(c, 46, 0, TAU, 48, f.color if f else UiTheme.MUTED, 3.0, true)
	_canvas.draw_string(font, c + Vector2(-90, 6), game.sector.systems[system].name, HORIZONTAL_ALIGNMENT_CENTER, 180, 15, UiTheme.ACCENT)
	for k in pl.size():
		var p := _place_pos(k)
		var col: Color = PLACE_COLORS.get(String(pl[k].kind), UiTheme.TEXT)
		if String(pl[k].kind) == "station":
			_canvas.draw_rect(Rect2(p - Vector2(20, 20), Vector2(40, 40)), UiTheme.PANEL2)
			_canvas.draw_rect(Rect2(p - Vector2(20, 20), Vector2(40, 40)), col, false, 3.0)
		else:
			_canvas.draw_circle(p, 22, UiTheme.PANEL2)
			_canvas.draw_arc(p, 22, 0, TAU, 40, col, 3.0, true)
		if k == selected_place:
			_canvas.draw_arc(p, 34, 0, TAU, 40, UiTheme.ACCENT, 2.0, true)
		if _story_at(system, k):
			_canvas.draw_arc(p + Vector2(-30, -26), 7.0, 0, TAU, 20, StoryDialog.STORY_COLOR, 3.0, true)
		var n := game.offers_at(system).filter(func(o: Dictionary) -> bool: return int(o.get("place", -1)) == k).size()
		for j in n:
			_diamond(p + Vector2(28 + j * 14, -26), 7.0, UiTheme.ACCENT)
		var dim: bool = pl[k].get("done", false)
		_canvas.draw_string(font, p + Vector2(-110, 44), "%s%s" % [pl[k].name, " · leer" if dim else ""],
			HORIZONTAL_ALIGNMENT_CENTER, 220, 14, UiTheme.ACCENT if k == selected_place else UiTheme.TEXT)
	if _story_places().has(system):
		_canvas.draw_arc(c + Vector2(-60, -60), 8.0, 0, TAU, 20, StoryDialog.STORY_COLOR, 3.0, true)
		_canvas.draw_string(font, c + Vector2(-140, -76), "Story-Ort", HORIZONTAL_ALIGNMENT_CENTER, 160, 13, StoryDialog.STORY_COLOR)
	if system == game.position:
		_diamond(c + Vector2(-ORBIT0 - 40, -ORBIT0 - 40), 9.0, UiTheme.CREW)
		_canvas.draw_string(font, c + Vector2(-ORBIT0 - 120, -ORBIT0 - 12), "Frontire", HORIZONTAL_ALIGNMENT_CENTER, 160, 13, UiTheme.MUTED)


## Seitenleiste der Systemansicht: gewählter Ort mit Funktionen und Aufträgen, die anderen Orte
func _render_place() -> void:
	var pl := _places(zoom)
	if pl.is_empty():
		return
	selected_place = clampi(selected_place, 0, pl.size() - 1)
	var p: Dictionary = pl[selected_place]
	var kind := String(p.kind)
	var here := zoom == game.position
	var f := game.sector.faction_of(zoom)
	_wrap(UiTheme.label(String(p.name), 26, UiTheme.ACCENT))
	_wrap(UiTheme.label("%s · %s · %s" % [Places.kind_name(kind), game.sector.systems[zoom].name, f.name if f else "neutral (Hafen)"], 14,
		f.color if f else UiTheme.MUTED))
	var ft := UiTheme.label(Places.function_text(kind), 13, UiTheme.MUTED)
	ft.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(ft)
	for m in game.story_engine().at_place(game.cur_sector, zoom, selected_place):
		_wrap(UiTheme.label("Story-Ort: %s" % m.title, 14, StoryDialog.STORY_COLOR))
	_side.add_child(UiTheme.label("MÖGLICHKEITEN", 13, UiTheme.MUTED))
	if here:
		# Ort anfliegen (Hub Auftrag 4, Entscheidung des Nutzers 19.10.2026): ohne Zeit, bei jedem Ort; startet Story-Ketten hier
		var fly := UiTheme.button("Anfliegen", "Kostet keine Zeit. Was an diesem Ort wartet, zeigt sich erst vor Ort.")
		fly.custom_minimum_size.y = 44
		fly.add_theme_color_override("font_color", UiTheme.ACCENT)
		fly.pressed.connect(func() -> void: place_action.emit(&"visit", selected_place))
		_side.add_child(fly)
	if not here:
		var nl := UiTheme.label("Nur, wenn das Schiff in diesem System liegt.", 14, UiTheme.MUTED)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(nl)
	elif Places.is_trade(kind):
		var specs := [[&"trade", "Händler"], [&"ship", "Schiffshändler"]]
		if game.is_harbor(zoom):
			specs += [[&"yard", "Werft"], [&"hire", "Crew anheuern"]]
		var grid := GridContainer.new()
		grid.columns = 2
		_side.add_child(grid)
		for spec in specs:
			var b := UiTheme.button(String(spec[1]), "" if game.is_harbor(zoom) else "Station: 20 % teurer als im Hafen")
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size.y = 44
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
			var kd: StringName = spec[0]
			b.pressed.connect(func() -> void: port.emit(kd))
			grid.add_child(b)
	elif kind == "wrack":
		var b := UiTheme.button("Schon geborgen" if p.done else "Bergen (1 Tag, Probe Reparatur)",
			"Teilerfolg +1 Schiffsmaterial, Erfolg +3 Schiffsmaterial und +2 Handwerksmaterial, Herausragend dazu eine beschädigte Schiffswaffe, Patzer −5 Hülle")
		b.disabled = not Places.can_salvage(game, selected_place)
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.pressed.connect(func() -> void: place_action.emit(&"salvage", selected_place))
		_side.add_child(b)
	elif Places.is_fuel(kind):
		var b := UiTheme.button("Treibstoff schöpfen (1 Tag, Probe Pilot)", "Teilerfolg +10, Erfolg +20, Herausragend +30, Patzer −5 Hülle; beliebig oft")
		b.disabled = not Places.can_skim(game, selected_place)
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.pressed.connect(func() -> void: place_action.emit(&"skim", selected_place))
		_side.add_child(b)
	else:
		_side.add_child(UiTheme.label("Bodeneinsätze über Aufträge.", 14, UiTheme.MUTED))
	var offers := game.offers_at(zoom).filter(func(o: Dictionary) -> bool: return int(o.get("place", -1)) == selected_place)
	_side.add_child(UiTheme.label("AUFTRÄGE AN DIESEM ORT", 13, UiTheme.MUTED))
	if offers.is_empty():
		_side.add_child(UiTheme.label("keine", 14, UiTheme.MUTED))
	for o in offers:
		_side.add_child(_offer_card(o))
	_side.add_child(UiTheme.label("ANDERE ORTE", 13, UiTheme.MUTED))
	for k in pl.size():
		if k == selected_place:
			continue
		var n := game.offers_at(zoom).filter(func(o: Dictionary) -> bool: return int(o.get("place", -1)) == k).size()
		var b := UiTheme.button("%s (%s)%s" % [pl[k].name, Places.kind_name(pl[k].kind), (" · %d %s" % [n, "Auftrag" if n == 1 else "Aufträge"]) if n > 0 else ""])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var kk: int = k
		b.pressed.connect(func() -> void:
			selected_place = kk
			selected_offer = -1
			refresh())
		_side.add_child(b)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(spacer)
	var offer := _selected_offer()
	if not offer.is_empty() and int(offer.get("place", -1)) == selected_place and int(offer.system) == zoom:
		var brief := UiTheme.button("Briefing" if here else "Hinfliegen & Briefing", "Auftrag annehmen")
		brief.disabled = not game.reachable(offer)
		brief.custom_minimum_size.y = 48
		brief.add_theme_color_override("font_color", UiTheme.ACCENT)
		brief.pressed.connect(func() -> void: start.emit(offer))
		_side.add_child(brief)


## Seitenleiste für ein Sprungtor: Ziel, Gebühr, Papiere, Rückreise; Kurs zum Tor oder Springen
func _render_gate(gt: Dictionary) -> void:
	var anchor := int(gt.system)
	_wrap(UiTheme.label("Sprungtor → %s" % _sector_name(int(gt.to_sector)), 24, UiTheme.ACCENT))
	_wrap(UiTheme.label("am Rand von %s · Betreiber: %s" % [game.sector.systems[anchor].name, game._operator_name(String(gt.operator))
		if String(gt.operator) != "" else "frei"], 14, UiTheme.MUTED))
	var r := game.sector.route(game.position, anchor)
	if anchor != game.position:
		_wrap(UiTheme.label("Route: %d %s bis %s, dann Sprung (1 Tag)" % [r.days, "Tag" if r.days == 1 else "Tage",
			game.sector.systems[anchor].name], 14, UiTheme.MUTED))
	_side.add_child(UiTheme.label("DURCHFLUG", 13, UiTheme.MUTED))
	_wrap(UiTheme.label("Gebühr: %d Cr (nach Verhandeln, Grundpreis %d)" % [game.gate_fee(gt), int(gt.fee)], 15, UiTheme.ACCENT))
	var need: bool = gt.papers
	var have := String(gt.operator) in game.papers
	_wrap(UiTheme.label("Papiere: %s" % ("nicht nötig" if not need else ("vorhanden" if have else "fehlen – im Hafen kaufen (%d Cr)" % game.papers_price())),
		15, UiTheme.GOOD if not need or have else UiTheme.BAD))
	_wrap(UiTheme.label("Rückreise über dasselbe Tor, gleiche Gebühr.", 13, UiTheme.MUTED))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.add_child(spacer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_side.add_child(row)
	var go := UiTheme.button("Kurs (%d %s)" % [r.days, "Tag" if r.days == 1 else "Tage"] if anchor != game.position else "Schiff ist am Tor")
	go.disabled = anchor == game.position or not game.can_travel(anchor)
	go.custom_minimum_size.y = 48
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.pressed.connect(func() -> void: travel.emit(anchor))
	row.add_child(go)
	var block := game.jump_block(gt)
	var j := UiTheme.button("Springen", block if block != "" else "%d Cr Gebühr, 1 Tag" % game.gate_fee(gt))
	j.disabled = block != ""
	j.custom_minimum_size.y = 48
	j.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	j.add_theme_color_override("font_color", UiTheme.ACCENT)
	j.pressed.connect(func() -> void: jump_gate.emit(gt))
	row.add_child(j)


## Label mit Zeilenumbruch in die Seitenleiste
func _wrap(l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(l)


## Papiere im Hafen: Betreiber der Tore dieses Sektors, die Papiere verlangen
func _render_papers() -> void:
	var ops := {}
	for gt in game.sector.gates:
		if gt.papers and not String(gt.operator) in game.papers:
			ops[String(gt.operator)] = true
	if ops.is_empty():
		return
	_side.add_child(UiTheme.label("PAPIERE FÜR SPRUNGTORE", 13, UiTheme.MUTED))
	for op in ops:
		var b := UiTheme.button("Papiere: %s (%d Cr)" % [game._operator_name(op), game.papers_price()], "Gelten für alle Tore dieses Betreibers")
		b.disabled = not game.can_buy_papers(op)
		b.pressed.connect(func() -> void:
			game.buy_papers(op)
			Sfx.play(&"klick")
			refresh())
		_side.add_child(b)


## Übersicht aller Sektoren mit ihren Toren (bekannt / unbekannt)
func _show_sectors() -> void:
	_sectors.max_size = Vector2(760, 620)
	_sectors.open("Sektoren")
	_sectors.content.add_child(UiTheme.label("Drei Sektoren, über Sprungtore verbunden; unbekannte werden beim ersten Sprung aufgedeckt.", 13, UiTheme.MUTED))
	for k in game.sectors.size():
		var known := k in game.known_sectors
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.ACCENT if k == game.cur_sector else UiTheme.LINE, 8, 12))
		var v := VBoxContainer.new()
		p.add_child(v)
		v.add_child(UiTheme.label("%s%s" % [_sector_name(k), "  · hier" if k == game.cur_sector else ""], 16, UiTheme.ACCENT if k == game.cur_sector else UiTheme.TEXT))
		if known:
			v.add_child(UiTheme.label("%d Systeme" % game.sectors[k].systems.size(), 13, UiTheme.MUTED))
			for gt in game.sectors[k].gates:
				v.add_child(UiTheme.label("Tor in %s → %s · %d Cr%s" % [game.sectors[k].systems[int(gt.system)].name, _sector_name(int(gt.to_sector)),
					int(gt.fee), " · Papiere nötig" if gt.papers else ""], 13))
		else:
			v.add_child(UiTheme.label("noch nicht besucht", 13, UiTheme.MUTED))
		_sectors.content.add_child(p)
	_sectors.add_close()
