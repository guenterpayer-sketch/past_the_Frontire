class_name TradeDialog
extends Modal
## Raumhafen „Handel“: links das Sortiment des Hafens (kaufen ins Lager), rechts das Lager des Schiffs (verkaufen zum
## halben Preis) und die Werkstatt für beschädigte Stücke (Mockup Bildschirm 28). Regeln und Preise: Stock.
## Reiter „Schiff“ (Mockup Bildschirm 35): Schiffswaffen im Sortiment und im Lager, Schiffsmunition, nach Verhandeln (ShipArms).

signal changed

var game: HubState
var _tab := 0                 # 0 = Ausrüstung, 1 = Schiff


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
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	content.add_child(tabs)
	for i in 2:
		var t := UiTheme.button(["Ausrüstung", "Schiff"][i], "", true)
		t.button_pressed = i == _tab
		t.pressed.connect(func() -> void:
			_tab = i
			show_trade(game))
		tabs.add_child(t)
	if _tab == 1:
		_render_ship(g)
		add_close()
		return
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
	sell.add_child(UiTheme.label("LAGER DES SCHIFFS (VERKAUFEN %d %%) UND WERKSTATT" % roundi(TradeSkills.sell_factor(g) * 100), 13, UiTheme.MUTED))
	var items := Stock.items(g)
	if items.is_empty():
		sell.add_child(UiTheme.label("Lager leer", 14, UiTheme.MUTED))
	for it in items:
		var key: String = it.key
		var row := _row(it.name, "×%d" % it.count, _price(Stock.sell_price(key, g), Stock.sell_price(key), true), "Verkaufen", Stock.can_sell(g, key), func() -> void: Stock.sell(g, key))
		if int(it.damage) < 0:
			var rc := Stock.repair_cost(g, key)
			row.get_child(0).add_child(_button("Reparieren %d Cr" % rc, Stock.can_repair(g, key), func() -> void: Stock.repair(g, key)))
		sell.add_child(row)
	var note := UiTheme.label("Was die Crew trägt, gehört nicht zum Lager (erst in der Waffenkammer ablegen). Beschädigt: Verkauf je −10 um %d %% weniger; Werkstatt %d %% vom Kaufpreis je −10, nach Handeln, sofort und ganz. Munition und Schiffsmaterial: Reiter „Raumhafen“." % [roundi(Stock.SELL_DAMAGE_STEP * 100), roundi(Stock.REPAIR_SHARE * 100)], 13, UiTheme.MUTED)
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
	name.tooltip_text = {&"handeln": "Waffen, Rüstungen, Munition, Medikits: Kauf und Verkauf", &"verhandeln": "Treibstoff, Werft, Schiffsmaterial, Werft-Ausbau, Schiffswaffen und Schiffsmunition (Kauf und Verkauf)",
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
	row.add_child(_button(action, ok, act))
	return p


## Knopf, der handelt und den Dialog neu aufbaut
func _button(action: String, ok: bool, act: Callable) -> Button:
	var b := UiTheme.button(action)
	b.disabled = not ok
	b.custom_minimum_size.x = 100
	b.pressed.connect(func() -> void:
		act.call()
		Sfx.play(&"klick")
		changed.emit()
		show_trade(game))
	return b


# ---------------------------------------------------------------- Reiter „Schiff“

func _render_ship(g: HubState) -> void:
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)
	content.add_child(cols)
	var buy := _col(cols)
	buy.add_child(UiTheme.label("SCHIFFSWAFFEN IM SORTIMENT (%d %%, NACH GASSENWISSEN)" % roundi(TradeSkills.shop_share(g) * 100), 13, UiTheme.MUTED))
	for key in ShipArms.shop(g, g.position):
		buy.add_child(_row("%s · %s" % [ShipArms.name(key), ShipArms.kind(key)], "", _price(ShipArms.buy_price(g, key), ShipArms.price(key), false),
			"Kaufen", ShipArms.can_buy(g, key), func() -> void: ShipArms.buy(g, key)))
	buy.add_child(UiTheme.label("SCHIFFSMUNITION (KAUF NACH VERHANDELN)", 13, UiTheme.MUTED))
	for t in ShipArms.AMMO_NAMES:
		var p := _row("%s · Vorrat %d" % [ShipArms.AMMO_NAMES[t], int(g.ship_ammo.get(t, 0))], "", "%d Cr" % ShipArms.ammo_price(g, t),
			"+%d" % ShipArms.AMMO_PACKS[t][0], ShipArms.can_buy_ammo(g, t, ShipArms.AMMO_PACKS[t][0]),
			func() -> void: ShipArms.buy_ammo(g, t, ShipArms.AMMO_PACKS[t][0]))
		var n2: int = ShipArms.AMMO_PACKS[t][1]
		p.get_child(0).add_child(_button("+%d" % n2, ShipArms.can_buy_ammo(g, t, n2), func() -> void: ShipArms.buy_ammo(g, t, n2)))
		buy.add_child(p)
	var sep := ColorRect.new()
	sep.color = UiTheme.LINE
	sep.custom_minimum_size.x = 1
	cols.add_child(sep)
	var sell := _col(cols)
	sell.add_child(UiTheme.label("LAGER: SCHIFFSWAFFEN, NICHT EINGEBAUT (VERKAUFEN %d %%)" % roundi(TradeSkills.ship_sell_factor(g) * 100), 13, UiTheme.MUTED))
	var items := ShipArms.stock_items(g)
	if items.is_empty():
		sell.add_child(UiTheme.label("keine", 14, UiTheme.MUTED))
	for it in items:
		var key: String = it.key
		sell.add_child(_row(it.name, "×%d" % it.count, "%d Cr" % ShipArms.sell_price(g, key), "Verkaufen", ShipArms.can_sell(g, key),
			func() -> void: ShipArms.sell(g, key)))
	sell.add_child(UiTheme.label("SCHIFFSMUNITION VERKAUFEN", 13, UiTheme.MUTED))
	for t in ShipArms.AMMO_NAMES:
		var n1: int = ShipArms.AMMO_PACKS[t][0]
		var n2: int = ShipArms.AMMO_PACKS[t][1]
		var p := _row(ShipArms.AMMO_NAMES[t], "", "%d Cr" % ShipArms.ammo_sell(g, t, n1), "−%d" % n1, ShipArms.can_sell_ammo(g, t, n1),
			func() -> void: ShipArms.sell_ammo(g, t, n1))
		p.get_child(0).add_child(_button("−%d" % n2, ShipArms.can_sell_ammo(g, t, n2), func() -> void: ShipArms.sell_ammo(g, t, n2)))
		sell.add_child(p)
	var note := UiTheme.label("Preise der Schiffswaffen: Platzhalter, bis der Raumkampf seinen Katalog liefert. Kauf und Verkauf nach Verhandeln, beschädigt je −10 um %d %% weniger. Gekaufte Waffen gehen ins Lager, Einbau im Maschinenraum (nur im Hafen). Schiffsraketen %d Cr, Geschosse %d Cr." % [
		roundi(ShipArms.SELL_DAMAGE_STEP * 100), ShipArms.AMMO_PRICE.schiffsraketen, ShipArms.AMMO_PRICE.geschosse], 13, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(note)


func _col(parent: Control) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	parent.add_child(v)
	return v
