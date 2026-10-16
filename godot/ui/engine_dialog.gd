class_name EngineDialog
extends Modal
## Maschinenraum (früher Hangar): Schiffsausbau je Bereich mit Stufe, nächster Stufe, Werft (Credits, sofort, nur im Hafen)
## und Crew (Material und Tage, überall, nur ein Ausbau zur Zeit). Regeln: ShipUpgrades.

signal changed

var game: HubState


func show_engine(g: HubState) -> void:
	game = g
	max_size = Vector2(1240, 760)
	open("Maschinenraum: Schiffsausbau")
	content.add_child(UiTheme.label("%d Cr · Material %d · %s" % [g.credits, g.material,
		"im Hafen: Werft offen" if g.is_harbor(g.position) else "kein Hafen: Werft geschlossen"], 15))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	for h in ["Bereich", "Stufe", "nächste Stufe", "Werft (sofort, nur im Hafen)", "Crew (überall, Tage)"]:
		grid.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	for id in ShipUpgrades.AREAS:
		_row(grid, id)
	content.add_child(_project_box())
	add_close()


func _row(grid: GridContainer, id: StringName) -> void:
	var lv := ShipUpgrades.level(game, id)
	var maxed := lv >= ShipUpgrades.MAX_LEVEL
	grid.add_child(UiTheme.label(ShipUpgrades.AREAS[id].name, 15))
	grid.add_child(UiTheme.label("●".repeat(lv) + "○".repeat(ShipUpgrades.MAX_LEVEL - lv), 16, UiTheme.ACCENT))
	grid.add_child(UiTheme.label("ausgebaut: " + ShipUpgrades.describe(id, lv) if maxed else
		"%s → %s" % [ShipUpgrades.describe(id, lv), ShipUpgrades.describe(id, lv + 1)], 14, UiTheme.MUTED if maxed else UiTheme.TEXT))
	if maxed:
		grid.add_child(Control.new())
		grid.add_child(Control.new())
		return
	var yard := UiTheme.button("Werft %d Cr" % ShipUpgrades.yard_cost(game, id), "Sofort, nur im Hafen, nur mit genug Credits")
	yard.disabled = not ShipUpgrades.can_yard(game, id)
	yard.pressed.connect(func() -> void:
		ShipUpgrades.buy_yard(game, id)
		Sfx.play(&"klick")
		changed.emit()
		show_engine(game))
	grid.add_child(yard)
	if String(game.project.get("id", "")) == String(id):
		grid.add_child(UiTheme.label("im Bau: noch %d %s" % [game.project.days, "Tag" if int(game.project.days) == 1 else "Tage"], 14, UiTheme.ACCENT))
		return
	var crew := UiTheme.button("Crew: %d Material · %d Tage" % [ShipUpgrades.CREW_MATERIAL[lv], ShipUpgrades.CREW_DAYS[lv]],
		"Material wird sofort verbraucht; am Ende Reparaturprobe. Nur ein Crew-Ausbau zur Zeit.")
	crew.disabled = not ShipUpgrades.can_crew(game, id)
	crew.pressed.connect(func() -> void:
		ShipUpgrades.start_crew(game, id)
		Sfx.play(&"klick")
		changed.emit()
		show_engine(game))
	grid.add_child(crew)


func _project_box() -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.box(UiTheme.BG, UiTheme.ACCENT if ShipUpgrades.busy(game) else UiTheme.LINE, 8, 12))
	var who := Voyage.repairer(game)
	var t := ""
	if ShipUpgrades.busy(game):
		var id := StringName(game.project.id)
		t = "Laufender Crew-Ausbau: %s Stufe %d · noch %d %s · Probe am Ende: %s" % [ShipUpgrades.AREAS[id].name,
			ShipUpgrades.level(game, id) + 1, game.project.days, "Tag" if int(game.project.days) == 1 else "Tage",
			"%s (Reparatur %s)" % [who.name, Dice.fmt(Rules.skill_total(who, ShipUpgrades.SKILL))] if who else "niemand verfügbar"]
	else:
		t = "Kein Crew-Ausbau läuft. Die Tage vergehen beim Reisen, Warten und im Einsatz."
	t += "\nAm Ende eine Reparaturprobe (Station Technik, sonst der Beste): Erfolg = fertig, Teilerfolg = 1 Tag länger, Fehlschlag = 1 Material weg und 1 Tag länger. Wer baut, darf trotzdem in Einsätze."
	var l := UiTheme.label(t, 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p.add_child(l)
	return p
