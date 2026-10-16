class_name TradeDialog
extends Modal
## Raumhafen „Handel“: links das Sortiment des Hafens (kaufen ins Lager), rechts das Lager des Schiffs (verkaufen zum
## halben Preis). Regeln und Preise: Stock.

signal changed

var game: HubState


func show_trade(g: HubState) -> void:
	game = g
	max_size = Vector2(1300, 820)
	open("Raumhafen %s: Handel" % g.sector.systems[g.position].name)
	content.add_child(UiTheme.label("Credits: %d Cr · Sortiment wechselt alle %d Tage" % [g.credits, Stock.SHOP_DAYS], 16, UiTheme.ACCENT))
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	content.add_child(cols)
	var buy := VBoxContainer.new()
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.add_theme_constant_override("separation", 4)
	cols.add_child(buy)
	buy.add_child(UiTheme.label("KAUFEN (SORTIMENT)", 13, UiTheme.MUTED))
	for key in Stock.shop(g, g.position):
		buy.add_child(_row(Stock.name_of(key), "", "%d Cr" % Stock.price(key), "Kaufen", Stock.can_buy(g, key), func() -> void: Stock.buy(g, key)))
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.x = 1
	cols.add_child(sep)
	var sell := VBoxContainer.new()
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.add_theme_constant_override("separation", 4)
	cols.add_child(sell)
	sell.add_child(UiTheme.label("LAGER DES SCHIFFS (VERKAUFEN %d %%)" % roundi(Stock.SELL_FACTOR * 100), 13, UiTheme.MUTED))
	var items := Stock.items(g)
	if items.is_empty():
		sell.add_child(UiTheme.label("Lager leer", 14, UiTheme.MUTED))
	for it in items:
		var key: String = it.key
		sell.add_child(_row(it.name, "×%d" % it.count, "%d Cr" % Stock.sell_price(key), "Verkaufen", Stock.can_sell(g, key), func() -> void: Stock.sell(g, key)))
	var note := UiTheme.label("Was die Crew trägt, gehört nicht zum Lager. Munition und Schiffsmaterial: Reiter „Raumhafen“.", 13, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sell.add_child(note)
	add_close()


func _row(name: String, count: String, price: String, action: String, ok: bool, act: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.PANEL2, 6, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	var n := UiTheme.label(name, 15)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(n)
	if count != "":
		row.add_child(UiTheme.label(count, 15, UiTheme.ACCENT))
	var pl := UiTheme.label(price, 14, UiTheme.MUTED)
	pl.custom_minimum_size.x = 70
	row.add_child(pl)
	var b := UiTheme.button(action)
	b.disabled = not ok
	b.custom_minimum_size.x = 100
	b.pressed.connect(func() -> void:
		act.call()
		Sfx.play(&"klick")
		changed.emit()
		show_trade(game))
	row.add_child(b)
	return p
