class_name MedbayDialog
extends Modal
## Krankenstation: Patienten mit Stufe und Resttagen, Personal (bis 2; Arzt = höhere Zweite Hilfe, Helfer halb),
## Zuweisen/Abziehen, letzte Proben, „1 Tag warten“.

signal wait_day
## Handwerk begonnen (Medikits herstellen)
signal changed

var game: HubState


func show_medbay(g: HubState) -> void:
	game = g
	open("Krankenstation")
	var intro := UiTheme.label("Tag %d. Tage vergehen beim Reisen, im Einsatz und beim Warten. Jeden Tag mit Patienten würfelt der Arzt eine Zweite-Hilfe-Probe: W100 offen + Arzt + Helfer/2; ab %d heilt ein Tag zusätzlich, ab %d zwei. Der Arzt bleibt beim Einsatz an Bord, der Helfer darf mit." % [
		g.day, Medbay.T_ONE, Medbay.T_TWO], 13, UiTheme.MUTED)
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(intro)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	content.add_child(cols)
	cols.add_child(_patients())
	cols.add_child(_staff())
	content.add_child(_medkits())
	var wait := UiTheme.button("1 Tag warten")
	wait.add_theme_color_override("font_color", UiTheme.ACCENT)
	wait.pressed.connect(func() -> void: wait_day.emit())
	footer.add_child(wait)
	add_close()


func _patients() -> Control:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiTheme.label("PATIENTEN", 13, UiTheme.MUTED))
	var pts := Campaign.patients()
	if pts.is_empty():
		v.add_child(UiTheme.label("Niemand verwundet.", 15, UiTheme.GOOD))
	else:
		var g := GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 16)
		for h in ["Figur", "Stufe", "noch"]:
			g.add_child(UiTheme.label(h, 12, UiTheme.MUTED))
		for c in pts:
			g.add_child(UiTheme.label("%s %s" % [c.letter, c.name], 15, UiTheme.CREW))
			g.add_child(UiTheme.label(Injury.name(c.injury), 15, UiTheme.BAD if c.is_locked() else UiTheme.ACCENT))
			g.add_child(UiTheme.label("%d %s · %s" % [c.injury_days, "Tag" if c.injury_days == 1 else "Tage",
				"gefangen, heilt nicht" if game.is_captured(c) else ("gesperrt" if c.is_locked() else "darf mit (Malus %d)" % Injury.LIGHT_MALUS)], 14))
		v.add_child(g)
	var sp := Control.new()
	sp.custom_minimum_size.y = 12
	v.add_child(sp)
	v.add_child(UiTheme.label("LETZTE TAGE", 13, UiTheme.MUTED))
	if game.medlog.is_empty():
		v.add_child(UiTheme.label("–", 14, UiTheme.MUTED))
	for line in game.medlog:
		var l := UiTheme.label(line, 14)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(l)
	return v


func _staff() -> Control:
	var v := VBoxContainer.new()
	v.custom_minimum_size.x = 420
	v.add_child(UiTheme.label("PERSONAL (bis %d)" % Medbay.MAX_STAFF, 13, UiTheme.MUTED))
	var doc := Medbay.doctor(game)
	var hlp := Medbay.helper(game)
	v.add_child(UiTheme.label("Arzt: %s" % (doc.name if doc else "–"), 16, UiTheme.ACCENT if doc else UiTheme.MUTED))
	v.add_child(UiTheme.label("Helfer: %s" % (hlp.name if hlp else "–"), 15, UiTheme.TEXT if hlp else UiTheme.MUTED))
	v.add_child(UiTheme.label("Probenbonus: %s" % Dice.fmt(Medbay.bonus(game)) if doc else "Ohne Personal heilt nur der normale Tag.", 14, UiTheme.MUTED))
	var sp := Control.new()
	sp.custom_minimum_size.y = 8
	v.add_child(sp)
	v.add_child(UiTheme.label("Zuweisen (Zweite Hilfe):", 13, UiTheme.MUTED))
	for c in Campaign.crew():
		var on := String(c.id) in game.medics
		var row := HBoxContainer.new()
		var away := c.is_locked() or game.is_captured(c)
		var name := UiTheme.label("%s %s%s" % [c.letter, c.name, " · gefangen" if game.is_captured(c) else ""], 14, UiTheme.TEXT if not away else UiTheme.MUTED)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		row.add_child(UiTheme.label(Dice.fmt(Rules.skill_total(c, Medbay.SKILL)), 14))
		var b := UiTheme.button("abziehen" if on else "zuweisen", "gefangen: zählt nicht" if game.is_captured(c)
			else ("verwundet: zählt nicht, solange gesperrt" if c.is_locked() else ""))
		b.disabled = (not on and game.medics.size() >= Medbay.MAX_STAFF) or (not on and game.is_captured(c))
		b.custom_minimum_size.x = 96
		b.pressed.connect(func() -> void:
			Medbay.toggle(game, c)
			show_medbay(game))
		row.add_child(b)
		v.add_child(row)
	return v


## Medikits herstellen (Crafting, Mockup Bildschirm 31): Figur wählen, 1 Medikit, Probe Medikamente herstellen „mittel“
## mit dem Bonus des Ausbaus Krankenstation
var _maker: StringName = &""


func _medkits() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	var key := Stock.MEDKIT
	v.add_child(UiTheme.label("MEDIKITS HERSTELLEN · Handwerksmaterial %d · im Lager %d" % [game.craft_material, Stock.count(game, key)], 13, UiTheme.MUTED))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var pick := OptionButton.new()
	var crew := Campaign.crew()
	var sel: Character = null
	for c in crew:
		var job := Crafting.job_of(game, c)
		var st := Crafting.status_text(game, c)
		pick.add_item("%s (%+d)%s" % [c.name, Crafting.check_bonus(game, c, key), "" if st == "frei" else " – " + st])
		pick.set_item_disabled(pick.item_count - 1, not Crafting.can_work(c))
		if c.id == _maker or (sel == null and _maker == &"" and job.is_empty() and Crafting.can_work(c)):
			sel = c
	if sel == null and not crew.is_empty():
		sel = crew[0]
	if sel:
		pick.select(crew.find(sel))
	pick.item_selected.connect(func(i: int) -> void:
		_maker = crew[i].id
		show_medbay(game))
	row.add_child(pick)
	var m := Crafting.build_material(key)
	row.add_child(UiTheme.label("Medikit ×1 (%d Cr) · %d Material · %d Tag" % [Stock.price(key), m, Crafting.build_days(game, key)], 15))
	var b := UiTheme.button("Herstellen")
	b.disabled = not Crafting.can_build(game, sel, key)
	b.pressed.connect(func() -> void:
		Crafting.build(game, sel, key)
		Sfx.play(&"klick")
		changed.emit()
		show_medbay(game))
	row.add_child(b)
	v.add_child(row)
	var l := UiTheme.label("Patzer = Material weg, sonst 1 Medikit ins Lager. Eine Arbeit je Figur wie in der Werkstatt; Bonus des Ausbaus Krankenstation.", 12, UiTheme.MUTED)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	return v
