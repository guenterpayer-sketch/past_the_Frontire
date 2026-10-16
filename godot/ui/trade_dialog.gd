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
	content.add_child(UiTheme.label("Credits: %d Cr · Tag %d · Sortiment wechselt alle %d Tage" % [g.credits, g.day, Stock.SHOP_DAYS], 16, UiTheme.ACCENT))
	content.add_child(UiTheme.label("PROBEN HEUTE (je Fertigkeit eine pro Tag; ohne Probe wie Fehlschlag: 5 % schlechter)", 13, UiTheme.MUTED))
	for sk in TradeSkills.SKILLS:
		content.add_child(_skill_row(sk))
	var line := ColorRect.new()
	line.color = UiTheme.LINE
	line.custom_minimum_size.y = 1
	content.add_child(line)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	content.add_child(cols)
	var buy := VBoxContainer.new()
	buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy.add_theme_constant_override("separation", 4)
	cols.add_child(buy)
	buy.add_child(UiTheme.label("KAUFEN (SORTIMENT %d %%)" % roundi(TradeSkills.shop_share(g) * 100), 13, UiTheme.MUTED))
	for key in Stock.shop(g, g.position):
		buy.add_child(_row(Stock.name_of(key), "", _price(Stock.buy_price(g, key), Stock.price(key), false), "Kaufen", Stock.can_buy(g, key), func() -> void: Stock.buy(g, key)))
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.x = 1
	cols.add_child(sep)
	var sell := VBoxContainer.new()
	sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell.add_theme_constant_override("separation", 4)
	cols.add_child(sell)
	sell.add_child(UiTheme.label("LAGER DES SCHIFFS (VERKAUFEN %d %%)" % roundi(TradeSkills.sell_factor(g) * 100), 13, UiTheme.MUTED))
	var items := Stock.items(g)
	if items.is_empty():
		sell.add_child(UiTheme.label("Lager leer", 14, UiTheme.MUTED))
	for it in items:
		var key: String = it.key
		sell.add_child(_row(it.name, "×%d" % it.count, _price(Stock.sell_price(key, g), Stock.sell_price(key), true), "Verkaufen", Stock.can_sell(g, key), func() -> void: Stock.sell(g, key)))
	var note := UiTheme.label("Was die Crew trägt, gehört nicht zum Lager. Munition und Schiffsmaterial: Reiter „Raumhafen“.", 13, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sell.add_child(note)
	add_close()


## Preis mit Normalpreis in Klammern, wenn er abweicht (good = höher ist besser, beim Verkauf)
func _price(now: int, normal: int, good_up: bool) -> String:
	return "%d Cr" % now if now == normal else "%d Cr (%d)" % [now, normal]


## Zeile je Handelsfertigkeit: Figur wählen, würfeln, Ergebnis
func _skill_row(sk: StringName) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	p.add_child(row)
	var name := UiTheme.label(Rules.skill_name(sk), 15)
	name.custom_minimum_size.x = 130
	name.tooltip_text = {&"handeln": "Waffen, Rüstungen, Munition, Medikits: Kauf und Verkauf", &"verhandeln": "Treibstoff, Werft, Schiffsmaterial, Werft-Ausbau",
		&"gassenwissen": "Größe des Sortiments"}[sk]
	name.mouse_filter = Control.MOUSE_FILTER_STOP
	row.add_child(name)
	var r := TradeSkills.roll_of(game, sk)
	var crew := Campaign.crew()
	if r.is_empty():
		var pick := OptionButton.new()
		pick.custom_minimum_size = Vector2(260, 34)
		var best := 0
		for i in crew.size():
			pick.add_item("%s (%s)" % [crew[i].name, Dice.fmt(Rules.skill_total(crew[i], sk))], i)
			if Rules.skill_total(crew[i], sk) > Rules.skill_total(crew[best], sk):
				best = i
		pick.select(best)
		row.add_child(pick)
		var b := UiTheme.button("Würfeln")
		b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.disabled = crew.is_empty() or not TradeSkills.can_roll(game, sk)
		b.pressed.connect(func() -> void:
			TradeSkills.roll(game, sk, crew[pick.selected])
			Sfx.play(&"wuerfel")
			changed.emit()
			show_trade(game))
		row.add_child(b)
		row.add_child(UiTheme.label("noch nicht gewürfelt – " + TradeSkills.effect_text(sk, TradeSkills.NONE), 14, UiTheme.MUTED))
	else:
		var res := StringName(r.result)
		var col := UiTheme.GOOD if res in [&"erfolg", &"herausragend"] else (UiTheme.TEXT if res == &"teilerfolg" else Color("ff8a3d"))
		row.add_child(UiTheme.label("%s: %s %d → %s" % [r.name, r.result_name, int(r.total), TradeSkills.effect_text(sk, res)], 14, col))
	return p


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
