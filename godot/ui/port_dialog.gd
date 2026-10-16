class_name PortDialog
extends Modal
## Raumhafen in eigenen Fenstern (Mockup „Schiff-Hub Mockup“ Bildschirme 36–39, Entscheidungen des Nutzers 16.10.2026):
## Schiffshändler (Treibstoff, Schiffsmaterial, Proviant, Schiffsmunition, Schiffswaffen; alles nach Verhandeln) und
## Crew anheuern. Händler = TradeDialog, Werft = ShipArmsDialog.show_yard().

signal changed
signal hired(ch: Character)

var game: HubState
var _mode := &"ship"


func show_ship(g: HubState) -> void:
	game = g
	_mode = &"ship"
	_render()


func show_hire(g: HubState) -> void:
	game = g
	_mode = &"hire"
	_render()


func _render() -> void:
	max_size = Vector2(1300, 820)
	var port: String = game.sector.systems[game.position].name
	if _mode == &"ship":
		open("Raumhafen %s: Schiffshändler" % port)
		_render_ship()
	else:
		open("Raumhafen %s: Crew anheuern" % port)
		_render_hire()
	add_close()


func _again() -> void:
	Sfx.play(&"klick")
	changed.emit()
	_render()


# ---------------------------------------------------------------- Schiffshändler

func _render_ship() -> void:
	var g := game
	content.add_child(UiTheme.label("Credits: %d Cr · Tag %d" % [g.credits, g.day], 16, UiTheme.BAD if g.credits < 0 else UiTheme.ACCENT))
	content.add_child(UiTheme.label("PROBEN HEUTE (je Fertigkeit eine pro Tag; ohne Probe wie Fehlschlag: 5 % schlechter)", 13, UiTheme.MUTED))
	for sk in [&"verhandeln", &"gassenwissen"]:
		content.add_child(TradeDialog.skill_row(g, sk, func() -> void: _again()))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	content.add_child(cols)
	var left := _col(cols)
	left.add_child(UiTheme.label("VORRÄTE", 13, UiTheme.MUTED))
	var price := Voyage.fuel_price(g)
	var need := g.tank_max() - g.fuel
	var fuel := _box(left, "Treibstoff", "Tank %d / %d" % [g.fuel, g.tank_max()],
		"%d Cr je Einheit%s · Tanken geht immer (Notkredit)" % [price, " (nach Notsprit doppelt)" if g.emergency else ""])
	var row := _row(fuel)
	for n in [10, 25]:
		row.add_child(_btn("+%d (%d Cr)" % [n, n * price], n > need, func() -> void: Voyage.buy_fuel(g, n)))
	row.add_child(_btn("Volltanken +%d (%d Cr)" % [need, need * price], need <= 0, func() -> void: Voyage.buy_fuel(g, need)))
	var mat := _box(left, "Schiffsmaterial", "an Bord %d" % g.material, "%d Cr je Einheit · für Reparaturen und Crew-Ausbau" % Voyage.material_price(g))
	var mrow := _row(mat)
	for n in [1, 3]:
		mrow.add_child(_btn("%d kaufen (%d Cr)" % [n, n * Voyage.material_price(g)], not Voyage.can_buy_material(g, n), func() -> void: Voyage.buy_material(g, n)))
	var fill := Galley.fill_amount(g)
	var pv := _box(left, "Proviant", "an Bord %d · %d je Tag außerhalb des Hafens" % [g.provisions, Galley.need()],
		"%d Cr je Einheit · im Hafen kein Verbrauch · ohne Proviant %d auf Proben im Schiff" % [Galley.price(g), Galley.MALUS])
	var prow := _row(pv)
	for n in [10, 30]:
		prow.add_child(_btn("+%d (%d Cr)" % [n, n * Galley.price(g)], not Galley.can_buy(g, n), func() -> void: Galley.buy(g, n)))
	prow.add_child(_btn("bis %d Tage +%d (%d Cr)" % [Galley.FILL_DAYS, fill, fill * Galley.price(g)], not Galley.can_buy(g, fill),
		func() -> void: Galley.buy(g, fill)))
	for t in ShipArms.AMMO_NAMES:
		var n1: int = ShipArms.AMMO_PACKS[t][0]
		var n2: int = ShipArms.AMMO_PACKS[t][1]
		var am := _box(left, String(ShipArms.AMMO_NAMES[t]), "Vorrat %d" % int(g.ship_ammo.get(t, 0)),
			"%d Cr je Stück · Verkauf %d Cr" % [ShipArms.ammo_price(g, t), ShipArms.ammo_sell(g, t, 1)])
		var arow := _row(am)
		for n in [n1, n2]:
			arow.add_child(_btn("+%d (%d Cr)" % [n, n * ShipArms.ammo_price(g, t)], not ShipArms.can_buy_ammo(g, t, n), func() -> void: ShipArms.buy_ammo(g, t, n)))
		arow.add_child(_btn("−%d (+%d Cr)" % [n1, ShipArms.ammo_sell(g, t, n1)], not ShipArms.can_sell_ammo(g, t, n1), func() -> void: ShipArms.sell_ammo(g, t, n1)))
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.x = 1
	cols.add_child(sep)
	var right := _col(cols)
	right.add_child(UiTheme.label("SCHIFFSWAFFEN IM SORTIMENT (%d %%, NACH GASSENWISSEN)" % roundi(TradeSkills.shop_share(g) * 100), 13, UiTheme.MUTED))
	for key in ShipArms.shop(g, g.position):
		right.add_child(_item("%s · %s" % [ShipArms.name(key), ShipArms.kind(key)], "%d Cr" % ShipArms.buy_price(g, key), "Kaufen",
			ShipArms.can_buy(g, key), func() -> void: ShipArms.buy(g, key)))
	right.add_child(UiTheme.label("LAGER: SCHIFFSWAFFEN, NICHT EINGEBAUT (VERKAUFEN %d %%)" % roundi(TradeSkills.ship_sell_factor(g) * 100), 13, UiTheme.MUTED))
	var items := ShipArms.stock_items(g)
	if items.is_empty():
		right.add_child(UiTheme.label("keine", 14, UiTheme.MUTED))
	for it in items:
		var key: String = it.key
		right.add_child(_item("%s ×%d" % [it.name, it.count], "%d Cr" % ShipArms.sell_price(g, key), "Verkaufen", ShipArms.can_sell(g, key),
			func() -> void: ShipArms.sell(g, key)))
	_note("Alles nach Verhandeln. Preise der Schiffswaffen: Platzhalter, bis der Raumkampf seinen Katalog liefert; beschädigt je −10 um %d %% weniger. Gekaufte Schiffswaffen gehen ins Lager, einbauen in der Werft." % roundi(ShipArms.SELL_DAMAGE_STEP * 100))


# ---------------------------------------------------------------- Crew anheuern

## Anheuern aus der Liste „im Hafen“ (mit Fortschritt) und aus dem Roster, nur bei freiem Platz
func _render_hire() -> void:
	var free := game.free_berths()
	content.add_child(UiTheme.label("Plätze an Bord %d / %d" % [Campaign.crew().size(), game.berths], 16, UiTheme.GOOD if free > 0 else UiTheme.BAD))
	var waiting := Campaign.harbor()
	content.add_child(UiTheme.label("IM HAFEN (ENTLASSEN, MIT FORTSCHRITT)", 13, UiTheme.MUTED))
	if waiting.is_empty():
		content.add_child(UiTheme.label("niemand", 14, UiTheme.MUTED))
	for c in waiting:
		content.add_child(_hire_row(c, "wartet mit Fortschritt" + ((" · " + c.injury_text()) if c.injury != "" else ""), free))
	content.add_child(UiTheme.label("AUS DEM ROSTER (STAND DES ROSTERS)", 13, UiTheme.MUTED))
	var any := false
	for r in GlobalRoster.entries():
		var rid: StringName = r.roster_id if r.roster_id != &"" else r.id
		if Campaign.is_aboard(rid) or waiting.any(func(h: Character) -> bool: return h.roster_id == rid):
			continue
		any = true
		content.add_child(_hire_row(r, r.role, free))
	if not any:
		content.add_child(UiTheme.label("alle Roster-Figuren sind an Bord oder im Hafen", 14, UiTheme.MUTED))


func _hire_row(c: Character, note: String, free: int) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.PANEL2, 6, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	p.add_child(row)
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
			hired.emit(h)
		_again())
	row.add_child(b)
	return p


# ---------------------------------------------------------------- Hilfen

func _col(parent: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	parent.add_child(v)
	return v


func _box(parent: Control, title: String, value: String, note: String) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 10))
	parent.add_child(p)
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


func _row(parent: Control) -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	parent.add_child(r)
	return r


func _btn(text: String, off: bool, act: Callable) -> Button:
	var b := UiTheme.button(text)
	b.disabled = off
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 13)
	b.pressed.connect(func() -> void:
		act.call()
		_again())
	return b


func _item(name: String, price: String, action: String, ok: bool, act: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.PANEL2, 6, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	var n := UiTheme.label(name, 15)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	var pl := UiTheme.label(price, 14, UiTheme.MUTED)
	pl.custom_minimum_size.x = 70
	row.add_child(pl)
	var b := UiTheme.button(action)
	b.disabled = not ok
	b.custom_minimum_size.x = 100
	b.pressed.connect(func() -> void:
		act.call()
		_again())
	row.add_child(b)
	return p


func _note(text: String) -> void:
	var l := UiTheme.label(text, 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)
