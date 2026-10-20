class_name TradeDialog
extends Modal
## Raumhafen „Händler“ (Ausrüstung der Crew, Mockup Bildschirm 38): links das Sortiment des Hafens (kaufen ins Lager),
## Munition und Handwerksmaterial, rechts das Lager des Schiffs (verkaufen) und die Werkstatt für beschädigte Stücke.
## Alles nach Handeln; Regeln und Preise: Stock, Voyage, Crafting. Schiffsbedarf: PortDialog (Schiffshändler).

signal changed

var game: HubState


func show_trade(g: HubState) -> void:
	game = g
	max_size = Vector2(1300, 820)
	open("%s: Händler" % g.market_title())
	content.add_child(UiTheme.label("Credits: %d Cr · Tag %d · Sortiment wechselt alle %d Tage" % [g.credits, g.day, Stock.SHOP_DAYS], 16, UiTheme.ACCENT))
	content.add_child(UiTheme.label("PROBEN HEUTE (je Fertigkeit eine pro Tag; ohne Probe wie Fehlschlag: 5 % schlechter)", 13, UiTheme.MUTED))
	for sk in [&"handeln", &"gassenwissen"]:
		content.add_child(skill_row(g, sk, func() -> void:
			changed.emit()
			show_trade(game)))
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
	buy.add_child(UiTheme.label("MUNITION UND HANDWERKSMATERIAL", 13, UiTheme.MUTED))
	for t in Voyage.AMMO_START:
		var packs: Array = Voyage.AMMO_PACKS[t]
		var n1: int = packs[0]
		var n2: int = packs[1]
		var ar := _row("%s · Vorrat %d" % [Ammo.TYPES.get(StringName(t), t), int(g.ammo.get(t, 0))], "", "%d Cr" % Voyage.ammo_price(g, t),
			"+%d" % n1, Voyage.can_buy_ammo(g, t, n1), func() -> void: Voyage.buy_ammo(g, t, n1))
		ar.get_child(0).add_child(_button("+%d" % n2, Voyage.can_buy_ammo(g, t, n2), func() -> void: Voyage.buy_ammo(g, t, n2)))
		ar.get_child(0).add_child(_button("−%d (+%d)" % [n1, Voyage.ammo_sell(g, t, n1)], Voyage.can_sell_ammo(g, t, n1), func() -> void: Voyage.sell_ammo(g, t, n1)))
		buy.add_child(ar)
	var cm := _row("Handwerksmaterial · an Bord %d" % g.craft_material, "", "%d Cr" % Crafting.material_price(g), "+1",
		Crafting.can_buy_material(g, 1), func() -> void: Crafting.buy_material(g, 1))
	cm.get_child(0).add_child(_button("+10", Crafting.can_buy_material(g, 10), func() -> void: Crafting.buy_material(g, 10)))
	cm.get_child(0).add_child(_button("−1 (+%d)" % Crafting.material_sell(g), Crafting.can_sell_material(g), func() -> void: Crafting.sell_material(g)))
	buy.add_child(cm)
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
	var note := UiTheme.label("Was die Crew trägt, gehört nicht zum Lager (erst in der Waffenkammer ablegen). Beschädigt: Verkauf je −10 um %d %% weniger; Werkstatt %d %% vom Kaufpreis je −10, nach Handeln, sofort und ganz. Treibstoff, Proviant, Schiffsmaterial und Schiffswaffen: Schiffshändler." % [roundi(Stock.SELL_DAMAGE_STEP * 100), roundi(Stock.REPAIR_SHARE * 100)], 13, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sell.add_child(note)
	add_close()


## Preis mit Normalpreis in Klammern, wenn er abweicht (good = höher ist besser, beim Verkauf)
func _price(now: int, normal: int, good_up: bool) -> String:
	return "%d Cr" % now if now == normal else "%d Cr (%d)" % [now, normal]


## Zeile je Handelsfertigkeit: Figur wählen, würfeln, Ergebnis (auch im Schiffshändler); after = neu zeichnen
static func skill_row(game: HubState, sk: StringName, after: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.LINE, 8, 8))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	p.add_child(row)
	var name := UiTheme.label(Rules.skill_name(sk), 15)
	name.custom_minimum_size.x = 130
	name.tooltip_text = {&"handeln": "Waffen, Rüstungen, Schilde, Medikits, Munition, Handwerksmaterial: Kauf und Verkauf", &"verhandeln": "Treibstoff, Proviant, Werft, Schiffsmaterial, Werft-Ausbau, Schiffswaffen und Schiffsmunition (Kauf und Verkauf)",
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
			after.call())
		row.add_child(b)
		var nl := UiTheme.label("noch nicht gewürfelt – " + TradeSkills.effect_text(sk, TradeSkills.NONE), 14, UiTheme.MUTED)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
	else:
		var res := StringName(r.result)
		var col := UiTheme.GOOD if res in [&"erfolg", &"herausragend"] else (UiTheme.TEXT if res == &"teilerfolg" else Color("ff8a3d"))
		var rl := UiTheme.label("%s: %s %d → %s" % [r.name, r.result_name, int(r.total), TradeSkills.effect_text(sk, res)], 14, col)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(rl)
	return p


func _row(name: String, count: String, price: String, action: String, ok: bool, act: Callable) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.PANEL2, UiTheme.PANEL2, 6, 6))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	p.add_child(row)
	var n := UiTheme.label(name, 15)
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Name darf umbrechen, damit die Zeile schmaler werden kann (lange Liste mit Bildlaufleiste)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size.x = 120
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
