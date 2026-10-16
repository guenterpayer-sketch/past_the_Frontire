class_name CraftDialog
extends Modal
## Werkstatt in der Waffenkammer (Mockup „Schiff-Hub Mockup“, Bildschirme 29–30): Handwerker wählen, Reiter Bauen,
## Zerlegen, Reparieren. Regeln: Crafting. Medikits baut die Krankenstation (MedbayDialog).

signal changed

const TABS := ["Bauen", "Zerlegen", "Reparieren"]

var game: HubState
var tab := 0
var _who: StringName = &""


func show_craft(g: HubState) -> void:
	game = g
	max_size = Vector2(1340, 840)
	refresh()
	move_to_front()


func refresh() -> void:
	var g := game
	var lv := Crafting.level(g)
	open("Werkstatt (Waffenkammer)")
	content.add_child(UiTheme.label("Handwerksmaterial %d · Tag %d · Werkstatt Stufe %d: %s · Ausbau im Maschinenraum" % [
		g.craft_material, g.day, lv, ShipUpgrades.describe(&"workshop", lv)], 15, UiTheme.ACCENT))
	content.add_child(UiTheme.label("HANDWERKER (EINE ARBEIT JE FIGUR, NICHT GESPERRT)", 13, UiTheme.MUTED))
	var crew := Campaign.crew()
	if _pick() == null:
		for c in crew:
			if not Crafting.is_busy(g, c):
				_who = c.id
				break
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 8)
	flow.add_theme_constant_override("v_separation", 8)
	for c in crew:
		var job := Crafting.job_of(g, c)
		var b := UiTheme.button("%s · Waffen %+d · Rüstung %+d\n%s" % [c.name, Rules.skill_total(c, Crafting.SKILL_WEAPON),
			Rules.skill_total(c, Crafting.SKILL_ARMOR), "frei" if job.is_empty() else Crafting.job_text(job)], "", true)
		b.button_pressed = c.id == _who
		b.add_theme_color_override("font_color", UiTheme.GOOD if job.is_empty() else Color("ff8a3d"))
		b.custom_minimum_size.x = 300
		b.pressed.connect(func() -> void:
			_who = c.id
			refresh())
		flow.add_child(b)
	content.add_child(flow)
	var tabs := HBoxContainer.new()
	for i in TABS.size():
		var tb := UiTheme.button(TABS[i], "", true)
		tb.button_pressed = i == tab
		tb.pressed.connect(func() -> void:
			tab = i
			refresh())
		tabs.add_child(tb)
	content.add_child(tabs)
	match tab:
		0:
			_build_list()
		1:
			_take_list()
		_:
			_repair_list()
	add_close()


func _pick() -> Character:
	for c in Campaign.crew():
		if c.id == _who:
			return c
	return null


func _grid(heads: Array) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = heads.size()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 6)
	for h in heads:
		grid.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	content.add_child(grid)
	return grid


func _action(grid: GridContainer, text: String, ok: bool, act: Callable) -> void:
	var b := UiTheme.button(text)
	b.disabled = not ok
	b.pressed.connect(func() -> void:
		act.call()
		Sfx.play(&"klick")
		changed.emit()
		refresh())
	grid.add_child(b)


func _probe(key: String) -> String:
	var c := _pick()
	return "%+d" % Crafting.check_bonus(game, c, key) if c else "–"


func _build_list() -> void:
	var c := _pick()
	var grid := _grid(["Stück", "Kaufpreis", "Material", "Dauer", "Probe" + (" (%s)" % c.name if c else ""), ""])
	for key in Crafting.buildable():
		var open_ := Crafting.unlocked(game, key)
		var m := Crafting.build_material(key)
		var col := UiTheme.TEXT if open_ else UiTheme.MUTED
		grid.add_child(UiTheme.label(Crafting.name_of(key), 15, col))
		grid.add_child(UiTheme.label("%d Cr" % Crafting.price(key), 15, col))
		grid.add_child(UiTheme.label("%d%s" % [m, " (fehlt)" if open_ and m > game.craft_material else ""], 15,
			UiTheme.BAD if open_ and m > game.craft_material else col))
		var d := Crafting.build_days(game, key)
		grid.add_child(UiTheme.label("%d %s" % [d, "Tag" if d == 1 else "Tage"], 15, col))
		grid.add_child(UiTheme.label(_probe(key) if open_ else "–", 15, col))
		if open_:
			_action(grid, "Bauen", Crafting.can_build(game, c, key), func() -> void: Crafting.build(game, c, key))
		else:
			grid.add_child(UiTheme.label("ab Stufe %d" % Crafting.unlock_level(key), 13, UiTheme.MUTED))
	_note("Material 50 %% vom Kaufpreis (1 Material = %d Cr, aufgerundet), sofort verbraucht. Dauer 1 Tag je angefangene %d Cr. Probe „mittel“ am Ende der Arbeit: Patzer = Material weg · Fehlschlag −20 · Teilerfolg −10 · Erfolg heil · Herausragend +5. Munition: Patzer = Material weg, sonst die Menge. Fertiges kommt ins Lager." % [Crafting.MATERIAL_VALUE, Crafting.DAY_PRICE])


func _take_list() -> void:
	var c := _pick()
	var grid := _grid(["Stück", "Lager", "Material: Patzer / Fehlschl. / Teilerf. / Erfolg / Herausr.", "Probe" + (" (%s)" % c.name if c else ""), ""])
	var any := false
	for it in Stock.items(game):
		var key: String = it.key
		if key == Stock.MEDKIT or key == Equipment.SHIELD:
			continue
		any = true
		grid.add_child(UiTheme.label(it.name, 15))
		grid.add_child(UiTheme.label("×%d" % it.count, 15))
		grid.add_child(UiTheme.label(" / ".join(Crafting.TAKE_SHARE.keys().map(func(r: StringName) -> String: return str(Crafting.take_material(key, r)))), 15))
		grid.add_child(UiTheme.label(_probe(key), 15))
		_action(grid, "Zerlegen", Crafting.can_take_apart(game, c, key), func() -> void: Crafting.take_apart(game, c, key))
	if not any:
		content.add_child(UiTheme.label("Keine Waffen oder Rüstungen im Lager.", 14, UiTheme.MUTED))
	_note("Stück sofort aus dem Lager; 1 Tag; Material am Ende nach Ergebnis 0 / 10 / 20 / 30 / 40 % vom Kaufpreis (abgerundet). Getragenes vorher in der Ausrüstung ablegen.")


func _repair_list() -> void:
	var c := _pick()
	var grid := _grid(["Stück", "Lager", "Material", "Werkstatt im Raumhafen zum Vergleich", "Probe" + (" (%s)" % c.name if c else ""), ""])
	var any := false
	for it in Stock.items(game):
		var key: String = it.key
		if int(it.damage) >= 0:
			continue
		any = true
		grid.add_child(UiTheme.label(it.name, 15))
		grid.add_child(UiTheme.label("×%d" % it.count, 15))
		var m := Crafting.repair_material(key)
		grid.add_child(UiTheme.label(str(m), 15, UiTheme.BAD if m > game.craft_material else UiTheme.TEXT))
		grid.add_child(UiTheme.label("%d Cr" % roundi(Stock.price(key) * Stock.REPAIR_SHARE * Stock.damage_steps(key)), 15, UiTheme.MUTED))
		grid.add_child(UiTheme.label(_probe(key), 15))
		_action(grid, "Reparieren", Crafting.can_repair(game, c, key), func() -> void: Crafting.repair(game, c, key))
	if not any:
		content.add_child(UiTheme.label("Keine beschädigten Stücke im Lager.", 14, UiTheme.MUTED))
	_note("Material 5 % vom Kaufpreis je −10 (aufgerundet), sofort verbraucht; 1 Tag; das Stück bleibt während der Arbeit in der Werkstatt. Ergebnis: Patzer −10 mehr · Fehlschlag nichts · Teilerfolg −10 weg · Erfolg heil · Herausragend heil und Material zurück. Nur Stücke im Lager.")


func _note(text: String) -> void:
	var l := UiTheme.label(text, 13, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(l)
