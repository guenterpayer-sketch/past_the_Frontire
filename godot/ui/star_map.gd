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
## im Raumhafen gekauft (Credits, Treibstoff, Hülle oder Material geändert)
signal bought
## Reiter „Handel“ im Hafen (Kauf/Verkauf, Lager)
signal trade
## große Reparatur durch die Crew (1 Tag)
signal crew_repair
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
var _port_tab := 0            # im Hafen: 0 = Raumhafen, 1 = Crew anheuern
var _repair_btn: Button


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
	_repair_btn = UiTheme.button("Große Reparatur (1 Tag)", "Überall möglich: 1 Tag, 1 Schiffsmaterial, Reparaturprobe. Teilerfolg +10, Erfolg +20, Herausragend +40 Hülle; Fehlschlag ±0, Patzer −5 (Material ist weg)")
	_repair_btn.custom_minimum_size.y = 44
	_repair_btn.pressed.connect(func() -> void: crew_repair.emit())
	top.add_child(_repair_btn)
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
	_status.text = "Tag %d · Position: %s · %s\n%d Cr · Treibstoff %d/%d · Hülle %d/%d · Material %d" % [game.day, sys.name, game.sector.name,
		game.credits, game.fuel, game.tank_max(), game.hull, game.hull_max(), game.material]
	_repair_btn.disabled = not Voyage.can_crew_repair(game)
	var who := Voyage.repairer(game)
	_repair_btn.text = "Große Reparatur (1 Tag)" + ((" · %s %s" % [who.name.split(" ")[0], Dice.fmt(Rules.skill_total(who, &"rsReparatur"))]) if who else "")
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
	if selected != game.position and r.days > 0:
		_render_route(r.days)
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
	elif selected == game.position:
		var tabs := HBoxContainer.new()
		tabs.add_theme_constant_override("separation", 6)
		_side.add_child(tabs)
		var tr := UiTheme.button("Handel …", "Waffen, Rüstungen, Medikits kaufen und aus dem Lager verkaufen")
		tr.custom_minimum_size.y = 40
		tr.pressed.connect(func() -> void: trade.emit())
		for i in 2:
			var t := UiTheme.button(["Raumhafen", "Crew anheuern"][i], "", true)
			t.button_pressed = i == _port_tab
			t.custom_minimum_size.y = 40
			t.pressed.connect(func() -> void:
				_port_tab = i
				refresh())
			tabs.add_child(t)
		tabs.add_child(tr)
		if _port_tab == 0:
			_render_port()
		else:
			_render_harbor()
	else:
		var l := UiTheme.label("Hafen: Raumhafen (Tanken, Werft, Material) und Anheuern, wenn das Schiff hier liegt.", 14, UiTheme.MUTED)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_side.add_child(l)
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
	go.disabled = selected == game.position or r.days < 0 or not game.can_travel(selected)
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
func _render_port() -> void:
	_side.add_child(UiTheme.label("Credits: %d Cr" % game.credits, 16, UiTheme.BAD if game.credits < 0 else UiTheme.ACCENT))
	var price := Voyage.fuel_price(game)
	var need := game.tank_max() - game.fuel
	var fuel := _port_box("Tanken", "Tank %d / %d" % [game.fuel, game.tank_max()],
		"%d Cr je Einheit%s · Tanken geht immer (Notkredit)" % [price, " (nach Notsprit doppelt)" if game.emergency else ""])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for n in [10, 25]:
		var amt := mini(n, need)
		row.add_child(_buy_button("+%d (%d Cr)" % [n, n * price], amt <= 0 or n > need, func() -> void: Voyage.buy_fuel(game, n)))
	row.add_child(_buy_button("Volltanken +%d (%d Cr)" % [need, need * price], need <= 0, func() -> void: Voyage.buy_fuel(game, need)))
	fuel.add_child(row)
	var yard := _port_box("Werft: große Reparatur", "Hülle %d / %d" % [game.hull, game.hull_max()],
		"+%d Hülle für 1 Material + %d Cr Werftlohn%s" % [Voyage.YARD_HULL, Voyage.yard_cost(game), " · Hülle 0: auch auf Notkredit" if Voyage.hull_emergency(game) else ""])
	yard.add_child(_buy_button("1× reparieren (1 Material, %d Cr)" % Voyage.yard_cost(game), not Voyage.can_yard_repair(game), func() -> void: Voyage.yard_repair(game)))
	var mat := _port_box("Schiffsmaterial", "an Bord %d" % game.material, "%d Cr je Einheit · nur für große Reparaturen" % Voyage.material_price(game))
	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 6)
	for n in [1, 3]:
		mrow.add_child(_buy_button("%d kaufen (%d Cr)" % [n, n * Voyage.material_price(game)], not Voyage.can_buy_material(game, n), func() -> void: Voyage.buy_material(game, n)))
	mat.add_child(mrow)
	var am := _port_box("Munition", "", "Je Schuss: Energiezellen %d Cr, Projektil %d Cr, Raketen %d Cr (nach Handeln, Handelsdialog)" % [
		Voyage.ammo_price(game, "energie"), Voyage.ammo_price(game, "projektil"), Voyage.ammo_price(game, "raketen")])
	for t in Voyage.AMMO_START:
		var arow := HBoxContainer.new()
		arow.add_theme_constant_override("separation", 6)
		var nl := UiTheme.label("%s: %d" % [Ammo.TYPES.get(StringName(t), t), int(game.ammo.get(t, 0))], 14)
		nl.custom_minimum_size.x = 150
		arow.add_child(nl)
		for n in Voyage.AMMO_PACKS[t]:
			var cost: int = n * Voyage.ammo_price(game, t)
			arow.add_child(_buy_button("+%d (%d Cr)" % [n, cost], not Voyage.can_buy_ammo(game, t, n), func() -> void: Voyage.buy_ammo(game, t, n)))
		var sn: int = Voyage.AMMO_PACKS[t][0]
		arow.add_child(_buy_button("−%d (+%d Cr)" % [sn, Voyage.ammo_sell(game, t, sn)], not Voyage.can_sell_ammo(game, t, sn),
			func() -> void: Voyage.sell_ammo(game, t, sn)))
		am.add_child(arow)


func _port_box(title: String, value: String, note: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 10))
	_side.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var head := HBoxContainer.new()
	var t := UiTheme.label(title, 15)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(UiTheme.label(value, 14))
	v.add_child(head)
	var l := UiTheme.label(note, 12, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return v


func _buy_button(text: String, off: bool, act: Callable) -> Button:
	var b := UiTheme.button(text)
	b.disabled = off
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(func() -> void:
		act.call()
		Sfx.play(&"klick")
		bought.emit()
		refresh())
	return b


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
