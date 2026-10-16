class_name GalleyDialog
extends Modal
## Kombüse (Mockup „Frontire Kombüse und Proviant“, vom Nutzer bestätigt 16.10.2026): Koch wählen, Vorrat,
## Verbrauch je Ergebnis der Kochprobe, letzte Kochproben, Hinweis auf den Trainingsbonus. Regeln: Galley.

signal changed
signal wait_day

var game: HubState


func show_galley(g: HubState) -> void:
	game = g
	open("Kombüse")
	var intro := UiTheme.label("Tag %d. Der Koch würfelt jeden Tag außerhalb des Hafens eine Kochprobe (Kochen, EMP + KOO) und bekommt EP. Das Ergebnis bestimmt den Verbrauch dieses Tages. Ohne Koch: normaler Verbrauch. Im Raumhafen wird nicht gekocht und nichts verbraucht." % g.day, 13, UiTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	content.add_child(cols)
	cols.add_child(_cooks())
	cols.add_child(_stock())
	content.add_child(_log())
	var wait := UiTheme.button("1 Tag warten")
	wait.add_theme_color_override("font_color", UiTheme.ACCENT)
	wait.pressed.connect(func() -> void: wait_day.emit())
	footer.add_child(wait)
	add_close()


func refresh() -> void:
	if visible:
		show_galley(game)


func _cooks() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 380
	v.add_child(UiTheme.label("KOCH", 13, UiTheme.MUTED))
	var cur := Galley.cook(game)
	for c in Campaign.crew():
		var roles := []
		if String(c.id) in game.medics:
			roles.append("Krankenstation")
		if game.jobs.has(String(c.id)):
			roles.append("Werkstatt")
		if c.is_locked():
			roles.append("verwundet, kocht nicht")
		var b := UiTheme.button("%s%s%s   Kochen %s" % ["▸ " if c == cur else "", c.name, (" · " + ", ".join(roles)) if not roles.is_empty() else "",
			Dice.fmt(Rules.skill_total(c, Galley.SKILL))], "%s als Koch einstellen" % c.name)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if c == cur:
			b.add_theme_color_override("font_color", UiTheme.ACCENT)
		b.pressed.connect(func() -> void:
			Galley.set_cook(game, c)
			Sfx.play(&"klick")
			changed.emit()
			refresh())
		v.add_child(b)
	var none := UiTheme.button(("▸ " if cur == null else "") + "kein Koch   (normaler Verbrauch)")
	none.alignment = HORIZONTAL_ALIGNMENT_LEFT
	none.pressed.connect(func() -> void:
		Galley.set_cook(game, null)
		changed.emit()
		refresh())
	v.add_child(none)
	var n := UiTheme.label("Der Koch darf zugleich Arzt, Helfer oder Handwerker sein.", 12, UiTheme.MUTED)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(n)
	return v


func _stock() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiTheme.label("VORRAT", 13, UiTheme.MUTED))
	v.add_child(UiTheme.label("%d Proviant" % game.provisions, 20, UiTheme.BAD if game.provisions <= 0 else UiTheme.TEXT))
	if game.provisions <= 0:
		v.add_child(UiTheme.label("Leer: %d auf Proben im Schiff, bis wieder Proviant gekauft ist (Sternenkarte, Reiter „Raumhafen“)." % Galley.MALUS, 13, UiTheme.BAD))
	elif game.is_harbor(game.position):
		v.add_child(UiTheme.label("Im Hafen: kein Verbrauch. Kaufen auf der Brücke, Sternenkarte, Reiter „Raumhafen“.", 13, UiTheme.MUTED))
	else:
		v.add_child(UiTheme.label("reicht etwa %d Tage bei normalem Verbrauch" % Galley.days_left(game), 13, UiTheme.MUTED))
	var n := Campaign.crew().size()
	var g := GridContainer.new()
	g.columns = 3
	g.add_theme_constant_override("h_separation", 16)
	for h in ["Ergebnis der Kochprobe", "Verbrauch", "bei %d an Bord" % n]:
		g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
	for row in [[&"patzer", "Patzer", "+25 %"], [&"fehlschlag", "Fehlschlag / ohne Koch", "normal"], [&"teilerfolg", "Teilerfolg", "−10 %"],
			[&"erfolg", "Erfolg", "−20 %"], [&"herausragend", "Herausragend", "−30 %"]]:
		g.add_child(UiTheme.label(row[1], 14, HubUI.cook_color({"result": String(row[0])})))
		g.add_child(UiTheme.label(row[2], 14))
		g.add_child(UiTheme.label(str(Galley.need(row[0])), 14))
	v.add_child(g)
	var note := UiTheme.label("1 je Crewmitglied an Bord und Tag, kaufmännisch gerundet, mindestens 1.", 12, UiTheme.MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(note)
	return v


func _log() -> Control:
	var v := VBoxContainer.new()
	v.add_child(UiTheme.label("LETZTE KOCHPROBEN", 13, UiTheme.MUTED))
	if game.cooklog.is_empty():
		v.add_child(UiTheme.label("–", 14, UiTheme.MUTED))
	else:
		var g := GridContainer.new()
		g.columns = 5
		g.add_theme_constant_override("h_separation", 18)
		for h in ["Tag", "Koch", "Probe", "Verbrauch", "Proviant"]:
			g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
		for i in mini(8, game.cooklog.size()):
			var e: Dictionary = game.cooklog[i]
			g.add_child(UiTheme.label(str(e.day), 14))
			g.add_child(UiTheme.label(String(e.cook) if String(e.cook) != "" else "–", 14, UiTheme.CREW))
			g.add_child(UiTheme.label(("%d · %s" % [int(e.total), e.result_name]) if String(e.cook) != "" else String(e.result_name), 14, HubUI.cook_color(e)))
			g.add_child(UiTheme.label(str(e.use), 14))
			g.add_child(UiTheme.label("%d → %d" % [e.p0, e.p1], 14, UiTheme.BAD if int(e.p1) <= 0 else UiTheme.TEXT))
		v.add_child(g)
	var last := game.day / HubState.TRAINING_DAYS * HubState.TRAINING_DAYS
	var next := last + HubState.TRAINING_DAYS
	var t := "Herausragend seit dem letzten Training: %s → das Training an Tag %d gibt %d freie EP." % [
		"ja" if Galley.bonus_pending(game) else "nein", next, game.training_xp() + (Galley.TRAINING_BONUS if Galley.bonus_pending(game) else 0)]
	v.add_child(UiTheme.label(t, 13, UiTheme.ACCENT if Galley.bonus_pending(game) else UiTheme.MUTED))
	return v
